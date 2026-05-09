import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

import 'Controllers/AppController/app_controller.dart';
import 'Services/notification_service.dart';
import 'Services/offline_cache_service.dart';
import 'View/PrizeBondApp/prize_bond_app.dart';
import 'firebase_options.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  // await GetStorage.init();
  AppController().initializeController();
  //
  // SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  // ]);

  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Firebase ────────────────────────────────────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── 2. Local Storage (GetStorage for simple key-value) ─────────────────────
  await GetStorage.init();

  // ── 3. Hive (offline draw cache) ───────────────────────────────────────────
  await OfflineCacheService.init();

  // ── 4. Push Notifications ──────────────────────────────────────────────────
  // Register background message handler BEFORE runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    PrizeBondApp(),
  );
}
