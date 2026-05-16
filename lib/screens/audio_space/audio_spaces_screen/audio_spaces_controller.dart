import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/logger.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/screens/audio_space/create_audio_space_screen/create_audio_space_controller.dart';
import 'package:untitled/screens/audio_space/models/audio_space.dart';
import 'package:untitled/utilities/firebase_const.dart';

enum SpaceFilter { all, audio, video }

class AudioSpacesController extends BaseController {
  List<AudioSpace> spaces = [];
  SpaceFilter currentFilter = SpaceFilter.all;
  StreamSubscription? spacesListener;

  List<AudioSpace> get filteredSpaces {
    switch (currentFilter) {
      case SpaceFilter.audio:
        return spaces.where((s) => !s.isVideoConference).toList();
      case SpaceFilter.video:
        return spaces.where((s) => s.isVideoConference).toList();
      case SpaceFilter.all:
        return spaces;
    }
  }

  void setFilter(SpaceFilter filter) {
    currentFilter = filter;
    update();
  }

  @override
  void onInit() {
    fetchSpaces();
    super.onInit();
  }

  bool _isUserInSpace(AudioSpace audioSpace) {
    final userId = SessionManager.shared.getUserID();
    final allUsers = (audioSpace.users ?? []) + (audioSpace.leavedUsers ?? []);
    return allUsers.any((user) => user.id?.toInt() == userId);
  }

  void fetchSpaces() {
    spacesListener = FirebaseFirestore.instance
        .collection(FirebaseAudioConst.audioSpaces)
        .snapshots()
        .listen((event) {
      spaces = [];
      for (var doc in event.docs) {
        try {
          AudioSpace audioSpace = AudioSpace.fromFireStore(
            doc as DocumentSnapshot<Map<String, dynamic>>, null);
          if (audioSpace.type == AudioSpaceType.public || _isUserInSpace(audioSpace)) {
            spaces.add(audioSpace);
          }
        } catch (e) {
          Loggers.error("Error parsing audio space ${doc.id}: $e");
        }
      }
      update();
    }, onError: (error) {
      Loggers.error("Firestore audio spaces listener error: $error");
    });
  }

  @override
  void onClose() {
    spacesListener?.cancel();
    super.onClose();
  }
}
