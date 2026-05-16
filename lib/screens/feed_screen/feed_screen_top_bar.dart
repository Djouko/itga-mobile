import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/screens/audio_space/audio_spaces_screen/audio_spaces_screen.dart';
import 'package:untitled/screens/extra_views/logo_tag.dart';
import 'package:untitled/screens/notification_screen/notification_screen.dart';
import 'package:untitled/screens/random_screen/random_screen.dart';
import 'package:untitled/screens/search_screen/search_screen.dart';
import 'package:untitled/common/controller/notification_badge_controller.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/utilities/const.dart';

class FeedScreenTopBar extends StatelessWidget {
  const FeedScreenTopBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double imageSize = 25;
    return Container(
      color: cBG,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const LogoTag(),
            Row(
              children: [
                InkWell(
                  onTap: () {
                    Get.to(() => const NotificationScreen());
                  },
                  child: Obx(() {
                    final count = Get.isRegistered<NotificationBadgeController>()
                        ? NotificationBadgeController.to.unreadCount.value
                        : 0;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Image.asset(
                          MyImages.bell,
                          width: imageSize,
                          height: imageSize,
                        ),
                        if (count > 0)
                          Positioned(
                            right: -8,
                            top: -5,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: cRed,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Center(
                                child: Text(
                                  count > 99 ? '99+' : '$count',
                                  style: MyTextStyle.gilroyBold(size: 9, color: cWhite),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
                InkWell(
                  onTap: () {
                    Get.to(() => RandomScreen());
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Image.asset(
                      MyImages.random,
                      width: 20,
                    ),
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    Get.to(() => const AudioSpacesScreen());
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Image.asset(
                      MyImages.audioRoom,
                      width: imageSize,
                      height: imageSize,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Get.to(() => const SearchScreen());
                  },
                  child: Image.asset(
                    MyImages.search,
                    width: imageSize,
                    height: imageSize,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
