// lib/Services/cloudinary_service.dart
//
// FREE alternative to Firebase Storage for uploading PDF files.
//
// Why Cloudinary?
//   • Free tier: 25 GB storage + 25 GB bandwidth / month.
//   • NO credit card or billing required.
//   • Simple REST API — one POST request to upload, get back a URL.
//   • Uploaded files are publicly accessible via a permanent HTTPS URL.
//
// ─────────────────────────────────────────────────────────────────────────────
// ONE-TIME SETUP (do this before first use):
// ─────────────────────────────────────────────────────────────────────────────
//
//  Step 1 — Create a FREE Cloudinary account
//    → Go to https://cloudinary.com/
//    → Click "Sign Up for Free"  (no credit card needed)
//    → Complete registration
//
//  Step 2 — Note your Cloud Name
//    → After login, your dashboard shows "Cloud Name" in the top-left
//    → It looks like:  dxxxabcyz
//    → Copy it and paste below as  _cloudName
//
//  Step 3 — Create an UNSIGNED Upload Preset
//    → In Cloudinary dashboard → Settings (gear icon) → Upload
//    → Scroll to "Upload presets" → click "Add upload preset"
//    → Set "Signing mode" to  UNSIGNED  (IMPORTANT — signed presets need a secret)
//    → Give it a name, e.g.  prize_bond_pdfs
//    → Click Save
//    → Copy the preset name and paste below as  _uploadPreset
//
//  Step 4 — Replace the placeholder values below and you're done!
//
// ─────────────────────────────────────────────────────────────────────────────
// Firestore document fields saved after upload:
//   pdfUrl        → public HTTPS download link (never expires)
//   pdfName       → original file name selected by admin
//   pdfUploadedAt → ISO-8601 timestamp
//   category      → "draw_result"
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class CloudinaryService {
  // ── Configuration ──────────────────────────────────────────────────────────
  // Replace these two values with your own from the Cloudinary dashboard.
  static const String _cloudName    = 'YOUR_CLOUD_NAME';    // e.g. 'dxxxabcyz'
  static const String _uploadPreset = 'YOUR_UPLOAD_PRESET'; // e.g. 'prize_bond_pdfs'

  final Dio _dio = Dio();
  final Logger _logger = Logger();

  // ── Upload PDF ─────────────────────────────────────────────────────────────
  //
  // Uploads [file] to Cloudinary and returns the public download URL.
  //
  // Parameters:
  //   file        — the PDF file to upload (selected by admin via file_picker)
  //   onProgress  — optional callback receiving progress from 0.0 to 1.0
  //
  // Returns:
  //   String URL on success (e.g. "https://res.cloudinary.com/...")
  //   null on failure
  Future<String?> uploadPdf(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;

      // Cloudinary endpoint for RAW (non-image) files like PDF.
      // For images you'd use /image/upload — for PDF use /raw/upload.
      final uploadUrl =
          'https://api.cloudinary.com/v1_1/$_cloudName/raw/upload';

      // Build multipart form data
      final formData = FormData.fromMap({
        'upload_preset': _uploadPreset,   // must match what you created
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        uploadUrl,
        data: formData,
        onSendProgress: (sent, total) {
          // Report upload progress (0.0 → 1.0) to the caller
          if (total > 0 && onProgress != null) {
            onProgress(sent / total);
          }
        },
        options: Options(
          // Cloudinary returns JSON even without Accept header,
          // but setting this makes Dio parse it automatically.
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Parse JSON response — 'secure_url' is the permanent HTTPS link
        final Map<String, dynamic> data = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        final url = data['secure_url'] as String?;
        _logger.i('Cloudinary upload success: $url');
        return url;
      }

      _logger.e('Cloudinary upload failed. Status: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      _logger.e('Cloudinary network error: ${e.message}');
      return null;
    } catch (e) {
      _logger.e('Cloudinary unexpected error: $e');
      return null;
    }
  }
}
