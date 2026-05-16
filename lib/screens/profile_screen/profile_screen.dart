import 'dart:convert';

import 'package:detectable_text_field/detectable_text_field.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:untitled/common/managers/url_extractor/metadata_extract_base.dart';
import 'package:untitled/common/managers/url_extractor/parsers/base_parser.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/utils/achievement_badges.dart';
import 'package:untitled/common/extensions/int_extension.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/buttons/floating_btn_for_creating.dart';
import 'package:untitled/common/widgets/functions.dart';
import 'package:untitled/common/widgets/menu.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/enums/reel_page_type.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/company/company_dashboard_screen.dart';
import 'package:untitled/screens/chats_screen/chatting_screen/chatting_view.dart';
import 'package:untitled/screens/company/company_public_profile_screen.dart';
import 'package:untitled/screens/extra_views/back_button.dart';
import 'package:untitled/common/widgets/loader_widget.dart';
import 'package:untitled/common/widgets/network_error_view.dart';
import 'package:untitled/common/widgets/no_data_view.dart';
import 'package:untitled/screens/feed_screen/feed_screen.dart';
import 'package:untitled/screens/post/post_card.dart';
import 'package:untitled/screens/follow_button/follow_button.dart';
import 'package:untitled/screens/profile_screen/follower_following/follower_following_screen.dart';
import 'package:untitled/screens/profile_screen/full_image_screen.dart';
import 'package:untitled/screens/profile_screen/profile_controller.dart';
import 'package:untitled/screens/reels_screen/reels_grid.dart';
import 'package:untitled/screens/report_screen/report_sheet.dart';
import 'package:untitled/screens/rooms_screen/room_card.dart';
import 'package:untitled/screens/setting_screen/setting_screen.dart';
import 'package:untitled/screens/story_screen/story_screen.dart';
import 'package:untitled/utilities/const.dart';

class ProfileScreen extends StatelessWidget {
  final num userId;

  const ProfileScreen(
      {Key? key, this.isFromTabBar = false, required this.userId})
      : super(key: key);
  final bool isFromTabBar;

