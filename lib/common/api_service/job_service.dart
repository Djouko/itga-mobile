import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/api_service/new_api_service.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/models/common_response.dart';
import 'package:untitled/models/job_models.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/params.dart';
import 'package:untitled/utilities/web_service.dart';

class JobService {
  static var shared = JobService();

  int? _currentUserId() {
    final id = SessionManager.shared.getUserID();
    return id > 0 ? id : null;
  }

  void _attachCompanyOwner(Map<String, dynamic> param) {
    final userId = _currentUserId();
    if (userId != null) param[Param.userId] = userId;
  }

  // ─── User-facing ────────────────────────────────────────────────────────

  Future<List<JobOffer>> fetchJobs({
    required int start,
    String? keyword,
    String? contractType,
    String? locationType,
    String? experienceLevel,
    String? domain,
    String? sortBy,
  }) async {
    var param = <String, dynamic>{
      Param.userId: SessionManager.shared.getUserID(),
      Param.start: start,
      Param.limit: Limits.pagination,
    };
    if (keyword != null && keyword.isNotEmpty) param[Param.keyword] = keyword;
    if (contractType != null) param[Param.contractType] = contractType;
    if (locationType != null) param[Param.locationType] = locationType;
    if (experienceLevel != null) param[Param.experienceLevel] = experienceLevel;
    if (domain != null) param[Param.domainField] = domain;
    if (sortBy != null) param[Param.sortBy] = sortBy;

    final response = await NewApiService.shared.call(
      url: WebService.fetchJobs,
      param: param,
      fromJson: JobOffersResponse.fromJson,
    );
    return response.data ?? [];
  }

  Future<JobOffer?> fetchJobDetail({required int jobId}) async {
    var param = {
      Param.jobOfferId: jobId,
      Param.userId: SessionManager.shared.getUserID(),
    };
    final response = await NewApiService.shared.call(
      url: WebService.fetchJobDetail,
      param: param,
      fromJson: JobOfferDetailResponse.fromJson,
    );
    return response.data;
  }

  Future<bool> toggleSaveJob({required int jobId}) async {
    var param = {
      Param.jobOfferId: jobId,
      Param.userId: SessionManager.shared.getUserID(),
    };
    final response = await NewApiService.shared.call(
      url: WebService.toggleSaveJob,
      param: param,
      fromJson: CommonResponse.fromJson,
    );
    return response.status == true;
  }

  Future<List<JobOffer>> fetchSavedJobs({required int start}) async {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.start: start,
      Param.limit: Limits.pagination,
    };
    final response = await NewApiService.shared.call(
      url: WebService.fetchSavedJobs,
      param: param,
      fromJson: JobOffersResponse.fromJson,
    );
    return response.data ?? [];
  }

  Future<bool> applyToJob({
    required int jobId,
    String? coverLetter,
    XFile? cvFile,
  }) async {
    var param = <String, dynamic>{
      Param.userId: SessionManager.shared.getUserID(),
      Param.jobOfferId: jobId,
    };
    if (coverLetter != null && coverLetter.isNotEmpty) {
      param[Param.coverLetter] = coverLetter;
    }

    if (cvFile != null) {
      final response = await NewApiService.shared.multiPartCallApi(
        url: WebService.applyToJob,
        param: param,
        filesMap: {Param.cvFile: [cvFile]},
        fromJson: CommonResponse.fromJson,
      );
      return response.status == true;
    } else {
      final response = await NewApiService.shared.call(
        url: WebService.applyToJob,
        param: param,
        fromJson: CommonResponse.fromJson,
      );
      return response.status == true;
    }
  }

  Future<List<JobApplication>> fetchMyApplications({required int start}) async {
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.start: start,
      Param.limit: Limits.pagination,
    };
    final response = await NewApiService.shared.call(
      url: WebService.fetchMyApplications,
      param: param,
      fromJson: JobApplicationsResponse.fromJson,
    );
    return response.data ?? [];
  }

  // ─── Company-facing ─────────────────────────────────────────────────────

  Future<List<JobOffer>> fetchCompanyJobs({required int companyId, required int start}) async {
    var param = <String, dynamic>{
      Param.companyId: companyId,
      Param.start: start,
      Param.limit: Limits.pagination,
    };
    _attachCompanyOwner(param);
    final response = await NewApiService.shared.call(
      url: WebService.fetchCompanyJobs,
      param: param,
      fromJson: JobOffersResponse.fromJson,
    );
    return response.data ?? [];
  }

  Future<bool> createJob({required int companyId, required Map<String, dynamic> data}) async {
    final payload = _normalizeJobPayload(data)..[Param.companyId] = companyId;
    _attachCompanyOwner(payload);
    final response = await NewApiService.shared.call(
      url: WebService.createJob,
      param: payload,
      fromJson: CommonResponse.fromJson,
    );
    return response.status == true;
  }

  Future<bool> editJob({required int jobId, required int companyId, required Map<String, dynamic> data}) async {
    final payload = _normalizeJobPayload(data)
      ..[Param.jobOfferId] = jobId
      ..[Param.companyId] = companyId;
    _attachCompanyOwner(payload);
    final response = await NewApiService.shared.call(
      url: WebService.editJob,
      param: payload,
      fromJson: CommonResponse.fromJson,
    );
    return response.status == true;
  }

  Future<bool> deleteJob({required int jobId, required int companyId}) async {
    var param = <String, dynamic>{
      Param.jobOfferId: jobId,
      Param.companyId: companyId,
    };
    _attachCompanyOwner(param);
    final response = await NewApiService.shared.call(
      url: WebService.deleteJob,
      param: param,
      fromJson: CommonResponse.fromJson,
    );
    return response.status == true;
  }

  Future<List<JobApplication>> fetchJobApplications({required int jobId, required int companyId, required int start}) async {
    var param = <String, dynamic>{
      Param.jobOfferId: jobId,
      Param.companyId: companyId,
      Param.start: start,
      Param.limit: Limits.pagination,
    };
    _attachCompanyOwner(param);
    final response = await NewApiService.shared.call(
      url: WebService.fetchJobApplications,
      param: param,
      fromJson: JobApplicationsResponse.fromJson,
    );
    return response.data ?? [];
  }

  Future<bool> updateApplicationStatus({required int applicationId, required int companyId, required String status}) async {
    var param = <String, dynamic>{
      Param.applicationId: applicationId,
      Param.companyId: companyId,
      Param.jobStatus: status,
    };
    _attachCompanyOwner(param);
    final response = await NewApiService.shared.call(
      url: WebService.updateApplicationStatus,
      param: param,
      fromJson: CommonResponse.fromJson,
    );
    return response.status == true;
  }

  Map<String, dynamic> _normalizeJobPayload(Map<String, dynamic> data) {
    final payload = Map<String, dynamic>.from(data);
    final skills = payload[Param.requiredSkills];
    if (skills is List) {
      payload[Param.requiredSkills] = jsonEncode(skills);
    }
    return payload;
  }
}
