import 'package:untitled/common/api_service/post_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/models/registration.dart';

class PostRepostedUsersController extends BaseController {
  List<User> users = [];
  int postId;

  PostRepostedUsersController(this.postId);

  @override
  void onReady() {
    fetchUsers();
    super.onReady();
  }

  void fetchUsers() {
    startLoading();
    PostService.shared.fetchReposts(
      postId: postId,
      start: users.length,
      completion: (users) {
        stopLoading();
        this.users.addAll(users);
        update();
      },
    );
  }
}
