// import 'package:flutter/cupertino.dart';
// import 'package:get/get.dart';
// import 'package:prize_bond_app/Admin/AdminDashboard/admin_dashboard.dart';
// import 'package:prize_bond_app/View/MarketPlace%20Page/market_place_page.dart';
//
// import '../Admin/AllUsers/all_users.dart';
// import '../View/DashboardPage/dashboard_page.dart';
// import '../View/My Bonds/my_bonds.dart';
//
// class BottomNavController extends GetxController {
//   var currentIndex = 0;
//   late PageController pageController;
//   List<Widget> screens = [
//     DashboardPage(),
//     MyBonds(),
//     MarketPlacePage(),
//   ];
//
//   void changeTab(int index) {
//     currentIndex = index;
//     pageController.jumpToPage(index);
//   }
// }
//
// class BottomNavAdminController extends GetxController {
//   var currentIndex = 0;
//   late PageController pageController;
//   List<Widget> screens = [
//     AdminDashboard(),
//     CustomerListScreen(),
//   ];
//
//   void changeTab(int index) {
//     currentIndex = index;
//     pageController.jumpToPage(index);
//   }
// }

// lib/Controllers/bottom_nav_controller.dart
// UPDATED: Points user screens to Firebase-connected versions
// Admin dashboard also updated

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

// Admin screens
import '../Admin/AdminDashboard/admin_dashboard.dart';
import '../Admin/AllUsers/all_users.dart';
// User screens
import '../View/DashboardPage/dashboard_page.dart';
import '../View/MarketPlace Page/market_place_page.dart';
import '../View/My Bonds/my_bonds.dart';

// ─── USER NAVIGATION ───────────────────────────────────────────────────────────
class BottomNavController extends GetxController {
  var currentIndex = 0;
  late PageController pageController;

  // NOTE: DashboardPage and MyBonds are existing screens.
  // DashboardPage will be updated to use DrawController (Firebase).
  // MyBonds will be updated to use MyBondsFirebaseController.
  List<Widget> screens = [
    DashboardPage(),
    MyBonds(),
    MarketPlacePage(),
  ];

  void changeTab(int index) {
    currentIndex = index;
    pageController.jumpToPage(index);
    update(); // Refresh GetBuilder
  }
}

// ─── ADMIN NAVIGATION ─────────────────────────────────────────────────────────
class BottomNavAdminController extends GetxController {
  var currentIndex = 0;
  late PageController pageController;

  List<Widget> screens = [
    AdminDashboard(), // Now points to full AdminDashboardScreen
    CustomerListScreen(),
  ];

  void changeTab(int index) {
    currentIndex = index;
    pageController.jumpToPage(index);
    update();
  }
}
