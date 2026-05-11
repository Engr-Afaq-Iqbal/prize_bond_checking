// lib/View/marketplace/sell_bond_screen.dart
// Form screen to list a prize bond for sale on the marketplace.
//
// This screen can be opened in two ways:
//  1. "Add New Bond"  — all fields blank, user fills everything manually.
//  2. "From My Bonds" — bond number and denomination are pre-filled from
//     the saved-bonds list; user only needs to fill price, city, phone.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Theme/app_theme.dart';
import '../../Utils/mock_data.dart';

// ── IMPORTANT: import uses uppercase "Controllers" to match the file that was
// registered with Get.put() in MarketplaceScreen.
// Using a different casing (controllers vs Controllers) makes Dart treat them
// as two separate types — that causes the "is not a subtype" runtime crash.
import '../../Controllers/marketplace_controller.dart';

class SellBondScreen extends StatelessWidget {
  // Optional pre-filled values (passed when user selects "From My Bonds")
  final String? prefilledBondNumber;
  final int? prefilledDenomination;

  SellBondScreen({
    super.key,
    this.prefilledBondNumber,
    this.prefilledDenomination,
  });

  // Text controllers for all form fields
  late final TextEditingController _bondNumberCtrl =
      TextEditingController(text: prefilledBondNumber ?? '');
  late final TextEditingController _priceCtrl = TextEditingController();
  late final TextEditingController _cityCtrl = TextEditingController();
  late final TextEditingController _phoneCtrl = TextEditingController();

  // Selected denomination — starts from pre-filled value or default 750
  late final RxInt _selectedDenom =
      (prefilledDenomination ?? 750).obs;

  @override
  Widget build(BuildContext context) {
    // Get.find() looks up the controller that was already registered.
    // This works because marketplace_screen.dart uses the SAME import path.
    final MarketplaceController controller = Get.find<MarketplaceController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('List Bond for Sale'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info Banner ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Fill the details below. Buyers will contact you directly via WhatsApp.',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Bond Denomination (dropdown) ──────────────────────────────────
            _label('Bond Denomination *'),
            Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedDenom.value,
                      isExpanded: true,
                      // Show all available denominations as dropdown items
                      items: MockData.denominations
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text('Rs. $d Prize Bond'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) _selectedDenom.value = v;
                      },
                    ),
                  ),
                )),
            const SizedBox(height: 16),

            // ── Bond Number ───────────────────────────────────────────────────
            _label('Bond Number * (6 digits)'),
            TextField(
              controller: _bondNumberCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              // Grey out if pre-filled from My Bonds — user shouldn't change it
              readOnly: prefilledBondNumber != null,
              decoration: InputDecoration(
                hintText: 'e.g. 887766',
                counterText: '',
                fillColor: prefilledBondNumber != null
                    ? Colors.grey.shade100
                    : Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 16),

            // ── Asking Price ──────────────────────────────────────────────────
            _label('Asking Price (Rs.) *'),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g. 40500',
                prefixText: 'Rs. ',
              ),
            ),
            const SizedBox(height: 16),

            // ── City ──────────────────────────────────────────────────────────
            _label('Your City *'),
            TextField(
              controller: _cityCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Karachi',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // ── Phone / WhatsApp ──────────────────────────────────────────────
            _label('WhatsApp / Phone Number *'),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'e.g. 03001234567',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Buyers will contact you directly on WhatsApp.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // ── Submit Button ─────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // Parse price (returns 0 if text is not a valid number)
                  final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;

                  // Call controller — it validates, saves locally, then syncs
                  controller.addListing(
                    bondNumber: _bondNumberCtrl.text.trim(),
                    denomination: _selectedDenom.value,
                    price: price,
                    city: _cityCtrl.text.trim(),
                    phone: _phoneCtrl.text.trim(),
                  );
                },
                child: const Text(
                  'List for Sale',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for field labels
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppTextStyles.bodySecondary),
      );
}
