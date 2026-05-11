// lib/View/PrizeBondApp/prize_bond_app.dart
// Root widget of the app.
// Starts at SplashScreen — which decides where to go based on auth state.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../Theme/app_theme.dart';
import '../../Theme/colors.dart';
import '../SplashPage/splash_page.dart';

class PrizeBondApp extends StatelessWidget {
  const PrizeBondApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(400, 812),
      builder: (context, child) {
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: kWhite,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        );

        return GetMaterialApp(
          title: 'Prize Bond App',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          // App always starts at SplashScreen.
          // SplashScreen checks Firebase session and routes to the right place.
          home: const SplashScreen(),
        );
      },
    );
  }
}
