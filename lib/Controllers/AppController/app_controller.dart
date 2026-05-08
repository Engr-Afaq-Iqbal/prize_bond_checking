import 'package:get/get.dart';
import 'package:prize_bond_app/Controllers/AuthControllers/auth_controller.dart';
import 'package:prize_bond_app/Controllers/AuthControllers/signup_controller.dart';
import 'package:prize_bond_app/Controllers/CustomerController/customer_controller.dart';
import 'package:prize_bond_app/Controllers/bottom_nav_controller.dart';

class AppController {
  void initializeController() {
    // Get.put<NetworkController>(NetworkController(), permanent: true);

    // Get.put(OnboardingController());
    Get.put(AuthController());
    Get.put(SignupController());
    Get.put(BottomNavController());
    Get.put(BottomNavAdminController());
    Get.put(CustomerController());
  }
}
