import 'dart:convert';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/api_service/api_service.dart';
import 'package:untitled/common/api_service/new_api_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/comment_model.dart';
import 'package:untitled/models/comments_model.dart';
import 'package:untitled/models/common_response.dart';
import 'package:untitled/models/post_users_model.dart';
import 'package:untitled/models/posts_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/room_model.dart';
import 'package:untitled/models/search_hashtags_model.dart';
import 'package:untitled/models/single_feed_model.dart';
import 'package:untitled/models/upload_file.dart';
import 'package:untitled/screens/add_post_screen/add_post_controller.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/params.dart';
import 'package:untitled/utilities/web_service.dart';

class PostService {
  static var shared = PostService();

  User _companyAsUser({
    required int? companyId,
    required int? ownerUserId,
    required String? name,
    required String? logo,
    required String? description,
    required String? sector,
    required int? isVerified,
    required int? followersCount,
    String? email,
    String? website,
    String? city,
    String? country,
  }) {
    final ownedCompany = UserOwnedCompany(
      id: companyId,
      ownerUserId: ownerUserId,
      name: name,
      email: email,
      logo: logo,
      description: description,
      sector: sector,
      website: website,
      city: city,
      country: country,
      isVerified: isVerified,
      followersCount: followersCount,
    );

    return User(
      id: ownerUserId ?? 0,
      fullName: name ?? '',
      username: companyId == null ? 'company' : 'company-$companyId',
      bio: description,
      profile: logo,
      followers: followersCount ?? 0,
      following: 0,
      isVerified: isVerified ?? 0,
      isBlock: 0,
      isPushNotifications: 1,
      profileType: 'company',
      ownedCompany: ownedCompany,
    );
  }

  Future<void> searchPosts(
      String query, int start, Function(List<Post> posts) completion) async {
    final companyId = SessionManager.shared.getActingCompanyId();
    var param = {
      Param.keyword: query,
      Param.start: start,
      Param.limit: Limits.pagination,
      Param.userId: SessionManager.shared.getUserID(),
      if (companyId != null) Param.companyId: companyId,
    };
    await ApiService.shared.call(
        url: WebService.searchPost,
        param: param,
        completion: (response) {
          List<Post>? posts = PostsModel.fromJson(response).data;
          if (posts != null) {
            completion(posts);
          }
        });
  }

  Future<List<Post>> searchPostsWithInterest(
      {required String query,
      required int start,
      required num interestId}) async {
    final companyId = SessionManager.shared.getActingCompanyId();
    var param = {
      Param.keyword: query,
      Param.start: start,
      Param.limit: Limits.pagination,
      Param.userId: SessionManager.shared.getUserID(),
      Param.interestId: interestId,
      if (companyId != null) Param.companyId: companyId,
    };

    PostsModel model = await NewApiService.shared.call(
      url: WebService.searchPostByInterestId,
      param: param,
      fromJson: PostsModel.fromJson,
    );

    return model.data ?? [];
  }

  Future<void> searchHashtags(String query, int start,
      Function(List<SearchTag> posts) completion) async {
    var param = {
      Param.keyword: query,
      Param.start: start,
      Param.limit: Limits.pagination,
      Param.userId: SessionManager.shared.getUserID(),
    };
    await ApiService.shared.call(
        url: WebService.searchHashtag,
        param: param,
        completion: (response) {
          List<SearchTag>? posts = SearchHashtagsModel.fromJson(response).data;
          if (posts != null) {
            completion(posts);
          }
        });
  }

  void uploadFile(XFile file, Function(String) completion) {
    ApiService.shared.multiPartCallApi(
      url: WebService.uploadFile,
      filesMap: {
        'uploadFile': [file]
      },
      completion: (response) {
        String? fileURL = UploadFile.fromJson(response).data;
        if (fileURL != null) {
          completion(fileURL);
        }
      },
    );
  }

  Future<void> fetchPost(int postId, Function(Post? post) completion) async {
    final companyId = SessionManager.shared.getActingCompanyId();
    var param = {
      Param.postId: postId,
      Param.myUserId: SessionManager.shared.getUserID(),
      if (companyId != null) Param.companyId: companyId,
    };
    await ApiService.shared.call(
      url: WebService.fetchPostByPostId,
      param: param,
      completion: (response) {
        Post? post = SingleFeedModel.fromJson(response).data;
        completion(post);
      },
    );
  }

