// lib/View/Admin/DrawManagement/create_draw_screen.dart
//
// Admin screen — fill in draw details and optionally attach a PDF.
//
// ─────────────────────────────────────────────────────────────────────────────
// FIREBASE SETUP GUIDE (run once before first use)
// ─────────────────────────────────────────────────────────────────────────────
//
// 1. Enable Firebase Storage
//    • Open Firebase Console → your project → Build → Storage → Get started
//    • Choose a storage location (e.g. asia-south1 for Pakistan)
//    • Click Done
//
// 2. Configure Storage Security Rules (allow authenticated uploads)
//    In the Storage "Rules" tab, replace the default rules with:
//
//      rules_version = '2';
//      service firebase.storage {
//        match /b/{bucket}/o {
//          // Anyone can read (download PDFs)
//          match /{allPaths=**} {
//            allow read;
//          }
//          // Only authenticated users can upload
//          match /draw_pdfs/{drawId} {
//            allow write: if request.auth != null;
//          }
//        }
//      }
//
// 3. Enable Firestore Database
//    • Firebase Console → Build → Firestore Database → Create database
//    • Start in production mode, choose same region as Storage
//    • Add Firestore Security Rules that allow authenticated reads/writes.
//
// 4. How data is saved
//    When admin taps "Publish Draw Result":
//      a. A Firestore document is created in the 'draws' collection with fields:
//           denomination, drawNumber, drawDate, city, winningNumbers, uploadedBy
//      b. The PDF (if selected) is uploaded to Firebase Storage at:
//           draw_pdfs/<drawId>.pdf
//      c. Firestore document is updated with:
//           pdfUrl        → public download URL
//           pdfName       → original filename picked by admin
//           pdfUploadedAt → ISO-8601 upload timestamp
//           category      → "draw_result"
//      d. All saved user bonds matching denomination + winningNumbers are marked.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../Controllers/AdminControllers/admin_draw_controller.dart';
import '../../../Utils/mock_data.dart'; // for denominations list

class CreateDrawScreen extends StatelessWidget {
  const CreateDrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse the existing AdminDrawController (already put in AdminDashboard)
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
                color: const Color(0xFF1A3C40).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Color(0xFF1A3C40), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'After upload, users will be notified and their saved bonds will be auto-checked.',
                      style: TextStyle(
                          color: Color(0xFF1A3C40), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── FIREBASE SETUP GUIDE (collapsible) ────────────────────────
            const _FirebaseSetupGuide(),
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
              hint: 'e.g., 98',
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
              hint: 'e.g., Karachi',
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
                    'e.g., 123456, 789012, 345678\n\nEnter all winning bond numbers separated by commas',
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
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.upload_file,
                              size: 32, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Tap to select PDF',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf,
                            color: Colors.red, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(ctrl.pdfName.value,
                              style: const TextStyle(fontSize: 13)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: ctrl.clearPdf,
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 32),

            // ── UPLOAD BUTTON & PROGRESS ───────────────────────────────────
            Obx(() => ctrl.isUploading.value
                ? Column(
                    children: [
                      LinearProgressIndicator(
                        value: ctrl.uploadProgress.value,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF1A3C40),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _progressLabel(ctrl.uploadProgress.value),
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
                      label: const Text('Publish Draw Result',
                          style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3C40),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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

  String _progressLabel(double progress) {
    if (progress < 0.1) return 'Creating draw...';
    if (progress < 0.7) return 'Uploading PDF... ${(progress * 100).toInt()}%';
    if (progress < 0.85) return 'Saving to database...';
    if (progress < 0.95) return 'Auto-checking user bonds...';
    return 'Finalizing...';
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w500)),
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

// ── Firebase Setup Guide ───────────────────────────────────────────────────────
//
// Collapsible card shown to the admin explaining the one-time Firebase
// configuration needed before the upload feature works.
class _FirebaseSetupGuide extends StatefulWidget {
  const _FirebaseSetupGuide();

  @override
  State<_FirebaseSetupGuide> createState() => _FirebaseSetupGuideState();
}

class _FirebaseSetupGuideState extends State<_FirebaseSetupGuide> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          // Header row — tap to expand/collapse
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.settings_outlined,
                      color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Firebase Setup Guide (tap to expand)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.blue.shade700,
                  ),
                ],
              ),
            ),
          ),

          // Expandable steps
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Divider(height: 1),
                  SizedBox(height: 12),
                  _SetupStep(
                    number: '1',
                    title: 'Enable Firebase Storage',
                    detail:
                        'Firebase Console → your project → Build → Storage → '
                        'Get started → choose region (asia-south1) → Done.',
                  ),
                  SizedBox(height: 10),
                  _SetupStep(
                    number: '2',
                    title: 'Set Storage Security Rules',
                    detail:
                        'In Storage → Rules tab, allow read for everyone and '
                        'write only for signed-in users:\n\n'
                        'match /draw_pdfs/{id} {\n'
                        '  allow read;\n'
                        '  allow write: if request.auth != null;\n'
                        '}',
                    isCode: true,
                  ),
                  SizedBox(height: 10),
                  _SetupStep(
                    number: '3',
                    title: 'Enable Firestore Database',
                    detail:
                        'Firebase Console → Build → Firestore Database → '
                        'Create database → Production mode → same region → Done.',
                  ),
                  SizedBox(height: 10),
                  _SetupStep(
                    number: '4',
                    title: 'What gets saved to Firestore',
                    detail:
                        'Each uploaded draw stores:\n'
                        '• pdfUrl — download link\n'
                        '• pdfName — original filename\n'
                        '• pdfUploadedAt — timestamp\n'
                        '• category — "draw_result"',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Single numbered step inside the setup guide
class _SetupStep extends StatelessWidget {
  final String number;
  final String title;
  final String detail;
  final bool isCode;

  const _SetupStep({
    required this.number,
    required this.title,
    required this.detail,
    this.isCode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number badge
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.blue.shade700,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Container(
                padding: isCode
                    ? const EdgeInsets.all(8)
                    : EdgeInsets.zero,
                decoration: isCode
                    ? BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      )
                    : null,
                child: Text(
                  detail,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontFamily: isCode ? 'monospace' : null,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
