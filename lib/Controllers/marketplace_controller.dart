// lib/Controllers/marketplace_controller.dart
// Controls the Marketplace screen.
//
// Key features:
//  1. AUTH GUARD    — only logged-in users can list bonds.
//  2. OFFLINE-FIRST — listing is saved locally first (GetStorage),
//                     then pushed to Firestore when internet is available.
//  3. PENDING QUEUE — if offline, listings are queued and auto-synced
//                     the next time loadListings() runs while online.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Models/market_listing_model.dart';
import '../Services/connectivity_service.dart';
import '../View/SignInPage/sign_in_page.dart';

class MarketplaceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _local = GetStorage(); // Used for pending-listings queue
  final Logger _logger = Logger();

  // Key used to store pending (not yet synced) listings in GetStorage
  static const String _pendingKey = 'pending_marketplace_listings';

  // Observable state
  final RxList<MarketListingModel> listings = <MarketListingModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt filterDenomination = 0.obs; // 0 = show all denominations

  // ── Computed ───────────────────────────────────────────────────────────────

  /// Returns the listings filtered by the selected denomination.
  List<MarketListingModel> get filteredListings {
    if (filterDenomination.value == 0) return listings;
    return listings
        .where((l) => l.denomination == filterDenomination.value)
        .toList();
  }

  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    loadListings(); // Loads online data OR shows cached mock data
  }

  // ── LOAD LISTINGS ──────────────────────────────────────────────────────────

  /// Fetches listings from Firestore.
  /// Also flushes any locally-queued pending listings to Firestore first.
  Future<void> loadListings() async {
    isLoading.value = true;

    // If online, first push any pending (offline-queued) listings to Firestore
    if (ConnectivityService.online) {
      await _flushPendingListings();
    }

    try {
      // Build query — filter by denomination if one is selected
      Query query = _firestore
          .collection('marketplace')
          .where('isActive', isEqualTo: true)
          .orderBy('listedAt', descending: true);

      if (filterDenomination.value != 0) {
        query = query.where('denomination',
            isEqualTo: filterDenomination.value);
      }

      final snapshot = await query.limit(50).get();
      listings.assignAll(
        snapshot.docs.map((doc) => MarketListingModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id)),
      );
    } catch (e) {
      _logger.e('Error loading marketplace: $e');
      // When offline or Firestore fails, show demo data so screen is not empty
      _loadDemoData();
    }

    isLoading.value = false;
  }

  // ── ADD LISTING (offline-first) ────────────────────────────────────────────

  /// Lists a bond for sale.
  ///
  /// Step 1: Auth + validation checks.
  /// Step 2: Save listing to local GetStorage queue immediately.
  /// Step 3: Close the sell screen.
  /// Step 4: If online, push to Firestore now; otherwise it waits for next sync.
  Future<void> addListing({
    required String bondNumber,
    required int denomination,
    required double price,
    required String city,
    String phone = '',
  }) async {
    // ── AUTH GUARD ─────────────────────────────────────────────────────────
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Redirect to login instead of blocking silently
      Get.to(() => const SignInPage());
      return;
    }

    // ── VALIDATION ──────────────────────────────────────────────────────────
    if (bondNumber.trim().isEmpty ||
        bondNumber.trim().length != 6 ||
        price <= 0 ||
        city.trim().isEmpty ||
        phone.trim().isEmpty) {
      Get.snackbar('Incomplete Form',
          'Please fill all required fields (bond number must be 6 digits)',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // ── STEP 1: BUILD LISTING DATA ──────────────────────────────────────────
    // We use a simple Map here so it can be stored in GetStorage AND Firestore
    // without needing two separate model conversions.
    final listingData = <String, dynamic>{
      'sellerUid': user.uid,
      'sellerName': '', // Will be filled from Firestore user doc if online
      'sellerCity': city.trim(),
      'bondNumber': bondNumber.trim(),
      'denomination': denomination,
      'askingPrice': price,
      'listedAt': DateTime.now().toIso8601String(),
      'isActive': true,
      'sellerPhone': phone.trim(),
    };

    // ── STEP 2: SAVE TO LOCAL QUEUE (offline-first) ─────────────────────────
    // The listing is queued on the device immediately.
    // Even with no internet the user gets a success message.
    _saveToLocalQueue(listingData);

    // ── STEP 3: CLOSE THE SELL SCREEN ──────────────────────────────────────
    Get.back();
    Get.snackbar(
      'Listed!',
      ConnectivityService.online
          ? 'Your bond is now listed on the marketplace'
          : 'Saved locally — will sync when you reconnect',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    // ── STEP 4: PUSH TO FIRESTORE NOW (if online) ───────────────────────────
    if (ConnectivityService.online) {
      await _flushPendingListings();
      await loadListings(); // Refresh the list so the new listing appears
    }
  }

  // ── PENDING QUEUE HELPERS ──────────────────────────────────────────────────

  /// Stores a listing in the local GetStorage queue to be synced later.
  void _saveToLocalQueue(Map<String, dynamic> data) {
    final List pending = List.from(
      _local.read<List>(_pendingKey) ?? [],
    );
    pending.add(data);
    _local.write(_pendingKey, pending);
    _logger.i('Queued 1 listing locally. Total pending: ${pending.length}');
  }

  /// Pushes all locally-queued listings to Firestore, then clears the queue.
  /// Called automatically whenever we load listings while online.
  Future<void> _flushPendingListings() async {
    final List pending = List.from(
      _local.read<List>(_pendingKey) ?? [],
    );
    if (pending.isEmpty) return;

    _logger.i('Flushing ${pending.length} pending listings to Firestore…');

    final user = FirebaseAuth.instance.currentUser;

    // Try to get seller name from Firestore user profile
    String sellerName = 'Anonymous';
    if (user != null) {
      try {
        final userDoc =
            await _firestore.collection('customers').doc(user.uid).get();
        final first = userDoc.data()?['firstName'] ?? '';
        final last = userDoc.data()?['lastName'] ?? '';
        final full = '$first $last'.trim();
        if (full.isNotEmpty) sellerName = full;
      } catch (_) {}
    }

    final List failed = []; // Keep failed ones to retry next time

    for (final rawData in pending) {
      try {
        final data = Map<String, dynamic>.from(rawData as Map);
        data['sellerName'] = sellerName;

        // Convert ISO string back to Timestamp for Firestore
        if (data['listedAt'] is String) {
          data['listedAt'] = DateTime.parse(data['listedAt'] as String);
        }

        await _firestore.collection('marketplace').add(data);
      } catch (e) {
        _logger.e('Failed to push listing to Firestore: $e');
        failed.add(rawData); // Retry this one next time
      }
    }

    // Replace pending queue with only the ones that failed
    _local.write(_pendingKey, failed);
  }

  // ── CONTACT SELLER ────────────────────────────────────────────────────────

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

  Future<void> _openWhatsApp(
      String phone, MarketListingModel listing) async {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    final international = cleaned.startsWith('+')
        ? cleaned
        : '+92${cleaned.replaceFirst(RegExp(r'^0'), '')}';

    final message = Uri.encodeComponent(
      'Hi ${listing.sellerName}, I am interested in your '
      'Rs. ${listing.denomination} Prize Bond #${listing.bondNumber} '
      'listed for Rs. ${listing.askingPrice.toStringAsFixed(0)}.',
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

  // ── FILTER ────────────────────────────────────────────────────────────────

  void setFilter(int denomination) {
    filterDenomination.value = denomination;
    loadListings();
  }

  // ── DEMO DATA (shown when offline / Firestore fails) ─────────────────────

  void _loadDemoData() {
    listings.assignAll([
      MarketListingModel(
        id: 'demo1',
        sellerUid: 'demo',
        sellerName: 'Ahmed K.',
        sellerCity: 'Islamabad',
        bondNumber: '887766',
        denomination: 40000,
        askingPrice: 40500,
        listedAt: DateTime(2025, 11, 10),
        sellerPhone: '03001234567',
      ),
      MarketListingModel(
        id: 'demo2',
        sellerUid: 'demo',
        sellerName: 'Sara T.',
        sellerCity: 'Lahore',
        bondNumber: '112233',
        denomination: 25000,
        askingPrice: 25200,
        listedAt: DateTime(2025, 11, 12),
        sellerPhone: '03211234567',
      ),
    ]);
  }
}
