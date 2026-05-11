import 'package:get/get.dart';
import 'package:prize_bond_app/Controllers/AuthControllers/auth_controller.dart';
import 'package:prize_bond_app/Controllers/AuthControllers/signup_controller.dart';
import 'package:prize_bond_app/Controllers/CustomerController/customer_controller.dart';
import 'package:prize_bond_app/Controllers/DrawControllers/draw_controller.dart';
import 'package:prize_bond_app/Controllers/bottom_nav_controller.dart';
import 'package:prize_bond_app/Controllers/user_controller.dart';

import '../../Services/connectivity_service.dart';

class AppController {
  void initializeController() {
    // ── Services ──────────────────────────────────────────────────────────────
    Get.put(ConnectivityService(), permanent: true);

    // ── Draw data (needed by both Home and Draws screens) ─────────────────────
    Get.put(DrawController(), permanent: true);

    // ── User profile cache (available across all screens) ─────────────────────
    Get.put(UserController(), permanent: true);

    // ── Auth + Nav ────────────────────────────────────────────────────────────
    Get.put(CustomerController());
    Get.put(AuthController(), permanent: true);
    Get.put(SignupController(), permanent: true);
    Get.put(BottomNavController(), permanent: true);
    Get.put(BottomNavAdminController(), permanent: true);
  }
}
