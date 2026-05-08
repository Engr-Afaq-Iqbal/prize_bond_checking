// lib/controllers/home_controller.dart
// Controls all logic for the Home screen
// Handles bond checking, draw results, and stats

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Utils/mock_data.dart';
import '../Utils/storage_service.dart';
import '../models/draw_result_model.dart';

class HomeController extends GetxController {
  final StorageService _storage = StorageService();

  // Observable variables - UI reacts automatically when these change
  final RxInt selectedDenomination = 750.obs; // Currently selected denomination
  final RxString bondNumber = ''.obs; // Bond number entered by user
  final RxBool hasResult = false.obs; // Whether a result is shown
  final RxBool isWinner = false.obs; // Result: won or not
  final RxBool isChecking = false.obs; // Loading state during check
  final RxList<DrawResultModel> latestDraws = <DrawResultModel>[].obs;
  final RxInt totalBonds = 0.obs; // Count of user's saved bonds
  final RxString nextDrawDate = ''.obs; // Formatted next draw date

  @override
  void onInit() {
    super.onInit();
    loadData(); // Load data when controller initializes
  }

  // Load all data needed for the home screen
  void loadData() {
    // Get latest draw results from mock data
    latestDraws.assignAll(MockData.getLatestDraws());

    // Count user's saved bonds
    totalBonds.value = _storage.getSavedBonds().length;

    // Set next draw date (hardcoded for demo, would be dynamic in real app)
    nextDrawDate.value = '14 Nov';
  }

  // Called when user taps "Check Result" button
  void checkBond() async {
    if (bondNumber.value.isEmpty) {
      Get.snackbar('Error', 'Please enter a bond number',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Show loading indicator
    isChecking.value = true;
    hasResult.value = false;

    // Simulate API delay (in real app, this would be an HTTP call)
    await Future.delayed(const Duration(milliseconds: 800));

    // Check against mock winning numbers
    isWinner.value =
        MockData.checkBond(bondNumber.value, selectedDenomination.value);
    hasResult.value = true;
    isChecking.value = false;

    // If winner, show congratulations notification
    if (isWinner.value) {
      _showWinnerDialog();
    }
  }

  // Show winner dialog/snackbar notification
  void _showWinnerDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('🎉 Congratulations!'),
        content: Text(
          'Your bond number ${bondNumber.value} (Rs. ${selectedDenomination.value}) has WON!',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  // Called from scanner - autofills the bond number
  void fillFromScanner(String scannedNumber) {
    bondNumber.value = scannedNumber;
    hasResult.value = false; // Reset any previous result
  }

  // Refresh total bond count (called after adding/deleting bonds)
  void refreshBondCount() {
    totalBonds.value = _storage.getSavedBonds().length;
  }
}
