// lib/screens/marketplace/sell_bond_screen.dart
// Screen to list your own bond for sale

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Theme/app_theme.dart';
import '../../Utils/mock_data.dart';
import '../../controllers/marketplace_controller.dart';

class SellBondScreen extends StatelessWidget {
  SellBondScreen({super.key});

  final TextEditingController _bondNumberCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final RxInt _selectedDenom = 750.obs;

  @override
  Widget build(BuildContext context) {
    final MarketplaceController controller = Get.find<MarketplaceController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sell Your Bond'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
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
                      'List your prize bond for sale. Buyers can contact you directly.',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Denomination ──────────────────────────────────────────────────
            _fieldLabel('Bond Denomination *'),
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
            _fieldLabel('Bond Number *'),
            TextField(
              controller: _bondNumberCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g., 887766',
              ),
            ),
            const SizedBox(height: 16),

            // ── Asking Price ──────────────────────────────────────────────────
            _fieldLabel('Asking Price (Rs.) *'),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g., 40500',
                prefixText: 'Rs. ',
              ),
            ),
            const SizedBox(height: 16),

            // ── Location ──────────────────────────────────────────────────────
            _fieldLabel('Your City / Location'),
            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g., Karachi',
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit Button ─────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final price = double.tryParse(_priceCtrl.text) ?? 0;
                  controller.addListing(
                    bondNumber: _bondNumberCtrl.text,
                    denomination: _selectedDenom.value,
                    price: price,
                    city: _locationCtrl.text,
                  );
                },
                child:
                    const Text('List for Sale', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to create a field label
  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppTextStyles.bodySecondary),
    );
  }
}
