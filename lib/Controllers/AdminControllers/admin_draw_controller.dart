// lib/Controllers/AdminControllers/admin_draw_controller.dart
// Admin-only controller: upload draw results, manage draws, store notifications.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../../models/draw_model.dart';
import '../../Services/cloudinary_service.dart';
import '../../Services/draw_service.dart';
import '../../Services/notification_service.dart';
import '../../Services/saved_bond_service.dart';
import '../../Services/offline_cache_service.dart';

class AdminDrawController extends GetxController {
  final DrawService _drawService = DrawService();
  final SavedBondService _bondService = SavedBondService();
  final OfflineCacheService _cache = OfflineCacheService();
  final NotificationService _notificationService = NotificationService();
  final Logger _logger = Logger();

  // ── Form controllers ───────────────────────────────────────────────────────
  final TextEditingController drawNumberCtrl = TextEditingController();
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController winningNumbersCtrl = TextEditingController();
  final RxInt selectedDenomination = 750.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  // ── State ──────────────────────────────────────────────────────────────────
  final RxList<DrawModel> allDraws = <DrawModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxString uploadStatusLabel = ''.obs;
  final Rx<File?> selectedPdf = Rx<File?>(null);
  final RxString pdfName = ''.obs;

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

    if (result != null && result.files.single.path != null) {
      selectedPdf.value = File(result.files.single.path!);
      pdfName.value = result.files.single.name;
    }
  }

  void clearPdf() {
    selectedPdf.value = null;
    pdfName.value = '';
  }

  // ─── CREATE DRAW ───────────────────────────────────────────────────────────

  Future<void> createDraw() async {
    if (!_validateForm()) return;

    final winningNumbers = _parseWinningNumbers();
    if (winningNumbers == null) return;

    isUploading.value = true;
    uploadProgress.value = 0;
    uploadStatusLabel.value = 'Creating draw…';

    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final denomination = selectedDenomination.value;
      final drawNumber = int.tryParse(drawNumberCtrl.text.trim()) ?? 0;

      // Step 1 — Create Firestore document
      final newDraw = DrawModel(
        id: '',
        denomination: denomination,
        drawNumber: drawNumber,
        drawDate: selectedDate.value,
        city: cityCtrl.text.trim(),
        winningNumbers: winningNumbers,
        createdAt: DateTime.now(),
        uploadedBy: adminUid,
      );

      final drawId = await _drawService.createDraw(newDraw);
      if (drawId == null) throw Exception('Failed to create draw document');
      uploadProgress.value = 0.10;

      // Step 2 — Upload PDF to Cloudinary if selected
      if (selectedPdf.value != null) {
        uploadStatusLabel.value = 'Uploading PDF…';
        final pdfUrl = await _uploadPdfWithProgress(selectedPdf.value!, drawId);

        if (pdfUrl != null) {
          await _drawService.updateDraw(drawId, {
            'pdfUrl': pdfUrl,
            'pdfName': pdfName.value,
            'pdfUploadedAt': DateTime.now().toIso8601String(),
            'category': 'draw_result',
          });
        }
      }
      uploadProgress.value = 0.70;

      // Step 3 — Auto-check all user bonds against the new draw
      uploadStatusLabel.value = 'Checking bonds…';
      final winners = await _bondService.autoCheckBondsForDraw(
        drawId: drawId,
        denomination: denomination,
        winningNumbers: winningNumbers,
      );
      uploadProgress.value = 0.80;

      // Step 4 — Store in-app notifications in Firestore for each winner
      // (Firebase Functions will send push notifications when account is upgraded)
      uploadStatusLabel.value = 'Storing notifications…';
      await _storeWinnerNotifications(
        drawId: drawId,
        drawNumber: drawNumber,
        denomination: denomination,
        winners: winners,
      );
      uploadProgress.value = 0.90;

      // Step 5 — Refresh local data and cache
      uploadStatusLabel.value = 'Finishing up…';
      await loadDraws();
      await loadStats();
      await _cache.cacheDraws(allDraws.toList());

      uploadProgress.value = 1.0;
      isUploading.value = false;
      uploadStatusLabel.value = '';

      Get.snackbar(
        'Draw Uploaded!',
        'Draw #$drawNumber published. ${winners.length} winner(s) found.',
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

  // ─── PDF UPLOAD ────────────────────────────────────────────────────────────

  Future<String?> _uploadPdfWithProgress(File pdf, String drawId) async {
    try {
      final cloudinary = CloudinaryService();
      final url = await cloudinary.uploadPdf(
        pdf,
        onProgress: (progress) {
          uploadProgress.value = 0.10 + progress * 0.58;
        },
      );

      if (url == null) {
        _logger.e('Cloudinary returned null URL for draw $drawId');
        Get.snackbar(
          'PDF Upload Failed',
          'Draw was saved without a PDF. Check Cloudinary credentials.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }

      return url;
    } catch (e) {
      _logger.e('PDF upload exception: $e');
      return null;
    }
  }

  // ─── STORE WINNER NOTIFICATIONS IN FIRESTORE ──────────────────────────────
  // Notifications are stored per-user so users see them in the in-app inbox.
  // Push delivery will be handled by Firebase Functions once account is upgraded.

  Future<void> _storeWinnerNotifications({
    required String drawId,
    required int drawNumber,
    required int denomination,
    required List<WinnerInfo> winners,
  }) async {
    final seenUserIds = <String>{};

    for (final winner in winners) {
      await _notificationService.storeNotification(
        userId: winner.userId,
        title: 'Congratulations! Your Bond Won!',
        body:
            'Bond #${winner.bondNumber} (Rs. $denomination) won in Draw #$drawNumber!',
        type: 'winner',
        relatedId: drawId,
      );

      seenUserIds.add(winner.userId);
    }

    _logger.i('Stored ${seenUserIds.length} winner notification(s) in Firestore');
  }

  // ─── DELETE DRAW ───────────────────────────────────────────────────────────

  void confirmDeleteDraw(DrawModel draw) {
    Get.dialog(AlertDialog(
      title: const Text('Delete Draw'),
      content: Text(
        'Delete Draw #${draw.drawNumber} (Rs. ${draw.denomination})? This cannot be undone.',
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Get.back();
            await _drawService.deleteDraw(draw.id);
            allDraws.removeWhere((d) => d.id == draw.id);
            Get.snackbar('Deleted', 'Draw removed successfully',
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

  bool _validateForm() {
    if (drawNumberCtrl.text.trim().isEmpty ||
        cityCtrl.text.trim().isEmpty ||
        winningNumbersCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please fill Draw Number, City, and Winning Numbers',
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
      Get.snackbar('Validation Error', 'Enter at least one winning number',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
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
    uploadProgress.value = 0;
    uploadStatusLabel.value = '';
  }
}
