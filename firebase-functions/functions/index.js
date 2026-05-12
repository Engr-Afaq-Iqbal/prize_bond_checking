// firebase-functions/functions/index.js
//
// Prize Bond App — Firebase Cloud Functions v2
//
// FUNCTIONS:
//   1. onNewDraw       — Firestore trigger: runs when admin publishes a draw
//                        • Sends "new draw available" push to ALL users
//                        • Sends personal "you won!" push to each winner
//                        • Stores in-app notification in Firestore per winner
//
//   2. onUserSignup    — Firestore trigger: runs when new customer doc created
//                        • Logs new registration (extend here for welcome email etc.)
//
//   3. getAdminStats   — HTTPS callable: returns real-time counts for admin dashboard
//
// DEPLOYMENT:
//   cd firebase-functions
//   npm install                          (first time only)
//   firebase deploy --only functions
//
// NODE VERSION: 18  (set in package.json engines)

"use strict";

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

// Set default region (change to match your Firebase project region)
setGlobalOptions({ region: "us-central1" });

const db    = admin.firestore();
const fcm   = admin.messaging();

// ═══════════════════════════════════════════════════════════════════════════
// FUNCTION 1: onNewDraw
// Triggered when admin creates a new document in the 'draws' collection.
//
// What it does:
//   1. Broadcast "new draw available" notification to all active users
//   2. Find winning bonds and send personal "you won!" notification per winner
//   3. Store in-app notification in Firestore for each winner
// ═══════════════════════════════════════════════════════════════════════════
exports.onNewDraw = onDocumentCreated(
  "draws/{drawId}",
  async (event) => {
    const drawId   = event.params.drawId;
    const drawData = event.data.data();

    if (!drawData) {
      console.error("onNewDraw: empty document data for drawId:", drawId);
      return null;
    }

    const denomination   = drawData.denomination   ?? 0;
    const drawNumber     = drawData.drawNumber     ?? 0;
    const winningNumbers = drawData.winningNumbers ?? [];

    console.log(
      `onNewDraw: Draw #${drawNumber} (Rs. ${denomination}) — ` +
      `${winningNumbers.length} winning numbers`
    );

    // ── Step 1: Broadcast to ALL users ──────────────────────────────────────
    await _broadcastNewDraw({ denomination, drawNumber, drawId });

    // ── Step 2: Find winning bonds & notify winners ─────────────────────────
    if (winningNumbers.length > 0) {
      await _notifyWinners({
        drawId,
        drawNumber,
        denomination,
        winningNumbers,
      });
    }

    console.log("onNewDraw: completed successfully for draw:", drawId);
    return null;
  }
);

// ── Helper: broadcast to all active users ───────────────────────────────────
async function _broadcastNewDraw({ denomination, drawNumber, drawId }) {
  try {
    const snapshot = await db
      .collection("customers")
      .where("status", "==", "active")
      .where("role",   "==", "normal_user")
      .get();

    if (snapshot.empty) {
      console.log("_broadcastNewDraw: no active users found");
      return;
    }

    // Collect valid FCM tokens
    const tokens = [];
    snapshot.forEach((doc) => {
      const token = doc.data().fcmToken;
      if (token && typeof token === "string" && token.length > 10) {
        tokens.push(token);
      }
    });

    if (tokens.length === 0) {
      console.log("_broadcastNewDraw: no FCM tokens found");
      return;
    }

    console.log(`_broadcastNewDraw: sending to ${tokens.length} users`);

    // Firebase FCM multicast — max 500 tokens per call
    const chunks = _chunkArray(tokens, 500);
    for (const chunk of chunks) {
      const response = await fcm.sendEachForMulticast({
        tokens: chunk,
        notification: {
          title: "📋 New Draw Results Available",
          body: `Rs. ${denomination} Prize Bond Draw #${drawNumber} results are now published!`,
        },
        data: {
          type:       "draw_result",
          drawId:     drawId,
          screen:     "/draws",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "prize_bond_channel",
            sound:     "default",
            priority:  "high",
          },
        },
        apns: {
          payload: {
            aps: { sound: "default", badge: 1 },
          },
        },
      });

      // Clean up invalid tokens
      const invalidTokens = [];
      response.responses.forEach((resp, idx) => {
        if (
          !resp.success &&
          (resp.error?.code === "messaging/invalid-registration-token" ||
           resp.error?.code === "messaging/registration-token-not-registered")
        ) {
          invalidTokens.push(chunk[idx]);
        }
      });

      if (invalidTokens.length > 0) {
        console.log(
          `_broadcastNewDraw: removing ${invalidTokens.length} invalid tokens`
        );
        await _removeInvalidTokens(invalidTokens);
      }
    }

    console.log(`_broadcastNewDraw: sent to ${tokens.length} users`);
  } catch (err) {
    console.error("_broadcastNewDraw error:", err);
  }
}

