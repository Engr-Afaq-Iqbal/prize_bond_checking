// lib/Controllers/DrawControllers/draw_controller.dart
// Manages draw results for both Home and Schedule screens
// Handles online (Firestore) and offline (Hive cache) modes
// Also handles PDF download with progress

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../Models/draw_model.dart';
import '../../Services/connectivity_service.dart';
import '../../Services/draw_service.dart';
import '../../Services/offline_cache_service.dart';

class DrawController extends GetxController {
  final DrawService _drawService = DrawService();
  final OfflineCacheService _cache = OfflineCacheService();
  final Logger _logger = Logger();

  // ── Observable State ──────────────────────────────────────────────────────
  final RxList<DrawModel> draws = <DrawModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt filterDenomination = 0.obs; // 0 = all
  final RxBool isOffline = false.obs;

  // PDF download tracking
  final RxMap<String, double> downloadProgress = <String, double>{}.obs;
  final RxSet<String> downloadedDrawIds = <String>{}.obs;

  // Bond check result
  final RxBool hasCheckResult = false.obs;
  final RxBool isWinner = false.obs;
  final RxString checkedBondNumber = ''.obs;
  final RxInt selectedDenomination = 750.obs;
  final RxBool isChecking = false.obs;
  DrawModel? winningDraw; // Which draw this bond won in

  @override
  void onInit() {
    super.onInit();
    loadDraws();
    _loadDownloadedPdfIds();
  }

  // ─── LOAD DRAWS ────────────────────────────────────────────────────────────

  Future<void> loadDraws() async {
    isLoading.value = true;
    errorMessage.value = '';

    final online = ConnectivityService.online;

    if (online) {
      // Online: fetch from Firestore and update cache
      await _loadFromFirestore();
    } else {
      // Offline: load from local Hive cache
      _loadFromCache();
    }

    isOffline.value = !online;
    isLoading.value = false;
  }

  Future<void> _loadFromFirestore() async {
    try {
      final fetchedDraws = await _drawService.getLatestDraws(limit: 30);
      draws.assignAll(fetchedDraws);

      // Update local cache for offline use
      await _cache.cacheDraws(fetchedDraws);
      _logger.i('Loaded ${fetchedDraws.length} draws from Firestore');
    } catch (e) {
      _logger.e('Firestore load error: $e');
      // Fallback to cache even on error
      _loadFromCache();
      errorMessage.value = 'Could not refresh. Showing cached data.';
    }
  }

  void _loadFromCache() {
    final cachedDraws = _cache.getCachedDraws();
    draws.assignAll(cachedDraws);

    if (cachedDraws.isEmpty) {
      errorMessage.value =
          'No offline data available. Please connect to internet once to download results.';
    }
  }

  // ─── FILTERED DRAWS ────────────────────────────────────────────────────────

  List<DrawModel> get filteredDraws {
    if (filterDenomination.value == 0) return draws;
    return draws
        .where((d) => d.denomination == filterDenomination.value)
        .toList();
  }

  void setFilter(int denomination) {
    filterDenomination.value = denomination;
  }

  // ─── BOND CHECK ────────────────────────────────────────────────────────────

  Future<void> checkBond(String number, int denomination) async {
    if (number.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a bond number',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isChecking.value = true;
    hasCheckResult.value = false;

    // Small delay for UX
    await Future.delayed(const Duration(milliseconds: 500));

    // Check against loaded draws (works offline too if data is cached)
    winningDraw = null;
    for (final draw in draws) {
      if (draw.denomination == denomination &&
          draw.winningNumbers.contains(number.trim())) {
        winningDraw = draw;
        break;
      }
    }

    checkedBondNumber.value = number;
    selectedDenomination.value = denomination;
    isWinner.value = winningDraw != null;
    hasCheckResult.value = true;
    isChecking.value = false;

    // Show winner dialog
    if (isWinner.value && winningDraw != null) {
      _showWinnerDialog(number, denomination);
    }
  }

  void _showWinnerDialog(String number, int denomination) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('🎉 Congratulations!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bond #$number (Rs. $denomination) has WON!'),
          const SizedBox(height: 8),
          if (winningDraw != null)
            Text(
              'Draw #${winningDraw!.drawNumber} - ${winningDraw!.city}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Great!')),
      ],
    ));
  }

  // ─── PDF DOWNLOAD ──────────────────────────────────────────────────────────

  Future<void> downloadPdf(DrawModel draw) async {
    if (draw.pdfUrl == null) {
      Get.snackbar('No PDF', 'No PDF available for this draw',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Check if already downloaded
    final cached = _cache.getLocalPdfPath(draw.id);
    if (cached != null && File(cached).existsSync()) {
      await openPdf(cached);
      return;
    }

    if (!ConnectivityService.online) {
      Get.snackbar('Offline', 'Connect to internet to download PDF',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      // Set initial progress
      downloadProgress[draw.id] = 0.0;

      // Get download directory
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/draw_${draw.id}.pdf';

      // Download with Dio (shows progress)
      final dio = Dio();
      await dio.download(
        draw.pdfUrl!,
        path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress[draw.id] = received / total;
            downloadProgress.refresh();
          }
        },
      );

      // Save local path to cache
      await _cache.setLocalPdfPath(draw.id, path);
      downloadedDrawIds.add(draw.id);
      downloadProgress.remove(draw.id);

      Get.snackbar('Downloaded!', 'PDF saved. Opening...',
          snackPosition: SnackPosition.BOTTOM);

      await openPdf(path);
    } catch (e) {
      downloadProgress.remove(draw.id);
      _logger.e('PDF download error: $e');
      Get.snackbar('Error', 'Failed to download PDF',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> openPdf(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      Get.snackbar('Error', 'Cannot open PDF: ${result.message}',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Load list of already-downloaded PDF IDs
  void _loadDownloadedPdfIds() {
    final cached = _cache.getCachedDraws();
    for (final draw in cached) {
      final path = _cache.getLocalPdfPath(draw.id);
      if (path != null && File(path).existsSync()) {
        downloadedDrawIds.add(draw.id);
      }
    }
  }

  bool isPdfDownloaded(String drawId) {
    return downloadedDrawIds.contains(drawId);
  }

  bool isDownloading(String drawId) {
    return downloadProgress.containsKey(drawId);
  }
}
