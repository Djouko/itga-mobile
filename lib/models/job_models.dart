import 'dart:convert';

import 'package:untitled/models/registration.dart';

// ─── Company ────────────────────────────────────────────────────────────────

class Company {
  int? id;
  int? ownerUserId;
  String? name;
  String? email;
  String? logo;
  String? description;
  String? sector;
  String? rseCommitments;
  String? website;
  String? phone;
  String? city;
  String? country;
  int? companySize;
  int? isVerified;
  int? isSuspended;
  String? deviceToken;
  String? createdAt;
  String? updatedAt;
  int? publishedOffersCount;
  int? jobOffersCount;
  int? followersCount;
  int? isFollowing;

  Company({
    this.id,
    this.ownerUserId,
    this.name,
    this.email,
    this.logo,
    this.description,
    this.sector,
    this.rseCommitments,
    this.website,
    this.phone,
    this.city,
    this.country,
    this.companySize,
    this.isVerified,
    this.isSuspended,
    this.deviceToken,
    this.createdAt,
    this.updatedAt,
    this.publishedOffersCount,
    this.jobOffersCount,
    this.followersCount,
    this.isFollowing,
  });

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        id: json['id'],
        ownerUserId: json['owner_user_id'] is int
            ? json['owner_user_id']
            : int.tryParse(json['owner_user_id']?.toString() ?? ''),
        name: json['name'],
        email: json['email'],
        logo: json['logo'],
        description: json['description'],
        sector: json['sector'],
        rseCommitments: json['rse_commitments'],
        website: json['website'],
        phone: json['phone'],
        city: json['city'],
        country: json['country'],
        companySize: json['company_size'],
        isVerified: json['is_verified'],
        isSuspended: json['is_suspended'],
        deviceToken: json['device_token'],
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
        publishedOffersCount: json['published_offers_count'],
        jobOffersCount: json['job_offers_count'],
        followersCount: json['followers_count'],
        isFollowing: json['is_following'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_user_id': ownerUserId,
        'name': name,
        'email': email,
        'logo': logo,
        'description': description,
        'sector': sector,
        'rse_commitments': rseCommitments,
        'website': website,
        'phone': phone,
        'city': city,
        'country': country,
        'company_size': companySize,
        'is_verified': isVerified,
        'is_suspended': isSuspended,
        'device_token': deviceToken,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'published_offers_count': publishedOffersCount,
        'job_offers_count': jobOffersCount,
        'followers_count': followersCount,
        'is_following': isFollowing,
      };
}

// ─── JobOffer ───────────────────────────────────────────────────────────────

class JobOffer {
  int? id;
  int? companyId;
  String? title;
  String? contractType;
  String? locationType;
  String? locationCity;
  String? domain;
  String? description;
  String? missions;
  List<String>? requiredSkills;
  num? salaryMin;
  num? salaryMax;
  String? salaryPeriod;
  String? experienceLevel;
  String? deadline;
  String? status;
  int? isFeatured;
  int? viewsCount;
  int? applicationsCount;
  String? createdAt;
  String? updatedAt;
  Company? company;
  int? isSaved;
  int? isApplied;
  num? matchScore;
  int? isMatch;
  String? applicationStatus;

  JobOffer({
    this.id,
    this.companyId,
    this.title,
    this.contractType,
    this.locationType,
    this.locationCity,
    this.domain,
    this.description,
    this.missions,
    this.requiredSkills,
    this.salaryMin,
    this.salaryMax,
    this.salaryPeriod,
    this.experienceLevel,
    this.deadline,
    this.status,
    this.isFeatured,
    this.viewsCount,
    this.applicationsCount,
    this.createdAt,
    this.updatedAt,
    this.company,
    this.isSaved,
    this.isApplied,
    this.matchScore,
    this.isMatch,
    this.applicationStatus,
  });

