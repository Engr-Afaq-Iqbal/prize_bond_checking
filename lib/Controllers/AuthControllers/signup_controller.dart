import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Utils/utils.dart';

class SignupController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController phoneNumberCtrl = TextEditingController();
  TextEditingController firstNameCtrl = TextEditingController();
  TextEditingController lastNameCtrl = TextEditingController();
  TextEditingController emailAddressCtrl = TextEditingController();
  TextEditingController addressCtrl = TextEditingController();
  TextEditingController currentAddressCtrl = TextEditingController();
  TextEditingController cityCtrl = TextEditingController();
  TextEditingController passwordCtrl = TextEditingController();
  TextEditingController pinCodeCtrl = TextEditingController();
  TextEditingController confirmPinCodeCtrl = TextEditingController();
  TextEditingController confirmPasswordCtrl = TextEditingController();
  bool _isSubmitted = false;
  bool _isButtonPressed = false;
  List<String> countriesList = [
    'Riyadh',
    'Mecca',
    'Madinah',
    'Qassim',
    'Eastern Province',
    'Asir',
    'Tabuk',
    'Hail',
    'Northern Borders',
    'Jazan',
    'Najran',
    'Al Bahah',
    'Al Jawf',
  ];
  String? selectedCountry;
  Map<String, bool> agreements = {};
  final signUpFormKey = GlobalKey<FormState>();

  bool get isSubmitted => _isSubmitted;

  set setIsSubmitted(bool value) {
    _isSubmitted = value;
  }

  bool get getIsButtonPressed => _isButtonPressed;

  set setIsButtonPressed(bool value) {
    _isButtonPressed = value;
  }

  bool getAgreementValue(String key) {
    return agreements[key] ?? false;
  }

  void setAgreementValue(String key, bool value) {
    agreements[key] = value;
  }

  /// Create user account and return success status

  Future<bool> createUserAccount() async {
    try {
      final role = roleValue;
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailAddressCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) {
        showErrorSnackBar(errorMessage: 'Account Creation Failed');
        return false;
      }

      await _firestore.collection('customers').doc(user.uid).set({
        'uid': user.uid,
        'firstName': firstNameCtrl.text.trim(),
        'lastName': lastNameCtrl.text.trim(),
        'contactNumber': phoneNumberCtrl.text.trim(),
        'email': emailAddressCtrl.text.trim(),
        'role': role,
        'status': 'pending',
        'pinCode': pinCodeCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'city': cityCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } on FirebaseAuthException catch (e) {
      /// 👇 User-friendly + actionable messages
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'thisEmailReistered'.tr;
          break;

        case 'invalid-email':
          message = 'pleaseEnterValidEmailAddress'.tr;
          break;

        case 'weak-password':
          message = 'yourPasswordIsWeek'.tr;
          break;

        default:
          message = 'unableToCreateAccount'.tr;
      }

      showErrorSnackBar(errorMessage: message);
      return false;
    } catch (e) {
      showErrorSnackBar(errorMessage: 'somethingWentWrong'.tr);
      return false;
    }
  }

  TextEditingController otpController = TextEditingController();

  String formattedPhone(String phone) {
    phone = phone.replaceAll(RegExp(r'\s+'), '');
    phone = phone.replaceAll('-', '');

    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }

    return '+966$phone';
  }

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future<void> saveToken(String currentUserId) async {
    String? token = await messaging.getToken();

    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'fcmToken': token,
        'lang': Get.locale?.languageCode ?? 'en',
      });

      logger.i("FCM Token saved: $token");
    }
  }

  /// Default selection = Normal User
  Rx<UserRole> selectedRole = UserRole.normalUser.obs;

  /// Value to send Firebase
  String get roleValue {
    switch (selectedRole.value) {
      case UserRole.admin:
        return "admin";
      case UserRole.normalUser:
        return "normal_user";
    }
  }
}

enum UserRole {
  admin,
  normalUser,
}
