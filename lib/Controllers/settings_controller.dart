// lib/controllers/settings_controller.dart
// Controls all settings options
// Uses GetStorage to persist user preferences

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Utils/storage_service.dart';

class SettingsController extends GetxController {
  final StorageService _storage = StorageService();

  // Observable settings - UI updates automatically when changed
  final RxBool notificationsEnabled = true.obs;
  final RxBool autoCheckEnabled = true.obs;
  final RxString selectedLanguage = 'English'.obs;

  final List<String> availableLanguages = ['English', 'اردو (Urdu)'];

  @override
  void onInit() {
    super.onInit();
    loadSettings(); // Load saved preferences from storage
  }

  // Load saved settings from storage
  void loadSettings() {
    notificationsEnabled.value = _storage.getNotificationsEnabled();
    autoCheckEnabled.value = _storage.getAutoCheckEnabled();
    selectedLanguage.value = _storage.getLanguage();
  }

  // Toggle notifications on/off
  void toggleNotifications(bool value) {
    notificationsEnabled.value = value;
    _storage.setNotificationsEnabled(value);

    Get.snackbar(
      value ? 'Notifications On' : 'Notifications Off',
      value
          ? 'You will receive prize bond alerts'
          : 'Notifications have been disabled',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Toggle auto-check on/off
  void toggleAutoCheck(bool value) {
    autoCheckEnabled.value = value;
    _storage.setAutoCheckEnabled(value);
  }

  // Change language selection (UI only for now)
  void changeLanguage(String language) {
    selectedLanguage.value = language;
    _storage.setLanguage(language);

    Get.snackbar(
      'Language',
      'Language changed to $language (Full translation coming soon)',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Clear all saved bonds with confirmation
  void clearAllBonds() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear All Bonds'),
        content: const Text(
            'This will permanently delete all your saved bonds. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _storage.clearAllBonds();
              Get.back();
              Get.snackbar('Cleared', 'All saved bonds have been deleted',
                  snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Logout function (navigate to login screen)
  void logout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              // Navigate to login - auth is already handled separately
              // In your existing auth setup, call your auth controller's logout
              Get.offAllNamed('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
