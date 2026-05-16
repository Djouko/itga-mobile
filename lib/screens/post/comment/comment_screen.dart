import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/managers/load_more_widget.dart';
import 'package:untitled/common/widgets/mention_overlay.dart';
import 'package:untitled/common/widgets/no_data_view.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/extra_views/back_button.dart';
import 'package:untitled/screens/post/comment/comment_card.dart';
import 'package:untitled/screens/post/comment/comment_controller.dart';
import 'package:untitled/screens/post/post_controller.dart';
import 'package:untitled/utilities/const.dart';

class CommentScreen extends StatelessWidget {
  final PostController postController;

  const CommentScreen({Key? key, required this.postController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(CommentController(postController.post, postController));
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(color: cBlack, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cLightText.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(width: 15),
                  Text(
                    LKeys.comments.tr,
                    style: MyTextStyle.gilroyBold(color: cWhite, size: 18),
                  ),
                  const Spacer(),
                  const XMarkButton(),
                  const SizedBox(width: 5),
                ],
              ),
              const SizedBox(height: 8),
              Divider(height: 0.5, thickness: 0.5, color: cLightText.withValues(alpha: 0.12)),
              Expanded(
                child: GetBuilder(
                    init: controller,
                    builder: (controller) {
                      return NoDataView(
                        showShow: controller.comments.isEmpty,
                        child: LoadMoreWidget(
                          loadMore: controller.fetchComments,
                          child: ListView.builder(
                            itemCount: controller.comments.length,
                            itemBuilder: (context, index) {
                              final comment = controller.comments[index];
                              return RepaintBoundary(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CommentCard(
                                    comment: comment,
                                    onDeleteTap: () {
                                      controller.deleteComment(comment);
                                    },
                                    onDeleteModeratorTap: () {
                                      controller.deleteCommentByModerator(comment);
                                    },
                                    onLikeDisLike: () {
                                      controller.likeDislikeComment(comment);
                                    },
                                    onReplyTap: () {
                                      controller.setReplyingTo(comment);
                                    },
                                    onEditTap: () {
                                      controller.startEditComment(comment);
                                    },
                                  ),
                                  if (comment.replyCount > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 55),
                                      child: GestureDetector(
                                        onTap: () {
                                          if (comment.repliesLoaded) {
                                            controller.toggleRepliesVisibility(comment);
                                          } else {
                                            controller.fetchReplies(comment);
                                          }
                                        },
                                        child: Text(
                                          comment.repliesLoaded
                                              ? '── ${LKeys.hideReplies.tr}'
                                              : '── ${LKeys.viewReplies.tr} (${comment.replyCount})',
                                          style: MyTextStyle.gilroySemiBold(color: cPrimary, size: 13),
                                        ),
                                      ),
                                    ),
                                  if (comment.repliesLoaded)
                                    ...comment.replies.map((reply) => Padding(
                                      padding: const EdgeInsets.only(left: 45),
                                      child: CommentCard(
                                        comment: reply,
                                        isReply: true,
                                        onDeleteTap: () {
                                          controller.deleteComment(reply);
                                        },
                                        onDeleteModeratorTap: () {
                                          controller.deleteCommentByModerator(reply);
                                        },
                                        onLikeDisLike: () {
                                          controller.likeDislikeComment(reply);
                                        },
                                        onReplyTap: () {
                                          controller.setReplyingTo(comment);
                                        },
                                        onEditTap: () {
                                          controller.startEditComment(reply);
                                        },
                                      ),
                                    )),
                                ],
                              ));
                            },
                          ),
                        ),
                      );
                    }),
              ),
              MentionOverlay(
                textController: controller.textEditingController,
                onMentionSelected: controller.addMentionedUser,
              ),
              GetBuilder<CommentController>(
                init: controller,
                builder: (_) {
                  if (controller.editingComment != null) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: cOrange.withValues(alpha: 0.08),
                        border: const Border(left: BorderSide(color: cOrange, width: 3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded, color: cOrange, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Editing comment...',
                              style: MyTextStyle.gilroySemiBold(color: cOrange, size: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: controller.cancelEdit,
                            child: const Icon(Icons.close_rounded, color: cLightText, size: 18),
                          ),
                        ],
                      ),
                    );
                  }
                  if (controller.replyingTo != null) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: cPrimary.withValues(alpha: 0.08),
                        border: Border(left: BorderSide(color: cPrimary, width: 3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.reply_rounded, color: cPrimary, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${LKeys.replyingTo.tr} @${controller.replyingTo?.user?.username ?? ''}',
                              style: MyTextStyle.gilroySemiBold(color: cPrimary, size: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: controller.cancelReply,
                            child: Icon(Icons.close_rounded, color: cLightText, size: 18),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              commentTextField(controller)
            ],
          ),
        ),
      ),
    );
  }

  Widget commentTextField(CommentController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cLightText.withValues(alpha: 0.12))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cWhite.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller.textEditingController,
                decoration: InputDecoration(
                  hintText: LKeys.writeSomething.tr,
                  hintStyle: MyTextStyle.gilroyRegular(color: cLightText, size: 15),
                  border: InputBorder.none,
                  counterText: '',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                cursorColor: cPrimary,
                style: MyTextStyle.gilroyRegular(color: cWhite, size: 15),
                maxLines: 3,
                minLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: controller.addComment,
            child: const SendBtn(),
          ),
        ],
      ),
    );
  }
}

class SendBtn extends StatelessWidget {
  const SendBtn({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return CircleAvatar(
      backgroundColor: cPrimary,
      foregroundColor: cBlack,
      radius: 16,
      child: Container(
        padding: const EdgeInsets.only(left: 2),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(isRTL ? -1.0 : 1.0, 1.0),
          child: Image.asset(
            MyImages.send,
            height: 20,
            width: 20,
          ),
        ),
      ),
    );
  }
}
