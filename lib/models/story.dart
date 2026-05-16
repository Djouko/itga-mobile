import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/library/story_view/story_view.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/utilities/const.dart';

class StoryModel {
  StoryModel({
    this.status,
    this.message,
    this.data,
  });

  StoryModel.fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? Story.fromJson(json['data']) : null;
  }

  bool? status;
  String? message;
  Story? data;
}

class Story {
  Story({
    this.id,
    this.userId,
    this.companyId,
    this.type,
    this.duration,
    this.content,
    this.viewByUserIds,
    this.viewByCompanyIds,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.company,
    this.thumbnail,
  });

  Story.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    companyId = json['company_id'];
    type = json['type'];
    duration = json['duration'];
    content = json['content'];
    thumbnail = json['thumbnail'];
    viewByUserIds = json['view_by_user_ids'];
    viewByCompanyIds = json['view_by_company_ids'];
    createdAt = json['created_at'];
    company = json['company'] != null && json['company'] is Map
        ? UserOwnedCompany.fromJson(Map<String, dynamic>.from(json['company']))
        : null;
    updatedAt = json['updated_at'];
    user = companyId != null && company != null
        ? _companyAsUser(company!)
        : json['user'] != null
            ? User.fromJson(json['user'])
            : null;
  }

  num? id;
  num? userId;
  num? companyId;
  num? type;
  num? duration;
  String? content;
  String? viewByUserIds;
  String? viewByCompanyIds;
  String? createdAt;
  String? updatedAt;
  User? user;
  UserOwnedCompany? company;
  String? thumbnail;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['company_id'] = companyId;
    map['type'] = type;
    map['duration'] = duration;
    map['content'] = content;
    map['thumbnail'] = thumbnail;
    map['view_by_user_ids'] = viewByUserIds;
    map['view_by_company_ids'] = viewByCompanyIds;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['user'] = user?.toJson();
    map['company'] = company?.toJson();
    return map;
  }

  bool isWatchedByMe() {
    final actingCompanyId = SessionManager.shared.getActingCompanyId();
    final actorId = actingCompanyId ?? SessionManager.shared.getUserID();
    final source = actingCompanyId != null ? viewByCompanyIds : viewByUserIds;
    var arr = source?.split(',') ?? [];
    return arr.contains(actorId.toString());
  }

  List<String> viewedByUsersIds() {
    final source = SessionManager.shared.getActingCompanyId() != null
        ? viewByCompanyIds
        : viewByUserIds;
    return source?.split(',') ?? [];
  }

  bool isOwnedByCurrentActor() {
    final actingCompanyId = SessionManager.shared.getActingCompanyId();
    if (actingCompanyId != null) {
      return companyId?.toInt() == actingCompanyId;
    }
    return companyId == null &&
        userId?.toInt() == SessionManager.shared.getUserID();
  }

  StoryItem toStoryItem(StoryController controller) {
    if (type == 1) {
      return StoryItem.pageVideo(
        story: this,
        content?.addBaseURL() ?? '',
        controller: controller,
        duration: Duration(seconds: (duration ?? Limits.storyDuration).toInt()),
        shown: isWatchedByMe(),
        id: id ?? 0,
        viewedByUsersIds: viewedByUsersIds(),
      );
    } else if (type == 0) {
      return StoryItem.pageImage(
        story: this,
        url: content?.addBaseURL() ?? '',
        duration: Duration(seconds: Limits.storyDuration),
        controller: controller,
        shown: isWatchedByMe(),
        id: id ?? 0,
        viewedByUsersIds: viewedByUsersIds(),
      );
    } else {
      return StoryItem.text(
        story: this,
        title: content ?? '',
        backgroundColor: cBlack,
        shown: isWatchedByMe(),
        id: id ?? 0,
        viewedByUsersIds: viewedByUsersIds(),
      );
    }
  }

  DateTime get date => DateTime.parse(createdAt ?? '');

  String? get thumbnailForReply {
    if (type == 1) return thumbnail;
    return content;
  }
}

User _companyAsUser(UserOwnedCompany company) {
  return User(
    id: company.id,
    fullName: company.name,
    username: 'company-${company.id}',
    bio: company.description,
    profile: company.logo,
    followers: company.followersCount,
    following: 0,
    isVerified: company.isVerified == 1 ? 2 : 0,
    isBlock: company.isSuspended,
    profileType: 'company',
    ownedCompany: company,
  );
}
