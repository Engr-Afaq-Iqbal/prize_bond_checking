// lib/controllers/marketplace_controller.dart
// Controls the Marketplace screen
// Shows bonds for sale and allows user to list their own bonds

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Utils/mock_data.dart';
import '../Utils/storage_service.dart';
import '../models/marketplace_model.dart';

class MarketplaceController extends GetxController {
  final StorageService _storage = StorageService();

  // All listings (mock + user's own)
  final RxList<MarketplaceModel> allListings = <MarketplaceModel>[].obs;

  // Filter state
  final RxInt filterDenomination = 0.obs; // 0 means "All"

  @override
  void onInit() {
    super.onInit();
    loadListings();
  }

  // Load both mock listings and user's stored listings
  void loadListings() {
    final mockListings = MockData.getMarketplaceListings();
    final userListings = _storage.getMarketListings();

    // Combine mock data with user's real listings
    allListings.assignAll([...mockListings, ...userListings]);
  }

  // Get filtered listings based on denomination filter
  List<MarketplaceModel> get filteredListings {
    if (filterDenomination.value == 0) return allListings; // Show all
    return allListings
        .where((l) => l.denomination == filterDenomination.value)
        .toList();
  }

  // Add new listing (from Sell Your Bond screen)
  void addListing(
      String bondNumber, int denomination, double price, String location) {
    if (bondNumber.trim().isEmpty || price <= 0) {
      Get.snackbar('Error', 'Please fill all required fields',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final listing = MarketplaceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bondNumber: bondNumber.trim(),
      denomination: denomination,
      askingPrice: price,
      sellerName: 'You', // In real app, this would be logged-in user's name
      location: location.trim(),
      listedDate: DateTime.now(),
    );

    _storage.addMarketListing(listing);
    allListings.add(listing);

    Get.snackbar('Listed!', 'Your bond is now listed for sale',
        snackPosition: SnackPosition.BOTTOM);
    Get.back(); // Close the sell screen
  }

  // Simulate contacting seller (in real app, this would open WhatsApp/chat)
  void contactSeller(MarketplaceModel listing) {
    Get.dialog(
      AlertDialog(
        title: const Text('Contact Seller'),
        content: Text(
          'Seller: ${listing.sellerName}\nLocation: ${listing.location}\n\n'
          'In a real app, this would connect you via WhatsApp or in-app chat.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }

  // Set denomination filter
  void setFilter(int denomination) {
    filterDenomination.value = denomination;
  }
}