// ── Helper: find winners and send personal notifications ────────────────────
async function _notifyWinners({
  drawId, drawNumber, denomination, winningNumbers,
}) {
  try {
    const bondsSnap = await db
      .collection("saved_bonds")
      .where("denomination", "==", denomination)
      .get();

    if (bondsSnap.empty) {
      console.log("_notifyWinners: no saved bonds for denomination:", denomination);
      return;
    }

    const winners = [];
    bondsSnap.forEach((doc) => {
      const b = doc.data();
      if (winningNumbers.includes(b.bondNumber)) {
        winners.push({ id: doc.id, ...b });
      }
    });

    console.log(`_notifyWinners: found ${winners.length} winning bonds`);
    if (winners.length === 0) return;

    // Process each winner
    await Promise.all(
      winners.map((winner) =>
        _processWinner({ winner, drawId, drawNumber, denomination })
      )
    );
  } catch (err) {
    console.error("_notifyWinners error:", err);
  }
}

// ── Helper: process a single winner ─────────────────────────────────────────
async function _processWinner({ winner, drawId, drawNumber, denomination }) {
  const { userId, bondNumber } = winner;

  try {
    // Duplicate prevention: skip if notification already sent for this bond+draw
    const existing = await db
      .collection("notifications")
      .where("userId",     "==", userId)
      .where("relatedId",  "==", drawId)
      .where("bondNumber", "==", bondNumber)
      .where("type",       "==", "winner")
      .limit(1)
      .get();

    if (!existing.empty) {
      console.log(`_processWinner: duplicate skipped — user ${userId}, bond ${bondNumber}, draw ${drawId}`);
      return;
    }

    // Store in-app notification in Firestore
    await db.collection("notifications").add({
      userId:     userId,
      title:      "🎉 Congratulations! You Won!",
      body:       `Bond #${bondNumber} (Rs. ${denomination}) won in Draw #${drawNumber}!`,
      type:       "winner",
      relatedId:  drawId,
      bondNumber: bondNumber,
      drawNumber: drawNumber,
      denomination: denomination,
      isRead:     false,
      createdAt:  admin.firestore.FieldValue.serverTimestamp(),
    });

    // Fetch user's FCM token
    const userDoc = await db.collection("customers").doc(userId).get();
    if (!userDoc.exists) {
      console.log("_processWinner: user not found:", userId);
      return;
    }

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      console.log("_processWinner: no FCM token for user:", userId);
      return;
    }

    // Send push notification
    await fcm.send({
      token: fcmToken,
      notification: {
        title: "🎉 Congratulations! You Won!",
        body:  `Bond #${bondNumber} (Rs. ${denomination}) won in Draw #${drawNumber}!`,
      },
      data: {
        type:        "winner",
        drawId:      drawId,
        bondNumber:  String(bondNumber),
        drawNumber:  String(drawNumber),
        denomination: String(denomination),
        screen:      "/my-bonds",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "prize_bond_channel",
          sound:     "default",
          priority:  "high",
        },
      },
      apns: {
        payload: {
          aps: { sound: "default", badge: 1 },
        },
      },
    });

    console.log(`_processWinner: notification sent — user ${userId}, bond ${bondNumber}`);
  } catch (err) {
    if (
      err.code === "messaging/invalid-registration-token" ||
      err.code === "messaging/registration-token-not-registered"
    ) {
      console.log("_processWinner: invalid token for user:", userId);
      await db.collection("customers").doc(userId).update({ fcmToken: null });
    } else {
      console.error("_processWinner error for user", userId, ":", err);
    }
  }
}

// ── Helper: remove invalid FCM tokens from Firestore ────────────────────────
async function _removeInvalidTokens(invalidTokens) {
  try {
    const snap = await db
      .collection("customers")
      .where("fcmToken", "in", invalidTokens)
      .get();

    const batch = db.batch();
    snap.forEach((doc) => batch.update(doc.ref, { fcmToken: null }));
    await batch.commit();
  } catch (err) {
    console.error("_removeInvalidTokens error:", err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FUNCTION 2: onUserSignup
// Triggered when a new document is created in 'customers'.
// ═══════════════════════════════════════════════════════════════════════════
exports.onUserSignup = onDocumentCreated(
  "customers/{userId}",
  async (event) => {
    const userId   = event.params.userId;
    const userData = event.data.data();

    console.log(
      `onUserSignup: new user — ${userData?.email ?? "unknown"} ` +
      `(role: ${userData?.role ?? "unknown"})`
    );

    // Placeholder: add welcome email, analytics event, etc. here
    return null;
  }
);

// ═══════════════════════════════════════════════════════════════════════════
// FUNCTION 3: getAdminStats (HTTPS Callable)
// Called from the admin dashboard to get real-time counts.
// Only accessible by authenticated admin users.
// ═══════════════════════════════════════════════════════════════════════════
exports.getAdminStats = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const userDoc = await db
    .collection("customers")
    .doc(request.auth.uid)
    .get();

  if (!userDoc.exists || userDoc.data().role !== "admin") {
    throw new HttpsError("permission-denied", "Admin access only.");
  }

  const [usersSnap, bondsSnap, drawsSnap] = await Promise.all([
    db.collection("customers").where("role", "==", "normal_user").count().get(),
    db.collection("saved_bonds").count().get(),
    db.collection("draws").count().get(),
  ]);

  return {
    totalUsers:      usersSnap.data().count,
    totalSavedBonds: bondsSnap.data().count,
    totalDraws:      drawsSnap.data().count,
  };
});

// ── Utility: split array into chunks ────────────────────────────────────────
function _chunkArray(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}
