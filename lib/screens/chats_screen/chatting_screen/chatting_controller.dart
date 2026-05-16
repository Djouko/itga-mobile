import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/api_service/post_service.dart';
import 'package:untitled/common/utils/input_sanitizer.dart';
import 'package:detectable_text_field/detectable_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/moderator_service.dart';
import 'package:untitled/common/api_service/notification_service.dart';
import 'package:untitled/common/api_service/room_service.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/int_extension.dart';
import 'package:untitled/common/managers/firebase_notification_manager.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/chat.dart';
import 'package:untitled/models/invitations_model.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/room_model.dart';
import 'package:untitled/models/story.dart';
import 'package:untitled/screens/chats_screen/chatting_screen/block_user_controller.dart';
import 'package:untitled/screens/rooms_screen/room_controller.dart';
import 'package:untitled/screens/sheets/confirmation_sheet.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/utilities/firebase_const.dart';

class ChattingController extends BlockUserController {
  ScrollController scrollController = ScrollController();
  DocumentReference? documentSender;
  DocumentReference? documentReceiver;
  CollectionReference? drChatMessages;
  StreamSubscription? messagesListener;
  StreamSubscription? userListener;
  StreamSubscription? myUserListener;
  List<ChatMessage> messages = [];
  ChatUserRoom? chatUserRoom;
  ChatUserRoom? myChatRoom;
  QueryDocumentSnapshot<ChatMessage>? lastMsgQuery;
  String deleteId = "";
  bool isFirstTime = true;
  Room? room;
  User? user;
  FirebaseFirestore db = FirebaseFirestore.instance;
  DetectableTextEditingController messageTextController =
      DetectableTextEditingController(
    detectedStyle: MyTextStyle.gilroySemiBold(size: 16, color: cPrimary)
        .copyWith(height: 1.2),
    regExp: detectionRegExp(atSign: false, url: true, hashtag: false)!,
  );
  User? myUser = SessionManager.shared.getUser();
  bool shouldCallAPI = true;

  ChattingController(
      {this.room, this.user, ChatUserRoom? chatUserRoom, bool? shouldCallAPI}) {
    if (chatUserRoom != null) {
      this.chatUserRoom = chatUserRoom;
    } else if (room != null) {
      this.chatUserRoom = ChatUserRoom(
          conversationId: room?.firebaseId(),
          title: room?.title ?? '',
          profileImage: room?.photo ?? '',
          userIdOrRoomId: room?.id,
          type: 2);
    } else if (user != null) {
      this.chatUserRoom = ChatUserRoom(
          conversationId: user?.id?.toConversationId(),
          title: user?.fullName ?? '',
          profileImage: user?.profile ?? '',
          userIdOrRoomId: user?.id,
          type: 1);
    }
    var firebaseUserIdentity =
        this.chatUserRoom?.userIdOrRoomId?.toString() ?? '';

    documentSender = db
        .collection(FirebaseConst.users)
        .doc(myUser?.firebaseId())
        .collection(FirebaseConst.userList)
        .doc(firebaseUserIdentity);

    documentReceiver = db
        .collection(FirebaseConst.users)
        .doc(firebaseUserIdentity)
        .collection(FirebaseConst.userList)
        .doc(myUser?.firebaseId());
    //
    drChatMessages = db
        .collection(FirebaseConst.chats)
        .doc(this.chatUserRoom?.conversationId ?? '')
        .collection(FirebaseConst.messages);
    stopNotification();
    this.shouldCallAPI = shouldCallAPI ?? true;
  }

  @override
  void onReady() {
    if (shouldCallAPI) {
      fetchDetailWithAPI();
    }
    super.onReady();
  }

  @override
  void onInit() {
    scrollController.addListener(
      () {
        if (scrollController.offset ==
            scrollController.position.maxScrollExtent) {
          if (!isLoading.value) {
            loadOldData();
          }
        }
      },
    );
    super.onInit();
  }

