// lib/Config/notification_config.dart
// Notification channel constants shared across the app.
// FCM sending will be added later via Firebase Functions.

class NotificationConfig {
  static const String channelId   = 'prize_bond_channel';
  static const String channelName = 'Prize Bond Notifications';
  static const String channelDesc = 'Draw results, winning bonds, and app alerts';
}
