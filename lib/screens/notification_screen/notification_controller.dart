import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/common_service.dart';
import 'package:untitled/common/controller/cupertino_controller.dart';
import 'package:untitled/common/managers/connectivity_service.dart';
import 'package:untitled/models/notification_model.dart';
import 'package:untitled/models/user_notification_model.dart';

class NotificationScreenController extends CupertinoController {
  ScrollController scrollController = ScrollController();
  ScrollController userScrollController = ScrollController();
  List<PlatformNotification> notifications = [];
  List<UserNotification> userNotifications = [];
  bool hasNetworkError = false;

  final _retryKey = 'notification_screen';

  @override
  void onReady() {
    fetchUserNotifications();
    fetchNotification();
    _registerAutoRetry();
    super.onReady();
  }

  void _registerAutoRetry() {
    if (Get.isRegistered<ConnectivityService>()) {
      Get.find<ConnectivityService>().addOnBackOnline(_retryKey, () {
        if (hasNetworkError) {
          hasNetworkError = false;
          fetchUserNotifications(shouldRefresh: true);
          fetchNotification(shouldRefresh: true);
        }
      });
    }
  }

  Future<void> fetchNotification({bool shouldRefresh = false}) async {
    try {
      await CommonService.shared.fetchPlatformNotification(shouldRefresh ? 0 : notifications.length, (newNotifications) {
        hasNetworkError = false;
        if (shouldRefresh) {
          notifications.clear();
        }
        notifications.addAll(newNotifications);
        update();
      });
    } catch (_) {
      hasNetworkError = true;
      update();
    }
  }

  Future<void> fetchUserNotifications({bool shouldRefresh = false}) async {
    if (userNotifications.isEmpty) {
      isLoading.value = true;
      update();
    }

    try {
      await CommonService.shared.fetchUserNotifications(shouldRefresh ? 0 : userNotifications.length, (notifications) {
        hasNetworkError = false;
        isLoading.value = false;
        if (shouldRefresh) {
          userNotifications.clear();
        }
        userNotifications.addAll(notifications);
        update();
      });
    } catch (_) {
      hasNetworkError = true;
      isLoading.value = false;
      update();
    }
  }

  @override
  void onClose() {
    if (Get.isRegistered<ConnectivityService>()) {
      Get.find<ConnectivityService>().removeOnBackOnline(_retryKey);
    }
    super.onClose();
  }
}
