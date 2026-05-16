import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/moderator_service.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/managers/connectivity_service.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/managers/share_manager.dart';
import 'package:untitled/common/widgets/functions.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/story.dart';
import 'package:untitled/screens/feed_screen/feed_screen_controller.dart';
import 'package:untitled/screens/follow_button/follow_controller.dart';
import 'package:untitled/utilities/const.dart';

import '../sheets/confirmation_sheet.dart';

class ProfileController extends FeedScreenController {
  User? user;
  final int userID;
  String followBtnID = "follow_btn";

  double maxExtent = 250.0;
  double currentExtent = 250.0;
  final bool isFromTabBar;
  final idForImage = '${DateTime.now().microsecondsSinceEpoch}';

  RxInt selectedPage = 0.obs;
  RxList<Reel> reels = RxList();

  PageController pageController = PageController(initialPage: 0);

  // ScrollController newScrollController = ScrollController();

  ProfileController(this.userID, this.isFromTabBar);

  double _lastReportedExtent = 250.0;

  User _profileDisplayUser(User source) {
    final displayUser = User();
    displayUser.id = source.id;
    displayUser.identity = source.identity;
    displayUser.username = source.username;
    displayUser.fullName = source.fullName;
    displayUser.bio = source.bio;
    displayUser.interestIds = source.interestIds;
    displayUser.profile = source.profile;
    displayUser.backgroundImage = source.backgroundImage;
    displayUser.isPushNotifications = source.isPushNotifications;
    displayUser.isInvitedToRoom = source.isInvitedToRoom;
    displayUser.isVerified = source.isVerified;
    displayUser.isBlock = source.isBlock;
    displayUser.blockUserIds = source.blockUserIds;
    displayUser.following = source.following;
    displayUser.followers = source.followers;
    displayUser.loginType = source.loginType;
    displayUser.deviceType = source.deviceType;
    displayUser.deviceToken = source.deviceToken;
    displayUser.createdAt = source.createdAt;
    displayUser.updatedAt = source.updatedAt;
    displayUser.headline = source.headline;
    displayUser.about = source.about;
    displayUser.experience = source.experience;
    displayUser.education = source.education;
    displayUser.skills = source.skills;
    displayUser.location = source.location;
    displayUser.website = source.website;
    displayUser.pronouns = source.pronouns;
    displayUser.profileType = source.profileType;
    displayUser.ownedCompany = source.ownedCompany;
    displayUser.followingStatus = source.followingStatus;
    displayUser.isModerator = source.isModerator;
    displayUser.savedMusicIds = source.savedMusicIds;
    displayUser.savedReelIds = source.savedReelIds;
    displayUser.savedPostIds = source.savedPostIds;
    displayUser.interest = source.interest;
    displayUser.stories = List<Story>.from(source.stories ?? []);
    displayUser.companyStories = List<Story>.from(source.companyStories ?? []);
    final mergedStories = <Story>[
      ...(displayUser.stories ?? []),
      ...(displayUser.companyStories ?? []),
    ];
    if (mergedStories.isNotEmpty) {
      mergedStories.sort(_compareStories);
      displayUser.stories = mergedStories;
    }
    return displayUser;
  }

