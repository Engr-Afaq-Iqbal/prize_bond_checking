// lib/utils/storage_service.dart
// Handles all local data persistence using GetStorage
// Think of this as a simple key-value database stored on the device

import 'package:get_storage/get_storage.dart';
import '../models/bond_model.dart';
import '../models/marketplace_model.dart';

class StorageService {
  // Storage keys - these are like table names in a database
  static const String _bondsKey = 'saved_bonds';
  static const String _marketKey = 'marketplace_listings';
  static const String _notifKey = 'notifications_enabled';
  static const String _autoCheckKey = 'auto_check_enabled';
  static const String _languageKey = 'language';

  final GetStorage _box = GetStorage();

  // ─── BONDS ────────────────────────────────────────────────────────────────

  // Get all saved bonds from storage
  List<BondModel> getSavedBonds() {
    final data = _box.read<List>(_bondsKey) ?? [];
    return data.map((e) => BondModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  // Save a new bond to storage
  void saveBond(BondModel bond) {
    final bonds = getSavedBonds();
    bonds.add(bond);
    _box.write(_bondsKey, bonds.map((b) => b.toJson()).toList());
  }

  // Delete a bond by its ID
  void deleteBond(String id) {
    final bonds = getSavedBonds();
    bonds.removeWhere((b) => b.id == id);
    _box.write(_bondsKey, bonds.map((b) => b.toJson()).toList());
  }

  // Update all bonds (used when updating winner status)
  void updateBonds(List<BondModel> bonds) {
    _box.write(_bondsKey, bonds.map((b) => b.toJson()).toList());
  }

  // Delete all saved bonds (used in Settings → Clear Bonds)
  void clearAllBonds() {
    _box.write(_bondsKey, []);
  }

  // ─── MARKETPLACE ──────────────────────────────────────────────────────────

  // Get marketplace listings (user's own listings only)
  List<MarketplaceModel> getMarketListings() {
    final data = _box.read<List>(_marketKey) ?? [];
    return data.map((e) => MarketplaceModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  // Add a new listing to marketplace
  void addMarketListing(MarketplaceModel listing) {
    final listings = getMarketListings();
    listings.add(listing);
    _box.write(_marketKey, listings.map((l) => l.toJson()).toList());
  }

  // ─── SETTINGS ─────────────────────────────────────────────────────────────

  bool getNotificationsEnabled() => _box.read<bool>(_notifKey) ?? true;
  void setNotificationsEnabled(bool val) => _box.write(_notifKey, val);

  bool getAutoCheckEnabled() => _box.read<bool>(_autoCheckKey) ?? true;
  void setAutoCheckEnabled(bool val) => _box.write(_autoCheckKey, val);

  String getLanguage() => _box.read<String>(_languageKey) ?? 'English';
  void setLanguage(String lang) => _box.write(_languageKey, lang);
}
