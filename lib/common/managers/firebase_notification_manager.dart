import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/controller/notification_badge_controller.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/screens/notification_screen/notification_screen.dart';
import 'package:untitled/models/chat.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/chats_screen/chatting_screen/chatting_view.dart';
import 'package:untitled/screens/single_post_screen/single_post_screen.dart';
import 'package:untitled/screens/single_reel_screen/single_reel_screen.dart';
import 'package:untitled/screens/video_call/video_call_screen.dart';
import 'package:untitled/common/managers/callkit_manager.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/params.dart';

class FirebaseNotificationManager {
  static var shared = FirebaseNotificationManager();
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  AndroidNotificationChannel channel = const AndroidNotificationChannel(
      'high_importance_channel', 'Chatter Notifications',
      description: 'Notifications from Chatter app',
      playSound: true,
      enableLights: true,
      enableVibration: true,
      importance: Importance.max);

  int _notificationIdCounter = 0;

  String newMessageId = '';

  bool _isInitialized = false;
  bool _isNavigationReady = false;
  Map<String, dynamic>? _pendingNavData;

  void init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, sound: true);

    await firebaseMessaging.requestPermission(
        alert: true, badge: true, sound: true);

    // iOS: ensure notifications show even when app is in foreground
    await firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    Loggers.success("FCM permissions configured");

    var initializationSettingsAndroid = const AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    var initializationSettingsIOS = const DarwinInitializationSettings(
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: false);

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Background → foreground: user tapped system notification while app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      Loggers.info('FCM onMessageOpenedApp: ${message.data}');
      _scheduleNavigation(message.data);
    });

    // Terminated → launch: user tapped notification that launched the app from scratch
    // Call immediately — navigation will be queued until markNavigationReady()
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        Loggers.info(
            'FCM getInitialMessage (terminated launch): ${message.data}');
        _scheduleNavigation(message.data);
      }
    });

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    getNotificationToken((token) {
      if (token != 'No Token') {
        _updateDeviceTokenOnServer(token);
      }
    });
    // Initialize CallKit for native incoming call screen (WhatsApp/Messenger style)
    CallKitManager.shared.init();

    subscribeToTopic(notificationTopic);

    firebaseMessaging.onTokenRefresh.listen((newToken) {
      Loggers.info('FCM token refreshed: $newToken');
      _updateDeviceTokenOnServer(newToken);
    });
  }

  /// Called from TabBarController once the navigation stack is fully ready.
  void markNavigationReady() {
    _isNavigationReady = true;
    Loggers.info('FCM: Navigation marked ready');
    _tryPendingNavigation();
  }

  void _scheduleNavigation(Map<String, dynamic> data) {
    // Video call notifications → always show native incoming call screen
    final type = int.tryParse('${data['type'] ?? ''}') ?? 0;
    if (type == 20) {
      Loggers.info(
          'FCM: Incoming video call from background/terminated — showing native call screen');
      _showIncomingCallScreen(data);
      return;
    }

    if (_isNavigationReady) {
      _safeNavigate(data);
    } else {
      Loggers.info('FCM: Queuing pending navigation (nav not ready yet)');
      _pendingNavData = data;
    }
  }

  void _tryPendingNavigation() {
    if (_pendingNavData != null) {
      final data = Map<String, dynamic>.from(_pendingNavData!);
      _pendingNavData = null;
      Loggers.info('FCM: Executing pending navigation: $data');
      _safeNavigate(data);
    }
  }

  void _safeNavigate(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateFromData(data);
    });
  }

  /// Show native incoming call screen (WhatsApp/Messenger style) for video calls.
  void _showIncomingCallScreen(Map<String, dynamic> data) {
    final channelId = data['channel_id']?.toString() ?? '';
    final agoraToken = data['agora_token']?.toString() ?? '';
    final callerName = data['caller_name']?.toString() ?? 'Someone';
    final callerImage = data['caller_image']?.toString();
    final callerId = int.tryParse('${data['caller_id'] ?? ''}') ?? 0;
    final callerProfileType = data['caller_profile_type']?.toString() ?? 'user';
    final callerCompanyId = int.tryParse('${data['caller_company_id'] ?? ''}');

    if (channelId.isEmpty || agoraToken.isEmpty) {
      Loggers.error(
          'CallKit: Missing channel_id or agora_token in notification data');
      return;
    }

    // WhatsApp pattern: if already in a call, show "busy" notification instead of ringing
    if (CallKitManager.shared.isInCall) {
      Loggers.info(
          'FCM: User is already in a call — showing busy notification for $callerName');
      showNotification(RemoteMessage(data: {
        'title': callerName,
        'body': 'Missed video call (you were on another call)',
        'type': '0',
      }));
      return;
    }

    CallKitManager.shared.showIncomingCall(
      channelId: channelId,
      agoraToken: agoraToken,
      callerId: callerId,
      callerName: callerName,
      callerImage: callerImage,
      callerProfileType: callerProfileType,
      callerCompanyId: callerCompanyId,
    );
  }

  void _updateDeviceTokenOnServer(String token) {
    final userId = SessionManager.shared.getUserID();
    if (userId == 0) return;
    UserService.shared.editProfile(deviceToken: token);
  }

  void showNotification(RemoteMessage message) {
    String? payload;
    try {
      payload = jsonEncode(message.data);
    } catch (_) {}
    _notificationIdCounter++;
    flutterLocalNotificationsPlugin.show(
      _notificationIdCounter,
      message.data['title'],
      message.data['body'],
      NotificationDetails(
        iOS: const DarwinNotificationDetails(
            presentSound: true, presentAlert: true, presentBadge: true),
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload == null || response.payload!.isEmpty) {
      Get.to(() => const NotificationScreen());
      return;
    }
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _navigateFromData(data);
    } catch (_) {
      Get.to(() => const NotificationScreen());
    }
  }

  /// Build a ChatUserRoom with proper type and userIdOrRoomId from conversationId.
  /// Room format: 'room_{roomId}' → type=2
  /// 1-on-1 format: '{id1}-{id2}' (sorted) → type=1, other user's ID
  ChatUserRoom _buildChatUserRoom(String conversationId) {
    if (conversationId.startsWith('room_')) {
      final roomId = int.tryParse(conversationId.replaceFirst('room_', ''));
      return ChatUserRoom(
          conversationId: conversationId, userIdOrRoomId: roomId, type: 2);
    }
    // 1-on-1 chat: extract the OTHER user's ID
    final parts = conversationId.split('-');
    final myId = SessionManager.shared.getUserID();
    int? otherUserId;
    if (parts.length == 2) {
      final id1 = int.tryParse(parts[0]);
      final id2 = int.tryParse(parts[1]);
      if (id1 != null && id2 != null) {
        otherUserId = (id1 == myId) ? id2 : id1;
      }
    }
    return ChatUserRoom(
        conversationId: conversationId, userIdOrRoomId: otherUserId, type: 1);
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final type = int.tryParse('${data['type'] ?? ''}') ?? 0;
    final postId = int.tryParse('${data['post_id'] ?? ''}') ?? 0;
    final reelId = int.tryParse('${data['reel_id'] ?? ''}') ?? 0;
    final userId = int.tryParse('${data['user_id'] ?? ''}') ?? 0;
    final conversationId = data[Param.conversationId]?.toString();

    Loggers.info(
        'Notification tap: type=$type postId=$postId reelId=$reelId userId=$userId convId=$conversationId');

    switch (type) {
      case 1: // follow
        Get.to(() => const NotificationScreen());
        break;
      case 2: // comment
      case 3: // liked post
      case 11: // mentioned in post
      case 12: // mentioned in comment
      case 15: // reposted post → navigate to the repost itself
        if (postId > 0) {
          Get.to(() => SinglePostScreen(postId: postId));
        } else {
          Get.to(() => const NotificationScreen());
        }
        break;
      case 9: // liked reel
      case 10: // commented on reel
      case 13: // mentioned in reel comment
      case 14: // mentioned in reel
        if (reelId > 0) {
          Get.to(() => SingleReelScreen(reelId: reelId));
        } else {
          Get.to(() => const NotificationScreen());
        }
        break;
      case 4: // chat message
      case 5: // room message
        if (conversationId != null && conversationId.isNotEmpty) {
          Get.to(() =>
              ChattingView(chatUserRoom: _buildChatUserRoom(conversationId)));
        } else {
          Get.to(() => const NotificationScreen());
        }
        break;
      case 20: // incoming video call
        final callChannelId = data['channel_id']?.toString();
        final callToken = data['agora_token']?.toString();
        final callerName = data['caller_name']?.toString();
        final callerImage = data['caller_image']?.toString();
        final callerProfileType =
            data['caller_profile_type']?.toString() ?? 'user';
        final callerCompanyId =
            int.tryParse('${data['caller_company_id'] ?? ''}');
        final callerId = int.tryParse('${data['caller_id'] ?? ''}') ?? 0;
        // If already in this call, don't open a duplicate screen
        if (CallKitManager.shared.isInCall &&
            CallKitManager.shared.activeChannelId == callChannelId) {
          Loggers.info(
              'FCM: Already in call $callChannelId — skipping duplicate navigation');
          break;
        }
        if (callChannelId != null && callToken != null) {
          CallKitManager.shared.isInCall = true;
          CallKitManager.shared.activeChannelId = callChannelId;
          Get.to(() => VideoCallScreen(
                channelId: callChannelId,
                token: callToken,
                isOutgoing: false,
                remoteUser: User(
                  id: callerId,
                  fullName: callerName,
                  profile: callerImage,
                  profileType: callerProfileType,
                  username:
                      callerProfileType == 'company' && callerCompanyId != null
                          ? 'company-$callerCompanyId'
                          : null,
                  bio:
                      callerProfileType == 'company' ? 'Entreprise ITGA' : null,
                ),
              ));
        }
        break;
      default:
        if (conversationId != null && conversationId.isNotEmpty) {
          Get.to(() =>
              ChattingView(chatUserRoom: _buildChatUserRoom(conversationId)));
        } else if (reelId > 0) {
          Get.to(() => SingleReelScreen(reelId: reelId));
        } else if (postId > 0) {
          Get.to(() => SinglePostScreen(postId: postId));
        } else {
          Get.to(() => const NotificationScreen());
        }
    }
  }

  void getNotificationToken(Function(String token) completion) {
    try {
      FirebaseMessaging.instance.getToken().then(
        (value) {
          if (value?.isEmpty == true || value == null) {
            Loggers.error('Token: $value');
            completion('No Token');
          } else {
            Loggers.success('Token: $value');
            completion(value);
          }
        },
        onError: (e) {
          completion('No Token');
        },
      );
    } catch (e) {
      completion('No Token');
    }
  }

  void subscribeToTopic(String topic) async {
    var user = SessionManager.shared.getUser();
    if (user == null || user.isPushNotifications == 1) {
      await firebaseMessaging
          .subscribeToTopic('${topic}_${Platform.isIOS ? 'ios' : 'android'}')
          .onError((error, stackTrace) {
        Loggers.error('FCM topic subscription failed: $error');
      });

      if (kDebugMode) {
        await firebaseMessaging.subscribeToTopic(
            'test_${topic}_${Platform.isIOS ? 'ios' : 'android'}');
      }
    }
  }

  void unsubscribeToTopic(String topic) async {
    await firebaseMessaging
        .unsubscribeFromTopic('${topic}_${Platform.isIOS ? 'ios' : 'android'}');

    if (kDebugMode) {
      await firebaseMessaging.unsubscribeFromTopic(
          'test_${topic}_${Platform.isIOS ? 'ios' : 'android'}');
    }
  }

  bool hasListenerSet = false;

  void setupListener() async {
    if (hasListenerSet) {
      return;
    }
    hasListenerSet = true;
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Loggers.info('FCM foreground: ${message.data}');

      if (message.data[Param.conversationId] ==
          SessionManager.shared.getStoredConversation()) {
        Loggers.info('Suppressing notification — user is in same chat');
        return;
      }

      // Handle incoming video call — show native call screen (WhatsApp style)
      final type = int.tryParse('${message.data['type'] ?? ''}') ?? 0;
      if (type == 20) {
        Loggers.info(
            'FCM foreground: Incoming video call — showing native call screen');
        _showIncomingCallScreen(message.data);
        return;
      }

      final msgId = message.messageId;
      if (msgId != null && (msgId != newMessageId || Platform.isAndroid)) {
        newMessageId = msgId;
        if (Get.isRegistered<NotificationBadgeController>()) {
          NotificationBadgeController.to.incrementOptimistically();
          NotificationBadgeController.to.fetchUnreadCount();
        }
        showNotification(message);
      }
    });
  }
}
