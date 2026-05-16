import 'package:untitled/common/api_service/story_service.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/story.dart';

class FeedStoriesController extends BaseController {
  List<User> storyUsers = [];
  User myUser = SessionManager.shared.getUser() ?? User();

  User _activeCompanyUser({List<Story>? stories}) {
    final companyId = SessionManager.shared.getActingCompanyId();
    final company = SessionManager.shared.getUser()?.ownedCompany;
    final companyName =
        SessionManager.shared.getActingCompanyName() ?? company?.name ?? '';
    return User(
      id: companyId,
      fullName: companyName,
      username: 'company-$companyId',
      profile: company?.logo,
      isVerified: company?.isVerified == 1 ? 2 : 0,
      profileType: 'company',
      ownedCompany: company,
      stories: stories ?? [],
    );
  }

  bool _isActiveCompanyStoryUser(User user) {
    final companyId = SessionManager.shared.getActingCompanyId();
    return companyId != null &&
        user.profileType == 'company' &&
        user.id?.toInt() == companyId;
  }

  @override
  void onReady() {
    fetchStories();
    fetchMyStories();
    super.onReady();
  }

  Future<void> fetchStories() async {
    await StoryService.shared.fetchStories((storyUsers) {
      this.storyUsers = storyUsers;
      if (SessionManager.shared.isCompanyActingMode()) {
        User? activeCompanyStoryUser;
        for (final user in this.storyUsers) {
          if (_isActiveCompanyStoryUser(user)) {
            activeCompanyStoryUser = user;
            break;
          }
        }
        myUser = activeCompanyStoryUser ?? _activeCompanyUser();
        this.storyUsers.removeWhere(_isActiveCompanyStoryUser);
      }
      this.storyUsers.sort((a, b) {
        if (a.isAllStoryShown()) {
          return 1;
        }
        return -1;
      });
      update();
    });
  }

  Future<void> fetchMyStories() async {
    if (SessionManager.shared.isCompanyActingMode()) {
      final activeStories =
          _isActiveCompanyStoryUser(myUser) ? myUser.stories : <Story>[];
      myUser = _activeCompanyUser(stories: activeStories);
      update();
      return;
    }
    await UserService.shared.fetchProfile(SessionManager.shared.getUserID(),
        (user) {
      myUser = user;
      update();
    });
  }
}
