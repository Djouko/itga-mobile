import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/reel_model_extension.dart';
import 'package:untitled/screens/company/company_public_profile_screen.dart';
import 'package:untitled/screens/extra_views/back_button.dart';
import 'package:untitled/screens/follow_button/follow_button.dart';
import 'package:untitled/screens/profile_screen/profile_screen.dart';
import 'package:untitled/screens/reels_screen/reel/reel_page_controller.dart';
import 'package:untitled/screens/tag_screen/tag_controller.dart';
import 'package:untitled/screens/tag_screen/tag_screen.dart';
import 'package:untitled/utilities/const.dart';

class UserInfoAndDescription extends StatelessWidget {
  final ReelController controller;

  const UserInfoAndDescription({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          UserInfoHeader(controller: controller),
          const SizedBox(height: 2),
          UserStats(controller: controller),
          const SizedBox(height: 10),
          ReelDescriptionSection(
            controller: controller,
          ),
        ],
      ),
    );
  }
}

class UserInfoHeader extends StatelessWidget {
  const UserInfoHeader({required this.controller, super.key});

  final ReelController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: InkWell(
            onTap: controller.onProfileTap,
            child: Obx(
              () {
                return Text(
                  controller.reel.value?.company?.name ??
                      controller.reel.value?.user?.username ??
                      'unknown',
                  style: MyTextStyle.gilroyBold(color: cWhite, size: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: VerifyIcon(
            user: controller.reel.value?.user,
          ),
        ),
        if (controller.reel.value?.company != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: ShapeDecoration(
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(cornerRadius: 30),
                side: BorderSide(color: cCyan.withValues(alpha: 0.35)),
              ),
              color: cCyan.withValues(alpha: 0.14),
            ),
            child: Text(
              'Entreprise',
              style: MyTextStyle.gilroySemiBold(size: 11, color: cCyan),
            ),
          ),
        if (controller.reel.value?.company == null &&
            controller.reel.value?.isMyReel == false)
          FollowButton(
            user: controller.reel.value?.user,
            child: (isFollowing) {
              return Opacity(
                opacity: !isFollowing ? 1 : 0,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.only(
                      top: 6, left: 10, right: 10, bottom: 4),
                  decoration: ShapeDecoration(
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(cornerRadius: 30),
                      side: BorderSide(color: cWhite.withValues(alpha: 0.3)),
                      borderAlign: BorderAlign.inside,
                    ),
                    color: cWhite.withValues(alpha: 0.05),
                  ),
                  child: Text(
                    isFollowing ? LKeys.unFollow.tr : LKeys.follow.tr,
                    style: MyTextStyle.gilroyRegular(size: 13, color: cWhite),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class UserStats extends StatelessWidget {
  const UserStats({super.key, required this.controller});

  final ReelController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          DateFormat('dd MMM yyyy')
              .format(controller.reel.value?.createdAt ?? DateTime.now()),
          style: MyTextStyle.outfitLight(
              color: cWhite.withValues(alpha: 0.8), size: 11),
        ),
        Container(
          height: 3,
          width: 3,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: cWhite.withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
        ),
        Text(
          '${controller.reel.value?.viewsCount ?? '1'} ${LKeys.views.tr}',
          style: MyTextStyle.outfitLight(
            color: cWhite.withValues(alpha: 0.8),
            size: 11,
          ),
        ),
      ],
    );
  }
}

class ReelDescriptionSection extends StatelessWidget {
  const ReelDescriptionSection({super.key, required this.controller});

  final ReelController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.reel.value?.description == null ||
        (controller.reel.value?.description ?? '').isEmpty) {
      return const SizedBox();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: ReadMoreText(
          controller.reel.value?.description ?? '',
          style: MyTextStyle.outfitLight(
                  color: cWhite.withValues(alpha: 0.8), size: 15)
              .copyWith(height: 1.4),
          annotations: [
            Annotation(
              regExp: RegExp(r'#([a-zA-Z0-9_]+)'),
              spanBuilder: ({required String text, TextStyle? textStyle}) =>
                  TextSpan(
                      text: text,
                      style: textStyle?.copyWith(
                        color: cPrimary,
                        fontFamily: MyTextStyle.gilroyMedium().fontFamily,
                        fontSize: 15,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          if (text.startsWith('#')) {
                            Get.delete<TagController>().then((value) {
                              Get.to(
                                  () => TagScreen(tag: text, isForReel: true),
                                  preventDuplicates: false);
                            });
                          }
                        }),
            ),
            Annotation(
              regExp: RegExp(r'@([a-zA-Z0-9_]+)'),
              spanBuilder: ({required String text, TextStyle? textStyle}) =>
                  TextSpan(
                      text: text,
                      style: textStyle?.copyWith(
                        color: cPrimary,
                        fontFamily: MyTextStyle.gilroyMedium().fontFamily,
                        fontSize: 15,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          if (text.startsWith('@')) {
                            _openMentionProfile(text);
                          }
                        }),
            ),
          ],
          trimMode: TrimMode.Line,
          trimLines: 3,
          trimCollapsedText: ' ${LKeys.showMore.tr}',
          trimExpandedText: '   ${LKeys.showLess.tr}',
          moreStyle: MyTextStyle.outfitLight(
              color: cWhite.withValues(alpha: 0.8), size: 15),
          lessStyle: MyTextStyle.outfitLight(
              color: cWhite.withValues(alpha: 0.8), size: 15),
        ),
      ),
    );
  }

  void _openMentionProfile(String rawUsername) {
    final username = rawUsername.replaceFirst(RegExp(r'^@'), '').trim();
    if (username.isEmpty) return;

    final companyMatch = RegExp(r'^company-(\d+)$', caseSensitive: false)
        .firstMatch(username);
    if (companyMatch != null) {
      final companyId = int.tryParse(companyMatch.group(1) ?? '');
      if (companyId != null) {
        Get.to(() => CompanyPublicProfileScreen(companyId: companyId),
            preventDuplicates: false);
        return;
      }
    }

    UserService.shared.searchProfile(username, 0, (users) {
      if (users.isEmpty) return;
      final lower = username.toLowerCase();
      final target = users.firstWhereOrNull(
            (user) => (user.username ?? '').toLowerCase() == lower,
          ) ??
          users.first;

      if (target.profileType == 'company' && target.ownedCompany?.id != null) {
        Get.to(
            () => CompanyPublicProfileScreen(
                companyId: target.ownedCompany!.id!),
            preventDuplicates: false);
        return;
      }

      Get.to(() => ProfileScreen(userId: target.id ?? 0),
          preventDuplicates: false);
    });
  }
}
