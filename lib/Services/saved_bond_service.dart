// lib/Services/saved_bond_service.dart
// Firestore operations for user's saved bonds
// Also handles auto-check logic when new draw is uploaded

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../Models/saved_bond_model.dart';

class SavedBondService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  static const String _collection = 'saved_bonds';

  // ─── FETCH USER'S BONDS ────────────────────────────────────────────────────

  // Get all saved bonds for a specific user
  Future<List<SavedBondModel>> getUserBonds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('savedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SavedBondModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      _logger.e('Error fetching saved bonds: $e');
      return [];
    }
  }

  // Real-time stream of user's bonds (auto-updates UI)
  Stream<List<SavedBondModel>> userBondsStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SavedBondModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // ─── SAVE A BOND ──────────────────────────────────────────────────────────

  Future<bool> saveBond(SavedBondModel bond) async {
    try {
      // Check for duplicate first
      final existing = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: bond.userId)
          .where('bondNumber', isEqualTo: bond.bondNumber)
          .where('denomination', isEqualTo: bond.denomination)
          .get();

      if (existing.docs.isNotEmpty) {
        return false; // Already saved
      }

      await _firestore.collection(_collection).add(bond.toFirestore());

      // Increment user's savedBondsCount for admin stats
      await _firestore.collection('customers').doc(bond.userId).update({
        'savedBondsCount': FieldValue.increment(1),
      });

      _logger.i('Bond saved: ${bond.bondNumber}');
      return true;
    } catch (e) {
      _logger.e('Error saving bond: $e');
      return false;
    }
  }

  // ─── DELETE A BOND ─────────────────────────────────────────────────────────

  Future<bool> deleteBond(String bondId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(bondId).delete();

      // Decrement counter
      await _firestore.collection('customers').doc(userId).update({
        'savedBondsCount': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      _logger.e('Error deleting bond: $e');
      return false;
    }
  }

  // ─── AUTO-CHECK BONDS ──────────────────────────────────────────────────────
  // Called after admin uploads new draw results
  // Checks all user bonds against the new draw's winning numbers
  // Returns list of bond IDs that won

  Future<List<String>> autoCheckBondsForDraw({
    required String drawId,
    required int denomination,
    required List<String> winningNumbers,
  }) async {
    final List<String> winnerBondIds = [];

    try {
      // Get all bonds matching this denomination
      final snapshot = await _firestore
          .collection(_collection)
          .where('denomination', isEqualTo: denomination)
          .get();

      // Check each bond
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        final bondNumber = doc.data()['bondNumber'] as String;

        if (winningNumbers.contains(bondNumber)) {
          // This bond won!
          winnerBondIds.add(doc.id);

          // Update bond status in Firestore
          batch.update(doc.reference, {
            'isWinner': true,
            'winningDrawId': drawId,
          });
        }
      }

      // Commit all updates at once
      await batch.commit();

      _logger.i('Auto-check complete. ${winnerBondIds.length} winners found.');
      return winnerBondIds;
    } catch (e) {
      _logger.e('Auto-check error: $e');
      return [];
    }
  }
}
