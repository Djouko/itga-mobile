import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/connectivity_service.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/reel_model.dart';

class DashboardReelsController extends BaseController {
  RxList<Reel> reels = <Reel>[].obs;
  RxList<Reel> reelsOfFollowings = <Reel>[].obs;
  RxBool isLoadingForYou = false.obs;
  RxBool isLoadingFollowing = false.obs;
  PageController pageController = PageController(initialPage: DashboardReelPageType.forYou.value);
  Rx<DashboardReelPageType> selectedPageType = DashboardReelPageType.forYou.obs;

  @override
  void onReady() {
    fetchReels();
    fetchFollowingReels();
    ConnectivityService.instance.addOnBackOnline('dashboard_reels_$hashCode', () {
      if (hasNetworkError) {
        hasNetworkError = false;
        fetchReels(shouldReset: reels.isEmpty);
        fetchFollowingReels(shouldReset: reelsOfFollowings.isEmpty);
      }
    });
    super.onReady();
  }

  @override
  void onClose() {
    ConnectivityService.instance.removeOnBackOnline('dashboard_reels_$hashCode');
    super.onClose();
  }

  bool _isFetchingForYou = false;

  Future<void> fetchReels({bool shouldReset = false}) async {
    if (_isFetchingForYou && !shouldReset) return;
    _isFetchingForYou = true;
    isLoadingForYou.value = true;
    isLoading.value = true;
    try {
      var newReels = await ReelService.shared.fetchExploreReels(
        start: shouldReset ? 0 : reels.length,
        type: selectedPageType.value.value,
      );
      if (shouldReset) {
        reels.clear();
      }
      reels.addAll(newReels);
      hasNetworkError = false;
    } catch (_) {
      hasNetworkError = true;
    } finally {
      _isFetchingForYou = false;
      isLoadingForYou.value = false;
      isLoading.value = isLoadingFollowing.value;
    }
  }

  Future<void> refreshReels() async {
    await fetchReels(shouldReset: true);
  }

  bool _isFetchingFollowing = false;

  Future<void> fetchFollowingReels({bool shouldReset = false}) async {
    if (_isFetchingFollowing && !shouldReset) return;
    _isFetchingFollowing = true;
    isLoadingFollowing.value = true;
    isLoading.value = true;
    try {
      var newReels = await ReelService.shared.fetchExploreReels(
        start: shouldReset ? 0 : reelsOfFollowings.length,
        type: DashboardReelPageType.following.value,
      );
      if (shouldReset) {
        reelsOfFollowings.clear();
      }
      reelsOfFollowings.addAll(newReels);
      hasNetworkError = false;
    } catch (_) {
      hasNetworkError = true;
    } finally {
      _isFetchingFollowing = false;
      isLoadingFollowing.value = false;
      isLoading.value = isLoadingForYou.value;
    }
  }

  Future<void> refreshFollowingReels() async {
    await fetchFollowingReels(shouldReset: true);
  }

  void onChangePage(int value) {
    selectedPageType.value = DashboardReelPageType.values.firstWhere((element) => element.value == value);
  }

  void changeTheType(DashboardReelPageType type) {
    selectedPageType.value = type;
    pageController.animateToPage(type.value, duration: Duration(milliseconds: 200), curve: Curves.bounceInOut);
  }
}

enum DashboardReelPageType {
  forYou(1),
  following(0);

  final int value;

  const DashboardReelPageType(this.value);

  String get title {
    switch (this) {
      case DashboardReelPageType.forYou:
        return LKeys.forYou;
      case DashboardReelPageType.following:
        return LKeys.following;
    }
  }
}