  @override
  Widget build(BuildContext context) {
    final ProfileController controller =
        ProfileController(userId.toInt(), isFromTabBar);
    final bool isMyProfile =
        controller.userID == SessionManager.shared.getUserID();
    Functions.changStatusBar(StatusBarStyle.white);
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomRight,
        children: [
          GetBuilder(
              id: controller.scrollID,
              tag: controller.scrollID,
              init: controller,
              builder: (controller) {
                return RefreshIndicator(
                  triggerMode: RefreshIndicatorTriggerMode.anywhere,
                  color: refreshIndicatorColor,
                  backgroundColor: refreshIndicatorBgColor,
                  onRefresh: () async {
                    await controller.getProfile(isForRefresh: true);
                    await controller.fetchUserPosts(isForRefresh: true);
                    await controller.fetchReels(shouldRefresh: true);
                  },
                  child: CustomScrollView(
                    controller: controller.scrollController,
                    physics: AlwaysScrollableScrollPhysics(),
                    slivers: <Widget>[
                      GetBuilder(
                          id: controller.scrollID,
                          tag: controller.scrollID,
                          init: controller,
                          builder: (_) {
                            var temp = (controller.currentExtent * 0.28);
                            var size = temp < 35.0 ? 35.0 : temp;
                            var o = (-1 * (size - 70)) * 0.02857143;
                            var opacity = 1 - (o > 1.0 ? 1.0 : o);
                            return SliverAppBar(
                              pinned: true,
                              backgroundColor: Colors.transparent,
                              expandedHeight: controller.maxExtent,
                              collapsedHeight: 60,
                              stretch: true,
                              shadowColor: Colors.transparent,
                              leadingWidth: 0,
                              automaticallyImplyLeading: false,
                              flexibleSpace: FlexibleSpaceBar(
                                expandedTitleScale: 1,
                                titlePadding: const EdgeInsets.all(0),
                                collapseMode: CollapseMode.pin,
                                title: Stack(
                                  children: [
                                    Stack(
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            var backgroundImage = controller
                                                    .user?.backgroundImage ??
                                                '';
                                            if (backgroundImage.isNotEmpty) {
                                              Get.context!.pushTransparentRoute(
                                                FullImageScreen(
                                                  image: backgroundImage,
                                                  tag:
                                                      'BackgroundImage_${controller.userID}_${controller.idForImage}',
                                                  width: Get.width,
                                                  height: null,
                                                  cornerRadius: 0,
                                                ),
                                              );
                                            }
                                          },
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Container(color: cBlack),
                                              Hero(
                                                tag:
                                                    'BackgroundImage_${controller.userID}_${controller.idForImage}',
                                                child: MyCachedImage(
                                                  imageUrl: controller.user
                                                          ?.backgroundImage ??
                                                      '',
                                                  width: Get.width,
                                                  height: 170 +
                                                      Get.mediaQuery.viewInsets
                                                          .top,
                                                ),
                                              ),
                                              if (opacity < 0.98)
                                                Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin:
                                                          Alignment.topCenter,
                                                      end: Alignment
                                                          .bottomCenter,
                                                      colors: [
                                                        Colors.black.withValues(
                                                            alpha:
                                                                (1 - opacity) *
                                                                    0.55),
                                                        Colors.transparent,
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  isFromTabBar ? 15 : 45,
                                              vertical: 12),
                                          child: temp < 5
                                              ? namePlate(controller,
                                                  isFromTop: true)
                                              : Container(),
                                        ),
                                        top(controller, opacity)
                                      ],
                                    ),
                                    SafeArea(
                                      child: Container(
                                        // padding: const EdgeInsets.only(top: 18, right: 15, left: 7),
                                        child: Row(
                                          children: [
                                            !isFromTabBar
                                                ? GestureDetector(
                                                    onTap: () {
                                                      Get.back();
                                                    },
                                                    child: const Icon(
                                                      Icons
                                                          .chevron_left_rounded,
                                                      color: cWhite,
                                                      size: 30,
                                                    ),
                                                  )
                                                : const SizedBox(
                                                    width: 30,
                                                    height: 30,
                                                  ),
                                            const Spacer(),
                                            if (isMyProfile)
                                              InkWell(
                                                onTap: () {
                                                  Get.to(() =>
                                                          const SettingScreen())
                                                      ?.then((value) {
                                                    controller
                                                        .updateMyProfile();
                                                  });
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 18,
                                                          right: 15,
                                                          left: 15,
                                                          bottom: 15),
                                                  child: const Icon(
                                                    Icons.settings,
                                                    size: 24,
                                                    color: cWhite,
                                                  ),
                                                ),
                                              )
                                            else
                                              Container(
                                                padding: const EdgeInsets.only(
                                                    top: 18,
                                                    right: 15,
                                                    left: 15,
                                                    bottom: 15),
                                                child: profileMenu(controller),
                                              )
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                stretchModes: const [
                                  StretchMode.zoomBackground
                                ],
                                // background: GestureDetector(
                                //   child: MyCachedImage(
                                //     imageUrl: controller.user?.backgroundImage ?? '',
                                //     // width: Get.width,
                                //     height: 190 + Get.mediaQuery.viewInsets.top,
                                //   ),
                                // ),
                              ),
                            );
                          }),
                      if (controller.hasNetworkError &&
                          controller.user?.username == null)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: NetworkErrorView(onRetry: () {
                            controller.getProfile();
                            controller.fetchUserPosts(
                                userID: controller.userID);
                            controller.fetchReels();
                          }),
                        )
                      else ...[
                        // Static header — never rebuilds during scroll
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              details(controller),
                              const SizedBox(height: 10),
                              segmentController(controller),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                        // Posts tab — true lazy SliverList, no shrinkWrap
                        Obx(() => controller.selectedPage.value == 0
                            ? _ProfilePostsSliver(
                                controller: controller,
                                onDeletePost: (id) {
                                  controller.posts
                                      .removeWhere((p) => p.id == id);
                                  controller.update([controller.profileFeedID]);
                                },
                                onRefresh: () => controller
                                    .update([controller.profileFeedID]),
                              )
                            : const SliverToBoxAdapter(
                                child: SizedBox.shrink())),
                        // Reels tab
                        Obx(() => controller.selectedPage.value == 1
                            ? SliverToBoxAdapter(
                                child: gridReelsView(controller))
                            : const SliverToBoxAdapter(
                                child: SizedBox.shrink())),
                        // About tab
                        Obx(() => controller.selectedPage.value == 2
                            ? SliverToBoxAdapter(
                                child: aboutTabView(controller))
                            : const SliverToBoxAdapter(
                                child: SizedBox.shrink())),
                      ],
                    ],
                  ),
                );
              }),
          isMyProfile
              ? GetBuilder(
                  init: controller,
                  builder: (controller) {
                    return FloatingBtnForCreating(
                      onPostBack: (post) {
                        controller.fetchUserPosts(isForRefresh: true);
                      },
                      onStoryBack: () {
                        controller.getStories();
                      },
                      onReelBack: (reel) {
                        controller.fetchReels(shouldRefresh: true);
                      },
                    );
                  })
              : Container(),
        ],
      ),
    );
  }

  Widget gridReelsView(ProfileController controller) {
    return ReelsGrid(
      reels: controller.reels,
      reelType: ReelPageType.user,
      isLoading: controller.isLoading,
      onFetchMoreData: controller.fetchReels,
      shrinkWrap: true,
      user: controller.user,
      menus: [
        if (controller.userID == SessionManager.shared.getUserID())
          ContextMenuElement(
            title: LKeys.delete.tr,
            onTap: controller.deleteReel,
          ),
        if (SessionManager.shared.getUser()?.isModerator == 1 &&
            controller.userID != SessionManager.shared.getUserID())
          ContextMenuElement(
            title: LKeys.delete.tr,
            onTap: controller.deleteReelByModerator,
          ),
      ],
    );
  }

  Widget top(ProfileController controller, double opacity) {
    final bool hasStories = (controller.user?.stories ?? []).isNotEmpty;
    final bool hasUnseenStories =
        hasStories && controller.user?.isAllStoryShown() == false;
    final String displayProfileImage =
        ((controller.user?.ownedCompany?.logo ?? '').isNotEmpty)
            ? controller.user?.ownedCompany?.logo ?? ''
            : controller.user?.profile ?? '';
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // LinkedIn/Twitter-style gradient band (taller + gradient for smooth blend)
        Container(
          height: 90,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                cBlack.withValues(alpha: opacity * 0.6),
                cBlack.withValues(alpha: opacity),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(width: isFromTabBar ? 0 : (1 - opacity) * 25),
                  GestureDetector(
                    onLongPress: () {
                      Get.context!.pushTransparentRoute(
                        FullImageScreen(
                          image: displayProfileImage,
                          tag:
                              'ProfileImage${controller.userID}_${controller.idForImage}',
                          width: Get.width - 100,
                          height: Get.width - 100,
                        ),
                      );
                    },
                    onTap: () {
                      if (hasStories) {
                        Get.bottomSheet(
                                StoryScreen(
                                    users: [controller.user ?? User()],
                                    index: 0),
                                isScrollControlled: true,
                                ignoreSafeArea: false)
                            .then((value) {
                          controller.getStories();
                        });
                      } else {
                        Get.context!.pushTransparentRoute(
                          FullImageScreen(
                            image: displayProfileImage,
                            tag:
                                'ProfileImage${controller.userID}_${controller.idForImage}',
                            width: Get.width - 100,
                            height: Get.width - 100,
                          ),
                        );
                      }
                    },
                    child: Opacity(
                      opacity: opacity,
                      child: Hero(
                        tag:
                            'ProfileImage${controller.userID}_${controller.idForImage}',
                        transitionOnUserGestures: true,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: SmoothBorderRadius.all(SmoothRadius(
                                cornerRadius: 17,
                                cornerSmoothing: cornerSmoothing)),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2)),
                            ],
                          ),
                          child: ClipSmoothRect(
                            radius: const SmoothBorderRadius.all(SmoothRadius(
                                cornerRadius: 17,
                                cornerSmoothing: cornerSmoothing)),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              color: hasStories
                                  ? (hasUnseenStories ? cPrimary : cLightText)
                                  : cBlack,
                              child: MyCachedImage(
                                imageUrl: displayProfileImage,
                                width: opacity == 0 ? 0 : 85,
                                height: opacity == 0 ? 0 : 85,
                                cornerRadius: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  (!(controller.user?.isBlockedByMe() ?? false))
                      ? Opacity(
                          opacity: opacity,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: followBtn(controller),
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ],
    );
  }

  Widget namePlate(ProfileController controller, {bool isFromTop = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                controller.user?.fullName ?? '',
                style: MyTextStyle.gilroyBlack(
                    color: cWhite, size: isFromTop ? 20 : 24),
                maxLines: 1,
              ),
            ),
            VerifyIcon(
              user: controller.user,
            )
          ],
        ),
        Text(
          '@${controller.user?.username ?? ''}',
          style: MyTextStyle.gilroyLight(color: cPrimary),
        ),
      ],
    );
  }

  Widget details(ProfileController controller) {
    return GetBuilder(
        init: controller,
        tag: "${controller.userID}",
        builder: (controller) {
          if (controller.user == null) return Container();
          final user = controller.user!;
          final bool hasHeadline =
              user.headline != null && user.headline!.isNotEmpty;
          final bool hasLocation =
              user.location != null && user.location!.isNotEmpty;

          return Container(
            color: cBlack,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 12, 15, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      namePlate(controller),
                      if (hasHeadline) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.headline!,
                          style: MyTextStyle.gilroyRegular(
                              color: cLightIcon, size: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (hasLocation) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                color: cLightText, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              user.location!,
                              style: MyTextStyle.gilroyRegular(
                                  color: cLightText, size: 13),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (user.ownedCompany != null) ...[
                  const SizedBox(height: 12),
                  _companyIdentityCard(user.ownedCompany!),
                ],
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      _statItem(
                        count: controller.posts.length.toString(),
                        label: LKeys.feed.tr,
                        onTap: () => controller.onChangeSegment(0),
                      ),
                      _statDivider(),
                      _statItem(
                        count: user.followers?.makeToString() ?? '0',
                        label: LKeys.followers.tr,
                        onTap: () => Get.to(() => FollowerFollowingScreen(
                            isForFollowing: false, user: user)),
                      ),
                      _statDivider(),
                      _statItem(
                        count: user.following?.makeToString() ?? '0',
                        label: LKeys.following.tr,
                        onTap: () => Get.to(() => FollowerFollowingScreen(
                            isForFollowing: true, user: user)),
                      ),
                    ],
                  ),
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cDarkBG,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: cLightText.withValues(alpha: 0.1)),
                    ),
                    child: DetectableText(
                      maxLines: null,
                      detectionRegExp:
                          detectionRegExp(atSign: false, url: true)!,
                      onTap: (p0) async {
                        controller.handleURL(url: p0);
                      },
                      lessStyle: MyTextStyle.gilroyMedium(color: cPrimary),
                      moreStyle: MyTextStyle.gilroyMedium(color: cPrimary),
                      trimCollapsedText: LKeys.showMore.tr,
                      trimExpandedText: '  ${LKeys.showLess.tr}',
                      text: user.bio ?? '',
                      basicStyle:
                          MyTextStyle.gilroyLight(size: 15, color: cLightIcon),
                      detectedStyle:
                          MyTextStyle.gilroyRegular(size: 15, color: cPrimary),
                    ),
                  ),
                ],
                if (user.getInterestsStringList().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: user.getInterestsStringList().map((e) {
                        return RoomCardInterestTagToShow(tag: e);
                      }).toList(),
                    ),
                  ),
                ],
                _achievementBadgesRow(
                    user, controller.posts.length, controller.reels.length),
                const SizedBox(height: 12),
                // Instagram 2024: Full-width action buttons row
                _actionButtonsRow(controller, user),
                const SizedBox(height: 14),
              ],
            ),
          );
        });
  }

  Widget _companyIdentityCard(UserOwnedCompany company) {
    final location = [company.city, company.country]
        .where((s) => (s ?? '').isNotEmpty)
        .join(', ');
    final hasWebsite = (company.website ?? '').isNotEmpty;
    final isMyCompany = company.ownerUserId == SessionManager.shared.getUserID();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cPrimary.withValues(alpha: 0.18),
            cHashtagColor.withValues(alpha: 0.10),
            cDarkBG,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cPrimary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: cPrimary.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: MyCachedImage(
                  imageUrl: company.logo ?? '',
                  width: 48,
                  height: 48,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            company.name ?? '',
                            style: MyTextStyle.gilroyBlack(
                                color: cWhite, size: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (company.isVerified == 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: cPrimary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Verifiee',
                              style: MyTextStyle.gilroySemiBold(
                                  color: cPrimary, size: 10),
                            ),
                          ),
                      ],
                    ),
                    if ((company.sector ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(company.sector!,
                          style: MyTextStyle.gilroySemiBold(
                              color: cPrimary, size: 12)),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _companyMiniChip(Icons.business_center_outlined,
                            '${company.publishedOffersCount ?? 0} offres'),
                        _companyMiniChip(Icons.people_alt_outlined,
                            '${company.followersCount ?? 0} abonnes'),
                        if (location.isNotEmpty)
                          _companyMiniChip(
                              Icons.location_on_outlined, location),
                        if (hasWebsite)
                          _companyMiniChip(
                              Icons.link_rounded, company.website!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _companyActionButton(
            label: 'Voir la page entreprise',
            icon: Icons.apartment_rounded,
            isPrimary: true,
            onTap: company.id == null
                ? null
                : () => Get.to(
                    () => CompanyPublicProfileScreen(companyId: company.id!)),
          ),
          if (isMyCompany) ...[
            const SizedBox(height: 8),
            _companyActionButton(
              label: LKeys.companyDashboard.tr,
              icon: Icons.dashboard_outlined,
              isPrimary: false,
              onTap: company.id == null
                  ? null
                  : () => Get.to(
                      () => CompanyDashboardScreen(companyId: company.id!)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _companyActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? cPrimary : cBlack.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isPrimary ? cPrimary : cPrimary.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isPrimary ? cBlack : cPrimary, size: 17),
            const SizedBox(width: 7),
            Text(label,
                style: MyTextStyle.gilroySemiBold(
                    color: isPrimary ? cBlack : cPrimary, size: 13)),
          ],
        ),
      ),
    );
  }

  Widget _companyMiniChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: cBlack.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cLightText.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cPrimary, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: MyTextStyle.gilroyMedium(color: cLightIcon, size: 11)),
        ],
      ),
    );
  }

  /// Instagram 2024-style full-width action buttons row.
  /// Own profile: [Edit Profile] [Share Profile]
  /// Other profile: [Message] [Video Call] [Follow/Unfollow]
  Widget _actionButtonsRow(ProfileController controller, User user) {
    final bool isMyProfile = user.id == SessionManager.shared.getUserID();
    final bool isBlocked = user.isBlockedByMe();
    if (isBlocked) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: isMyProfile
          ? Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    label: LKeys.editProfile.tr,
                    icon: Icons.edit_outlined,
                    isPrimary: true,
                    onTap: () {
                      Get.to(() => const SettingScreen())?.then((_) {
                        controller.updateMyProfile();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    label: LKeys.share.tr,
                    icon: Icons.share_outlined,
                    isPrimary: false,
                    onTap: controller.shareProfile,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    label: LKeys.sendMessage.tr,
                    icon: Icons.chat_bubble_outline_rounded,
                    isPrimary: false,
                    onTap: () => Get.to(() => ChattingView(user: user)),
                  ),
                ),
                const SizedBox(width: 8),
                if (user.followingStatus != null)
                  Expanded(
                    child: FollowButton(
                      user: user,
                      child: (isFollowing) {
                        return _actionBtn(
                          label:
                              isFollowing ? LKeys.unFollow.tr : LKeys.follow.tr,
                          icon: isFollowing
                              ? Icons.person_remove_outlined
                              : Icons.person_add_outlined,
                          isPrimary: !isFollowing,
                          onTap: null, // FollowButton handles tap
                        );
                      },
                      onChange: (u) {
                        controller.user?.followingStatus = u?.followingStatus;
                        controller.update();
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required bool isPrimary,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isPrimary ? cPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPrimary ? cPrimary : cLightText.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isPrimary ? cBlack : cWhite),
            const SizedBox(width: 6),
            Text(
              label,
              style: MyTextStyle.gilroySemiBold(
                color: isPrimary ? cBlack : cWhite,
                size: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(
      {required String count, required String label, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Text(count, style: MyTextStyle.gilroyBold(color: cWhite, size: 18)),
            const SizedBox(height: 2),
            Text(label,
                style: MyTextStyle.gilroyRegular(color: cLightText, size: 12)),
          ],
        ),
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 28,
      color: cLightText.withValues(alpha: 0.2),
    );
  }

  Widget _achievementBadgesRow(User user, int postCount, int reelCount) {
    final badges = AchievementBadges.computeBadges(user,
        postCount: postCount, reelCount: reelCount);
    final earned = badges.where((b) => b.isEarned).toList();
    if (earned.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          itemCount: earned.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final badge = earned[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badge.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: badge.color.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badge.icon, color: badge.color, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    badge.title(),
                    style: MyTextStyle.gilroySemiBold(
                        size: 12, color: badge.color),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget linkedInSections(ProfileController controller) {
    return GetBuilder(
      init: controller,
      tag: "${controller.userID}",
      builder: (controller) {
        final user = controller.user;
        if (user == null) return Container();

        final bool hasHeadline =
            user.headline != null && user.headline!.isNotEmpty;
        final bool hasAbout = user.about != null && user.about!.isNotEmpty;
        final bool hasExperience =
            user.experience != null && user.experience!.isNotEmpty;
        final bool hasEducation =
            user.education != null && user.education!.isNotEmpty;
        final bool hasSkills = user.skills != null && user.skills!.isNotEmpty;
        final bool hasLocation =
            user.location != null && user.location!.isNotEmpty;
        final bool hasWebsite =
            user.website != null && user.website!.isNotEmpty;
        final bool hasPronouns =
            user.pronouns != null && user.pronouns!.isNotEmpty;
        final bool hasAny = hasHeadline ||
            hasAbout ||
            hasExperience ||
            hasEducation ||
            hasSkills ||
            hasLocation ||
            hasWebsite ||
            hasPronouns;
        final bool isMyProfile = user.id == SessionManager.shared.getUserID();

        if (!hasAny && !isMyProfile) return Container();

        return Column(
          children: [
            if (hasHeadline || hasLocation || hasPronouns || hasWebsite)
              _profileInfoBar(user,
                  hasHeadline: hasHeadline,
                  hasLocation: hasLocation,
                  hasPronouns: hasPronouns,
                  hasWebsite: hasWebsite),
            if (hasAbout)
              _profileSection(
                icon: Icons.person_outline_rounded,
                title: LKeys.about.tr,
                child: Text(
                  user.about!,
                  style: MyTextStyle.gilroyRegular(color: cLightIcon, size: 15),
                ),
              ),
            if (hasExperience)
              _profileSection(
                icon: Icons.business_center_outlined,
                title: LKeys.experience.tr,
                child:
                    _buildJsonListItems(user.experience!, isExperience: true),
              ),
            if (hasEducation)
              _profileSection(
                icon: Icons.school_outlined,
                title: LKeys.education.tr,
                child:
                    _buildJsonListItems(user.education!, isExperience: false),
              ),
            if (hasSkills)
              _profileSection(
                icon: Icons.auto_awesome_outlined,
                title: LKeys.skills.tr,
                child: _buildSkillsChips(user.skills!),
              ),
          ],
        );
      },
    );
  }

  Widget _profileInfoBar(User user,
      {required bool hasHeadline,
      required bool hasLocation,
      required bool hasPronouns,
      required bool hasWebsite}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cDarkBG,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cLightText.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeadline) ...[
            Text(
              user.headline!,
              style: MyTextStyle.gilroySemiBold(color: cWhite, size: 16),
            ),
            if (hasLocation || hasPronouns || hasWebsite)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                    height: 1, color: cLightText.withValues(alpha: 0.1)),
              ),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (hasPronouns) _infoChip(Icons.badge_outlined, user.pronouns!),
              if (hasLocation)
                _infoChip(Icons.location_on_outlined, user.location!),
              if (hasWebsite)
                _infoChip(Icons.link_rounded, user.website!, isLink: true),
            ],
          ),
          if (hasWebsite) ...[
            const SizedBox(height: 12),
            _WebsitePreviewCard(url: user.website!),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, {bool isLink = false}) {
    final chipContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isLink
            ? cPrimary.withValues(alpha: 0.1)
            : cLightText.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLink
              ? cPrimary.withValues(alpha: 0.2)
              : cLightText.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isLink ? cPrimary : cLightText, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: MyTextStyle.gilroyMedium(
                color: isLink ? cPrimary : cLightIcon,
                size: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    if (isLink) {
      return GestureDetector(
        onTap: () async {
          var url = text;
          if (!url.startsWith('http://') && !url.startsWith('https://')) {
            url = 'https://$url';
          }
          final uri = Uri.tryParse(url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: chipContent,
      );
    }
    return chipContent;
  }

  Widget _profileSection(
      {required IconData icon, required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cDarkBG,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cLightText.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: cPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: MyTextStyle.gilroyBold(color: cWhite, size: 17)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: cLightText.withValues(alpha: 0.1)),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildJsonListItems(String jsonStr, {required bool isExperience}) {
    try {
      final List<dynamic> items =
          jsonStr.startsWith('[') ? _parseJson(jsonStr) : [];
      if (items.isEmpty) {
        return Text(jsonStr,
            style: MyTextStyle.gilroyRegular(color: cLightIcon, size: 15));
      }
      return Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          if (item is Map<String, dynamic>) {
            final title =
                item['title'] ?? item['position'] ?? item['degree'] ?? '';
            final subtitle = item['company'] ?? item['school'] ?? '';
            final period = item['period'] ?? '';
            final isLast = index == items.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: cPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: cPrimary.withValues(alpha: 0.15)),
                        ),
                        child: Icon(
                          isExperience
                              ? Icons.business_center_rounded
                              : Icons.school_rounded,
                          color: cPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title.toString(),
                                style: MyTextStyle.gilroySemiBold(
                                    color: cWhite, size: 15)),
                            if (subtitle.toString().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(subtitle.toString(),
                                  style: MyTextStyle.gilroyRegular(
                                      color: cLightIcon, size: 14)),
                            ],
                            if (period.toString().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined,
                                      color: cLightText, size: 12),
                                  const SizedBox(width: 4),
                                  Text(period.toString(),
                                      style: MyTextStyle.gilroyLight(
                                          color: cLightText, size: 13)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 54),
                    child: Divider(
                        height: 16, color: cLightText.withValues(alpha: 0.08)),
                  ),
              ],
            );
          }
          return Container();
        }),
      );
    } catch (_) {
      return Text(jsonStr,
          style: MyTextStyle.gilroyRegular(color: cLightIcon, size: 15));
    }
  }

  List<dynamic> _parseJson(String jsonStr) {
    try {
      if (jsonStr.isEmpty) return [];
      final decoded = jsonDecode(jsonStr);
      return decoded is List ? List<dynamic>.from(decoded) : [];
    } catch (_) {
      return [];
    }
  }

  Widget _buildSkillsChips(String skillsStr) {
    try {
      List<String> skillsList = [];
      if (skillsStr.startsWith('[')) {
        final parsed = jsonDecode(skillsStr);
        if (parsed is List) {
          skillsList = parsed.map((e) => e.toString()).toList();
        }
      } else {
        skillsList = skillsStr
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (skillsList.isEmpty) {
        return Text(skillsStr,
            style: MyTextStyle.gilroyRegular(color: cLightIcon, size: 15));
      }
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: skillsList
            .map((skill) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    skill,
                    style:
                        MyTextStyle.gilroySemiBold(color: cPrimary, size: 13),
                  ),
                ))
            .toList(),
      );
    } catch (_) {
      return Text(skillsStr,
          style: MyTextStyle.gilroyRegular(color: cLightIcon, size: 15));
    }
  }

  Widget postsView(ProfileController controller) {
    return FeedsView(
      controller: controller,
      id: '${controller.userID}_${controller.profileFeedID}',
    );
  }

  Widget followBtn(ProfileController controller) {
    return GetBuilder<ProfileController>(
      init: controller,
      tag: "${controller.userID}",
      builder: (controller) {
        if (controller.user?.id == SessionManager.shared.getUserID())
          return Container();
        if (controller.user?.followingStatus == null) return Container();
        return FollowButton(
          user: controller.user,
          child: (isFollowing) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
              decoration: BoxDecoration(
                color: isFollowing ? Colors.transparent : cPrimary,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isFollowing
                      ? cLightText.withValues(alpha: 0.4)
                      : cPrimary,
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    isFollowing ? LKeys.unFollow.tr : LKeys.follow.tr,
                    style: MyTextStyle.gilroyBold(
                      color: isFollowing ? cLightText : cBlack,
                      size: 14,
                    ),
                  ),
                  Opacity(
                    opacity: 0,
                    child: Text(
                      LKeys.unFollow.tr,
                      style: MyTextStyle.gilroyBold(size: 14),
                    ),
                  ),
                ],
              ),
            );
          },
          onChange: (user) {
            controller.user?.followingStatus = user?.followingStatus;
            controller.update();
          },
        );
      },
    );
  }

  Widget profileMenu(ProfileController controller) {
    return Menu(items: [
      PopupMenuItem(
        onTap: controller.shareProfile,
        textStyle: MyTextStyle.gilroyMedium(),
        child: Text(LKeys.share.tr),
      ),
      PopupMenuItem(
        onTap: () {
          Future.delayed(const Duration(milliseconds: 1), () {
            Get.bottomSheet(ReportSheet(user: controller.user),
                isScrollControlled: true);
          });
        },
        textStyle: MyTextStyle.gilroyMedium(),
        child: Text(LKeys.report.tr),
      ),
      PopupMenuItem(
        textStyle: MyTextStyle.gilroyMedium(),
        child: Text(controller.user?.isBlockedByMe() ?? false
            ? LKeys.unBlock.tr
            : LKeys.block.tr),
        onTap: controller.blockUnblock,
      ),
      if (SessionManager.shared.getUserID() != controller.user?.id &&
          SessionManager.shared.getUser()?.isModerator == 1 &&
          controller.user?.isBlock == 0)
        PopupMenuItem(
          textStyle: MyTextStyle.gilroyMedium(),
          child: Text(LKeys.blockGlobally.tr),
          onTap: controller.blockByModerator,
        )
    ]);
  }

  Widget segmentController(ProfileController controller) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: cDarkBG,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cLightText.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            _buildTab(LKeys.feed, Icons.grid_view_rounded, 0, controller),
            _buildTab(
                LKeys.reels, Icons.play_circle_outline_rounded, 1, controller),
            _buildTab(LKeys.about, Icons.person_outline_rounded, 2, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
      String text, IconData icon, int index, ProfileController controller) {
    final isSelected = controller.selectedPage.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.onChangeSegment(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? cPrimary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? cPrimary : cLightText, size: 20),
              const SizedBox(height: 3),
              Text(
                text.tr.toUpperCase(),
                style: MyTextStyle.gilroySemiBold(
                  size: 11,
                  color: isSelected ? cPrimary : cLightText,
                ).copyWith(letterSpacing: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget aboutTabView(ProfileController controller) {
    return GetBuilder(
      init: controller,
      tag: "${controller.userID}",
      builder: (controller) {
        final user = controller.user;
        if (user == null) return Container();
        final isMyProfile = user.id == SessionManager.shared.getUserID();

        final bool hasHeadline =
            user.headline != null && user.headline!.isNotEmpty;
        final bool hasAbout = user.about != null && user.about!.isNotEmpty;
        final bool hasExperience =
            user.experience != null && user.experience!.isNotEmpty;
        final bool hasEducation =
            user.education != null && user.education!.isNotEmpty;
        final bool hasSkills = user.skills != null && user.skills!.isNotEmpty;
        final bool hasLocation =
            user.location != null && user.location!.isNotEmpty;
        final bool hasWebsite =
            user.website != null && user.website!.isNotEmpty;
        final bool hasPronouns =
            user.pronouns != null && user.pronouns!.isNotEmpty;
        final bool hasAny = hasHeadline ||
            hasAbout ||
            hasExperience ||
            hasEducation ||
            hasSkills ||
            hasLocation ||
            hasWebsite ||
            hasPronouns;

        return Column(
          children: [
            if (isMyProfile)
              GestureDetector(
                onTap: () {
                  Get.to(() => const SettingScreen())
                      ?.then((_) => controller.updateMyProfile());
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cPrimary.withValues(alpha: 0.15),
                        cPrimary.withValues(alpha: 0.05)
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cPrimary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: cPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.edit_outlined,
                            color: cPrimary, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        LKeys.editProfile.tr,
                        style: MyTextStyle.gilroySemiBold(
                            color: cPrimary, size: 15),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          color: cPrimary.withValues(alpha: 0.6), size: 20),
                    ],
                  ),
                ),
              ),
            if (!hasAny && !isMyProfile)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: cLightText, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      LKeys.noProfileInfo.tr,
                      style: MyTextStyle.gilroyRegular(
                          color: cLightText, size: 15),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              linkedInSections(controller),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _WebsitePreviewCard extends StatefulWidget {
  final String url;
  const _WebsitePreviewCard({required this.url});

  @override
  State<_WebsitePreviewCard> createState() => _WebsitePreviewCardState();
}

class _WebsitePreviewCardState extends State<_WebsitePreviewCard> {
  UrlMetadata? _metadata;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      var url = widget.url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      final meta = await extract(url).timeout(const Duration(seconds: 8));
      if (mounted)
        setState(() {
          _metadata = meta;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: cDarkBG,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cLightText.withValues(alpha: 0.12)),
        ),
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: cPrimary))),
      );
    }
    if (_metadata == null) return const SizedBox.shrink();

    final hasImage = (_metadata!.image ?? '').isNotEmpty;
    final title = _metadata!.title ?? '';
    final description = _metadata!.description ?? '';
    if (title.isEmpty && description.isEmpty && !hasImage)
      return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        var url = widget.url;
        if (!url.startsWith('http://') && !url.startsWith('https://'))
          url = 'https://$url';
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: cDarkBG,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cLightText.withValues(alpha: 0.15)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              Image.network(
                _metadata!.image!,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(title,
                        style:
                            MyTextStyle.gilroySemiBold(color: cWhite, size: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(description,
                        style: MyTextStyle.gilroyRegular(
                            color: cLightIcon, size: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 4),
                  Text(widget.url,
                      style:
                          MyTextStyle.gilroyRegular(color: cPrimary, size: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePostsSliver extends StatelessWidget {
  final ProfileController controller;
  final void Function(num id) onDeletePost;
  final VoidCallback onRefresh;

  const _ProfilePostsSliver({
    required this.controller,
    required this.onDeletePost,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      init: controller,
      tag: '${controller.userID}_${controller.profileFeedID}',
      builder: (ctrl) {
        if (ctrl.isLoading.value && ctrl.posts.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: LoaderWidget(),
            ),
          );
        }
        if (ctrl.posts.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: NoDataView(title: LKeys.noPosts.tr),
          );
        }
        return SliverList.builder(
          itemCount: ctrl.posts.length,
          itemBuilder: (context, index) => RepaintBoundary(
            child: PostCard(
              post: ctrl.posts[index],
              onDeletePost: onDeletePost,
              refreshView: onRefresh,
            ),
          ),
        );
      },
    );
  }
}
