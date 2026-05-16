import 'package:get/get.dart';
import 'package:untitled/common/api_service/new_api_service.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/models/job_models.dart';
import 'package:untitled/utilities/params.dart';
import 'package:untitled/utilities/web_service.dart';

class CompanyService {
  static var shared = CompanyService();

  int? _currentUserId() {
    final id = SessionManager.shared.getUserID();
    return id > 0 ? id : null;
  }

  void _addFollowerCompanyId(Map<String, dynamic> param) {
    final companyId = SessionManager.shared.getActingCompanyId();
    if (companyId != null) {
      param[Param.followerCompanyId] = companyId;
    }
  }

  Future<CompanyAuthResponse> register({
    required String name,
    required String email,
    required String password,
    String? sector,
    String? deviceToken,
  }) async {
    var param = <String, dynamic>{
      Param.name: name,
      Param.email: email,
      Param.password: password,
    };
    if (sector != null && sector.isNotEmpty) param[Param.sector] = sector;
    if (deviceToken != null && deviceToken.isNotEmpty) {
      param[Param.deviceToken] = deviceToken;
      param[Param.deviceType] = GetPlatform.isIOS ? 1 : 0;
    }
    final userId = _currentUserId();
    if (userId != null) param[Param.userId] = userId;

    return await NewApiService.shared.call(
      url: WebService.companyRegister,
      param: param,
      fromJson: CompanyAuthResponse.fromJson,
    );
  }

  Future<CompanyAuthResponse> login({
    required String email,
    required String password,
    String? deviceToken,
  }) async {
    var param = <String, dynamic>{
      Param.email: email,
      Param.password: password,
    };
    if (deviceToken != null && deviceToken.isNotEmpty) {
      param[Param.deviceToken] = deviceToken;
      param[Param.deviceType] = GetPlatform.isIOS ? 1 : 0;
    }
    final userId = _currentUserId();
    if (userId != null) param[Param.userId] = userId;
    return await NewApiService.shared.call(
      url: WebService.companyLogin,
      param: param,
      fromJson: CompanyAuthResponse.fromJson,
    );
  }

  Future<CompanyAuthResponse> verifyEmail({
    required String email,
    required String code,
    String? deviceToken,
  }) async {
    final param = <String, dynamic>{Param.email: email, 'code': code};
    if (deviceToken != null && deviceToken.isNotEmpty) {
      param[Param.deviceToken] = deviceToken;
      param[Param.deviceType] = GetPlatform.isIOS ? 1 : 0;
    }
    final userId = _currentUserId();
    if (userId != null) param[Param.userId] = userId;
    return await NewApiService.shared.call(
      url: WebService.companyVerifyEmail,
      param: param,
      fromJson: CompanyAuthResponse.fromJson,
    );
  }

  Future<CompanyAuthResponse> resendVerification(
      {required String email}) async {
    return await NewApiService.shared.call(
      url: WebService.companyResendVerification,
      param: {Param.email: email},
      fromJson: CompanyAuthResponse.fromJson,
    );
  }

  Future<CompanyDashboardResponse> fetchDashboard(
      {required int companyId}) async {
    var param = <String, dynamic>{
      Param.companyId: companyId,
    };
    final userId = _currentUserId();
    if (userId != null) param[Param.userId] = userId;
    return await NewApiService.shared.call(
      url: WebService.companyFetchDashboard,
      param: param,
      fromJson: CompanyDashboardResponse.fromJson,
    );
  }

  Future<CompanyAuthResponse> fetchProfile({required int companyId}) async {
    var param = <String, dynamic>{
      Param.companyId: companyId,
    };
    final userId = _currentUserId();
    if (userId != null) param[Param.userId] = userId;
    return await NewApiService.shared.call(
      url: WebService.companyFetchProfile,
      param: param,
      fromJson: CompanyAuthResponse.fromJson,
    );
  }

  /// Public company profile + paginated published jobs.
  /// [userId] optional: when provided, response.company.isFollowing reflects
  /// whether the current user follows this company.
  Future<CompanyPublicProfileResponse> publicProfile({
    required int companyId,
    int? userId,
    int start = 0,
    int limit = 10,
  }) async {
    final param = <String, dynamic>{
      Param.companyId: companyId,
      Param.start: start,
      Param.limit: limit,
    };
    if (userId != null) param[Param.userId] = userId;
    _addFollowerCompanyId(param);
    return await NewApiService.shared.call(
      url: WebService.companyPublicProfile,
      param: param,
      fromJson: CompanyPublicProfileResponse.fromJson,
    );
  }

  Future<CompanyFollowResponse> followCompany({
    required int userId,
    required int companyId,
  }) async {
    final param = <String, dynamic>{
      Param.userId: userId,
      Param.companyId: companyId
    };
    _addFollowerCompanyId(param);
    return await NewApiService.shared.call(
      url: WebService.companyFollow,
      param: param,
      fromJson: CompanyFollowResponse.fromJson,
    );
  }

  Future<CompanyFollowResponse> unfollowCompany({
    required int userId,
    required int companyId,
  }) async {
    final param = <String, dynamic>{
      Param.userId: userId,
      Param.companyId: companyId
    };
    _addFollowerCompanyId(param);
    return await NewApiService.shared.call(
      url: WebService.companyUnfollow,
      param: param,
      fromJson: CompanyFollowResponse.fromJson,
    );
  }

  Future<CompanyListResponse> fetchFollowedCompanies({
    required int userId,
    int start = 0,
    int limit = 20,
  }) async {
    final param = <String, dynamic>{
      Param.userId: userId,
      Param.start: start,
      Param.limit: limit,
    };
    _addFollowerCompanyId(param);
    return await NewApiService.shared.call(
      url: WebService.companyFetchFollowed,
      param: param,
      fromJson: CompanyListResponse.fromJson,
    );
  }
}
