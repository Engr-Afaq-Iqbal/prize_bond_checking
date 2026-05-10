// lib/controllers/home_controller.dart
// Controls the Home screen — delegates bond checking & draw data to DrawController

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../Controllers/DrawControllers/draw_controller.dart';
import '../Utils/storage_service.dart';

class HomeController extends GetxController {
  final StorageService _storage = StorageService();

  // Delegate to DrawController for all Firebase data
  DrawController get _draw => Get.find<DrawController>();

  final RxInt selectedDenomination = 750.obs;
  final RxString bondNumber = ''.obs;
  final RxInt totalBonds = 0.obs;
  final RxString nextDrawDate = ''.obs;

  // Expose draw controller state so the view can bind to it directly
  bool get hasResult => _draw.hasCheckResult.value;
  bool get isWinner => _draw.isWinner.value;
  bool get isChecking => _draw.isChecking.value;

  @override
  void onInit() {
    super.onInit();
    _loadStats();
  }

  void _loadStats() {
    totalBonds.value = _storage.getSavedBonds().length;
    _computeNextDraw();
  }

  void _computeNextDraw() {
    final upcoming = _draw.draws
        .where((d) => d.drawDate.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.drawDate.compareTo(b.drawDate));

    if (upcoming.isNotEmpty) {
      nextDrawDate.value =
          DateFormat('dd MMM').format(upcoming.first.drawDate);
    } else {
      nextDrawDate.value = 'TBA';
    }
  }

  // Called when user taps "Check Result"
  Future<void> checkBond() async {
    await _draw.checkBond(bondNumber.value, selectedDenomination.value);
  }

  // Called from scanner screen result
  void fillFromScanner(String scannedNumber) {
    bondNumber.value = scannedNumber;
    _draw.hasCheckResult.value = false;
  }

  void refreshBondCount() {
    totalBonds.value = _storage.getSavedBonds().length;
  }
}
