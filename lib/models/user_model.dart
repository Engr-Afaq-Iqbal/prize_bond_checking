// lib/Models/user_model.dart
// Represents a user document in Firestore
// Collection: 'customers'

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String role;         // 'admin' or 'normal_user'
  final String status;       // 'active', 'pending', 'suspended'
  final String city;
  final String? fcmToken;    // For push notifications
  final DateTime createdAt;
  final int savedBondsCount; // Cached count for admin stats

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.status,
    required this.city,
    this.fcmToken,
    required this.createdAt,
    this.savedBondsCount = 0,
  });

  String get fullName => '$firstName $lastName';

  bool get isAdmin => role == 'admin';

  factory UserModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return UserModel(
      uid: docId,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'normal_user',
      status: data['status'] ?? 'pending',
      city: data['city'] ?? '',
      fcmToken: data['fcmToken'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      savedBondsCount: data['savedBondsCount'] ?? 0,
    );
  }
}
