class AudioSpaceUser {
  int? id;
  String? username;
  String? fullName;
  String? image;
  String? deviceToken;
  num? deviceType;
  bool? isVerified;
  int? companyId;
  String? profileType;
  String? displayName;
  String? displayAvatar;
  AudioSpaceUserType? type;
  AudioSpaceMicStatus? micStatus;
  bool isCameraOn;

  AudioSpaceUser({
    String? username,
    String? fullName,
    num? deviceType,
    String? deviceToken,
    String? image,
    bool? isVerified,
    num? id,
    int? companyId,
    String? profileType,
    String? displayName,
    String? displayAvatar,
    AudioSpaceUserType? type,
    AudioSpaceMicStatus? micStatus,
    this.isCameraOn = false,
  }) {
    this.username = username;
    this.fullName = fullName;
    this.deviceType = deviceType;
    this.deviceToken = deviceToken;
    this.image = image;
    this.isVerified = isVerified;
    this.id = id?.toInt();
    this.companyId = companyId;
    this.profileType = profileType;
    this.displayName = displayName;
    this.displayAvatar = displayAvatar;
    this.type = type;
    this.micStatus = micStatus;
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': username,
      "fullName": fullName,
      "deviceType": deviceType,
      "deviceToken": deviceToken,
      "image": image,
      "isVerified": isVerified,
      "id": id?.toInt(),
      "company_id": companyId,
      "profile_type": profileType ?? "user",
      "display_name": displayName ?? fullName,
      "display_avatar": displayAvatar ?? image,
      "type": type?.value ?? AudioSpaceUserType.listener.value,
      "mic_status": micStatus?.value ?? AudioSpaceMicStatus.muted.value,
      "is_camera_on": isCameraOn,
    };
  }

  static int? _safeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? _safeBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return null;
  }

  static num? _safeNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  AudioSpaceUser.fromJson(Map<String, dynamic> json)
      : isCameraOn = _safeBool(json["is_camera_on"]) ?? false {
    username = json["userName"];
    fullName = json["fullName"];
    deviceToken = json["deviceToken"];
    deviceType = _safeNum(json["deviceType"]);
    image = json["image"];
    isVerified = _safeBool(json["isVerified"]);
    id = _safeInt(json["id"]);
    companyId = _safeInt(json["company_id"] ?? json["companyId"]);
    profileType = json["profile_type"] ?? json["profileType"] ?? "user";
    displayName = json["display_name"] ?? json["displayName"];
    displayAvatar = json["display_avatar"] ?? json["displayAvatar"];
    type = AudioSpaceUserType.values.firstWhere(
      (element) => element.value == json["type"],
      orElse: () => AudioSpaceUserType.listener,
    );
    micStatus = AudioSpaceMicStatus.values.firstWhere(
      (element) => element.value == json["mic_status"],
      orElse: () => AudioSpaceMicStatus.muted,
    );
  }
}

enum AudioSpaceUserType {
  listener('LISTENER'),
  host('HOST'),
  admin('ADMIN'),
  requested('REQUESTED'),
  kickedOut('KICKED_OUT'),
  added('ADDED');

  final String value;

  const AudioSpaceUserType(this.value);
}

enum AudioSpaceMicStatus {
  notGranted('NOT_GRANTED'),
  muted('MUTED'),
  on('ON');

  final String value;

  const AudioSpaceMicStatus(this.value);
}
