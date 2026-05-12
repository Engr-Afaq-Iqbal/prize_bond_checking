// lib/Controllers/DrawControllers/draw_controller.dart
//
// Manages draw results for Home, Schedule, and Draw-list screens.
// Handles both online (Firestore) and offline (Hive cache) modes.
//
// PDF strategy:
//   • draw.pdfUrl != null → admin uploaded a PDF to Firebase Storage
//     → download from Firebase Storage, cache locally, open
//   • draw.pdfUrl == null → no admin PDF
//     → generate PDF from winning numbers locally (offline-capable)

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/draw_model.dart';
import '../../Services/connectivity_service.dart';
import '../../Services/draw_service.dart';
import '../../Services/notification_service.dart';
import '../../Services/offline_cache_service.dart';

class DrawController extends GetxController {
  final DrawService _drawService = DrawService();
  final OfflineCacheService _cache = OfflineCacheService();
  final Logger _logger = Logger();

  // ── Observable state ───────────────────────────────────────────────────────
  final RxList<DrawModel> draws = <DrawModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt filterDenomination = 0.obs;
  final RxBool isOffline = false.obs;
  final RxString filterCity = ''.obs;
  DateTime? filterDateFrom;
  DateTime? filterDateTo;
  final RxBool hasDateFilter = false.obs;

  // PDF download/generation tracking
  final RxMap<String, double> downloadProgress = <String, double>{}.obs;
  final RxSet<String> downloadedDrawIds = <String>{}.obs;

