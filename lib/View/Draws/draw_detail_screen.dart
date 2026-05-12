// lib/View/Draws/draw_detail_screen.dart
// Shows full details of a draw: winning numbers + PDF (download or generate).

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Controllers/DrawControllers/draw_controller.dart';
import '../../models/draw_model.dart';

class DrawDetailScreen extends StatelessWidget {
  final DrawModel draw;

  const DrawDetailScreen({super.key, required this.draw});

  @override
  Widget build(BuildContext context) {
    final DrawController ctrl = Get.find<DrawController>();

    // True when admin uploaded a PDF to Firebase Storage
    final bool hasAdminPdf =
        draw.pdfUrl != null && draw.pdfUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3C40),
        foregroundColor: Colors.white,
        title: Text('Draw #${draw.drawNumber}'),
        actions: [
          Obx(() {
            final downloading = ctrl.isDownloading(draw.id);
            final downloaded = ctrl.isPdfDownloaded(draw.id);
            return IconButton(
              icon: downloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(
                      downloaded
                          ? Icons.picture_as_pdf
                          : hasAdminPdf
                              ? Icons.download_outlined
                              : Icons.picture_as_pdf_outlined,
                    ),
              onPressed: () => ctrl.downloadPdf(draw),
              tooltip: downloaded
                  ? 'Open PDF'
                  : hasAdminPdf
                      ? 'Download PDF'
                      : 'Generate PDF',
            );
          }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── DRAW INFO CARD ──────────────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(Icons.emoji_events, 'Draw Number',
                        '#${draw.drawNumber}'),
                    _infoRow(Icons.savings_outlined, 'Denomination',
                        'Rs. ${draw.denomination}'),
                    _infoRow(Icons.calendar_today, 'Date',
                        DateFormat('MMMM dd, yyyy').format(draw.drawDate)),
                    _infoRow(Icons.location_city, 'City', draw.city),
                    _infoRow(
                        Icons.format_list_numbered,
                        'Total Winners',
                        '${draw.winningNumbers.length} numbers'),
                    if (hasAdminPdf && draw.pdfFileSize != null)
                      _infoRow(
                        Icons.attach_file,
                        'PDF Size',
                        draw.pdfFileSize! < 1024 * 1024
                            ? '${(draw.pdfFileSize! / 1024).toStringAsFixed(1)} KB'
                            : '${(draw.pdfFileSize! / 1024 / 1024).toStringAsFixed(1)} MB',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── WINNING NUMBERS ─────────────────────────────────────────────
            const Text(
              'Winning Numbers',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),

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
                              color: const Color(0xFF4CAF50)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF4CAF50)
                                    .withValues(alpha: 0.3),
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

            // ── PDF SECTION ─────────────────────────────────────────────────
            Text(
              hasAdminPdf ? 'Download PDF' : 'Winning Numbers PDF',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),

            Obx(() {
              final downloaded = ctrl.isPdfDownloaded(draw.id);
              final downloading = ctrl.isDownloading(draw.id);

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        downloaded
                            ? Icons.picture_as_pdf
                            : hasAdminPdf
                                ? Icons.cloud_download_outlined
                                : Icons.description_outlined,
                        size: 48,
                        color: downloaded
                            ? Colors.red
                            : const Color(0xFF1A3C40),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        downloaded
                            ? 'PDF ready. Tap to open.'
                            : hasAdminPdf
                                ? 'Admin uploaded a PDF. Tap to download.'
                                : 'Generate a PDF of all winning numbers.',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),

                      if (downloading)
                        Obx(() => Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value:
                                        ctrl.downloadProgress[draw.id],
                                    color: const Color(0xFF2E7D6B),
                                    backgroundColor:
                                        Colors.grey.shade200,
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  hasAdminPdf
                                      ? 'Downloading…'
                                      : 'Generating…',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey),
                                ),
                              ],
                            ))
                      else
                        ElevatedButton.icon(
                          onPressed: () => ctrl.downloadPdf(draw),
                          icon: Icon(downloaded
                              ? Icons.open_in_new
                              : hasAdminPdf
                                  ? Icons.download_outlined
                                  : Icons.picture_as_pdf_outlined),
                          label: Text(downloaded
                              ? 'Open PDF'
                              : hasAdminPdf
                                  ? 'Download PDF'
                                  : 'Generate PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF1A3C40),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
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
              style: const TextStyle(
                  color: Colors.grey, fontSize: 14)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
