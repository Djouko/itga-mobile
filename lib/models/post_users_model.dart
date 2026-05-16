import 'package:untitled/models/registration.dart';

class PostUsersModel {
  PostUsersModel({
    this.status,
    this.message,
    this.data,
  });

  PostUsersModel.fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(Data.fromJson(v));
      });
    }
  }

  bool? status;
  String? message;
  List<Data>? data;

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

class Data {
  Data({
    this.id,
    this.userId,
    this.companyId,
    this.postId,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.company,
  });

  Data.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    companyId = json['company_id'];
    postId = json['post_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    company = json['company'] != null && json['company'] is Map
        ? UserOwnedCompany.fromJson(Map<String, dynamic>.from(json['company']))
        : null;
  }

  num? id;
  num? userId;
  num? companyId;
  num? postId;
  String? createdAt;
  String? updatedAt;
  User? user;
  UserOwnedCompany? company;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['company_id'] = companyId;
    map['post_id'] = postId;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    if (user != null) {
      map['user'] = user?.toJson();
    }
    if (company != null) {
      map['company'] = company?.toJson();
    }
    return map;
  }
}
