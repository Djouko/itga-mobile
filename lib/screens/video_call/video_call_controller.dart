import 'dart:convert';
import 'dart:typed_data';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled/common/api_service/common_service.dart';
import 'package:untitled/common/api_service/notification_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/common/managers/callkit_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class _CallerIdentity {
  final String name;
  final String? image;
  final String profileType;
  final int? companyId;

  const _CallerIdentity({
    required this.name,
    this.image,
    required this.profileType,
    this.companyId,
  });
}

class VideoCallController extends GetxController {
  final User? remoteUser;
  final String? channelId;
  final String? existingToken;
  final bool isOutgoing;

  VideoCallController({
    this.remoteUser,
    this.channelId,
    this.existingToken,
    this.isOutgoing = true,
  });

  RtcEngine? _engine;
  final RxBool isEngineReady = false.obs;
  final RxBool isJoined = false.obs;
  final RxBool isMicOn = true.obs;
  final RxBool isCameraOn = true.obs;
  final RxBool isFrontCamera = true.obs;
  final RxBool isScreenSharing = false.obs;
  final RxBool isRemoteVideoOn = false.obs;
  final RxSet<int> remoteUsers = <int>{}.obs;
  final RxString callStatus = 'connecting'.obs;
  final RxInt callDuration = 0.obs;

  // Audio output mode (WhatsApp style: speaker / earpiece / muted)
  final Rx<VideoCallAudioOutput> audioOutputMode =
      VideoCallAudioOutput.speakerphone.obs;

  // Network quality indicator (WhatsApp "poor connection" banner)
  // QualityType values: 0=unknown, 1=excellent, 2=good, 3=poor, 4=bad, 5=vbad, 6=down
  final RxInt localNetworkQuality = 0.obs;

  // Track muted remote users (for long-press mute feature)
  final RxSet<int> mutedRemoteUsers = <int>{}.obs;

