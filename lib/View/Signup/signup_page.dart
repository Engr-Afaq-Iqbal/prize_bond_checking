import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../Theme/colors.dart';
import '../../../Utils/dimensions.dart';
import '../../../Utils/font_styles.dart';
import '../../../Utils/utils.dart';
import '../../Controllers/AuthControllers/signup_controller.dart';
import '../../Utils/app_confirmation_page.dart';
import '../../Utils/app_custom_button.dart';
import '../../Utils/app_form_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  @override
  void initState() {
    super.initState();
    final ctrl = Get.find<SignupController>();
    ctrl.setIsButtonPressed = false;
    ctrl.setIsSubmitted = false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: Scaffold(
        backgroundColor: kWhite,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: kWhite,
        ),
        body: GetBuilder<SignupController>(
          builder: (signUpCtrl) {
            return Form(
              key: signUpCtrl.signUpFormKey,
              autovalidateMode: signUpCtrl.isSubmitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: SizesDimensions.width(Dimensions.paddingSize5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    size20h,
                    customText(
                      text: 'Getting Started'.tr,
                      textStyle: bold32Black,
                    ),
                    customText(
                      text: 'Seems you are new'.tr,
                      textStyle: regular18Black.copyWith(
                        color: kBlack.withAlpha(70),
                      ),
                    ),
                    size50h,

                    /// Full Name
                    AppFormField(
                      controller: signUpCtrl.firstNameCtrl,
                      labelText: 'First Name'.tr,
                      customBorderColorActive: kBlack,
                      customBorderColorInActive: Colors.black12,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required'.tr : null,
                    ),

                    /// Full Name
                    AppFormField(
                      controller: signUpCtrl.lastNameCtrl,
                      labelText: 'Last Name'.tr,
                      customBorderColorActive: kBlack,
                      customBorderColorInActive: Colors.black12,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required'.tr : null,
                    ),

                    /// Phone
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: AppFormField(
                        controller: signUpCtrl.phoneNumberCtrl,
                        labelText: 'Phone Number'.tr,
                        hintText: '92xxxxxxxxxx'.tr,
                        keyboardType: TextInputType.number,
                        inputFormatterList: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        customBorderColorActive: kBlack,
                        customBorderColorInActive: Colors.black12,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required'.tr;
                          return null;
                        },
                      ),
                    ),

                    /// Email
                    AppFormField(
                      controller: signUpCtrl.emailAddressCtrl,
                      labelText: 'Email Address'.tr,
                      keyboardType: TextInputType.emailAddress,
                      customBorderColorActive: kBlack,
                      customBorderColorInActive: Colors.black12,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required'.tr;
                        if (!GetUtils.isEmail(v.trim())) {
                          return 'Invalid email address'.tr;
                        }
                        return null;
                      },
                    ),

                    /// Password
                    AppFormField(
                      maxLength: 4,
                      controller: signUpCtrl.pinCodeCtrl,
                      labelText: 'PIN Code'.tr,
                      hintText: '****',
                      isPasswordField: true,
                      keyboardType: TextInputType.number,
                      inputFormatterList: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      customBorderColorActive: kBlack,
                      customBorderColorInActive: Colors.black12,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required'.tr;
                        if (v.length < 4) return 'PIN must be 4 digits'.tr;
                        return null;
                      },
                    ),

                    AppFormField(
                      maxLength: 4,
                      controller: signUpCtrl.confirmPinCodeCtrl,
                      labelText: 'Confirm PIN Code'.tr,
                      hintText: '****',
                      isPasswordField: true,
                      keyboardType: TextInputType.number,
                      inputFormatterList: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      customBorderColorActive: kBlack,
                      customBorderColorInActive: Colors.black12,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required'.tr;
                        if (v != signUpCtrl.pinCodeCtrl.text) {
                          return 'Confirm PIN must match PIN Code'.tr;
                        }
                        return null;
                      },
                    ),

                    /// Email
                    AppFormField(
                      controller: signUpCtrl.addressCtrl,
                      labelText: 'Address'.tr,
                      keyboardType: TextInputType.text,
                      customBorderColorActive: kBlack,
                      customBorderColorInActive: Colors.black12,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required'.tr;
                        return null;
                      },
                    ),

                    /// Email
                    AppFormField(
                      controller: signUpCtrl.cityCtrl,
                      labelText: 'City'.tr,
                      keyboardType: TextInputType.text,
                      customBorderColorActive: kBlack,
                      customBorderColorInActive: Colors.black12,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required'.tr;
                        return null;
                      },
                    ),

                    /// Password
                    AppFormField(
                      controller: signUpCtrl.passwordCtrl,
                      labelText: 'Password'.tr,
                      hintText: '********',
                      isPasswordField: true,
                      customBorderColorActive: kBlack,
                      customBorderColorInActive: Colors.black12,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required'.tr : null,
                    ),

                    /// Confirm Password
                    AppFormField(
                      controller: signUpCtrl.confirmPasswordCtrl,
                      labelText: 'Confirm Password'.tr,
                      hintText: '********',
                      isPasswordField: true,
                      customBorderColorActive: kBlack,
                      customBorderColorInActive: Colors.black12,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required'.tr : null,
                    ),
                    Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          /// NORMAL USER
                          Row(
                            children: [
                              Radio<UserRole>(
                                value: UserRole.normalUser,
                                groupValue: signUpCtrl.selectedRole.value,
                                onChanged: (value) {
                                  signUpCtrl.selectedRole.value = value!;
                                },
                              ),
                              const Text("Normal User"),
                            ],
                          ),

                          const SizedBox(width: 20),

                          /// ADMIN
                          Row(
                            children: [
                              Radio<UserRole>(
                                activeColor: primaryBlueColor,
                                value: UserRole.admin,
                                groupValue: signUpCtrl.selectedRole.value,
                                onChanged: (value) {
                                  signUpCtrl.selectedRole.value = value!;
                                },
                              ),
                              const Text("Admin"),
                            ],
                          ),
                        ],
                      ),
                    ),

                    size50h,

                    /// Submit Button
                    AppCustomButton(
                      title: customText(
                        text: 'Continue'.tr,
                        textStyle: bold16White,
                      ),
                      onTap: signUpCtrl.getIsButtonPressed
                          ? null
                          : () async {
                              hideKeyboard(context);

                              signUpCtrl.setIsSubmitted = true;
                              signUpCtrl.setIsButtonPressed = true;
                              signUpCtrl.update();

                              if (!signUpCtrl.signUpFormKey.currentState!
                                  .validate()) {
                                signUpCtrl.setIsButtonPressed = false;
                                signUpCtrl.update();
                                return;
                              }

                              if (signUpCtrl.passwordCtrl.text.trim() !=
                                  signUpCtrl.confirmPasswordCtrl.text.trim()) {
                                showErrorSnackBar(
                                  errorMessage: 'confirmPasswordIsNotSame'.tr,
                                );
                                signUpCtrl.setIsButtonPressed = false;
                                signUpCtrl.update();
                                return;
                              }

                              /// ✅ SAFE loader
                              safeShowProgress();

                              bool success = false;

                              try {
                                success = await signUpCtrl.createUserAccount();
                              } catch (_) {
                                // swallow — handled below
                              }

                              /// ✅ FORCE stop loader (no mercy)
                              safeStopProgress();

                              signUpCtrl.setIsButtonPressed = false;
                              signUpCtrl.update();

                              if (success) {
                                Get.offAll(() => const AppConfirmationPage());
                              }
                            },
                    ),
                    size80h,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isProgressShowing = false;

  void safeShowProgress() {
    if (_isProgressShowing) return;
    _isProgressShowing = true;
    showProgress();
  }

  void safeStopProgress() {
    if (!_isProgressShowing) return;
    _isProgressShowing = false;
    stopProgress();
  }
}
