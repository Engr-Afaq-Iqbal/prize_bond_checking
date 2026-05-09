// lib/Controllers/AdminControllers/admin_draw_controller.dart
// Admin-only: upload draw results, manage draws, view stats
// This replaces the empty AdminDashboard

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../../Models/draw_model.dart';
import '../../Services/draw_service.dart';
import '../../Services/saved_bond_service.dart';
import '../../Services/offline_cache_service.dart';

class AdminDrawController extends GetxController {
  final DrawService _drawService = DrawService();
  final SavedBondService _bondService = SavedBondService();
  final OfflineCacheService _cache = OfflineCacheService();
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
    // Validate fields
    if (drawNumberCtrl.text.trim().isEmpty ||
        cityCtrl.text.trim().isEmpty ||
        winningNumbersCtrl.text.trim().isEmpty) {
      Get.snackbar('Validation Error',
          'Please fill all required fields (Draw Number, City, Winning Numbers)',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    // Parse winning numbers (comma-separated)
    final winningNumbers = winningNumbersCtrl.text
        .split(',')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    if (winningNumbers.isEmpty) {
      Get.snackbar('Error', 'Please enter at least one winning number',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isUploading.value = true;
    uploadProgress.value = 0;

    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Create a temporary draw (without PDF URL yet)
      final newDraw = DrawModel(
        id: '',
        denomination: selectedDenomination.value,
        drawNumber: int.tryParse(drawNumberCtrl.text.trim()) ?? 0,
        drawDate: selectedDate.value,
        city: cityCtrl.text.trim(),
        winningNumbers: winningNumbers,
        createdAt: DateTime.now(),
        uploadedBy: adminUid,
      );

      // Step 1: Create Firestore document (get auto-generated ID)
      final drawId = await _drawService.createDraw(newDraw);
      if (drawId == null) throw Exception('Failed to create draw document');

      // Step 2: Upload PDF if selected
      if (selectedPdf.value != null) {
        uploadProgress.value = 0.1;
        final pdfUrl = await _uploadPdfWithProgress(
            selectedPdf.value!, drawId);

        if (pdfUrl != null) {
          // Update Firestore with PDF URL
          await _drawService.updateDraw(drawId, {'pdfUrl': pdfUrl});
          uploadProgress.value = 0.8;
        }
      }

      // Step 3: Auto-check all user bonds against new draw
      uploadProgress.value = 0.85;
      await _bondService.autoCheckBondsForDraw(
        drawId: drawId,
        denomination: selectedDenomination.value,
        winningNumbers: winningNumbers,
      );

      // Step 4: Update cache
      uploadProgress.value = 0.95;
      await loadDraws();
      await _cache.cacheDraws(allDraws.toList());

      uploadProgress.value = 1.0;
      isUploading.value = false;

      // Success!
      Get.snackbar('✅ Draw Uploaded!',
          'Draw results published and users notified.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);

      _resetForm();
      Get.back(); // Close create draw screen
    } catch (e) {
      _logger.e('Create draw error: $e');
      isUploading.value = false;
      Get.snackbar('Error', 'Failed to upload draw: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  // Upload PDF and track progress
  Future<String?> _uploadPdfWithProgress(File pdf, String drawId) async {
    try {
      final ref = FirebaseStorage.instance.ref('draw_pdfs/$drawId.pdf');
      final task = ref.putFile(pdf);

      task.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          // Map upload progress to 10%-70% of overall progress
          uploadProgress.value =
              0.1 + (snapshot.bytesTransferred / snapshot.totalBytes) * 0.6;
        }
      });

      final snap = await task;
      return await snap.ref.getDownloadURL();
    } catch (e) {
      _logger.e('PDF upload error: $e');
      return null;
    }
  }

  // ─── DELETE DRAW ───────────────────────────────────────────────────────────

  void confirmDeleteDraw(DrawModel draw) {
    Get.dialog(AlertDialog(
      title: const Text('Delete Draw'),
      content: Text(
          'Delete Draw #${draw.drawNumber} (Rs. ${draw.denomination})? This cannot be undone.'),
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

  // ─── RESET FORM ────────────────────────────────────────────────────────────

  void _resetForm() {
    drawNumberCtrl.clear();
    cityCtrl.clear();
    winningNumbersCtrl.clear();
    selectedDenomination.value = 750;
    selectedDate.value = DateTime.now();
    selectedPdf.value = null;
    pdfName.value = '';
    uploadProgress.value = 0;
  }
}
