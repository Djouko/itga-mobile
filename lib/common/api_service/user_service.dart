import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/api_service/api_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/common_response.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/setting_model.dart';
import 'package:untitled/models/users_model.dart';
import 'package:untitled/screens/login_screen/login_controller.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/params.dart';
import 'package:untitled/utilities/web_service.dart';

class UserService {
  static var shared = UserService();

  void _addActingCompanyId(Map<String, dynamic> param) {
    final companyId = SessionManager.shared.getActingCompanyId();
    if (companyId != null) {
      param[Param.companyId] = companyId;
    }
  }

  Future<void> fetchFollowingList(
      num userId, int start, Function(List<User> users) completion) async {
    Map<String, dynamic> param = {
      Param.myUserId: userId,
      Param.start: start,
      Param.limit: Limits.pagination,
    };
    _addActingCompanyId(param);
    await ApiService.shared.call(
      url: WebService.fetchFollowingList,
      param: param,
      completion: (response) {
        var users = UsersModel.fromJson(response).data;
        if (users != null) {
          completion(users);
        }
      },
    );
  }

  Future<void> fetchFollowerList(
      num userId, int start, Function(List<User> users) completion,
      {String? keyword = null}) async {
    Map<String, dynamic> param = {
      Param.userId: userId,
      Param.start: start,
      Param.limit: Limits.pagination,
    };
    if (keyword != null) {
      param[Param.keyword] = keyword;
    }
    await ApiService.shared.call(
      url: WebService.fetchFollowersList,
      param: param,
      completion: (response) {
        var users = UsersModel.fromJson(response).data;
        if (users != null) {
          completion(users);
        }
      },
    );
  }

  Future<void> searchProfile(
      String keyword, int start, Function(List<User> users) completion) async {
    var param = {
      Param.myUserId: SessionManager.shared.getUserID(),
      Param.keyword: keyword,
      Param.start: start,
      Param.limit: Limits.pagination,
    };

    await ApiService.shared.call(
      url: WebService.searchProfile,
      param: param,
      completion: (response) {
        var users = UsersModel.fromJson(response).data;
        if (users != null) {
          completion(users);
        }
      },
    );
  }

  void fetchBlockedUserList(Function(List<User> users) completion) {
    var param = {
      Param.myUserId: SessionManager.shared.getUserID(),
      Param.limit: Limits.pagination,
    };

    ApiService.shared.call(
      url: WebService.fetchBlockedUserList,
      param: param,
      completion: (response) {
        var users = UsersModel.fromJson(response).data;
        if (users != null) {
          completion(users);
        }
      },
    );
  }

  void profileVerification(
      String fullName, String documentType, XFile? document, XFile? selfie) {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.fullName: fullName,
      Param.documentType: documentType,
    };

