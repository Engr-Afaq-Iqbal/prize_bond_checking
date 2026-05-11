// lib/Controllers/my_bonds_controller.dart
// Controls the "My Bonds" screen.
//
// Key features implemented here:
//  1. AUTH GUARD   — user must be logged in to save/delete bonds.
//  2. OFFLINE-FIRST — bond is saved to device storage FIRST (instant),
//                     then pushed to Firestore in the background.
//  3. FIREBASE SYNC — when internet is available the bond is also stored
//                     in the cloud so data is never lost.
//  4. AUTO-CHECK    — checks saved bonds against draw results automatically.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Services/connectivity_service.dart';
import '../Utils/mock_data.dart';
import '../Utils/storage_service.dart';
import '../View/SignInPage/sign_in_page.dart';
import '../models/bond_model.dart';

class MyBondsController extends GetxController {
  // StorageService uses GetStorage — a fast key-value store on the device.
  // This is what powers the OFFLINE capability.
  final StorageService _storage = StorageService();

  // Firestore — the cloud database where bonds are backed up.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable list — every time this changes the UI rebuilds automatically.
  final RxList<BondModel> savedBonds = <BondModel>[].obs;

  // True while the auto-check routine is running (shows loading spinner).
  final RxBool isAutoChecking = false.obs;

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns true if a Firebase user is currently signed in.
  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  /// Returns the Firebase UID of the signed-in user, or null if not signed in.
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    loadBonds(); // Load bonds from local storage when screen opens
  }

  // ── LOAD ───────────────────────────────────────────────────────────────────

  /// Reads bonds from the device's local storage (works offline).
  void loadBonds() {
    savedBonds.assignAll(_storage.getSavedBonds());
  }

  // ── ADD BOND (offline-first) ───────────────────────────────────────────────

  /// Saves a new bond.
  ///
  /// Step 1: Validates input and checks for duplicates.
  /// Step 2: Saves to local GetStorage immediately (offline-first).
  /// Step 3: Closes the bottom sheet.
  /// Step 4: In background, pushes to Firestore if internet is available.
  Future<void> addBond(String number, int denomination) async {
    // ── AUTH GUARD ────────────────────────────────────────────────────────────
    // We refuse to save if the user is not logged in.
    // The UI should already hide the "Add" button, but this is a safety net.
    if (!isLoggedIn) {
      Get.snackbar(
        'Login Required',
        'Please sign in to save bonds',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        mainButton: TextButton(
          onPressed: () => Get.to(() => const SignInPage()),
          child: const Text('Sign In', style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }

    // ── VALIDATION ─────────────────────────────────────────────────────────────
    final trimmed = number.trim();

    if (trimmed.isEmpty) {
      Get.snackbar('Error', 'Please enter a bond number',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Prize bond numbers are exactly 6 digits
    if (trimmed.length != 6 || int.tryParse(trimmed) == null) {
      Get.snackbar('Invalid Number', 'Bond number must be exactly 6 digits',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Check for duplicate in the local list
    final exists = savedBonds.any(
      (b) => b.number == trimmed && b.denomination == denomination,
    );
    if (exists) {
      Get.snackbar('Already Saved', 'This bond is already in your portfolio',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // ── STEP 1: SAVE LOCALLY (offline-first) ────────────────────────────────
    // The bond is written to the device right now — no internet needed.
    // The user sees it in the list immediately.
    final bond = BondModel(
      // Include userId in the ID so bonds from different users don't clash
      id: '${currentUserId}_${DateTime.now().millisecondsSinceEpoch}',
      number: trimmed,
      denomination: denomination,
      addedDate: DateTime.now(),
    );

    _storage.saveBond(bond); // Write to GetStorage (device)
    savedBonds.add(bond);    // Update the observable list → UI rebuilds

    // ── STEP 2: CLOSE THE BOTTOM SHEET ──────────────────────────────────────
    // We close BEFORE showing the snackbar so the sheet dismisses first.
    Get.back();

    Get.snackbar(
      'Bond Saved!',
      'Added to your portfolio',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    // ── STEP 3: SYNC TO FIREBASE IN BACKGROUND ───────────────────────────────
    // This runs AFTER the UI is updated, so the user never waits for it.
    // If there is no internet, the bond stays in local storage and is synced
    // the next time this method is called while online.
    _syncBondToFirebase(bond);
  }

  // ── FIREBASE SYNC (background) ────────────────────────────────────────────

  /// Pushes a single bond to Firestore if it is not already there.
  /// Runs silently — failures do NOT show errors since local save succeeded.
  Future<void> _syncBondToFirebase(BondModel bond) async {
    if (!ConnectivityService.online || currentUserId == null) return;

    try {
      // Check if this exact bond already exists in Firestore
      final query = await _firestore
          .collection('saved_bonds')
          .where('userId', isEqualTo: currentUserId)
          .where('bondNumber', isEqualTo: bond.number)
          .where('denomination', isEqualTo: bond.denomination)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        // Not in Firestore yet — push it now
        await _firestore.collection('saved_bonds').add({
          'userId': currentUserId,
          'bondNumber': bond.number,
          'denomination': bond.denomination,
          'savedAt': bond.addedDate.toIso8601String(),
          'localId': bond.id, // Keep a reference to the local ID
        });
      }
    } catch (_) {
      // Firebase push failed — bond is still safe in local storage.
      // It will be pushed next time the user is online and opens the app.
    }
  }

  /// Syncs ALL locally-saved bonds to Firestore.
  /// Call this when the app reconnects to the internet.
  Future<void> syncAllToFirebase() async {
    for (final bond in savedBonds) {
      await _syncBondToFirebase(bond);
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  void deleteBond(String id) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Bond'),
        content: const Text('Remove this bond from your portfolio?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              _storage.deleteBond(id);
              savedBonds.removeWhere((b) => b.id == id);
              Get.snackbar('Deleted', 'Bond removed',
                  snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── AUTO-CHECK ────────────────────────────────────────────────────────────

  /// Checks all saved bonds against the latest draw results.
  /// Updates isWinner flag and shows a snackbar if any bond won.
  Future<void> autoCheckBonds() async {
    if (savedBonds.isEmpty) return;

    isAutoChecking.value = true;
    // Small delay so the loading spinner is visible
    await Future.delayed(const Duration(seconds: 1));

    bool foundWinner = false;
    for (int i = 0; i < savedBonds.length; i++) {
      final bond = savedBonds[i];
      final won = MockData.checkBond(bond.number, bond.denomination);
      savedBonds[i].isWinner = won;
      if (won) foundWinner = true;
    }

    savedBonds.refresh(); // Trigger UI rebuild
    _storage.updateBonds(savedBonds.toList()); // Persist winner flags
    isAutoChecking.value = false;

    if (foundWinner) {
      Get.snackbar(
        '🎉 Winner!',
        'One or more of your bonds have won! Check results.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Navigate to login screen.
  void goToLogin() => Get.to(() => const SignInPage());
}
