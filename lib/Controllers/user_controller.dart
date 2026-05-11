// lib/Controllers/user_controller.dart
//
// Manages the currently logged-in user's profile data.
//
// Responsibilities:
//   1. Cache the user profile in GetStorage so it loads instantly (even offline).
//   2. Detect when a DIFFERENT user logs in and wipe stale local data.
//   3. Fetch the new user's bonds from Firestore and save locally.
//   4. Expose the current user to any widget via `UserController.to.currentUser`.

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../Services/offline_cache_service.dart';
import '../Utils/storage_service.dart';
import '../models/bond_model.dart';
import '../models/user_model.dart';

class UserController extends GetxController {
  // ── Storage keys ───────────────────────────────────────────────────────────
  static const String _userProfileKey = 'user_profile_cache';
  static const String _lastUserIdKey  = 'last_logged_in_uid';

  final GetStorage _box = GetStorage();

  // ── Observable state ───────────────────────────────────────────────────────
  // Widgets wrap this in Obx() to auto-rebuild when the profile loads.
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  // Convenience accessor: UserController.to
  static UserController get to => Get.find<UserController>();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _loadCachedUser(); // Show last-known profile instantly while fetching
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Called right after a successful login.
  ///
  /// [newUid]     — UID of the user who just signed in.
  /// [previousUid] — UID that was stored locally before this login (may be null
  ///                 for first-ever login or after sign-out).
  ///
  /// If [previousUid] differs from [newUid], all cached data for the old user
  /// is wiped before the new user's data is fetched.
  Future<void> fetchAndCacheUser({
    required String newUid,
    String? previousUid,
  }) async {
    // ── Different user → clear previous user's data ──────────────────────────
    if (previousUid != null && previousUid.isNotEmpty && previousUid != newUid) {
      await _clearPreviousUserData();
    }

    // Record who is now logged in
    _box.write(_lastUserIdKey, newUid);

    // ── Fetch from Firestore ──────────────────────────────────────────────────
    try {
      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(newUid)
          .get();

      if (doc.exists) {
        final user = UserModel.fromFirestore(doc.data()!, doc.id);
        currentUser.value = user;
        // Persist to local storage
        _box.write(_userProfileKey, jsonEncode(user.toJson()));

        // If this is a new user, also pull their saved bonds from Firestore
        if (previousUid != newUid) {
          await _fetchAndCacheBonds(newUid);
        }
      }
    } catch (_) {
      // No internet or Firestore error — fall back to whatever is cached
      _loadCachedUser();
    }
  }

  /// Read the UID that was stored before the current login attempt.
  /// AuthController calls this BEFORE updating the stored UID so it can
  /// pass the old value to [fetchAndCacheUser].
  String? get lastLoggedInUid => _box.read<String>(_lastUserIdKey);

  /// Clears the in-memory user and removes the cached profile.
  /// Called from AuthController.signOut().
  void clearUser() {
    currentUser.value = null;
    _box.remove(_userProfileKey);
    // Note: we intentionally keep _lastUserIdKey so we can detect the SAME
    // user logging back in and skip the data-clear step.
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  void _loadCachedUser() {
    final raw = _box.read<String>(_userProfileKey);
    if (raw == null) return;
    try {
      currentUser.value = UserModel.fromJson(jsonDecode(raw));
    } catch (_) {
      // Corrupted cache — ignore
    }
  }

  /// Wipes all local data that belongs to the previous user:
  ///   • Saved bonds (GetStorage)
  ///   • Draw / bond cache (Hive)
  ///   • Cached user profile
  Future<void> _clearPreviousUserData() async {
    StorageService().clearAllBonds();
    await OfflineCacheService().clearAll();
    _box.remove(_userProfileKey);
    currentUser.value = null;
  }

  /// Downloads the new user's saved bonds from Firestore and stores them
  /// locally so they appear in "My Bonds" immediately (and offline).
  Future<void> _fetchAndCacheBonds(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('saved_bonds')
          .where('userId', isEqualTo: uid)
          .get();

      final storage = StorageService();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final bond = BondModel(
          id: doc.id,
          number: data['bondNumber'] ?? '',
          denomination: (data['denomination'] as num?)?.toInt() ?? 750,
          addedDate: data['savedAt'] != null
              ? DateTime.tryParse(data['savedAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
          isWinner: data['isWinner'] ?? false,
        );
        // saveBond skips duplicates based on number + denomination
        storage.saveBond(bond);
      }
    } catch (_) {
      // No internet or Firestore error — bonds from local storage still show
    }
  }
}
