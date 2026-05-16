import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/models/setting_model.dart';
import 'package:untitled/models/story.dart';

class Registration {
  bool? status;
  String? message;
  String? authToken;
  User? data;

  Registration({
    this.status,
    this.message,
    this.authToken,
    this.data,
  });

  factory Registration.fromJson(dynamic json) => Registration(
        status: json["status"],
        message: json["message"],
        authToken: json["auth_token"],
        data: json["data"] == null ? null : User.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "auth_token": authToken,
        "data": data?.toJson(),
      };
}

class UserOwnedCompany {
  int? id;
  int? ownerUserId;
  String? name;
  String? email;
  String? logo;
  String? description;
  String? sector;
  String? website;
  String? city;
  String? country;
  int? companySize;
  int? isVerified;
  int? isSuspended;
  int? publishedOffersCount;
  int? jobOffersCount;
  int? followersCount;
  int? isFollowing;

  UserOwnedCompany({
    this.id,
    this.ownerUserId,
    this.name,
    this.email,
    this.logo,
    this.description,
    this.sector,
    this.website,
    this.city,
    this.country,
    this.companySize,
    this.isVerified,
    this.isSuspended,
    this.publishedOffersCount,
    this.jobOffersCount,
    this.followersCount,
    this.isFollowing,
  });

  factory UserOwnedCompany.fromJson(Map<String, dynamic> json) =>
      UserOwnedCompany(
        id: _jsonInt(json['id']),
        ownerUserId: _jsonInt(json['owner_user_id']),
        name: json['name'],
        email: json['email'],
        logo: json['logo'],
        description: json['description'],
        sector: json['sector'],
        website: json['website'],
        city: json['city'],
        country: json['country'],
        companySize: _jsonInt(json['company_size']),
        isVerified: _jsonInt(json['is_verified']),
        isSuspended: _jsonInt(json['is_suspended']),
        publishedOffersCount: _jsonInt(json['published_offers_count']),
        jobOffersCount: _jsonInt(json['job_offers_count']),
        followersCount: _jsonInt(json['followers_count']),
        isFollowing: _jsonInt(json['is_following']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_user_id': ownerUserId,
        'name': name,
        'email': email,
        'logo': logo,
        'description': description,
        'sector': sector,
        'website': website,
        'city': city,
        'country': country,
        'company_size': companySize,
        'is_verified': isVerified,
        'is_suspended': isSuspended,
        'published_offers_count': publishedOffersCount,
        'job_offers_count': jobOffersCount,
        'followers_count': followersCount,
        'is_following': isFollowing,
      };
}

int? _jsonInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

class User {
  User({
    this.id,
    this.identity,
    this.username,
    this.fullName,
    this.bio,
    this.interestIds,
    this.profile,
    this.backgroundImage,
    this.isPushNotifications,
    this.isInvitedToRoom,
    this.isVerified,
    this.isBlock,
    this.blockUserIds,
    this.following,
    this.followers,
    this.loginType,
    this.deviceType,
    this.deviceToken,
    this.createdAt,
    this.updatedAt,
    this.followingStatus,
    this.stories,
    this.companyStories,
    this.interest,
    this.savedMusicIds,
    this.profileType,
    this.ownedCompany,
  });

