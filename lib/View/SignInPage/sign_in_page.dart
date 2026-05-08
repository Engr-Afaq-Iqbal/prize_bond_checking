import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controllers/AuthControllers/auth_controller.dart';
import '../../Theme/colors.dart';
import '../../Utils/app_custom_button.dart';
import '../../Utils/app_form_field.dart';
import '../../Utils/dimensions.dart';
import '../../Utils/font_styles.dart';
import '../../Utils/utils.dart';
import '../Signup/signup_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  late final signInFormKey;
  @override
  void initState() {
    signInFormKey = GlobalKey<FormState>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: kWhite,
        body: SingleChildScrollView(
          child: Form(
            key: signInFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                size70h,

                size20h,
                customText(text: 'Welcome', textStyle: bold32Black),
                customText(
                  text: 'Enter email address to get started',
                  textStyle: regular18Black.copyWith(
                    color: kBlack.withAlpha(70),
                  ),
                  maxLines: 3,
                ),
                size30h,
                roleSelector(),

                size30h,
                AppFormField(
                  padding: EdgeInsets.zero,
                  controller: Get.find<AuthController>().emailAddressCtrl,
                  labelText: 'Email Address'.tr,
                  hintText: '',
                  keyboardType: TextInputType.emailAddress,
                  // inputFormatterList: [
                  //   FilteringTextInputFormatter.digitsOnly,
                  // ],
                  customBorderColorActive: kBlack,
                  customBorderColorInActive: Colors.black12,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Required';
                    }
                    if (!GetUtils.isEmail(v.trim())) {
                      return 'Enter a valid Email Address'.tr;
                    }
                    return null;
                  },
                  onChanged: (v) {
                    Get.find<AuthController>().update(['signInForm']);
                  },
                ),
                size20h,
                AppFormField(
                  controller: Get.find<AuthController>().passwordCtrl,
                  labelText: 'Password'.tr,
                  hintText: '********'.tr,
                  keyboardType: TextInputType.text,
                  isPasswordField: true,
                  customBorderColorActive: kBlack,
                  customBorderColorInActive: Colors.black12,
                  validator: (String? v) {
                    if (v!.isEmpty) {
                      return 'Required'.tr;
                    }
                    return null;
                  },
                  onChanged: (v) {
                    Get.find<AuthController>().update(['signInForm']);
                  },
                ),
                // Spacer(),
                size15h,

                size30h,
                size200h,

                size15h,
                AppCustomButton(
                  margin: EdgeInsets.symmetric(
                    horizontal: SizesDimensions.width(
                      Dimensions.paddingSize10,
                    ),
                  ),
                  title: customText(
                    text: 'Continue',
                    textStyle: bold16White,
                  ),
                  onTap: () {
                    if (signInFormKey.currentState!.validate()) {
                      Get.find<AuthController>().signInWithEmail();
                    }
                  },
                ),
                size20h,
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Get.to(() => SignupPage());
                    },
                    child: customText(
                      text: 'Create Account'.tr,
                      textStyle: regular14Black,
                      maxLines: 3,
                    ),
                  ),
                ),
                size100h,
              ],
            ).paddingSymmetric(
              horizontal: SizesDimensions.width(Dimensions.paddingSize5),
            ),
          ),
        ),
      ),
    );
  }

  Widget roleSelector() {
    final signupController = Get.find<AuthController>();

    return Obx(
      () => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            /// NORMAL USER
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    signupController.selectedRole.value = UserRole.normal_user,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: signupController.selectedRole.value ==
                            UserRole.normal_user
                        ? primaryBlueColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      "Normal User",
                      style: TextStyle(
                        color: signupController.selectedRole.value ==
                                UserRole.normal_user
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /// ADMIN
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    signupController.selectedRole.value = UserRole.admin,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: signupController.selectedRole.value == UserRole.admin
                        ? primaryBlueColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      "Admin",
                      style: TextStyle(
                        color: signupController.selectedRole.value ==
                                UserRole.admin
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
