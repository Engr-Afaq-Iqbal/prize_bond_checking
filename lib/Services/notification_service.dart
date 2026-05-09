// lib/Services/notification_service.dart
// Handles FCM push notifications setup and handling
// Stores notifications in Firestore for in-app notification history

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

// Background message handler - must be top-level function (not inside class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background notifications silently
  Logger().i('Background notification: ${message.notification?.title}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // ─── INITIALIZATION ────────────────────────────────────────────────────────
  // Call this once in main.dart after Firebase.initializeApp()

  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission (iOS requires explicit permission)
    await _requestPermission();

    // Handle foreground notifications
    _handleForegroundNotifications();

    // Handle notification click (app opened from notification)
    _handleNotificationClick();

    _logger.i('NotificationService initialized');
  }

  // ─── REQUEST PERMISSION ────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    _logger.i('Notification permission: ${settings.authorizationStatus}');
  }

  // ─── GET & SAVE FCM TOKEN ──────────────────────────────────────────────────

  Future<void> saveTokenToFirestore(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await _firestore.collection('customers').doc(userId).update({
        'fcmToken': token,
      });

      // Listen for token refresh (token can change)
      _messaging.onTokenRefresh.listen((newToken) async {
        await _firestore.collection('customers').doc(userId).update({
          'fcmToken': newToken,
        });
        _logger.i('FCM token refreshed and saved');
      });

      _logger.i('FCM token saved for user: $userId');
    } catch (e) {
      _logger.e('Error saving FCM token: $e');
    }
  }

  // ─── FOREGROUND NOTIFICATIONS ──────────────────────────────────────────────

  void _handleForegroundNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      // Show in-app snackbar/dialog since app is open
      Get.snackbar(
        notification.title ?? 'Prize Bond Update',
        notification.body ?? '',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF1A3C40),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.notifications, color: Colors.white),
      );
    });
  }

  // ─── NOTIFICATION CLICK HANDLER ────────────────────────────────────────────

  void _handleNotificationClick() {
    // App opened from terminated state via notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _navigateFromNotification(message.data);
      }
    });

    // App in background, user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigateFromNotification(message.data);
    });
  }

  // Navigate user based on notification data payload
  void _navigateFromNotification(Map<String, dynamic> data) {
    final type = data['type'];
    if (type == 'draw_result') {
      // Navigate to draw details
      Get.toNamed('/draws');
    } else if (type == 'winner') {
      // Navigate to my bonds screen to see the winning bond
      Get.toNamed('/my-bonds');
    }
  }

  // ─── STORE NOTIFICATION IN FIRESTORE (in-app history) ─────────────────────

  Future<void> storeNotification({
    required String userId,
    required String title,
    required String body,
    required String type, // 'draw_result', 'winner', 'general'
    String? relatedId,    // Draw ID or bond ID
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
      _logger.e('Error storing notification: $e');
    }
  }

  // Get user's notification history
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

  // Mark notification as read
  Future<void> markAsRead(String notifId) async {
    await _firestore
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }
}
