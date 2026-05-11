// lib/Services/offline_cache_service.dart
// Handles all local data storage using Hive (fast NoSQL local DB)
// This powers the offline feature: user can check bonds without internet

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../models/draw_model.dart';
import '../models/saved_bond_model.dart';

class OfflineCacheService {
  static const String _drawsBoxName = 'draws_cache';
  static const String _bondsBoxName = 'saved_bonds_cache';
  static const String _settingsBoxName = 'app_settings';

  final Logger _logger = Logger();

  // ─── INITIALIZATION ────────────────────────────────────────────────────────
  // Call this in main() before runApp()
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_drawsBoxName);
    await Hive.openBox(_bondsBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  // ─── DRAW RESULTS CACHE ────────────────────────────────────────────────────

  // Save list of draws to local storage
  Future<void> cacheDraws(List<DrawModel> draws) async {
    try {
      final box = Hive.box(_drawsBoxName);
      // Store as JSON string map: key = draw ID
      for (final draw in draws) {
        await box.put(draw.id, jsonEncode(draw.toLocalJson()));
      }
      // Save timestamp of last sync
      await setLastSyncTime(DateTime.now());
      _logger.i('Cached ${draws.length} draws locally');
    } catch (e) {
      _logger.e('Error caching draws: $e');
    }
  }

  // Update a single draw in cache (e.g., after PDF download)
  Future<void> updateCachedDraw(DrawModel draw) async {
    try {
      final box = Hive.box(_drawsBoxName);
      await box.put(draw.id, jsonEncode(draw.toLocalJson()));
    } catch (e) {
      _logger.e('Error updating cached draw: $e');
    }
  }

  // Get all cached draws
  List<DrawModel> getCachedDraws() {
    try {
      final box = Hive.box(_drawsBoxName);
      final List<DrawModel> draws = [];

      for (final key in box.keys) {
        try {
          final json = jsonDecode(box.get(key));
          draws.add(DrawModel.fromLocalJson(json));
        } catch (e) {
          // Skip corrupted entries
          _logger.w('Skipping corrupted draw entry: $key');
        }
      }

      // Sort by draw date, newest first
      draws.sort((a, b) => b.drawDate.compareTo(a.drawDate));
      return draws;
    } catch (e) {
      _logger.e('Error reading cached draws: $e');
      return [];
    }
  }

  // Get winning numbers for a specific denomination (for offline check)
  List<String> getWinningNumbers(int denomination) {
    final draws = getCachedDraws();
    final List<String> allNumbers = [];
    for (final draw in draws) {
      if (draw.denomination == denomination) {
        allNumbers.addAll(draw.winningNumbers);
      }
    }
    return allNumbers;
  }

  // Check if a bond number won in any cached draw of given denomination
  DrawModel? checkBondOffline(String number, int denomination) {
    final draws = getCachedDraws();
    for (final draw in draws) {
      if (draw.denomination == denomination &&
          draw.winningNumbers.contains(number.trim())) {
        return draw; // Return the winning draw
      }
    }
    return null; // Not a winner
  }

  bool hasAnyData() {
    final box = Hive.box(_drawsBoxName);
    return box.isNotEmpty;
  }

  // ─── SAVED BONDS CACHE ─────────────────────────────────────────────────────

  Future<void> cacheSavedBonds(List<SavedBondModel> bonds) async {
    try {
      final box = Hive.box(_bondsBoxName);
      await box.clear(); // Replace with fresh data
      for (final bond in bonds) {
        await box.put(bond.id, jsonEncode(bond.toLocalJson()));
      }
    } catch (e) {
      _logger.e('Error caching saved bonds: $e');
    }
  }

  List<SavedBondModel> getCachedSavedBonds() {
    try {
      final box = Hive.box(_bondsBoxName);
      final List<SavedBondModel> bonds = [];
      for (final key in box.keys) {
        try {
          final json = jsonDecode(box.get(key));
          bonds.add(SavedBondModel.fromLocalJson(json));
        } catch (_) {}
      }
      return bonds;
    } catch (e) {
      return [];
    }
  }

  // ─── SETTINGS & METADATA ──────────────────────────────────────────────────

  Future<void> setLastSyncTime(DateTime time) async {
    final box = Hive.box(_settingsBoxName);
    await box.put('lastSync', time.toIso8601String());
  }

  DateTime? getLastSyncTime() {
    final box = Hive.box(_settingsBoxName);
    final raw = box.get('lastSync');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLocalPdfPath(String drawId, String path) async {
    final box = Hive.box(_settingsBoxName);
    await box.put('pdf_$drawId', path);
  }

  String? getLocalPdfPath(String drawId) {
    final box = Hive.box(_settingsBoxName);
    return box.get('pdf_$drawId');
  }

  // ─── CLEAR ALL (used in settings) ─────────────────────────────────────────
  Future<void> clearAll() async {
    await Hive.box(_drawsBoxName).clear();
    await Hive.box(_bondsBoxName).clear();
    await Hive.box(_settingsBoxName).clear();
  }
}