  Future<void> fetchPostsByHashtag(
      String tag, int start, Function(List<Post>) completion) async {
    final companyId = SessionManager.shared.getActingCompanyId();
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.start: start,
      Param.tag: tag,
      Param.limit: Limits.pagination.toString(),
      if (companyId != null) Param.companyId: companyId,
    };
    await ApiService.shared.call(
      param: param,
      url: WebService.fetchPostsByHashtag,
      completion: (data) {
        var obj = PostsModel.fromJson(data).data;
        if (obj != null) {
          completion(obj);
        }
      },
    );
  }

  void likeDislike(num commentId, Function(Comment comment) completion) {
    final companyId = SessionManager.shared.getActingCompanyId();
    var params = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.commentId: commentId,
      if (companyId != null) Param.companyId: companyId,
    };
    ApiService.shared.call(
      url: WebService.likeDislikeComment,
      param: params,
      completion: (response) {
        Comment? comment = CommentModel.fromJson(response).data;
        if (comment != null) {
          completion(comment);
        }
      },
    );
  }

  Future<void> editPost(
      {required int postId,
      required String desc,
      String? tags,
      required Function(Post post) completion}) async {
    final companyId = SessionManager.shared.getActingCompanyId();
    Map<String, dynamic> param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.postId: postId,
      Param.desc: desc,
      if (tags != null) Param.tags: tags,
      if (companyId != null) Param.companyId: companyId,
    };
    await ApiService.shared.call(
      url: WebService.editPost,
      param: param,
      completion: (response) {
        if (response['status'] == true && response['data'] != null) {
          completion(Post.fromJson(response['data']));
        }
      },
    );
  }

  Future<void> repostPost(
      {required int postId,
      String? desc,
      required Function(Post post) completion,
      Function()? onError}) async {
    final companyId = SessionManager.shared.getActingCompanyId();
    Map<String, dynamic> params = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.postId: postId,
      if (companyId != null) Param.companyId: companyId,
    };
    if (desc != null && desc.isNotEmpty) {
      params[Param.desc] = desc;
    }
    await ApiService.shared.call(
      url: WebService.repostPost,
      param: params,
      completion: (response) {
        if (response['status'] == true && response['data'] != null) {
          var post = Post.fromJson(response['data']);
          completion(post);
        } else {
          onError?.call();
        }
      },
    );
  }

  void fetchUsersWhoLikedPost(
      {required int postId, required Function(List<User> users) completion}) {
    Map<String, dynamic> param = {
      Param.postId: postId,
      Param.userId: SessionManager.shared.getUserID(),
    };
    ApiService.shared.call(
      url: WebService.fetchUsersWhoLikedPost,
      param: param,
      completion: (response) {
        var users = PostUsersModel.fromJson(response).data;
        if (users != null) {
          completion(users.map((e) {
            final company = e.company;
            if (company != null) {
              return _companyAsUser(
                companyId: company.id,
                ownerUserId: company.ownerUserId ?? e.userId?.toInt(),
                name: company.name,
                logo: company.logo,
                description: company.description,
                sector: company.sector,
                isVerified: company.isVerified,
                followersCount: company.followersCount,
                email: company.email,
                website: company.website,
                city: company.city,
                country: company.country,
              );
            }
            return e.user ?? User();
          }).toList());
        }
      },
    );
  }

  void fetchReposts(
      {required int postId,
      required int start,
      required Function(List<User> users) completion}) {
    Map<String, dynamic> param = {
      Param.postId: postId,
      Param.start: start,
      Param.limit: Limits.pagination,
    };
    ApiService.shared.call(
      url: WebService.fetchReposts,
      param: param,
      completion: (response) {
        var posts = PostsModel.fromJson(response).data;
        if (posts != null) {
          completion(posts.map((e) {
            final company = e.company;
            if (company != null) {
              return _companyAsUser(
                companyId: company.id,
                ownerUserId: company.ownerUserId ?? e.userId,
                name: company.name,
                logo: company.logo,
                description: company.description,
                sector: company.sector,
                isVerified: company.isVerified,
                followersCount: company.followersCount,
                email: company.email,
                website: company.website,
                city: company.city,
                country: company.country,
              );
            }
            return e.user ?? User();
          }).toList());
        }
      },
    );
  }

  void addComment(
      String comment, num postId, Function(Comment comment) completion,
      {String? mentionedUserIds, num? parentId}) {
    final companyId = SessionManager.shared.getActingCompanyId();
    var params = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.desc: comment,
      Param.postId: postId,
      Param.mentionedUserIds: mentionedUserIds,
      if (companyId != null) Param.companyId: companyId,
    };
    if (parentId != null) {
      params[Param.parentId] = parentId;
    }
    ApiService.shared.call(
      url: WebService.addComment,
      param: params,
      completion: (response) {
        var comment = CommentModel.fromJson(response).data;
        if (comment != null) {
          completion(comment);
        }
      },
    );
  }

  void editComment(
      {required num commentId,
      required String description,
      required Function(bool success) completion}) {
    final companyId = SessionManager.shared.getActingCompanyId();
    var params = {
      Param.userId: SessionManager.shared.getUserID(),
      'comment_id': commentId,
      Param.desc: description,
      if (companyId != null) Param.companyId: companyId,
    };
    ApiService.shared.call(
      url: WebService.editComment,
      param: params,
      completion: (response) {
        var obj = CommonResponse.fromJson(response);
        completion(obj.status ?? false);
      },
    );
  }

  void deleteComment(
      {required num commentId, required Function(bool success) completion}) {
    final companyId = SessionManager.shared.getActingCompanyId();
    var params = {
      Param.userId: SessionManager.shared.getUserID(),
      'comment_id': commentId,
      if (companyId != null) Param.companyId: companyId,
    };
    ApiService.shared.call(
      url: WebService.deleteComment,
      param: params,
      completion: (response) {
        var obj = CommonResponse.fromJson(response);
        completion(obj.status ?? false);
      },
    );
  }

  Future<void> fetchComments(num postId, int start,
      Function(List<Comment> comments) completion) async {
    final companyId = SessionManager.shared.getActingCompanyId();
    var params = {
      Param.start: start,
      Param.postId: postId,
      Param.limit: Limits.pagination,
      Param.myUserId: SessionManager.shared.getUserID(),
      if (companyId != null) Param.companyId: companyId,
    };
    await ApiService.shared.call(
      url: WebService.fetchComments,
      param: params,
      completion: (response) {
        var comments = CommentsModel.fromJson(response).data;
        if (comments != null) {
          completion(comments);
        }
      },
    );
  }

  Future<void> fetchReplies(num commentId, int start,
      Function(List<Comment> replies) completion) async {
    final companyId = SessionManager.shared.getActingCompanyId();
    var params = {
      Param.commentId: commentId,
      Param.start: start,
      Param.limit: Limits.pagination,
      Param.myUserId: SessionManager.shared.getUserID(),
      if (companyId != null) Param.companyId: companyId,
    };
    await ApiService.shared.call(
      url: WebService.fetchReplies,
      param: params,
      completion: (response) {
        var replies = CommentsModel.fromJson(response).data;
        if (replies != null) {
          completion(replies);
        }
      },
    );
  }

  Future<void> reportPost(num postId, String reason, String desc) async {
    final companyId = SessionManager.shared.getActingCompanyId();
    var param = {
      Param.postId: postId,
      Param.userId: SessionManager.shared.getUserID(),
      Param.reason: reason,
      Param.desc: desc,
      if (companyId != null) Param.companyId: companyId,
    };

    await ApiService.shared.call(
      url: WebService.reportPost,
      param: param,
      completion: (response) {
        var obj = CommonResponse.fromJson(response);
        if (obj.status == true) {
          Get.back();
          Get.back();
          BaseController.share.showSnackBar(LKeys.reportAddedSuccessfully.tr,
              type: SnackBarType.success);
        } else {
          BaseController.share.showSnackBar(obj.message ?? "Report failed",
              type: SnackBarType.error);
        }
      },
    );
  }

  Future<void> fetchUserPosts(
      int userID, int start, Function(List<Post> posts) completion) async {
    final companyId = SessionManager.shared.getActingCompanyId();
    var param = {
      Param.myUserId: SessionManager.shared.getUserID(),
      Param.userId: userID.toString(),
      Param.start: start.toString(),
      Param.limit: Limits.pagination.toString(),
      if (companyId != null) Param.companyId: companyId,
    };
    await ApiService.shared.call(
        param: param,
        url: WebService.fetchPostByUser,
        completion: (data) {
          var obj = PostsModel.fromJson(data).data;
          if (obj != null) {
            completion(obj);
          }
        });
  }

  void uploadPost({
    required String desc,
    required String tags,
    required PostType contentType,
    String? urlPreview,
    required List<XFile> images,
    XFile? video,
    XFile? audioFile,
    required Function(int bytes, int totalBytes) onProgress,
    required Function(Post feed) completion,
    required String thumbnailPath,
    required List<double> waves,
    required String interestIds,
    String? mentionedUserIds,
  }) {
    final companyId = SessionManager.shared.getActingCompanyId();
    var param = {
      Param.linkPreviewJson: urlPreview,
      Param.desc: desc,
      Param.tags: tags,
      Param.userId: SessionManager.shared.getUserID(),
      Param.contentType: contentType.value.toString(),
      Param.audioWaves: jsonEncode(waves),
      Param.interestIds: interestIds,
      Param.mentionedUserIds: mentionedUserIds,
      if (companyId != null) Param.companyId: companyId,
    };
    ApiService.shared.multiPartCallApi(
      url: WebService.addPost,
      param: param,
      filesMap: {
        Param.contents: contentType == PostType.image
            ? images
            : contentType == PostType.video
                ? [video]
                : [audioFile],
        Param.thumbnailArray: [XFile(thumbnailPath)]
      },
      completion: (data) {
        var post = SingleFeedModel.fromJson(data).data;
        if (post != null) {
          completion(post);
        }
      },
    );
  }

  void likePost(int postID, Function() completion) {
    final companyId = SessionManager.shared.getActingCompanyId();
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.postId: postID.toString(),
      if (companyId != null) Param.companyId: companyId.toString(),
    };

    ApiService.shared.call(
      param: param,
      url: WebService.likePost,
      completion: (p0) {
        var response = CommonResponse.fromJson(p0);
        if (response.status == true) {
          completion();
        }
      },
    );
  }

  void deletePost(int postID, Function() completion) {
    final companyId = SessionManager.shared.getActingCompanyId();
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.postId: postID.toString(),
      if (companyId != null) Param.companyId: companyId.toString(),
    };

    ApiService.shared.call(
      param: param,
      url: WebService.deleteMyPost,
      completion: (p0) {
        var response = CommonResponse.fromJson(p0);
        if (response.status == true) {
          completion();
        }
      },
    );
  }

  void dislikePost(int postID, Function() completion) {
    final companyId = SessionManager.shared.getActingCompanyId();
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.postId: postID.toString(),
      if (companyId != null) Param.companyId: companyId.toString(),
    };

    ApiService.shared.call(
      param: param,
      url: WebService.dislikePost,
      completion: (p0) {
        var response = CommonResponse.fromJson(p0);
        if (response.status == true) {
          completion();
        }
      },
    );
  }

  Future<List<Post>> fetchSavedPosts({required int start}) async {
    final companyId = SessionManager.shared.getActingCompanyId();
    var param = {
      Param.userId: SessionManager.shared.getUserID(),
      Param.start: start,
      Param.limit: Limits.pagination,
      if (companyId != null) Param.companyId: companyId,
    };
    List<Post> posts = [];
    await ApiService.shared.call(
      param: param,
      url: WebService.fetchSavedPosts,
      completion: (data) {
        posts = PostsModel.fromJson(data).data ?? [];
      },
    );
    return posts;
  }

  Future<void> fetchPosts({
    required bool shouldSendSuggestedRoom,
    required int start,
    required Function(List<Post> posts, List<Room> suggestedRooms) completion,
    Function()? onError,
    int? feedTypeOverride,
  }) async {
    final companyId = SessionManager.shared.getActingCompanyId();
    var param = {
      Param.myUserId: SessionManager.shared.getUserID(),
      Param.limit: Limits.pagination.toString(),
      Param.start: start,
      Param.shouldSendSuggestedRoom: shouldSendSuggestedRoom ? 1 : 0,
      Param.fetchPostType: feedTypeOverride ??
          SessionManager.shared.getSettings()?.fetchPostType ??
          0,
      if (companyId != null) Param.companyId: companyId,
    };
    await ApiService.shared.call(
        param: param,
        url: WebService.fetchPosts,
        onError: onError,
        completion: (data) {
          var parsed = PostsModel.fromJson(data);
          var obj = parsed.data;
          var rooms = parsed.suggestedRooms;
          if (obj != null) {
            completion(obj, rooms ?? []);
          }
        });
  }
}
