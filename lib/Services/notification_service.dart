// lib/Services/notification_service.dart
//
// Handles notifications for the Prize Bond app:
//   • Displaying local notifications (foreground + background + terminated)
//   • Handling FCM messages when they arrive (future: sent by Firebase Functions)
//   • Saving FCM token to Firestore (Functions will use it later)
//   • Storing and reading notification history in Firestore
//
// Call order:
//   1. NotificationService.initLocalNotifications()  ← in main() before runApp
//   2. FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)
//   3. NotificationService().initialize()             ← after user logs in

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../Config/notification_config.dart';

// ── Background handler — top-level (required by FCM) ─────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.showLocalNotification(
    title: message.notification?.title ?? 'Prize Bond Update',
    body: message.notification?.body ?? '',
    payload: message.data['type'] as String?,
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    NotificationConfig.channelId,
    NotificationConfig.channelName,
    description: NotificationConfig.channelDesc,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  );

  // ── Static init — call ONCE in main() before runApp ───────────────────────

  static Future<void> initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onLocalNotificationTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  @pragma('vm:entry-point')
  static void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload ?? '';
    if (payload == 'draw_result') {
      Get.toNamed('/draws');
    } else if (payload == 'winner') {
      Get.toNamed('/my-bonds');
    }
  }

  // ── Show a local notification ──────────────────────────────────────────────

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      NotificationConfig.channelId,
      NotificationConfig.channelName,
      channelDescription: NotificationConfig.channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  // ── Instance init — call after user logs in ────────────────────────────────

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _requestPermission();
    _handleForegroundMessages();
    _handleNotificationTaps();
    _logger.i('NotificationService initialized');
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    _logger.i('Notification permission: ${settings.authorizationStatus}');
  }

  void _handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      showLocalNotification(
        title: notification.title ?? 'Prize Bond Update',
        body: notification.body ?? '',
        payload: message.data['type'] as String?,
      );

      Get.snackbar(
        notification.title ?? 'Prize Bond Update',
        notification.body ?? '',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF1A3C40),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        icon: const Icon(Icons.notifications, color: Colors.amber),
        margin: const EdgeInsets.all(8),
      );
    });
  }

  void _handleNotificationTaps() {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _navigateFromData(message.data);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigateFromData(message.data);
    });
  }

  void _navigateFromData(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'draw_result':
        Get.toNamed('/draws');
      case 'winner':
        Get.toNamed('/my-bonds');
    }
  }

  // ── Save FCM token to Firestore (Firebase Functions will read it later) ────

  Future<void> saveToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await _firestore.collection('customers').doc(userId).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _messaging.onTokenRefresh.listen((newToken) async {
        await _firestore.collection('customers').doc(userId).update({
          'fcmToken': newToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      });

      _logger.i('FCM token saved for $userId');
    } catch (e) {
      _logger.e('saveToken error: $e');
    }
  }

  // ── Firestore notification history ────────────────────────────────────────

  Future<void> storeNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'relatedId': relatedId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('storeNotification error: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> markAsRead(String notifId) async {
    await _firestore
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }
}