  void sendStoryReply({required Story story, required String reply}) {
    messageTextController.text = reply;
    commonSend(
        type: MessageType.storyReply,
        content: '',
        thumbnail: story.thumbnailForReply ?? '',
        storyId: story.id);
  }

  void sendMsg({MessageType type = MessageType.text}) {
    final sanitized = InputSanitizer.sanitizeText(messageTextController.text);
    if (sanitized.isEmpty) {
      return;
    }
    messageTextController.text = sanitized;
    commonSend(type: MessageType.text);
  }

  void commonSend(
      {required MessageType type,
      String content = '',
      String thumbnail = '',
      num? storyId}) {
    if (chatUserRoom?.iAmBlocked == true) {
      return;
    }
    if (chatUserRoom?.iBlocked == true) {
      unblockUser(user, () {});
      return;
    }
    var date = DateTime.now();
    String lastMsg;
    if (messageTextController.text.isNotEmpty) {
      lastMsg = messageTextController.text;
    } else if (type == MessageType.document) {
      lastMsg = '\u{1F4CE} Document';
    } else if (type == MessageType.image) {
      lastMsg = 'Image';
    } else {
      lastMsg = 'Video';
    }
    final actingCompanyId = SessionManager.shared.getActingCompanyId();
    final actingCompanyName = SessionManager.shared.getActingCompanyName();
    final isCompanyActor = actingCompanyId != null;
    final actorName = isCompanyActor
        ? (actingCompanyName?.trim().isNotEmpty == true
            ? actingCompanyName!.trim()
            : myUser?.fullName)
        : myUser?.fullName;
    final actorUsername =
        isCompanyActor ? 'company-$actingCompanyId' : myUser?.username;
    final actorAvatar = isCompanyActor ? null : myUser?.profile;
    final actorProfileType = isCompanyActor ? 'company' : 'user';
    if (room != null) {
      var roomData = ChatUserRoom(
          conversationId: room?.firebaseId(),
          lastMsg: lastMsg,
          profileImage: room?.photo,
          title: room?.title,
          time: date,
          type: 2,
          usersIds: room?.roomUsers?.map((e) => e.id ?? 0).toList(),
          userIdOrRoomId: room?.id,
          unreadCounts: {},
          deleteChatIds: {});
      chatUserRoom?.usersIds?.forEach((element) {
        roomData.unreadCounts?['${element.toInt()}'] =
            (chatUserRoom?.unreadCounts?['${element.toInt()}'] ?? 0) + 1;
        roomData.deleteChatIds?['${element.toInt()}'] =
            ((chatUserRoom?.deleteChatIds?['${element.toInt()}']) ?? '')
                .replaceFirst(RegExp('d'), '');
      });
      if (deleteId == "" && messages.isEmpty) {
        db
            .collection(FirebaseConst.chats)
            .doc(roomData.conversationId ?? '')
            .set(roomData.toFireStore());
      } else {
        db
            .collection(FirebaseConst.chats)
            .doc(roomData.conversationId ?? '')
            .update(roomData.toFireStore());
      }
      var totalUserForNotifications = room?.roomUsers
          ?.where((element) => element.isPushNotifications == 1)
          .map((e) => e.deviceToken ?? '')
          .toList();
      totalUserForNotifications?.removeWhere((element) => element == '');
      NotificationService.shared.sendToTopic(
          topic: 'room_${room?.id ?? 0}',
          title: room?.title ?? '',
          body: '${actorName ?? ''} : $lastMsg',
          conversationId: chatUserRoom?.conversationId ?? '');
    } else {
      chatUserRoom?.lastMsg = lastMsg;
      chatUserRoom?.time = date;
      chatUserRoom?.newMsgCount = 0;
      chatUserRoom?.isDeleted = false;
      if (deleteId == "" && messages.isEmpty) {
        documentSender?.set(chatUserRoom?.toFireStore());
      } else {
        documentSender?.update(chatUserRoom?.toFireStore() ?? {});
      }
    }

    if (user != null) {
      var status = (user?.followingStatus ?? 0);
      var myChatRoom = ChatUserRoom(
        isMute: false,
        profileImage: actorAvatar,
        profileType: actorProfileType,
        companyId: actingCompanyId,
        conversationId: chatUserRoom?.conversationId,
        lastMsg: lastMsg,
        title: actorName,
        time: date,
        type: (status == 1) || (status == 3) ? 1 : 0,
        userIdOrRoomId: myUser?.id,
        newMsgCount: 1,
        isDeleted: false,
      );
      if ((deleteId == "" && messages.isEmpty) ||
          this.myChatRoom?.type == null) {
        documentReceiver?.set(myChatRoom.toFireStore());
      } else {
        myChatRoom.type = this.myChatRoom?.type;
        var map = myChatRoom.toFireStore();
        map[FirebaseConst.newMsgCount] = FieldValue.increment(1);
        documentReceiver?.update(map);
      }
      if (user?.isPushNotifications == 1) {
        NotificationService.shared.sendToSingleUser(
            token: user?.deviceToken ?? '',
            deviceType: user?.deviceType,
            title: actorName ?? '',
            body: lastMsg,
            conversationId: chatUserRoom?.conversationId ?? '');
      }
    }
    var map = ChatMessage(
            id: date.microsecondsSinceEpoch.toString(),
            msg: messageTextController.text,
            msgType: type.value,
            content: content,
            thumbnail: thumbnail,
            senderId: myUser?.id,
            senderCompanyId: actingCompanyId,
            senderProfileType: actorProfileType,
            senderName: actorName,
            senderUsername: actorUsername,
            senderAvatar: actorAvatar,
            storyId: storyId?.toInt())
        .toJson();

    drChatMessages?.doc(date.microsecondsSinceEpoch.toString()).set(map);
    messageTextController.text = "";
  }

