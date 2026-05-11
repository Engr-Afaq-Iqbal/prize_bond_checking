// lib/Controllers/BondControllers/my_bonds_controller.dart
// Manages user's saved bonds with Firestore sync
// Requires user to be logged in (auth-gated feature)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../../models/saved_bond_model.dart';
import '../../Services/saved_bond_service.dart';
import '../../Services/offline_cache_service.dart';
import '../../Services/connectivity_service.dart';
import '../../View/SignInPage/sign_in_page.dart'; // existing auth screen

class MyBondsFirebaseController extends GetxController {
  final SavedBondService _bondService = SavedBondService();
  final OfflineCacheService _cache = OfflineCacheService();
  final Logger _logger = Logger();

  final RxList<SavedBondModel> savedBonds = <SavedBondModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isAutoChecking = false.obs;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    loadBonds();
  }

  // ─── LOAD BONDS ────────────────────────────────────────────────────────────

  Future<void> loadBonds() async {
    // If user not logged in, load empty (UI handles redirect)
    if (currentUserId == null) return;

    isLoading.value = true;

    if (ConnectivityService.online) {
      await _loadFromFirestore();
    } else {
      _loadFromCache();
    }

    isLoading.value = false;
  }

  Future<void> _loadFromFirestore() async {
    try {
      final bonds = await _bondService.getUserBonds(currentUserId!);
      savedBonds.assignAll(bonds);
      // Cache for offline use
      await _cache.cacheSavedBonds(bonds);
    } catch (e) {
      _logger.e('Error loading bonds: $e');
      _loadFromCache();
    }
  }

  void _loadFromCache() {
    final cached = _cache.getCachedSavedBonds()
        .where((b) => b.userId == currentUserId)
        .toList();
    savedBonds.assignAll(cached);
  }

  // ─── ADD BOND ──────────────────────────────────────────────────────────────

  Future<void> addBond(String number, int denomination) async {
    if (currentUserId == null) {
      _redirectToLogin();
      return;
    }

    if (number.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a bond number',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Check for local duplicate before Firestore call
    final duplicate = savedBonds.any(
      (b) => b.bondNumber == number.trim() && b.denomination == denomination,
    );
    if (duplicate) {
      Get.snackbar('Duplicate', 'This bond is already saved',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final bond = SavedBondModel(
      id: '', // Firestore will generate
      userId: currentUserId!,
      bondNumber: number.trim(),
      denomination: denomination,
      savedAt: DateTime.now(),
    );

    if (ConnectivityService.online) {
      final success = await _bondService.saveBond(bond);
      if (success) {
        await loadBonds(); // Refresh from Firestore
        Get.snackbar('Saved!', 'Bond added to your portfolio',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Already Saved', 'This bond is already in your portfolio',
            snackPosition: SnackPosition.BOTTOM);
      }
    } else {
      Get.snackbar('Offline', 'Connect to internet to save bonds',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ─── DELETE BOND ───────────────────────────────────────────────────────────

  void deleteBond(String bondId) {
    Get.dialog(AlertDialog(
      title: const Text('Delete Bond'),
      content: const Text('Are you sure you want to remove this bond?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Get.back();
            await _bondService.deleteBond(bondId, currentUserId!);
            savedBonds.removeWhere((b) => b.id == bondId);
            Get.snackbar('Deleted', 'Bond removed',
                snackPosition: SnackPosition.BOTTOM);
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ));
  }

  // ─── AUTO-CHECK ────────────────────────────────────────────────────────────
  // Called when a new draw is uploaded (via Firebase trigger or manual trigger)

  Future<void> autoCheckAgainstLatestDraw({
    required String drawId,
    required int denomination,
    required List<String> winningNumbers,
  }) async {
    if (savedBonds.isEmpty) return;

    isAutoChecking.value = true;

    final winners = await _bondService.autoCheckBondsForDraw(
      drawId: drawId,
      denomination: denomination,
      winningNumbers: winningNumbers,
    );

    // Build a set of winning bond IDs for O(1) lookup
    final winnerBondIds = winners.map((w) => w.bondId).toSet();

    // Update local list to reflect winner status
    for (int i = 0; i < savedBonds.length; i++) {
      if (winnerBondIds.contains(savedBonds[i].id)) {
        savedBonds[i].isWinner = true;
        savedBonds[i].winningDrawId = drawId;
      }
    }
    savedBonds.refresh();

    isAutoChecking.value = false;

    if (winners.isNotEmpty) {
      Get.snackbar(
        'You Won!',
        '${winners.length} of your bonds won in the latest draw!',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
      );
    }
  }

  // ─── AUTH GUARD ────────────────────────────────────────────────────────────

  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  void _redirectToLogin() {
    Get.to(() => const SignInPage());
  }
}
