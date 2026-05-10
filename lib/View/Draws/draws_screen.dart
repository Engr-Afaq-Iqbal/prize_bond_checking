// lib/View/Draws/draws_screen.dart
// Draw results screen with denomination, city, and date filters

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Controllers/DrawControllers/draw_controller.dart';
import '../../Models/draw_model.dart';
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
          // Clear filters button (visible only when filters are active)
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
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filter',
            onPressed: () => _showFilterSheet(context, ctrl),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── OFFLINE BANNER ──────────────────────────────────────────────────
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

          // ── ACTIVE FILTER CHIPS ─────────────────────────────────────────────
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

          // ── ERROR MESSAGE ───────────────────────────────────────────────────
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

          // ── DRAWS LIST ──────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final draws = ctrl.filteredDraws;

              if (draws.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                );
              }

              return RefreshIndicator(
                onRefresh: ctrl.loadDraws,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: draws.length,
                  itemBuilder: (_, i) => _DrawCard(draw: draws[i]),
                ),
              );
            }),
          ),
        ],
      ),
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

// ── Filter Sheet ──────────────────────────────────────────────────────────────
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
              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter Draw Results',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDenom = 0;
                        _selectedCity = '';
                        _dateFrom = null;
                        _dateTo = null;
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Denomination ────────────────────────────────────────────────
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

              // ── City ───────────────────────────────────────────────────────
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
                      onSelected: (_) => setState(() => _selectedCity = ''),
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

              // ── Date Range ─────────────────────────────────────────────────
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
                          lastDate: DateTime.now().add(
                              const Duration(days: 365)),
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
                          lastDate: DateTime.now().add(
                              const Duration(days: 365)),
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
                      onPressed: () =>
                          setState(() {
                            _dateFrom = null;
                            _dateTo = null;
                          }),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Apply Button ───────────────────────────────────────────────
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
                  if (draw.pdfUrl != null)
                    Obx(() {
                      final downloading = ctrl.isDownloading(draw.id);
                      final downloaded = ctrl.isPdfDownloaded(draw.id);
                      return IconButton(
                        icon: downloading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: Obx(() => CircularProgressIndicator(
                                      value:
                                          ctrl.downloadProgress[draw.id],
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
