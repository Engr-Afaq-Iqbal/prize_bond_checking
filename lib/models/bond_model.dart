// lib/models/bond_model.dart
// Represents a saved prize bond owned by the user

class BondModel {
  final String id;           // Unique ID for the bond
  final String number;       // Bond number (e.g., "123456")
  final int denomination;    // Bond value in Rs. (e.g., 750)
  final DateTime addedDate;  // When user saved this bond
  bool isWinner;             // Whether this bond won in latest draw

  BondModel({
    required this.id,
    required this.number,
    required this.denomination,
    required this.addedDate,
    this.isWinner = false,
  });

  // Convert to Map for storage in GetStorage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'denomination': denomination,
      'addedDate': addedDate.toIso8601String(),
      'isWinner': isWinner,
    };
  }

  // Create from stored Map
  factory BondModel.fromJson(Map<String, dynamic> json) {
    return BondModel(
      id: json['id'],
      number: json['number'],
      denomination: json['denomination'],
      addedDate: DateTime.parse(json['addedDate']),
      isWinner: json['isWinner'] ?? false,
    );
  }
}
