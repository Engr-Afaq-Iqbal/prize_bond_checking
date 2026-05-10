// lib/View/scanner/scanner_screen.dart
// Real camera scanner with ML Kit OCR for prize bond number recognition

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Theme/app_theme.dart';
import '../../Controllers/scanner_controller.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

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
      body: Obx(() {
        // Camera permission denied
        if (controller.cameraPermissionDenied.value) {
          return _PermissionDeniedView();
        }

        // Scan complete → show result
        if (controller.scanComplete.value) {
          return _ScanResultView(controller: controller);
        }

        // Camera not ready yet
        if (!controller.isCameraReady.value) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text('Initializing camera…',
                    style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
        }

        // Live camera view
        return _CameraView(controller: controller);
      }),
    );
  }
}

// ── Live Camera View ───────────────────────────────────────────────────────────
class _CameraView extends StatelessWidget {
  final ScannerController controller;
  const _CameraView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        CameraPreview(controller.cameraController!),

        // Scanning overlay
        Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dark overlay with transparent center window
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.55),
                      BlendMode.srcOut,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            backgroundBlendMode: BlendMode.dstOut,
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 280,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Frame border
                  Container(
                    width: 280,
                    height: 110,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: AppColors.accent, width: 2.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  // Animated scan line
                  Obx(() => controller.isScanning.value
                      ? const SizedBox.shrink()
                      : _ScanLine()),

                  // Instruction text
                  const Positioned(
                    bottom: 40,
                    child: Text(
                      'Align bond number inside the frame',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom controls
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(24),
              child: Obx(() => Column(
                    children: [
                      const Text(
                        'Point camera at your bond number — it scans automatically',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: controller.isScanning.value
                              ? null
                              : controller.captureAndScan,
                          icon: controller.isScanning.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.camera),
                          label: Text(
                            controller.isScanning.value
                                ? 'Scanning…'
                                : 'Capture & Scan',
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  )),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Scan Result View ──────────────────────────────────────────────────────────
class _ScanResultView extends StatelessWidget {
  final ScannerController controller;
  const _ScanResultView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: AppColors.winning, size: 72),
        const SizedBox(height: 24),
        const Text('Number Detected!',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.winning.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.winning.withOpacity(0.4)),
          ),
          child: Text(
            controller.scannedNumber.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
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
                  onPressed: () =>
                      Get.back(result: controller.scannedNumber.value),
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
        ),
      ],
    );
  }
}

// ── Permission Denied View ─────────────────────────────────────────────────────
class _PermissionDeniedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                size: 64, color: Colors.white38),
            const SizedBox(height: 20),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Please grant camera access to scan prize bond numbers.',
              style: TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated Scan Line ─────────────────────────────────────────────────────────
class _ScanLine extends StatefulWidget {
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _pos;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pos = Tween<double>(begin: -40, end: 40).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pos,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _pos.value),
        child: Container(
          width: 260,
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.8),
            borderRadius: BorderRadius.circular(1),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 2,
              )
            ],
          ),
        ),
      ),
    );
  }
}
