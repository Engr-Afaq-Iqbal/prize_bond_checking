// lib/Controllers/scanner_controller.dart
//
// QR Code Scanner Controller using mobile_scanner package.
//
// How it works:
//   1. MobileScannerController (from mobile_scanner package) opens the camera
//      and automatically scans for QR codes in real time.
//   2. Every time a QR code is detected, onBarcodeDetected() is called.
//   3. We validate that the scanned value is EXACTLY 6 digits (Pakistan prize bonds).
//   4. On valid scan → store the number + pause the scanner.
//   5. User taps "Use This Number" → result returned to previous screen.
//   6. User taps "Scan Again" → reset state + resume scanner.
//
// NOTE: There is NO fake/random number generation anywhere in this file.
//       The scanned value comes 100% from the actual QR code.

import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerController extends GetxController {
  // ── mobile_scanner controller ──────────────────────────────────────────────
  //
  // DetectionSpeed.noDuplicates → prevents the same QR code from triggering
  // multiple callbacks in a row (avoids double-processing).
  final MobileScannerController mobileScannerCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  // ── Observable state (Obx watches these) ──────────────────────────────────
  final RxBool scanComplete = false.obs;      // true once a valid QR is found
  final RxString scannedNumber = ''.obs;      // the 6-digit bond number

  @override
  void onClose() {
    // Always dispose the camera controller when leaving the screen
    mobileScannerCtrl.dispose();
    super.onClose();
  }

  // ── QR Detection Callback ─────────────────────────────────────────────────
  //
  // Called automatically by MobileScanner every time it detects a barcode.
  // We receive a BarcodeCapture object that may contain multiple barcodes.
  void onBarcodeDetected(BarcodeCapture capture) {
    // If we already have a result, ignore new detections
    if (scanComplete.value) return;

    // Get the first detected barcode
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;

    // rawValue is the exact string encoded in the QR code
    final rawValue = barcode.rawValue?.trim() ?? '';
    if (rawValue.isEmpty) return;

    // ── Validation ────────────────────────────────────────────────────────
    // Pakistan prize bonds are always EXACTLY 6 digits (e.g. 123456).
    // We reject anything else to prevent false positives from other QR codes
    // in the environment (product barcodes, Wi-Fi QR codes, etc.).
    if (!RegExp(r'^\d{6}$').hasMatch(rawValue)) {
      // Not a valid bond number — ignore silently (scanner keeps running)
      return;
    }

    // ── Valid bond number found! ───────────────────────────────────────────
    scannedNumber.value = rawValue;
    scanComplete.value = true;

    // Pause the scanner — user now sees the result screen
    mobileScannerCtrl.stop();
  }

  // ── Reset + Resume ────────────────────────────────────────────────────────
  //
  // Called when user taps "Scan Again" on the result screen.
  Future<void> reset() async {
    scannedNumber.value = '';
    scanComplete.value = false;
    // Resume the camera and start scanning again
    await mobileScannerCtrl.start();
  }
}
