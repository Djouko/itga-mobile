import 'dart:convert';

import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:like_button/like_button.dart';
import 'package:readmore/readmore.dart';
import 'package:untitled/common/extensions/date_time_extension.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/extensions/int_extension.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/buttons/play_button.dart';
import 'package:untitled/common/widgets/menu.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/post_model_extension.dart';
import 'package:untitled/models/posts_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/add_post_screen/add_post_controller.dart';
import 'package:untitled/screens/add_post_screen/add_post_screen.dart';
import 'package:untitled/screens/add_post_screen/record_audio/record_audio_screen.dart';
import 'package:untitled/screens/company/company_public_profile_screen.dart';
import 'package:untitled/screens/extra_views/back_button.dart';
import 'package:untitled/screens/post/comment/comment_screen.dart';
import 'package:untitled/screens/post/post_controller.dart';
import 'package:untitled/screens/post/repost_sheet.dart';
import 'package:untitled/screens/profile_screen/profile_screen.dart';
import 'package:untitled/screens/tag_screen/tag_screen.dart';
import 'package:untitled/utilities/const.dart';
import 'package:zoom_pinch_overlay/zoom_pinch_overlay.dart';

import '../tag_screen/tag_controller.dart';
import 'double_click_like.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final Function(int postID) onDeletePost;
  final Function() refreshView;

  const PostCard(
      {super.key,
      required this.post,
      required this.onDeletePost,
      required this.refreshView});

  @override
  Widget build(BuildContext context) {
    final PostController controller =
        PostController(post, onDeletePost, refreshView);
    final Post contentPost = post.displayPost;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        // Repost header — Twitter style: "🔁 Username reposted"
        if (post.isRepost)
          Padding(
            padding: const EdgeInsets.only(left: 54, right: 12, bottom: 4),
            child: GestureDetector(
              onTap: () {
                Get.to(() => ProfileScreen(userId: post.userId ?? 0),
                    preventDuplicates: false);
              },
              child: Row(
                children: [
                  Icon(Icons.repeat_rounded,
                      size: 15, color: cLightText.withValues(alpha: 0.7)),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: post.user?.fullName ?? '',
                            style: MyTextStyle.gilroySemiBold(
                                color: cLightText, size: 12),
                          ),
                          TextSpan(
                            text: ' ${LKeys.repostedBy.tr}',
                            style: MyTextStyle.gilroyRegular(
                                color: cLightText.withValues(alpha: 0.7),
                                size: 12),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Reposter's comment (quote repost)
        if (post.isRepost && post.desc != null && post.desc!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            child: Text(
              post.desc!,
              style: MyTextStyle.gilroyRegular(color: cMainText, size: 15),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        // Original post content — wrapped in a subtle card when it's a quote repost
        Container(
          margin: post.isRepost && post.desc != null && post.desc!.isNotEmpty
              ? const EdgeInsets.symmetric(horizontal: 12)
              : EdgeInsets.zero,
          decoration: post.isRepost &&
                  post.desc != null &&
                  post.desc!.isNotEmpty
              ? BoxDecoration(
                  border: Border.all(color: cLightText.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(14),
                )
              : null,
          clipBehavior:
              post.isRepost && post.desc != null && post.desc!.isNotEmpty
                  ? Clip.antiAlias
                  : Clip.none,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: PostTopBar(
                    controller: controller, displayPost: contentPost),
              ),
              const SizedBox(height: 7),
              if (!post.isRepost &&
                  contentPost.desc != "" &&
                  contentPost.desc != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: PostDescriptionView(controller: controller),
                )
              else if (post.isRepost &&
                  contentPost.desc != "" &&
                  contentPost.desc != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: PostDescriptionView(
                      controller: controller, useDisplayPost: true),
                )
              else
                const SizedBox(height: 5),
              if (contentPost.content?.isNotEmpty == true)
                (contentPost.type == PostType.audio)
                    ? contentView(controller, useDisplayPost: post.isRepost)
                    : (contentPost.type == PostType.image ||
                            contentPost.type == PostType.video)
                        ? DoubleClickLikeAnimator(
                            child: contentView(controller,
                                useDisplayPost: post.isRepost),
                            onAnimation: () {
                              if (controller.post.isLike == 0) {
                                controller.likeFromDoubleTap();
                              }
                            },
                            onTap: () {
                              controller.openVideoSheet();
                            },
                          )
                        : Container()
              else if (contentPost.linkPreview != null)
                UrlMetaDataCard(metadata: contentPost.linkPreview!)
              else
                const Column(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: PostBottomBar(controller: controller),
        ),
        Divider(
          thickness: 0.5,
          height: 0.5,
          color: cLightText.withValues(alpha: 0.12),
        ),
      ],
    );
  }

  Widget contentView(PostController controller, {bool useDisplayPost = false}) {
    final targetPost =
        useDisplayPost ? controller.post.displayPost : controller.post;
    switch (targetPost.type) {
      case PostType.image:
        return PostImagesPageView(
            controller: controller, useDisplayPost: useDisplayPost);
      case PostType.video:
        return PostVideoElement(
            controller: controller, useDisplayPost: useDisplayPost);
      case PostType.audio:
        return PostAudioElement(
            controller: controller, useDisplayPost: useDisplayPost);
      case PostType.text:
        return Container();
    }
  }
}

class PostDescriptionView extends StatelessWidget {
  final PostController controller;
  final bool isForVideo;
  final bool useDisplayPost;

  const PostDescriptionView(
      {Key? key,
      required this.controller,
      this.isForVideo = false,
      this.useDisplayPost = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final targetPost =
        useDisplayPost ? controller.post.displayPost : controller.post;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: ReadMoreText(
        targetPost.desc ?? '',
        style: MyTextStyle.outfitLight(
            size: 16, color: isForVideo ? cLightIcon : cMainText),
        annotations: [
          Annotation(
            regExp: RegExp(r'#([a-zA-Z0-9_]+)'),
            spanBuilder: ({required String text, TextStyle? textStyle}) =>
                TextSpan(
                    text: text,
                    style: textStyle?.copyWith(
                      color: cPrimary,
                      fontFamily: MyTextStyle.outfitMedium(
                              size: 16, color: cHashtagColor)
                          .fontFamily,
                      fontSize: 16,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        if (text.startsWith('#')) {
                          Get.delete<TagController>().then((value) {
                            Get.to(
                              () => TagScreen(
                                tag: text,
                                isForReel: false,
                              ),
                              preventDuplicates: false,
                            );
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
                      fontFamily: MyTextStyle.outfitMedium(
                              size: 16, color: cHashtagColor)
                          .fontFamily,
                      fontSize: 16,
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
        trimLines: 5,
        trimCollapsedText: ' ${LKeys.showMore.tr}',
        trimExpandedText: '   ${LKeys.showLess.tr}',
        moreStyle: MyTextStyle.outfitRegular(
            color: isForVideo ? cLightIcon : cMainText, size: 16),
        lessStyle: MyTextStyle.outfitRegular(
            color: isForVideo ? cLightIcon : cMainText, size: 16),
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

class PostBottomBar extends StatelessWidget {
  final PostController controller;
  final bool isForVideo;

  const PostBottomBar(
      {Key? key, required this.controller, this.isForVideo = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconColor = isForVideo ? cWhite : cLightText;
    final countColor = isForVideo ? cWhite : cLightText;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _actionButton(
            child: GetBuilder(
                init: controller,
                tag: "${controller.post.id}",
                id: 'comment',
                builder: (context) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Get.bottomSheet(
                        CommentScreen(postController: controller),
                        isScrollControlled: true,
                        ignoreSafeArea: false,
                      ).then((value) {
                        controller.update(['comment']);
                        controller.update();
                        controller.refreshView();
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(MyImages.comment,
                            width: 19, height: 19, color: iconColor),
                        const SizedBox(width: 5),
                        Text(
                          (controller.post.commentsCount).makeToString(),
                          style: MyTextStyle.gilroyRegular(
                              size: 13, color: countColor),
                        ),
                      ],
                    ),
                  );
                }),
          ),
          _actionButton(
            child: Obx(
              () => LikeButton(
                onTap: (isLiked) async {
                  this.controller.toggleFav();
                  return true;
                },
                countPostion: CountPostion.right,
                likeCount: this.controller.post.likesCount ?? 0,
                size: 19,
                isLiked: controller.isLiked.value,
                likeCountPadding: const EdgeInsets.symmetric(horizontal: 4),
                countBuilder: (likeCount, isLiked, text) {
                  return Text(text,
                      style: MyTextStyle.gilroyRegular(
                          size: 13, color: countColor));
                },
                likeBuilder: (isLiked) {
                  return Image.asset(
                    this.controller.isLiked.value
                        ? MyImages.heartFill
                        : MyImages.heart,
                    width: 19,
                    height: 19,
                    color: this.controller.isLiked.value ? cRed : iconColor,
                  );
                },
              ),
            ),
          ),
          _actionButton(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Get.bottomSheet(
                  RepostSheet(controller: controller),
                  isScrollControlled: true,
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.repeat_rounded, size: 19, color: iconColor),
                  if (controller.post.repostCount > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      controller.post.repostCount.makeToString(),
                      style: MyTextStyle.gilroyRegular(
                          size: 13, color: countColor),
                    ),
                  ],
                ],
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: controller.onSaved,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Image.asset(
                controller.post.isSaved
                    ? MyImages.bookmarkFill
                    : MyImages.bookmark,
                width: 19,
                height: 19,
                color: controller.post.isSaved ? cPrimary : iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required Widget child}) {
    return Expanded(
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
  }
}

class PostTopBar extends StatelessWidget {
  final PostController controller;
  final bool isForVideo;
  final Post? displayPost;

  const PostTopBar(
      {Key? key,
      required this.controller,
      this.isForVideo = false,
      this.displayPost})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Post targetPost = displayPost ?? controller.post;
    final User? targetUser = targetPost.user;
    final company = targetPost.company;
    final bool isCompanyPost = company?.id != null;
    final actorName = isCompanyPost ? company?.name : targetUser?.fullName;
    final actorImage = isCompanyPost ? company?.logo : targetUser?.profile;
    return GestureDetector(
      onTap: () {
        if (isCompanyPost) {
          Get.to(() => CompanyPublicProfileScreen(companyId: company!.id!),
              preventDuplicates: false);
        } else {
          Get.to(() => ProfileScreen(userId: targetPost.userId ?? 0),
              preventDuplicates: false);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyCachedProfileImage(
            imageUrl: actorImage,
            width: 44,
            height: 44,
            fullName: actorName,
            cornerRadius: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              actorName ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MyTextStyle.gilroyBold(
                                  color: isForVideo ? cWhite : cBlack,
                                  size: 16),
                            ),
                          ),
                          if (isCompanyPost)
                            Container(
                              margin: const EdgeInsets.only(left: 5),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: cPrimary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: cPrimary.withValues(alpha: 0.20)),
                              ),
                              child: Text(
                                'Entreprise',
                                style: MyTextStyle.gilroySemiBold(
                                    color: cPrimary, size: 10),
                              ),
                            )
                          else
                            VerifyIcon(user: targetUser),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              isCompanyPost
                                  ? (company?.sector ?? 'ITGA')
                                  : "@${targetUser?.username ?? ""}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MyTextStyle.gilroyRegular(
                                  size: 14,
                                  color: isForVideo ? cLightIcon : cLightText),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      controller.post.date.timeAgoShort(),
                      style: MyTextStyle.gilroyRegular(
                          size: 13,
                          color: isForVideo ? cLightIcon : cLightText),
                    ),
                    const SizedBox(width: 4),
                    PostMenuButton(
                      controller: controller,
                      isForVideo: isForVideo,
                    ),
                    if (isForVideo) ...[
                      const SizedBox(width: 10),
                      const XMarkButton(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostMenuButton extends StatelessWidget {
  final PostController controller;
  final bool isForVideo;

  const PostMenuButton(
      {Key? key, required this.controller, required this.isForVideo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Menu(
      isFromPost: true,
      items: [
        if (controller.isCurrentActorOwner)
          PopupMenuItem(
            textStyle: MyTextStyle.gilroyRegular(),
            onTap: controller.showEditPost,
            child: Text(LKeys.editPost.tr),
          ),
        if (controller.isCurrentActorOwner)
          PopupMenuItem(
            textStyle: MyTextStyle.gilroyRegular(),
            onTap: controller.showWhoLikedThePost,
            child: Text(LKeys.seeWhoLikedPost.tr),
          ),
        if (controller.post.repostCount > 0)
          PopupMenuItem(
            textStyle: MyTextStyle.gilroyRegular(),
            onTap: controller.showWhoRepostedThePost,
            child: Text(LKeys.seeWhoReposted.tr),
          ),
        PopupMenuItem(
          textStyle: MyTextStyle.gilroyRegular(),
          onTap: controller.deleteOrReport,
          child: Text(controller.isCurrentActorOwner
              ? LKeys.delete.tr
              : LKeys.report.tr),
        ),
        if (SessionManager.shared.getUserID() != controller.post.userId &&
            SessionManager.shared.getUser()?.isModerator == 1)
          PopupMenuItem(
            textStyle: MyTextStyle.gilroyRegular(),
            onTap: controller.deletePosyByModerator,
            child: Text(LKeys.delete.tr),
          ),
        PopupMenuItem(
          textStyle: MyTextStyle.gilroyRegular(),
          onTap: controller.sharePost,
          child: Text(LKeys.share.tr),
        ),
      ],
      isForVideo: isForVideo,
    );
  }
}

class PostImagesPageView extends StatelessWidget {
  final PostController controller;
  final bool useDisplayPost;

  const PostImagesPageView(
      {Key? key, required this.controller, this.useDisplayPost = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final targetPost =
        useDisplayPost ? controller.post.displayPost : controller.post;
    if (targetPost.content?.isNotEmpty == true) {
      var height = targetPost.content?.length == 1 ? null : Get.width;
      return GetBuilder<PostController>(
          init: controller,
          tag: "${controller.post.id}",
          id: "pageView",
          builder: (control) {
            var contentCount = targetPost.content?.length ?? 0;
            return contentCount == 1
                ? image(
                    imageUrl: targetPost.content?.first.content, height: height)
                : SizedBox(
                    height: Get.width,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        PageView.builder(
                          onPageChanged: (value) => control.onPageChange(value),
                          itemCount: targetPost.content?.length,
                          itemBuilder: (context, index) {
                            return image(
                                imageUrl:
                                    (targetPost.content?[index].content ?? ''),
                                height: height);
                          },
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(contentCount, (index) {
                              return contentCount > 1
                                  ? Container(
                                      margin: const EdgeInsets.only(right: 3),
                                      height: 2.7,
                                      width: contentCount > 8
                                          ? (Get.width - 120) / contentCount
                                          : 30,
                                      decoration: ShapeDecoration(
                                        color: control.selectedImageIndex ==
                                                index
                                            ? cWhite
                                            : cWhite.withValues(alpha: 0.30),
                                        shape: const SmoothRectangleBorder(
                                            borderRadius:
                                                SmoothBorderRadius.all(
                                                    SmoothRadius(
                                                        cornerRadius: 10,
                                                        cornerSmoothing:
                                                            cornerSmoothing))),
                                      ),
                                    )
                                  : Container();
                            }),
                          ),
                        ),
                      ],
                    ),
                  );
          });
    } else {
      return Container();
    }
  }

  Widget image({String? imageUrl, double? height}) {
    return ZoomOverlay(
      modalBarrierColor: Colors.black.withValues(alpha: 0.5),
      minScale: 1,
      maxScale: 3.0,
      animationCurve: Curves.fastOutSlowIn,
      animationDuration: const Duration(milliseconds: 300),
      twoTouchOnly: true,
      child: ClipRRect(
        child: Container(
          constraints: BoxConstraints(maxHeight: Get.height / 1.5),
          child: FadeInImage(
              placeholder: AssetImage(
                MyImages.placeHolderImage,
              ),
              image: NetworkImage(imageUrl?.addBaseURL() ?? ''),
              imageErrorBuilder: (context, error, stackTrace) {
                return Image.asset(MyImages.placeHolderImage,
                    height: Get.width);
              },
              width: Get.width,
              repeat: ImageRepeat.noRepeat,
              height: height,
              fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class PostVideoElement extends StatelessWidget {
  final PostController controller;
  final bool useDisplayPost;

  const PostVideoElement(
      {Key? key, required this.controller, this.useDisplayPost = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final targetPost =
        useDisplayPost ? controller.post.displayPost : controller.post;
    if (targetPost.content?.isEmpty == true) {
      return Container();
    }
    return GestureDetector(
      onTap: () {
        controller.openVideoSheet();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: Get.width,
            width: double.infinity,
            child: MyCachedImage(
              imageUrl: (targetPost.content?.first.thumbnail ?? ""),
            ),
          ),
          PlayButton(),
        ],
      ),
    );
  }
}

class PostAudioElement extends StatelessWidget {
  final PostController controller;
  final bool useDisplayPost;

  const PostAudioElement(
      {Key? key, required this.controller, this.useDisplayPost = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final targetPost =
        useDisplayPost ? controller.post.displayPost : controller.post;
    List<double> waves = (jsonDecode(targetPost.content?.first.audioWaves ?? "")
            as List<dynamic>)
        .map((e) => e as double)
        .toList();
    if (targetPost.content?.isEmpty == true) {
      return Container();
    }
    return GestureDetector(
        onTap: () {
          controller.openAudioSheet();
        },
        child: WaveCard(waves: waves));
  }
}
