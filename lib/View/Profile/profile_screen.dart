// lib/View/Profile/profile_screen.dart
//
// Displays the logged-in user's profile.
// Shows a clean login/register UI for guests — no endless spinner.
//
// Fields shown: Full Name, Email, City, Role, Status, Member Since
// Fields intentionally excluded: Password, PIN, Saved Bonds Count

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Controllers/AuthControllers/auth_controller.dart';
import '../../Controllers/user_controller.dart';
import '../../Theme/app_theme.dart';
import '../../models/user_model.dart';
import '../SignInPage/sign_in_page.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // ── Guest (not logged in at all) ──────────────────────────────────────────
    if (firebaseUser == null) {
      return const _GuestProfile();
    }

    // ── Logged in — show profile reactively ───────────────────────────────────
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          final user = UserController.to.currentUser.value;

          // No cached profile yet — show a minimal profile using Firebase Auth
          // data (email) so there is never an endless spinner.
          if (user == null) {
            return _MinimalProfile(firebaseUser: firebaseUser);
          }

          // Full profile loaded from Firestore / local cache
          return _FullProfile(user: user);
        }),
      ),
    );
  }
}

// ── Guest profile (not logged in) ─────────────────────────────────────────────
//
// Clean screen with Login and Register buttons.
// No spinner — shown immediately when user is a guest.
class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Back button row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => Get.back(),
                  ),
                  const Text('My Profile', style: AppTextStyles.heading2),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Person icon
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline,
                          size: 60, color: AppColors.primary),
                    ),
                    const SizedBox(height: 28),

                    const Text(
                      'Login to view your profile',
                      style: AppTextStyles.heading2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      'Sign in to access your profile, saved bonds, and all app features.',
                      style: AppTextStyles.bodySecondary,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Get.to(() => const SignInPage()),
                        icon: const Icon(Icons.login),
                        label: const Text('Login',
                            style: TextStyle(fontSize: 16)),
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
                        onPressed: () => Get.to(() => const SignInPage()),
                        icon: const Icon(Icons.person_add_outlined),
                        label: const Text('Register',
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

// ── Minimal profile (logged in but Firestore data not yet loaded) ──────────────
//
// Shown briefly while UserController fetches the full profile.
// Uses data already available from FirebaseAuth (email) to avoid a blank
// spinner screen. This should only appear for a second at most.
class _MinimalProfile extends StatelessWidget {
  final User firebaseUser;
  const _MinimalProfile({required this.firebaseUser});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AppBar(showLogoutButton: false),

        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar with first letter of email
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A3C40),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (firebaseUser.email ?? '?')[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    firebaseUser.email ?? 'Loading profile…',
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(height: 8),
                  const Text('Loading profile…',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Full profile (all data loaded) ────────────────────────────────────────────
class _FullProfile extends StatelessWidget {
  final UserModel user;
  const _FullProfile({required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _AppBar(showLogoutButton: true),

          // ── Gradient avatar card ─────────────────────────────────────────
          _AvatarCard(user: user),
          const SizedBox(height: 20),

          // ── Personal Information ─────────────────────────────────────────
          _InfoSection(
            title: 'Personal Information',
            tiles: [
              _InfoTile(
                icon: Icons.person_outline,
                label: 'Full Name',
                value: user.fullName.trim().isEmpty ? 'Not set' : user.fullName,
              ),
              _InfoTile(
                icon: Icons.email_outlined,
                label: 'Email Address',
                value: user.email.isEmpty ? 'Not set' : user.email,
              ),
              _InfoTile(
                icon: Icons.location_city_outlined,
                label: 'City',
                value: user.city.isEmpty ? 'Not set' : user.city,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Account Details ──────────────────────────────────────────────
          _InfoSection(
            title: 'Account Details',
            tiles: [
              _InfoTile(
                icon: Icons.badge_outlined,
                label: 'Account Type',
                value: user.isAdmin ? 'Admin' : 'Normal User',
                valueColor: user.isAdmin
                    ? const Color(0xFF7C4DFF)
                    : AppColors.primary,
              ),
              _InfoTile(
                icon: Icons.verified_outlined,
                label: 'Status',
                value: _statusLabel(user.status),
                valueColor: _statusColor(user.status),
              ),
              _InfoTile(
                icon: Icons.calendar_today_outlined,
                label: 'Member Since',
                value: DateFormat('MMMM yyyy').format(user.createdAt),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Sign Out button ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout, color: AppColors.accentRed),
                label: const Text('Sign Out',
                    style: TextStyle(
                        color: AppColors.accentRed, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.accentRed),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _confirmLogout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.find<AuthController>().signOut();
            },
            child: const Text('Sign Out',
                style: TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':    return 'Active';
      case 'pending':   return 'Pending Approval';
      case 'suspended': return 'Suspended';
      default:          return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':    return const Color(0xFF4CAF50);
      case 'pending':   return Colors.orange;
      case 'suspended': return AppColors.accentRed;
      default:          return AppColors.textSecondary;
    }
  }
}

// ── App bar ────────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final bool showLogoutButton;
  const _AppBar({required this.showLogoutButton});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Get.back(),
          ),
          const Expanded(
            child: Text('My Profile', style: AppTextStyles.heading2),
          ),
        ],
      ),
    );
  }
}

// ── Avatar card with gradient ──────────────────────────────────────────────────
class _AvatarCard extends StatelessWidget {
  final UserModel user;
  const _AvatarCard({required this.user});

  // Get two-letter initials from name
  String get _initials {
    final first = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final last  = user.lastName.isNotEmpty  ? user.lastName[0]  : '';
    final combo = (first + last).toUpperCase();
    return combo.isEmpty ? '?' : combo;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3C40), Color(0xFF2E7D6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3C40).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circle with initials
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Name + role chip
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.trim().isEmpty
                      ? user.email
                      : user.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.isAdmin ? '⭐ Admin' : 'Normal User',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                if (user.city.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        user.city,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info section card ──────────────────────────────────────────────────────────
class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoTile> tiles;
  const _InfoSection({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.3,
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            color: Colors.white,
            child: Column(
              children: [
                for (int i = 0; i < tiles.length; i++) ...[
                  tiles[i],
                  if (i < tiles.length - 1)
                    const Divider(height: 1, indent: 56, endIndent: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single info tile ───────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon box
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),

          // Label + value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
