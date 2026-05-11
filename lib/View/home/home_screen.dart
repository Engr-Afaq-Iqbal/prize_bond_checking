// lib/View/home/home_screen.dart
// Home screen — bond checker backed by real Firebase draw data

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Controllers/DrawControllers/draw_controller.dart';
import '../../Theme/app_theme.dart';
import '../../Utils/common_widgets.dart';
import '../../Utils/mock_data.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/nav_controller.dart';
import '../scanner/scanner_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final TextEditingController _bondInputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.put(HomeController());
    final DrawController draw = Get.find<DrawController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ───────────────────────────────────────────────────────
            AppHeader(
              title: 'Prize Bond Checking',
              onSettingsTap: () => Get.to(() => SettingsScreen()),
            ),

            // ── SCROLLABLE CONTENT ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── STATS ROW ────────────────────────────────────────────
                    Obx(() => Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                label: 'Total Bonds',
                                value: controller.totalBonds.value.toString(),
                                backgroundColor: const Color(0xFFFFF9C4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                label: 'Next Draw',
                                value: controller.nextDrawDate.value,
                                backgroundColor: const Color(0xFFE8F5F3),
                                textColor: AppColors.primary,
                              ),
                            ),
                          ],
                        )),
                    const SizedBox(height: 20),

                    // ── QUICK CHECK CARD ──────────────────────────────────────
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quick Check',
                                style: AppTextStyles.heading2),
                            const SizedBox(height: 12),

                            // Denomination Dropdown
                            Obx(() => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value:
                                          controller.selectedDenomination.value,
                                      isExpanded: true,
                                      icon: const Icon(Icons.expand_more,
                                          color: AppColors.textSecondary),
                                      items: MockData.denominations
                                          .map((d) => DropdownMenuItem(
                                                value: d,
                                                child: Text('Rs. $d Prize Bond',
                                                    style: AppTextStyles.body),
                                              ))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          controller
                                              .selectedDenomination.value = val;
                                          draw.hasCheckResult.value = false;
                                        }
                                      },
                                    ),
                                  ),
                                )),
                            const SizedBox(height: 12),

                            // Bond Number Input
                            TextField(
                              controller: _bondInputController,
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              decoration: const InputDecoration(
                                hintText: 'Enter 6-digit Bond Number',
                                counterText: '',
                              ),
                              onChanged: (val) =>
                                  controller.bondNumber.value = val,
                            ),
                            const SizedBox(height: 12),

                            // Check Result Button
                            Obx(() => SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: draw.isChecking.value
                                        ? null
                                        : controller.checkBond,
                                    child: draw.isChecking.value
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2),
                                          )
                                        : const Text('Check Result',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600)),
                                  ),
                                )),

                            // ── RESULT DISPLAY ────────────────────────────────
                            Obx(() => draw.hasCheckResult.value
                                ? _buildResultCard(
                                    draw.isWinner.value,
                                    draw.checkedBondNumber.value,
                                    draw.selectedDenomination.value,
                                    draw.winningDraw?.drawNumber,
                                    draw.winningDraw?.city,
                                  )
                                : const SizedBox.shrink()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── LATEST DRAW RESULTS ───────────────────────────────────
                    SectionHeader(
                      title: 'Latest Draw Results',
                      actionLabel: 'View All',
                      onAction: () {
                        Get.find<NavController>().changePage(3);
                      },
                    ),
                    const SizedBox(height: 12),

                    Obx(() {
                      if (draw.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final latest = draw.draws.take(5).toList();
                      if (latest.isEmpty) {
                        return const Text('No draw results yet.',
                            style: AppTextStyles.bodySecondary);
                      }
                      return Column(
                        children: latest
                            .map((d) => _DrawResultTile(
                                  denomination: d.denomination,
                                  city: d.city,
                                  date: d.drawDate,
                                  drawNumber: d.drawNumber,
                                ))
                            .toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── SCANNER FAB ──────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final result = await Get.to(() => const ScannerScreen());
          if (result != null && result is String) {
            controller.fillFromScanner(result);
            _bondInputController.text = result;
          }
        },
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  Widget _buildResultCard(
    bool isWinner,
    String number,
    int denomination,
    int? drawNumber,
    String? city,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWinner
            ? AppColors.winning.withOpacity(0.1)
            : AppColors.notWinning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinner ? AppColors.winning : AppColors.notWinning,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isWinner ? Icons.emoji_events : Icons.cancel_outlined,
            color: isWinner ? AppColors.winning : AppColors.notWinning,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWinner ? '🎉 WINNER!' : 'Not a Winner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isWinner ? AppColors.winning : AppColors.notWinning,
                  ),
                ),
                Text(
                  'Bond #$number (Rs. $denomination)',
                  style: AppTextStyles.bodySecondary,
                ),
                if (isWinner && drawNumber != null && city != null)
                  Text(
                    'Draw #$drawNumber · $city',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Draw Result Tile ──────────────────────────────────────────────────────────
class _DrawResultTile extends StatelessWidget {
  final int denomination;
  final String city;
  final DateTime date;
  final int drawNumber;

  const _DrawResultTile({
    required this.denomination,
    required this.city,
    required this.date,
    required this.drawNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.emoji_events, color: AppColors.primary),
        ),
        title: Text('Rs. $denomination Draw #$drawNumber',
            style: AppTextStyles.heading3),
        subtitle: Text(
          '$city · ${DateFormat('yyyy-MM-dd').format(date)}',
          style: AppTextStyles.caption,
        ),
        trailing:
            const Icon(Icons.download_outlined, color: AppColors.textSecondary),
      ),
    );
  }
}
