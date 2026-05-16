import 'dart:async';

import 'package:get/get.dart';
import 'package:untitled/common/api_service/common_service.dart';

class NotificationBadgeController extends GetxController {
  static NotificationBadgeController get to => Get.find<NotificationBadgeController>();

  RxInt unreadCount = 0.obs;
  Timer? _timer;

  @override
  void onReady() {
    super.onReady();
    fetchUnreadCount();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchUnreadCount();
    });
  }

  Future<void> fetchUnreadCount() async {
    int count = await CommonService.shared.fetchUnreadNotificationCount();
    unreadCount.value = count;
  }

  Future<void> markAllAsRead() async {
    await CommonService.shared.markNotificationsAsRead();
    unreadCount.value = 0;
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
