// lib/View/scanner/scanner_screen.dart
//
// Real camera scanner with ML Kit OCR.
// The scanner box is now square (QR codes are square) and much larger so
// the user does not need to hold their phone far from the bond.

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controllers/scanner_controller.dart';
import '../../Theme/app_theme.dart';

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

        // Scan complete → show result screen
        if (controller.scanComplete.value) {
          return _ScanResultView(controller: controller);
        }

        // Camera still initializing
        if (!controller.isCameraReady.value) {
          return const _LoadingView();
        }

        // Live camera feed with overlay
        return _CameraView(controller: controller);
      }),
    );
  }
}

// ── Loading view (camera initializing) ────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
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
}

// ── Live Camera View ───────────────────────────────────────────────────────────
class _CameraView extends StatelessWidget {
  final ScannerController controller;
  const _CameraView({required this.controller});

  // The scanner box is square — QR codes are always square.
  // Larger box = user can scan from closer distance (more comfortable).
  static const double _boxSize = 270.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Full-screen camera preview ────────────────────────────────────────
        CameraPreview(controller.cameraController!),

        // ── Dark overlay with transparent square window ───────────────────────
        // We use ColorFiltered + BlendMode to cut a transparent hole in the
        // dark overlay, revealing the camera feed in the scan area only.
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.60),
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
              // Transparent square in the center (the scan zone)
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

        // ── Animated corner brackets (looks better than a full border) ────────
        Center(
          child: SizedBox(
            width: _boxSize,
            height: _boxSize,
            child: const _CornerBrackets(),
          ),
        ),

        // ── Animated scan line inside the box ────────────────────────────────
        Center(
          child: SizedBox(
            width: _boxSize,
            height: _boxSize,
            child: Obx(() => controller.isScanning.value
                ? const SizedBox.shrink()
                : const _ScanLine(boxSize: _boxSize)),
          ),
        ),

        // ── Instruction label below the scan box ──────────────────────────────
        Positioned(
          bottom: 160,
          left: 0,
          right: 0,
          child: Column(
            children: [
              const Text(
                'Hold your prize bond inside the frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Bond number must be exactly 6 digits',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // ── Bottom control bar ────────────────────────────────────────────────
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
            child: Obx(() => SizedBox(
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )),
          ),
        ),
      ],
    );
  }
}

// ── Animated corner brackets ──────────────────────────────────────────────────
//
// L-shaped corners that pulse in and out — a classic modern scanner effect.
class _CornerBrackets extends StatefulWidget {
  const _CornerBrackets();

  @override
  State<_CornerBrackets> createState() => _CornerBracketsState();
}

class _CornerBracketsState extends State<_CornerBrackets>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    // Pulse the corners: fade in/out to show the scanner is active
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _opacityAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
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
      animation: _opacityAnim,
      builder: (_, __) => Opacity(
        opacity: _opacityAnim.value,
        child: CustomPaint(
          painter: _CornerPainter(color: AppColors.accent),
        ),
      ),
    );
  }
}

// Draws four L-shaped corners inside the bounding box
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

    const cornerLength = 30.0;  // Length of each L arm
    const radius      = 12.0;   // Corner rounding radius

    // Top-left corner
    canvas.drawPath(
      _cornerPath(Offset.zero, size, _Corner.topLeft, cornerLength, radius),
      paint,
    );
    // Top-right corner
    canvas.drawPath(
      _cornerPath(Offset.zero, size, _Corner.topRight, cornerLength, radius),
      paint,
    );
    // Bottom-left corner
    canvas.drawPath(
      _cornerPath(Offset.zero, size, _Corner.bottomLeft, cornerLength, radius),
      paint,
    );
    // Bottom-right corner
    canvas.drawPath(
      _cornerPath(Offset.zero, size, _Corner.bottomRight, cornerLength, radius),
      paint,
    );
  }

  Path _cornerPath(
      Offset origin, Size size, _Corner corner, double len, double r) {
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

    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

// ── Animated scan line ────────────────────────────────────────────────────────
//
// A horizontal green glow line that sweeps up and down inside the scan box.
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

    // Move line across most of the box height
    final half = widget.boxSize / 2 - 20;
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
            width: widget.boxSize - 20, // Slightly inset from the box edges
            height: 2.5,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.85),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.5),
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

        // Display the scanned bond number
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.winning.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: AppColors.winning.withOpacity(0.4)),
          ),
          child: Text(
            controller.scannedNumber.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '6-digit prize bond number',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 32),

        // Action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              // Retry: scan again
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

              // Use: return the scanned number to the previous screen
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
              'Please grant camera access to scan prize bond numbers.\n'
              'Go to Settings → App → Camera and enable it.',
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
