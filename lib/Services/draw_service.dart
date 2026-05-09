// lib/Services/draw_service.dart
// All Firestore + Firebase Storage operations for draw results
// Used by both Admin (upload) and User (read) controllers

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import '../Models/draw_model.dart';

class DrawService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
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

  // Upload PDF to Firebase Storage and return download URL
  Future<String?> uploadPdf(File pdfFile, String drawId) async {
    try {
      final ref = _storage.ref('draw_pdfs/$drawId.pdf');
      final uploadTask = ref.putFile(pdfFile);

      // Track upload progress (caller can listen to this)
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      _logger.i('PDF uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _logger.e('PDF upload error: $e');
      return null;
    }
  }

  // Upload task with progress (for progress bar in admin UI)
  UploadTask? uploadPdfWithProgress(File pdfFile, String drawId) {
    try {
      final ref = _storage.ref('draw_pdfs/$drawId.pdf');
      return ref.putFile(pdfFile);
    } catch (e) {
      _logger.e('Error starting upload: $e');
      return null;
    }
  }

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

  // Delete a draw
  Future<bool> deleteDraw(String drawId) async {
    try {
      // Delete PDF from storage if exists
      try {
        await _storage.ref('draw_pdfs/$drawId.pdf').delete();
      } catch (_) {} // Ignore if no PDF

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