  User.fromJson(dynamic json) {
    id = json['id'];
    identity = json['identity'];
    username = json['username'];
    fullName = json['full_name'];
    bio = json['bio'];
    interestIds = json['interest_ids'];
    profile = json['profile'];
    backgroundImage = json['background_image'];
    isPushNotifications = json['is_push_notifications'];
    isInvitedToRoom = json['is_invited_to_room'];
    isVerified = json['is_verified'];
    isBlock = json['is_block'];
    blockUserIds = json['block_user_ids'];
    following = json['following'];
    followers = json['followers'];
    loginType = json['login_type'];
    deviceType = json['device_type'];
    deviceToken = json['device_token'];
    isModerator = json['is_moderator'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    followingStatus = json['followingStatus'];
    savedMusicIds = json['saved_music_ids'];
    savedReelIds = json['saved_reel_ids'];
    savedPostIds = json['saved_post_ids'];
    headline = json['headline'];
    about = json['about'];
    experience = json['experience'];
    education = json['education'];
    skills = json['skills'];
    location = json['location'];
    website = json['website'];
    pronouns = json['pronouns'];
    profileType = json['profile_type'];
    ownedCompany = json['owned_company'] != null && json['owned_company'] is Map
        ? UserOwnedCompany.fromJson(
            Map<String, dynamic>.from(json['owned_company']))
        : null;

    if (json['interest'] != null) {
      interest = [];
      json['interest'].forEach((v) {
        interest?.add(Interest.fromJson(v));
      });
    }

    if (json['stories'] != null) {
      stories = [];
      json['stories'].forEach((v) {
        var s = Story.fromJson(v);
        s.user = this;
        stories?.add(s);
      });
    }

    if (json['company_stories'] != null) {
      companyStories = [];
      json['company_stories'].forEach((v) {
        var s = Story.fromJson(v);
        companyStories?.add(s);
      });
    }
  }

  num? id;
  String? identity;
  String? username;
  String? fullName;
  String? bio;
  String? interestIds;
  String? profile;
  String? backgroundImage;
  num? isPushNotifications;
  num? isInvitedToRoom;
  num? isVerified;
  num? isBlock;
  String? blockUserIds;
  num? following;
  num? followers;
  num? loginType;
  num? deviceType;
  num? isModerator;
  String? savedMusicIds;
  String? savedReelIds;
  String? savedPostIds;
  String? deviceToken;
  String? createdAt;
  String? updatedAt;
  String? headline;
  String? about;
  String? experience;
  String? education;
  String? skills;
  String? location;
  String? website;
  String? pronouns;
  String? profileType;
  UserOwnedCompany? ownedCompany;

  num? followingStatus;
  List<Story>? stories;
  List<Story>? companyStories;
  List<Interest>? interest;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['identity'] = identity;
    map['username'] = username;
    map['full_name'] = fullName;
    map['bio'] = bio;
    map['interest_ids'] = interestIds;
    map['profile'] = profile;
    map['background_image'] = backgroundImage;
    map['is_push_notifications'] = isPushNotifications;
    map['is_invited_to_room'] = isInvitedToRoom;
    map['is_verified'] = isVerified;
    map['is_block'] = isBlock;
    map['block_user_ids'] = blockUserIds;
    map['following'] = following;
    map['followers'] = followers;
    map['login_type'] = loginType;
    map['device_type'] = deviceType;
    map['device_token'] = deviceToken;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['followingStatus'] = followingStatus;
    map['is_moderator'] = isModerator;
    map['saved_music_ids'] = savedMusicIds;
    map['saved_reel_ids'] = savedReelIds;
    map['saved_post_ids'] = savedPostIds;
    map['headline'] = headline;
    map['about'] = about;
    map['experience'] = experience;
    map['education'] = education;
    map['skills'] = skills;
    map['location'] = location;
    map['website'] = website;
    map['pronouns'] = pronouns;
    map['profile_type'] = profileType;
    map['owned_company'] = ownedCompany?.toJson();
    if (stories != null) {
      map['stories'] = stories?.map((v) => v.toJson()).toList();
    }
    if (companyStories != null) {
      map['company_stories'] =
          companyStories?.map((v) => v.toJson()).toList();
    }
    if (interest != null) {
      map['interest'] = interest?.map((v) => v.toJson()).toList();
    }
    return map;
  }

  String firebaseId() {
    return "${id ?? 0}";
  }

  bool isAllStoryShown() {
    var isWatched = true;
    for (var element in (stories ?? [])) {
      if (!element.isWatchedByMe()) {
        isWatched = false;
        break;
      }
    }
    return isWatched;
  }

  bool isBlockedByMe() {
    return SessionManager.shared
            .getUser()
            ?.blockUserIds
            ?.split(',')
            .contains('$id') ??
        false;
  }
}

extension O on User {
  List<String> getInterestsStringList() {
    List<String> arr = (interestIds ?? '').split(',');
    List<Interest> interests =
        SessionManager.shared.getSettings()?.interests?.where((element) {
              return arr.contains("${element.id}");
            }).toList() ??
            [];

    return interests.map((e) => e.title ?? "").toList();
  }

  List<Interest> getInterests() {
    List<String> arr = (interestIds ?? '').split(',');
    List<Interest> interests =
        SessionManager.shared.getSettings()?.interests?.where((element) {
              return arr.contains("${element.id}");
            }).toList() ??
            [];

    return interests;
  }

  List<int> getSavedMusicIdsList() {
    List<String> arr = (savedMusicIds ?? '').split(',');

    return arr.map((e) => int.tryParse(e) ?? 0).toList();
  }

  List<int> getSavedReelIdsList() {
    List<String> arr = (savedReelIds ?? '').split(',');

    return arr.map((e) => int.tryParse(e) ?? 0).toList();
  }

  List<int> getSavedPostIdsList() {
    List<String> arr = (savedPostIds ?? '').split(',');

    return arr.map((e) => int.tryParse(e) ?? 0).toList();
  }

  ///Use this
  FollowStatus get followStatus {
    return FollowStatus.values.firstWhere(
      (element) => element.value == (followingStatus?.toInt() ?? 0),
    );
  }
}

enum FollowStatus {
  noFollowNo(0),
  heFollowsMe(1),
  iFollowHim(2),
  weFollowEachOther(3);

  /// koi ek bija ne follow nathi kartu to 0
  /// same valo mane follow kar che to 1
  /// hu same vala ne follow karu chu to 2
  /// banne ek bija ne follow kare to 3

  final int value;

  const FollowStatus(this.value);
}
