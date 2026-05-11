// lib/View/settings/settings_screen.dart
// App settings — Preferences and Account sections only.
// Language and Clear Saved Bonds have been removed per requirements.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controllers/settings_controller.dart';
import '../../Theme/app_theme.dart';
import '../Profile/profile_screen.dart';
import '../SignInPage/sign_in_page.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = Get.put(SettingsController());
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── PREFERENCES SECTION ───────────────────────────────────────────
            _SectionLabel(label: 'PREFERENCES'),

            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Notifications toggle
                  Obx(() => _SettingsTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Get alerts when your bond wins',
                        trailing: Switch(
                          value: controller.notificationsEnabled.value,
                          onChanged: controller.toggleNotifications,
                          activeColor: AppColors.primary,
                        ),
                      )),
                  const Divider(height: 1, indent: 56),

                  // Auto-check toggle
                  Obx(() => _SettingsTile(
                        icon: Icons.autorenew_outlined,
                        title: 'Auto-Check',
                        subtitle: 'Automatically check bonds on new draws',
                        trailing: Switch(
                          value: controller.autoCheckEnabled.value,
                          onChanged: controller.toggleAutoCheck,
                          activeColor: AppColors.primary,
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── ACCOUNT SECTION ───────────────────────────────────────────────
            _SectionLabel(label: 'ACCOUNT'),

            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // My Profile tile
                  // • Logged in  → navigate to ProfileScreen
                  // • Logged out → show a login/register bottom sheet
                  _SettingsTile(
                    icon: Icons.person_outline,
                    title: 'My Profile',
                    subtitle: isLoggedIn
                        ? 'View your account details'
                        : 'Login to view your profile',
                    iconColor: AppColors.primary,
                    onTap: () {
                      if (isLoggedIn) {
                        Get.to(() => const ProfileScreen());
                      } else {
                        _showLoginPrompt();
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),

                  // Logout (logged in) or Sign In (guest)
                  isLoggedIn
                      ? _SettingsTile(
                          icon: Icons.logout,
                          title: 'Logout',
                          subtitle: 'Sign out from your account',
                          iconColor: AppColors.accentRed,
                          onTap: controller.logout,
                        )
                      : _SettingsTile(
                          icon: Icons.login,
                          title: 'Sign In',
                          subtitle: 'Log in to save bonds and use marketplace',
                          iconColor: AppColors.primary,
                          onTap: () => Get.to(() => const SignInPage()),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // App version footer
            const Center(
              child: Text(
                'Prize Bond App v1.0.0\nFYP Project – CS619',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Bottom sheet shown when a guest taps "My Profile"
  void _showLoginPrompt() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Icon
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Login to view your profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'Sign in to access your profile, saved bonds, and all premium features.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 28),

            // Login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  Get.to(() => const SignInPage());
                },
                icon: const Icon(Icons.login),
                label: const Text('Login', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Register button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Get.back();
                  Get.to(() => const SignInPage());
                },
                icon: const Icon(Icons.person_add_outlined),
                label:
                    const Text('Register', style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

// ── Reusable Section Label ─────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Reusable Settings Tile ─────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon box
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.heading3),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),

            // Trailing widget or right arrow
            trailing ??
                (onTap != null
                    ? const Icon(Icons.chevron_right,
                        color: AppColors.textSecondary)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
