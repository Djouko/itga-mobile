import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/moderator_service.dart';
import 'package:untitled/common/api_service/post_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/utils/input_sanitizer.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/comments_model.dart';
import 'package:untitled/models/posts_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/post/post_controller.dart';
import 'package:untitled/screens/sheets/confirmation_sheet.dart';

class CommentController extends BaseController {
  final Post post;
  final PostController postController;
  List<Comment> comments = [];
  TextEditingController textEditingController = TextEditingController();
  List<User> mentionedUsers = [];

  Comment? replyingTo;

  CommentController(this.post, this.postController);

  @override
  void onReady() {
    fetchComments();
    super.onReady();
  }

  Future<void> fetchComments() async {
    if (comments.isEmpty) {
      startLoading();
    }
    await PostService.shared.fetchComments(post.id ?? 0, comments.length, (comments) {
      stopLoading();
      this.comments.addAll(comments);
      update();
    });
  }

  void addMentionedUser(User user) {
    if (!mentionedUsers.any((u) => u.id == user.id)) {
      mentionedUsers.add(user);
    }
  }

  void setReplyingTo(Comment? comment) {
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

  void addComment() {
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
    PostService.shared.addComment(sanitized, post.id ?? 0, (comment) {
      stopLoading();
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
      textEditingController.clear();
      mentionedUsers.clear();
      postController.post.commentsCount += 1;
      postController.update(['comment']);
      postController.update();
      update();
    }, mentionedUserIds: mentionIds, parentId: replyingTo?.id);
  }

  Future<void> fetchReplies(Comment comment) async {
    await PostService.shared.fetchReplies(comment.id ?? 0, comment.replies.length, (replies) {
      var index = comments.indexWhere((c) => c.id == comment.id);
      if (index != -1) {
        comments[index].replies.addAll(replies);
        comments[index].repliesLoaded = true;
        update();
      }
    });
  }

  void toggleRepliesVisibility(Comment comment) {
    var index = comments.indexWhere((c) => c.id == comment.id);
    if (index != -1) {
      comments[index].repliesLoaded = !comments[index].repliesLoaded;
      update();
    }
  }

  Comment? editingComment;

  void startEditComment(Comment comment) {
    editingComment = comment;
    replyingTo = null;
    textEditingController.text = comment.desc ?? '';
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

  void submitEdit() {
    if (editingComment == null || textEditingController.text.trim().isEmpty) return;
    final newDesc = textEditingController.text.trim();
    final commentId = editingComment!.id ?? 0;
    startLoading();
    PostService.shared.editComment(
      commentId: commentId,
      description: newDesc,
      completion: (success) {
        stopLoading();
        if (!success) {
          showSnackBar(LKeys.someThingWentWrong.tr, type: SnackBarType.error);
          return;
        }
        // Update locally
        if (editingComment!.parentId != null) {
          var parentIndex = comments.indexWhere((c) => c.id == editingComment!.parentId);
          if (parentIndex != -1) {
            var replyIndex = comments[parentIndex].replies.indexWhere((r) => r.id == commentId);
            if (replyIndex != -1) {
              comments[parentIndex].replies[replyIndex].desc = newDesc;
              comments[parentIndex].replies[replyIndex].isEdited = true;
            }
          }
        } else {
          var index = comments.indexWhere((c) => c.id == commentId);
          if (index != -1) {
            comments[index].desc = newDesc;
            comments[index].isEdited = true;
          }
        }
        editingComment = null;
        textEditingController.clear();
        update();
      },
    );
  }

  void deleteComment(Comment comment) {
    startLoading();
    PostService.shared.deleteComment(
      commentId: comment.id ?? 0,
      completion: (success) {
        stopLoading();
        if (!success) {
          showSnackBar(LKeys.someThingWentWrong.tr, type: SnackBarType.error);
          return;
        }
        if (comment.parentId != null) {
          var parentIndex = comments.indexWhere((c) => c.id == comment.parentId);
          if (parentIndex != -1) {
            comments[parentIndex].replies.removeWhere((r) => r.id == comment.id);
            comments[parentIndex].replyCount -= 1;
          }
        } else {
          int removedCount = 1 + comment.replyCount;
          comments.removeWhere((element) => element.id == comment.id);
          postController.post.commentsCount -= removedCount;
          postController.update(['comment']);
          update();
          return;
        }
        postController.post.commentsCount -= 1;
        postController.update(['comment']);
        update();
      },
    );
  }

  void deleteCommentByModerator(Comment comment) {
    Get.bottomSheet(ConfirmationSheet(
      desc: LKeys.deleteCommentDisc,
      buttonTitle: LKeys.delete,
      onTap: () {
        stopLoading();
        ModeratorService.shared.deleteComment(
            commentId: comment.id?.toInt() ?? 0,
            completion: () {
              stopLoading();
              if (comment.parentId != null) {
                var parentIndex = comments.indexWhere((c) => c.id == comment.parentId);
                if (parentIndex != -1) {
                  comments[parentIndex].replies.removeWhere((r) => r.id == comment.id);
                  comments[parentIndex].replyCount -= 1;
                }
                postController.post.commentsCount -= 1;
              } else {
                int removedCount = 1 + comment.replyCount;
                comments.removeWhere((element) => element.id == comment.id);
                postController.post.commentsCount -= removedCount;
              }
              postController.update(['comment']);
              update();
            });
      },
    ));
  }

  @override
  void onClose() {
    textEditingController.dispose();
    super.onClose();
  }

  void likeDislikeComment(Comment comment) {
    Comment target = comment;
    if (comment.parentId != null) {
      var parentIndex = comments.indexWhere((c) => c.id == comment.parentId);
      if (parentIndex != -1) {
        var replyIndex = comments[parentIndex].replies.indexWhere((r) => r.id == comment.id);
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
    PostService.shared.likeDislike(comment.id ?? 0, (_) {});
  }
}
