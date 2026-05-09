// lib/Models/saved_bond_model.dart
// Represents a bond saved by a logged-in user
// Stored in Firestore: 'saved_bonds' collection (subcollection under user)

class SavedBondModel {
  final String id;           // Firestore document ID
  final String userId;       // Owner's UID
  final String bondNumber;   // The bond number
  final int denomination;    // Bond denomination
  final DateTime savedAt;    // When user saved it
  bool isWinner;             // Updated when draw result is checked
  String? winningDrawId;     // Which draw this bond won in (if any)

  SavedBondModel({
    required this.id,
    required this.userId,
    required this.bondNumber,
    required this.denomination,
    required this.savedAt,
    this.isWinner = false,
    this.winningDrawId,
  });

  factory SavedBondModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return SavedBondModel(
      id: docId,
      userId: data['userId'] ?? '',
      bondNumber: data['bondNumber'] ?? '',
      denomination: data['denomination'] ?? 0,
      savedAt: (data['savedAt'] as dynamic).toDate(),
      isWinner: data['isWinner'] ?? false,
      winningDrawId: data['winningDrawId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'bondNumber': bondNumber,
      'denomination': denomination,
      'savedAt': savedAt,
      'isWinner': isWinner,
      'winningDrawId': winningDrawId,
    };
  }

  // For local offline storage
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'userId': userId,
      'bondNumber': bondNumber,
      'denomination': denomination,
      'savedAt': savedAt.toIso8601String(),
      'isWinner': isWinner,
      'winningDrawId': winningDrawId,
    };
  }

  factory SavedBondModel.fromLocalJson(Map<String, dynamic> json) {
    return SavedBondModel(
      id: json['id'],
      userId: json['userId'],
      bondNumber: json['bondNumber'],
      denomination: json['denomination'],
      savedAt: DateTime.parse(json['savedAt']),
      isWinner: json['isWinner'] ?? false,
      winningDrawId: json['winningDrawId'],
    );
  }
}
