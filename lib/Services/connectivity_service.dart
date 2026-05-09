// lib/Services/connectivity_service.dart
// Monitors network connectivity status
// Used to decide: load from Firestore (online) or Hive cache (offline)

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final RxBool isOnline = true.obs;

  @override
  void onInit() {
    super.onInit();
    _monitorConnectivity();
  }

  Future<void> _monitorConnectivity() async {
    // Check initial state
    final result = await Connectivity().checkConnectivity();
    isOnline.value = _isConnected(result);

    // Listen for changes
    Connectivity().onConnectivityChanged.listen((result) {
      isOnline.value = _isConnected(result);
    });
  }

  bool _isConnected(List<ConnectivityResult> result) {
    return result.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  // Easy check: call this anywhere
  static bool get online =>
      Get.find<ConnectivityService>().isOnline.value;
}
