import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../Theme/app_theme.dart';
import '../../Theme/colors.dart';
import '../main_screen.dart';

class PrizeBondApp extends StatefulWidget {
  const PrizeBondApp({super.key});

  @override
  State<PrizeBondApp> createState() => _PrizeBondAppState();
}

class _PrizeBondAppState extends State<PrizeBondApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Get.find<AccountInfoController>().getThemeData();
    return ScreenUtilInit(
      designSize: const Size(400, 812), // Adjust this to your design's size
      builder: (context, child) {
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: kWhite,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        );

        final overlayStyle = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: kWhite,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.dark,
        );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: GetMaterialApp(
            // Apply our custom theme
            theme: AppTheme.lightTheme,
            // translations: Translation(),
            // locale: locale,
            // fallbackLocale: Locale(AppConfig.enLang, AppConfig.enCountry),
            // Note: /login route connects to your existing auth screens
            getPages: [
              GetPage(name: '/', page: () => MainScreen()),
              // Your existing auth pages should be registered here:
              // GetPage(name: '/login', page: () => LoginScreen()),
            ],
            debugShowCheckedModeBanner: false,
            // theme: Get.find<ThemeController>().themeData,
            // home: const SplashScreen(),
            // Start with the main screen
            // In your final app, start with login screen if user not authenticated
            // home: MainScreen(),
          ),
        );
      },
    );
  }
}
