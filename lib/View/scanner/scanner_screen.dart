// lib/screens/scanner/scanner_screen.dart
// Simulates camera scanning for prize bond numbers

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Theme/app_theme.dart';
import '../../controllers/scanner_controller.dart';

class ScannerScreen extends StatelessWidget {
  ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ScannerController controller = Get.put(ScannerController());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Bond Number'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.black87,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          size: 80, color: Colors.white24),
                      SizedBox(height: 16),
                      Text('Camera Preview',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 16)),
                      Text('(Simulated in this demo)',
                          style:
                              TextStyle(color: Colors.white24, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  width: 260,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.accent, width: 2.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Obx(() => controller.isScanning.value
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                  color: AppColors.accent),
                              SizedBox(height: 12),
                              Text('Scanning...',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 14)),
                            ],
                          ),
                        )
                      : const Center(
                          child: Text(
                            'Position bond number\nwithin frame',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        )),
                ),
                const Positioned(
                  bottom: 40,
                  child: Text(
                    'Hold steady and ensure good lighting',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(24),
            child: Obx(() {
              if (controller.scanComplete.value) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.winning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.winning.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.winning),
                          const SizedBox(width: 10),
                          Text(
                            'Scanned: ${controller.scannedNumber.value}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: controller.reset,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Retry'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => Get.back(
                                result: controller.scannedNumber.value),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Use This Number',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  const Text('Point camera at your bond number',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: controller.isScanning.value
                          ? null
                          : controller.startScan,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Tap to Scan',
                          style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
