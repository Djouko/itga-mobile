import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/post_service.dart';
import 'package:untitled/common/managers/connectivity_service.dart';
import 'package:untitled/models/posts_model.dart';
import 'package:untitled/models/room_model.dart';
import 'package:untitled/screens/chats_screen/chatting_screen/block_user_controller.dart';
import 'package:untitled/utilities/const.dart';

class FeedScreenController extends BlockUserController {
  // List<Feed> posts = [];
  String scrollID = "${DateTime.now().millisecondsSinceEpoch}scrollID";
  RxList<Post> posts = <Post>[].obs;
  List<Room> suggestedRooms = [];
  bool? isFromFeedScreen;
  String profileFeedID = "profileFeedID";
  String feedViewID = "feedViewID";
  ScrollController? scrollController = ScrollController();
  int userId = 0;
  RxInt selectedFeedType = 0.obs;

  FeedScreenController({this.isFromFeedScreen, this.scrollController}) {
    if (this.scrollController == null) {
      this.scrollController = ScrollController();
      _ownsScrollController = true;
    }
  }

  @override
  void onReady() {
    super.onReady();
    update();
    if (isFromFeedScreen == true) {
      fetchFeeds();
    }
    scrollController?.addListener(
      () {
        if (scrollController!.offset ==
            scrollController!.position.maxScrollExtent) {
          if (!isLoading.value) {
            if ((isFromFeedScreen ?? false) == true) {
              fetchFeeds();
            } else {
              fetchUserPosts(userID: userId);
            }
          }
        }
      },
    );

    // Auto-retry: reload when network comes back after a failure
    ConnectivityService.instance.addOnBackOnline('feed_$hashCode', () {
      if (hasNetworkError) {
        fetchFeeds(isForRefresh: posts.isEmpty);
      }
    });
  }

  void switchFeedType(int type) {
    if (selectedFeedType.value == type) return;
    selectedFeedType.value = type;
    posts.clear();
    suggestedRooms = [];
    fetchFeeds();
  }

  bool _isFetchingFeeds = false;

  Future<void> fetchFeeds({bool isForRefresh = false}) async {
    if (_isFetchingFeeds && !isForRefresh) return;
    _isFetchingFeeds = true;
    final shouldFetchSuggestedRooms = isForRefresh || posts.isEmpty;
    isLoading.value = true;
    hasNetworkError = false;
    update();
    try {
      await PostService.shared.fetchPosts(
          shouldSendSuggestedRoom: shouldFetchSuggestedRooms,
          start: isForRefresh ? 0 : posts.length,
          feedTypeOverride:
              isFromFeedScreen == true ? selectedFeedType.value : null,
          onError: () {
            _isFetchingFeeds = false;
            isLoading.value = false;
            hasNetworkError = true;
            update();
          },
          completion: (posts, suggestedRooms) {
            _isFetchingFeeds = false;
            if (isForRefresh) {
              this.posts.clear();
              this.suggestedRooms = [];
            }

            if (shouldFetchSuggestedRooms) {
              this.suggestedRooms = suggestedRooms;
            }

            this.posts.addAll(posts);
            isLoading.value = false;
            hasNetworkError = false;
            update();
          });
    } catch (_) {
      _isFetchingFeeds = false;
      isLoading.value = false;
      hasNetworkError = true;
      update();
    }
  }

  bool _ownsScrollController = false;

  @override
  void onClose() {
    ConnectivityService.instance.removeOnBackOnline('feed_$hashCode');
    if (_ownsScrollController) {
      scrollController?.dispose();
    }
    super.onClose();
  }

  var isAllPostLoaded = false;

  Future<void> fetchUserPosts(
      {int? userID = null, bool isForRefresh = false}) async {
    if (isForRefresh) {
      isAllPostLoaded = false;
      posts.clear();
      update();
    }
    if (isAllPostLoaded) return;
    if (userID != null) {
      userId = userID;
    }
    try {
      await PostService.shared.fetchUserPosts(userId, posts.length, (posts) {
        this.posts.addAll(posts);
        if (posts.length < Limits.pagination) {
          isAllPostLoaded = true;
        }
        hasNetworkError = false;
        update();
      });
    } catch (_) {
      isLoading.value = false;
      hasNetworkError = true;
      update();
    }
  }
}
