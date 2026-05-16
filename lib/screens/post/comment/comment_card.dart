import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:readmore/readmore.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/extensions/date_time_extension.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/extensions/int_extension.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/comments_model.dart';
import 'package:untitled/screens/company/company_public_profile_screen.dart';
import 'package:untitled/screens/extra_views/back_button.dart';
import 'package:untitled/screens/profile_screen/profile_screen.dart';
import 'package:untitled/screens/tag_screen/tag_controller.dart';
import 'package:untitled/screens/tag_screen/tag_screen.dart';
import 'package:untitled/utilities/const.dart';

class CommentCard extends StatelessWidget {
  final Comment comment;
  final Function() onDeleteTap;
  final Function() onDeleteModeratorTap;
  final Function() onLikeDisLike;
  final Function()? onReplyTap;
  final Function()? onEditTap;
  final bool isReply;

  const CommentCard(
      {Key? key,
      required this.comment,
      required this.onDeleteTap,
      required this.onLikeDisLike,
      required this.onDeleteModeratorTap,
      this.onReplyTap,
      this.onEditTap,
      this.isReply = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMyComment = SessionManager.shared.getUserID() == comment.userId;
    final isModerator = SessionManager.shared.getUser()?.isModerator == 1;
    final canAct = isMyComment || (isModerator && !isMyComment);

    return GestureDetector(
      onLongPress:
          canAct ? () => _showActionsSheet(context, isMyComment) : null,
      child: canAct
          ? Slidable(
              key: Key(comment.id.toString()),
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                children: [
                  if (isMyComment && onEditTap != null)
                    SlidableAction(
                      flex: 1,
                      onPressed: (context) => onEditTap!(),
                      backgroundColor: cPrimary,
                      foregroundColor: Colors.white,
                      icon: CupertinoIcons.pencil,
                      autoClose: true,
                    ),
                  SlidableAction(
                    flex: 1,
                    onPressed: (context) {
                      if (isMyComment) {
                        onDeleteTap();
                      } else {
                        onDeleteModeratorTap();
                      }
                    },
                    backgroundColor: cRed,
                    foregroundColor: Colors.white,
                    icon: CupertinoIcons.trash,
                    autoClose: true,
                  ),
                ],
              ),
              child: view())
          : view(),
    );
  }

