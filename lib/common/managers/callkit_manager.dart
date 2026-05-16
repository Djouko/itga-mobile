import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/video_call/video_call_screen.dart';
import 'package:uuid/uuid.dart';

/// Manages native incoming call screens (WhatsApp/Messenger style).
/// Uses flutter_callkit_incoming for:
/// - Android: Full-screen incoming call notification
/// - iOS: Native CallKit integration
///
/// Handles the critical edge case where the app is terminated:
/// When user accepts a call from killed state, the app launches fresh
/// but Get.to() can't work until the nav stack is ready. We store
/// pending call data and navigate once markNavigationReady() is called
/// (same pattern as WhatsApp/Messenger).
class CallKitManager {
  static final shared = CallKitManager._();
  CallKitManager._();

  bool _isListening = false;
  bool _isNavigationReady = false;
  Map<String, dynamic>? _pendingCallData;

  /// Track if a call is currently active (prevents duplicate call screens)
  bool isInCall = false;
  String? activeChannelId;

  /// Initialize CallKit event listeners — call once at app startup.
  void init() {
    if (_isListening) return;
    _isListening = true;

    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      Loggers.info('CallKit event: ${event.event} body=${event.body}');

      switch (event.event) {
        case Event.actionCallIncoming:
          Loggers.info('CallKit: Incoming call received');
          break;
        case Event.actionCallAccept:
          _onCallAccepted(event.body);
          break;
        case Event.actionCallDecline:
          _onCallDeclined(event.body);
          break;
        case Event.actionCallTimeout:
          _onCallTimeout(event.body);
          break;
        case Event.actionCallCallback:
          _onCallCallback(event.body);
          break;
        case Event.actionCallEnded:
          Loggers.info('CallKit: Call ended');
          isInCall = false;
          activeChannelId = null;
          break;
        default:
          break;
      }
    });

    // Check if app was launched by accepting a call (terminated state)
    _checkForAcceptedCallOnLaunch();

    Loggers.success('CallKit: Event listeners initialized');
  }

  /// Called from TabBarController once the navigation stack is fully ready.
  /// If a call was accepted while app was terminated, navigate now.
  void markNavigationReady() {
    _isNavigationReady = true;
    Loggers.info('CallKit: Navigation marked ready');
    _tryPendingCall();
  }

  Future<void> _checkForAcceptedCallOnLaunch() async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is List && calls.isNotEmpty) {
        final call = calls.first;
        Loggers.info('CallKit: Found active call on launch: $call');
        // This call was accepted while app was terminated
        _onCallAccepted(call is Map<String, dynamic> ? call : null);
      }
    } catch (e) {
      Loggers.error('CallKit: Error checking active calls: $e');
    }
  }

  void _tryPendingCall() {
    if (_pendingCallData != null && _isNavigationReady) {
      Loggers.info('CallKit: Executing pending call navigation');
      final data = _pendingCallData!;
      _pendingCallData = null;
      _navigateToVideoCall(data);
    }
  }

  /// Show native incoming call screen when a video call notification arrives.
  Future<void> showIncomingCall({
    required String channelId,
    required String agoraToken,
    required int callerId,
    required String callerName,
    String? callerImage,
    String callerProfileType = 'user',
    int? callerCompanyId,
  }) async {
    final callUUID = const Uuid().v4();

    final params = CallKitParams(
      id: callUUID,
      nameCaller: callerName,
      appName: 'Chatter',
      avatar: callerImage,
      handle: 'Video Call',
      type: 1, // 0 = audio, 1 = video
      duration: 45000, // 45 sec ring timeout (WhatsApp uses ~45s)
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed video call',
        callbackText: 'Call back',
      ),
      extra: <String, dynamic>{
        'channel_id': channelId,
        'agora_token': agoraToken,
        'caller_id': '$callerId',
        'caller_name': callerName,
        'caller_image': callerImage ?? '',
        'caller_profile_type': callerProfileType,
        'caller_company_id': callerCompanyId == null ? '' : '$callerCompanyId',
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#1C1C1E',
        backgroundUrl: '',
        actionColor: '#4CAF50',
        textColor: '#FFFFFF',
        incomingCallNotificationChannelName: 'Incoming Video Call',
        isShowCallID: false,
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: false,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
    Loggers.info(
        'CallKit: Showing incoming call from $callerName (uuid=$callUUID)');
  }

  /// Show outgoing call indicator (optional, for caller UX).
  Future<void> showOutgoingCall({
    required String channelId,
    required String calleeName,
    String? calleeImage,
  }) async {
    final callUUID = const Uuid().v4();

    final params = CallKitParams(
      id: callUUID,
      nameCaller: calleeName,
      appName: 'Chatter',
      avatar: calleeImage,
      handle: 'Video Call',
      type: 1,
      extra: <String, dynamic>{
        'channel_id': channelId,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        backgroundColor: '#1C1C1E',
        actionColor: '#4CAF50',
        textColor: '#FFFFFF',
      ),
      ios: const IOSParams(
        handleType: 'generic',
        supportsVideo: true,
      ),
    );

    await FlutterCallkitIncoming.startCall(params);
  }

  /// End any active call (cleanup).
  Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
  }

  /// End a specific call.
  Future<void> endCall(String callId) async {
    await FlutterCallkitIncoming.endCall(callId);
  }

  // ── Event handlers ──

  void _onCallAccepted(Map<String, dynamic>? body) {
    Loggers.info('CallKit: Call ACCEPTED — body=$body');
    if (body == null) return;

    final extra = _extractExtra(body);
    if (extra == null || extra.isEmpty) {
      Loggers.error('CallKit: No extra data in accepted call body');
      return;
    }

    if (_isNavigationReady) {
      _navigateToVideoCall(extra);
    } else {
      // App was terminated — queue the call for when nav stack is ready
      Loggers.info('CallKit: Nav not ready, queuing pending call');
      _pendingCallData = extra;
    }
  }

  Future<void> _navigateToVideoCall(Map<String, dynamic> extra) async {
    final channelId = extra['channel_id']?.toString();
    final agoraToken = extra['agora_token']?.toString();
    final callerName = extra['caller_name']?.toString();
    final callerImage = extra['caller_image']?.toString();
    final callerProfileType =
        extra['caller_profile_type']?.toString() ?? 'user';
    final callerCompanyId = int.tryParse('${extra['caller_company_id'] ?? ''}');
    final callerId = int.tryParse('${extra['caller_id'] ?? ''}') ?? 0;

    if (channelId == null || agoraToken == null) {
      Loggers.error('CallKit: Missing channel_id or agora_token');
      return;
    }

    // If already in a call on the same channel, don't open a second screen
    if (isInCall && activeChannelId == channelId) {
      Loggers.info(
          'CallKit: Already in call on channel=$channelId, skipping duplicate');
      await endAllCalls();
      return;
    }

    Loggers.info('CallKit: Navigating to VideoCallScreen (channel=$channelId)');

    // Track active call state
    isInCall = true;
    activeChannelId = channelId;

    // End the native call UI BEFORE navigating to in-app call screen
    await endAllCalls();

    // Small delay to ensure CallKit UI is fully dismissed
    await Future.delayed(const Duration(milliseconds: 200));

    Get.to(() => VideoCallScreen(
          channelId: channelId,
          token: agoraToken,
          isOutgoing: false,
          remoteUser: User(
            id: callerId,
            fullName: callerName,
            profile: callerImage,
            profileType: callerProfileType,
            username: callerProfileType == 'company' && callerCompanyId != null
                ? 'company-$callerCompanyId'
                : null,
            bio: callerProfileType == 'company' ? 'Entreprise ITGA' : null,
          ),
        ));
  }

  /// Called when the video call ends (from VideoCallController)
  void markCallEnded() {
    isInCall = false;
    activeChannelId = null;
  }

  /// Robustly extract the 'extra' map from CallKit event body.
  /// flutter_callkit_incoming returns different formats on different platforms:
  /// - Map<String, dynamic> (ideal)
  /// - Map<Object?, Object?> (Android some versions)
  /// - The body itself may contain channel_id directly (fallback)
  Map<String, dynamic>? _extractExtra(Map<String, dynamic> body) {
    try {
      final rawExtra = body['extra'];
      if (rawExtra is Map<String, dynamic>) {
        return rawExtra;
      } else if (rawExtra is Map) {
        return rawExtra.map((k, v) => MapEntry(k.toString(), v));
      } else if (rawExtra is String && rawExtra.isNotEmpty) {
        try {
          final decoded = Uri.splitQueryString(rawExtra);
          if (decoded.containsKey('channel_id')) return decoded;
        } catch (_) {}
      }
    } catch (e) {
      Loggers.error('CallKit: Error extracting extra from body[extra]: $e');
    }

    // Fallback: some CallKit versions put extra fields directly in body
    if (body.containsKey('channel_id')) {
      Loggers.info('CallKit: Found channel_id directly in body (fallback)');
      return body;
    }

    return null;
  }

  /// Handle "Call back" tap from missed call notification.
  /// Per flutter_callkit_incoming docs: Event.actionCallCallback fires when
  /// user clicks "Call back" from missed call notification.
  void _onCallCallback(Map<String, dynamic>? body) {
    Loggers.info('CallKit: Call CALLBACK (missed call tap) — body=$body');
    if (body == null) return;

    final extra = _extractExtra(body);
    if (extra == null || extra.isEmpty) {
      Loggers.error('CallKit: No extra data in callback body');
      return;
    }

    // Navigate to call — same flow as accept
    if (_isNavigationReady) {
      _navigateToVideoCall(extra);
    } else {
      _pendingCallData = extra;
    }
  }

  void _onCallDeclined(Map<String, dynamic>? body) {
    Loggers.info('CallKit: Call DECLINED');
    isInCall = false;
    activeChannelId = null;
    endAllCalls();
  }

  void _onCallTimeout(Map<String, dynamic>? body) {
    Loggers.info('CallKit: Call TIMED OUT — showing missed call');
    endAllCalls();
  }
}
