// lib/Services/pdf_export_service.dart
//
// Generates two types of PDF reports:
//
//  1. exportDrawsToPdf()   Draw results table (filtered or all).
//                           Includes draw number, denomination, date, city,
//                           winner count, and sample winning numbers.
//
//  2. exportScheduleToPdf() Full draw schedule for all 8 bond denominations.
//                             Saved permanently to device so it works offline.
//
// Both PDFs are saved to device storage and opened automatically.

import 'dart:io';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/draw_model.dart';

class PdfExportService {
  // ── App primary color (used in PDF headers) ────────────────────────────────
  static const PdfColor _primaryColor = PdfColor.fromInt(0xFF1A3C40);
  static const PdfColor _accentColor = PdfColor.fromInt(0xFF2E7D6B);

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. DRAW RESULTS PDF
  // ═══════════════════════════════════════════════════════════════════════════

  /// Exports the given [draws] list to a PDF and opens it.
  ///
  /// If filters are applied on the Draws screen, pass only the filtered list
  /// so the PDF reflects exactly what the user sees.
  ///
  /// [filterLabel] is shown in the PDF header to describe the active filter.
  Future<void> exportDrawsToPdf({
    required List<DrawModel> draws,
    String filterLabel = 'All Denominations',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          _buildResultsHeader(filterLabel),
          pw.SizedBox(height: 14),
          pw.Text(
            'Total records: ${draws.length}',
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 12),
          draws.isEmpty ? _buildEmptyNote() : _buildResultsTable(draws),
          pw.SizedBox(height: 20),
          // Winning numbers appendix one section per draw
          if (draws.isNotEmpty) ..._buildWinningNumbersSections(draws),
        ],
      ),
    );

    // Save to temp directory and open
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/prize_bond_results_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    await _openFile(file.path);
  }

  // ── Results PDF: header ────────────────────────────────────────────────────
  pw.Widget _buildResultsHeader(String filterLabel) {
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Prize Bond Draw Results',
          style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor),
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Filter: $filterLabel',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.Text('Exported: $now',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: _primaryColor, thickness: 1.5),
      ],
    );
  }

  // ── Results PDF: summary table ─────────────────────────────────────────────
  pw.Widget _buildResultsTable(List<DrawModel> draws) {
    const headers = ['Draw #', 'Denomination', 'Date', 'City', 'Winners'];

    final rows = draws.map((d) {
      return [
        '#${d.drawNumber}',
        'Rs. ${d.denomination}',
        DateFormat('dd MMM yyyy').format(d.drawDate),
        d.city,
        '${d.winningNumbers.length}',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _primaryColor),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
      },
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F7FA)),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.8),
        1: const pw.FlexColumnWidth(1.3),
        2: const pw.FlexColumnWidth(1.3),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(0.7),
      },
    );
  }

  // ── Results PDF: winning numbers appendix ──────────────────────────────────
  //
  // For each draw, list all winning numbers in a compact grid.
  // If there are more than 30, show the first 30 and note the total.
  List<pw.Widget> _buildWinningNumbersSections(List<DrawModel> draws) {
    final widgets = <pw.Widget>[];

    widgets.add(pw.SizedBox(height: 10));
    widgets.add(pw.Text(
      'WINNING NUMBERS',
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: _primaryColor,
      ),
    ));
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(pw.Divider(color: _primaryColor, thickness: 1));
    widgets.add(pw.SizedBox(height: 8));

    for (final draw in draws) {
      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Draw title
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE8F5E9),
                ),
                child: pw.Text(
                  'Draw #${draw.drawNumber} - Rs. ${draw.denomination} - '
                  '${DateFormat('dd MMM yyyy').format(draw.drawDate)} - ${draw.city}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              // Winning numbers in a compact comma-separated list
              _buildNumbersList(draw.winningNumbers),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  pw.Widget _buildNumbersList(List<String> numbers) {
    const int maxShown = 50; // show at most 50 per draw to avoid huge PDFs
    final shown = numbers.take(maxShown).toList();
    final remaining = numbers.length - shown.length;

    final buffer = StringBuffer();
    for (int i = 0; i < shown.length; i++) {
      buffer.write(shown[i]);
      if (i < shown.length - 1) buffer.write(',  ');
    }
    if (remaining > 0) buffer.write('  … and $remaining more');

    return pw.Text(
      buffer.toString(),
      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
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

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. DRAW SCHEDULE PDF
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns the path where the schedule PDF will be saved.
  /// Used by the UI to check if a PDF already exists (without generating it).
  Future<String> getSchedulePdfPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/prize_bond_draw_schedule.pdf';
  }

  /// Generates the full draw schedule PDF and saves it to the device.
  ///
  /// The file is saved to the Documents directory (NOT temp), so it persists
  /// and works offline even after the app restarts.
  ///
  /// Returns the local path of the saved file, or null on error.
  Future<String?> exportScheduleToPdf() async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            _buildScheduleHeader(now),
            pw.SizedBox(height: 16),
            _buildScheduleIntro(),
            pw.SizedBox(height: 14),
            _buildScheduleTable(now),
            pw.SizedBox(height: 20),
            ..._buildUpcomingDrawsSection(now),
            pw.SizedBox(height: 20),
            _buildScheduleFooter(),
          ],
        ),
      );

      // Save to Documents directory - survives app restarts (offline access)
      final path = await getSchedulePdfPath();
      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      // Open the file automatically after generation (consistent with results export)
      await _openFile(path);

      return path;
    } catch (e) {
      return null;
    }
  }

  // ── Schedule PDF: header ───────────────────────────────────────────────────
  pw.Widget _buildScheduleHeader(DateTime now) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Pakistan Prize Bond Draw Schedule',
          style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor),
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'National Savings Pakistan',
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
            pw.Text(
              'Generated: ${DateFormat('dd MMM yyyy').format(now)}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: _primaryColor, thickness: 1.5),
      ],
    );
  }

  // ── Schedule PDF: intro note ───────────────────────────────────────────────
  pw.Widget _buildScheduleIntro() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFE8F5E9),
      ),
      child: pw.Text(
        'This schedule shows all 8 prize bond denominations with their official '
        'draw dates. After downloading, this PDF works completely offline.',
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
      ),
    );
  }

  // ── Schedule PDF: main table ───────────────────────────────────────────────
  pw.Widget _buildScheduleTable(DateTime now) {
    const headers = [
      'Denomination',
      'Draw Frequency',
      'Draw Months/Day',
      'Next Draw'
    ];

    final entries = _scheduleData();
    final rows = entries.map((e) {
      final next = e.nextDraw(now);
      return [
        'Rs. ${_formatDenom(e.denomination)}',
        e.frequency,
        e.monthsDay,
        DateFormat('dd MMM yyyy').format(next),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _primaryColor),
      cellStyle: const pw.TextStyle(fontSize: 9),
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
        0: const pw.FlexColumnWidth(1.1),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1.8),
        3: const pw.FlexColumnWidth(1.2),
      },
    );
  }

  // ── Schedule PDF: upcoming draws (next 6 months) ───────────────────────────
  List<pw.Widget> _buildUpcomingDrawsSection(DateTime now) {
    final upcoming = _getUpcomingDraws(now, months: 6);

    return [
      pw.Text(
        'UPCOMING DRAWS Next 6 Months',
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: _primaryColor,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Divider(color: _primaryColor, thickness: 1),
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        headers: ['Date', 'Denomination', 'Frequency'],
        data: upcoming
            .map((u) => [
                  DateFormat('EEE, dd MMM yyyy').format(u.date),
                  'Rs. ${_formatDenom(u.denomination)}',
                  u.frequency,
                ])
            .toList(),
        border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
        headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
          color: PdfColors.white,
        ),
        headerDecoration: const pw.BoxDecoration(color: _accentColor),
        cellStyle: const pw.TextStyle(fontSize: 9),
        rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
        oddRowDecoration:
            const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF0F4F3)),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.6),
          1: const pw.FlexColumnWidth(1.1),
          2: const pw.FlexColumnWidth(1.3),
        },
      ),
    ];
  }

  // ── Schedule PDF: footer ───────────────────────────────────────────────────
  pw.Widget _buildScheduleFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 4),
        pw.Text(
          'Source: National Savings Pakistan | This file is saved offline on your device.',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Schedule data helpers
  // ═══════════════════════════════════════════════════════════════════════════

  List<_ScheduleData> _scheduleData() => [
        _ScheduleData(
          denomination: 100,
          frequency: 'Monthly',
          monthsDay: '1st of every month',
          nextDraw: (now) => _nextDayOfMonth(now, 1),
        ),
        _ScheduleData(
          denomination: 200,
          frequency: 'Monthly',
          monthsDay: '15th of every month',
          nextDraw: (now) => _nextDayOfMonth(now, 15),
        ),
        _ScheduleData(
          denomination: 750,
          frequency: 'Monthly',
          monthsDay: '15th of every month',
          nextDraw: (now) => _nextDayOfMonth(now, 15),
        ),
        _ScheduleData(
          denomination: 1500,
          frequency: 'Bi-monthly',
          monthsDay: '1st & 15th of every month',
          nextDraw: (now) => _nextAmong(now, [1, 15]),
        ),
        _ScheduleData(
          denomination: 7500,
          frequency: 'Quarterly',
          monthsDay: '1st of Feb, May, Aug, Nov',
          nextDraw: (now) => _nextMonthDay(now, [2, 5, 8, 11], 1),
        ),
        _ScheduleData(
          denomination: 15000,
          frequency: 'Quarterly',
          monthsDay: '1st of Jan, Apr, Jul, Oct',
          nextDraw: (now) => _nextMonthDay(now, [1, 4, 7, 10], 1),
        ),
        _ScheduleData(
          denomination: 25000,
          frequency: 'Quarterly',
          monthsDay: '1st of Jan, Apr, Jul, Oct',
          nextDraw: (now) => _nextMonthDay(now, [1, 4, 7, 10], 1),
        ),
        _ScheduleData(
          denomination: 40000,
          frequency: 'Quarterly',
          monthsDay: '1st of Mar, Jun, Sep, Dec',
          nextDraw: (now) => _nextMonthDay(now, [3, 6, 9, 12], 1),
        ),
      ];

  /// Generates all upcoming draw events within [months] months from [now],
  /// sorted by date.
  List<_DrawEvent> _getUpcomingDraws(DateTime now, {required int months}) {
    final cutoff = DateTime(now.year, now.month + months, now.day);
    final events = <_DrawEvent>[];

    for (final s in _scheduleData()) {
      DateTime cursor = s.nextDraw(now);
      while (cursor.isBefore(cutoff)) {
        events.add(_DrawEvent(
          date: cursor,
          denomination: s.denomination,
          frequency: s.frequency,
        ));
        // Advance to next occurrence based on frequency pattern
        cursor = s.nextDraw(cursor.add(const Duration(days: 1)));
      }
    }

    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  // ── Date calculation helpers ───────────────────────────────────────────────

  DateTime _nextDayOfMonth(DateTime now, int day) {
    final today = DateTime(now.year, now.month, now.day);
    final candidate = DateTime(now.year, now.month, day);
    if (!candidate.isBefore(today)) return candidate;
    return DateTime(now.year, now.month + 1, day);
  }

  DateTime _nextAmong(DateTime now, List<int> days) {
    final today = DateTime(now.year, now.month, now.day);
    for (final day in days) {
      final candidate = DateTime(now.year, now.month, day);
      if (!candidate.isBefore(today)) return candidate;
    }
    return DateTime(now.year, now.month + 1, days.first);
  }

  DateTime _nextMonthDay(DateTime now, List<int> months, int day) {
    final today = DateTime(now.year, now.month, now.day);
    for (final month in months) {
      final candidate = DateTime(now.year, month, day);
      if (!candidate.isBefore(today)) return candidate;
    }
    return DateTime(now.year + 1, months.first, day);
  }

  String _formatDenom(int denom) {
    if (denom >= 1000) {
      return '${(denom / 1000).toStringAsFixed(denom % 1000 == 0 ? 0 : 1)}K';
    }
    return '$denom';
  }

  // ── Open file helper ───────────────────────────────────────────────────────

  Future<void> _openFile(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      Get.snackbar(
        'PDF Saved',
        'File saved to: $path',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }
}

// ── Internal helper data classes ───────────────────────────────────────────────

class _ScheduleData {
  final int denomination;
  final String frequency;
  final String monthsDay;
  final DateTime Function(DateTime now) nextDraw;

  const _ScheduleData({
    required this.denomination,
    required this.frequency,
    required this.monthsDay,
    required this.nextDraw,
  });
}

class _DrawEvent {
  final DateTime date;
  final int denomination;
  final String frequency;

  const _DrawEvent({
    required this.date,
    required this.denomination,
    required this.frequency,
  });
}
