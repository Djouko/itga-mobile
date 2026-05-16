import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_ended_for_host_screen.dart';
import 'package:untitled/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_ended_for_user_screen.dart';
import 'package:untitled/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_members_view.dart';
import 'package:untitled/screens/audio_space/create_audio_space_screen/audio_space_invite_screen.dart';
import 'package:untitled/screens/audio_space/models/audio_space.dart';
import 'package:untitled/screens/audio_space/models/audio_space_message.dart';
import 'package:untitled/screens/audio_space/models/audio_space_user.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/firebase_const.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'audio_space_screen.dart';

class AudioSpaceController extends BaseController {
  var selectedType = AudioSpacePageType.room.obs;
  TextEditingController searchController = TextEditingController();
  TextEditingController messageTextController = TextEditingController();

  Rx<AudioSpace> audioSpaceObs;
  AudioSpace get audioSpace => audioSpaceObs.value;

  RxList<AudioSpaceUser> allListener = <AudioSpaceUser>[].obs;
  RxList<AudioSpaceMessage> messages = <AudioSpaceMessage>[].obs;
  ScrollController messageScrollController = ScrollController();
  StreamSubscription? spacesListener;
  StreamSubscription? messagesListener;

  var isJoined = false.obs;
  var isEngineInitialized = false.obs;
  var audioOutputMode = AudioOutputMode.speakerphone.obs;
  var amIHost = false.obs;
  var isMySpace = false.obs;
  var isCameraOn = false.obs;
  var isVideoMode = false.obs;
  var isScreenSharing = false.obs;
  final RxInt screenSharingUid = 0.obs;
  final RxSet<int> remoteVideoUsers = <int>{}.obs;
  final RxList<MapEntry<String, DateTime>> floatingReactions =
      <MapEntry<String, DateTime>>[].obs;
  final RxInt localNetworkQuality = 0.obs;

  static RtcEngine? _engine;
  RtcEngineEventHandler? agoraHandler;
  Timer? _timer;
  int _remainingSeconds = (SessionManager.shared
              .getSettings()
              ?.audioSpaceDurationInMinutes
              ?.toInt() ??
          0) *
      60;

  bool _isJoining = false;
  bool _previousAmIHost = false;
  bool? _previousMicOn;
  bool _previousVideoMode = false;
  bool _isCleanedUp = false;
  int? _dataStreamId;
  DateTime? _lastReactionTs;

  bool get showOptionsShow => isMySpace.value;
  bool get isVideoConference => audioSpace.isVideoConference;
  RtcEngine? get engine => _engine;

  AudioSpaceController(AudioSpace space) : audioSpaceObs = space.obs {
    // Set role from initial space data BEFORE async init,
    // so joinSpace knows the correct role immediately.
    var myID = SessionManager.shared.getUserID();
    isMySpace.value = space.admins.any((e) => e.id?.toInt() == myID);
    amIHost.value = space.hostsWithAdmin.any((e) => e.id?.toInt() == myID);
    isVideoMode.value = space.isVideoConference;
    _previousVideoMode = space.isVideoConference;
    Loggers.info(
        "AudioSpaceController: myID=$myID, isMySpace=${isMySpace.value}, amIHost=${amIHost.value}, isVideo=${space.isVideoConference}, users=${space.users?.length ?? 0}");
    _init();
  }

  Future<void> _init() async {
    WakelockPlus.enable();
    _setupSpaceListener();
    _setupMessagesListener();
    await initAgora();
    if (!isEngineInitialized.value) {
      Loggers.warning("Agora init failed, retrying in 1s...");
      await Future.delayed(const Duration(seconds: 1));
      await initAgora();
    }
    // Fix race condition: space listener fires before engine is ready,
    // so explicitly try to join after engine init completes.
    if (isEngineInitialized.value && !isJoined.value && !_isJoining) {
      Loggers.info("_init: engine ready, calling joinSpace");
      joinSpace();
    }
  }

