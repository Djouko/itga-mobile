import 'package:untitled/common/api_service/post_service.dart';
import 'package:untitled/screens/feed_screen/feed_screen_controller.dart';

class SavedPostsScreenController extends FeedScreenController {
  SavedPostsScreenController() : super(isFromFeedScreen: false);

  @override
  void onReady() {
    super.onReady();
    fetchSavedPosts();
  }

  Future<void> fetchSavedPosts({bool shouldRefresh = false}) async {
    isLoading.value = true;
    try {
      var newPosts = await PostService.shared.fetchSavedPosts(start: shouldRefresh ? 0 : posts.length);
      if (shouldRefresh) {
        posts.clear();
      }
      posts.addAll(newPosts);
      hasNetworkError = false;
    } catch (_) {
      hasNetworkError = true;
    } finally {
      isLoading.value = false;
      update();
    }
  }
}
