// lib/View/Admin/DrawManagement/create_draw_screen.dart
//
// Admin screen — fill in draw details and optionally attach a PDF.
// The PDF is uploaded to Firebase Storage; all other data goes to Firestore.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../Controllers/AdminControllers/admin_draw_controller.dart';
import '../../../Utils/mock_data.dart';

class CreateDrawScreen extends StatelessWidget {
  const CreateDrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminDrawController ctrl = Get.find<AdminDrawController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3C40),
        foregroundColor: Colors.white,
        title: const Text('Upload Draw Result'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── INFO BANNER ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3C40).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Color(0xFF1A3C40), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'After publishing, users are notified automatically '
                      'and their saved bonds are auto-checked.',
                      style:
                          TextStyle(color: Color(0xFF1A3C40), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── DENOMINATION ───────────────────────────────────────────────
            _fieldLabel('Bond Denomination *'),
            Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: ctrl.selectedDenomination.value,
                      isExpanded: true,
                      items: MockData.denominations
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text('Rs. $d Prize Bond'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) ctrl.selectedDenomination.value = v;
                      },
                    ),
                  ),
                )),
            const SizedBox(height: 16),

            // ── DRAW NUMBER ────────────────────────────────────────────────
            _fieldLabel('Draw Number *'),
            _textField(
              controller: ctrl.drawNumberCtrl,
              hint: 'e.g. 98',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // ── DRAW DATE ──────────────────────────────────────────────────
            _fieldLabel('Draw Date *'),
            Obx(() => GestureDetector(
                  onTap: () => ctrl.pickDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('MMMM dd, yyyy')
                              .format(ctrl.selectedDate.value),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 16),

            // ── CITY ───────────────────────────────────────────────────────
            _fieldLabel('City *'),
            _textField(
              controller: ctrl.cityCtrl,
              hint: 'e.g. Karachi',
            ),
            const SizedBox(height: 16),

            // ── WINNING NUMBERS ────────────────────────────────────────────
            _fieldLabel('Winning Numbers * (comma-separated)'),
            TextField(
              controller: ctrl.winningNumbersCtrl,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText:
                    'e.g. 123456, 789012, 345678\n\n'
                    'Enter all winning bond numbers separated by commas',
                hintStyle:
                    const TextStyle(color: Colors.grey, fontSize: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 16),

            // ── PDF UPLOAD ─────────────────────────────────────────────────
            _fieldLabel('Draw Result PDF (Optional)'),
            Obx(() => ctrl.selectedPdf.value == null
                ? GestureDetector(
                    onTap: ctrl.pickPdf,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.upload_file,
                              size: 36,
                              color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap to attach PDF',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Uploaded to Firebase Storage',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf,
                            color: Colors.red, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ctrl.pdfName.value,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (ctrl.pdfSizeLabel.value.isNotEmpty)
                                Text(
                                  ctrl.pdfSizeLabel.value,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              size: 20, color: Colors.grey),
                          onPressed: ctrl.clearPdf,
                          tooltip: 'Remove PDF',
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 32),

            // ── PUBLISH BUTTON / PROGRESS ──────────────────────────────────
            Obx(() => ctrl.isUploading.value
                ? Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ctrl.uploadProgress.value,
                          backgroundColor: Colors.grey.shade200,
                          color: const Color(0xFF1A3C40),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        ctrl.uploadStatusLabel.value.isEmpty
                            ? _progressLabel(ctrl.uploadProgress.value)
                            : ctrl.uploadStatusLabel.value,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: ctrl.createDraw,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text(
                        'Publish Draw Result',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3C40),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _progressLabel(double p) {
    if (p < 0.10) return 'Preparing…';
    if (p < 0.55) return 'Uploading PDF… ${(p * 200).toInt()}%';
    if (p < 0.70) return 'Saving draw to database…';
    if (p < 0.85) return 'Auto-checking user bonds…';
    if (p < 0.99) return 'Finishing up…';
    return 'Done!';
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
