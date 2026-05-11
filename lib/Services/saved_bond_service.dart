// lib/Services/saved_bond_service.dart
// Firestore operations for user's saved bonds.
// Also handles auto-check logic when admin uploads a new draw result.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/saved_bond_model.dart';

// Holds winner info returned from autoCheckBondsForDraw
class WinnerInfo {
  final String bondId;
  final String userId;
  final String bondNumber;

  const WinnerInfo({
    required this.bondId,
    required this.userId,
    required this.bondNumber,
  });
}

class SavedBondService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  static const String _collection = 'saved_bonds';

  // ─── FETCH USER'S BONDS ────────────────────────────────────────────────────

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
      final existing = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: bond.userId)
          .where('bondNumber', isEqualTo: bond.bondNumber)
          .where('denomination', isEqualTo: bond.denomination)
          .get();

      if (existing.docs.isNotEmpty) return false; // Already saved

      await _firestore.collection(_collection).add(bond.toFirestore());

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
  //
  // Called after admin uploads new draw results.
  // Returns a list of WinnerInfo for every bond that won, so the caller can
  // send targeted notifications to each winner's userId / FCM token.

  Future<List<WinnerInfo>> autoCheckBondsForDraw({
    required String drawId,
    required int denomination,
    required List<String> winningNumbers,
  }) async {
    final List<WinnerInfo> winners = [];

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('denomination', isEqualTo: denomination)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final bondNumber = data['bondNumber'] as String? ?? '';
        final userId = data['userId'] as String? ?? '';

        if (winningNumbers.contains(bondNumber)) {
          winners.add(WinnerInfo(
            bondId: doc.id,
            userId: userId,
            bondNumber: bondNumber,
          ));

          batch.update(doc.reference, {
            'isWinner': true,
            'winningDrawId': drawId,
          });
        }
      }

      await batch.commit();

      _logger.i(
        'Auto-check complete: ${winners.length} winner(s) found '
        'for denomination Rs.$denomination draw $drawId',
      );
      return winners;
    } catch (e) {
      _logger.e('Auto-check error: $e');
      return [];
    }
  }

}
