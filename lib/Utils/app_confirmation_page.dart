import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:prize_bond_app/Utils/utils.dart';

import '../Config/app_config.dart';
import '../Theme/colors.dart';
import '../View/SignInPage/sign_in_page.dart';
import 'app_custom_button.dart';
import 'app_styles.dart';
import 'dimensions.dart';
import 'images_url.dart';

class AppConfirmationPage extends StatelessWidget {
  final String? route;
  final String? title;
  final String? txt;
  final String? txt2;
  final String? txt3;
  final String? txt4;
  final String? btnTxt;
  final String? resultImg;
  final bool showParty;
  final bool showCurrency;

  const AppConfirmationPage({
    super.key,
    this.title,
    this.txt,
    this.btnTxt,
    this.route,
    this.resultImg = tickImage,
    this.txt4,
    this.txt3,
    this.txt2,
    this.showParty = false,
    this.showCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () => hideKeyboard(context),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Column(
            children: [
              size120h,
              SvgPicture.asset('${AppConfig.imgUrl}$success'),
              size150h,
              CustomText(
                text: 'Thank You',
                maxLines: 3,
                textAlign: TextAlign.center,
                textStyle: AppTextStyles.extraBold(
                  Dimensions.fontSize24,
                ).black,
              ),
              size20h,
              CustomText(
                text:
                    'We have received your Request to create an Account, Your account is pending for Approval',
                maxLines: 5,
                textAlign: TextAlign.center,
                textStyle: AppTextStyles.regular(
                  Dimensions.fontSize14,
                ).grey,
              ),
              size20h,
              size20h,
              const Spacer(),
              AppStyles.dividerLine(width: Get.width),
              size20h,
              AppCustomButton(
                margin: EdgeInsets.symmetric(
                  horizontal: SizesDimensions.width(
                    Dimensions.paddingSize5,
                  ),
                ),
                bgColor: lightPrimaryBlueColor,
                title: CustomText(
                  text: 'Continue'.tr,
                  textStyle: AppTextStyles.extraBold(
                    Dimensions.fontSize16,
                  ).white,
                ),
                onTap: () async {
                  await closeSnackBarIfOpen();
                  Get.offAll(() => SignInPage());
                },
              ),
              Platform.isAndroid ? size90h : size50h,
            ],
          ).paddingSymmetric(
            horizontal: SizesDimensions.width(Dimensions.paddingSize3),
          ),
        ),
      ),
    );
  }
}
