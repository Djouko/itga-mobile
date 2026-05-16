import 'package:untitled/common/api_service/post_service.dart';
import 'package:untitled/common/managers/connectivity_service.dart';
import 'package:untitled/screens/feed_screen/feed_screen_controller.dart';

class SinglePostController extends FeedScreenController {
  int postId;

  SinglePostController(this.postId);

  @override
  void onReady() {
    fetchPost();
    ConnectivityService.instance.addOnBackOnline('single_post_$postId', () {
      if (hasNetworkError) {
        hasNetworkError = false;
        fetchPost();
      }
    });
    super.onReady();
  }

  @override
  void onClose() {
    ConnectivityService.instance.removeOnBackOnline('single_post_$postId');
    super.onClose();
  }

  void fetchPost() {
    isLoading.value = true;
    hasNetworkError = false;
    update();
    try {
      PostService.shared.fetchPost(postId, (post) {
        isLoading.value = false;
        if (post == null) {
          hasNetworkError = true;
          update();
          return;
        }
        hasNetworkError = false;
        posts.clear();
        posts.add(post);
        update();
      });
    } catch (_) {
      isLoading.value = false;
      hasNetworkError = true;
      update();
    }
  }
}
