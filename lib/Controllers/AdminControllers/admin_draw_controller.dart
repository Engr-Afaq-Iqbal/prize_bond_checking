// lib/Controllers/AdminControllers/admin_draw_controller.dart
//
// Admin controller — creates draw results and uploads PDFs to Firebase Storage.
//
// Flow when admin taps "Publish":
//   1. Validate form fields
//   2. Upload PDF to Firebase Storage (if selected)
//      → draw_results/{denomination}/{drawNumber}.pdf
//   3. Create Firestore document in 'draws' collection
//   4. Auto-check all saved user bonds → mark winners (isWinner: true)
//      Note: Firebase Functions also does this and sends push notifications
//   5. Refresh admin dashboard data
//
// Push notifications are sent automatically by Firebase Functions
// (onNewDraw trigger) — no code needed here for that.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../../models/draw_model.dart';
import '../../Services/draw_service.dart';
import '../../Services/firebase_storage_service.dart';
import '../../Services/saved_bond_service.dart';
import '../../Services/offline_cache_service.dart';

class AdminDrawController extends GetxController {
  final DrawService _drawService = DrawService();
  final SavedBondService _bondService = SavedBondService();
  final OfflineCacheService _cache = OfflineCacheService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final Logger _logger = Logger();

  // ── Form controllers ───────────────────────────────────────────────────────
  final TextEditingController drawNumberCtrl = TextEditingController();
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController winningNumbersCtrl = TextEditingController();
  final RxInt selectedDenomination = 750.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  // ── Observable state ───────────────────────────────────────────────────────
  final RxList<DrawModel> allDraws = <DrawModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxString uploadStatusLabel = ''.obs;

  // PDF picker state
  final Rx<File?> selectedPdf = Rx<File?>(null);
  final RxString pdfName = ''.obs;
  final RxString pdfSizeLabel = ''.obs;

