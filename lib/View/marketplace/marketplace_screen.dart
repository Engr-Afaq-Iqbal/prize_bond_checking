// lib/screens/marketplace/marketplace_screen.dart
// Bond buy/sell marketplace

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:prize_bond_app/View/marketplace/sell_bond_screen.dart';

import '../../Theme/app_theme.dart';
import '../../Utils/common_widgets.dart';
import '../../Utils/mock_data.dart';
import '../../Controllers/marketplace_controller.dart';
import '../../Models/market_listing_model.dart';
import '../settings/settings_screen.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MarketplaceController controller = Get.put(MarketplaceController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            AppHeader(
              title: 'Marketplace',
              onSettingsTap: () => Get.to(() => SettingsScreen()),
            ),

            // Body
            Expanded(
              child: Column(
                children: [
                  // ── Title + Filter ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bond Marketplace', style: AppTextStyles.heading2),
                        // Filter button
                        IconButton(
                          icon: const Icon(Icons.filter_list,
                              color: AppColors.primary),
                          onPressed: () => _showFilterSheet(controller),
                        ),
                      ],
                    ),
                  ),

                  // ── Filter chips ───────────────────────────────────────────
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

                  // ── Listings ───────────────────────────────────────────────
                  Expanded(
                    child: Obx(() {
                      final listings = controller.filteredListings;
                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          ...listings
                              .map((l) => _MarketCard(
                                    listing: l,
                                    onContact: () =>
                                        controller.contactSeller(l),
                                  ))
                              .toList(),

                          // ── Sell Your Bond CTA ────────────────────────────
                          GestureDetector(
                            onTap: () => Get.to(() => SellBondScreen()),
                            child: Container(
                              margin: const EdgeInsets.only(top: 4, bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.border,
                                    style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.add_circle_outline,
                                      size: 32, color: AppColors.textSecondary),
                                  SizedBox(height: 8),
                                  Text('Sell Your Prize Bond',
                                      style: AppTextStyles.bodySecondary),
                                ],
                              ),
                            ),
                          ),
                        ],
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

  // Show denomination filter bottom sheet
  void _showFilterSheet(MarketplaceController controller) {
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
                // "All" chip
                Obx(() => FilterChip(
                      label: const Text('All'),
                      selected: controller.filterDenomination.value == 0,
                      onSelected: (_) {
                        controller.setFilter(0);
                        Get.back();
                      },
                    )),
                // Denomination chips
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

// ── Marketplace Card ───────────────────────────────────────────────────────────
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
            // Top row: denomination badge + price
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

            // Bond number
            Text('Number: ${listing.bondNumber}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),

            // Seller info
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

            // Contact Seller button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onContact,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Contact Seller'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
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
