import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:untitled/screens/audio_space/models/audio_space_user.dart';

class AudioSpaceMessage {
  String? id;
  int? userId;
  String? content;
  DateTime? time;
  AudioSpaceUser? user;
  int? senderCompanyId;
  String? senderProfileType;
  String? senderName;
  String? senderUsername;
  String? senderAvatar;

  AudioSpaceMessage(
      {this.id,
      this.userId,
      this.content,
      this.time,
      this.senderCompanyId,
      this.senderProfileType,
      this.senderName,
      this.senderUsername,
      this.senderAvatar});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['userId'] = userId;
    map['content'] = content;
    map['time'] = time != null ? Timestamp.fromDate(time!) : null;
    map['sender_company_id'] = senderCompanyId;
    map['sender_profile_type'] = senderProfileType ?? 'user';
    map['sender_name'] = senderName;
    map['sender_username'] = senderUsername;
    map['sender_avatar'] = senderAvatar;
    return map;
  }

  factory AudioSpaceMessage.fromFireStore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return AudioSpaceMessage(
      id: data?['id'],
      userId: _safeInt(data?['userId']),
      content: data?['content'],
      time: (data?['time'] as Timestamp?)?.toDate(),
      senderCompanyId:
          _safeInt(data?['sender_company_id'] ?? data?['senderCompanyId']),
      senderProfileType:
          data?['sender_profile_type'] ?? data?['senderProfileType'],
      senderName: data?['sender_name'] ?? data?['senderName'],
      senderUsername: data?['sender_username'] ?? data?['senderUsername'],
      senderAvatar: data?['sender_avatar'] ?? data?['senderAvatar'],
    );
  }

  static int? _safeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  AudioSpaceMessage.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    userId = _safeInt(json["userId"]);
    content = json["content"];
    time = (json["time"] as Timestamp?)?.toDate();
    senderCompanyId =
        _safeInt(json["sender_company_id"] ?? json["senderCompanyId"]);
    senderProfileType =
        json["sender_profile_type"] ?? json["senderProfileType"];
    senderName = json["sender_name"] ?? json["senderName"];
    senderUsername = json["sender_username"] ?? json["senderUsername"];
    senderAvatar = json["sender_avatar"] ?? json["senderAvatar"];
  }

  String getChatTime() {
    if (time != null) return DateFormat('h:mm a').format(time!);
    var microseconds = int.tryParse(id ?? '0') ?? 0;
    return DateFormat('h:mm a').format(
      DateTime.fromMillisecondsSinceEpoch((microseconds / 1000).round()),
    );
  }
}
