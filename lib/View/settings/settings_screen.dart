// lib/screens/settings/settings_screen.dart
// App settings page with toggles and preferences

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Theme/app_theme.dart';
import '../../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = Get.put(SettingsController());

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
            // ── Section: Preferences ──────────────────────────────────────────
            _SectionLabel(label: 'PREFERENCES'),

            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Notifications Toggle
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

                  // Auto-Check Toggle
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

            // ── Section: Language ─────────────────────────────────────────────
            _SectionLabel(label: 'LANGUAGE'),

            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() => Column(
                    children: controller.availableLanguages.map((lang) {
                      final isSelected =
                          controller.selectedLanguage.value == lang;
                      return Column(
                        children: [
                          InkWell(
                            onTap: () => controller.changeLanguage(lang),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  const Icon(Icons.language,
                                      color: AppColors.primary, size: 22),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child:
                                        Text(lang, style: AppTextStyles.body),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check,
                                        color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                          if (lang != controller.availableLanguages.last)
                            const Divider(height: 1, indent: 56),
                        ],
                      );
                    }).toList(),
                  )),
            ),
            const SizedBox(height: 20),

            // ── Section: Data ─────────────────────────────────────────────────
            _SectionLabel(label: 'DATA'),

            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Clear Saved Bonds
                  _SettingsTile(
                    icon: Icons.delete_sweep_outlined,
                    title: 'Clear Saved Bonds',
                    subtitle: 'Remove all bonds from your portfolio',
                    iconColor: AppColors.accentRed,
                    onTap: controller.clearAllBonds,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section: Account ──────────────────────────────────────────────
            _SectionLabel(label: 'ACCOUNT'),

            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: _SettingsTile(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out from your account',
                iconColor: AppColors.accentRed,
                onTap: controller.logout,
              ),
            ),
            const SizedBox(height: 32),

            // App version info
            const Center(
              child: Text(
                'Prize Bond App v1.0.0\nFYP Project - CS619',
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
}

// ── Section Label ──────────────────────────────────────────────────────────────
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

// ── Settings Tile ──────────────────────────────────────────────────────────────
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
            // Icon
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

            // Trailing widget or chevron
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