  void pickAndSendDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt',
          'csv',
          'zip'
        ],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null) return;

      final maxSize = 25 * 1024 * 1024; // 25 MB limit
      if (file.size > maxSize) {
        showSnackBar('File too large. Maximum size is 25 MB.');
        return;
      }

      startLoading();
      final xFile = XFile(file.path!);
      PostService.shared.uploadFile(xFile, (url) {
        stopLoading();
        if (url.isNotEmpty) {
          messageTextController.text = file.name;
          commonSend(type: MessageType.document, content: url);
        }
      });
    } catch (e) {
      stopLoading();
      showSnackBar('Failed to pick document');
    }
  }

  void removeStoryFromMessage({required ChatMessage message}) {
    message.thumbnail = '';
    // drChatMessages?.doc(message.id ?? '').update(message.toJson());
    drChatMessages?.doc(message.id ?? '').set(message.toJson());
  }

  void fetchDetailWithAPI() {
    if (chatUserRoom?.type != 2) {
      myUserListener = db
          .collection(FirebaseConst.users)
          .doc("${chatUserRoom?.userIdOrRoomId?.toInt() ?? 0}")
          .collection(FirebaseConst.userList)
          .doc(myUser?.firebaseId())
          .snapshots()
          .listen((event) {
        myChatRoom = ChatUserRoom.fromJson(event.data() ?? {});
        update();
      });
      userListener = db
          .collection(FirebaseConst.users)
          .doc(myUser?.firebaseId())
          .collection(FirebaseConst.userList)
          .doc("${chatUserRoom?.userIdOrRoomId?.toInt() ?? 0}")
          .snapshots()
          .listen((event) {
        if (event.data() != null) {
          chatUserRoom = ChatUserRoom.fromJson(event.data() ?? {});
          stopNotification();
        }
        deleteId = chatUserRoom?.deletedId ?? '';
        if (isFirstTime) {
          fetchMessages();
        }
        update();
      });

      startLoading();
      UserService.shared
          .fetchProfile(chatUserRoom?.userIdOrRoomId?.toInt() ?? 0, (user) {
        stopLoading();
        this.user = user;
        update();
      });
      UserService.shared.fetchMyProfile(
          userID: myUser?.id ?? 0,
          myUserId: chatUserRoom?.userIdOrRoomId?.toInt(),
          completion: (user) {
            myUser = user;
            update();
          });
    } else if (chatUserRoom?.type == 2) {
      this.room?.roomUsers = SessionManager.shared
          .getUsersForGroup(conversationId: chatUserRoom?.conversationId ?? '');
      userListener = db
          .collection(FirebaseConst.chats)
          .doc(chatUserRoom?.conversationId)
          .snapshots()
          .listen((event) {
        if (event.data() != null) {
          chatUserRoom = ChatUserRoom.fromJson(event.data() ?? {});
          stopNotification();
        }

        deleteId = (chatUserRoom?.deleteChatIds?['${myUser?.id}'] ?? '')
            .replaceFirst(RegExp('d'), '');
        if (isFirstTime) {
          fetchMessages();
        }
        update();
      });
      this.room = Room(id: chatUserRoom?.userIdOrRoomId?.toInt() ?? 0);
      this.room?.roomUsers = SessionManager.shared
          .getUsersForGroup(conversationId: chatUserRoom?.conversationId ?? '');
      update();
      RoomService.shared.fetchRoom(chatUserRoom?.userIdOrRoomId?.toInt() ?? 0,
          shouldShowMembers: true, (room) {
        this.room = room;
        SessionManager.shared.setUsersForGroup(
            conversationId: chatUserRoom?.conversationId ?? '',
            users: room.roomUsers ?? []);
        if (room.isMute == 0) {
          FirebaseNotificationManager.shared
              .subscribeToTopic('room_${room.id ?? 0}');
        }
        update();
      });
    }
  }

  void markAsRead() {
    if (chatUserRoom?.type == 2) {
      var map = chatUserRoom?.unreadCounts ?? {};
      map['${myUser?.id}'] = 0;
      db
          .collection(FirebaseConst.chats)
          .doc(chatUserRoom?.conversationId)
          .update({FirebaseConst.unreadCounts: map});
    } else {
      documentSender?.update({FirebaseConst.newMsgCount: 0});
    }
  }

  void fetchMessages() {
    if (messagesListener != null) return;
    messagesListener = drChatMessages
        ?.withConverter(
          fromFirestore: ChatMessage.fromFireStore,
          toFirestore: (value, options) => value.toFireStore(),
        )
        .where(FirebaseConst.id, isGreaterThan: deleteId)
        .orderBy(FirebaseConst.id, descending: true)
        .limit(FirebaseConst.pagination)
        .snapshots()
        .listen((event) {
      isFirstTime = false;
      for (var element in event.docChanges) {
        var data = element.doc.data();
        if (data != null) {
          switch (element.type) {
            case DocumentChangeType.added:
              // print("add");
              messages.add(data);
              messages.sort(
                (a, b) => (b.id ?? '').compareTo((a.id ?? '')),
              );
              update();
              break;
            case DocumentChangeType.modified:
              var index =
                  messages.indexWhere((element) => element.id == data.id);
              if (index >= 0) {
                messages[index] = data;
                update();
              }
              break;
            case DocumentChangeType.removed:
              messages.removeWhere((element) => element.id == data.id);
              update();
              break;
          }
        }
      }
      if (lastMsgQuery == null && event.docs.isNotEmpty) {
        lastMsgQuery = event.docs.last;
      }
    });
  }

  void loadOldData() {
    if (lastMsgQuery == null) {
      return;
    }
    isLoading.value = true;
    drChatMessages
        ?.withConverter(
          fromFirestore: ChatMessage.fromFireStore,
          toFirestore: (value, options) => value.toFireStore(),
        )
        .where(FirebaseConst.id, isGreaterThan: deleteId)
        .orderBy(FirebaseConst.id, descending: true)
        .startAfterDocument(lastMsgQuery!)
        .limit(FirebaseConst.pagination)
        .get()
        .then((value) {
      isLoading.value = false;
      for (var element in value.docs) {
        messages.add(element.data());
      }
      if (value.docs.isNotEmpty) {
        lastMsgQuery = value.docs.last;
      }
      update();
    });
  }

  void rejectMessageRequest() {
    Get.bottomSheet(ConfirmationSheet(
      desc: LKeys.rejectChatRequest,
      buttonTitle: LKeys.reject,
      onTap: () {
        var date = DateTime.now().microsecondsSinceEpoch.toString();
        documentSender?.update(
            {FirebaseConst.deletedId: date, FirebaseConst.isDeleted: true});
        Get.back();
      },
    ));
  }

  void acceptMessageRequest() {
    documentSender?.update({FirebaseConst.type: 1});
    chatUserRoom?.type = 1;
    update();
  }

  void leaveRoom() {
    startLoading();
    RoomService.shared.leaveThisRoom(room?.id ?? 0, () {
      stopLoading();
      room?.userRoomStatus = GroupUserAccessType.none.value;
      room?.totalMember = (room?.totalMember ?? 0) - 1;
      chatUserRoom?.usersIds?.removeWhere(
          (element) => element == SessionManager.shared.getUserID());
      db
          .collection(FirebaseConst.chats)
          .doc(chatUserRoom?.conversationId ?? '')
          .update(chatUserRoom?.toFireStore() ?? {});
      Get.back(result: room);

      update();
    });
  }

  List<Invitation> joinRequests = [];

  void fetchRequests() {
    startLoading();
    RoomService.shared.fetchRoomRequestList(room?.id ?? 0, (invitations) {
      stopLoading();
      joinRequests = invitations;
      update();
    });
  }

  void acceptRequest(Invitation invitation) {
    startLoading();
    RoomService.shared
        .acceptRoomRequest(invitation.userId ?? 0, invitation.roomId ?? 0, () {
      stopLoading();
      room?.totalMember = (room?.totalMember ?? 0) + 1;
      joinRequests.removeWhere((element) => element.id == invitation.id);
      RoomController.addRoomToUsersChatList(invitation.user, room ?? Room());
      update();
    });
  }

  void muteUnMuteNotification() {
    var type = (room?.isMute ?? 0) == 0 ? 1 : 0;
    RoomService.shared.muteUnmuteNotification(type, room?.id ?? 0, () {
      room?.isMute = type;
      if (type == 0) {
        FirebaseNotificationManager.shared
            .subscribeToTopic('room_${room?.id ?? 0}');
      } else {
        FirebaseNotificationManager.shared
            .unsubscribeToTopic('room_${room?.id ?? 0}');
      }
      update();
    });
  }

  void rejectRequest(Invitation invitation) {
    startLoading();
    RoomService.shared
        .rejectRoomRequest(invitation.userId ?? 0, invitation.roomId ?? 0, () {
      stopLoading();
      joinRequests.removeWhere((element) => element.id == invitation.id);
      update();
    });
  }

  void deleteRoom() async {
    startLoading();
    RoomService.shared.deleteRoom(room?.id ?? 0, () async {
      stopLoading();
      await db
          .collection(FirebaseConst.chats)
          .doc(chatUserRoom?.conversationId)
          .delete();
      Get.back();
    });
  }

  void deleteRoomByModerator() {
    Get.bottomSheet(
      ConfirmationSheet(
        desc: LKeys.deleteRoomByModeratorDesc,
        buttonTitle: LKeys.deleteThisRoom,
        onTap: () {
          startLoading();
          ModeratorService.shared.deleteRoom(
              roomId: room?.id?.toInt() ?? 0,
              completion: () async {
                stopLoading();
                await db
                    .collection(FirebaseConst.chats)
                    .doc(chatUserRoom?.conversationId)
                    .delete();
                Get.back();
              });
        },
      ),
    );
  }

  void stopNotification() {
    SessionManager.shared
        .setStoredConversation(chatUserRoom?.conversationId ?? '');
  }

  void startNotification() {
    SessionManager.shared.setStoredConversation('');
  }

  @override
  void onClose() {
    startNotification();
    messagesListener?.cancel();
    userListener?.cancel();
    myUserListener?.cancel();
    markAsRead();
    scrollController.dispose();
    messageTextController.dispose();
    super.onClose();
  }
}