  // Emoji reactions (Google Meet/Zoom pattern)
  final RxList<ReactionEmoji> activeReactions = <ReactionEmoji>[].obs;
  static const List<String> availableReactions = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '👏',
    '🎉',
    '🔥',
    '✨'
  ];

  void sendReaction(String emoji) {
    final reaction = ReactionEmoji(
      emoji: emoji,
      id: DateTime.now().microsecondsSinceEpoch,
    );
    activeReactions.add(reaction);
    // Auto-remove after animation completes (2 seconds)
    Future.delayed(const Duration(seconds: 2), () {
      activeReactions.removeWhere((r) => r.id == reaction.id);
    });
    // Send via Agora data stream so remote users see it too
    _sendReactionToRemote(emoji);
  }

  Future<void> _createDataStream() async {
    try {
      _dataStreamId = await _engine?.createDataStream(DataStreamConfig(
            syncWithAudio: false,
            ordered: false,
          )) ??
          -1;
    } catch (_) {
      _dataStreamId = -1;
    }
  }

  void _sendReactionToRemote(String emoji) {
    if (_dataStreamId < 0) return;
    try {
      final payload = Uint8List.fromList(utf8.encode('reaction:$emoji'));
      _engine?.sendStreamMessage(
        streamId: _dataStreamId,
        data: payload,
        length: payload.length,
      );
    } catch (_) {
      // Data stream not critical — ignore errors
    }
  }

  void _onRemoteReaction(String emoji) {
    final reaction = ReactionEmoji(
      emoji: emoji,
      id: DateTime.now().microsecondsSinceEpoch,
    );
    activeReactions.add(reaction);
    Future.delayed(const Duration(seconds: 2), () {
      activeReactions.removeWhere((r) => r.id == reaction.id);
    });
  }

  String _channelId = '';
  String _token = '';
  int _localUid = 0;
  bool _isEnding = false;
  int _dataStreamId = -1;

  RtcEngine? get engine => _engine;
  String get activeChannelId => _channelId;

  @override
  void onInit() {
    super.onInit();
    _localUid = SessionManager.shared.getUserID();
    _channelId = channelId ?? const Uuid().v1();
    WakelockPlus.enable();
    // Track active call in CallKitManager
    CallKitManager.shared.isInCall = true;
    CallKitManager.shared.activeChannelId = _channelId;
    _initCall();
  }

  Future<void> _initCall() async {
    callStatus.value = 'connecting';
    if (existingToken != null && existingToken!.isNotEmpty) {
      _token = existingToken!;
      await _initEngine();
      if (isEngineReady.value) {
        await _joinChannel();
      } else {
        // Engine init failed with existing token — try generating a fresh one
        Loggers.warning(
            'VideoCall: Engine init failed with existing token, regenerating...');
        _generateTokenAndJoin();
      }
    } else {
      _generateTokenAndJoin();
    }
  }

  void _generateTokenAndJoin() {
    CommonService.shared.generateAgoraToken(
      channelName: _channelId,
      completion: (token) async {
        _token = token;
        await _initEngine();
        await _joinChannel();
        // Send push notification to callee so they can join
        if (isOutgoing && remoteUser != null) {
          _notifyCallee();
        }
      },
      onError: () {
        callStatus.value = 'failed';
        Loggers.error('VideoCall: Failed to generate Agora token');
        BaseController.share.showSnackBar(
          LKeys.someThingWentWrong.tr,
          type: SnackBarType.error,
        );
      },
    );
  }

  Future<void> _initEngine() async {
    try {
      var perms = await [Permission.camera, Permission.microphone].request();
      Loggers.info('VideoCall permissions: $perms');

      // Check if critical permissions were granted
      final camGranted = perms[Permission.camera]?.isGranted ?? false;
      final micGranted = perms[Permission.microphone]?.isGranted ?? false;
      if (!micGranted) {
        Loggers.error('VideoCall: Microphone permission denied');
        callStatus.value = 'failed';
        BaseController.share.showSnackBar(
          'Microphone permission is required for calls',
          type: SnackBarType.error,
        );
        return;
      }
      if (!camGranted) {
        Loggers.warning(
            'VideoCall: Camera permission denied — audio-only mode');
      }

      if (_engine != null) {
        try {
          await _engine?.release();
        } catch (_) {}
        _engine = null;
      }

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        audioScenario: AudioScenarioType.audioScenarioDefault,
      ));

      // Wrap each Agora API call individually so one failure doesn't abort init.
      // CRITICAL: enableDualStreamMode can throw on some devices if the video
      // module isn't fully ready — this must NOT prevent the call from starting.
      try {
        await _engine!.enableVideo();
      } catch (e) {
        Loggers.error('VideoCall initEngine enableVideo: $e');
      }
      try {
        await _engine!.enableAudio();
      } catch (e) {
        Loggers.error('VideoCall initEngine enableAudio: $e');
      }
      try {
        await _engine!
            .setVideoEncoderConfiguration(const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 15,
          bitrate: 600,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ));
      } catch (e) {
        Loggers.error('VideoCall initEngine setVideoEncoderConfig: $e');
      }
      // Optimize for weak networks: dual-stream lets remote side auto-switch
      // to low-quality video when bandwidth drops.
      try {
        await _engine!.enableDualStreamMode(enabled: true);
      } catch (e) {
        Loggers.error('VideoCall initEngine enableDualStream: $e');
      }
      try {
        await _engine!
            .setRemoteDefaultVideoStreamType(VideoStreamType.videoStreamLow);
      } catch (e) {
        Loggers.error('VideoCall initEngine setRemoteStreamType: $e');
      }
      // Start local camera preview so the user sees themselves immediately
      try {
        await _engine!.startPreview();
      } catch (e) {
        Loggers.error('VideoCall initEngine startPreview: $e');
      }

      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (conn, elapsed) {
          Loggers.info('VideoCall: Joined channel uid=${conn.localUid}');
          isJoined.value = true;
          callStatus.value = 'waiting';
          _startDurationTimer();
          _createDataStream();
          // Apply audio output mode once in channel (setEnableSpeakerphone requires it)
          _applyAudioOutputMode();
        },
        onUserJoined: (conn, remoteUid, elapsed) {
          Loggers.info('VideoCall: Remote user joined uid=$remoteUid');
          remoteUsers.add(remoteUid);
          isRemoteVideoOn.value = true;
          callStatus.value = 'connected';
          // Cancel the unanswered timeout since someone joined
          _cancelUnansweredTimeout();
        },
        onUserOffline: (conn, remoteUid, reason) {
          Loggers.info(
              'VideoCall: Remote user left uid=$remoteUid reason=$reason');
          remoteUsers.remove(remoteUid);
          if (remoteUsers.isEmpty) {
            callStatus.value = 'ended';
            Future.delayed(const Duration(seconds: 1), endCall);
          }
        },
        onRemoteVideoStateChanged: (conn, remoteUid, state, reason, elapsed) {
          isRemoteVideoOn.value =
              state == RemoteVideoState.remoteVideoStateDecoding;
        },
        onTokenPrivilegeWillExpire: (conn, token) {
          Loggers.warning('VideoCall: Token expiring soon — renewing...');
          _renewToken();
        },
        onNetworkQuality: (conn, remoteUid, txQuality, rxQuality) {
          // remoteUid == 0 means local user's network quality
          if (remoteUid == 0) {
            final worst = txQuality.index > rxQuality.index
                ? txQuality.index
                : rxQuality.index;
            localNetworkQuality.value = worst;
          }
        },
        onStreamMessage: (conn, remoteUid, streamId, data, length, sentTs) {
          final msg = utf8.decode(data);
          if (msg.startsWith('reaction:')) {
            _onRemoteReaction(msg.substring('reaction:'.length));
          }
        },
        onError: (err, msg) {
          Loggers.error('VideoCall Agora Error $err: $msg');
        },
      ));

      isEngineReady.value = true;
      Loggers.info('VideoCall: Engine initialized');
    } catch (e) {
      Loggers.error('VideoCall: Engine init error: $e');
      callStatus.value = 'failed';
    }
  }

  Future<void> _joinChannel() async {
    if (_engine == null || !isEngineReady.value) return;

    try {
      await _engine!.joinChannel(
        token: _token,
        channelId: _channelId,
        uid: _localUid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          publishCameraTrack: true,
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
        ),
      );
    } catch (e) {
      Loggers.error('VideoCall: joinChannel error: $e');
      callStatus.value = 'failed';
    }
  }

  void toggleMic() {
    isMicOn.value = !isMicOn.value;
    _engine?.muteLocalAudioStream(!isMicOn.value);
  }

  void toggleAudioOutput() async {
    if (!isJoined.value) return;
    switch (audioOutputMode.value) {
      case VideoCallAudioOutput.speakerphone:
        audioOutputMode.value = VideoCallAudioOutput.earpiece;
        break;
      case VideoCallAudioOutput.earpiece:
        audioOutputMode.value = VideoCallAudioOutput.muted;
        break;
      case VideoCallAudioOutput.muted:
        audioOutputMode.value = VideoCallAudioOutput.speakerphone;
        break;
    }
    await _applyAudioOutputMode();
  }

  Future<void> _applyAudioOutputMode() async {
    if (!isEngineReady.value || !isJoined.value) return;
    try {
      switch (audioOutputMode.value) {
        case VideoCallAudioOutput.speakerphone:
          await _engine?.setEnableSpeakerphone(true);
          await _engine?.adjustPlaybackSignalVolume(100);
          break;
        case VideoCallAudioOutput.earpiece:
          await _engine?.setEnableSpeakerphone(false);
          await _engine?.adjustPlaybackSignalVolume(100);
          break;
        case VideoCallAudioOutput.muted:
          await _engine?.adjustPlaybackSignalVolume(0);
          break;
      }
    } catch (e) {
      Loggers.error('VideoCall: Audio output mode error: $e');
    }
  }

  void toggleMuteRemoteUser(int uid) {
    final isMuted = mutedRemoteUsers.contains(uid);
    if (isMuted) {
      mutedRemoteUsers.remove(uid);
      _engine?.muteRemoteAudioStream(uid: uid, mute: false);
    } else {
      mutedRemoteUsers.add(uid);
      _engine?.muteRemoteAudioStream(uid: uid, mute: true);
    }
  }

  void toggleCamera() {
    isCameraOn.value = !isCameraOn.value;
    _engine?.muteLocalVideoStream(!isCameraOn.value);
  }

  void switchCamera() {
    _engine?.switchCamera();
    isFrontCamera.value = !isFrontCamera.value;
  }

  Future<void> toggleScreenShare() async {
    if (isScreenSharing.value) {
      await _engine?.stopScreenCapture();
      await _engine?.startPreview();
      // Mobile API: publishScreenCaptureVideo (NOT publishScreenTrack which is desktop-only)
      await _engine?.updateChannelMediaOptions(const ChannelMediaOptions(
        publishScreenCaptureVideo: false,
        publishScreenCaptureAudio: false,
        publishCameraTrack: true,
      ));
      isScreenSharing.value = false;
    } else {
      await _engine?.startScreenCapture(
        const ScreenCaptureParameters2(
          captureVideo: true,
          captureAudio: true,
          videoParams: ScreenVideoParameters(
            dimensions: VideoDimensions(width: 1280, height: 720),
            frameRate: 15,
            bitrate: 1500,
          ),
        ),
      );
      // Mobile API: publishScreenCaptureVideo (NOT publishScreenTrack which is desktop-only)
      await _engine?.updateChannelMediaOptions(const ChannelMediaOptions(
        publishScreenCaptureVideo: true,
        publishScreenCaptureAudio: true,
        publishCameraTrack: false,
      ));
      isScreenSharing.value = true;
    }
  }

  void _startDurationTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (isJoined.value) {
        callDuration.value++;
        return true;
      }
      return false;
    });
  }

  void _renewToken() {
    CommonService.shared.generateAgoraToken(
      channelName: _channelId,
      completion: (newToken) {
        _token = newToken;
        _engine?.renewToken(newToken);
        Loggers.info('VideoCall: Token renewed successfully');
      },
      onError: () {
        Loggers.error('VideoCall: Token renewal failed');
      },
    );
  }

  // ── Unanswered call timeout (WhatsApp: ~60s) ──────────────────────
  // If nobody joins within 60 seconds, auto-end the call.
  bool _unansweredTimeoutCancelled = false;

  void _startUnansweredTimeout() {
    _unansweredTimeoutCancelled = false;
    Future.delayed(const Duration(seconds: 60), () {
      if (!_unansweredTimeoutCancelled &&
          remoteUsers.isEmpty &&
          callStatus.value != 'connected') {
        Loggers.info('VideoCall: Unanswered timeout — ending call');
        callStatus.value = 'ended';
        endCall();
      }
    });
  }

  void _cancelUnansweredTimeout() {
    _unansweredTimeoutCancelled = true;
  }

  _CallerIdentity _currentCallerIdentity() {
    final user = SessionManager.shared.getUser();
    final actingCompanyId = SessionManager.shared.getActingCompanyId();
    final actingCompanyName = SessionManager.shared.getActingCompanyName();

    if (actingCompanyId != null) {
      final name =
          (actingCompanyName != null && actingCompanyName.trim().isNotEmpty)
              ? actingCompanyName.trim()
              : (user?.fullName ?? 'Entreprise ITGA');
      return _CallerIdentity(
        name: name,
        image: null,
        profileType: 'company',
        companyId: actingCompanyId,
      );
    }

    return _CallerIdentity(
      name: user?.fullName ?? 'Someone',
      image: user?.profile,
      profileType: 'user',
    );
  }

  void _notifyCallee() {
    if (remoteUser == null) return;
    final token = remoteUser!.deviceToken;
    if (token == null || token.isEmpty) {
      Loggers.warning(
          'VideoCall: Cannot notify callee — no device token for ${remoteUser!.fullName}');
      return;
    }
    final callerIdentity = _currentCallerIdentity();
    NotificationService.shared.sendToSingleUser(
      token: token,
      deviceType: remoteUser!.deviceType,
      title: callerIdentity.name,
      body: 'Incoming video call...',
      extraData: {
        'type': '20',
        'channel_id': _channelId,
        'agora_token': _token,
        'caller_id': '$_localUid',
        'caller_name': callerIdentity.name,
        'caller_image': callerIdentity.image ?? '',
        'caller_profile_type': callerIdentity.profileType,
        'caller_company_id': callerIdentity.companyId == null
            ? ''
            : '${callerIdentity.companyId}',
      },
    );
    Loggers.info(
        'VideoCall: Notification sent to ${remoteUser!.fullName} (token=${token.substring(0, 10.clamp(0, token.length))}...)');
    // Start timeout — if no one answers within 60s, end the call
    _startUnansweredTimeout();
  }

  /// WhatsApp pattern: invite another user to join the ongoing call
  void inviteParticipant(User user) {
    if (user.deviceToken == null || user.deviceToken!.isEmpty) {
      BaseController.share.showSnackBar(
        'Cannot reach ${user.fullName ?? 'this user'}',
        type: SnackBarType.error,
      );
      return;
    }
    final callerIdentity = _currentCallerIdentity();
    NotificationService.shared.sendToSingleUser(
      token: user.deviceToken!,
      deviceType: user.deviceType,
      title: callerIdentity.name,
      body: 'Incoming video call...',
      extraData: {
        'type': '20',
        'channel_id': _channelId,
        'agora_token': _token,
        'caller_id': '$_localUid',
        'caller_name': callerIdentity.name,
        'caller_image': callerIdentity.image ?? '',
        'caller_profile_type': callerIdentity.profileType,
        'caller_company_id': callerIdentity.companyId == null
            ? ''
            : '${callerIdentity.companyId}',
      },
    );
    BaseController.share.showSnackBar(
      'Invitation sent to ${user.fullName ?? 'participant'}',
      type: SnackBarType.success,
    );
    Loggers.info(
        'VideoCall: Invited ${user.fullName} to join call $_channelId');
  }

  String get formattedDuration {
    final mins = (callDuration.value ~/ 60).toString().padLeft(2, '0');
    final secs = (callDuration.value % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void endCall() {
    if (_isEnding) return;
    _isEnding = true;
    _cancelUnansweredTimeout();
    _cleanup();
    if (Get.isRegistered<VideoCallController>()) {
      Get.back();
    }
  }

  Future<void> _cleanup() async {
    try {
      if (isScreenSharing.value) {
        await _engine?.stopScreenCapture();
      }
      await _engine?.leaveChannel();
      await _engine?.release();
      _engine = null;
    } catch (e) {
      Loggers.error('VideoCall: cleanup error: $e');
    }
    // End native call screen (CallKit) if active + mark call ended
    CallKitManager.shared.endAllCalls();
    CallKitManager.shared.markCallEnded();
    isJoined.value = false;
    isEngineReady.value = false;
    WakelockPlus.disable();
  }

  @override
  void onClose() {
    _cleanup();
    super.onClose();
  }
}

class ReactionEmoji {
  final String emoji;
  final int id;
  ReactionEmoji({required this.emoji, required this.id});
}

enum VideoCallAudioOutput {
  speakerphone,
  earpiece,
  muted,
}
