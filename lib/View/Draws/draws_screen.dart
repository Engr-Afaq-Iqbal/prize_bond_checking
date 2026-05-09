// lib/View/Draws/draws_screen.dart
// User-facing screen showing all draw results from Firebase
// Works offline using cached data

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
    // Use existing DrawController (shared with Home screen)
    final DrawController ctrl = Get.find<DrawController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3C40),
        foregroundColor: Colors.white,
        title: const Text('Draw Results'),
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context, ctrl),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── OFFLINE BANNER ────────────────────────────────────────────────
          Obx(() => ctrl.isOffline.value
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  color: Colors.orange.shade100,
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Offline mode - showing cached data',
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange)),
                    ],
                  ),
                )
              : const SizedBox.shrink()),

          // ── ERROR MESSAGE ─────────────────────────────────────────────────
          Obx(() => ctrl.errorMessage.value.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.all(12),
                  margin:
                      const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(ctrl.errorMessage.value,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.red)),
                )
              : const SizedBox.shrink()),

          // ── DRAWS LIST ────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final draws = ctrl.filteredDraws;

              if (draws.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events_outlined,
                          size: 60, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No draw results available',
                          style: TextStyle(color: Colors.grey)),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by Denomination',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Obx(() => FilterChip(
                      label: const Text('All'),
                      selected: ctrl.filterDenomination.value == 0,
                      onSelected: (_) {
                        ctrl.setFilter(0);
                        Get.back();
                      },
                    )),
                ...MockData.denominations.map((d) => Obx(() => FilterChip(
                      label: Text('Rs. $d'),
                      selected: ctrl.filterDenomination.value == d,
                      onSelected: (_) {
                        ctrl.setFilter(d);
                        Get.back();
                      },
                    ))),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
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
    final isPdfDownloaded = ctrl.isPdfDownloaded(draw.id);
    final isDownloading = ctrl.isDownloading(draw.id);

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
                  // Denomination badge
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
                  // PDF download button
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
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 13)),
                  const SizedBox(width: 12),
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(draw.drawDate),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
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