  void _setupSpaceListener() {
    spacesListener = FirebaseFirestore.instance
        .collection(FirebaseAudioConst.audioSpaces)
        .doc(audioSpace.id ?? '')
        .snapshots()
        .listen((event) {
      if (_isCleanedUp) return;
      if (event.exists) {
        try {
          var space = AudioSpace.fromFireStore(event, null);
          audioSpaceObs.value = space;

          var myID = SessionManager.shared.getUserID();
          isMySpace.value = space.admins.any((e) => e.id?.toInt() == myID);
          amIHost.value =
              space.hostsWithAdmin.any((e) => e.id?.toInt() == myID);

          // Sync video mode and screen sharing state from Firestore
          isVideoMode.value = space.isVideoConference;
          // Detect admin override: if I was sharing but Firestore now says someone else is
          if (isScreenSharing.value && space.screenSharingUid != myID) {
            Loggers.info(
                'Screen share overridden by admin — stopping my capture');
            _engine?.stopScreenCapture();
            isScreenSharing.value = false;
            _engine?.updateChannelMediaOptions(ChannelMediaOptions(
              publishCameraTrack: isCameraOn.value,
              publishScreenCaptureVideo: false,
              publishScreenCaptureAudio: false,
            ));
          }
          screenSharingUid.value = space.screenSharingUid;

          // ── Reactions via Firestore (works for ALL users including listeners) ──
          final rawReaction = event.data()?['last_reaction'];
          if (rawReaction is Map) {
            final reactionUid = (rawReaction['uid'] as num?)?.toInt() ?? 0;
            final reactionEmoji = rawReaction['emoji']?.toString() ?? '';
            final reactionTs = rawReaction['ts'];
            DateTime? ts;
            if (reactionTs is Timestamp) ts = reactionTs.toDate();
            // Show only if: from another user, emoji present, and not already shown
            if (reactionUid != myID && reactionEmoji.isNotEmpty && ts != null) {
              if (_lastReactionTs == null || ts.isAfter(_lastReactionTs!)) {
                _lastReactionTs = ts;
                _showFloatingReaction(reactionEmoji);
              }
            }
          }

          if (isMySpace.value && _timer == null) _startTimer();

          if (!isJoined.value && !_isJoining) {
            joinSpace();
          } else if (isJoined.value && isEngineInitialized.value) {
            _syncAgoraRole();
          }

          filterListeners();
        } catch (e) {
          Loggers.error("Space listener error: $e");
        }
      } else {
        if (!isMySpace.value) showUserEndedScreen();
        _safeLeaveChannel();
      }
    }, onError: (error) {
      Loggers.error("Space listener error: $error");
    });
  }

