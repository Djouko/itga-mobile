import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:untitled/common/managers/logger.dart';

class ConnectivityService extends GetxService {
  static ConnectivityService get instance => Get.find<ConnectivityService>();

  final Connectivity _connectivity = Connectivity();
  final RxBool isOnline = true.obs;
  final RxBool showBackOnline = false.obs;
  bool _wasOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _backOnlineTimer;

  // Auto-retry: callbacks fired when network comes back after being offline
  final Map<String, void Function()> _onBackOnlineCallbacks = {};

  void addOnBackOnline(String key, void Function() callback) {
    _onBackOnlineCallbacks[key] = callback;
  }

  void removeOnBackOnline(String key) {
    _onBackOnlineCallbacks.remove(key);
  }

  @override
  void onInit() {
    super.onInit();
    _checkInitial();
    _subscription = _connectivity.onConnectivityChanged.listen(_onChanged);
  }

  Future<void> _checkInitial() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _onChanged(results);
    } catch (_) {}
  }

  void _onChanged(List<ConnectivityResult> results) async {
    if (results.contains(ConnectivityResult.none)) {
      _wasOffline = true;
      isOnline.value = false;
      showBackOnline.value = false;
      _backOnlineTimer?.cancel();
      Loggers.warning('Network: OFFLINE');
      return;
    }
    // Has a connection type, but verify actual internet access
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      final nowOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      isOnline.value = nowOnline;

      if (nowOnline && _wasOffline) {
        _wasOffline = false;
        showBackOnline.value = true;
        _backOnlineTimer?.cancel();
        _backOnlineTimer = Timer(const Duration(seconds: 3), () {
          showBackOnline.value = false;
        });
        // Fire all auto-retry callbacks after a short delay to let network stabilize
        Loggers.info('Network: Back online — firing ${_onBackOnlineCallbacks.length} auto-retry callbacks');
        Future.delayed(const Duration(milliseconds: 800), () {
          for (final cb in _onBackOnlineCallbacks.values.toList()) {
            try { cb(); } catch (e) { Loggers.error('Network: Auto-retry callback error: $e'); }
          }
        });
      }
    } on SocketException {
      _wasOffline = true;
      isOnline.value = false;
    } on TimeoutException {
      _wasOffline = true;
      isOnline.value = false;
    }
    Loggers.info('Network: ${isOnline.value ? "ONLINE" : "OFFLINE"}');
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _backOnlineTimer?.cancel();
    super.onClose();
  }
}
