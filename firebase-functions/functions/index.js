// firebase-functions/functions/index.js
// Firebase Cloud Functions for Prize Bond App
// 
// SETUP INSTRUCTIONS:
//   1. cd firebase-functions/functions
//   2. npm install
//   3. firebase deploy --only functions

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ═══════════════════════════════════════════════════════════════════════════════
// FUNCTION 1: onNewDraw
// Triggered when admin adds a new draw to Firestore
// Automatically checks all saved bonds and sends push notifications
// ═══════════════════════════════════════════════════════════════════════════════
exports.onNewDraw = functions.firestore
  .document("draws/{drawId}")
  .onCreate(async (snap, context) => {
    const drawId = context.params.drawId;
    const drawData = snap.data();

    const denomination = drawData.denomination;
    const winningNumbers = drawData.winningNumbers || [];
    const drawNumber = drawData.drawNumber;

    console.log(`New draw created: Draw #${drawNumber} (Rs. ${denomination})`);
    console.log(`Winning numbers count: ${winningNumbers.length}`);

    // ── STEP 1: Find all saved bonds matching this denomination ──────────────
    const bondsSnapshot = await db
      .collection("saved_bonds")
      .where("denomination", "==", denomination)
      .get();

    if (bondsSnapshot.empty) {
      console.log("No saved bonds for denomination:", denomination);
    }

    // Collect winning bond documents
    const winnerDocs = [];
    bondsSnapshot.forEach((doc) => {
      const bondData = doc.data();
      if (winningNumbers.includes(bondData.bondNumber)) {
        winnerDocs.push({ id: doc.id, ...bondData });
      }
    });

    console.log(`Found ${winnerDocs.length} winning bonds`);

    // ── STEP 2: Update winning bonds in Firestore (batch write) ─────────────
    if (winnerDocs.length > 0) {
      const batch = db.batch();
      winnerDocs.forEach((winner) => {
        const bondRef = db.collection("saved_bonds").doc(winner.id);
        batch.update(bondRef, {
          isWinner: true,
          winningDrawId: drawId,
        });
      });
      await batch.commit();
      console.log("Updated winner status for", winnerDocs.length, "bonds");
    }

    // ── STEP 3: Send winner notifications to each winning bond's owner ───────
    const notifPromises = winnerDocs.map(async (winner) => {
      const userId = winner.userId;

      // Get user's FCM token
      const userDoc = await db.collection("customers").doc(userId).get();
      if (!userDoc.exists) return;

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log("No FCM token for user:", userId);
        return;
      }

      // Store notification in Firestore (in-app history)
      await db.collection("notifications").add({
        userId: userId,
        title: "🎉 You Won!",
        body: `Your bond #${winner.bondNumber} (Rs. ${denomination}) won in Draw #${drawNumber}!`,
        type: "winner",
        relatedId: drawId,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Send push notification
      try {
        await messaging.send({
          token: fcmToken,
          notification: {
            title: "🎉 Congratulations! You Won!",
            body: `Bond #${winner.bondNumber} (Rs. ${denomination}) won in Draw #${drawNumber}!`,
          },
          data: {
            type: "winner",
            drawId: drawId,
            bondNumber: winner.bondNumber,
          },
          android: {
            notification: {
              channelId: "prize_bond_channel",
              sound: "default",
              priority: "high",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        });
        console.log(`Winner notification sent to user: ${userId}`);
      } catch (error) {
        console.error("Error sending winner notification:", error);
      }
    });

    await Promise.all(notifPromises);

    // ── STEP 4: Send "new draw available" notification to ALL users ──────────
    await sendNewDrawNotificationToAll(denomination, drawNumber, drawId);

    console.log("onNewDraw function completed successfully");
    return null;
  });

// ── Helper: Send broadcast notification about new draw ──────────────────────
async function sendNewDrawNotificationToAll(denomination, drawNumber, drawId) {
  try {
    // Get all active users with FCM tokens
    const usersSnapshot = await db
      .collection("customers")
      .where("status", "==", "active")
      .where("role", "==", "normal_user")
      .get();

    const tokens = [];
    usersSnapshot.forEach((doc) => {
      const token = doc.data().fcmToken;
      if (token) tokens.push(token);
    });

    if (tokens.length === 0) {
      console.log("No user tokens found for broadcast");
      return;
    }

    // Send to all users (multicast - up to 500 tokens per call)
    const chunks = chunkArray(tokens, 500);

    for (const chunk of chunks) {
      await messaging.sendEachForMulticast({
        tokens: chunk,
        notification: {
          title: "📋 New Draw Results Available",
          body: `Rs. ${denomination} Draw #${drawNumber} results are now published!`,
        },
        data: {
          type: "draw_result",
          drawId: drawId,
        },
        android: {
          notification: {
            channelId: "prize_bond_channel",
            sound: "default",
          },
        },
      });
    }

    console.log(`New draw notification sent to ${tokens.length} users`);
  } catch (error) {
    console.error("Error sending broadcast notification:", error);
  }
}

// Utility: Split array into chunks
function chunkArray(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

// ═══════════════════════════════════════════════════════════════════════════════
// FUNCTION 2: onUserSignup
// Triggered when new user document is created in 'customers' collection
// Sets initial values and welcomes the user
// ═══════════════════════════════════════════════════════════════════════════════
exports.onUserSignup = functions.firestore
  .document("customers/{userId}")
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const userData = snap.data();

    console.log(`New user registered: ${userData.email} (${userData.role})`);

    // Admin accounts are auto-approved; normal users start as 'pending'
    // This is already handled in SignupController, but we can add extra logic here

    return null;
  });

// ═══════════════════════════════════════════════════════════════════════════════
// FUNCTION 3: getAdminStats (HTTPS callable)
// Called from admin dashboard to get real-time stats
// ═══════════════════════════════════════════════════════════════════════════════
exports.getAdminStats = functions.https.onCall(async (data, context) => {
  // Only authenticated admins can call this
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  // Verify admin role
  const userDoc = await db.collection("customers").doc(context.auth.uid).get();
  if (!userDoc.exists || userDoc.data().role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "Must be admin");
  }

  // Get counts
  const [usersSnap, bondsSnap, drawsSnap] = await Promise.all([
    db.collection("customers").where("role", "==", "normal_user").count().get(),
    db.collection("saved_bonds").count().get(),
    db.collection("draws").count().get(),
  ]);

  return {
    totalUsers: usersSnap.data().count,
    totalSavedBonds: bondsSnap.data().count,
    totalDraws: drawsSnap.data().count,
  };
});
