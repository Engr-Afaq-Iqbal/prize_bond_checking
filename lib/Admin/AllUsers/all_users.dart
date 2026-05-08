import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controllers/CustomerController/customer_controller.dart';
import '../../Utils/dimensions.dart';

class CustomerListScreen extends StatelessWidget {
  const CustomerListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CustomerController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Users")),
      body: GetBuilder<CustomerController>(
        builder: (_) => ctrl.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: ctrl.customers.length,
                itemBuilder: (context, index) {
                  final user = ctrl.customers[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    child: ListTile(
                      title: Text(user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(user.email),
                      trailing: _buildStatusChip(user.status),
                      onTap: () => _showStatusEditor(context, user, ctrl),
                    ),
                  );
                },
              ),
      ),
    );
  }

  // Simple UI helper for the status badge
  Widget _buildStatusChip(String status) {
    Color color = status == 'active'
        ? Colors.green
        : (status == 'pending' ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  // Simple BottomSheet for editing status
  void _showStatusEditor(
      BuildContext context, CustomerModel user, CustomerController ctrl) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Update Status for ${user.name}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...['active', 'pending', 'suspended'].map((status) => ListTile(
                  title: Text(status.toUpperCase()),
                  leading: Icon(Icons.circle,
                      color: status == 'active' ? Colors.green : Colors.orange),
                  onTap: () => ctrl.updateStatus(user.uid, status),
                )),
            size40h,
          ],
        ),
      ),
    );
  }
}
