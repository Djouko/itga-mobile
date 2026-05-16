import 'package:untitled/models/job_models.dart';
import 'package:untitled/models/registration.dart';

class ReelCommentsModel {
  bool? status;
  String? message;
  List<ReelComment>? data;

  ReelCommentsModel({
    this.status,
    this.message,
    this.data,
  });

  factory ReelCommentsModel.fromJson(Map<String, dynamic> json) =>
      ReelCommentsModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<ReelComment>.from(
                json["data"]!.map((x) => ReelComment.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class ReelComment {
  int? id;
  int? userId;
  int? companyId;
  int? reelId;
  int? parentId;
  String? description;
  int? isLike;
  num? commentLikeCount;
  int replyCount = 0;
  bool isEdited = false;
  List<ReelComment> replies = [];
  bool repliesLoaded = false;
  DateTime? createdAt;
  DateTime? updatedAt;
  User? user;
  Company? company;

  ReelComment({
    this.id,
    this.userId,
    this.companyId,
    this.reelId,
    this.parentId,
    this.description,
    this.isLike,
    this.commentLikeCount,
    this.replyCount = 0,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.company,
  });

  factory ReelComment.fromJson(Map<String, dynamic> json) {
    final comment = ReelComment(
      id: json["id"],
      userId: json["user_id"],
      companyId: json["company_id"],
      reelId: json["reel_id"],
      parentId: json["parent_id"],
      description: json["description"],
      isLike: json["is_like"],
      commentLikeCount: json["comment_like_count"],
      replyCount: json["reply_count"] ?? 0,
      createdAt: json["created_at"] == null
          ? null
          : DateTime.parse(json["created_at"]),
      updatedAt: json["updated_at"] == null
          ? null
          : DateTime.parse(json["updated_at"]),
      user: json["user"] == null ? null : User.fromJson(json["user"]),
      company:
          json["company"] == null ? null : Company.fromJson(json["company"]),
    );
    comment.isEdited = json["is_edited"] == 1;
    return comment;
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "company_id": companyId,
        "reel_id": reelId,
        "parent_id": parentId,
        "description": description,
        "is_like": isLike,
        "comment_like_count": commentLikeCount,
        "reply_count": replyCount,
        "is_edited": isEdited ? 1 : 0,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "user": user?.toJson(),
        "company": company?.toJson(),
      };
}
