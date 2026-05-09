// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../Controllers/AuthControllers/auth_controller.dart';
// import '../../Utils/dimensions.dart';
//
// class DashboardPage extends StatelessWidget {
//   const DashboardPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Dashboard Page'),
//         actions: [
//           GestureDetector(
//             onTap: () {
//               Get.find<AuthController>().signOut();
//               // Get.offAll(() => SignInPage());
//             },
//             child: Icon(
//               Icons.logout,
//               size: 30,
//             ),
//           ),
//           size50w,
//         ],
//       ),
//     );
//   }
// }

// lib/View/DashboardPage/dashboard_page.dart
// UPDATED: Replaces empty dashboard with full Firebase-connected Home screen
// Shows draw results from Firestore (with offline fallback)
// Preserves existing design style from the app

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Controllers/AuthControllers/auth_controller.dart';
import '../../Controllers/DrawControllers/draw_controller.dart';
import '../../Models/draw_model.dart';
import '../../Theme/colors.dart';
import '../../View/Draws/draw_detail_screen.dart';
import '../../View/Draws/draws_screen.dart';
import '../scanner/scanner_screen.dart';

class DashboardPage extends StatelessWidget {
  DashboardPage({super.key});

  final TextEditingController _bondInputCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // DrawController is already put in main.dart as permanent
    final DrawController ctrl = Get.find<DrawController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER (matches existing app style) ───────────────────────────
            _buildHeader(context),

            // ── BODY ──────────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── OFFLINE ALERT ──────────────────────────────────────────
                    Obx(() => ctrl.isOffline.value
                        ? _offlineBanner()
                        : const SizedBox.shrink()),

                    // ── STATS ROW ──────────────────────────────────────────────
                    Obx(() => Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                label: 'Total Draws',
                                value: ctrl.draws.length.toString(),
                                bgColor: const Color(0xFFFFF9C4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statCard(
                                label: 'Next Draw',
                                value: _nextDrawDate(ctrl.draws),
                                bgColor: const Color(0xFFE8F5F3),
                                textColor: primaryBlueColor,
                              ),
                            ),
                          ],
                        )),
                    const SizedBox(height: 20),

                    // ── QUICK CHECK CARD ───────────────────────────────────────
                    _buildQuickCheckCard(ctrl),
                    const SizedBox(height: 20),

                    // ── LATEST DRAWS ───────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Latest Draw Results',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E))),
                        GestureDetector(
                          onTap: () => Get.to(() => const DrawsScreen()),
                          child: Text('View All',
                              style: TextStyle(
                                  color: primaryBlueColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Obx(() {
                      if (ctrl.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final latest = ctrl.draws.take(4).toList();
                      return Column(
                        children:
                            latest.map((d) => _drawTile(d, ctrl)).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── SCANNER FAB ─────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlueColor,
        onPressed: () async {
          final result = await Get.to(() => ScannerScreen());
          if (result != null && result is String) {
            _bondInputCtrl.text = result;
          }
        },
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
      color: const Color(0xFF1A3C40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prize Bond Checking',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Text('National Savings Pakistan',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Get.find<AuthController>().signOut(),
          ),
        ],
      ),
    );
  }

  // ── OFFLINE BANNER ───────────────────────────────────────────────────────────
  Widget _offlineBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, size: 18, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'You\'re offline. Showing last downloaded results.\nConnect to internet to get latest draws.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── STAT CARD ────────────────────────────────────────────────────────────────
  Widget _statCard({
    required String label,
    required String value,
    required Color bgColor,
    Color textColor = const Color(0xFF1A1A2E),
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.7),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  // ── QUICK CHECK CARD ─────────────────────────────────────────────────────────
  Widget _buildQuickCheckCard(DrawController ctrl) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Check',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 12),

            // Denomination Dropdown
            Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: ctrl.selectedDenomination.value,
                      isExpanded: true,
                      items: [100, 200, 750, 1500, 7500, 15000, 25000, 40000]
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text('Rs. $d Prize Bond'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          ctrl.selectedDenomination.value = v;
                          ctrl.hasCheckResult.value = false;
                        }
                      },
                    ),
                  ),
                )),
            const SizedBox(height: 12),

            // Bond Number Input
            TextField(
              controller: _bondInputCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter Bond Number',
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              ),
              onChanged: (v) => ctrl.checkedBondNumber.value = v,
            ),
            const SizedBox(height: 12),

            // Check Button
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: ctrl.isChecking.value
                        ? null
                        : () => ctrl.checkBond(
                              _bondInputCtrl.text,
                              ctrl.selectedDenomination.value,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3C40),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: ctrl.isChecking.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Check Result',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                )),

            // Result display
            Obx(() => ctrl.hasCheckResult.value
                ? _buildResult(
                    ctrl.isWinner.value,
                    ctrl.checkedBondNumber.value,
                    ctrl.selectedDenomination.value,
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(bool isWinner, String number, int denom) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWinner
            ? const Color(0xFF4CAF50).withOpacity(0.1)
            : const Color(0xFFEF5350).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                isWinner ? const Color(0xFF4CAF50) : const Color(0xFFEF5350)),
      ),
      child: Row(
        children: [
          Icon(isWinner ? Icons.emoji_events : Icons.cancel_outlined,
              color:
                  isWinner ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
              size: 30),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isWinner ? '🎉 WINNER!' : 'Not a Winner',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isWinner
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFEF5350))),
              Text('Bond #$number (Rs. $denom)',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _drawTile(DrawModel draw, DrawController ctrl) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => Get.to(() => DrawDetailScreen(draw: draw)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A3C40).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.emoji_events, color: Color(0xFF1A3C40)),
        ),
        title: Text('Rs. ${draw.denomination} Draw #${draw.drawNumber}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          '${draw.city} · ${DateFormat('yyyy-MM-dd').format(draw.drawDate)}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: draw.pdfUrl != null
            ? IconButton(
                icon: const Icon(Icons.download_outlined,
                    color: Color(0xFF1A3C40)),
                onPressed: () => ctrl.downloadPdf(draw),
              )
            : null,
      ),
    );
  }

  String _nextDrawDate(List<DrawModel> draws) {
    final upcoming = draws.where((d) => d.drawDate.isAfter(DateTime.now()));
    if (upcoming.isEmpty) return 'TBA';
    final next =
        upcoming.reduce((a, b) => a.drawDate.isBefore(b.drawDate) ? a : b);
    return DateFormat('dd MMM').format(next.drawDate);
  }
}
