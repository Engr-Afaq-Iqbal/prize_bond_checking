// lib/screens/main_screen.dart
// Main wrapper screen with bottom navigation bar
// This is the shell that holds all 4 main tabs

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:prize_bond_app/View/schedule/schedule_screen.dart';

import '../Theme/app_theme.dart';
import '../controllers/nav_controller.dart';
import 'home/home_screen.dart';
import 'marketplace/marketplace_screen.dart';
import 'my_bonds/my_bonds_screen.dart';

class MainScreen extends StatelessWidget {
  MainScreen({super.key});

  // All 4 main screens - created once and kept alive
  final List<Widget> _screens = [
    HomeScreen(), // Tab 0: Home
    MyBondsScreen(), // Tab 1: My Bonds
    const MarketplaceScreen(), // Tab 2: Marketplace
    const ScheduleScreen(), // Tab 3: Schedule
  ];

  @override
  Widget build(BuildContext context) {
    // Get the navigation controller
    final NavController navController = Get.put(NavController());

    return Scaffold(
      // Show the currently selected screen
      body: Obx(() => IndexedStack(
            // IndexedStack keeps all screens alive (doesn't rebuild on tab switch)
            index: navController.currentIndex.value,
            children: _screens,
          )),

      // Bottom navigation bar
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: navController.currentIndex.value,
          onTap: navController.changePage,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'My Bonds',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Market',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Schedule',
            ),
          ],
        ),
      ),

      // Central scanner FAB (positioned above the nav bar)
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          // The Home screen has its own FAB handling,
          // but this provides global scanner access
          navController.changePage(0); // Go to home first
        },
        child: const Icon(Icons.camera_alt_outlined, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
