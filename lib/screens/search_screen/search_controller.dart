import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/post_service.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/controller/cupertino_controller.dart';
import 'package:untitled/common/managers/my_debouncer.dart';
import 'package:untitled/common/utils/input_sanitizer.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/chat.dart';
import 'package:untitled/models/posts_model.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/search_hashtags_model.dart';
import 'package:untitled/screens/audio_space/models/audio_space_user.dart';

class SearchScreenController extends CupertinoController {
  List<User> users = [];
  List<Post> posts = [];
  RxList<Reel> reels = RxList();
  List<SearchTag> tags = [];
  List<SearchTag> filterTags = [];
  List<AudioSpaceUser> selectedUsers = [];
  TextEditingController textEditingController = TextEditingController();

  var allPages = {
    0: LKeys.users,
    1: LKeys.posts,
    2: LKeys.reels,
    3: LKeys.hashtags,
  };

  @override
  void onReady() {
    super.onReady();
    searchUser();
    searchPost();
    searchReel();
    fetchAllHashtags();
  }

  void onSearchTextChanged() {
    MyDebouncer.shared.run(() {
      _performSearch();
    });
  }

  void _performSearch() {
    textEditingController.text = InputSanitizer.sanitizeSearch(textEditingController.text);
    searchUser(shouldErase: true);
    searchPost(shouldErase: true);
    searchReel(shouldErase: true);
    searchHashtags();
  }

  void fetchAllHashtags() async {
    try {
      await PostService.shared.searchHashtags(
        textEditingController.text,
        tags.length,
        (newTags) {
          tags = newTags;
          filterTags = newTags;
          update();
        },
      );
    } catch (_) {}
  }

  void searchHashtags({bool shouldErase = false}) {
    String searchText = textEditingController.text.toLowerCase();
    if (searchText.isEmpty) {
      filterTags = tags;
    } else {
      filterTags = tags.where((element) {
        return element.tag?.toLowerCase().contains(searchText) ?? false;
      }).toList();
    }
    update();
  }

  Future<void> searchReel({bool shouldErase = false}) async {
    String searchText = textEditingController.text;
    if (shouldErase) {
      reels.clear();
    }
    isLoading.value = true;
    try {
      var newReels = await ReelService.shared.searchReels(start: reels.length, keyword: searchText);
      reels.addAll(newReels);
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }

  Future<void> searchPost({bool shouldErase = false}) async {
    String searchText = textEditingController.text;
    if (shouldErase) {
      posts = [];
    }
    isLoading.value = true;

    try {
      await PostService.shared.searchPosts(
        searchText,
        posts.length,
        (newPosts) {
          isLoading.value = false;
          if (shouldErase) {
            posts = newPosts;
          } else {
            posts.addAll(newPosts);
          }
          update();
        },
      );
    } catch (_) {
      isLoading.value = false;
      update();
    }
  }

  Future<void> searchUser({bool shouldErase = false}) async {
    String searchText = textEditingController.text;
    if (shouldErase) {
      users = [];
    }
    isLoading.value = true;

    try {
      await UserService.shared.searchProfile(
        searchText,
        users.length,
        (newUsers) {
          isLoading.value = false;
          if (shouldErase) {
            users = newUsers;
          } else {
            users.addAll(newUsers);
          }
          update();
        },
      );
    } catch (_) {
      isLoading.value = false;
      update();
    }
  }

  @override
  void onClose() {
    textEditingController.dispose();
    super.onClose();
  }

  /// FOR AUDIO SPACE
  bool isUserSelected(User user) {
    return selectedUsers.any((element) => element.id?.toInt() == user.id?.toInt());
  }

  void addAndRemoveUser(User user) {
    if (isUserSelected(user)) {
      selectedUsers.removeWhere((element) => element.id?.toInt() == user.id?.toInt());
    } else {
      selectedUsers.add(user.toAudioSpaceUser(AudioSpaceUserType.added));
    }
    update();
  }
}
