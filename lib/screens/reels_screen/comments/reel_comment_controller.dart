import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/moderator_service.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/utils/input_sanitizer.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/reel_comments_model.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/reels_screen/reel/reel_page_controller.dart';
import 'package:untitled/screens/sheets/confirmation_sheet.dart';

class ReelCommentController extends BaseController {
  final ReelController reelController;
  RxList<ReelComment> comments = RxList();
  TextEditingController textEditingController = TextEditingController();
  List<User> mentionedUsers = [];

  ReelComment? replyingTo;

  ReelCommentController(this.reelController);

  Reel? get reel => reelController.reel.value;

  @override
  void onReady() {
    fetchComments();
    super.onReady();
  }

  Future<void> fetchComments() async {
    if (comments.isEmpty) {
      isLoading.value = true;
      update();
    }

    try {
      this.comments.addAll(
            await ReelService.shared
                .fetchComments(reelId: reel?.id ?? 0, start: comments.length),
          );
      hasNetworkError = false;
    } catch (_) {
      hasNetworkError = true;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  void addMentionedUser(User user) {
    if (!mentionedUsers.any((u) => u.id == user.id)) {
      mentionedUsers.add(user);
    }
  }

  void setReplyingTo(ReelComment? comment) {
    replyingTo = comment;
    if (comment != null) {
      textEditingController.text = '@${comment.user?.username ?? ''} ';
      textEditingController.selection = TextSelection.fromPosition(
        TextPosition(offset: textEditingController.text.length),
      );
    }
    update();
  }

  void cancelReply() {
    replyingTo = null;
    textEditingController.clear();
    update();
  }

  ReelComment? editingComment;

  void startEditComment(ReelComment comment) {
    editingComment = comment;
    replyingTo = null;
    textEditingController.text = comment.description ?? '';
    textEditingController.selection = TextSelection.fromPosition(
      TextPosition(offset: textEditingController.text.length),
    );
    update();
  }

  void cancelEdit() {
    editingComment = null;
    textEditingController.clear();
    update();
  }

  void submitEdit() async {
    if (editingComment == null || textEditingController.text.trim().isEmpty)
      return;
    final newDesc = textEditingController.text.trim();
    final commentId = editingComment!.id ?? 0;
    startLoading();
    bool success = await ReelService.shared
        .editReelComment(commentId: commentId, description: newDesc);
    stopLoading();
    if (success) {
      if (editingComment!.parentId != null) {
        var parentIndex =
            comments.indexWhere((c) => c.id == editingComment!.parentId);
        if (parentIndex != -1) {
          var replyIndex = comments[parentIndex]
              .replies
              .indexWhere((r) => r.id == commentId);
          if (replyIndex != -1) {
            comments[parentIndex].replies[replyIndex].description = newDesc;
            comments[parentIndex].replies[replyIndex].isEdited = true;
          }
        }
      } else {
        var index = comments.indexWhere((c) => c.id == commentId);
        if (index != -1) {
          comments[index].description = newDesc;
          comments[index].isEdited = true;
        }
      }
    }
    editingComment = null;
    textEditingController.clear();
    update();
  }

  void addComment() async {
    final sanitized = InputSanitizer.sanitizeText(textEditingController.text);
    if (sanitized.isEmpty) {
      return;
    }
    textEditingController.text = sanitized;
    // If editing, submit edit instead
    if (editingComment != null) {
      submitEdit();
      return;
    }
    startLoading();
    var mentionIds = mentionedUsers.map((u) => '${u.id}').toList().join(',');
    ReelComment? comment = await ReelService.shared.addComment(
      comment: sanitized,
      reelId: reel?.id ?? 0,
      mentionedUserIds: mentionIds,
      parentId: replyingTo?.id,
    );
    stopLoading();
    if (comment != null) {
      comment.user = SessionManager.shared.getUser();
      if (replyingTo != null) {
        var parentIndex = comments.indexWhere((c) => c.id == replyingTo!.id);
        if (parentIndex != -1) {
          comments[parentIndex].replies.insert(0, comment);
          comments[parentIndex].replyCount += 1;
          comments[parentIndex].repliesLoaded = true;
        }
        replyingTo = null;
      } else {
        comments.insert(0, comment);
      }
    }
    textEditingController.clear();
    mentionedUsers.clear();
    reelController.reel.update((val) {
      val?.commentsCount = (reelController.reel.value?.commentsCount ?? 0) + 1;
    });
    update();
  }

  Future<void> fetchReplies(ReelComment comment) async {
    var replies = await ReelService.shared.fetchReelCommentReplies(
      reelCommentId: comment.id ?? 0,
      start: comment.replies.length,
    );
    var index = comments.indexWhere((c) => c.id == comment.id);
    if (index != -1) {
      comments[index].replies.addAll(replies);
      comments[index].repliesLoaded = true;
      update();
    }
  }

  void toggleRepliesVisibility(ReelComment comment) {
    var index = comments.indexWhere((c) => c.id == comment.id);
    if (index != -1) {
      comments[index].repliesLoaded = !comments[index].repliesLoaded;
      update();
    }
  }

  void likeDislikeComment(ReelComment comment) {
    ReelComment target = comment;
    if (comment.parentId != null) {
      var parentIndex = comments.indexWhere((c) => c.id == comment.parentId);
      if (parentIndex != -1) {
        var replyIndex =
            comments[parentIndex].replies.indexWhere((r) => r.id == comment.id);
        if (replyIndex != -1) {
          target = comments[parentIndex].replies[replyIndex];
        }
      }
    } else {
      var index = comments.indexWhere((element) => element.id == comment.id);
      if (index != -1) {
        target = comments[index];
      }
    }
    target.isLike = target.isLike == 1 ? 0 : 1;
    target.commentLikeCount = target.isLike == 1
        ? (target.commentLikeCount ?? 0) + 1
        : (target.commentLikeCount ?? 0) - 1;
    update();
    ReelService.shared.likeDislikeReelComment(commentId: comment.id ?? 0);
  }

  void deleteComment(ReelComment comment) async {
    startLoading();
    await ReelService.shared.deleteReelComment(commentId: comment.id ?? 0);
    stopLoading();
    int removedCount = 1;
    if (comment.parentId != null) {
      var parentIndex = comments.indexWhere((c) => c.id == comment.parentId);
      if (parentIndex != -1) {
        comments[parentIndex].replies.removeWhere((r) => r.id == comment.id);
        comments[parentIndex].replyCount -= 1;
      }
    } else {
      removedCount = 1 + comment.replyCount;
      comments.removeWhere((element) => element.id == comment.id);
    }
    reelController.reel.update((val) {
      val?.commentsCount = max(
          0, (reelController.reel.value?.commentsCount ?? 0) - removedCount);
    });
    update();
  }

  @override
  void onClose() {
    textEditingController.dispose();
    super.onClose();
  }

  void deleteCommentByModerator(ReelComment comment) {
    Get.bottomSheet(ConfirmationSheet(
      desc: LKeys.deleteCommentDisc,
      buttonTitle: LKeys.delete,
      onTap: () {
        stopLoading();
        ModeratorService.shared
            .deleteReelComment(commentId: comment.id?.toInt() ?? 0);
        int removedCount = 1;
        if (comment.parentId != null) {
          var parentIndex =
              comments.indexWhere((c) => c.id == comment.parentId);
          if (parentIndex != -1) {
            comments[parentIndex]
                .replies
                .removeWhere((r) => r.id == comment.id);
            comments[parentIndex].replyCount -= 1;
          }
        } else {
          removedCount = 1 + comment.replyCount;
          comments.removeWhere((element) => element.id == comment.id);
        }
        reelController.reel.update((val) {
          val?.commentsCount = max(0,
              (reelController.reel.value?.commentsCount ?? 0) - removedCount);
        });
        update();
      },
    ));
  }
}
