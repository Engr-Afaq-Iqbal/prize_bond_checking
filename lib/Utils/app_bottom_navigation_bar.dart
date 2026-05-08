import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:prize_bond_app/Utils/images_url.dart';

import '../Config/app_config.dart';
import '../Controllers/bottom_nav_controller.dart';
import '../Theme/colors.dart';
import 'dimensions.dart';

class AppBottomNavigationBar extends StatefulWidget {
  final int selectedIndex;

  const AppBottomNavigationBar({super.key, this.selectedIndex = 0});

  @override
  State<AppBottomNavigationBar> createState() => _AppBottomNavigationBarState();
}

class _AppBottomNavigationBarState extends State<AppBottomNavigationBar> {
  final BottomNavController navController = Get.find<BottomNavController>();

  @override
  void initState() {
    super.initState();
    navController.currentIndex = widget.selectedIndex;
    navController.pageController = PageController(
      initialPage: navController.currentIndex,
    );

    // Security check
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   if (mounted && AppConfig.securityEnabled) {
    //     bool isChecked = await SecurityChecker.handleSecurityCheck();
    //     if (isChecked == true) return;
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width >= 600;
    return GetBuilder<BottomNavController>(
      builder: (bottomNavCtrl) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: PageView(
            controller: bottomNavCtrl.pageController,
            onPageChanged: (index) {
              bottomNavCtrl.currentIndex = index;
              bottomNavCtrl.update();
            },
            physics: const NeverScrollableScrollPhysics(),
            children: bottomNavCtrl.screens,
          ),

          // ---------------- CUSTOM NAVBAR ----------------
          bottomNavigationBar: Padding(
            padding: EdgeInsets.only(
              bottom: Platform.isAndroid
                  ? MediaQuery.of(context).padding.bottom
                  : 0,
            ),
            child: Container(
              height: isTablet ? 120 : Dimensions.size80,
              decoration: BoxDecoration(
                color: lightPrimaryBlueColor, // BLUE BG
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(Dimensions.radiusSize25),
                  topRight: Radius.circular(Dimensions.radiusSize25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) {
                  final isSelected = bottomNavCtrl.currentIndex == index;

                  // ICONS LIST
                  final iconsList = [dashboard, myBonds, market];

                  ///need to fill icons ok

                  return GestureDetector(
                    onTap: () => bottomNavCtrl.changeTab(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          '${AppConfig.imgUrl}${iconsList[index]}',
                          height: isTablet ? 50 : Dimensions.size25,
                          colorFilter: ColorFilter.mode(
                            isSelected ? kWhite : kWhite.withOpacity(0.6),
                            BlendMode.srcIn,
                          ),
                        ),
                        size10h,
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 3,
                          width: isSelected
                              ? isTablet
                                  ? 50
                                  : 22
                              : 0,
                          decoration: BoxDecoration(
                            color: kWhite,
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusSize20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AppBottomNavigationBarAdmin extends StatefulWidget {
  final int selectedIndex;

  const AppBottomNavigationBarAdmin({super.key, this.selectedIndex = 0});

  @override
  State<AppBottomNavigationBarAdmin> createState() =>
      _AppBottomNavigationBarAdminState();
}

class _AppBottomNavigationBarAdminState
    extends State<AppBottomNavigationBarAdmin> {
  final BottomNavAdminController navController =
      Get.find<BottomNavAdminController>();

  @override
  void initState() {
    super.initState();
    navController.currentIndex = widget.selectedIndex;
    navController.pageController = PageController(
      initialPage: navController.currentIndex,
    );

    // Security check
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   if (mounted && AppConfig.securityEnabled) {
    //     bool isChecked = await SecurityChecker.handleSecurityCheck();
    //     if (isChecked == true) return;
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width >= 600;
    return GetBuilder<BottomNavAdminController>(
      builder: (bottomNavCtrl) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: PageView(
            controller: bottomNavCtrl.pageController,
            onPageChanged: (index) {
              bottomNavCtrl.currentIndex = index;
              bottomNavCtrl.update();
            },
            physics: const NeverScrollableScrollPhysics(),
            children: bottomNavCtrl.screens,
          ),

          // ---------------- CUSTOM NAVBAR ----------------
          bottomNavigationBar: Padding(
            padding: EdgeInsets.only(
              bottom: Platform.isAndroid
                  ? MediaQuery.of(context).padding.bottom
                  : 0,
            ),
            child: Container(
              height: isTablet ? 120 : Dimensions.size80,
              decoration: BoxDecoration(
                color: lightPrimaryBlueColor, // BLUE BG
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(Dimensions.radiusSize25),
                  topRight: Radius.circular(Dimensions.radiusSize25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(2, (index) {
                  final isSelected = bottomNavCtrl.currentIndex == index;

                  // ICONS LIST
                  final iconsList = [
                    dashboard,
                    users,
                  ];

                  ///need to fill icons ok

                  return GestureDetector(
                    onTap: () => bottomNavCtrl.changeTab(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          '${AppConfig.imgUrl}${iconsList[index]}',
                          height: isTablet ? 50 : Dimensions.size25,
                          colorFilter: ColorFilter.mode(
                            isSelected ? kWhite : kWhite.withOpacity(0.6),
                            BlendMode.srcIn,
                          ),
                        ),
                        size10h,
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 3,
                          width: isSelected
                              ? isTablet
                                  ? 50
                                  : 22
                              : 0,
                          decoration: BoxDecoration(
                            color: kWhite,
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusSize20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
