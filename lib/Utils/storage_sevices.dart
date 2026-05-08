import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '/Config/app_config.dart';

class AppStorage {
  static final box = GetStorage();

  // static final boxAppSettings = GetStorage('appSettings');

  static final String _appNameForKey = AppConfig.appName.removeAllWhitespace;
  static final String _userDataKey = "${_appNameForKey}UserData";

  static final String _onBoardingStorageKey = "${_appNameForKey}OnBoarding";

  // -------------------------------------------------------------------
  // Core Storage Methods (Encrypted)
  // -------------------------------------------------------------------
  static Future<void> clearKeyData(String key) async {
    await box.remove(key);
  }

  static Future<void> _write(String key, dynamic value) async {
    final plainText = jsonEncode(value);
    await box.write(key, plainText);
  }

  // static T? _read<T>(String key) {
  //   final data = box.read(key);
  //   if (data == null) return null;
  //   try {
  //     final decryptedFuture = _decrypt(data);
  //     // Since _decrypt is async, we cannot await inside sync function.
  //     // So we convert _read into a sync wrapper that returns null-safe result.
  //     throw 'Use _readAsync for async decryption'; // just a guard
  //   } catch (_) {
  //     return null;
  //   }
  // }

  static Future<T?> _readAsync<T>(String key) async {
    final data = box.read(key);
    if (data == null) return null;
    return jsonDecode(data) as T;
  }

  static bool _storageHasData(String key) => box.hasData(key);

  /// User Data
  static bool isStorageHasUserData() => _storageHasData(_userDataKey);

  static Future<void> setUserData(String res) async =>
      await _write(_userDataKey, res);

  static Future<String?> getUserData() async {
    try {
      final jsonString = await _readAsync<String>(_userDataKey);

      if (jsonString == null || jsonString.isEmpty) return null;
      return jsonString;
    } catch (e) {
      // logger.e('User token Storage Error: $e');
      return null;
    }
  }

  static Future<void> clearUserData() async => clearKeyData(_userDataKey);

  static bool isStorageHasOnBoardingData() =>
      _storageHasData(_onBoardingStorageKey);

  static Future<void> setOnBoardingData(String res) async =>
      await _write(_onBoardingStorageKey, res);

  static Future<String?> getOnBoardingData() async {
    try {
      final jsonString = await _readAsync<String>(_onBoardingStorageKey);

      if (jsonString == null || jsonString.isEmpty) return null;
      return jsonString;
    } catch (e) {
      // logger.e('User token Storage Error: $e');
      return null;
    }
  }

  static Future<void> clearOnBoardingData() async =>
      clearKeyData(_onBoardingStorageKey);
}