  Future<void> _syncAgoraRole() async {
    var currentAmIHost = amIHost.value;
    var currentMicStatus = myUser.micStatus;
    var currentVideoMode = isVideoMode.value;

    // ── Video mode change (affects ALL participants, not just admin) ──
    if (currentVideoMode != _previousVideoMode) {
      _previousVideoMode = currentVideoMode;
      if (currentVideoMode) {
        // Switching TO video: enable the video module so the engine
        // can decode remote video streams (cameras + screen share).
        await _engine?.enableVideo();
        await _engine
            ?.setVideoEncoderConfiguration(const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 480, height: 640),
          frameRate: 15,
          bitrate: 600,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ));
        Loggers.info('_syncAgoraRole: enableVideo() for video mode ON');
      } else {
        // Switching TO audio-only: disable video module.
        isCameraOn.value = false;
        await _engine?.muteLocalVideoStream(true);
        await _engine?.stopPreview();
        await _engine?.disableVideo();
        Loggers.info('_syncAgoraRole: disableVideo() for video mode OFF');
      }
    }

    // ── Role change ──
    if (currentAmIHost != _previousAmIHost) {
      _previousAmIHost = currentAmIHost;
      _previousMicOn = null; // force mic re-eval on role change
      // IMPORTANT: await setClientRole so subsequent calls execute with correct role
      await _engine?.setClientRole(
        role: currentAmIHost
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      );
      await _engine?.updateChannelMediaOptions(ChannelMediaOptions(
        publishMicrophoneTrack: currentAmIHost,
        publishCameraTrack:
            currentAmIHost && currentVideoMode && isCameraOn.value,
        autoSubscribeAudio: true,
        autoSubscribeVideo: currentVideoMode,
      ));
      // When promoted to host: ensure local audio capture is active + unmute
      if (currentAmIHost) {
        await _engine?.enableLocalAudio(true);
        await _engine
            ?.muteLocalAudioStream(currentMicStatus != AudioSpaceMicStatus.on);
      }
      // When promoted to host in video mode, auto-enable camera
      if (currentAmIHost && currentVideoMode) {
        isCameraOn.value = true;
        await _engine?.muteLocalVideoStream(false);
        await _engine?.startPreview();
      }
      // When demoted from host, mute mic + disable camera
      if (!currentAmIHost) {
        await _engine?.muteLocalAudioStream(true);
        if (isCameraOn.value) {
          isCameraOn.value = false;
          await _engine?.muteLocalVideoStream(true);
          await _engine?.stopPreview();
        }
      }
    }

    // ── Mic state change (only for broadcasters) ──
    // CRITICAL: Use muteLocalAudioStream, NOT enableLocalAudio.
    // enableLocalAudio(false) disables the ENTIRE audio module (capture + playback),
    // meaning the user cannot hear ANYONE. muteLocalAudioStream only stops sending.
    var wantMicOn =
        currentAmIHost && currentMicStatus == AudioSpaceMicStatus.on;
    if (wantMicOn != _previousMicOn) {
      _previousMicOn = wantMicOn;
      await _engine?.muteLocalAudioStream(!wantMicOn);
    }
  }

  void _setupMessagesListener() {
    messagesListener = FirebaseFirestore.instance
        .collection(FirebaseAudioConst.audioSpaces)
        .doc(audioSpace.id ?? '')
        .collection(FirebaseAudioConst.messages)
        .orderBy('time', descending: false)
        .snapshots()
        .listen((event) {
      var parsedMessages = <AudioSpaceMessage>[];
      for (var doc in event.docs) {
        try {
          var msg = AudioSpaceMessage.fromFireStore(doc, null);
          msg.user = ((audioSpace.users ?? []) + (audioSpace.leavedUsers ?? []))
              .firstWhereOrNull((u) =>
                  u.id?.toInt() == msg.userId &&
                  u.companyId == msg.senderCompanyId);
          parsedMessages.add(msg);
        } catch (e) {
          Loggers.error("Error parsing message ${doc.id}: $e");
        }
      }
      messages.assignAll(parsedMessages);
    }, onError: (error) {
      Loggers.error("Messages listener error: $error");
    });
  }

  Future<void> initAgora() async {
    if (agoraAppId == 'agora_app_id' || agoraAppId.isEmpty) {
      Loggers.error("Agora App ID non configuré");
      return;
    }

    try {
      var permissions = [Permission.microphone];
      if (isVideoMode.value) permissions.add(Permission.camera);
      var permStatus = await permissions.request();
      Loggers.info("Permissions: $permStatus");

      // Release any stale engine from a previous session
      if (_engine != null) {
        try {
          await _engine?.release();
        } catch (_) {}
        _engine = null;
      }

      _engine = createAgoraRtcEngine();
      await _engine?.initialize(RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        audioScenario: AudioScenarioType.audioScenarioDefault,
      ));

      // Core audio setup — wrapped individually so one failure doesn't break init
      try {
        await _engine?.enableAudio();
      } catch (e) {
        Loggers.error("initAgora enableAudio: $e");
      }
      try {
        await _engine?.setDefaultAudioRouteToSpeakerphone(true);
      } catch (e) {
        Loggers.error("initAgora setDefaultRoute: $e");
      }

      // Video setup — ONLY for video conferences (NOT audio-only spaces).
      // CRITICAL: enableDualStreamMode and setRemoteDefaultVideoStreamType are
      // VIDEO APIs that can fail if the video module isn't active, which would
      // crash the entire initAgora() and leave isEngineInitialized=false.
      if (isVideoMode.value) {
        try {
          await _engine?.enableVideo();
        } catch (e) {
          Loggers.error("initAgora enableVideo: $e");
        }
        try {
          await _engine
              ?.setVideoEncoderConfiguration(const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 480, height: 640),
            frameRate: 15,
            bitrate: 600,
            orientationMode: OrientationMode.orientationModeAdaptive,
          ));
        } catch (e) {
          Loggers.error("initAgora setVideoEncoderConfig: $e");
        }
        try {
          await _engine?.enableDualStreamMode(enabled: true);
        } catch (e) {
          Loggers.error("initAgora enableDualStream: $e");
        }
        try {
          await _engine
              ?.setRemoteDefaultVideoStreamType(VideoStreamType.videoStreamLow);
        } catch (e) {
          Loggers.error("initAgora setRemoteStreamType: $e");
        }
      }

      agoraHandler = RtcEngineEventHandler(
        onJoinChannelSuccess: (conn, elapsed) async {
          Loggers.info(
              "Agora: Joined channel successfully, uid=${conn.localUid}");
          isJoined.value = true;
          _isJoining = false;
          // Create data stream for emoji reactions (Google Meet style)
          try {
            _dataStreamId =
                await _engine?.createDataStream(const DataStreamConfig(
              syncWithAudio: false,
              ordered: false,
            ));
            Loggers.info('Agora: Data stream created, id=$_dataStreamId');
          } catch (e) {
            Loggers.error('Agora: Failed to create data stream: $e');
          }
          // setEnableSpeakerphone requires being IN the channel
          _applyAudioOutputMode();
        },
        onUserJoined: (conn, remoteUid, elapsed) {
          Loggers.info("Agora: Remote user joined, uid=$remoteUid");
        },
        onUserOffline: (conn, remoteUid, reason) {
          Loggers.info(
              "Agora: Remote user offline, uid=$remoteUid, reason=$reason");
          remoteVideoUsers.remove(remoteUid);
        },
        onRemoteVideoStateChanged: (conn, remoteUid, state, reason, elapsed) {
          if (state == RemoteVideoState.remoteVideoStateDecoding) {
            remoteVideoUsers.add(remoteUid);
          } else if (state == RemoteVideoState.remoteVideoStateStopped ||
              state == RemoteVideoState.remoteVideoStateFrozen) {
            remoteVideoUsers.remove(remoteUid);
          }
        },
        onTokenPrivilegeWillExpire: (conn, token) {
          Loggers.warning("Agora: Token will expire soon");
        },
        onNetworkQuality: (conn, remoteUid, txQuality, rxQuality) {
          if (remoteUid == 0) {
            final worst = txQuality.index > rxQuality.index
                ? txQuality.index
                : rxQuality.index;
            localNetworkQuality.value = worst;
          }
        },
        onStreamMessage: (conn, remoteUid, streamId, data, length, sentTs) {
          try {
            final msg = utf8.decode(data);
            if (msg.startsWith('reaction:')) {
              _showFloatingReaction(msg.substring('reaction:'.length));
            }
          } catch (e) {
            Loggers.error('Agora: Failed to decode stream message: $e');
          }
        },
        onError: (err, msg) => Loggers.error("Agora Error $err: $msg"),
      );

      if (agoraHandler != null) _engine?.registerEventHandler(agoraHandler!);
      isEngineInitialized.value = true;
      Loggers.info(
          "Agora engine initialized successfully (video=${isVideoMode.value})");
    } catch (e) {
      Loggers.error("Agora Init Error: $e");
    }
  }

  void toggleAudioOutput() async {
    if (!isJoined.value) return;
    switch (audioOutputMode.value) {
      case AudioOutputMode.speakerphone:
        audioOutputMode.value = AudioOutputMode.earpiece;
        break;
      case AudioOutputMode.earpiece:
        audioOutputMode.value = AudioOutputMode.muted;
        break;
      case AudioOutputMode.muted:
        audioOutputMode.value = AudioOutputMode.speakerphone;
        break;
    }
    await _applyAudioOutputMode();
  }

  Future<void> _applyAudioOutputMode() async {
    if (!isEngineInitialized.value || !isJoined.value) return;
    try {
      switch (audioOutputMode.value) {
        case AudioOutputMode.speakerphone:
          await _engine?.setEnableSpeakerphone(true);
          await _engine?.adjustPlaybackSignalVolume(100);
          break;
        case AudioOutputMode.earpiece:
          await _engine?.setEnableSpeakerphone(false);
          await _engine?.adjustPlaybackSignalVolume(100);
          break;
        case AudioOutputMode.muted:
          await _engine?.adjustPlaybackSignalVolume(0);
          break;
      }
    } catch (e) {
      Loggers.error("Audio output mode error: $e");
    }
  }

  void filterListeners() {
    allListener.assignAll(audioSpace.requestsAndListener.where((user) {
      final queryLower = searchController.text.toLowerCase();
      return (user.username?.toLowerCase() ?? '').contains(queryLower);
    }).toList());
  }

  Future<void> joinSpace() async {
    if (!isEngineInitialized.value || _isJoining || isJoined.value) {
      Loggers.warning(
          "joinSpace skipped: engineInit=${isEngineInitialized.value}, joining=$_isJoining, joined=${isJoined.value}");
      return;
    }
    _isJoining = true;

    try {
      var myID = SessionManager.shared.getUserID();
      var actorUser = _createBasicAudioUser();
      var currentUserInSpace =
          audioSpace.users?.firstWhereOrNull((u) => u.isSameActor(actorUser));

      if (currentUserInSpace == null) {
        AudioSpaceUser newUser = actorUser;
        var isCreator = audioSpace.admins.isEmpty ||
            audioSpace.admins.any((e) => e.isSameActor(actorUser));
        if (isMySpace.value || isCreator) {
          newUser.type = AudioSpaceUserType.admin;
          newUser.micStatus = AudioSpaceMicStatus.on;
        }
        _changeUserType(user: newUser);
      }

      var shouldBeBroadcaster = amIHost.value || isMySpace.value;
      Loggers.info(
          "joinSpace: myID=$myID, amIHost=${amIHost.value}, isMySpace=${isMySpace.value}, broadcaster=$shouldBeBroadcaster, userType=${currentUserInSpace?.type}, token=${(audioSpace.token ?? '').isNotEmpty ? 'present' : 'MISSING'}");
      _previousAmIHost = shouldBeBroadcaster;
      await _engine?.setClientRole(
        role: shouldBeBroadcaster
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      );
      await _engine?.joinChannel(
        token: audioSpace.token ?? '',
        channelId: audioSpace.id ?? '',
        uid: myID,
        options: ChannelMediaOptions(
          publishMicrophoneTrack: shouldBeBroadcaster,
          publishCameraTrack: shouldBeBroadcaster && isVideoMode.value,
          autoSubscribeAudio: true,
          autoSubscribeVideo: isVideoMode.value,
        ),
      );
      if (shouldBeBroadcaster) {
        var micOn = currentUserInSpace?.micStatus == AudioSpaceMicStatus.on ||
            isMySpace.value;
        _previousMicOn = micOn;
        // CRITICAL: Use muteLocalAudioStream, NOT enableLocalAudio.
        // enableLocalAudio(false) kills ALL audio (capture + playback).
        await _engine?.muteLocalAudioStream(!micOn);
        // Auto-enable camera for hosts in video conference rooms
        if (isVideoMode.value) {
          isCameraOn.value = true;
          await _engine?.muteLocalVideoStream(false);
          await _engine?.startPreview();
          // Explicitly publish camera track
          await _engine?.updateChannelMediaOptions(const ChannelMediaOptions(
            publishCameraTrack: true,
            autoSubscribeVideo: true,
          ));
        }
      }
      // _applyAudioOutputMode is called in onJoinChannelSuccess
    } catch (e) {
      Loggers.error("Join space error: $e");
      _isJoining = false;
    }
  }

  void toggleMic() {
    var user = myUser;
    user.micStatus = user.micStatus == AudioSpaceMicStatus.muted
        ? AudioSpaceMicStatus.on
        : AudioSpaceMicStatus.muted;
    _changeUserType(user: user, micStatus: user.micStatus);
    if (isEngineInitialized.value) {
      var micOn = user.micStatus == AudioSpaceMicStatus.on;
      _previousMicOn = micOn;
      // CRITICAL: Use muteLocalAudioStream, NOT enableLocalAudio.
      // enableLocalAudio(false) kills ALL audio (capture + playback).
      _engine?.muteLocalAudioStream(!micOn);
    }
  }

  void toggleCamera() {
    if (!isEngineInitialized.value || !isJoined.value) {
      showSnackBar('Connecting to the room...', type: SnackBarType.info);
      return;
    }
    if (!amIHost.value && !isMySpace.value) return;
    isCameraOn.value = !isCameraOn.value;
    _engine?.muteLocalVideoStream(!isCameraOn.value);
    if (isCameraOn.value) {
      _engine?.startPreview();
    } else {
      _engine?.stopPreview();
    }
    // Publish camera track state to Agora channel
    _engine?.updateChannelMediaOptions(ChannelMediaOptions(
      publishCameraTrack: isCameraOn.value,
    ));
    // Update camera status in Firestore
    var user = myUser;
    user.isCameraOn = isCameraOn.value;
    _changeUserType(user: user);
  }

  void switchCamera() {
    _engine?.switchCamera();
  }

  Future<void> toggleVideoMode() async {
    // Only admin can switch the entire room mode
    if (!isMySpace.value) return;
    isVideoMode.value = !isVideoMode.value;
    if (isVideoMode.value) {
      // Switching from audio to video
      await Permission.camera.request();
      await _engine?.enableVideo();
      await _engine
          ?.setVideoEncoderConfiguration(const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 480, height: 640),
        frameRate: 15,
        bitrate: 600,
        orientationMode: OrientationMode.orientationModeAdaptive,
      ));
      if (amIHost.value || isMySpace.value) {
        isCameraOn.value = true;
        await _engine?.muteLocalVideoStream(false);
        await _engine?.startPreview();
        await _engine?.updateChannelMediaOptions(const ChannelMediaOptions(
          publishCameraTrack: true,
          autoSubscribeVideo: true,
        ));
        var user = myUser;
        user.isCameraOn = true;
        _changeUserType(user: user);
      }
    } else {
      // Switching from video to audio
      isCameraOn.value = false;
      await _engine?.muteLocalVideoStream(true);
      await _engine?.disableVideo();
      await _engine?.updateChannelMediaOptions(const ChannelMediaOptions(
        publishCameraTrack: false,
        autoSubscribeVideo: false,
      ));
      var user = myUser;
      user.isCameraOn = false;
      _changeUserType(user: user);
    }
    // Update Firestore room isVideoConference flag if admin
    if (isMySpace.value) {
      FirebaseFirestore.instance
          .collection(FirebaseAudioConst.audioSpaces)
          .doc(audioSpace.id ?? '')
          .update({"is_video_conference": isVideoMode.value});
    }
  }

  // ── Emoji reactions (Google Meet style) ──

  void sendReaction(String emoji) {
    // Show locally immediately
    _showFloatingReaction(emoji);
    // Broadcast via Firestore so ALL participants (including listeners/audience)
    // can see the reaction. Agora data streams only work for broadcasters in
    // LiveBroadcasting profile, so Firestore is the universal mechanism.
    try {
      final actorUser = _createBasicAudioUser();
      FirebaseFirestore.instance
          .collection(FirebaseAudioConst.audioSpaces)
          .doc(audioSpace.id ?? '')
          .update({
        'last_reaction': {
          'emoji': emoji,
          'uid': SessionManager.shared.getUserID(),
          'company_id': actorUser.companyId,
          'profile_type': actorUser.profileType,
          'name': actorUser.actorName,
          'ts': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      Loggers.error('sendReaction Firestore error: $e');
    }
  }

  void _showFloatingReaction(String emoji) {
    final entry = MapEntry(emoji, DateTime.now());
    floatingReactions.add(entry);
    Future.delayed(const Duration(seconds: 3), () {
      floatingReactions.remove(entry);
    });
  }

  Future<void> toggleScreenSharing() async {
    if (!isEngineInitialized.value || !isJoined.value) {
      showSnackBar('Connecting to the room...', type: SnackBarType.info);
      return;
    }
    if (!amIHost.value && !isMySpace.value) return;
    final myID = SessionManager.shared.getUserID();
    if (isScreenSharing.value) {
      await _engine?.stopScreenCapture();
      isScreenSharing.value = false;
      screenSharingUid.value = 0;
      // Restore camera track (mobile API: publishScreenCaptureVideo)
      await _engine?.updateChannelMediaOptions(ChannelMediaOptions(
        publishCameraTrack: isCameraOn.value,
        publishScreenCaptureVideo: false,
        publishScreenCaptureAudio: false,
      ));
      // Update Firestore to clear screen sharing state
      FirebaseFirestore.instance
          .collection(FirebaseAudioConst.audioSpaces)
          .doc(audioSpace.id ?? '')
          .update({"screen_sharing_uid": 0});
    } else {
      // Rule: only one person can share at a time.
      // Admin can override (stops existing share). Hosts must wait.
      final currentSharer = screenSharingUid.value;
      if (currentSharer > 0 && currentSharer != myID) {
        if (!isMySpace.value) {
          showSnackBar('Someone is already sharing their screen',
              type: SnackBarType.error);
          return;
        }
        // Admin override: Firestore update will notify the sharer to stop
        Loggers.info('Admin override: stopping share from uid=$currentSharer');
      }
      // Start screen capture (mobile API)
      await _engine?.startScreenCapture(const ScreenCaptureParameters2(
        captureAudio: true,
        captureVideo: true,
        videoParams: ScreenVideoParameters(
          dimensions: VideoDimensions(width: 720, height: 1280),
          frameRate: 15,
          bitrate: 1500,
        ),
      ));
      isScreenSharing.value = true;
      screenSharingUid.value = myID;
      // Mobile API: use publishScreenCaptureVideo (NOT publishScreenTrack which is desktop-only)
      await _engine?.updateChannelMediaOptions(const ChannelMediaOptions(
        publishScreenCaptureVideo: true,
        publishScreenCaptureAudio: true,
        publishCameraTrack: false,
      ));
      // Update Firestore so other users know who is sharing
      FirebaseFirestore.instance
          .collection(FirebaseAudioConst.audioSpaces)
          .doc(audioSpace.id ?? '')
          .update({"screen_sharing_uid": myID});
    }
  }

  void requestForHost(AudioSpaceUser user) {
    if (user.type == AudioSpaceUserType.requested) {
      _changeUserType(user: user, type: AudioSpaceUserType.listener);
    } else {
      _changeUserType(user: user, type: AudioSpaceUserType.requested);
      showSnackBar(LKeys.requestHasBeenSetForHost.tr,
          type: SnackBarType.success);
    }
  }

  void acceptRequest(AudioSpaceUser user) {
    var hostsLimit =
        SessionManager.shared.getSettings()?.audioSpaceHostsLimit ?? 0;
    if (hostsLimit == 0 || audioSpace.hosts.length < hostsLimit) {
      _changeUserType(user: user, type: AudioSpaceUserType.host);
    } else {
      showSnackBar(LKeys.hostLimitReached.tr, type: SnackBarType.error);
    }
  }

  void kickOut(AudioSpaceUser user) {
    showConfirmationSheet(
        desc: LKeys.wantToKickOutUser,
        buttonTitle: LKeys.yes,
        onTap: () {
          _changeUserType(user: user, type: AudioSpaceUserType.kickedOut);
        });
  }

  void removeAddedUser(AudioSpaceUser user) {
    showConfirmationSheet(
        desc: LKeys.wantToRemoveUser,
        buttonTitle: LKeys.yes,
        onTap: () {
          var updatedUsers = List<AudioSpaceUser>.from(audioSpace.users ?? []);
          updatedUsers.removeWhere(
              (element) => element.id?.toInt() == user.id?.toInt());
          FirebaseFirestore.instance
              .collection(FirebaseAudioConst.audioSpaces)
              .doc(audioSpace.id ?? '')
              .update({"users": updatedUsers.map((e) => e.toJson()).toList()});
        });
  }

  void makeUserToListener(AudioSpaceUser user) {
    showConfirmationSheet(
        desc: LKeys.wantToMakeHostListener,
        buttonTitle: LKeys.yes,
        onTap: () {
          _changeUserType(
              user: user,
              type: AudioSpaceUserType.listener,
              micStatus: AudioSpaceMicStatus.muted);
        });
  }

  void rejectRequest(AudioSpaceUser user) {
    showConfirmationSheet(
        desc: LKeys.wantToRejectRequest,
        buttonTitle: LKeys.yes,
        onTap: () {
          _changeUserType(user: user, type: AudioSpaceUserType.listener);
        });
  }

  void micToggleOfUser(AudioSpaceUser user) {
    _changeUserType(
        user: user,
        micStatus: user.micStatus == AudioSpaceMicStatus.muted
            ? AudioSpaceMicStatus.on
            : AudioSpaceMicStatus.muted);
  }

  void _changeUserType(
      {required AudioSpaceUser user,
      AudioSpaceUserType? type,
      AudioSpaceMicStatus? micStatus}) {
    if (micStatus != null) user.micStatus = micStatus;
    if (type != null) user.type = type;

    var updatedUsers = List<AudioSpaceUser>.from(audioSpace.users ?? []);
    updatedUsers.removeWhere((e) => e.isSameActor(user));
    updatedUsers.add(user);

    FirebaseFirestore.instance
        .collection(FirebaseAudioConst.audioSpaces)
        .doc(audioSpace.id ?? '')
        .update({"users": updatedUsers.map((e) => e.toJson()).toList()});
  }

  void sendMessage() {
    if (messageTextController.text.trim().isEmpty) return;
    var id = DateTime.now().microsecondsSinceEpoch.toString();
    final actorUser = _createBasicAudioUser();
    var message = AudioSpaceMessage(
      id: id,
      content: messageTextController.text.trim(),
      time: DateTime.now(),
      userId: SessionManager.shared.getUserID(),
      senderCompanyId: actorUser.companyId,
      senderProfileType: actorUser.profileType,
      senderName: actorUser.actorName,
      senderUsername: actorUser.username,
      senderAvatar: actorUser.actorAvatar,
    );

    FirebaseFirestore.instance
        .collection(FirebaseAudioConst.audioSpaces)
        .doc(audioSpace.id ?? '')
        .collection(FirebaseAudioConst.messages)
        .doc(id)
        .set(message.toJson());

    messageTextController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (messageScrollController.hasClients) {
        messageScrollController.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _safeLeaveChannel() async {
    try {
      if (_engine != null) {
        // Stop screen sharing if active
        if (isScreenSharing.value) {
          try {
            await _engine?.stopScreenCapture();
          } catch (_) {}
          isScreenSharing.value = false;
        }
        // Disable video if active
        if (isVideoMode.value || isCameraOn.value) {
          try {
            await _engine?.muteLocalVideoStream(true);
            await _engine?.disableVideo();
          } catch (_) {}
          isCameraOn.value = false;
        }
        if (isJoined.value) {
          await _engine?.leaveChannel();
        }
        isJoined.value = false;
        _isJoining = false;
      }
    } catch (e) {
      Loggers.error("Leave error: $e");
    }
  }

  void _deleteFirebaseRoom() {
    FirebaseFirestore.instance
        .collection(FirebaseAudioConst.audioSpaces)
        .doc(audioSpace.id ?? '')
        .delete();
    _deleteAllMessages();
  }

  void performCleanup({bool isAdminEnding = false}) {
    if (_isCleanedUp) return;
    _isCleanedUp = true;
    _safeLeaveChannel();
    if (isMySpace.value && isAdminEnding) {
      _deleteFirebaseRoom();
    } else if (!isMySpace.value) {
      var myID = SessionManager.shared.getUserID();
      var actorUser = _createBasicAudioUser();
      var updatedUsers = List<AudioSpaceUser>.from(audioSpace.users ?? []);
      updatedUsers.removeWhere(
          (e) => e.id?.toInt() == myID && e.companyId == actorUser.companyId);
      FirebaseFirestore.instance
          .collection(FirebaseAudioConst.audioSpaces)
          .doc(audioSpace.id ?? '')
          .update({"users": updatedUsers.map((e) => e.toJson()).toList()});
    }
  }

  void leaveSpace() {
    if (isMySpace.value) {
      endRoom();
    } else {
      performCleanup();
      Get.back();
    }
  }

  void dragAndBack() {
    if (isMySpace.value) {
      _isCleanedUp = false;
      return;
    }
    performCleanup();
  }

  void selectType(AudioSpacePageType type) {
    selectedType.value = type;
    if (type == AudioSpacePageType.messages) readAllMessages();
  }

  void readAllMessages() => SessionManager.shared
      .setLastMessageReadDate(spaceId: audioSpace.id ?? '');

  int countOfUnreadMessages() {
    var lastDate = SessionManager.shared
        .getLastMessageReadDate(spaceId: audioSpace.id ?? '');
    if (lastDate == null) return messages.length;
    return messages.where((m) => m.time?.isAfter(lastDate) ?? true).length;
  }

  AudioSpaceUser get myUser {
    var actorUser = _createBasicAudioUser();
    return audioSpace.users
            ?.firstWhereOrNull((u) => u.isSameActor(actorUser)) ??
        actorUser;
  }

  AudioSpaceUser _createBasicAudioUser() {
    var user = SessionManager.shared.getUser();
    final actingCompanyId = SessionManager.shared.getActingCompanyId();
    final actingCompanyName = SessionManager.shared.getActingCompanyName();
    final isCompanyActor = actingCompanyId != null;
    final actorName = isCompanyActor
        ? (actingCompanyName?.trim().isNotEmpty == true
            ? actingCompanyName!.trim()
            : user?.fullName)
        : user?.fullName;
    return AudioSpaceUser(
        id: user?.id?.toInt(),
        username: isCompanyActor ? 'company-$actingCompanyId' : user?.username,
        fullName: actorName,
        image: isCompanyActor ? null : user?.profile,
        deviceToken: user?.deviceToken,
        deviceType: user?.deviceType,
        isVerified: user?.isVerified == 1,
        companyId: actingCompanyId,
        profileType: isCompanyActor ? 'company' : 'user',
        displayName: actorName,
        displayAvatar: isCompanyActor ? null : user?.profile,
        type: AudioSpaceUserType.listener,
        micStatus: AudioSpaceMicStatus.muted);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _endRoom();
      } else {
        _remainingSeconds--;
      }
    });
  }

  Future<void> _endRoom() async {
    performCleanup(isAdminEnding: true);
    Get.bottomSheet(AudioSpaceEndedForHostScreen(controller: this),
        isScrollControlled: true);
  }

  Future<void> endRoom() async {
    showConfirmationSheet(
        desc: LKeys.wantToEndTheRoom, buttonTitle: LKeys.yes, onTap: _endRoom);
  }

  void _deleteAllMessages() async {
    var collection = FirebaseFirestore.instance
        .collection(FirebaseAudioConst.audioSpaces)
        .doc(audioSpace.id ?? '')
        .collection(FirebaseAudioConst.messages);
    var snapshots = await collection.get();
    var batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  void showUserEndedScreen() {
    if (!(Get.isBottomSheetOpen ?? false)) {
      isJoined.value = false;
      _isJoining = false;
      Get.bottomSheet(const AudioSpaceEndedForUserScreen(),
          isScrollControlled: true, enableDrag: false);
    }
  }

  void showUserDetails(AudioSpaceUser user) {
    Get.bottomSheet(AudioSpaceUserSheet(user: user, controller: this),
        isScrollControlled: true);
  }

  void showAddUsersSheet() {
    Get.bottomSheet(
        AudioSpaceInviteScreen(
          audioSpaceUsers: audioSpace.users ?? [],
          onBack: (users) {
            FirebaseFirestore.instance
                .collection(FirebaseAudioConst.audioSpaces)
                .doc(audioSpace.id ?? '')
                .update({"users": users.map((e) => e.toJson()).toList()});
          },
        ),
        isScrollControlled: true);
  }

  @override
  void onClose() {
    WakelockPlus.disable();
    _timer?.cancel();
    spacesListener?.cancel();
    messagesListener?.cancel();
    _releaseEngine();
    super.onClose();
  }

  Future<void> _releaseEngine() async {
    try {
      if (agoraHandler != null) {
        _engine?.unregisterEventHandler(agoraHandler!);
      }
      if (isJoined.value) {
        await _engine?.leaveChannel();
      }
      await _engine?.release();
      _engine = null;
      isJoined.value = false;
      isEngineInitialized.value = false;
    } catch (e) {
      Loggers.error("Engine release error: $e");
    }
  }
}

enum AudioOutputMode {
  speakerphone,
  earpiece,
  muted,
}
