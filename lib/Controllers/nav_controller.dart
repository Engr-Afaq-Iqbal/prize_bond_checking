// lib/controllers/nav_controller.dart
// Controls the bottom navigation bar tab switching

import 'package:get/get.dart';

class NavController extends GetxController {
  // Current selected tab index (0=Home, 1=MyBonds, 2=Market, 3=Schedule)
  final RxInt currentIndex = 0.obs;

  void changePage(int index) {
    currentIndex.value = index;
  }
}
