import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Config/app_config.dart';
import '../../Theme/colors.dart';
import '../SignInPage/sign_in_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 1. Setup the Animation
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // 2. Logic to route after 3 seconds
    _navigateToNext();
  }

  // Future<void> checkPermission() async {
  //   await LocationService.handleLocationPermission(context);
  // }

  Future<void> _navigateToNext() async {
    await Future.delayed(
      Duration(seconds: 3),
    ); // Give the user time to see the logo

    Get.offAll(() => const SignInPage());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlueColor, // Your requested background
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: _animation,
            child: Image.asset(
              height: 180,
              '${AppConfig.imgUrl}logo.png',
              // color: kWhite,
            ), // Replace this with your Image.asset('logo.png')
          ),
        ),
      ),
    );
  }
}
