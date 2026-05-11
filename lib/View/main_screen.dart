// lib/View/main_screen.dart
// Root shell for all user-facing tabs.
//
// NOTE: There is NO FloatingActionButton here.
// HomeScreen has its own scanner FAB. Having two FABs in the same route
// causes the "multiple heroes with the same tag" crash because Flutter
// animates FABs with a shared Hero tag by default. Each screen that needs
// a FAB must declare one inside its own Scaffold, not in this shell.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Theme/app_theme.dart';
import '../controllers/nav_controller.dart';
import 'Draws/draws_screen.dart';
import 'home/home_screen.dart';
import 'marketplace/marketplace_screen.dart';
import 'my_bonds/my_bonds_screen.dart';

class MainScreen extends StatelessWidget {
  MainScreen({super.key});

  // All tab screens — created once and kept alive by IndexedStack
  final List<Widget> _screens = [
    HomeScreen(),              // Tab 0 — Home (bond checker + scanner FAB)
    const MyBondsScreen(),     // Tab 1 — My Bonds (auth-gated actions)
    const MarketplaceScreen(), // Tab 2 — Marketplace (auth-gated actions)
    const DrawsScreen(),       // Tab 3 — All draw results + PDF download
  ];

  @override
  Widget build(BuildContext context) {
    final NavController nav = Get.put(NavController());

    return Scaffold(
      // IndexedStack keeps every screen alive when switching tabs
      body: Obx(() => IndexedStack(
            index: nav.currentIndex.value,
            children: _screens,
          )),

      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: nav.currentIndex.value,
          onTap: nav.changePage,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
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
              label: 'Draws',
            ),
          ],
        ),
      ),
      // NO FAB here — HomeScreen owns its scanner FAB inside its own Scaffold.
    );
  }
}
