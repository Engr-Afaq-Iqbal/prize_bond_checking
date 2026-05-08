import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class CustomerModel {
  final String uid;
  final String name;
  final String email;
  final String status;

  CustomerModel(
      {required this.uid,
      required this.name,
      required this.email,
      required this.status});

  factory CustomerModel.fromFirestore(var doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return CustomerModel(
      uid: doc.id,
      name: data['firstName'] ?? 'No Name',
      email: data['email'] ?? '',
      status: data['status'] ?? 'pending',
    );
  }
}

class CustomerController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<CustomerModel> customers = [];
  bool isLoading = false;

  @override
  void onInit() {
    fetchCustomers();
    super.onInit();
  }

  Future<void> fetchCustomers() async {
    isLoading = true;
    update();
    try {
      var snapshot = await _firestore.collection('customers').get();
      customers =
          snapshot.docs.map((doc) => CustomerModel.fromFirestore(doc)).toList();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> updateStatus(String uid, String newStatus) async {
    await _firestore
        .collection('customers')
        .doc(uid)
        .update({'status': newStatus});
    fetchCustomers(); // Refresh list
    Get.back(); // Close bottom sheet
    Get.snackbar("Success", "Status updated to $newStatus");
  }
}
