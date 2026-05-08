import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import '../Theme/colors.dart';
import 'dimensions.dart';
import 'font_styles.dart';

Logger logger = Logger();

void hideKeyboard(BuildContext context) {
  FocusScope.of(context).requestFocus(FocusNode());
}

bool isValidEmail(String? email) {
  if (email == null) return false;
  // Regex pattern for email validation
  final RegExp regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      caseSensitive: false, multiLine: false);
  return regex.hasMatch(email);
}

Builder progressIndicator({double? height, double? width}) =>
    Builder(builder: (context) {
      return Center(
        child: SizedBox(
          height: height,
          width: width,
          child: CircularProgressIndicator(
            backgroundColor: Colors.grey,
            color: Theme.of(context).colorScheme.primary,
            strokeWidth: 2.5,
          ),
        ),
      );
    });

void showProgress() {
  Get.defaultDialog(
    backgroundColor: Colors.transparent,
    title: "",
    content: Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
        Dimensions.radiusSize10,
      )),
      child: progressIndicator(),
    ),
    barrierDismissible: false,
  );
}

void stopProgress() {
  if (Get.isDialogOpen!) Get.back();
}

void showErrorSnackBar(
    {required String errorMessage, int durationInSeconds = 7}) {
  if (Get.isSnackbarOpen) {
    Get.back();
  }
  Get.snackbar(
    '',
    '',
    backgroundColor: kSnackRed,
    // backgroundColor: kRedFF624D,
    snackStyle: SnackStyle.FLOATING,
    duration: Duration(seconds: durationInSeconds),
    titleText: customText(
      text: 'somethingWentWrong'.tr,
      textStyle: bold14White,
    ),
    margin: EdgeInsets.symmetric(
      horizontal: 35,
    ),
    messageText: customText(
      text: errorMessage,
      textStyle: regular14White,
      maxLines: 5,
    ),
  );
}

void showSuccessSnackBar(
    {required String successMessage,
    int durationInSeconds = DurationSeconds.second7}) {
  Get.snackbar(
    '',
    '',
    backgroundColor: kSnackGreen,
    snackStyle: SnackStyle.FLOATING,
    duration: Duration(seconds: durationInSeconds),
    titleText: customText(
      text: 'successful'.tr,
      textStyle: bold14White,
    ),
    margin: EdgeInsets.symmetric(
      horizontal: 35,
    ),
    messageText: customText(
      text: successMessage,
      textStyle: regular14White,
      maxLines: 5,
    ),
  );
}

Future<void> closeSnackBarIfOpen(
    {Duration delay =
        const Duration(milliseconds: DurationSeconds.milliSecond500)}) async {
  if (Get.isSnackbarOpen) {
    Get.back();
    await Future.delayed(delay);
  }
}

String formatNumber(dynamic number) {
  return NumberFormat('#,###').format(number);
}

String formatDateBasedOnWeek(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final givenDate = DateTime(date.year, date.month, date.day);

  final difference = today.difference(givenDate).inDays;

  if (difference == 0) {
    return 'Today';
  } else if (difference == 1) {
    return 'Yesterday';
  } else if (difference <= 7) {
    return DateFormat.EEEE().format(date); // e.g., "Monday"
  } else {
    return DateFormat.yMMMd().format(date); // e.g., "Apr 20, 2025"
  }
}
