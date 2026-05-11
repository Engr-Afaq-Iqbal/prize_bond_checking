// lib/View/my_bonds/my_bonds_screen.dart
//
// Shows the user's saved prize bonds.
//
// AUTH WALL: If the user is NOT logged in, this screen shows a full-screen
//            "Sign In" prompt with no bond data visible at all.
//
// OFFLINE-FIRST: Bonds are stored locally; the sheet closes after save.
// AUTO-CHECK:    Checks bonds against draw results on open.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Theme/app_theme.dart';
import '../../Utils/common_widgets.dart';
import '../../Utils/mock_data.dart';
import '../../Controllers/my_bonds_controller.dart';
import '../../models/bond_model.dart';
import '../SignInPage/sign_in_page.dart';
import '../settings/settings_screen.dart';

class MyBondsScreen extends StatelessWidget {
  const MyBondsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Show the auth wall immediately — no need to create a controller yet
    if (FirebaseAuth.instance.currentUser == null) {
      return const _GuestWall();
    }

    // User is logged in — show the full bonds screen
    final MyBondsController controller = Get.put(MyBondsController());
    return _BondsBody(controller: controller);
  }
}

// ── Full-screen guest auth wall ────────────────────────────────────────────────
//
// Shown when no Firebase user is signed in.
// Contains an illustration, description, and Sign In / Create Account buttons.
class _GuestWall extends StatelessWidget {
  const _GuestWall();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Minimal header ───────────────────────────────────────────────
            AppHeader(
              title: 'My Portfolio',
              onSettingsTap: () => Get.to(() => SettingsScreen()),
            ),

            // ── Auth wall content ────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Lock icon illustration
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.07),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 28),

                    const Text(
                      'Your Bond Portfolio',
                      style: AppTextStyles.heading2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Sign in to save your prize bonds, check winning results, '
                      'and keep your portfolio synced across devices.',
                      style: AppTextStyles.bodySecondary,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // ── Sign In button ───────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Get.to(() => const SignInPage()),
                        icon: const Icon(Icons.login),
                        label: const Text('Sign In',
                            style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Create account link ──────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Get.to(() => const SignInPage()),
                        icon: const Icon(Icons.person_add_outlined),
                        label: const Text('Create Account',
                            style: TextStyle(fontSize: 16)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Offline note
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.accentYellow.withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.offline_bolt_outlined,
                              color: AppColors.accentYellow, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bonds sync to the cloud when you have internet. '
                              'They always load from your device first.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bonds body (logged-in users only) ─────────────────────────────────────────
class _BondsBody extends StatelessWidget {
  final MyBondsController controller;
  const _BondsBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            AppHeader(
              title: 'My Portfolio',
              onSettingsTap: () => Get.to(() => SettingsScreen()),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (controller.isAutoChecking.value) {
                  return const LoadingIndicator(
                      message: 'Auto-checking your bonds…');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header row with Add button ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Saved Bonds',
                              style: AppTextStyles.heading2),
                          ElevatedButton.icon(
                            onPressed: () => _showAddBondSheet(controller),
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

                    // ── Bond list or empty state ───────────────────────────────
                    Expanded(
                      child: Obx(() => controller.savedBonds.isEmpty
                          ? const EmptyState(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'No Bonds Saved',
                              subtitle:
                                  'Tap "Add New" to start tracking your bonds',
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: controller.savedBonds.length,
                              itemBuilder: (_, i) => _BondCard(
                                bond: controller.savedBonds[i],
                                onDelete: () => controller
                                    .deleteBond(controller.savedBonds[i].id),
                              ),
                            )),
                    ),

                    // ── Offline info strip ────────────────────────────────────
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.accentYellow.withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.offline_bolt_outlined,
                              color: AppColors.accentYellow, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bonds are saved on your device first. They sync to the cloud when you have internet.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary),
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

  // ── Add Bond Bottom Sheet ──────────────────────────────────────────────────
  void _showAddBondSheet(MyBondsController controller) {
    final TextEditingController numberCtrl = TextEditingController();
    final RxInt selectedDenom = 750.obs;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: Get.mediaQuery.viewInsets.bottom + 24,
        ),
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

            // Denomination dropdown
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
            const Text('Bond Number (6 digits)',
                style: AppTextStyles.bodySecondary),
            const SizedBox(height: 6),
            TextField(
              controller: numberCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: 'e.g. 123456',
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),

            // Save button — controller calls Get.back() inside addBond() on success
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    controller.addBond(numberCtrl.text, selectedDenom.value),
                child: const Text('Save Bond',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
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
                  DenominationBadge(denomination: bond.denomination),
                  const SizedBox(height: 8),
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
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.accentRed),
            ),
          ],
        ),
      ),
    );
  }
}