  int _compareStories(Story a, Story b) {
    final aDate = DateTime.tryParse(a.createdAt ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = DateTime.tryParse(b.createdAt ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final dateCompare = aDate.compareTo(bDate);
    if (dateCompare != 0) return dateCompare;
    return (a.id?.toInt() ?? 0).compareTo(b.id?.toInt() ?? 0);
  }

  void updateEverything() {
    update([scrollID]);
    update();
  }

  void updateMyProfile() {
    if (user?.id == SessionManager.shared.getUserID()) {
      final currentUser = SessionManager.shared.getUser();
      if (currentUser != null) {
        user = _profileDisplayUser(currentUser);
      }
      update();
      update([scrollID]);
    }
  }

  void getStories() {
    UserService.shared.fetchProfile(userID, (user) {
      if (user.id == SessionManager.shared.getUserID()) {
        SessionManager.shared.setUser(user);
      }
      this.user = _profileDisplayUser(user);
      update();
      update([scrollID]);
    });
  }

  Future<void> getProfile({bool isForRefresh = false}) async {
    if (!isForRefresh && !isFromTabBar) {
      isLoading.value = true;
      update();
    }
    try {
      await UserService.shared.fetchProfile(userID, (user) {
        final displayUser = _profileDisplayUser(user);
        this.user = displayUser;

        if (Get.isRegistered<FollowController>(tag: '${displayUser.id}')) {
          var controller = Get.find<FollowController>(tag: '${displayUser.id}');
          controller.user.value = displayUser;
        }

        if (user.id == SessionManager.shared.getUserID()) {
          SessionManager.shared.setUser(user);
        }
        hasNetworkError = false;
        isLoading.value = false;
        update();
        update([scrollID]);
      });
    } catch (_) {
      hasNetworkError = true;
      isLoading.value = false;
      update();
    }
  }

  @override
  void onReady() {
    super.onReady();
    user = User(id: userID);
    getProfile();
    if (!(user?.isBlockedByMe() ?? false)) {
      fetchUserPosts(userID: userID);
      fetchReels();
    }
    ConnectivityService.instance.addOnBackOnline('profile_$hashCode', () {
      if (hasNetworkError) {
        hasNetworkError = false;
        getProfile(isForRefresh: true);
        fetchUserPosts(userID: userID, isForRefresh: true);
        fetchReels(shouldRefresh: true);
      }
    });
    scrollController?.addListener(() {
      final clamped =
          (maxExtent - scrollController!.offset).clamp(0.0, maxExtent);
      currentExtent = clamped;
      // Throttle: only rebuild header when extent changes by ≥5px (~60fps on 250px range = every ~4px)
      if ((clamped - _lastReportedExtent).abs() >= 5) {
        _lastReportedExtent = clamped;
        update([scrollID]);
      }
    });
  }

  bool isAllReelsFetched = false;

  Future<void> fetchReels({bool shouldRefresh = false}) async {
    if (shouldRefresh) {
      isAllReelsFetched = false;
      reels.clear();
    }
    if (isAllReelsFetched) return;
    try {
      var newReels = await ReelService.shared
          .fetchReelsByUser(userId: userId, start: reels.length);
      reels.addAll(newReels);
      if (newReels.length < Limits.pagination) {
        isAllReelsFetched = true;
      }
    } catch (_) {
      hasNetworkError = true;
      update();
    }
  }

  void blockByModerator() {
    Future.delayed(const Duration(milliseconds: 1), () {
      Get.bottomSheet(ConfirmationSheet(
        desc: LKeys.blockUserGloballyByModeratorDesc,
        buttonTitle: LKeys.block,
        onTap: () {
          ModeratorService.shared.blockUser(
              userId: userId,
              completion: () async {
                user?.followingStatus =
                    FollowController.unfollow(user)?.followingStatus;
                posts.clear();
                updateEverything();
                Get.back();
              });
        },
      ));
    });
  }

  void blockUnblock() {
    if (user?.isBlockedByMe() ?? false) {
      unblockUser(user, () {
        fetchUserPosts(userID: (user?.id ?? 0).toInt());
        updateEverything();
      });
    } else {
      blockUser(user, () async {
        user = FollowController.unfollow(user);
        posts.clear();
        updateEverything();
      });
    }
  }

  @override
  void onClose() {
    ConnectivityService.instance.removeOnBackOnline('profile_$hashCode');
    pageController.dispose();
    Functions.changStatusBar(StatusBarStyle.white);
    super.onClose();
  }

  void shareProfile() {
    ShareManager.shared
        .shareTheContent(key: ShareKeys.user, value: user?.id?.toInt() ?? 0);
  }

  void onChangeSegment(int value) {
    selectedPage.value = value;
    // controller.jumpToPage(value);
  }

  void deleteReel(Reel reel) {
    Get.bottomSheet(ConfirmationSheet(
      desc: LKeys.deleteReelDesc.tr,
      buttonTitle: LKeys.delete.tr,
      onTap: () {
        reels.removeWhere((element) => element.id == reel.id);
        ReelService.shared.deleteReel(reelId: reel.id ?? 0);
      },
    ));
  }

  void deleteReelByModerator(Reel reel) {
    Get.bottomSheet(ConfirmationSheet(
      desc: LKeys.deleteReelDesc,
      buttonTitle: LKeys.delete,
      onTap: () {
        reels.removeWhere((element) => element.id == reel.id);
        ModeratorService.shared.deleteReel(reelId: reel.id ?? 0);
      },
    ));
  }
}
