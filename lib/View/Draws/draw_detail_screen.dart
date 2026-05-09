// lib/View/Draws/draw_detail_screen.dart
// Shows full details of a draw: winning numbers list, PDF viewer

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Controllers/DrawControllers/draw_controller.dart';
import '../../Models/draw_model.dart';

class DrawDetailScreen extends StatelessWidget {
  final DrawModel draw;

  const DrawDetailScreen({super.key, required this.draw});

  @override
  Widget build(BuildContext context) {
    final DrawController ctrl = Get.find<DrawController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3C40),
        foregroundColor: Colors.white,
        title: Text('Draw #${draw.drawNumber}'),
        actions: [
          if (draw.pdfUrl != null)
            Obx(() {
              final downloading = ctrl.isDownloading(draw.id);
              return IconButton(
                icon: downloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        ctrl.isPdfDownloaded(draw.id)
                            ? Icons.picture_as_pdf
                            : Icons.download_outlined,
                      ),
                onPressed: () => ctrl.downloadPdf(draw),
              );
            }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── DRAW INFO CARD ────────────────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(
                        Icons.emoji_events,
                        'Draw Number',
                        '#${draw.drawNumber}'),
                    _infoRow(Icons.savings_outlined, 'Denomination',
                        'Rs. ${draw.denomination}'),
                    _infoRow(Icons.calendar_today, 'Date',
                        DateFormat('MMMM dd, yyyy').format(draw.drawDate)),
                    _infoRow(
                        Icons.location_city, 'City', draw.city),
                    _infoRow(
                        Icons.format_list_numbered,
                        'Total Winners',
                        '${draw.winningNumbers.length} numbers'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── WINNING NUMBERS ───────────────────────────────────────────────
            const Text('Winning Numbers',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 12),

            // Show numbers in a wrap grid
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: draw.winningNumbers
                      .map((number) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    const Color(0xFF4CAF50).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              number,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                                letterSpacing: 1,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── PDF SECTION ───────────────────────────────────────────────────
            if (draw.pdfUrl != null) ...[
              const Text('Draw PDF',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 12),

              Obx(() {
                final localPath =
                    ctrl.isPdfDownloaded(draw.id)
                        ? 'downloaded' // Just indicator
                        : null;

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.picture_as_pdf,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(
                          ctrl.isPdfDownloaded(draw.id)
                              ? 'PDF downloaded. Tap to open.'
                              : 'Download PDF to view offline',
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        if (ctrl.isDownloading(draw.id))
                          Obx(() => LinearProgressIndicator(
                                value: ctrl.downloadProgress[draw.id],
                              ))
                        else
                          ElevatedButton.icon(
                            onPressed: () => ctrl.downloadPdf(draw),
                            icon: Icon(ctrl.isPdfDownloaded(draw.id)
                                ? Icons.open_in_new
                                : Icons.download_outlined),
                            label: Text(ctrl.isPdfDownloaded(draw.id)
                                ? 'Open PDF'
                                : 'Download PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A3C40),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1A3C40)),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
