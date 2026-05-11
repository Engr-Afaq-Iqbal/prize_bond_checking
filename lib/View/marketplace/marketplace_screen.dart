// lib/View/marketplace/marketplace_screen.dart
//
// Marketplace — browse bonds for sale and list your own.
//
// AUTH WALL: If the user is NOT logged in, this screen shows a full-screen
//            "Sign In" prompt. No listings are visible to guests.
//
// SELL FLOW (logged-in users):
//   1. Tap "Sell Your Bond" CTA
//   2. Bottom sheet: "From My Saved Bonds" or "Add New Bond"
//   3. Sell form (SellBondScreen) → controller saves locally → syncs to Firebase

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controllers/marketplace_controller.dart';
import '../../Theme/app_theme.dart';
import '../../Utils/common_widgets.dart';
import '../../Utils/mock_data.dart';
import '../../Utils/storage_service.dart';
import '../../models/bond_model.dart';
import '../../Models/market_listing_model.dart';
import '../SignInPage/sign_in_page.dart';
import '../settings/settings_screen.dart';
import 'sell_bond_screen.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Show the full auth wall if user is not logged in.
    // No controller needed for the guest view.
    if (FirebaseAuth.instance.currentUser == null) {
      return const _GuestWall();
    }

    // Logged in — show the full marketplace
    final MarketplaceController controller = Get.put(MarketplaceController());
    return _MarketplaceBody(controller: controller);
  }
}

// ── Full-screen guest auth wall ────────────────────────────────────────────────
class _GuestWall extends StatelessWidget {
  const _GuestWall();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Marketplace',
              onSettingsTap: () => Get.to(() => SettingsScreen()),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.07),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.storefront_outlined,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 28),

                    const Text(
                      'Bond Marketplace',
                      style: AppTextStyles.heading2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Sign in to browse bonds for sale, contact sellers, '
                      'and list your own prize bonds on the marketplace.',
                      style: AppTextStyles.bodySecondary,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // Sign In button
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

                    // Create account button
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

                    // Feature preview hint
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _FeatureRow(
                            icon: Icons.search,
                            text: 'Browse bonds listed by sellers',
                          ),
                          const SizedBox(height: 10),
                          _FeatureRow(
                            icon: Icons.chat_outlined,
                            text: 'Contact sellers via WhatsApp',
                          ),
                          const SizedBox(height: 10),
                          _FeatureRow(
                            icon: Icons.sell_outlined,
                            text: 'List your own bonds for sale',
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

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(text, style: AppTextStyles.bodySecondary),
      ],
    );
  }
}

// ── Full marketplace body (logged-in users) ────────────────────────────────────
class _MarketplaceBody extends StatelessWidget {
  final MarketplaceController controller;
  const _MarketplaceBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Marketplace',
              onSettingsTap: () => Get.to(() => SettingsScreen()),
            ),
            Expanded(
              child: Column(
                children: [
                  // ── Title + Filter ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bond Marketplace', style: AppTextStyles.heading2),
                        IconButton(
                          icon: const Icon(Icons.filter_list,
                              color: AppColors.primary),
                          tooltip: 'Filter by denomination',
                          onPressed: () =>
                              _showFilterSheet(context, controller),
                        ),
                      ],
                    ),
                  ),

                  // ── Active filter chip ──────────────────────────────────────
                  Obx(() => controller.filterDenomination.value != 0
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Chip(
                                label: Text(
                                    'Rs. ${controller.filterDenomination.value}'),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () => controller.setFilter(0),
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.1),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink()),

                  // ── Listings ────────────────────────────────────────────────
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final listings = controller.filteredListings;

                      return RefreshIndicator(
                        onRefresh: controller.loadListings,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            ...listings.map((l) => _MarketCard(
                                  listing: l,
                                  onContact: () => controller.contactSeller(l),
                                )),
                            const SizedBox(height: 8),
                            _SellCta(controller: controller),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(
      BuildContext context, MarketplaceController controller) {
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

// ── Sell CTA ───────────────────────────────────────────────────────────────────
class _SellCta extends StatelessWidget {
  final MarketplaceController controller;
  const _SellCta({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSellMethodSheet(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(Icons.add_circle_outline,
                size: 32, color: AppColors.textSecondary),
            SizedBox(height: 8),
            Text('Sell Your Prize Bond', style: AppTextStyles.bodySecondary),
          ],
        ),
      ),
    );
  }

  void _showSellMethodSheet(BuildContext context) {
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
            const Text('How do you want to list?',
                style: AppTextStyles.heading2),
            const SizedBox(height: 6),
            const Text(
              'Choose a bond from your saved portfolio or enter a new one.',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 20),
            _OptionTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'From My Saved Bonds',
              subtitle: 'Pick a bond you already have in your portfolio',
              onTap: () {
                Get.back();
                _showBondPickerSheet(context);
              },
            ),
            const SizedBox(height: 12),
            _OptionTile(
              icon: Icons.add_circle_outline,
              title: 'Add New Bond',
              subtitle: 'Enter bond number and details manually',
              onTap: () {
                Get.back();
                Get.to(() => SellBondScreen());
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showBondPickerSheet(BuildContext context) {
    final StorageService storage = StorageService();
    final List<BondModel> myBonds = storage.getSavedBonds();

    if (myBonds.isEmpty) {
      Get.bottomSheet(
        Container(
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No Saved Bonds',
                  style: AppTextStyles.heading2, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'Go to "My Bonds" to add some first.',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                    onPressed: () => Get.back(), child: const Text('OK')),
              ),
            ],
          ),
        ),
      );
      return;
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a Bond to Sell', style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            const Text('Tap a bond to pre-fill the sell form.',
                style: AppTextStyles.bodySecondary),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: myBonds.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final bond = myBonds[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Rs. ${bond.denomination}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      bond.number,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textSecondary),
                    onTap: () {
                      Get.back();
                      Get.to(() => SellBondScreen(
                            prefilledBondNumber: bond.number,
                            prefilledDenomination: bond.denomination,
                          ));
                    },
                  );
                },
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

// ── Option tile ────────────────────────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Marketplace card ───────────────────────────────────────────────────────────
class _MarketCard extends StatelessWidget {
  final MarketListingModel listing;
  final VoidCallback onContact;

  const _MarketCard({required this.listing, required this.onContact});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DenominationBadge(denomination: listing.denomination),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Asking Price', style: AppTextStyles.caption),
                    Text(
                      'Rs. ${listing.askingPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Bond # ${listing.bondNumber}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.border,
                  child: Icon(Icons.person,
                      size: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Text(
                  '${listing.sellerName}, ${listing.sellerCity}',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onContact,
                icon: Icon(
                  listing.sellerPhone.isNotEmpty
                      ? Icons.chat
                      : Icons.chat_bubble_outline,
                  size: 18,
                ),
                label: Text(listing.sellerPhone.isNotEmpty
                    ? 'Contact on WhatsApp'
                    : 'Contact Seller'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: listing.sellerPhone.isNotEmpty
                      ? const Color(0xFF25D366)
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
