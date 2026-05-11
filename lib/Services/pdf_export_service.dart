// lib/Services/pdf_export_service.dart
//
// Generates a PDF report from a list of draw results.
//
// Usage:
//   final service = PdfExportService();
//   await service.exportDrawsToPdf(draws: filteredDraws, filterLabel: 'Rs. 750');
//
// The generated PDF is saved to the device's temp folder and opened
// automatically using the system PDF viewer.

import 'dart:io';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../Models/draw_model.dart';

class PdfExportService {
  // Main method — call this from the Draws screen
  Future<void> exportDrawsToPdf({
    required List<DrawModel> draws,
    String filterLabel = 'All Denominations',
  }) async {
    // --- 1. Build the PDF document ---
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ── Header ────────────────────────────────────────────────────────
            _buildHeader(filterLabel),
            pw.SizedBox(height: 16),

            // ── Draw count info ───────────────────────────────────────────────
            pw.Text(
              'Total records: ${draws.length}',
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey600,
              ),
            ),
            pw.SizedBox(height: 12),

            // ── Table ─────────────────────────────────────────────────────────
            draws.isEmpty ? _buildEmptyNote() : _buildTable(draws),
          ];
        },
      ),
    );

    // --- 2. Save to device temp folder ---
    final dir = await getTemporaryDirectory();
    final fileName =
        'prize_bond_draws_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    // --- 3. Open the PDF ---
    final result = await OpenFilex.open(file.path);

    if (result.type != ResultType.done) {
      // If the system viewer fails, show a snackbar with the file location
      Get.snackbar(
        'PDF Saved',
        'File saved to: ${file.path}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // ── PDF header section ─────────────────────────────────────────────────────
  pw.Widget _buildHeader(String filterLabel) {
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // App title
        pw.Text(
          'Prize Bond Draw Results',
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF1A3C40),
          ),
        ),
        pw.SizedBox(height: 6),

        // Filter info + export date
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Filter: $filterLabel',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.Text(
              'Exported: $now',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ],
        ),

        pw.SizedBox(height: 8),
        pw.Divider(color: const PdfColor.fromInt(0xFF1A3C40), thickness: 1.5),
      ],
    );
  }

  // ── Table of draw results ──────────────────────────────────────────────────
  pw.Widget _buildTable(List<DrawModel> draws) {
    // Column headers
    const headers = ['Draw #', 'Denomination', 'Draw Date', 'City'];

    // Row data
    final rows = draws.map((d) {
      return [
        '#${d.drawNumber}',
        'Rs. ${d.denomination}',
        DateFormat('dd MMM yyyy').format(d.drawDate),
        d.city,
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 11,
        color: PdfColors.white,
      ),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1A3C40)),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
      },
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F7FA)),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
    );
  }

  // ── Empty state inside PDF ─────────────────────────────────────────────────
  pw.Widget _buildEmptyNote() {
    return pw.Center(
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(32),
        child: pw.Text(
          'No draw results match the current filter.',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
      ),
    );
  }
}
