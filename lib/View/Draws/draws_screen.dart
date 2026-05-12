// lib/View/Draws/draws_screen.dart
//
// Shows two sections:
//   1. DRAW SCHEDULE  — official Pakistan National Savings prize bond schedule,
//                       showing next upcoming draw date per denomination.
//   2. DRAW RESULTS   — all draw results with denomination/city/date filters,
//                       PDF download, and pull-to-refresh.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../../Controllers/DrawControllers/draw_controller.dart';
import '../../models/draw_model.dart';
import '../../Services/pdf_export_service.dart';
import '../../Utils/mock_data.dart';
import 'draw_detail_screen.dart';

class DrawsScreen extends StatelessWidget {
  const DrawsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DrawController ctrl = Get.find<DrawController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3C40),
        foregroundColor: Colors.white,
        title: const Text('Draw Results'),
        actions: [
          // Clear filters button (only visible when a filter is active)
          Obx(() {
            final active = ctrl.filterDenomination.value != 0 ||
                ctrl.filterCity.value.isNotEmpty ||
                ctrl.hasDateFilter.value;
            return active
                ? IconButton(
                    icon: const Icon(Icons.filter_list_off),
                    tooltip: 'Clear filters',
                    onPressed: ctrl.clearAllFilters,
                  )
                : const SizedBox.shrink();
          }),

          // Export current (filtered) results as PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export as PDF',
            onPressed: () => _exportPdf(ctrl),
          ),

          // Filter button
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filter',
            onPressed: () => _showFilterSheet(context, ctrl),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── OFFLINE BANNER ────────────────────────────────────────────────────
          Obx(() => ctrl.isOffline.value
              ? Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.orange.shade100,
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Offline mode – showing cached data',
                          style:
                              TextStyle(fontSize: 12, color: Colors.orange)),
                    ],
                  ),
                )
              : const SizedBox.shrink()),

          // ── ACTIVE FILTER CHIPS ───────────────────────────────────────────────
          Obx(() {
            final chips = <Widget>[];
            if (ctrl.filterDenomination.value != 0) {
              chips.add(_FilterChip(
                label: 'Rs. ${ctrl.filterDenomination.value}',
                onDelete: () => ctrl.setFilter(0),
              ));
            }
            if (ctrl.filterCity.value.isNotEmpty) {
              chips.add(_FilterChip(
                label: ctrl.filterCity.value,
                onDelete: () => ctrl.setCityFilter(''),
              ));
            }
            if (ctrl.hasDateFilter.value) {
              chips.add(_FilterChip(
                label: 'Date filter',
                onDelete: () => ctrl.setDateFilter(null, null),
              ));
            }
            if (chips.isEmpty) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Wrap(spacing: 8, children: chips),
            );
          }),

          // ── ERROR MESSAGE ─────────────────────────────────────────────────────
          Obx(() => ctrl.errorMessage.value.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(ctrl.errorMessage.value,
                      style: const TextStyle(fontSize: 13, color: Colors.red)),
                )
              : const SizedBox.shrink()),

          // ── MAIN SCROLLABLE BODY ──────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final draws = ctrl.filteredDraws;

              return RefreshIndicator(
                onRefresh: ctrl.loadDraws,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Section 1: Draw Schedule ────────────────────────────
                    const _DrawScheduleSection(),
                    const SizedBox(height: 20),

                    // ── Section 2: Draw Results ─────────────────────────────
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'DRAW RESULTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),

                    if (draws.isEmpty)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 24),
                            const Icon(Icons.emoji_events_outlined,
                                size: 60, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No draw results found',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: ctrl.clearAllFilters,
                              child: const Text('Clear filters'),
                            ),
                          ],
                        ),
                      )
                    else
                      ...draws.map((d) => _DrawCard(draw: d)).toList(),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Export the currently filtered draws to a PDF and open it.
  // If no filter is active, exports all loaded draws.
  Future<void> _exportPdf(DrawController ctrl) async {
    final draws = ctrl.filteredDraws;

    if (draws.isEmpty) {
      Get.snackbar(
        'Nothing to Export',
        'No draw results match the current filter.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Build a human-readable label for the filter applied
    String filterLabel = 'All Denominations';
    if (ctrl.filterDenomination.value != 0) {
      filterLabel = 'Rs. ${ctrl.filterDenomination.value}';
    }
    if (ctrl.filterCity.value.isNotEmpty) {
      filterLabel += ' – ${ctrl.filterCity.value}';
    }
    if (ctrl.hasDateFilter.value) {
      filterLabel += ' (date filtered)';
    }

    // Show a loading snackbar
    Get.snackbar(
      'Generating PDF…',
      'Please wait while the report is being created.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );

    await PdfExportService().exportDrawsToPdf(
      draws: draws,
      filterLabel: filterLabel,
    );
  }

  void _showFilterSheet(BuildContext context, DrawController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(ctrl: ctrl),
    );
  }
}

// ── Pakistani Draw Schedule ────────────────────────────────────────────────────
//
// Official National Savings Pakistan prize bond draw schedule.
// Automatically computes the NEXT upcoming draw date for each denomination.
class _DrawScheduleSection extends StatefulWidget {
  const _DrawScheduleSection();

  @override
  State<_DrawScheduleSection> createState() => _DrawScheduleSectionState();
}

class _DrawScheduleSectionState extends State<_DrawScheduleSection> {
  bool _expanded = true;       // expanded by default
  bool _generatingPdf = false; // true while PDF is being created
  String? _pdfPath;            // set once PDF is generated or found on disk

  @override
  void initState() {
    super.initState();
    // Check if a schedule PDF was already downloaded previously
    _checkExistingPdf();
  }

  Future<void> _checkExistingPdf() async {
    final path = await PdfExportService().getSchedulePdfPath();
    if (File(path).existsSync()) {
      if (mounted) setState(() => _pdfPath = path);
    }
  }

  // Generate the schedule PDF and open it.
  // Saves to Documents directory so it's available offline later.
  Future<void> _downloadSchedule() async {
    setState(() => _generatingPdf = true);

    final path = await PdfExportService().exportScheduleToPdf();

    if (!mounted) return;
    setState(() {
      _generatingPdf = false;
      _pdfPath = path;
    });

    if (path != null) {
      await OpenFilex.open(path);
    } else {
      Get.snackbar(
        'Error',
        'Could not generate schedule PDF. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _openSavedPdf() async {
    if (_pdfPath != null) {
      await OpenFilex.open(_pdfPath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header with toggle ──────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3C40),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Draw Schedule (National Savings Pakistan)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),

        // ── Schedule cards + Download button ────────────────────────────────
        if (_expanded) ...[
          const SizedBox(height: 10),
          ..._scheduleItems().map(_buildScheduleCard).toList(),
          const SizedBox(height: 10),

          // Download Full Schedule PDF button
          _DownloadScheduleButton(
            isGenerating: _generatingPdf,
            isDownloaded: _pdfPath != null,
            onDownload: _downloadSchedule,
            onOpen: _openSavedPdf,
          ),
        ],
      ],
    );
  }

  Widget _buildScheduleCard(_ScheduleEntry entry) {
    final now = DateTime.now();
    final next = entry.nextDrawDate(now);
    final daysLeft = next.difference(DateTime(now.year, now.month, now.day)).inDays;

    final String countdownText = daysLeft == 0
        ? 'Today!'
        : daysLeft == 1
            ? 'Tomorrow'
            : '$daysLeft days left';

    final Color countdownColor = daysLeft <= 3
        ? Colors.red.shade600
        : daysLeft <= 7
            ? Colors.orange.shade600
            : const Color(0xFF2E7D6B);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Denomination badge
            Container(
              width: 64,
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3C40).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Rs.\n${_formatDenom(entry.denomination)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A3C40),
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Date and schedule info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Draw: ${DateFormat('EEEE, d MMMM yyyy').format(next)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1F2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.scheduleLabel,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Countdown badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: countdownColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                countdownText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: countdownColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDenom(int denom) {
    if (denom >= 1000) {
      return '${(denom / 1000).toStringAsFixed(denom % 1000 == 0 ? 0 : 1)}K';
    }
    return '$denom';
  }

  // ── Official Pakistan National Savings Prize Bond Schedule ─────────────────
  //
  // Source: National Savings Pakistan (savings.gov.pk)
  //
  //  Rs. 100    — 1st of every month           (monthly)
  //  Rs. 200    — 15th of every month          (monthly)
  //  Rs. 750    — 15th of every month          (monthly)
  //  Rs. 1,500  — 1st & 15th of every month   (bi-monthly)
  //  Rs. 7,500  — 1st of Feb, May, Aug, Nov   (quarterly)
  //  Rs. 15,000 — 1st of Jan, Apr, Jul, Oct   (quarterly)
  //  Rs. 25,000 — 1st of Jan, Apr, Jul, Oct   (quarterly)
  //  Rs. 40,000 — 1st of Mar, Jun, Sep, Dec   (quarterly)

  List<_ScheduleEntry> _scheduleItems() => [
        _ScheduleEntry(
          denomination: 100,
          scheduleLabel: 'Every 1st of the month',
          nextDrawDate: (now) => _nextDayOfMonth(now, 1),
        ),
        _ScheduleEntry(
          denomination: 200,
          scheduleLabel: 'Every 15th of the month',
          nextDrawDate: (now) => _nextDayOfMonth(now, 15),
        ),
        _ScheduleEntry(
          denomination: 750,
          scheduleLabel: 'Every 15th of the month',
          nextDrawDate: (now) => _nextDayOfMonth(now, 15),
        ),
        _ScheduleEntry(
          denomination: 1500,
          scheduleLabel: 'Every 1st & 15th of the month',
          nextDrawDate: (now) => _nextAmong(now, [1, 15]),
        ),
        _ScheduleEntry(
          denomination: 7500,
          scheduleLabel: 'Quarterly — 1st of Feb, May, Aug, Nov',
          nextDrawDate: (now) => _nextMonthDay(now, [2, 5, 8, 11], 1),
        ),
        _ScheduleEntry(
          denomination: 15000,
          scheduleLabel: 'Quarterly — 1st of Jan, Apr, Jul, Oct',
          nextDrawDate: (now) => _nextMonthDay(now, [1, 4, 7, 10], 1),
        ),
        _ScheduleEntry(
          denomination: 25000,
          scheduleLabel: 'Quarterly — 1st of Jan, Apr, Jul, Oct',
          nextDrawDate: (now) => _nextMonthDay(now, [1, 4, 7, 10], 1),
        ),
        _ScheduleEntry(
          denomination: 40000,
          scheduleLabel: 'Quarterly — 1st of Mar, Jun, Sep, Dec',
          nextDrawDate: (now) => _nextMonthDay(now, [3, 6, 9, 12], 1),
        ),
      ];

  // Returns the next occurrence of [day] in the month (today counts if draw
  // hasn't happened yet today — i.e., if today IS that day return today).
  DateTime _nextDayOfMonth(DateTime now, int day) {
    final candidate = DateTime(now.year, now.month, day);
    if (!candidate.isBefore(DateTime(now.year, now.month, now.day))) {
      return candidate;
    }
    // Already passed — go to next month
    final next = DateTime(now.year, now.month + 1, day);
    return next;
  }

  // Returns the next date that is one of [days] in the month
  DateTime _nextAmong(DateTime now, List<int> days) {
    final today = DateTime(now.year, now.month, now.day);
    for (final day in days) {
      final candidate = DateTime(now.year, now.month, day);
      if (!candidate.isBefore(today)) return candidate;
    }
    // All days passed — check next month
    return DateTime(now.year, now.month + 1, days.first);
  }

  // Returns the next date where month is in [months] and day equals [day]
  DateTime _nextMonthDay(DateTime now, List<int> months, int day) {
    final today = DateTime(now.year, now.month, now.day);

    // Check current year first
    for (final month in months) {
      final candidate = DateTime(now.year, month, day);
      if (!candidate.isBefore(today)) return candidate;
    }

    // All this year's draws passed — go to next year
    return DateTime(now.year + 1, months.first, day);
  }
}

// ── Download Full Schedule Button ──────────────────────────────────────────────
//
// Shows:
//  • "Download Full Schedule" if no PDF exists yet
//  • Loading spinner while generating
//  • "Open Saved Schedule" (green) after download — works offline
class _DownloadScheduleButton extends StatelessWidget {
  final bool isGenerating;
  final bool isDownloaded;
  final VoidCallback onDownload;
  final VoidCallback onOpen;

  const _DownloadScheduleButton({
    required this.isGenerating,
    required this.isDownloaded,
    required this.onDownload,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (isGenerating) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1A3C40).withOpacity(0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF1A3C40),
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Generating schedule PDF…',
              style: TextStyle(fontSize: 13, color: Color(0xFF1A3C40)),
            ),
          ],
        ),
      );
    }

    if (isDownloaded) {
      // PDF already saved — show "Open" button with offline badge
      return GestureDetector(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf,
                  color: Colors.red, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open Saved Schedule',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A3C40),
                      ),
                    ),
                    Text(
                      'Works offline — saved on your device',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new,
                  size: 16, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    // Not yet downloaded
    return GestureDetector(
      onTap: onDownload,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A3C40).withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF1A3C40).withOpacity(0.25)),
        ),
        child: const Row(
          children: [
            Icon(Icons.download_outlined,
                color: Color(0xFF1A3C40), size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Download Full Schedule',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A3C40),
                    ),
                  ),
                  Text(
                    'Save as PDF — access anytime without internet',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.picture_as_pdf_outlined,
                size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// Helper data class for schedule entries
class _ScheduleEntry {
  final int denomination;
  final String scheduleLabel;
  final DateTime Function(DateTime now) nextDrawDate;

  const _ScheduleEntry({
    required this.denomination,
    required this.scheduleLabel,
    required this.nextDrawDate,
  });
}

// ── Filter Sheet ───────────────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final DrawController ctrl;
  const _FilterSheet({required this.ctrl});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late int _selectedDenom;
  late String _selectedCity;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _selectedDenom = widget.ctrl.filterDenomination.value;
    _selectedCity = widget.ctrl.filterCity.value;
    _dateFrom = widget.ctrl.filterDateFrom;
    _dateTo = widget.ctrl.filterDateTo;
  }

  @override
  Widget build(BuildContext context) {
    final cities = widget.ctrl.availableCities;
    final fmt = DateFormat('MMM dd, yyyy');

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter Draw Results',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedDenom = 0;
                      _selectedCity = '';
                      _dateFrom = null;
                      _dateTo = null;
                    }),
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Denomination ─────────────────────────────────────────────────
              const Text('Denomination',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedDenom == 0,
                    onSelected: (_) => setState(() => _selectedDenom = 0),
                  ),
                  ...MockData.denominations.map((d) => FilterChip(
                        label: Text('Rs. $d'),
                        selected: _selectedDenom == d,
                        onSelected: (_) =>
                            setState(() => _selectedDenom = d),
                      )),
                ],
              ),
              const SizedBox(height: 20),

              // ── City ────────────────────────────────────────────────────────
              const Text('City',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (cities.isEmpty)
                const Text('No cities loaded yet',
                    style: TextStyle(color: Colors.grey, fontSize: 13))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    FilterChip(
                      label: const Text('All Cities'),
                      selected: _selectedCity.isEmpty,
                      onSelected: (_) =>
                          setState(() => _selectedCity = ''),
                    ),
                    ...cities.map((c) => FilterChip(
                          label: Text(c),
                          selected: _selectedCity == c,
                          onSelected: (_) =>
                              setState(() => _selectedCity = c),
                        )),
                  ],
                ),
              const SizedBox(height: 20),

              // ── Date Range ──────────────────────────────────────────────────
              const Text('Date Range',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _dateFrom != null ? fmt.format(_dateFrom!) : 'From',
                        style: const TextStyle(fontSize: 13),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateFrom ?? DateTime(2020),
                          firstDate: DateTime(2010),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _dateFrom = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _dateTo != null ? fmt.format(_dateTo!) : 'To',
                        style: const TextStyle(fontSize: 13),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateTo ?? DateTime.now(),
                          firstDate: DateTime(2010),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _dateTo = picked);
                        }
                      },
                    ),
                  ),
                  if (_dateFrom != null || _dateTo != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        _dateFrom = null;
                        _dateTo = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.ctrl.setFilter(_selectedDenom);
                    widget.ctrl.setCityFilter(_selectedCity);
                    widget.ctrl.setDateFilter(_dateFrom, _dateTo);
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply Filters',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Active Filter Chip ─────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;
  const _FilterChip({required this.label, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onDelete,
      backgroundColor: const Color(0xFF1A3C40).withOpacity(0.1),
    );
  }
}