  /// Instagram/WhatsApp style: long-press shows action sheet
  void _showActionsSheet(BuildContext context, bool isMyComment) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: cAudioSpaceLightBG,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 12),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
              if (isMyComment && onEditTap != null)
                ListTile(
                  leading: const Icon(CupertinoIcons.pencil, color: cWhite),
                  title: Text(LKeys.edit.tr,
                      style: MyTextStyle.gilroyMedium(color: cWhite, size: 16)),
                  onTap: () {
                    Get.back();
                    Future.delayed(
                        const Duration(milliseconds: 300), () => onEditTap!());
                  },
                ),
              ListTile(
                leading: const Icon(CupertinoIcons.doc_on_doc, color: cWhite),
                title: Text(LKeys.copy.tr,
                    style: MyTextStyle.gilroyMedium(color: cWhite, size: 16)),
                onTap: () {
                  Get.back();
                  if (comment.desc != null) {
                    Clipboard.setData(ClipboardData(text: comment.desc!));
                  }
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.trash, color: cRed),
                title: Text(LKeys.delete.tr,
                    style: MyTextStyle.gilroyMedium(color: cRed, size: 16)),
                onTap: () {
                  Get.back();
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (isMyComment) {
                      onDeleteTap();
                    } else {
                      onDeleteModeratorTap();
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget view() {
    final double avatarSize = isReply ? 28 : 36;
    final company = comment.company;
    final bool isCompanyComment = company?.id != null;
    final actorName = isCompanyComment ? company?.name : comment.user?.fullName;
    final actorImage = isCompanyComment ? company?.logo : comment.user?.profile;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: goToProfile,
            child: MyCachedProfileImage(
              imageUrl: actorImage,
              height: avatarSize,
              width: avatarSize,
              fullName: actorName,
              cornerRadius: avatarSize / 2,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: goToProfile,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                actorName ?? '',
                                style: MyTextStyle.gilroyBold(
                                    color: cWhite, size: isReply ? 14 : 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCompanyComment)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cPrimary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('Entreprise',
                                    style: MyTextStyle.gilroySemiBold(
                                        color: cPrimary, size: 9)),
                              )
                            else
                              VerifyIcon(user: comment.user),
                            const SizedBox(width: 6),
                            Text(
                              comment.date.timeAgoShort(),
                              style: MyTextStyle.gilroyRegular(
                                  color: cLightText, size: 12),
                            ),
                            if (comment.isEdited)
                              Text(
                                ' · edited',
                                style: MyTextStyle.gilroyRegular(
                                    color: cLightText, size: 11),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onLikeDisLike,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          children: [
                            Image.asset(
                              comment.isLike == 1
                                  ? MyImages.heartFill
                                  : MyImages.heart,
                              width: 16,
                              height: 16,
                              color: comment.isLike == 1 ? cRed : cLightText,
                            ),
                            if ((comment.commentLikeCount ?? 0) > 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${comment.commentLikeCount?.makeToString() ?? ""}',
                                style: MyTextStyle.gilroyRegular(
                                    color: cLightText, size: 11),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                ReadMoreText(
                  comment.desc ?? '',
                  style: MyTextStyle.outfitLight(
                      color: cWhite, size: isReply ? 14 : 15),
                  annotations: [
                    Annotation(
                      regExp: RegExp(r'#([a-zA-Z0-9_]+)'),
                      spanBuilder: (
                              {required String text, TextStyle? textStyle}) =>
                          TextSpan(
                              text: text,
                              style: textStyle?.copyWith(
                                color: cPrimary,
                                fontFamily: MyTextStyle.outfitMedium(
                                        size: 15, color: cHashtagColor)
                                    .fontFamily,
                                fontSize: isReply ? 14 : 15,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  if (text.startsWith('#')) {
                                    Get.delete<TagController>().then((value) {
                                      Get.to(
                                          () => TagScreen(
                                              tag: text, isForReel: false),
                                          preventDuplicates: false);
                                    });
                                  }
                                }),
                    ),
                    Annotation(
                      regExp: RegExp(r'@([a-zA-Z0-9_]+)'),
                      spanBuilder: (
                              {required String text, TextStyle? textStyle}) =>
                          TextSpan(
                              text: text,
                              style: textStyle?.copyWith(
                                color: cPrimary,
                                fontFamily: MyTextStyle.outfitMedium(
                                        size: 15, color: cHashtagColor)
                                    .fontFamily,
                                fontSize: isReply ? 14 : 15,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  if (text.startsWith('@')) {
                                    final username = text.substring(1);
                                    UserService.shared
                                        .searchProfile(username, 0, (users) {
                                      if (users.isNotEmpty) {
                                        Get.to(
                                            () => ProfileScreen(
                                                userId: users.first.id ?? 0),
                                            preventDuplicates: false);
                                      }
                                    });
                                  }
                                }),
                    ),
                  ],
                  trimMode: TrimMode.Line,
                  trimLines: 5,
                  trimCollapsedText: ' ${LKeys.showMore.tr}',
                  trimExpandedText: '   ${LKeys.showLess.tr}',
                  moreStyle: MyTextStyle.outfitRegular(
                      color: cLightText, size: isReply ? 14 : 15),
                  lessStyle: MyTextStyle.outfitRegular(
                      color: cLightText, size: isReply ? 14 : 15),
                ),
                if (onReplyTap != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: GestureDetector(
                      onTap: onReplyTap,
                      child: Text(
                        LKeys.reply.tr,
                        style: MyTextStyle.gilroySemiBold(
                            color: cLightText, size: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void goToProfile() {
    Get.back();
    if (comment.company?.id != null) {
      Get.to(() => CompanyPublicProfileScreen(companyId: comment.company!.id!));
    } else {
      Get.to(() => ProfileScreen(userId: comment.userId ?? 0));
    }
  }
}
