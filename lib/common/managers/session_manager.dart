import 'dart:io';

import 'package:get_storage/get_storage.dart';
import 'package:untitled/localization/allLanguages.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/setting_model.dart';

class SessionManager {
  static var shared = SessionManager();
  var storage = GetStorage();
  var conversationId = '';

  void setLang(Lang lang) {
    storage.write("lang", lang.language.languageCode);
  }

  Lang getLang() {
    return LANGUAGES.firstWhere((element) => element.language.languageCode == (storage.read("lang") ?? LANGUAGES.first.language.languageCode));
  }

  String getStoredConversation() {
    return conversationId;
  }

  void setStoredConversation(String conversation) {
    conversationId = conversation;
  }

  DateTime? getLastMessageReadDate({required String spaceId}) {
    var date = storage.read(spaceId);
    if (date is int) return DateTime.fromMillisecondsSinceEpoch(date);
    if (date is DateTime) return date;
    return null;
  }

  void setLastMessageReadDate({required String spaceId}) {
    storage.write(spaceId, DateTime.now().millisecondsSinceEpoch);
  }

  bool isLogin() {
    return storage.read(SessionKeys.isLogin) ?? false;
  }

  void setUsersForGroup({required String conversationId, required List<User> users}) {
    storage.write(conversationId, users.map((u) => u.toJson()).toList());
  }

  List<User> getUsersForGroup({required String conversationId}) {
    var users = storage.read(conversationId);
    if (users is List<User>) {
      return users;
    } else if (users is List<dynamic>) {
      return users.map((user) => User.fromJson(user)).toList();
    }
    return [];
  }

  void setLogin(bool isLog) {
    storage.write(SessionKeys.isLogin, isLog);
  }

  void setUser(User? obj) {
    storage.write("user", obj?.toJson());
  }

  void setApiAuthToken(String? token) {
    if (token == null || token.trim().isEmpty) {
      storage.remove(SessionKeys.apiAuthToken);
      return;
    }
    storage.write(SessionKeys.apiAuthToken, token);
  }

  String? getApiAuthToken() {
    final token = storage.read(SessionKeys.apiAuthToken);
    if (token is String && token.trim().isNotEmpty) {
      return token;
    }
    return null;
  }

  void clearApiAuthToken() {
    storage.remove(SessionKeys.apiAuthToken);
  }

  User? getUser() {
    var user = storage.read("user");
    if (user is User?) {
      return user;
    } else {
      return User.fromJson(user);
    }
  }

  int getUserID() {
    return (getUser()?.id ?? 0).toInt();
  }

  void setSettings(Settings settings) {
    storage.write("setting", settings.toJson());
  }

  Settings? getSettings() {
    var data = storage.read("setting");
    if (data is Map<String, dynamic>) {
      return Settings.fromJson(data);
    } else if (data is Settings) {
      return data;
    }
    return null;
  }

  String getBannerAdId() {
    return (Platform.isAndroid ? (getSettings()?.adBannerAndroid) : (getSettings()?.adBannerIOs)) ?? '';
  }

  String getInterstitialAdId() {
    return (Platform.isAndroid ? (getSettings()?.adInterstitialAndroid) : (getSettings()?.adInterstitialIOs)) ?? '';
  }

  bool isAdMobOn() {
    return getSettings()?.isAdmobOn == 1 ? true : false;
  }

  void setActingCompany(int? id, String? name) {
    if (id == null) {
      storage.remove(SessionKeys.actingCompanyId);
      storage.remove(SessionKeys.actingCompanyName);
    } else {
      storage.write(SessionKeys.actingCompanyId, id);
      storage.write(SessionKeys.actingCompanyName, name ?? '');
    }
  }

  int? getActingCompanyId() {
    final val = storage.read(SessionKeys.actingCompanyId);
    if (val == null) return null;
    final id = val is int ? val : int.tryParse(val.toString());
    return (id != null && id > 0) ? id : null;
  }

  String? getActingCompanyName() => storage.read(SessionKeys.actingCompanyName);

  bool isCompanyActingMode() => getActingCompanyId() != null;

  void clear() {
    storage.erase();
  }
}

class SessionKeys {
  static const isLogin = "isLogin";
  static const apiAuthToken = "apiAuthToken";
  static const actingCompanyId = "actingCompanyId";
  static const actingCompanyName = "actingCompanyName";
}