    ApiService.shared.multiPartCallApi(
      url: WebService.profileVerification,
      param: param,
      filesMap: {
        Param.document: [document],
        Param.selfie: [selfie]
      },
      completion: (response) {
        var obj = CommonResponse.fromJson(response);
        if (obj.status == true) {
          var user = SessionManager.shared.getUser();
          user?.isVerified = 1;
          SessionManager.shared.setUser(user);
          Get.back();
          Get.back();
          BaseController.share.showSnackBar(
              LKeys.profileVerificationRequestSent.tr,
              type: SnackBarType.success);
        }
      },
    );
  }

  Future<void> reportUser(num userId, String reason, String desc) async {
    Map<String, dynamic> param = {
      Param.myUserId: SessionManager.shared.getUserID(),
      Param.userId: userId,
      Param.reason: reason,
      Param.desc: desc,
    };
    _addActingCompanyId(param);

    await ApiService.shared.call(
      url: WebService.reportUser,
      param: param,
      completion: (response) {
        var obj = CommonResponse.fromJson(response);
        if (obj.status == true) {
          Get.back();
          Get.back();
          BaseController.share.showSnackBar(LKeys.reportAddedSuccessfully.tr,
              type: SnackBarType.success);
        } else {
          BaseController.share.showSnackBar(obj.message ?? "Report failed",
              type: SnackBarType.error);
        }
      },
    );
  }

  Future<bool> followUser(num userId, Function() completion) async {
    Map<String, dynamic> param = {
      Param.userId: userId,
      Param.myUserId: SessionManager.shared.getUserID()
    };
    _addActingCompanyId(param);
    await ApiService.shared.call(
      url: WebService.followUser,
      param: param,
      completion: (response) {
        var obj = CommonResponse.fromJson(response);
        if (obj.status == true) {
          completion();
          return true;
        }
      },
    );

    return false;
  }

  void blockUser(num userId, Function() completion) {
    Map<String, dynamic> param = {
      Param.userId: userId,
      Param.myUserId: SessionManager.shared.getUserID()
    };
    ApiService.shared.call(
      url: WebService.userBlockedByUser,
      param: param,
      completion: (response) {
        var obj = CommonResponse.fromJson(response);
        if (obj.status == true) {
          completion();
        }
      },
    );
  }

  void unblockUser(num userId, Function() completion) {
    Map<String, dynamic> param = {
      Param.userId: userId,
      Param.myUserId: SessionManager.shared.getUserID()
    };
    ApiService.shared.call(
      url: WebService.userUnBlockedByUser,
      param: param,
      completion: (response) {
        var obj = Registration.fromJson(response);
        if (obj.status == true) {
          SessionManager.shared.setUser(obj.data);
          completion();
        }
      },
    );
  }

  Future<bool> unfollowUser(num userId, Function() completion) async {
    Map<String, dynamic> param = {
      Param.userId: userId,
      Param.myUserId: SessionManager.shared.getUserID()
    };
    _addActingCompanyId(param);
    await ApiService.shared.call(
      url: WebService.unfollowUser,
      param: param,
      completion: (response) {
        var obj = CommonResponse.fromJson(response);
        if (obj.status == true) {
          completion();
          return true;
        }
      },
    );

    return false;
  }

  Future<void> fetchProfile(int userID, Function(User user) completion) async {
    Map<String, dynamic> param = {
      Param.myUserId: SessionManager.shared.getUserID(),
      Param.userId: userID.toString()
    };
    _addActingCompanyId(param);

    await ApiService.shared.call(
      param: param,
      url: WebService.fetchProfile,
      completion: (p0) {
        var user = Registration.fromJson(p0).data;
        if (user != null) {
          completion(user);
        }
      },
    );
  }

  void fetchMyProfile(
      {required num userID,
      int? myUserId,
      required Function(User user) completion}) {
    Map<String, dynamic> param = {
      Param.myUserId: myUserId ?? SessionManager.shared.getUserID(),
      Param.userId: userID.toString()
    };
    _addActingCompanyId(param);

    ApiService.shared.call(
      param: param,
      url: WebService.fetchProfile,
      completion: (p0) {
        var user = Registration.fromJson(p0).data;
        if (user != null) {
          completion(user);
        }
      },
    );
  }

  void fetchRandomProfile(Function(User user) completion,
      {Function()? onNotFound}) {
    var param = {Param.myUserId: SessionManager.shared.getUserID()};
    ApiService.shared.call(
      url: WebService.fetchRandomProfile,
      param: param,
      completion: (response) {
        User? user = Registration.fromJson(response).data;
        if (user != null) {
          completion(user);
        } else {
          onNotFound?.call();
        }
      },
    );
  }

  void logOut(Function() completion) {
    var param = {Param.userId: SessionManager.shared.getUserID()};
    ApiService.shared.call(
      url: WebService.logOut,
      param: param,
      completion: (data) {
        var obj = CommonResponse.fromJson(data).status;
        if (obj == true) {
          SessionManager.shared.clearApiAuthToken();
          completion();
        }
      },
    );
  }

  void deleteUser(Function() completion) {
    var param = {Param.userId: SessionManager.shared.getUserID()};
    ApiService.shared.call(
      url: WebService.deleteUser,
      param: param,
      completion: (data) {
        var obj = CommonResponse.fromJson(data).status;
        if (obj == true) {
          completion();
        }
      },
    );
  }

  void checkForUsername(String username, Function(bool) completion) {
    ApiService.shared.call(
        url: WebService.checkUsername,
        param: {Param.username: username},
        completion: (value) {
          var response = CommonResponse.fromJson(value);
          completion(response.status ?? false);
        });
  }

  void editProfile({
    String? username,
    String? fullName,
    String? bio,
    List<Interest>? interests,
    XFile? profileImage,
    XFile? bgImage,
    String? blockUserIds,
    bool? isPushNotifications,
    bool? isInvitedToRoom,
    int? isVerified,
    List<int>? savedMusicIds,
    List<int>? savedReelsIds,
    List<int>? savedPostIds,
    String? headline,
    String? about,
    String? experience,
    String? education,
    String? skills,
    String? location,
    String? website,
    String? pronouns,
    String? deviceToken,
    Function(User)? completion,
  }) {
    Map<String, Object> param = {
      Param.userId: SessionManager.shared.getUserID()
    };

    if (username != null) {
      param[Param.username] = username;
    }

    if (fullName != null) {
      param[Param.fullName] = fullName;
    }

    if (bio != null) {
      param[Param.bio] = bio;
    }

    if (isVerified != null) {
      param[Param.isVerified] = isVerified;
    }

    if (fullName != null) {
      param[Param.fullName] = fullName;
    }

    if (blockUserIds != null) {
      param[Param.blockUserIds] = blockUserIds;
    }
    if (isPushNotifications != null) {
      param[Param.isPushNotifications] = isPushNotifications ? 1 : 0;
    }
    if (isInvitedToRoom != null) {
      param[Param.isInvitedToRoom] = isInvitedToRoom ? 1 : 0;
    }

    if (savedMusicIds != null) {
      param[Param.savedMusicIds] =
          (savedMusicIds).map((e) => "${e}").toList().join(",");
    }

    if (savedReelsIds != null) {
      param[Param.savedReelIds] =
          (savedReelsIds).map((e) => "${e}").toList().join(",");
    }

    if (savedPostIds != null) {
      param[Param.savedPostIds] =
          (savedPostIds).map((e) => "${e}").toList().join(",");
    }

    if (interests?.isNotEmpty == true) {
      var str = (interests ?? []).map((e) => "${e.id ?? 0}").toList().join(",");
      param[Param.interestIds] = str;
    }

    if (headline != null) {
      param[Param.headline] = headline;
    }
    if (about != null) {
      param[Param.about] = about;
    }
    if (experience != null) {
      param[Param.experience] = experience;
    }
    if (education != null) {
      param[Param.education] = education;
    }
    if (skills != null) {
      param[Param.skills] = skills;
    }
    if (location != null) {
      param[Param.location] = location;
    }
    if (website != null) {
      param[Param.website] = website;
    }
    if (pronouns != null) {
      param[Param.pronouns] = pronouns;
    }
    if (deviceToken != null) {
      param[Param.deviceToken] = deviceToken;
    }

    ApiService.shared.multiPartCallApi(
      url: WebService.editProfile,
      param: param,
      filesMap: {
        Param.profile: [profileImage],
        Param.backgroundImage: [bgImage]
      },
      completion: (data) {
        var user = Registration.fromJson(data).data;
        if (user != null) {
          SessionManager.shared.setUser(user);
          completion?.call(user);
        }
      },
    );
  }

  void registration(
      {String? name,
      required String identity,
      required String deviceToken,
      required LoginType loginType,
      required Function(Registration) completion}) async {
    Map<String, String> map = {};
    if (name != null) {
      map[Param.fullName] = name;
    }
    map[Param.identity] = identity;
    map[Param.deviceToken] = deviceToken;
    map[Param.loginType] = loginType.value.toString();
    map[Param.deviceType] = (GetPlatform.isIOS ? 1 : 0).toString();

    ApiService.shared.call(
      url: WebService.addUser,
      param: map,
      completion: (p0) {
        var registration = Registration.fromJson(p0);
        var user = registration.data;
        if (user != null) {
          SessionManager.shared.setApiAuthToken(registration.authToken);
          SessionManager.shared.setUser(user);
          completion(registration);
        }
      },
    );
  }
}
