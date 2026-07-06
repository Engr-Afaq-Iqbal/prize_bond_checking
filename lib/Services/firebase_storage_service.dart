// lib/Services/firebase_storage_service.dart
// Firebase Storage operations for draw result PDFs.
// Upload path: draw_results/{denomination}/{drawNumber}.pdf

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

// Result of a successful PDF upload.
class PdfUploadResult {
  final String downloadUrl;
  final String storagePath;
  final int fileSize;

  PdfUploadResult({
    required this.downloadUrl,
    required this.storagePath,
    required this.fileSize,
  });
}

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _logger = Logger();

  static const String _rootFolder = 'draw_results';

  // Upload a draw result PDF. Returns null on failure so the caller can
  // decide whether to publish the draw without a PDF.
  Future<PdfUploadResult?> uploadDrawPdf({
    required File file,
    required int denomination,
    required int drawNumber,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final storagePath = '$_rootFolder/$denomination/$drawNumber.pdf';
      final ref = _storage.ref(storagePath);

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'application/pdf'),
      );

      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0 && onProgress != null) {
          onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return PdfUploadResult(
        downloadUrl: downloadUrl,
        storagePath: storagePath,
        fileSize: file.lengthSync(),
      );
    } catch (e) {
      _logger.e('Error uploading draw PDF: $e');
      return null;
    }
  }

  // Delete a previously uploaded PDF. Safe to call on a missing object.
  Future<void> deleteDrawPdf(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } catch (e) {
      _logger.e('Error deleting draw PDF ($storagePath): $e');
    }
  }
}
