// lib/models/draw_result_model.dart
// Represents a prize bond draw result

class DrawResultModel {
  final String id;
  final int denomination;   // Bond denomination (e.g., 750)
  final DateTime drawDate;  // Date of the draw
  final String city;        // City where draw was held
  final List<String> winningNumbers; // List of winning bond numbers

  DrawResultModel({
    required this.id,
    required this.denomination,
    required this.drawDate,
    required this.city,
    required this.winningNumbers,
  });
}
