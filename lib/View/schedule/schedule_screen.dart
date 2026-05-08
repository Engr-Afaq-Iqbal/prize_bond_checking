// lib/screens/schedule/schedule_screen.dart
// Shows the annual draw schedule with download option

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Theme/app_theme.dart';
import '../../Utils/common_widgets.dart';
import '../../Utils/mock_data.dart';
import '../../controllers/schedule_controller.dart';
import '../../models/schedule_model.dart';
import '../settings/settings_screen.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ScheduleController controller = Get.put(ScheduleController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            AppHeader(
              title: 'Schedules',
              onSettingsTap: () => Get.to(() => SettingsScreen()),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title + Filter ─────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Draw Schedule 2025',
                            style: AppTextStyles.heading2),
                        IconButton(
                          icon: const Icon(Icons.filter_list,
                              color: AppColors.primary),
                          onPressed: () => _showFilterSheet(controller),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Schedule Table ─────────────────────────────────────────
                    Expanded(
                      child: Card(
                        child: Column(
                          children: [
                            // Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: const BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text('DATE',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text('BOND',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text('CITY',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary)),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),

                            // Table Rows
                            Expanded(
                              child: Obx(() {
                                final schedules = controller.filteredSchedules;
                                return ListView.separated(
                                  itemCount: schedules.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    return _ScheduleRow(
                                        schedule: schedules[index]);
                                  },
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Download PDF Button ────────────────────────────────────
                    Obx(() => SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: controller.isDownloading.value
                                ? null
                                : controller.downloadPdf,
                            icon: controller.isDownloading.value
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary),
                                  )
                                : const Icon(Icons.download_outlined),
                            label: Text(
                              controller.isDownloading.value
                                  ? 'Downloading...'
                                  : 'Download Yearly Schedule (PDF)',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(ScheduleController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by Denomination', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Obx(() => FilterChip(
                      label: const Text('All'),
                      selected: controller.filterDenomination.value == 0,
                      onSelected: (_) {
                        controller.setFilter(0);
                        Get.back();
                      },
                    )),
                ...MockData.denominations.map((d) => Obx(() => FilterChip(
                      label: Text('Rs. $d'),
                      selected: controller.filterDenomination.value == d,
                      onSelected: (_) {
                        controller.setFilter(d);
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

// ── Schedule Row ───────────────────────────────────────────────────────────────
class _ScheduleRow extends StatelessWidget {
  final ScheduleModel schedule;

  const _ScheduleRow({required this.schedule});

  @override
  Widget build(BuildContext context) {
    // Highlight upcoming draws (within next 30 days)
    final isUpcoming = schedule.drawDate
        .isAfter(DateTime.now().subtract(const Duration(days: 1)));

    return Container(
      color: isUpcoming ? AppColors.primary.withOpacity(0.03) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              DateFormat('MMM dd, yyyy').format(schedule.drawDate),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isUpcoming ? FontWeight.w600 : FontWeight.normal,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Rs. ${schedule.denomination}',
              style: AppTextStyles.body,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              schedule.city,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
