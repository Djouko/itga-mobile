import 'package:flutter/material.dart';
import 'package:untitled/common/api_service/post_service.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/api_service/room_service.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/posts_model.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/room_model.dart';
import 'package:untitled/models/setting_model.dart';

class ReportController extends BaseController {
  final List<SettingCommon> reasons = _resolveReportReasons();
  SettingCommon? selectedReason;
  TextEditingController reasonTextController = TextEditingController();

  static List<SettingCommon> _resolveReportReasons() {
    final List<SettingCommon> fromSettings = SessionManager.shared.getSettings()?.reportReasons ?? [];
    final List<SettingCommon> normalized = fromSettings.where((item) {
      final title = item.title?.trim() ?? '';
      return title.isNotEmpty;
    }).toList();

    if (normalized.isNotEmpty) {
      return normalized;
    }

    return [
      SettingCommon(id: -1, title: 'Contenu inapproprié'),
      SettingCommon(id: -2, title: 'Spam ou publicité'),
      SettingCommon(id: -3, title: 'Harcèlement ou intimidation'),
      SettingCommon(id: -4, title: 'Discours haineux'),
      SettingCommon(id: -5, title: 'Usurpation d\'identité'),
      SettingCommon(id: -6, title: 'Faux profil'),
      SettingCommon(id: -7, title: 'Autre'),
    ];
  }

  @override
  void onInit() {
    super.onInit();
    selectedReason = reasons.isNotEmpty ? reasons.first : null;
  }

  void onReasonChange(SettingCommon? reason) {
    selectedReason = reason;
    update();
  }

  void submitReport(Room? room, Post? post, User? user, Reel? reel) async {
    if (selectedReason == null) {
      showSnackBar("Please select a reason", type: SnackBarType.error);
      return;
    }
    if (reasonTextController.text.isEmpty) {
      showSnackBar(LKeys.pleaseEnterDescription, type: SnackBarType.error);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    startLoading();
    try {
      if (room != null) {
        await RoomService.shared.reportRoom(room.id ?? 0, selectedReason?.title ?? '', reasonTextController.text);
      } else if (post != null) {
        await PostService.shared.reportPost(post.id ?? 0, selectedReason?.title ?? '', reasonTextController.text);
      } else if (user != null) {
        await UserService.shared.reportUser(user.id ?? 0, selectedReason?.title ?? '', reasonTextController.text);
      } else if (reel != null) {
        await ReelService.shared.reportReel(reelId: reel.id ?? 0, reason: selectedReason?.title ?? '', desc: reasonTextController.text);
      }
    } catch (e) {
      showSnackBar("Something went wrong. Please try again.", type: SnackBarType.error);
    } finally {
      stopLoading();
    }
  }
}
