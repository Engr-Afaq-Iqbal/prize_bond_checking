// lib/View/SignInPage/sign_in_page.dart
// Login screen — supports Normal User, Admin, and Guest access.
//
// Flow:
//   1. Select role (Normal User / Admin) and enter credentials → Continue
//   2. OR tap "Continue as Guest" to skip login (limited access)
//
// Guest users can browse Home and Draws but cannot save bonds or list in market.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controllers/AuthControllers/auth_controller.dart';
import '../../Theme/colors.dart';
import '../../Utils/app_custom_button.dart';
import '../../Utils/app_form_field.dart';
import '../../Utils/dimensions.dart';
import '../../Utils/font_styles.dart';
import '../../Utils/utils.dart';
import '../../View/main_screen.dart';
import '../Signup/signup_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  late final GlobalKey<FormState> signInFormKey;

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

                // ── Title ──────────────────────────────────────────────────
                customText(text: 'Welcome', textStyle: bold32Black),
                customText(
                  text: 'Enter your email address to get started',
                  textStyle:
                      regular18Black.copyWith(color: kBlack.withAlpha(70)),
                  maxLines: 3,
                ),
                size30h,

                // ── Role Selector (Normal User / Admin) ───────────────────
                _roleSelector(),
                size30h,

                // ── Email ──────────────────────────────────────────────────
                AppFormField(
                  padding: EdgeInsets.zero,
                  controller: Get.find<AuthController>().emailAddressCtrl,
                  labelText: 'Email Address'.tr,
                  hintText: '',
                  keyboardType: TextInputType.emailAddress,
                  customBorderColorActive: kBlack,
                  customBorderColorInActive: Colors.black12,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!GetUtils.isEmail(v.trim())) {
                      return 'Enter a valid Email Address'.tr;
                    }
                    return null;
                  },
                  onChanged: (_) =>
                      Get.find<AuthController>().update(['signInForm']),
                ),
                size20h,

                // ── Password ───────────────────────────────────────────────
                AppFormField(
                  controller: Get.find<AuthController>().passwordCtrl,
                  labelText: 'Password'.tr,
                  hintText: '********'.tr,
                  keyboardType: TextInputType.text,
                  isPasswordField: true,
                  customBorderColorActive: kBlack,
                  customBorderColorInActive: Colors.black12,
                  validator: (v) =>
                      v!.isEmpty ? 'Required'.tr : null,
                  onChanged: (_) =>
                      Get.find<AuthController>().update(['signInForm']),
                ),
                size15h,
                size30h,

                // ── Login Button ───────────────────────────────────────────
                AppCustomButton(
                  margin: EdgeInsets.symmetric(
                    horizontal: SizesDimensions.width(Dimensions.paddingSize10),
                  ),
                  title: customText(
                      text: 'Continue', textStyle: bold16White),
                  onTap: () {
                    if (signInFormKey.currentState!.validate()) {
                      Get.find<AuthController>().signInWithEmail();
                    }
                  },
                ),
                size20h,

                // ── Create Account ─────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => Get.to(() => SignupPage()),
                    child: customText(
                      text: 'Create Account'.tr,
                      textStyle: regular14Black,
                      maxLines: 2,
                    ),
                  ),
                ),
                size20h,

                // ── Divider ────────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        SizesDimensions.width(Dimensions.paddingSize10),
                  ),
                  child: Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR',
                            style: regular14Black.copyWith(
                                color: kBlack.withAlpha(80))),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ),
                size20h,

                // ── Continue as Guest ──────────────────────────────────────
                // Guest users can browse the app without logging in.
                // They cannot save bonds or list bonds in the marketplace.
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        SizesDimensions.width(Dimensions.paddingSize10),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Navigate to the main screen without signing in.
                        // FirebaseAuth.instance.currentUser will be null,
                        // so auth-gated features will show a "Sign In" prompt.
                        Get.offAll(() => MainScreen());
                      },
                      icon: const Icon(Icons.person_outline),
                      label: const Text(
                        'Continue as Guest',
                        style: TextStyle(fontSize: 15),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: kBlack.withAlpha(60)),
                        foregroundColor: kBlack,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  // ── Role Selector (Normal User / Admin) ──────────────────────────────────
  Widget _roleSelector() {
    final auth = Get.find<AuthController>();

    return Obx(
      () => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            // ── Normal User tab ──────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    auth.selectedRole.value = UserRole.normal_user,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: auth.selectedRole.value == UserRole.normal_user
                        ? primaryBlueColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      'Normal User',
                      style: TextStyle(
                        color: auth.selectedRole.value ==
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

            // ── Admin tab ────────────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    auth.selectedRole.value = UserRole.admin,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: auth.selectedRole.value == UserRole.admin
                        ? primaryBlueColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      'Admin',
                      style: TextStyle(
                        color: auth.selectedRole.value == UserRole.admin
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
