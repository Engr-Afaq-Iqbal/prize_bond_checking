// lib/View/SplashPage/splash_page.dart
// Splash screen shown when the app opens.
//
// After the animation it checks whether the user already has an active
// Firebase session (Firebase Auth persists login automatically across restarts).
//
// Routing logic:
//   • Firebase user exists AND role = "admin"  → AdminDashboardScreen
//   • Firebase user exists AND role = "normal_user" → MainScreen (user tabs)
//   • No Firebase session (guest or never logged in) → SignInPage

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Config/app_config.dart';
import '../../Theme/colors.dart';
import '../../View/Admin/AdminDashboard/admin_dashboard_screen.dart';
import '../../View/SignInPage/sign_in_page.dart';
import '../../View/main_screen.dart';

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

    // Fade + scale animation for the logo
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _navigateToNext();
  }

  /// Waits 3 s, then decides where to route based on Firebase session.
  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));

    // Firebase Auth automatically restores the session after app restart.
    // currentUser is non-null if the user previously logged in and never logged out.
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // No active session — show the login/guest screen
      Get.offAll(() => const SignInPage());
      return;
    }

    // User is logged in — fetch their role from Firestore to decide navigation
    try {
      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // Account in Firebase Auth but not in Firestore — treat as logged out
        await FirebaseAuth.instance.signOut();
        Get.offAll(() => const SignInPage());
        return;
      }

      final role = doc.data()?['role'] as String? ?? 'normal_user';
      final status = doc.data()?['status'] as String? ?? 'active';

      // Suspended / pending accounts must re-authenticate
      if (status != 'active') {
        await FirebaseAuth.instance.signOut();
        Get.offAll(() => const SignInPage());
        return;
      }

      if (role == 'admin') {
        // Admin goes directly to the admin dashboard
        Get.offAll(() => const AdminDashboardScreen());
      } else {
        // Regular user goes to the main user tab shell
        Get.offAll(() => MainScreen());
      }
    } catch (e) {
      // Firestore error (e.g. offline) — fall back to SignIn
      Get.offAll(() => const SignInPage());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlueColor,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: _animation,
            child: Image.asset(
              '${AppConfig.imgUrl}logo.png',
              height: 180,
            ),
          ),
        ),
      ),
    );
  }
}
