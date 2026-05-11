// lib/main.dart
// App entry point — initializes all services in the correct order

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

import 'Controllers/AppController/app_controller.dart';
import 'Services/notification_service.dart';
import 'Services/offline_cache_service.dart';
import 'View/PrizeBondApp/prize_bond_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Step 1: Firebase (Auth + Firestore cloud database) ─────────────────────
  await Firebase.initializeApp();

  // ── Step 2: GetStorage (simple key-value local storage for bonds/settings) ──
  await GetStorage.init();

  // ── Step 3: Hive (offline draw cache) ──────────────────────────────────────
  // CRITICAL: Must come BEFORE AppController because DrawController reads
  // from Hive immediately when it is created. If Hive is not open yet,
  // you get "HiveError: Box not found" crash.
  await OfflineCacheService.init();

  // ── Step 4: Background push notification handler (must be before runApp) ────
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ── Step 5: Register all GetX controllers (Hive is ready now) ──────────────
  AppController().initializeController();

  // Lock the app to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(PrizeBondApp());
}
