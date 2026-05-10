// // lib/controllers/marketplace_controller.dart
// // Controls the Marketplace screen
// // Shows bonds for sale and allows user to list their own bonds
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../Utils/mock_data.dart';
// import '../Utils/storage_service.dart';
// import '../models/marketplace_model.dart';
//
// class MarketplaceController extends GetxController {
//   final StorageService _storage = StorageService();
//
//   // All listings (mock + user's own)
//   final RxList<MarketplaceModel> allListings = <MarketplaceModel>[].obs;
//
//   // Filter state
//   final RxInt filterDenomination = 0.obs; // 0 means "All"
//
//   @override
//   void onInit() {
//     super.onInit();
//     loadListings();
//   }
//
//   // Load both mock listings and user's stored listings
//   void loadListings() {
//     final mockListings = MockData.getMarketplaceListings();
//     final userListings = _storage.getMarketListings();
//
//     // Combine mock data with user's real listings
//     allListings.assignAll([...mockListings, ...userListings]);
//   }
//
//   // Get filtered listings based on denomination filter
//   List<MarketplaceModel> get filteredListings {
//     if (filterDenomination.value == 0) return allListings; // Show all
//     return allListings
//         .where((l) => l.denomination == filterDenomination.value)
//         .toList();
//   }
//
//   // Add new listing (from Sell Your Bond screen)
//   void addListing(
//       String bondNumber, int denomination, double price, String location) {
//     if (bondNumber.trim().isEmpty || price <= 0) {
//       Get.snackbar('Error', 'Please fill all required fields',
//           snackPosition: SnackPosition.BOTTOM);
//       return;
//     }
//
//     final listing = MarketplaceModel(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       bondNumber: bondNumber.trim(),
//       denomination: denomination,
//       askingPrice: price,
//       sellerName: 'You', // In real app, this would be logged-in user's name
//       location: location.trim(),
//       listedDate: DateTime.now(),
//     );
//
//     _storage.addMarketListing(listing);
//     allListings.add(listing);
//
//     Get.snackbar('Listed!', 'Your bond is now listed for sale',
//         snackPosition: SnackPosition.BOTTOM);
//     Get.back(); // Close the sell screen
//   }
//
//   // Simulate contacting seller (in real app, this would open WhatsApp/chat)
//   void contactSeller(MarketplaceModel listing) {
//     Get.dialog(
//       AlertDialog(
//         title: const Text('Contact Seller'),
//         content: Text(
//           'Seller: ${listing.sellerName}\nLocation: ${listing.location}\n\n'
//           'In a real app, this would connect you via WhatsApp or in-app chat.',
//         ),
//         actions: [
//           TextButton(onPressed: () => Get.back(), child: const Text('OK')),
//         ],
//       ),
//     );
//   }
//
//   // Set denomination filter
//   void setFilter(int denomination) {
//     filterDenomination.value = denomination;
//   }
// }

// lib/Controllers/marketplace_controller.dart
// UPDATED: Marketplace now uses Firestore instead of local mock data
// Login required to post listings

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Models/market_listing_model.dart';
import '../Services/connectivity_service.dart';
import '../View/SignInPage/sign_in_page.dart';

class MarketplaceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  final RxList<MarketListingModel> listings = <MarketListingModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt filterDenomination = 0.obs;

  List<MarketListingModel> get filteredListings {
    if (filterDenomination.value == 0) return listings;
    return listings
        .where((l) => l.denomination == filterDenomination.value)
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadListings();
  }

  // ─── LOAD LISTINGS ─────────────────────────────────────────────────────────

  Future<void> loadListings() async {
    isLoading.value = true;
    try {
      Query query = _firestore
          .collection('marketplace')
          .where('isActive', isEqualTo: true)
          .orderBy('listedAt', descending: true);

      if (filterDenomination.value != 0) {
        query =
            query.where('denomination', isEqualTo: filterDenomination.value);
      }

      final snapshot = await query.limit(50).get();
      listings.assignAll(
        snapshot.docs.map((doc) => MarketListingModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id)),
      );
    } catch (e) {
      _logger.e('Error loading marketplace: $e');
      // Fallback to mock data if offline
      _loadMockData();
    }
    isLoading.value = false;
  }

  void _loadMockData() {
    // Show some sample listings when offline
    listings.assignAll([
      MarketListingModel(
        id: 'm1',
        sellerUid: 'demo',
        sellerName: 'Ahmed K.',
        sellerCity: 'Islamabad',
        bondNumber: '887766',
        denomination: 40000,
        askingPrice: 40500,
        listedAt: DateTime(2025, 11, 10),
      ),
      MarketListingModel(
        id: 'm2',
        sellerUid: 'demo',
        sellerName: 'Sara T.',
        sellerCity: 'Lahore',
        bondNumber: '112233',
        denomination: 25000,
        askingPrice: 25200,
        listedAt: DateTime(2025, 11, 12),
      ),
    ]);
  }

  // ─── ADD LISTING ───────────────────────────────────────────────────────────

  Future<void> addListing({
    required String bondNumber,
    required int denomination,
    required double price,
    required String city,
    String phone = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.to(() => const SignInPage());
      return;
    }

    if (bondNumber.trim().isEmpty || price <= 0 || city.trim().isEmpty) {
      Get.snackbar('Error', 'Please fill all fields',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (!ConnectivityService.online) {
      Get.snackbar('Offline', 'Connect to internet to list a bond',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      // Get seller name from Firestore
      final userDoc =
          await _firestore.collection('customers').doc(user.uid).get();
      final firstName = userDoc.data()?['firstName'] ?? '';
      final lastName = userDoc.data()?['lastName'] ?? '';
      final sellerName = '$firstName $lastName'.trim();

      final listing = MarketListingModel(
        id: '',
        sellerUid: user.uid,
        sellerName: sellerName.isEmpty ? 'Anonymous' : sellerName,
        sellerCity: city.trim(),
        bondNumber: bondNumber.trim(),
        denomination: denomination,
        askingPrice: price,
        listedAt: DateTime.now(),
        sellerPhone: phone.trim(),
      );

      await _firestore.collection('marketplace').add(listing.toFirestore());
      await loadListings();

      Get.snackbar('Listed!', 'Your bond is now listed for sale',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
      Get.back();
    } catch (e) {
      _logger.e('Error adding listing: $e');
      Get.snackbar('Error', 'Failed to list bond',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ─── CONTACT SELLER ────────────────────────────────────────────────────────

  void contactSeller(MarketListingModel listing) {
    Get.dialog(AlertDialog(
      title: const Text('Contact Seller'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Seller: ${listing.sellerName}'),
          Text('Location: ${listing.sellerCity}'),
          if (listing.sellerPhone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Phone: ${listing.sellerPhone}'),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        if (listing.sellerPhone.isNotEmpty) ...[
          TextButton(
            onPressed: () {
              Get.back();
              _openWhatsApp(listing.sellerPhone, listing);
            },
            child: const Text('WhatsApp'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _callSeller(listing.sellerPhone);
            },
            child: const Text('Call'),
          ),
        ],
      ],
    ));
  }

  Future<void> _openWhatsApp(String phone, MarketListingModel listing) async {
    // Sanitize phone: remove spaces, dashes, parentheses
    final cleaned = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    // Add Pakistan country code if missing
    final international =
        cleaned.startsWith('+') ? cleaned : '+92${cleaned.replaceFirst(RegExp(r'^0'), '')}';

    final message = Uri.encodeComponent(
      'Hi ${listing.sellerName}, I am interested in your Rs. ${listing.denomination} Prize Bond #${listing.bondNumber} listed for Rs. ${listing.askingPrice.toStringAsFixed(0)}.',
    );
    final uri = Uri.parse('https://wa.me/$international?text=$message');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'WhatsApp is not installed',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _callSeller(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar('Error', 'Cannot make calls on this device',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ─── FILTER ────────────────────────────────────────────────────────────────

  void setFilter(int denomination) {
    filterDenomination.value = denomination;
    loadListings();
  }

  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;
}
