import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/utils/input_sanitizer.dart';
import 'package:untitled/common/managers/my_debouncer.dart';
import 'package:untitled/enums/reel_page_type.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/registration.dart' show User;
import 'package:untitled/screens/reels_screen/reel/reel_page_controller.dart';
import 'package:video_player/video_player.dart';

class ReelsScreenController extends BaseController {
  RxMap<int, ReelPlayerEntry> players = <int, ReelPlayerEntry>{}.obs;

  RxList<Reel> reels = <Reel>[].obs;
  RxInt position = 0.obs;

  String? hashtag;
  User? user;
  ReelPageType reelPageType;

  PageController pageController = PageController();
  Future<void> Function()? onFetchMoreData;
  Future<void> Function()? onRefresh;

  TextEditingController commentTextController = TextEditingController();
  List<User> mentionedUsers = [];

  ReelsScreenController({
    required this.reels,
    required this.position,
    this.user,
    this.hashtag,
    required this.reelPageType,
    required this.onFetchMoreData,
    required this.onRefresh,
  });

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: position.value);
  }

  @override
  void onClose() {
    super.onClose();
    disposeAllController();
  }

  Future<void> _fetchMoreData() async {
    if (position >= reels.length - 3) {
      await onFetchMoreData?.call();
      _initializeControllerAtIndex(position.value + 1);
    }
  }

  void pauseAllPlayers() {
    final keys = players.keys.toList(); // 👈 COPY
    for (var i in keys) {
      _stopControllerAtIndex(i);
    }
  }

  void initVideoPlayer() async {
    /// Initialize 1st video
    await _initializeControllerAtIndex(position.value);

    /// Play 1st video
    _playControllerAtIndex(position.value);

    /// Initialize 2nd vide
    if (position >= 0) {
      await _initializeControllerAtIndex(position.value - 1);
    }
    await _initializeControllerAtIndex(position.value + 1);
  }

  void _onPageSwitch(int index) {
    pauseAllPlayers();
    _initializeControllerAtIndex(index);
    _initializeControllerAtIndex(index + 1);
    _initializeControllerAtIndex(index - 1);
    _disposeAllExcept(index);
  }

  void _disposeAllExcept(int index) {
    final validIndexes = {index - 1, index, index + 1};

    final keys = players.keys.toList(); // 👈 COPY

    for (final i in keys) {
      if (!validIndexes.contains(i)) {
        _disposeControllerAtIndex(i);
        players.remove(i);
      }
    }
  }

  Future<void> _initializeControllerAtIndex(int index) async {
    if (index < 0 || index >= reels.length) return;

    /// 🔒 HARD GUARD (no race possible)
    if (players[index]?.status == PlayerStatus.initializing || players[index]?.status == PlayerStatus.initialized) {
      return;
    }

    /// 🔒 Mark initializing IMMEDIATELY
    players[index] = ReelPlayerEntry(status: PlayerStatus.initializing);

    try {
      late VideoPlayerController controller;

      final reel = reels[index];
      if (reel.id == -1) {
        controller = VideoPlayerController.file(
          File(reel.content ?? ''),
        );
      } else {
        final url = reel.content ?? '';
        // TikTok-style: check cache first (instant), else stream via network (immediate playback)
        final fileInfo = await DefaultCacheManager().getFileFromCache(url);
        if (fileInfo != null) {
          controller = VideoPlayerController.file(fileInfo.file);
        } else {
          // Stream immediately — don't wait for full download
          controller = VideoPlayerController.networkUrl(
            Uri.parse(url),
            httpHeaders: const {'Connection': 'keep-alive'},
          );
          // Fire-and-forget: cache in background for future replays
          DefaultCacheManager().getSingleFile(url).then((_) {}).catchError((_) {});
        }
      }

      await controller.initialize();
      controller.setLooping(true);

      players[index] = ReelPlayerEntry(
        controller: controller,
        status: PlayerStatus.initialized,
      );

      Loggers.info("🚀 INITIALIZED $index");

      if (index == position.value) {
        _playControllerAtIndex(index);
      }
    } catch (e) {
      Loggers.error("❌ INIT FAILED $index $e");

      _disposeControllerAtIndex(index);
    }
  }

  void _playControllerAtIndex(int index) {
    final entry = players[index];
    final controller = entry?.controller;

    if (controller == null) return;
    if (!controller.value.isInitialized) return;

    controller.play();

    MyDebouncer.shared.run(milliseconds: 3000, () {
      _increaseViewsCount(reels[index]);
    });
    Loggers.info('🚀🚀🚀 PLAYING $index');
  }

  void _increaseViewsCount(Reel? reel) async {
    int reelId = reel?.id?.toInt() ?? -1;
    if (reel == null) {
      return Loggers.error('Post not found');
    }
    if (reelId == -1) {
      return;
    }

    bool status = await ReelService.shared.increaseViewCount(reelId: reelId);
    if (status) {
      reel.viewsCount = (reel.viewsCount ?? 0) + 1;
      reels[reels.indexWhere((element) => element.id == reelId)].viewsCount = reel.viewsCount;
    }
  }

  void _stopControllerAtIndex(int index) {
    if (reels.length > index && index >= 0) {
      final controller = players[index]?.controller;
      if (controller != null) {
        controller.pause();
        controller.seekTo(const Duration()); // Reset position
        Loggers.info('🚀🚀🚀 STOPPED $index');
      }
    }
  }

  void _disposeControllerAtIndex(int index) {
    ReelPlayerEntry? entry = players[index];
    if (entry == null) return;
    if (entry.status == PlayerStatus.disposed || entry.status == PlayerStatus.none) return;

    final controller = entry.controller;

    if (controller != null) {
      if (entry.listener != null) {
        controller.removeListener(entry.listener!);
      }
      controller.pause();
      controller.dispose();
    }

    entry.controller = null;
    entry.listener = null;
    entry.status = PlayerStatus.disposed;
    players[index] = entry;

    Loggers.info("🗑 DISPOSED $index");
  }

  Future<void> disposeAllController() async {
    final entries = players.entries.toList(); // 👈 COPY

    for (var entry in entries) {
      final controller = entry.value.controller;
      final listener = entry.value.listener;

      if (listener != null) {
        controller?.removeListener(listener);
      }

      controller?.pause();
      await controller?.dispose();
    }

    players.clear();
  }

  void onPageChanged(int index) {
    if (index > position.value) {
      _fetchMoreData();
    }
    position.value = index;
    _onPageSwitch(index);
    _preCacheUpcomingVideos(index);
  }

  void _preCacheUpcomingVideos(int currentIndex) {
    // Pre-cache next 2 videos only (avoid bandwidth contention with current stream)
    for (int i = 2; i <= 3; i++) {
      final idx = currentIndex + i;
      if (idx < reels.length && reels[idx].id != -1) {
        final url = reels[idx].content ?? '';
        if (url.isNotEmpty) {
          DefaultCacheManager().getSingleFile(url).then((_) {
            Loggers.info('📦 Pre-cached reel $idx');
          }).catchError((_) {});
        }
      }
    }
  }

  void updatePageController(bool reset) {
    if (reset) {
      if (pageController.hasClients) {
        pageController.jumpToPage(0); // Reset to first page
      } else {
        pageController = PageController(initialPage: 0);
      }
    }
  }

  void addMentionedUser(User user) {
    if (!mentionedUsers.any((u) => u.id == user.id)) {
      mentionedUsers.add(user);
    }
  }

  void addComment() async {
    final sanitized = InputSanitizer.sanitizeText(commentTextController.text);
    if (sanitized.isEmpty) return;
    Reel reel = reels[position.value];
    if (Get.isRegistered<ReelController>(tag: reel.id?.toString() ?? '')) {
      var reelController = Get.find<ReelController>(tag: reel.id?.toString() ?? '');
      var mentionIds = mentionedUsers.map((u) => '${u.id}').toList().join(',');
      await ReelService.shared.addComment(comment: sanitized, reelId: reel.id ?? 0, mentionedUserIds: mentionIds);
      stopLoading();

      commentTextController.clear();
      mentionedUsers.clear();
      reelController.reel.update((val) {
        val?.commentsCount = (reelController.reel.value?.commentsCount ?? 0) + 1;
      });
    }
  }

  void onRefreshPage() async {
    await onRefresh?.call();
    position.value = 0;
    await disposeAllController();
    initVideoPlayer();
  }
}

class ReelPlayerEntry {
  VideoPlayerController? controller;
  VoidCallback? listener;
  PlayerStatus status;

  ReelPlayerEntry({this.controller, this.listener, this.status = PlayerStatus.none});
}

enum PlayerStatus { none, initializing, initialized, disposed }