  // Admin stats
  final RxInt totalUsers = 0.obs;
  final RxInt totalSavedBonds = 0.obs;
  final RxInt totalDraws = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadDraws();
    loadStats();
  }

  @override
  void onClose() {
    drawNumberCtrl.dispose();
    cityCtrl.dispose();
    winningNumbersCtrl.dispose();
    super.onClose();
  }

  // ─── LOAD DATA ─────────────────────────────────────────────────────────────

  Future<void> loadDraws() async {
    isLoading.value = true;
    final draws = await _drawService.getLatestDraws(limit: 50);
    allDraws.assignAll(draws);
    isLoading.value = false;
  }

  Future<void> loadStats() async {
    totalUsers.value = await _drawService.getTotalUsersCount();
    totalSavedBonds.value = await _drawService.getTotalSavedBondsCount();
    totalDraws.value = await _drawService.getTotalDrawsCount();
  }

  // ─── PDF PICKER ────────────────────────────────────────────────────────────

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    selectedPdf.value = file;
    pdfName.value = result.files.single.name;

    final bytes = file.lengthSync();
    pdfSizeLabel.value = bytes < 1024 * 1024
        ? '${(bytes / 1024).toStringAsFixed(1)} KB'
        : '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  void clearPdf() {
    selectedPdf.value = null;
    pdfName.value = '';
    pdfSizeLabel.value = '';
  }

  // ─── CREATE DRAW ───────────────────────────────────────────────────────────

  Future<void> createDraw() async {
    if (!_validateForm()) return;

    final winningNumbers = _parseWinningNumbers();
    if (winningNumbers == null) return;

    isUploading.value = true;
    uploadProgress.value = 0;
    uploadStatusLabel.value = 'Preparing…';

    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final denomination = selectedDenomination.value;
      final drawNumber = int.tryParse(drawNumberCtrl.text.trim()) ?? 0;

      // ── Step 1: Upload PDF to Firebase Storage (optional) ──────────────────
      String? pdfUrl;
      String? pdfStoragePath;
      int? pdfFileSize;

      if (selectedPdf.value != null) {
        uploadStatusLabel.value = 'Uploading PDF…';

        final result = await _storageService.uploadDrawPdf(
          file: selectedPdf.value!,
          denomination: denomination,
          drawNumber: drawNumber,
          onProgress: (p) {
            // PDF upload takes 0% → 50% of total progress
            uploadProgress.value = p * 0.50;
          },
        );

        if (result != null) {
          pdfUrl = result.downloadUrl;
          pdfStoragePath = result.storagePath;
          pdfFileSize = result.fileSize;
          _logger.i('PDF uploaded: $pdfUrl');
        } else {
          // Upload failed — ask admin whether to continue without PDF
          final proceed = await _confirmProceedWithoutPdf();
          if (!proceed) {
            isUploading.value = false;
            uploadStatusLabel.value = '';
            return;
          }
        }
      }

      uploadProgress.value = 0.55;
      uploadStatusLabel.value = 'Saving draw…';

      // ── Step 2: Create Firestore draw document ─────────────────────────────
      final newDraw = DrawModel(
        id: '',
        denomination: denomination,
        drawNumber: drawNumber,
        drawDate: selectedDate.value,
        city: cityCtrl.text.trim(),
        winningNumbers: winningNumbers,
        pdfUrl: pdfUrl,
        pdfName: pdfName.value.isEmpty ? null : pdfName.value,
        pdfUploadedAt: pdfUrl != null ? DateTime.now() : null,
        pdfStoragePath: pdfStoragePath,
        pdfFileSize: pdfFileSize,
        createdAt: DateTime.now(),
        uploadedBy: adminUid,
      );

      final drawId = await _drawService.createDraw(newDraw);
      if (drawId == null) throw Exception('Failed to create draw in Firestore');

      uploadProgress.value = 0.65;

      // ── Step 3: Auto-check all saved bonds → mark winners ──────────────────
      // Firebase Functions (onNewDraw) handles push notifications independently.
      uploadStatusLabel.value = 'Checking bonds…';
      final winners = await _bondService.autoCheckBondsForDraw(
        drawId: drawId,
        denomination: denomination,
        winningNumbers: winningNumbers,
      );
      uploadProgress.value = 0.85;

      // ── Step 4: Refresh local data ─────────────────────────────────────────
      uploadStatusLabel.value = 'Finishing up…';
      await loadDraws();
      await loadStats();
      await _cache.cacheDraws(allDraws.toList());

      uploadProgress.value = 1.0;
      isUploading.value = false;
      uploadStatusLabel.value = '';

      final pdfMsg = pdfUrl != null ? ' PDF attached.' : '';
      Get.snackbar(
        'Draw Published!',
        'Draw #$drawNumber published.$pdfMsg '
            '${winners.length} winner(s) found.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      _resetForm();
      Get.back();
    } catch (e) {
      _logger.e('createDraw error: $e');
      isUploading.value = false;
      uploadStatusLabel.value = '';
      Get.snackbar(
        'Upload Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  // ─── DELETE DRAW ───────────────────────────────────────────────────────────

  void confirmDeleteDraw(DrawModel draw) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Draw'),
      content: Text(
        'Delete Draw #${draw.drawNumber} (Rs. ${draw.denomination})?\n'
        'This also removes the uploaded PDF. This cannot be undone.',
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Get.back();
            // Delete PDF from Storage first (if exists)
            if (draw.pdfStoragePath != null &&
                draw.pdfStoragePath!.isNotEmpty) {
              await _storageService.deleteDrawPdf(draw.pdfStoragePath!);
            }
            await _drawService.deleteDraw(draw.id);
            allDraws.removeWhere((d) => d.id == draw.id);
            totalDraws.value = (totalDraws.value - 1).clamp(0, 999999);
            Get.snackbar('Deleted', 'Draw removed successfully.',
                snackPosition: SnackPosition.BOTTOM);
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ));
  }

  // ─── DATE PICKER ───────────────────────────────────────────────────────────

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) selectedDate.value = picked;
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  Future<bool> _confirmProceedWithoutPdf() async {
    bool proceed = false;
    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('PDF Upload Failed'),
        content: const Text(
          'The PDF could not be uploaded to Firebase Storage.\n\n'
          'Do you want to publish the draw without a PDF?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              proceed = false;
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              proceed = true;
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3C40)),
            child: const Text('Publish Anyway',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return proceed;
  }

  bool _validateForm() {
    if (drawNumberCtrl.text.trim().isEmpty ||
        cityCtrl.text.trim().isEmpty ||
        winningNumbersCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please fill Draw Number, City, and Winning Numbers.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  List<String>? _parseWinningNumbers() {
    final numbers = winningNumbersCtrl.text
        .split(',')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    if (numbers.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Enter at least one winning number.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
    return numbers;
  }

  void _resetForm() {
    drawNumberCtrl.clear();
    cityCtrl.clear();
    winningNumbersCtrl.clear();
    selectedDenomination.value = 750;
    selectedDate.value = DateTime.now();
    selectedPdf.value = null;
    pdfName.value = '';
    pdfSizeLabel.value = '';
    uploadProgress.value = 0;
    uploadStatusLabel.value = '';
  }
}
