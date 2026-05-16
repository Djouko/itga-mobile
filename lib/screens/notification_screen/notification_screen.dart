import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/date_time_extension.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/managers/ads/banner_ad.dart';
import 'package:untitled/common/managers/load_more_widget.dart';
import 'package:untitled/common/managers/my_refresh_indicator.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/common/widgets/network_error_view.dart';
import 'package:untitled/common/widgets/no_data_view.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/notification_model.dart';
import 'package:untitled/models/user_notification_model.dart';
import 'package:untitled/screens/company/company_public_profile_screen.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/notification_screen/notification_controller.dart';
import 'package:untitled/screens/profile_screen/profile_screen.dart';
import 'package:untitled/screens/rooms_screen/single_room/single_room_screen.dart';
import 'package:untitled/screens/single_post_screen/single_post_screen.dart';
import 'package:untitled/screens/single_reel_screen/single_reel_screen.dart';
import 'package:untitled/common/controller/notification_badge_controller.dart';
import 'package:untitled/utilities/const.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    NotificationScreenController controller = NotificationScreenController();
    if (Get.isRegistered<NotificationBadgeController>()) {
      NotificationBadgeController.to.markAllAsRead();
    }
    return Scaffold(
      body: Column(
        children: [
          const TopBarForInView(title: LKeys.notification),
          GetBuilder<NotificationScreenController>(
              init: controller,
              builder: (controller) {
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        color: cDarkBG,
                        width: double.infinity,
                        child: Column(
                          children: [
                            const SizedBox(height: 15),
                            segmentController(controller),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                      Expanded(
                        child: PageView(
                          controller: controller.controller,
                          onPageChanged: controller.onChangePage,
                          children: [
                            MyRefreshIndicator(
                              onRefresh: () async {
                                await controller.fetchUserNotifications(
                                    shouldRefresh: true);
                              },
                              child: controller.hasNetworkError &&
                                      controller.userNotifications.isEmpty
                                  ? NetworkErrorView(onRetry: () {
                                      controller.fetchUserNotifications(
                                          shouldRefresh: true);
                                      controller.fetchNotification(
                                          shouldRefresh: true);
                                    })
                                  : NoDataView(
                                      showShow: !controller.isLoading.value &&
                                          controller.userNotifications.isEmpty,
                                      child: LoadMoreWidget(
                                        loadMore:
                                            controller.fetchUserNotifications,
                                        child: ListView.builder(
                                          physics:
                                              AlwaysScrollableScrollPhysics(),
                                          controller:
                                              controller.userScrollController,
                                          padding: const EdgeInsets.all(10),
                                          itemCount: controller
                                              .userNotifications.length,
                                          itemBuilder: (context, index) {
                                            return RepaintBoundary(
                                              child: UserNotificationCard(
                                                notification: controller
                                                    .userNotifications[index],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                            ),
                            MyRefreshIndicator(
                              onRefresh: () async {
                                await controller.fetchNotification(
                                    shouldRefresh: true);
                              },
                              child: LoadMoreWidget(
                                loadMore: controller.fetchNotification,
                                child: listView(controller: controller),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          BannerAdView(bottom: true)
        ],
      ),
    );
  }

  Widget segmentController(NotificationScreenController controller) {
    return CupertinoSlidingSegmentedControl(
      children: {
        0: buildSegment(LKeys.forYou, 0, controller),
        1: buildSegment(LKeys.platform, 1, controller)
      },
      groupValue: controller.selectedPage,
      backgroundColor: cWhite.withValues(alpha: 0.12),
      thumbColor: cPrimary,
      padding: const EdgeInsets.all(0),
      onValueChanged: (value) {
        controller.onChangeSegment(value ?? 0);
      },
    );
  }

  Widget buildSegment(
      String text, int index, NotificationScreenController controller) {
    return Container(
      alignment: Alignment.center,
      width: (Get.width / 2) - 30,
      child: Text(
        text.tr.toUpperCase(),
        style: MyTextStyle.gilroySemiBold(
                size: 13,
                color: controller.selectedPage == index
                    ? cWhite
                    : cWhite.withValues(alpha: 0.7))
            .copyWith(letterSpacing: 2),
      ),
    );
  }

  Widget listView({required NotificationScreenController controller}) {
    return ListView.builder(
      physics: AlwaysScrollableScrollPhysics(),
      controller: controller.scrollController,
      padding: const EdgeInsets.all(10),
      itemCount: controller.notifications.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: NotificationCard(
            notification: controller.notifications[index],
          ),
        );
      },
    );
  }
}

class UserNotificationCard extends StatelessWidget {
  final UserNotification notification;

  const UserNotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final timeAgo = _parseTimeAgo();
    final thumbnailUrl = _getThumbnailUrl();
    final actorName = notification.company?.name ?? notification.user?.fullName;
    final actorImage = notification.company?.logo ?? notification.user?.profile;
    return GestureDetector(
      onTap: () => _navigateToNotification(notification),
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.transparent
              : cPrimary.withValues(alpha: 0.04),
          border: Border(
              bottom: BorderSide(color: cLightText.withValues(alpha: 0.06))),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                if (notification.company?.id != null) {
                  Get.to(() => CompanyPublicProfileScreen(
                      companyId: notification.company!.id!));
                } else {
                  Get.to(
                      () => ProfileScreen(userId: notification.user?.id ?? 0));
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  MyCachedProfileImage(
                    imageUrl: actorImage,
                    fullName: actorName,
                    width: 48,
                    height: 48,
                    cornerRadius: 24,
                  ),
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _typeColor(),
                        shape: BoxShape.circle,
                        border: Border.all(color: cWhite, width: 2),
                      ),
                      child: Icon(_typeIcon(), color: cWhite, size: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: actorName ?? '',
                          style: MyTextStyle.gilroyBold(size: 14, color: cNavy),
                        ),
                        TextSpan(
                          text: ' ${notificationContent()}',
                          style: MyTextStyle.gilroyRegular(
                              size: 14,
                              color: cDarkText.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    timeAgo,
                    style: MyTextStyle.gilroyRegular(
                        size: 12, color: cLightText.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            if (thumbnailUrl != null) ...[
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: MyCachedImage(
                  imageUrl: thumbnailUrl,
                  width: 44,
                  height: 44,
                ),
              )
            ],
            if (!notification.isRead && thumbnailUrl == null)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                    color: cPrimary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  String _parseTimeAgo() {
    if (notification.createdAt == null) return '';
    try {
      return DateTime.parse(notification.createdAt!).timeAgo();
    } catch (_) {
      return '';
    }
  }

  String? _getThumbnailUrl() {
    final postContents = notification.post?.content;
    if (postContents != null && postContents.isNotEmpty) {
      return postContents.first.thumbnail ?? postContents.first.content;
    }
    if (notification.reel?.thumbnail != null) {
      return notification.reel?.thumbnail;
    }
    return null;
  }

  IconData _typeIcon() {
    final t = (notification.type ?? 0).toInt();
    if (t == 1) return Icons.person_add_rounded;
    if (t == 2 || t == 10 || t == 12 || t == 13)
      return Icons.chat_bubble_rounded;
    if (t == 3 || t == 9) return Icons.favorite_rounded;
    if (t >= 4 && t <= 8) return Icons.group_rounded;
    if (t == 11 || t == 14) return Icons.alternate_email_rounded;
    if (t == 15) return Icons.repeat_rounded;
    return Icons.notifications_rounded;
  }

  Color _typeColor() {
    final t = (notification.type ?? 0).toInt();
    if (t == 1) return cNavy;
    if (t == 3 || t == 9) return cRed;
    if (t == 2 || t == 10 || t == 12 || t == 13) return cTeal;
    if (t >= 4 && t <= 8) return cMagenta;
    if (t == 11 || t == 14) return cPrimary;
    if (t == 15) return cCyan;
    return cLightText;
  }

  void _navigateToNotification(UserNotification n) {
    final type = (n.type ?? 0).toInt();
    switch (type) {
      case 1: // follow
        if (n.company != null || (n.companyId != null && n.companyId != 0)) {
          Get.to(() => CompanyPublicProfileScreen(
              companyId: (n.companyId ?? n.company?.id ?? 0).toInt()));
        } else {
          Get.to(() => ProfileScreen(userId: n.user?.id ?? n.userId ?? 0));
        }
        break;
      case 2: // commented on post
      case 3: // liked post
      case 11: // mentioned in post
      case 12: // mentioned in comment
      case 15: // reposted post
        if (n.postId != null && n.postId != 0) {
          Get.to(() => SinglePostScreen(postId: (n.postId ?? 0).toInt()));
        } else if (n.post != null) {
          Get.to(() => SinglePostScreen(postId: (n.post?.id ?? 0).toInt()));
        } else {
          Get.to(() => ProfileScreen(userId: n.user?.id ?? 0));
        }
        break;
      case 4: // invited to room
      case 5: // accepted room invitation
      case 6: // requested to join room
      case 7: // joined room
      case 8: // accepted join request
        if (n.room != null) {
          Get.to(() => SingleRoomScreen(roomId: (n.room?.id ?? 0).toInt()));
        } else {
          Get.to(() => ProfileScreen(userId: n.user?.id ?? 0));
        }
        break;
      case 9: // liked reel
      case 10: // commented on reel
      case 13: // mentioned in reel comment
      case 14: // mentioned in reel
        if (n.reelId != null && n.reelId != 0) {
          Get.to(() => SingleReelScreen(reelId: (n.reelId ?? 0).toInt()));
        } else if (n.reel != null) {
          Get.to(() => SingleReelScreen(reelId: (n.reel?.id ?? 0).toInt()));
        } else {
          Get.to(() => ProfileScreen(userId: n.user?.id ?? 0));
        }
        break;
      default:
        if (n.reel != null || (n.reelId != null && n.reelId != 0)) {
          Get.to(() =>
              SingleReelScreen(reelId: (n.reelId ?? n.reel?.id ?? 0).toInt()));
        } else if (n.post != null || (n.postId != null && n.postId != 0)) {
          Get.to(() =>
              SinglePostScreen(postId: (n.postId ?? n.post?.id ?? 0).toInt()));
        } else if (n.room != null) {
          Get.to(() => SingleRoomScreen(roomId: (n.room?.id ?? 0).toInt()));
        } else if (n.company != null ||
            (n.companyId != null && n.companyId != 0)) {
          Get.to(() => CompanyPublicProfileScreen(
              companyId: (n.companyId ?? n.company?.id ?? 0).toInt()));
        } else {
          Get.to(() => ProfileScreen(userId: n.user?.id ?? 0));
        }
    }
  }

  String notificationContent() {
    switch ((notification.type ?? 0).toInt()) {
      case 1:
        return LKeys.hasStartedFollowingYou.tr;
      case 2:
        return LKeys.hasCommentedToYourPost.tr;
      case 3:
        return LKeys.hasLikedYourPost.tr;
      case 4:
        return '${LKeys.hasInvitedToRoom.tr} ${notification.room?.title ?? ''}';
      case 5:
        return '${LKeys.hasAcceptedYourInvitationOfRoom.tr} ${notification.room?.title ?? ''}';
      case 6:
        return '${LKeys.hasRequestedToJoinYourRoom.tr} ${notification.room?.title ?? ''}';
      case 7:
        return '${LKeys.hasJoinedYourRoom.tr} ${notification.room?.title ?? ''}';
      case 8:
        return '${LKeys.hasAcceptedYourJoinRequestOfRoom.tr} ${notification.room?.title ?? ''}';
      case 9:
        return LKeys.hasLikedYourReel.tr;
      case 10:
        return LKeys.hasCommentedToYourReel.tr;
      case 11:
        return LKeys.hasMentionedYouInAPost.tr;
      case 12:
        return LKeys.hasMentionedYouInAComment.tr;
      case 13:
        return LKeys.hasMentionedYouInAReelComment.tr;
      case 14:
        return LKeys.hasMentionedYouInAReel.tr;
      case 15:
        return LKeys.hasRepostedYourPost.tr;
    }
    return "";
  }
}

class NotificationCard extends StatelessWidget {
  final PlatformNotification notification;

  const NotificationCard({Key? key, required this.notification})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cNavy,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Image.asset(MyImages.logo, width: 22, height: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: notification.title ?? '',
                        style: MyTextStyle.gilroyBold(size: 14, color: cNavy),
                      ),
                      TextSpan(
                        text: ' ${notification.description ?? ''}',
                        style: MyTextStyle.gilroyRegular(
                            size: 14, color: cDarkText.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
