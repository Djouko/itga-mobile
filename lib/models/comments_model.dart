import 'package:untitled/models/registration.dart';
import 'package:untitled/models/job_models.dart';

// class CommentModel {
//   CommentModel({
//     this.status,
//     this.message,
//     this.data,
//   });
//
//   CommentModel.fromJson(dynamic json) {
//     status = json['status'];
//     message = json['message'];
//     data = (json['data'] != null) ? Comment.fromJson(json['data']) : null;
//   }
//
//   bool? status;
//   String? message;
//   Comment? data;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['status'] = status;
//     map['message'] = message;
//     if (data != null) {
//       map['data'] = data;
//     }
//     return map;
//   }
// }

class CommentsModel {
  CommentsModel({
    this.status,
    this.message,
    this.data,
  });

  CommentsModel.fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(Comment.fromJson(v));
      });
    }
  }

  bool? status;
  String? message;
  List<Comment>? data;

  CommentsModel copyWith({
    bool? status,
    String? message,
    List<Comment>? data,
  }) =>
      CommentsModel(
        status: status ?? this.status,
        message: message ?? this.message,
        data: data ?? this.data,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Comment {
  Comment({
    this.id,
    this.userId,
    this.postId,
    this.desc,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.company,
    this.isLike,
    this.commentLikeCount,
  });

  Comment.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    postId = json['post_id'];
    parentId = json['parent_id'];
    desc = json['desc'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    isLike = json['is_like'];
    commentLikeCount = json['comment_like_count'];
    replyCount = json['reply_count'] ?? 0;
    isEdited = json['is_edited'] == 1;
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    company =
        json['company'] != null ? Company.fromJson(json['company']) : null;
  }

  num? id;
  num? userId;
  num? postId;
  num? parentId;
  String? desc;
  String? createdAt;
  String? updatedAt;
  User? user;
  Company? company;
  int? isLike;
  int? commentLikeCount;
  int replyCount = 0;
  bool isEdited = false;
  List<Comment> replies = [];
  bool repliesLoaded = false;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['post_id'] = postId;
    map['desc'] = desc;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['is_like'] = isLike;
    map['comment_like_count'] = commentLikeCount;
    map['parent_id'] = parentId;
    map['reply_count'] = replyCount;
    map['is_edited'] = isEdited ? 1 : 0;
    if (user != null) {
      map['user'] = user?.toJson();
    }
    if (company != null) {
      map['company'] = company?.toJson();
    }
    return map;
  }
}

extension O on Comment {
  DateTime get date => DateTime.parse(createdAt ?? '');
}
