import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:audio_session/audio_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/managers/subscription_manager.dart';
import 'package:untitled/common/widgets/functions.dart';
import 'package:untitled/localization/allLanguages.dart';
import 'package:untitled/screens/splash_screen/splash_screen_view.dart';
import 'package:untitled/utilities/const.dart';

import 'common/managers/ads/interstitial_manager.dart';
import 'common/managers/connectivity_service.dart';
import 'localization/languages.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  Loggers.success("Background message received: ${message.data}");

  // Video call (type 20): Show native incoming call screen via CallKit
  // even when app is completely killed — exactly how WhatsApp/Messenger work.
  final type = int.tryParse('${message.data['type'] ?? ''}') ?? 0;
  if (type == 20) {
    final channelId = message.data['channel_id']?.toString() ?? '';
    final agoraToken = message.data['agora_token']?.toString() ?? '';
    final callerName = message.data['caller_name']?.toString() ?? 'Someone';
    final callerImage = message.data['caller_image']?.toString();
    final callerId = message.data['caller_id']?.toString() ?? '0';

    if (channelId.isNotEmpty && agoraToken.isNotEmpty) {
      final params = CallKitParams(
        id: channelId,
        nameCaller: callerName,
        appName: 'Chatter',
        avatar: callerImage,
        handle: 'Video Call',
        type: 1,
        duration: 45000,
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
          'caller_id': callerId,
          'caller_name': callerName,
          'caller_image': callerImage ?? '',
        },
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#1C1C1E',
          actionColor: '#4CAF50',
          textColor: '#FFFFFF',
          incomingCallNotificationChannelName: 'Incoming Video Call',
          isShowCallID: false,
        ),
        ios: const IOSParams(
          handleType: 'generic',
          supportsVideo: true,
          maximumCallGroups: 1,
          maximumCallsPerCallGroup: 1,
          ringtonePath: 'system_ringtone_default',
        ),
      );
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    }
    return;
  }
  // Non-call messages: Android system tray handles them automatically
  // when payload has a 'notification' key — no action needed here.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp();
  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await GetStorage.init();
  SessionManager.shared;
  InterstitialManager.shared;
  await AppTrackingTransparency.requestTrackingAuthorization();
  PackageInfo.fromPlatform();
  SubscriptionManager.shared.initPlatformState();
  MobileAds.instance.initialize();
  (await AudioSession.instance)
      .configure(const AudioSessionConfiguration.speech());
  Get.put(ConnectivityService(), permanent: true);

  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.library == 'image resource service' &&
        (details.exception.toString().contains('404') ||
            details.exception.toString().contains('403'))) {
      return;
    }

    FlutterError.presentError(details);
  };
  // fvp.registerWith();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Functions.changStatusBar(StatusBarStyle.black);
    Lang lang = SessionManager.shared.getLang();

    return GetMaterialApp(
      translations: Languages(),
      locale: lang.language.local,
      builder: (context, child) {
        return ScrollConfiguration(behavior: MyScrollBehavior(), child: child!);
      },
      fallbackLocale: LANGUAGES.first.language.local,
      debugShowCheckedModeBanner: false,
      title: appName,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.light,
        scaffoldBackgroundColor: cBG,
        primaryColor: cPrimary,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: cPrimary,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: cDarkBG,
        primaryColor: cPrimary,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: cPrimary,
          brightness: Brightness.dark,
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SplashScreenView(),
    );
  }
}

class MyScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
