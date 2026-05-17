import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:untitled/common/api_service/api_service.dart';
import 'package:untitled/common/api_service/room_service.dart';
import 'package:untitled/common/managers/firebase_notification_manager.dart';
import 'package:untitled/models/room_member_model.dart';
import 'package:untitled/utilities/params.dart';
import 'package:untitled/utilities/web_service.dart';

class NotificationService {
  static var shared = NotificationService();

  void sendToSingleUser({
    String? token,
    num? deviceType,
    required String title,
    required String body,
    String? conversationId,
    Map<String, String>? extraData,
  }) {
    if (token == null || token.isEmpty) return;

    Map<String, dynamic> dataPayload = {
      Param.conversationId: conversationId ?? '',
      "body": body,
      "title": title,
    };
    if (extraData != null) dataPayload.addAll(extraData);

    // Video calls (type 20): Android stays data-only so the background handler
    // can show CallKit. iOS receives an APNs alert fallback because PushKit/VoIP
    // entitlement is not configured in the current iOS project.
    final isVideoCall = extraData?['type'] == '20';

    Map<String, dynamic> messageData = {
      "token": token,
      "data": dataPayload,
      "android": <String, dynamic>{
        "priority": "high",
      },
      "apns": <String, dynamic>{
        "payload": <String, dynamic>{
          "aps": <String, dynamic>{
            "content-available": 1,
            if (isVideoCall) "alert": {"title": title, "body": body},
            "sound": "default",
            "badge": 1,
          }
        },
        "headers": <String, dynamic>{
          "apns-push-type": "alert",
          if (isVideoCall) "apns-priority": "10",
        },
      },
    };

    // Non-call messages: include notification payload for system tray display
    if (!isVideoCall) {
      messageData["notification"] = {"body": body, "title": title};
      messageData["android"]["notification"] = <String, dynamic>{
        "sound": "default",
        "channel_id": "high_importance_channel",
        "default_vibrate_timings": true,
      };
    }

    Map<String, dynamic> inputData = {"message": messageData};
    commonSend(inputData);
  }

  void sendToTopic({
    String? topic,
    required String title,
    required String body,
    required String conversationId,
  }) {
    final dataPayload = {Param.conversationId: conversationId, "body": body, "title": title};
    final notifPayload = {"body": body, "title": title};

    // Android topic
    commonSend({"message": {
      "topic": '${topic}_android',
      "notification": notifPayload,
      "data": dataPayload,
      "android": {
        "priority": "high",
        "notification": {
          "sound": "default",
          "channel_id": "high_importance_channel",
          "default_vibrate_timings": true,
        }
      },
    }});

    // iOS topic
    commonSend({"message": {
      "topic": '${topic}_ios',
      "notification": notifPayload,
      "data": dataPayload,
      "apns": {
        "payload": {
          "aps": {"sound": "default", "badge": 1}
        }
      },
    }});
  }

  void commonSend(Map<String, dynamic> inputData) {
    final headers = Map<String, String>.from(ApiService.shared.header);
    headers['Content-Type'] = 'application/json';
    http.post(
      Uri.parse(WebService.pushNotificationToSingleUser),
      headers: headers,
      body: json.encode(inputData),
    ).then((value) {
      print('FCM proxy response: ${value.statusCode} ${value.body}');
    }).catchError((e) {
      print('FCM proxy error: $e');
    });
  }

  void getMyRooms(Function(List<RoomMember> rooms) completion) {
    RoomService.shared.fetchRoomsIAmIn((rooms) {
      completion(rooms);
    });
  }

  void subscribeToAllMyRoom() {
    getMyRooms((rooms) {
      for (var element in rooms) {
        if (element.isMute == 0) {
          FirebaseNotificationManager.shared.subscribeToTopic('room_${element.roomId ?? 0}');
        }
      }
    });
  }

  void unsubscribeToAllMyRoom() {
    getMyRooms((rooms) {
      for (var element in rooms) {
        FirebaseNotificationManager.shared.unsubscribeToTopic('room_${element.roomId ?? 0}');
      }
    });
  }
}
