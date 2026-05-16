import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/models/posts_model.dart';
import 'package:untitled/models/registration.dart';

extension PostModelExtension on Post {
  bool get isSaved => SessionManager.shared.getUser()?.getSavedPostIdsList().contains(this.id ?? 0) ?? false;

  void saveToggle() {
    var user = SessionManager.shared.getUser();
    var newIds = (user?.getSavedPostIdsList() ?? []);
    if (isSaved) {
      newIds.removeWhere((element) => element == id);
    } else {
      newIds.add(id?.toInt() ?? 0);
    }
    user?.savedPostIds = newIds.join(',');
    SessionManager.shared.setUser(user);
  }

  bool get isMyPost => userId == SessionManager.shared.getUserID();
}
