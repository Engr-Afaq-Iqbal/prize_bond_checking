// lib/screens/my_bonds/my_bonds_screen.dart
// Shows user's saved prize bonds with auto-check results

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Theme/app_theme.dart';
import '../../Utils/common_widgets.dart';
import '../../Utils/mock_data.dart';
import '../../controllers/my_bonds_controller.dart';
import '../../models/bond_model.dart';
import '../settings/settings_screen.dart';

class MyBondsScreen extends StatelessWidget {
  MyBondsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MyBondsController controller = Get.put(MyBondsController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            AppHeader(
              title: 'My Portfolio',
              onSettingsTap: () => Get.to(() => SettingsScreen()),
            ),

            // Body
            Expanded(
              child: Obx(() {
                // Show loading while auto-checking
                if (controller.isAutoChecking.value) {
                  return const LoadingIndicator(
                      message: 'Auto-checking your bonds...');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Saved Bonds Header + Add Button ──────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Saved Bonds',
                              style: AppTextStyles.heading2),
                          ElevatedButton.icon(
                            onPressed: () => _showAddBondDialog(controller),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add New'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Bond List ─────────────────────────────────────────────
                    Expanded(
                      child: controller.savedBonds.isEmpty
                          ? const EmptyState(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'No Bonds Saved',
                              subtitle:
                                  'Tap "Add New" to start tracking your prize bonds',
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: controller.savedBonds.length,
                              itemBuilder: (context, index) {
                                return _BondCard(
                                  bond: controller.savedBonds[index],
                                  onDelete: () => controller.deleteBond(
                                      controller.savedBonds[index].id),
                                );
                              },
                            ),
                    ),

                    // ── Sign-in prompt for auto-check ────────────────────────
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.accentYellow.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_outlined,
                              color: AppColors.accentYellow, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.textPrimary),
                                children: [
                                  TextSpan(text: 'Sign into enable '),
                                  TextSpan(
                                    text: 'Auto-Check',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accentYellow),
                                  ),
                                  TextSpan(
                                      text: ' and cloud sync for your bonds.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // Show bottom sheet dialog to add a new bond
  void _showAddBondDialog(MyBondsController controller) {
    final TextEditingController numberCtrl = TextEditingController();
    final RxInt selectedDenom = 750.obs;

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
            const Text('Add New Bond', style: AppTextStyles.heading2),
            const SizedBox(height: 16),

            // Denomination picker
            const Text('Denomination', style: AppTextStyles.bodySecondary),
            const SizedBox(height: 6),
            Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedDenom.value,
                      isExpanded: true,
                      items: MockData.denominations
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text('Rs. $d'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) selectedDenom.value = v;
                      },
                    ),
                  ),
                )),
            const SizedBox(height: 12),

            // Bond number input
            const Text('Bond Number', style: AppTextStyles.bodySecondary),
            const SizedBox(height: 6),
            TextField(
              controller: numberCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g., 123456',
              ),
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  controller.addBond(numberCtrl.text, selectedDenom.value);
                  Get.back();
                },
                child: const Text('Save Bond'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

// ── Single Bond Card ───────────────────────────────────────────────────────────
class _BondCard extends StatelessWidget {
  final BondModel bond;
  final VoidCallback onDelete;

  const _BondCard({required this.bond, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Bond info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Denomination badge
                  DenominationBadge(denomination: bond.denomination),
                  const SizedBox(height: 8),
                  // Bond number (big and bold like in Figma)
                  Text(
                    bond.number,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Added: ${DateFormat('yyyy-MM-dd').format(bond.addedDate)}',
                    style: AppTextStyles.caption,
                  ),
                  // Show winner badge if won
                  if (bond.isWinner) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.winning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('🏆 WINNER',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.winning,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            // Delete button
            IconButton(
              onPressed: onDelete,
              icon:
                  const Icon(Icons.delete_outline, color: AppColors.accentRed),
            ),
          ],
        ),
      ),
    );
  }
}
