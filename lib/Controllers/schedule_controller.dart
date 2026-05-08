// lib/controllers/schedule_controller.dart
// Controls the Schedule screen
// Shows upcoming draw schedules and handles PDF download simulation

import 'package:get/get.dart';

import '../Utils/mock_data.dart';
import '../models/schedule_model.dart';

class ScheduleController extends GetxController {
  final RxList<ScheduleModel> schedules = <ScheduleModel>[].obs;
  final RxBool isDownloading = false.obs;
  final RxInt filterDenomination = 0.obs; // 0 = All

  @override
  void onInit() {
    super.onInit();
    loadSchedules();
  }

  void loadSchedules() {
    schedules.assignAll(MockData.getSchedule());
  }

  // Get filtered schedules
  List<ScheduleModel> get filteredSchedules {
    if (filterDenomination.value == 0) return schedules;
    return schedules
        .where((s) => s.denomination == filterDenomination.value)
        .toList();
  }

  // Simulate PDF download
  // In a real app, this would download from National Savings Pakistan website
  Future<void> downloadPdf() async {
    isDownloading.value = true;

    // Simulate download delay
    await Future.delayed(const Duration(seconds: 2));

    isDownloading.value = false;

    // Show success notification
    Get.snackbar(
      'Downloaded!',
      'Draw schedule PDF saved to your device.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  void setFilter(int denomination) {
    filterDenomination.value = denomination;
  }
}
