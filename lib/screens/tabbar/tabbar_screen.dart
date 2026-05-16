import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:proste_indexed_stack/proste_indexed_stack.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/managers/ads/banner_ad.dart';
import 'package:untitled/common/managers/company_mode_controller.dart';
import 'package:untitled/common/managers/connectivity_service.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/functions.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/chats_screen/chats_screen.dart';
import 'package:untitled/screens/chats_screen/chats_screen_controller.dart';
import 'package:untitled/screens/company/company_dashboard_screen.dart';
import 'package:untitled/screens/dashboard_reels_screen/dashboard_reels_screen.dart';
import 'package:untitled/screens/feed_screen/feed_screen.dart';
import 'package:untitled/screens/profile_screen/profile_screen.dart';
import 'package:untitled/screens/random_screen/random_screen.dart';
import 'package:untitled/screens/rooms_screen/rooms_screen.dart';
import 'package:untitled/common/controller/notification_badge_controller.dart';
import 'package:untitled/screens/tabbar/tabbar_controller.dart';
import 'package:untitled/utilities/const.dart';

class TabBarScreen extends StatelessWidget {
  TabBarScreen({Key? key}) : super(key: key);
  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final TabBarController controller = Get.put(TabBarController());
    final ChatsScreensController chatScreenController = Get.put(ChatsScreensController());
    Get.put(NotificationBadgeController());
    CompanyModeController.to;
    Functions.changStatusBar(StatusBarStyle.black);
    return Scaffold(
      backgroundColor: cWhite,
      body: GetBuilder<TabBarController>(
        builder: (controller) {
          return Column(
            children: [
              _CompanyModeBanner(),
              Obx(() {
                final cs = ConnectivityService.instance;
                final offline = !cs.isOnline.value;
                final backOnline = cs.showBackOnline.value;
                final showBanner = offline || backOnline;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: showBanner ? 32 : 0,
                  color: offline
                      ? cRed.withValues(alpha: 0.9)
                      : cGreen.withValues(alpha: 0.9),
                  child: showBanner
                      ? Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                offline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                offline ? LKeys.noConnection.tr : LKeys.backOnline.tr,
                                style: MyTextStyle.gilroySemiBold(color: Colors.white, size: 12),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                );
              }),
              Expanded(
                child: ProsteIndexedStack(
                  children: [
                    IndexedStackChild(child: FeedScreen(scrollController: scrollController)),
                    IndexedStackChild(child: RoomsScreen()),
                    IndexedStackChild(child: DashboardReelsScreen(), preload: true),
                    IndexedStackChild(child: ChatsScreen(), preload: true),
                    IndexedStackChild(child: ProfileScreen(isFromTabBar: true, userId: SessionManager.shared.getUserID()), preload: true),
                  ],
                  index: controller.selectedTab,
                ),
              ),
              BannerAdView(),
              Container(
                decoration: BoxDecoration(
                  color: cBlack,
                  border: Border(top: BorderSide(color: cWhite.withValues(alpha: 0.06), width: 0.5)),
                ),
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      button(LKeys.feed, MyImages.quill, 0, controller),
                      button(LKeys.rooms, MyImages.meeting, 1, controller),
                      button(LKeys.reels, MyImages.reels, 2, controller),
                      GetBuilder(
                          init: chatScreenController,
                          builder: (chatScreenController) {
                            return button(LKeys.chats, MyImages.chat, 3, controller, isBudged: chatScreenController.isNewMessage);
                          }),
                      button(LKeys.profile, MyImages.profile, 4, controller),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        init: controller,
      ),
    );
  }

  Widget button(String title, String image, int index, TabBarController controller, {bool isBudged = false}) {
    return GestureDetector(
      onTap: () {
        if (index == 0 && controller.selectedTab == 0) {
          HapticFeedback.mediumImpact();
          if (scrollController.offset == 0) {
            refreshIndicatorKey.currentState?.show();
          } else {
            scrollController.animateTo(0, duration: Duration(milliseconds: 500), curve: Curves.linear);
          }
        }
        controller.selectIndex(index);
      },
      child: Container(
        color: cBlack,
        width: Get.width / 5,
        child: TabBarButton(
          image: image,
          title: title,
          isSelected: controller.selectedTab == index,
          isBudged: isBudged,
        ),
      ),
    );
  }

  Widget selectedWidget(TabBarController controller) {
    switch (controller.selectedTab) {
      case 0:
        return FeedScreen(scrollController: scrollController);
      case 1:
        return RoomsScreen();
      case 2:
        return RandomScreen();
      case 3:
        return ChatsScreen();
      case 4:
        return ProfileScreen(
          isFromTabBar: true,
          userId: SessionManager.shared.getUserID(),
        );
    }
    return Container();
  }
}

class _CompanyModeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = CompanyModeController.to;
      if (!ctrl.isActing) return const SizedBox.shrink();
      return GestureDetector(
        onTap: () {
          final id = ctrl.actingId.value ?? 0;
          ctrl.deactivate();
          if (id > 0) {
            Get.offAll(() => CompanyDashboardScreen(companyId: id));
          }
        },
        child: SafeArea(
          bottom: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF7B2FFF).withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00C4D4).withValues(alpha: 0.16),
                        const Color(0xFF7B2FFF).withValues(alpha: 0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.business_rounded, color: Color(0xFF7B2FFF), size: 17),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'IDENTITE ACTIVE',
                        style: MyTextStyle.gilroyBold(size: 8, color: Colors.black38),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        ctrl.actingName.value,
                        style: MyTextStyle.gilroyBold(size: 12, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B2FFF).withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.dashboard_rounded, color: Color(0xFF7B2FFF), size: 14),
                      const SizedBox(width: 5),
                      Text('Dashboard', style: MyTextStyle.gilroyBold(size: 11, color: const Color(0xFF7B2FFF))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class TabBarButton extends StatelessWidget {
  final String title;
  final String image;
  final bool isSelected;
  final bool isBudged;

  const TabBarButton({Key? key, required this.title, required this.image, required this.isSelected, this.isBudged = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? cPrimary : Colors.transparent,
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topRight,
          children: [
            Image.asset(
              image,
              width: 22,
              height: 22,
              color: isSelected ? cWhite : cLightText.withValues(alpha: 0.5),
            ),
            if (isBudged)
              Positioned(
                bottom: 14,
                left: 14,
                child: Container(
                  height: 9,
                  width: 9,
                  decoration: BoxDecoration(
                    color: cMagenta,
                    shape: BoxShape.circle,
                    border: Border.all(color: cBlack, width: 1.5),
                  ),
                ),
              )
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title.tr,
          style: MyTextStyle.gilroyRegular(
            size: 10,
            color: isSelected ? cWhite : cLightText.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