// ── Draw Card ──────────────────────────────────────────────────────────────────
class _DrawCard extends StatelessWidget {
  final DrawModel draw;
  const _DrawCard({required this.draw});

  @override
  Widget build(BuildContext context) {
    final DrawController ctrl = Get.find<DrawController>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => Get.to(() => DrawDetailScreen(draw: draw)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3C40).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Rs. ${draw.denomination}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A3C40))),
                  ),
                  Obx(() {
                    final downloading = ctrl.isDownloading(draw.id);
                    final downloaded = ctrl.isPdfDownloaded(draw.id);
                    return IconButton(
                      icon: downloading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: Obx(() => CircularProgressIndicator(
                                    value: ctrl.downloadProgress[draw.id],
                                    strokeWidth: 2,
                                  )),
                            )
                          : Icon(
                              downloaded
                                  ? Icons.picture_as_pdf
                                  : Icons.download_outlined,
                              color: downloaded
                                  ? Colors.red
                                  : const Color(0xFF1A3C40),
                            ),
                      onPressed: () => ctrl.downloadPdf(draw),
                      tooltip: downloaded ? 'Open PDF' : 'Generate PDF',
                    );
                  }),
                ],
              ),
              const SizedBox(height: 10),
              Text('Draw #${draw.drawNumber}',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(draw.city,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(width: 12),
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(draw.drawDate),
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${draw.winningNumbers.length} winning numbers',
                  style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