  // Bond check result
  final RxBool hasCheckResult = false.obs;
  final RxBool isWinner = false.obs;
  final RxString checkedBondNumber = ''.obs;
  final RxInt selectedDenomination = 750.obs;
  final RxBool isChecking = false.obs;
  DrawModel? winningDraw;

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
      await _loadFromFirestore();
    } else {
      _loadFromCache();
    }

    isOffline.value = !online;
    isLoading.value = false;
  }

  Future<void> _loadFromFirestore() async {
    try {
      final fetched = await _drawService.getLatestDraws();
      draws.assignAll(fetched);
      await _cache.cacheDraws(fetched);
      _logger.i('Loaded ${fetched.length} draws from Firestore');
    } catch (e) {
      _logger.e('Firestore load error: $e');
      _loadFromCache();
      errorMessage.value = 'Could not refresh. Showing cached data.';
    }
  }

  void _loadFromCache() {
    final cached = _cache.getCachedDraws();
    draws.assignAll(cached);
    if (cached.isEmpty) {
      errorMessage.value =
          'No offline data. Connect to the internet once to download results.';
    }
  }

  // ─── FILTERED DRAWS ────────────────────────────────────────────────────────

  List<DrawModel> get filteredDraws {
    final denom = filterDenomination.value;
    final city = filterCity.value;
    final hasDate = hasDateFilter.value;

    return draws.where((d) {
      if (denom != 0 && d.denomination != denom) return false;
      if (city.isNotEmpty &&
          !d.city.toLowerCase().contains(city.toLowerCase())) {
        return false;
      }
      if (hasDate) {
        if (filterDateFrom != null && d.drawDate.isBefore(filterDateFrom!)) {
          return false;
        }
        if (filterDateTo != null && d.drawDate.isAfter(filterDateTo!)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<String> get availableCities {
    final cities = draws.map((d) => d.city).toSet().toList()..sort();
    return cities;
  }

  void setFilter(int denomination) => filterDenomination.value = denomination;
  void setCityFilter(String city) => filterCity.value = city;

  void setDateFilter(DateTime? from, DateTime? to) {
    filterDateFrom = from;
    filterDateTo = to;
    hasDateFilter.value = from != null || to != null;
  }

  void clearAllFilters() {
    filterDenomination.value = 0;
    filterCity.value = '';
    filterDateFrom = null;
    filterDateTo = null;
    hasDateFilter.value = false;
  }

  // ─── BOND CHECK ────────────────────────────────────────────────────────────

  Future<void> checkBond(String number, int denomination) async {
    if (number.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a bond number.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isChecking.value = true;
    hasCheckResult.value = false;

    await Future.delayed(const Duration(milliseconds: 500));

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

    if (isWinner.value && winningDraw != null) {
      NotificationService.showLocalNotification(
        title: '🎉 Congratulations! You Won!',
        body:
            'Bond #$number (Rs. $denomination) won in Draw #${winningDraw!.drawNumber} — ${winningDraw!.city}!',
        payload: 'winner',
      );
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
              'Draw #${winningDraw!.drawNumber} — ${winningDraw!.city}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(), child: const Text('Great!')),
      ],
    ));
  }

  // ─── PDF: DOWNLOAD (Firebase Storage) or GENERATE (local) ────────────────
  //
  // If the admin uploaded a PDF → download from Firebase Storage.
  // Otherwise → generate a beautifully designed PDF from winning numbers.

  Future<void> downloadPdf(DrawModel draw) async {
    if (isDownloading(draw.id)) return;

    // Return cached file immediately if it still exists on disk
    final cached = _cache.getLocalPdfPath(draw.id);
    if (cached != null && File(cached).existsSync()) {
      _logger.i('Opening cached PDF: $cached');
      await openPdf(cached);
      return;
    }
    if (cached != null) await _cache.setLocalPdfPath(draw.id, '');

    if (draw.pdfUrl != null && draw.pdfUrl!.isNotEmpty) {
      await _downloadFromStorage(draw);
    } else {
      await _generateAndOpenPdf(draw);
    }
  }

  // ── Download admin-uploaded PDF from Firebase Storage ─────────────────────

  Future<void> _downloadFromStorage(DrawModel draw) async {
    if (!ConnectivityService.online) {
      Get.snackbar(
        'Offline',
        'Connect to the internet to download the PDF, '
            'or tap Generate PDF to create one offline.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    downloadProgress[draw.id] = 0.0;

    final dir = await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/draw_${draw.id}.pdf';

    try {
      _logger.i('Downloading PDF from Storage: ${draw.pdfUrl}');

      final ref = FirebaseStorage.instance.refFromURL(draw.pdfUrl!);
      final file = File(savePath);

      final task = ref.writeToFile(file);

      task.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          downloadProgress[draw.id] =
              snapshot.bytesTransferred / snapshot.totalBytes;
          downloadProgress.refresh();
        }
      });

      await task;

      // Verify download
      final fileSize = file.lengthSync();
      if (fileSize < 100) {
        await file.delete();
        throw Exception('Downloaded file too small — likely corrupt.');
      }

      await _cache.setLocalPdfPath(draw.id, savePath);
      downloadedDrawIds.add(draw.id);
      downloadProgress.remove(draw.id);

      _logger.i('PDF saved: $savePath  (${fileSize ~/ 1024} KB)');

      Get.snackbar(
        'Downloaded!',
        'PDF saved. Opening…',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await openPdf(savePath);
    } on FirebaseException catch (e) {
      downloadProgress.remove(draw.id);
      _logger.e('Storage download error [${e.code}]: ${e.message}');

      if (e.code == 'object-not-found') {
        Get.snackbar(
          'PDF Not Found',
          'The PDF file no longer exists on the server.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        // Fallback: generate locally
        Get.snackbar(
          'Download Failed',
          'Generating PDF locally instead…',
          snackPosition: SnackPosition.BOTTOM,
        );
        await _generateAndOpenPdf(draw);
      }
    } catch (e) {
      downloadProgress.remove(draw.id);
      _logger.e('Unexpected download error: $e');
      await _generateAndOpenPdf(draw);
    }
  }

  // ── Generate PDF locally from winning numbers ──────────────────────────────

  Future<void> _generateAndOpenPdf(DrawModel draw) async {
    downloadProgress[draw.id] = 0.1;

    try {
      downloadProgress[draw.id] = 0.3;
      downloadProgress.refresh();

      final pdfBytes = await _buildDrawPdf(draw);

      downloadProgress[draw.id] = 0.85;
      downloadProgress.refresh();

      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/draw_${draw.id}_winners.pdf';
      await File(savePath).writeAsBytes(pdfBytes);

      await _cache.setLocalPdfPath(draw.id, savePath);
      downloadedDrawIds.add(draw.id);
      downloadProgress.remove(draw.id);

      _logger.i('PDF generated: $savePath');

      Get.snackbar(
        'PDF Ready',
        'Opening winning numbers PDF…',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await openPdf(savePath);
    } catch (e) {
      downloadProgress.remove(draw.id);
      _logger.e('PDF generation error: $e');
      Get.snackbar(
        'Error',
        'Failed to generate PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ── PDF builder ────────────────────────────────────────────────────────────

  Future<List<int>> _buildDrawPdf(DrawModel draw) async {
    const primaryColor = PdfColor.fromInt(0xFF1A3C40);
    const accentColor = PdfColor.fromInt(0xFF2E7D6B);
    const lightGreen = PdfColor.fromInt(0xFFE8F5E9);
    const rowAlt = PdfColor.fromInt(0xFFF0F4F3);

    final dateStr =
        DateFormat('MMMM dd, yyyy').format(draw.drawDate);
    final generatedStr =
        DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Prize Bond Winning Numbers',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('National Savings Pakistan',
                        style: pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700)),
                    pw.Text('Generated: $generatedStr',
                        style: pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey500)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: primaryColor, thickness: 2),
            pw.SizedBox(height: 4),
          ],
        ),
        build: (_) => [
          // Draw info card
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: const pw.BoxDecoration(
              color: lightGreen,
              borderRadius:
                  pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _pdfInfoCell(
                    'Denomination', 'Rs. ${draw.denomination}', primaryColor),
                _pdfInfoCell(
                    'Draw Number', '#${draw.drawNumber}', primaryColor),
                _pdfInfoCell('Date', dateStr, primaryColor),
                _pdfInfoCell('City', draw.city, primaryColor),
                _pdfInfoCell('Total Winners',
                    '${draw.winningNumbers.length}', accentColor),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // Section heading
          pw.Row(children: [
            pw.Container(
                width: 4,
                height: 16,
                decoration: const pw.BoxDecoration(color: accentColor)),
            pw.SizedBox(width: 8),
            pw.Text(
              'WINNING BOND NUMBERS',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ]),
          pw.SizedBox(height: 8),

          // Numbers grid (6 columns)
          _buildNumbersGrid(draw.winningNumbers, rowAlt),

          pw.SizedBox(height: 20),

          // Footer
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 4),
          pw.Text(
            'Pakistan Prize Bond  •  Draw #${draw.drawNumber}  •  '
            'Rs. ${draw.denomination}  •  $dateStr  •  ${draw.city}',
            style:
                pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfInfoCell(
      String label, String value, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColors.grey600)),
        pw.SizedBox(height: 3),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: color)),
      ],
    );
  }

  pw.Widget _buildNumbersGrid(
      List<String> numbers, PdfColor oddBg) {
    const cols = 6;
    final rows = <List<String>>[];
    for (int i = 0; i < numbers.length; i += cols) {
      final end = (i + cols).clamp(0, numbers.length);
      final row = List<String>.from(numbers.sublist(i, end));
      while (row.length < cols) {
        row.add('');
      }
      rows.add(row);
    }

    return pw.TableHelper.fromTextArray(
      data: rows,
      border: pw.TableBorder.all(
          color: PdfColors.grey300, width: 0.5),
      cellStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: const PdfColor.fromInt(0xFF1B5E20),
      ),
      cellAlignments: {
        for (int i = 0; i < cols; i++) i: pw.Alignment.center,
      },
      rowDecoration:
          const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: pw.BoxDecoration(color: oddBg),
      cellPadding: const pw.EdgeInsets.symmetric(
          horizontal: 4, vertical: 6),
    );
  }

  // ── Open a local file ──────────────────────────────────────────────────────

  Future<void> openPdf(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      _logger.e('openPdf failed: ${result.message} — $path');
      Get.snackbar(
        'Cannot Open PDF',
        'Install a PDF viewer app and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ── State helpers ──────────────────────────────────────────────────────────

  bool isPdfDownloaded(String drawId) =>
      downloadedDrawIds.contains(drawId);

  bool isDownloading(String drawId) =>
      downloadProgress.containsKey(drawId);

  void _loadDownloadedPdfIds() {
    for (final draw in _cache.getCachedDraws()) {
      final path = _cache.getLocalPdfPath(draw.id);
      if (path != null && File(path).existsSync()) {
        downloadedDrawIds.add(draw.id);
      }
    }
  }
}
