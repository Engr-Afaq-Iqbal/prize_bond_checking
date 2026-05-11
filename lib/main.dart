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

  // ── Step 1: Firebase (Auth + Firestore) ────────────────────────────────────
  await Firebase.initializeApp();

  // ── Step 2: GetStorage (key-value local storage) ───────────────────────────
  await GetStorage.init();

  // ── Step 3: Hive (offline draw cache) ─────────────────────────────────────
  // MUST come before AppController because DrawController reads Hive on init.
  await OfflineCacheService.init();

  // ── Step 4: Local notifications (must be before runApp) ───────────────────
  await NotificationService.initLocalNotifications();

  // ── Step 5: FCM background handler (must be top-level, before runApp) ──────
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ── Step 6: Register all GetX controllers ─────────────────────────────────
  AppController().initializeController();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(PrizeBondApp());
}
