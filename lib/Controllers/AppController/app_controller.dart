import 'package:get/get.dart';
import 'package:prize_bond_app/Controllers/AuthControllers/auth_controller.dart';
import 'package:prize_bond_app/Controllers/AuthControllers/signup_controller.dart';
import 'package:prize_bond_app/Controllers/CustomerController/customer_controller.dart';
import 'package:prize_bond_app/Controllers/bottom_nav_controller.dart';

import '../../Services/connectivity_service.dart';

class AppController {
  void initializeController() {
    // Get.put<NetworkController>(NetworkController(), permanent: true);

    // ── 5. Initialize GetX Services (available app-wide) ──────────────────────
    Get.put(ConnectivityService(), permanent: true);

    // ── 6. Initialize Auth + Nav Controllers ───────────────────────────────────
    Get.put(CustomerController());
    Get.put(AuthController(), permanent: true);
    Get.put(SignupController(), permanent: true);
    Get.put(BottomNavController(), permanent: true);
    Get.put(BottomNavAdminController(), permanent: true);
  }
}
