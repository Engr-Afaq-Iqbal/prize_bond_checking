// lib/controllers/scanner_controller.dart
// Controls the bond scanner feature
// Simulates camera scanning (real implementation would use camera package)

import 'package:get/get.dart';

class ScannerController extends GetxController {
  final RxBool isScanning = false.obs;
  final RxString scannedNumber = ''.obs;
  final RxBool scanComplete = false.obs;

  // List of mock bond numbers that scanner "detects"
  // In real app: OCR would read the actual bond number from camera
  final List<String> mockScanResults = [
    '123456', '887766', '112233', '987654', '444555',
    '999888', '777666', '333222', '111000', '555444',
  ];

  // Simulate scanning a bond number
  // In a real implementation, this would open the device camera and use OCR
  Future<void> startScan() async {
    isScanning.value = true;
    scanComplete.value = false;
    scannedNumber.value = '';

    // Simulate camera processing time (1.5 seconds)
    await Future.delayed(const Duration(milliseconds: 1500));

    // Pick a random mock result (simulating OCR reading)
    final randomIndex = DateTime.now().millisecond % mockScanResults.length;
    scannedNumber.value = mockScanResults[randomIndex];

    isScanning.value = false;
    scanComplete.value = true;
  }

  // Reset scanner state
  void reset() {
    isScanning.value = false;
    scannedNumber.value = '';
    scanComplete.value = false;
  }
}
