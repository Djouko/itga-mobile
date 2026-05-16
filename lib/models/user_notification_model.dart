import 'package:untitled/models/posts_model.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/room_model.dart';
import 'package:untitled/models/job_models.dart';

class UserNotificationModel {
  UserNotificationModel({
    this.status,
    this.message,
    this.data,
  });

  UserNotificationModel.fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(UserNotification.fromJson(v));
      });
    }
  }

  bool? status;
  String? message;
  List<UserNotification>? data;

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

class UserNotification {
  UserNotification({
    this.id,
    this.myUserId,
    this.userId,
    this.companyId,
    this.itemId,
    this.postId,
    this.roomId,
    this.reelId,
    this.type,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.company,
    this.post,
    this.room,
    this.reel,
  });

  UserNotification.fromJson(dynamic json) {
    id = json['id'];
    myUserId = json['my_user_id'];
    userId = json['user_id'];
    companyId = json['company_id'];
    itemId = json['item_id'];
    postId = json['post_id'];
    roomId = json['room_id'];
    reelId = json['reel_id'];
    type = json['type'];
    isRead = json['is_read'] == true || json['is_read'] == 1;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    company =
        json['company'] != null ? Company.fromJson(json['company']) : null;
    post = json['post'] != null ? Post.fromJson(json['post']) : null;
    room = json['room'] != null ? Room.fromJson(json['room']) : null;
    reel = json['reel'] != null ? Reel.fromJson(json['reel']) : null;
  }

  num? id;
  num? myUserId;
  num? userId;
  num? companyId;
  num? itemId;
  num? postId;
  num? roomId;
  num? reelId;
  num? type;
  bool isRead = false;
  String? createdAt;
  String? updatedAt;
  User? user;
  Company? company;
  Post? post;
  Room? room;
  Reel? reel;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['my_user_id'] = myUserId;
    map['user_id'] = userId;
    map['company_id'] = companyId;
    map['item_id'] = itemId;
    map['post_id'] = postId;
    map['room_id'] = roomId;
    map['reel_id'] = reelId;
    map['type'] = type;
    map['is_read'] = isRead;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    if (user != null) {
      map['user'] = user?.toJson();
    }
    if (company != null) {
      map['company'] = company?.toJson();
    }
    if (post != null) {
      map['post'] = post?.toJson();
    }
    if (room != null) {
      map['room'] = room?.toJson();
    }
    if (reel != null) {
      map['reel'] = reel?.toJson();
    }
    return map;
  }
}
