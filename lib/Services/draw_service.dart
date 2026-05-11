// lib/Services/draw_service.dart
// Firestore operations for draw results.
// PDF uploads now go through CloudinaryService (free, no billing needed).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/draw_model.dart';

class DrawService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Firestore collection name
  static const String _collection = 'draws';

  // ─── READ OPERATIONS ────────────────────────────────────────────────────────

  // Fetch latest draws (paginated) - used on Home screen
  Future<List<DrawModel>> getLatestDraws({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('drawDate', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => DrawModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      _logger.e('Error fetching draws: $e');
      return [];
    }
  }

  // Real-time stream of draws - for live updates
  Stream<List<DrawModel>> drawsStream({int limit = 20}) {
    return _firestore
        .collection(_collection)
        .orderBy('drawDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DrawModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Fetch draws with filter by denomination
  Future<List<DrawModel>> getDrawsByDenomination(int denomination) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('denomination', isEqualTo: denomination)
          .orderBy('drawDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DrawModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      _logger.e('Error filtering draws: $e');
      return [];
    }
  }

  // ─── ADMIN: CREATE DRAW ────────────────────────────────────────────────────

  // Create a new draw document in Firestore
  Future<String?> createDraw(DrawModel draw) async {
    try {
      // Use add() to auto-generate ID, or set() with custom ID
      final docRef = await _firestore
          .collection(_collection)
          .add(draw.toFirestore());

      _logger.i('Draw created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Error creating draw: $e');
      return null;
    }
  }

  // Update existing draw (e.g., add PDF URL after upload completes)
  Future<bool> updateDraw(String drawId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(drawId).update(data);
      return true;
    } catch (e) {
      _logger.e('Error updating draw: $e');
      return false;
    }
  }

  // Delete a draw (Firestore document only).
  // Note: Cloudinary files are managed from the Cloudinary dashboard.
  Future<bool> deleteDraw(String drawId) async {
    try {
      await _firestore.collection(_collection).doc(drawId).delete();
      _logger.i('Draw deleted: $drawId');
      return true;
    } catch (e) {
      _logger.e('Error deleting draw: $e');
      return false;
    }
  }

  // ─── ADMIN STATS ──────────────────────────────────────────────────────────

  Future<int> getTotalUsersCount() async {
    try {
      final snapshot = await _firestore
          .collection('customers')
          .where('role', isEqualTo: 'normal_user')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getTotalSavedBondsCount() async {
    try {
      final snapshot = await _firestore
          .collection('saved_bonds')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getTotalDrawsCount() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
