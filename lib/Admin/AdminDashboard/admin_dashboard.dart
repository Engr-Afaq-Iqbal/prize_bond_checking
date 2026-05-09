// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../Controllers/AuthControllers/auth_controller.dart';
// import '../../Utils/dimensions.dart';
//
// class AdminDashboard extends StatelessWidget {
//   const AdminDashboard({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Admin Dashboard'),
//         actions: [
//           GestureDetector(
//             onTap: () {
//               Get.find<AuthController>().signOut();
//               // Get.offAll(() => SignInPage());
//             },
//             child: Icon(
//               Icons.logout,
//               size: 30,
//             ),
//           ),
//           size50w,
//         ],
//       ),
//     );
//   }
// }

// lib/Admin/AdminDashboard/admin_dashboard.dart
// UPDATED: Now shows the full AdminDashboardScreen instead of empty widget
// Preserves existing import path used in bottom_nav_controller

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controllers/AdminControllers/admin_draw_controller.dart';
import '../../View/Admin/AdminDashboard/admin_dashboard_screen.dart';

// This class keeps the existing import path working.
// It simply delegates to the full AdminDashboardScreen.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Put AdminDrawController here so it's available to all admin screens
    Get.put(AdminDrawController());
    return const AdminDashboardScreen();
  }
}
