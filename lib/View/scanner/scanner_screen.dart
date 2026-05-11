// lib/View/scanner/scanner_screen.dart
//
// QR Code Scanner Screen.
//
// Flow:
//   1. Camera opens → automatically scans for QR codes.
//   2. When a valid 6-digit QR is detected → scanner pauses → result shown.
//   3. "Scan Again" → resumes scanner.
//   4. "Use This Number" → passes number back to the previous screen.
//
// Uses mobile_scanner package instead of camera + ML Kit OCR.
// This gives real QR decoding (not OCR guesswork) with instant detection.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../Controllers/scanner_controller.dart';
import '../../Theme/app_theme.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get.put creates the controller — it is disposed automatically when the
    // screen is popped (because we did NOT use permanent: true here).
    final ScannerController controller = Get.put(ScannerController());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Bond QR Code'),
        centerTitle: true,
      ),
      body: Obx(() {
        // Show result screen after successful scan
        if (controller.scanComplete.value) {
          return _ScanResultView(controller: controller);
        }

        // Show live camera view
        return _CameraView(controller: controller);
      }),
    );
  }
}

// ── Live Camera View ───────────────────────────────────────────────────────────
//
// Full-screen camera feed with a square scan box overlay.
// Scanning is fully automatic — no button press needed.
class _CameraView extends StatelessWidget {
  final ScannerController controller;
  const _CameraView({required this.controller});

  // Square scan box size in logical pixels
  static const double _boxSize = 270.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── MobileScanner: full-screen camera + auto QR detection ─────────────
        // errorBuilder handles permission denied / camera errors gracefully.
        MobileScanner(
          controller: controller.mobileScannerCtrl,
          onDetect: controller.onBarcodeDetected,
          errorBuilder: (context, error, child) {
            return _CameraErrorView(error: error);
          },
        ),

        // ── Dark overlay with transparent square cut-out ───────────────────────
        // ColorFiltered + BlendMode.srcOut "punches a hole" in the dark overlay,
        // revealing the camera feed only inside the scan box.
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.62),
            BlendMode.srcOut,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Dark background
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              // The transparent "window" — this becomes the clear scan area
              Center(
                child: Container(
                  width: _boxSize,
                  height: _boxSize,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Animated corner brackets ──────────────────────────────────────────
        Center(
          child: SizedBox(
            width: _boxSize,
            height: _boxSize,
            child: const _CornerBrackets(),
          ),
        ),

        // ── Animated scan line (sweeps up and down) ───────────────────────────
        Center(
          child: SizedBox(
            width: _boxSize,
            height: _boxSize,
            child: const _ScanLine(boxSize: _boxSize),
          ),
        ),

        // ── Instruction labels below the box ──────────────────────────────────
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Column(
            children: [
              const Text(
                'Point at prize bond QR code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Scanner detects automatically — no button needed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'QR must encode exactly 6 digits',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Camera Error View (permission denied or hardware error) ───────────────────
class _CameraErrorView extends StatelessWidget {
  final MobileScannerException error;
  const _CameraErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    // Determine the message based on error type
    final bool isPermission =
        error.errorCode == MobileScannerErrorCode.permissionDenied;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermission ? Icons.camera_alt_outlined : Icons.error_outline,
              size: 64,
              color: Colors.white38,
            ),
            const SizedBox(height: 20),
            Text(
              isPermission
                  ? 'Camera Permission Required'
                  : 'Camera Unavailable',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isPermission
                  ? 'Please grant camera access to scan QR codes.\n'
                      'Go to Settings → App → Camera and enable it.'
                  : 'Could not open the camera.\n'
                      'Please restart the app and try again.',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
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

// ── Animated Corner Brackets ──────────────────────────────────────────────────
//
// Four L-shaped corners that gently pulse in opacity — classic scanner effect.
class _CornerBrackets extends StatefulWidget {
  const _CornerBrackets();

  @override
  State<_CornerBrackets> createState() => _CornerBracketsState();
}

class _CornerBracketsState extends State<_CornerBrackets>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: CustomPaint(
          painter: _CornerPainter(color: AppColors.accent),
        ),
      ),
    );
  }
}

// Draws four L-shaped corners using CustomPainter
class _CornerPainter extends CustomPainter {
  final Color color;
  const _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const double armLen = 32.0; // Length of each L arm
    const double radius = 12.0; // Rounding radius at corner

    _drawCorner(canvas, paint, size, _Corner.topLeft, armLen, radius);
    _drawCorner(canvas, paint, size, _Corner.topRight, armLen, radius);
    _drawCorner(canvas, paint, size, _Corner.bottomLeft, armLen, radius);
    _drawCorner(canvas, paint, size, _Corner.bottomRight, armLen, radius);
  }

  void _drawCorner(Canvas canvas, Paint paint, Size size, _Corner corner,
      double len, double r) {
    final path = Path();
    double x, y;

    switch (corner) {
      case _Corner.topLeft:
        x = 0; y = 0;
        path.moveTo(x, y + len);
        path.quadraticBezierTo(x, y, x + r, y);
        path.lineTo(x + len, y);
        break;
      case _Corner.topRight:
        x = size.width; y = 0;
        path.moveTo(x - len, y);
        path.quadraticBezierTo(x, y, x, y + r);
        path.lineTo(x, y + len);
        break;
      case _Corner.bottomLeft:
        x = 0; y = size.height;
        path.moveTo(x, y - len);
        path.quadraticBezierTo(x, y, x + r, y);
        path.lineTo(x + len, y);
        break;
      case _Corner.bottomRight:
        x = size.width; y = size.height;
        path.moveTo(x - len, y);
        path.quadraticBezierTo(x, y, x, y - r);
        path.lineTo(x, y - len);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

// ── Animated Scan Line ────────────────────────────────────────────────────────
//
// A glowing horizontal line that sweeps up and down inside the scan box.
class _ScanLine extends StatefulWidget {
  final double boxSize;
  const _ScanLine({required this.boxSize});

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

    final half = widget.boxSize / 2 - 22;
    _pos = Tween<double>(begin: -half, end: half).animate(
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
        child: Center(
          child: Container(
            width: widget.boxSize - 24,
            height: 2.5,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.85),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.45),
                  blurRadius: 8,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Scan Result View ──────────────────────────────────────────────────────────
//
// Shown after a successful scan. User can retry or use the number.
class _ScanResultView extends StatelessWidget {
  final ScannerController controller;
  const _ScanResultView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.qr_code_scanner, color: AppColors.winning, size: 72),
        const SizedBox(height: 24),
        const Text(
          'QR Code Detected!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Display the scanned bond number
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
              fontSize: 38,
              fontWeight: FontWeight.bold,
              letterSpacing: 10,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '6-digit prize bond number',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 32),

        // Retry / Use buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              // Scan Again
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
                  child: const Text('Scan Again'),
                ),
              ),
              const SizedBox(width: 12),

              // Use this number — return it to the caller
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
                  child: const Text(
                    'Use This Number',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