  factory JobOffer.fromJson(Map<String, dynamic> json) {
    List<String>? skills;
    if (json['required_skills'] is List) {
      skills = List<String>.from(json['required_skills']);
    } else if (json['required_skills'] is String) {
      try {
        final decoded = jsonDecode(json['required_skills']);
        if (decoded is List) {
          skills = List<String>.from(decoded);
        }
      } catch (_) {}
    }

    return JobOffer(
      id: json['id'],
      companyId: json['company_id'],
      title: json['title'],
      contractType: json['contract_type'],
      locationType: json['location_type'],
      locationCity: json['location_city'],
      domain: json['domain'],
      description: json['description'],
      missions: json['missions'],
      requiredSkills: skills,
      salaryMin: json['salary_min'],
      salaryMax: json['salary_max'],
      salaryPeriod: json['salary_period'],
      experienceLevel: json['experience_level'],
      deadline: json['deadline'],
      status: json['status'],
      isFeatured: json['is_featured'],
      viewsCount: json['views_count'],
      applicationsCount: json['applications_count'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      company: json['company'] != null ? Company.fromJson(json['company']) : null,
      isSaved: json['is_saved'],
      isApplied: json['is_applied'],
      matchScore: json['match_score'],
      isMatch: json['is_match'],
      applicationStatus: json['application_status'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'title': title,
        'contract_type': contractType,
        'location_type': locationType,
        'location_city': locationCity,
        'domain': domain,
        'description': description,
        'missions': missions,
        'required_skills': requiredSkills,
        'salary_min': salaryMin,
        'salary_max': salaryMax,
        'salary_period': salaryPeriod,
        'experience_level': experienceLevel,
        'deadline': deadline,
        'status': status,
        'is_featured': isFeatured,
        'views_count': viewsCount,
        'applications_count': applicationsCount,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'company': company?.toJson(),
        'is_saved': isSaved,
        'is_applied': isApplied,
        'match_score': matchScore,
        'is_match': isMatch,
        'application_status': applicationStatus,
      };
}

// ─── JobApplication ─────────────────────────────────────────────────────────

class JobApplication {
  int? id;
  int? userId;
  int? jobOfferId;
  String? coverLetter;
  String? cvFile;
  String? status;
  String? companyNote;
  String? createdAt;
  String? updatedAt;
  User? user;
  JobOffer? jobOffer;

  JobApplication({
    this.id,
    this.userId,
    this.jobOfferId,
    this.coverLetter,
    this.cvFile,
    this.status,
    this.companyNote,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.jobOffer,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) => JobApplication(
        id: json['id'],
        userId: json['user_id'],
        jobOfferId: json['job_offer_id'],
        coverLetter: json['cover_letter'],
        cvFile: json['cv_file'],
        status: json['status'],
        companyNote: json['company_note'],
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
        user: json['user'] != null ? User.fromJson(json['user']) : null,
        jobOffer: json['job_offer'] != null ? JobOffer.fromJson(json['job_offer']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'job_offer_id': jobOfferId,
        'cover_letter': coverLetter,
        'cv_file': cvFile,
        'status': status,
        'company_note': companyNote,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'user': user?.toJson(),
        'job_offer': jobOffer?.toJson(),
      };
}

// ─── Response wrappers ──────────────────────────────────────────────────────

class JobOffersResponse {
  bool? status;
  String? message;
  List<JobOffer>? data;

  JobOffersResponse({this.status, this.message, this.data});

  factory JobOffersResponse.fromJson(Map<String, dynamic> json) => JobOffersResponse(
        status: json['status'],
        message: json['message'],
        data: json['data'] == null ? [] : List<JobOffer>.from(json['data'].map((x) => JobOffer.fromJson(x))),
      );
}

class JobOfferDetailResponse {
  bool? status;
  String? message;
  JobOffer? data;

  JobOfferDetailResponse({this.status, this.message, this.data});

  factory JobOfferDetailResponse.fromJson(Map<String, dynamic> json) => JobOfferDetailResponse(
        status: json['status'],
        message: json['message'],
        data: json['data'] != null ? JobOffer.fromJson(json['data']) : null,
      );
}

class JobApplicationsResponse {
  bool? status;
  String? message;
  List<JobApplication>? data;

  JobApplicationsResponse({this.status, this.message, this.data});

  factory JobApplicationsResponse.fromJson(Map<String, dynamic> json) => JobApplicationsResponse(
        status: json['status'],
        message: json['message'],
        data: json['data'] == null ? [] : List<JobApplication>.from(json['data'].map((x) => JobApplication.fromJson(x))),
      );
}

class CompanyAuthResponse {
  bool? status;
  String? message;
  String? errorCode;
  String? authToken;
  Company? data;
  User? ownerUser;
  bool? ownerUserAutoCreated;
  bool? ownerUserAutoLinked;

  CompanyAuthResponse({
    this.status,
    this.message,
    this.errorCode,
    this.authToken,
    this.data,
    this.ownerUser,
    this.ownerUserAutoCreated,
    this.ownerUserAutoLinked,
  });

  factory CompanyAuthResponse.fromJson(Map<String, dynamic> json) => CompanyAuthResponse(
        status: json['status'],
        message: json['message'],
        errorCode: json['error_code'],
        authToken: json['auth_token'],
        data: json['data'] != null ? Company.fromJson(json['data']) : null,
        ownerUser: json['owner_user'] != null ? User.fromJson(json['owner_user']) : null,
        ownerUserAutoCreated: json['owner_user_auto_created'],
        ownerUserAutoLinked: json['owner_user_auto_linked'],
      );
}

class CompanyDashboardResponse {
  bool? status;
  String? message;
  CompanyDashboardData? data;

  CompanyDashboardResponse({this.status, this.message, this.data});

  factory CompanyDashboardResponse.fromJson(Map<String, dynamic> json) => CompanyDashboardResponse(
        status: json['status'],
        message: json['message'],
        data: json['data'] != null ? CompanyDashboardData.fromJson(json['data']) : null,
      );
}

class CompanyDashboardData {
  Company? company;
  DashboardStats? stats;
  List<JobOffer>? recentOffers;

  CompanyDashboardData({this.company, this.stats, this.recentOffers});

  factory CompanyDashboardData.fromJson(Map<String, dynamic> json) => CompanyDashboardData(
        company: json['company'] != null ? Company.fromJson(json['company']) : null,
        stats: json['stats'] != null ? DashboardStats.fromJson(json['stats']) : null,
        recentOffers: json['recent_offers'] == null
            ? []
            : List<JobOffer>.from(json['recent_offers'].map((x) => JobOffer.fromJson(x))),
      );
}

class DashboardStats {
  int? totalOffers;
  int? publishedOffers;
  int? draftOffers;
  int? totalApplications;
  int? totalViews;

  DashboardStats({this.totalOffers, this.publishedOffers, this.draftOffers, this.totalApplications, this.totalViews});

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        totalOffers: json['total_offers'],
        publishedOffers: json['published_offers'],
        draftOffers: json['draft_offers'],
        totalApplications: json['total_applications'],
        totalViews: json['total_views'],
      );
}

class CompanyPublicProfileData {
  Company? company;
  List<JobOffer>? jobs;

  CompanyPublicProfileData({this.company, this.jobs});

  factory CompanyPublicProfileData.fromJson(Map<String, dynamic> json) => CompanyPublicProfileData(
        company: json['company'] != null ? Company.fromJson(json['company']) : null,
        jobs: json['jobs'] == null
            ? []
            : List<JobOffer>.from(json['jobs'].map((x) => JobOffer.fromJson(x))),
      );
}

class CompanyPublicProfileResponse {
  bool? status;
  String? message;
  CompanyPublicProfileData? data;

  CompanyPublicProfileResponse({this.status, this.message, this.data});

  factory CompanyPublicProfileResponse.fromJson(Map<String, dynamic> json) => CompanyPublicProfileResponse(
        status: json['status'],
        message: json['message'],
        data: json['data'] != null ? CompanyPublicProfileData.fromJson(json['data']) : null,
      );
}

class CompanyFollowResponse {
  bool? status;
  String? message;
  int? followersCount;
  int? isFollowing;

  CompanyFollowResponse({this.status, this.message, this.followersCount, this.isFollowing});

  factory CompanyFollowResponse.fromJson(Map<String, dynamic> json) => CompanyFollowResponse(
        status: json['status'],
        message: json['message'],
        followersCount: json['followers_count'],
        isFollowing: json['is_following'],
      );
}

class CompanyListResponse {
  bool? status;
  String? message;
  List<Company>? data;

  CompanyListResponse({this.status, this.message, this.data});

  factory CompanyListResponse.fromJson(Map<String, dynamic> json) => CompanyListResponse(
        status: json['status'],
        message: json['message'],
        data: json['data'] == null
            ? []
            : List<Company>.from(json['data'].map((x) => Company.fromJson(x))),
      );
}
