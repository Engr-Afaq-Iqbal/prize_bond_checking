// lib/Controllers/scanner_controller.dart
// Real camera scanning with ML Kit OCR text recognition

import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerController extends GetxController {
  final Logger _logger = Logger();

  final RxBool isScanning = false.obs;
  final RxString scannedNumber = ''.obs;
  final RxBool scanComplete = false.obs;
  final RxBool cameraPermissionDenied = false.obs;
  final RxBool isCameraReady = false.obs;

  CameraController? cameraController;
  List<CameraDescription> _cameras = [];
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  bool _isProcessingFrame = false;

  @override
  void onInit() {
    super.onInit();
    _initCamera();
  }

  @override
  void onClose() {
    cameraController?.dispose();
    _textRecognizer.close();
    super.onClose();
  }

  // ── CAMERA INIT ─────────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      cameraPermissionDenied.value = true;
      return;
    }

    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    cameraController = CameraController(
      _cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await cameraController!.initialize();
    isCameraReady.value = true;

    // Start real-time OCR frame processing
    cameraController!.startImageStream(_processFrame);
  }

  // ── FRAME PROCESSING ─────────────────────────────────────────────────────────

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessingFrame || scanComplete.value) return;
    _isProcessingFrame = true;

    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) {
        _isProcessingFrame = false;
        return;
      }

      final recognized = await _textRecognizer.processImage(inputImage);

      // Extract bond number: look for a 6-digit sequence
      final number = _extractBondNumber(recognized.text);
      if (number != null) {
        scannedNumber.value = number;
        scanComplete.value = true;
        await cameraController?.stopImageStream();
      }
    } catch (e) {
      _logger.e('OCR error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image) {
    if (cameraController == null) return null;

    final camera = _cameras.first;
    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // Extract a 6–9 digit bond number from the OCR text
  String? _extractBondNumber(String text) {
    final regex = RegExp(r'\b\d{6,9}\b');
    final match = regex.firstMatch(text);
    return match?.group(0);
  }

  // ── MANUAL SCAN TRIGGER ──────────────────────────────────────────────────────

  // Called when user taps the capture button to force an immediate capture
  Future<void> captureAndScan() async {
    if (cameraController == null || !isCameraReady.value) return;
    isScanning.value = true;

    try {
      await cameraController!.stopImageStream();
      final picture = await cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(picture.path);
      final recognized = await _textRecognizer.processImage(inputImage);

      final number = _extractBondNumber(recognized.text);
      if (number != null) {
        scannedNumber.value = number;
        scanComplete.value = true;
      } else {
        Get.snackbar(
          'No Number Found',
          'Could not detect a bond number. Try again with better lighting.',
          snackPosition: SnackPosition.BOTTOM,
        );
        // Restart stream for next attempt
        cameraController!.startImageStream(_processFrame);
      }
    } catch (e) {
      _logger.e('Capture error: $e');
      Get.snackbar('Error', 'Failed to scan. Please try again.',
          snackPosition: SnackPosition.BOTTOM);
      cameraController?.startImageStream(_processFrame);
    } finally {
      isScanning.value = false;
    }
  }

  // ── RESET ────────────────────────────────────────────────────────────────────

  Future<void> reset() async {
    scannedNumber.value = '';
    scanComplete.value = false;
    isScanning.value = false;
    _isProcessingFrame = false;
    // Restart image stream
    if (cameraController != null && isCameraReady.value) {
      try {
        await cameraController!.startImageStream(_processFrame);
      } catch (_) {}
    }
  }
}
