import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../Config/app_config.dart';
import '../../Controllers/user_controller.dart';
import '../../Utils/storage_sevices.dart';
import '../../Utils/utils.dart';
import '../../View/Admin/AdminDashboard/admin_dashboard_screen.dart';
import '../../View/SignInPage/sign_in_page.dart';
import '../../View/main_screen.dart';

class AuthController extends GetxController {
  TextEditingController phoneNumberCtrl = TextEditingController();
  TextEditingController otpController = TextEditingController();
  TextEditingController passwordCtrl = TextEditingController();
  TextEditingController emailAddressCtrl = TextEditingController();
  bool isBottomSheetOpened = false;
  Timer? timer;
  String selectedCountry = "Saudi Arabia (+966)";
  String flag = "🇸🇦"; // You can replace with image asset
  int selectedIndex = 0;
  int remainingSeconds = AppConfig.timerSeconds;
  String _otp = '';
  bool canResend = false;

  String get otp => _otp;

  set setOtp(String value) {
    _otp = value;
  }

  /// Temp location from map
  double? selectedLat;
  double? selectedLng;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===============================
  // EMAIL + PASSWORD LOGIN
  // ===============================
  final GetStorage _box = GetStorage();
  static const String _loginTimeKey = 'loginTime';
  static const Duration sessionDuration = Duration(hours: 1);
  Rx<User?> firebaseUser = Rx<User?>(null);
  Future<void> signInWithEmail() async {
    try {
      if (emailAddressCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
        Get.snackbar(
          'Login Failed'.tr,
          'Please enter both email and password'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
        );
        return;
      }

      showProgress(); // if you have loader

      final cred = await _auth.signInWithEmailAndPassword(
        email: emailAddressCtrl.text.trim(),
        password: passwordCtrl.text,
      );

      final userId = cred.user!.uid;

      // 🔥 FETCH DRIVER DATA
      final driverDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(userId)
          .get();

      if (!driverDoc.exists) {
        stopProgress();
        await _auth.signOut();
        Get.snackbar(
          'Login Failed'.tr,
          'Account Data Not Found'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final status = driverDoc.data()?['status'];
      final data = driverDoc.data();
      final dbRole = data?['role'];

      /// ROLE VALIDATION
      logger.i(selectedRole.value);

      // 🔴 IF PENDING
      if (status == 'pending') {
        stopProgress();
        await _auth.signOut();

        showPendingDialog();

        return;
      }

      // 🔴 IF REJECTED (Optional)
      if (status == 'suspended') {
        stopProgress();
        await _auth.signOut();

        Get.snackbar(
          "Account Suspended",
          "Your account has been rejected. Contact support.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      if (dbRole != selectedRole.value.name) {
        stopProgress();
        await _auth.signOut();

        Get.snackbar(
          "Login Failed",
          "Invalid credentials or account type selected. Please check your details and try again.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // 🟢 IF APPROVED — navigate to the right shell based on role
      if (status == 'active') {
        firebaseUser.value = cred.user;

        // Read previously stored UID BEFORE overwriting it.
        // UserController uses this to decide whether to clear stale data.
        final String? previousUid = await AppStorage.getUserData();

        // Persist the new UID locally
        AppStorage.setUserData(userId);

        await saveToken(userId);

        // Fetch and cache the user profile. If a DIFFERENT user just logged in
        // their old cached data is wiped and fresh data is loaded from Firestore.
        final userCtrl = Get.find<UserController>();
        await userCtrl.fetchAndCacheUser(
          newUid: userId,
          previousUid: previousUid,
        );

        stopProgress();

        if (dbRole == 'admin') {
          // Admin goes to the admin dashboard (draw upload + user management)
          Get.offAll(() => const AdminDashboardScreen());
        } else {
          // Regular user goes to the main tab shell
          Get.offAll(() => MainScreen());
        }
      } else {
        stopProgress();
        await _auth.signOut();
        Get.snackbar(
          'Login Failed'.tr,
          'Invalid Account Status'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } on FirebaseAuthException catch (e) {
      stopProgress();

      String errorMessage;

      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'theEmailAddressIsNotValid';
          break;
        case 'user-disabled':
          errorMessage = 'thisAccountHasBeenDisabledContactSupport';
          break;
        case 'user-not-found':
          errorMessage = 'noAccountFoundWithThisEmail';
          break;
        case 'wrong-password':
          errorMessage = 'incorrectPasswordPleaseTryAgain';
          break;
        case 'too-many-requests':
          errorMessage = 'tooManyLoginAttemptsPleaseTryAgainLater';
          break;
        default:
          errorMessage = 'loginFailedPleaseTryAgain';
      }

      Get.snackbar(
        'loginFailed'.tr,
        errorMessage.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );

      logger.e('FirebaseAuthException: ${e.code}');
    } catch (e) {
      stopProgress();

      Get.snackbar(
        'loginFailed'.tr,
        'pleaseTryAgainLater'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );

      logger.e('Unknown login error: $e');
    }
  }

  void showPendingDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔵 Icon Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: Colors.orange,
                  size: 40,
                ),
              ),

              const SizedBox(height: 20),

              // 🏷 Title
              const Text(
                "Account Pending",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              // 📝 Message
              const Text(
                "Your account is currently under review.\n\nPlease wait for admin approval before accessing the app.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.4),
              ),

              const SizedBox(height: 24),

              // 🔘 Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false, // Important
    );
  }

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Future<void> saveToken(String currentUserId) async {
  //   String? token = await messaging.getToken();
  //
  //   if (token != null) {
  //     await FirebaseFirestore.instance
  //         .collection('drivers')
  //         .doc(currentUserId)
  //         .update({
  //           'fcmToken': token,
  //           'lang': Get.locale?.languageCode ?? 'en',
  //         });
  //
  //     logger.i("FCM Token saved: $token");
  //   }
  // }

  Future<void> saveToken(String currentUserId) async {
    try {
      String? token = await messaging.getToken();

      if (token != null) {
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(currentUserId)
            .set({
          'fcmToken': token,
          'lang': Get.locale?.languageCode ?? 'en',
        }, SetOptions(merge: true)); // ✅ IMPORTANT

        logger.i("FCM Token saved: $token");
      }
    } catch (e) {
      logger.e("Error saving FCM token: $e");
    }
  }

  // ===============================
  // CHECK SESSION VALIDITY
  // ===============================
  bool isSessionValid() {
    final int? loginTime = _box.read(_loginTimeKey);

    if (loginTime == null) return false;

    final DateTime lastLogin = DateTime.fromMillisecondsSinceEpoch(loginTime);

    return DateTime.now().difference(lastLogin) <= sessionDuration;
  }

  Future<void> signOut() async {
    // Sign out from Firebase (clears the persisted session on device)
    await _auth.signOut();

    // Clear locally stored UID and session timestamp
    _box.remove(_loginTimeKey);
    await AppStorage.clearUserData();

    // Clear the cached user profile from UserController
    Get.find<UserController>().clearUser();

    firebaseUser.value = null;

    // Clear email/password fields so they don't show on next login
    emailAddressCtrl.clear();
    passwordCtrl.clear();

    // Return to the login screen, removing all previous routes
    Get.offAll(() => const SignInPage());
  }

  /// Default selection = Normal User
  Rx<UserRole> selectedRole = UserRole.normal_user.obs;

  /// Value to send Firebase
  String get roleValue {
    switch (selectedRole.value) {
      case UserRole.admin:
        return "admin";
      case UserRole.normal_user:
        return "normal_user";
    }
  }
}

enum UserRole {
  admin,
  normal_user,
}
