import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/date_time_extension.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/int_extension.dart';
import 'package:untitled/common/managers/context_menu_widget.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/chat.dart';
import 'package:untitled/screens/chats_screen/chats_screen_controller.dart';
import 'package:untitled/screens/chats_screen/chatting_screen/chatting_view.dart';
import 'package:untitled/screens/extra_views/back_button.dart';
import 'package:untitled/utilities/const.dart';

class ChatCard extends StatelessWidget {
  final ChatUserRoom chatUserRoom;
  final ChatsScreensController controller;

  const ChatCard(
      {Key? key, required this.chatUserRoom, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasUnread =
        chatUserRoom.newMsgCount != null && chatUserRoom.newMsgCount != 0;
    return ContextMenuWidget(
      child: GestureDetector(
        onTap: () {
          Get.to(() => ChattingView(chatUserRoom: chatUserRoom));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
                bottom: BorderSide(color: cLightText.withValues(alpha: 0.06))),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  MyCachedProfileImage(
                    imageUrl: chatUserRoom.profileImage,
                    fullName: chatUserRoom.title,
                    width: 56,
                    height: 56,
                    cornerRadius: 28,
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: cPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: cWhite, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  chatUserRoom.title ?? '',
                                  style: MyTextStyle.gilroyBold(
                                    size: 16,
                                    color: hasUnread ? cNavy : cDarkText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const VerifyIcon(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          chatUserRoom.time?.timeAgo() ?? '',
                          style: MyTextStyle.gilroyMedium(
                            size: 12,
                            color: hasUnread
                                ? cPrimary
                                : cLightText.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chatUserRoom.lastMsg ?? '',
                            style: MyTextStyle.gilroyRegular(
                              size: 14,
                              color: hasUnread
                                  ? cDarkText.withValues(alpha: 0.8)
                                  : cLightText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread && chatUserRoom.newMsgCount != -1)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: cPrimary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              chatUserRoom.newMsgCount?.makeToString() ?? '',
                              style: MyTextStyle.gilroyBold(
                                  size: 11, color: cWhite),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      menuProvider: (request) {
        return Menu(children: [
          MenuAction(
            title: chatUserRoom.newMsgCount == 0
                ? LKeys.markAsUnread.tr
                : LKeys.markAsRead.tr,
            callback: () => controller.markToggle(chatUserRoom),
          ),
          MenuAction(
            title: LKeys.clearChat.tr,
            callback: () => controller.clearChat(chatUserRoom),
          ),
          MenuAction(
            title: LKeys.deleteChat.tr,
            callback: () => controller.deleteChat(chatUserRoom),
          ),
        ]);
      },
    );
  }
}
