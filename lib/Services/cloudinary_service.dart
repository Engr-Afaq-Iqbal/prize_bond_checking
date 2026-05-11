// lib/Services/cloudinary_service.dart
//
// Uploads PDFs to Cloudinary (free tier: 25 GB storage + 25 GB bandwidth/month).
// No credit card or billing required.
//
// ─────────────────────────────────────────────────────────────────────────────
// ONE-TIME SETUP — complete BEFORE first use:
// ─────────────────────────────────────────────────────────────────────────────
//
//  Step 1 — Create a FREE Cloudinary account
//    → https://cloudinary.com → "Sign Up for Free" (no credit card needed)
//
//  Step 2 — Get your Cloud Name
//    → Dashboard (top-left) shows "Cloud Name", e.g. dxxxabcyz
//    → Paste it below as _cloudName
//
//  Step 3 — Create an UNSIGNED Upload Preset
//    → Settings (gear icon) → Upload → "Upload presets" → "Add upload preset"
//    → Set Signing mode = UNSIGNED  ← CRITICAL (signed presets = 401 error)
//    → Give it a name, e.g. prize_bond_pdfs
//    → Under "Allowed formats" add: pdf  (prevents other types being uploaded)
//    → Save → paste the preset name below as _uploadPreset
//
//  Step 4 — Replace the placeholder values below and you are done.
//
// ─────────────────────────────────────────────────────────────────────────────
// Common 401 causes:
//   • _cloudName or _uploadPreset are still 'YOUR_...' placeholders
//   • Upload preset Signing mode is SIGNED (must be UNSIGNED)
//   • Upload preset is disabled / deleted
//   • Typo in cloud name (case-sensitive)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class CloudinaryService {
  // ── ⚙️  Configuration — replace these two values ──────────────────────────
  static const String _cloudName = 'docsfstyc'; // e.g. 'dxxxabcyz'
  static const String _uploadPreset =
      'prize_bond_pdfs'; // e.g. 'prize_bond_pdfs'
  // ──────────────────────────────────────────────────────────────────────────

  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 90);

  final Logger _logger = Logger();

  bool get _isConfigured =>
      _cloudName != 'YOUR_CLOUD_NAME' &&
      _uploadPreset != 'YOUR_UPLOAD_PRESET' &&
      _cloudName.isNotEmpty &&
      _uploadPreset.isNotEmpty;

  // ── Upload PDF ─────────────────────────────────────────────────────────────
  //
  // Returns the public HTTPS download URL on success, null on failure.
  // [onProgress] receives values from 0.0 to 1.0 as upload progresses.
  //
  Future<String?> uploadPdf(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    // Early exit with a clear error if credentials were never set
    if (!_isConfigured) {
      _logger.e(
        'Cloudinary not configured!\n'
        '→ Open lib/Services/cloudinary_service.dart\n'
        '→ Replace _cloudName with your cloud name (e.g. dxxxabcyz)\n'
        '→ Replace _uploadPreset with your UNSIGNED preset name\n'
        '→ Make sure the preset Signing Mode = UNSIGNED in Cloudinary dashboard',
      );
      return null;
    }

    final fileName = file.path.split(Platform.pathSeparator).last;

    // Use /raw/upload endpoint for non-image files (PDFs, ZIPs, etc.)
    // /image/upload would reject PDF with 400 Bad Request
    final uploadUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/raw/upload';

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        _logger
            .i('Cloudinary upload attempt $attempt/$_maxRetries — $fileName');

        final dio = Dio(BaseOptions(
          connectTimeout: _timeout,
          receiveTimeout: _timeout,
          sendTimeout: _timeout,
        ));

        // Explicitly set content type to application/pdf so Cloudinary
        // stores and serves it correctly (default would be octet-stream).
        final formData = FormData.fromMap({
          'upload_preset': _uploadPreset,
          'resource_type': 'raw',
          'file': await MultipartFile.fromFile(
            file.path,
            filename: fileName,
            contentType: DioMediaType('application', 'pdf'),
          ),
        });

        final response = await dio.post(
          uploadUrl,
          data: formData,
          onSendProgress: (sent, total) {
            if (total > 0 && onProgress != null) {
              onProgress(sent / total);
            }
          },
          options: Options(responseType: ResponseType.json),
        );

        if (response.statusCode == 200 && response.data != null) {
          final Map<String, dynamic> data = response.data is String
              ? jsonDecode(response.data as String) as Map<String, dynamic>
              : response.data as Map<String, dynamic>;

          final url = data['secure_url'] as String?;
          if (url != null && url.isNotEmpty) {
            _logger.i('Cloudinary upload success: $url');
            return url;
          }
          _logger.e('Cloudinary: secure_url missing in response: $data');
          return null;
        }

        _logger.e(
          'Cloudinary unexpected status ${response.statusCode}: ${response.data}',
        );
        return null;
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;

        if (statusCode == 401) {
          // Auth failure — retrying will not help
          _logger.e(
            'Cloudinary 401 Unauthorized!\n'
            'Checklist:\n'
            '  ✗ Cloud Name "$_cloudName" — is this correct?\n'
            '  ✗ Upload Preset "$_uploadPreset" — does it exist?\n'
            '  ✗ Preset Signing Mode MUST be UNSIGNED '
            '(Settings → Upload → Upload presets)\n'
            '  ✗ Preset must not be disabled\n'
            'Response body: ${e.response?.data}',
          );
          return null;
        }

        if (statusCode == 400) {
          _logger.e(
            'Cloudinary 400 Bad Request: ${e.response?.data}\n'
            'Likely cause: upload_preset name typo or preset does not allow PDFs.',
          );
          return null;
        }

        // Network / timeout errors — retry
        if (attempt < _maxRetries) {
          final delay = Duration(seconds: attempt * 2);
          _logger.w(
            'Cloudinary attempt $attempt failed (${e.message}). '
            'Retrying in ${delay.inSeconds}s…',
          );
          await Future.delayed(delay);
          continue;
        }

        _logger.e(
          'Cloudinary upload failed after $_maxRetries attempts: ${e.message}',
        );
        return null;
      } catch (e) {
        _logger.e('Cloudinary unexpected error: $e');
        return null;
      }
    }
    return null;
  }
}
