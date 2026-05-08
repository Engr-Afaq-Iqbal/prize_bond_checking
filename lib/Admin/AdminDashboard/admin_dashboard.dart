import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controllers/AuthControllers/auth_controller.dart';
import '../../Utils/dimensions.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          GestureDetector(
            onTap: () {
              Get.find<AuthController>().signOut();
              // Get.offAll(() => SignInPage());
            },
            child: Icon(
              Icons.logout,
              size: 30,
            ),
          ),
          size50w,
        ],
      ),
    );
  }
}
