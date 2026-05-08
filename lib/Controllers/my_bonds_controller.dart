// lib/controllers/my_bonds_controller.dart
// Controls My Bonds screen
// Handles saving, deleting, and auto-checking bonds

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Utils/mock_data.dart';
import '../Utils/storage_service.dart';
import '../models/bond_model.dart';

class MyBondsController extends GetxController {
  final StorageService _storage = StorageService();

  // List of user's saved bonds - observable so UI updates automatically
  final RxList<BondModel> savedBonds = <BondModel>[].obs;
  final RxBool isAutoChecking = false.obs; // Loading state for auto-check

  @override
  void onInit() {
    super.onInit();
    loadBonds();
    autoCheckBonds(); // Run auto-check when screen opens
  }

  // Load saved bonds from local storage
  void loadBonds() {
    savedBonds.assignAll(_storage.getSavedBonds());
  }

  // Add a new bond to saved list
  void addBond(String number, int denomination) {
    // Validate bond number
    if (number.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a bond number',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Check for duplicates
    final exists = savedBonds.any(
      (b) => b.number == number.trim() && b.denomination == denomination,
    );
    if (exists) {
      Get.snackbar('Duplicate', 'This bond is already saved',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Create new bond and save it
    final bond = BondModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple unique ID
      number: number.trim(),
      denomination: denomination,
      addedDate: DateTime.now(),
    );

    _storage.saveBond(bond);
    savedBonds.add(bond); // Update UI immediately

    Get.snackbar('Saved!', 'Bond added to your portfolio',
        snackPosition: SnackPosition.BOTTOM);
  }

  // Delete a saved bond
  void deleteBond(String id) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Bond'),
        content: const Text('Are you sure you want to remove this bond?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _storage.deleteBond(id);
              savedBonds.removeWhere((b) => b.id == id);
              Get.back();
              Get.snackbar('Deleted', 'Bond removed',
                  snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Auto-check all saved bonds against latest draw results
  // This simulates what would happen with real API data
  Future<void> autoCheckBonds() async {
    if (savedBonds.isEmpty) return;

    isAutoChecking.value = true;
    await Future.delayed(const Duration(seconds: 1)); // Simulate checking delay

    bool foundWinner = false;

    // Check each bond against mock winning numbers
    for (int i = 0; i < savedBonds.length; i++) {
      final bond = savedBonds[i];
      final won = MockData.checkBond(bond.number, bond.denomination);
      savedBonds[i].isWinner = won;
      if (won) foundWinner = true;
    }

    // Trigger UI update
    savedBonds.refresh();

    // Update storage with winner status
    _storage.updateBonds(savedBonds.toList());

    isAutoChecking.value = false;

    // Notify user if any bonds won
    if (foundWinner) {
      Get.snackbar(
        '🎉 Winner!',
        'One or more of your bonds have won! Check results.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
