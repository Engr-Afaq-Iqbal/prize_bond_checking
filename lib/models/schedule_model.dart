// lib/models/schedule_model.dart
// Represents an upcoming prize bond draw schedule

class ScheduleModel {
  final String id;
  final DateTime drawDate;   // Scheduled draw date
  final int denomination;    // Which bond denomination
  final String city;         // Draw location

  ScheduleModel({
    required this.id,
    required this.drawDate,
    required this.denomination,
    required this.city,
  });
}
