import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/extensions/int_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/audio_space/create_audio_space_screen/create_audio_space_controller.dart';
import 'package:untitled/screens/audio_space/models/audio_space.dart';
import 'package:untitled/screens/audio_space/models/audio_space_user.dart';
import 'package:untitled/screens/post/comment/comment_screen.dart'; // Import pour SendBtn
import 'package:untitled/utilities/const.dart';

import 'audio_space_controller.dart';
import 'audio_space_members_view.dart';
import 'audio_space_messages_view.dart';
import 'audio_space_requests_view.dart';
import 'audio_space_room_view.dart';

class AudioSpaceScreen extends StatelessWidget {
  final AudioSpace audioSpace;

  const AudioSpaceScreen({super.key, required this.audioSpace});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AudioSpaceController(audioSpace));

    return Obx(() => PopScope(
          canPop: !controller.isMySpace.value,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              controller.dragAndBack();
            } else if (controller.isMySpace.value) {
              controller.endRoom();
            }
          },
          child: Scaffold(
            backgroundColor: cMainText,
            body: Stack(
              children: [
                Obx(() {
              var space = controller.audioSpace;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: cAudioSpaceBG,
                    padding: const EdgeInsets.all(15),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (controller.isMySpace.value) {
                                controller.endRoom();
                              } else {
                                controller.leaveSpace();
                              }
                            },
                            child: const Icon(
                              CupertinoIcons.chevron_back,
                              size: 24,
                              color: cPrimary,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(MyImages.audioMic, width: 18, height: 18),
                              const SizedBox(width: 2),
                              Text(
                                '${space.hostsWithAdmin.length}',
                                style: MyTextStyle.gilroySemiBold(size: 14, color: cWhite.withValues(alpha: 0.4)),
                              ),
                            ],
                          ),
                          const SizedBox(width: 15),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(MyImages.headphone, width: 14, height: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${space.requestsAndListener.length}',
                                style: MyTextStyle.gilroySemiBold(size: 14, color: cWhite.withValues(alpha: 0.4)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          color: cAudioSpaceBG,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      space.title ?? '',
                                      style: MyTextStyle.gilroyBold(size: 20, color: cWhite.withValues(alpha: 0.9)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: cGreen.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: cGreen.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (controller.isVideoMode.value)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 4),
                                            child: Icon(Icons.videocam_rounded, size: 12, color: cGreen),
                                          ),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: cGreen,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'LIVE',
                                          style: MyTextStyle.gilroyBold(size: 10, color: cGreen),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if ((space.description ?? '').isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  space.description!,
                                  style: MyTextStyle.gilroyRegular(size: 14, color: cWhite.withValues(alpha: 0.6)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            AudioSpaceTabButton(controller: controller, type: AudioSpacePageType.room),
                            AudioSpaceTabButton(
                              controller: controller,
                              type: AudioSpacePageType.messages,
                              count: controller.countOfUnreadMessages(),
                            ),
                            AudioSpaceTabButton(controller: controller, type: AudioSpacePageType.members),
                            if (controller.showOptionsShow)
                              AudioSpaceTabButton(
                                controller: controller,
                                type: AudioSpacePageType.requests,
                                count: space.requests.length,
                              ),
                          ],
                        ),
                        selectedScreen(controller)
                      ],
                    ),
                  ),
                  bottomBar(controller)
                ],
              );
            }),
                // Network quality banner (WhatsApp "poor connection" style)
                Obx(() {
                  final nq = controller.localNetworkQuality.value;
                  if (nq < 3) return const SizedBox.shrink();
                  return Positioned(
                    top: MediaQuery.of(context).padding.top + 56,
                    left: 40,
                    right: 40,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: (nq <= 3 ? cOrange : cRed).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.signal_cellular_connected_no_internet_0_bar_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              nq <= 3 ? 'Poor connection' : 'Very poor connection',
                              style: MyTextStyle.gilroySemiBold(color: Colors.white, size: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                // Floating emoji reactions overlay — covers most of the screen
                Obx(() {
                  // CRITICAL: snapshot the list to avoid ConcurrentModificationError
                  // when Future.delayed removes entries during Obx rebuild
                  final snapshot = List<MapEntry<String, DateTime>>.from(controller.floatingReactions);
                  if (snapshot.isEmpty) return const SizedBox.shrink();
                  // Limit to last 5 to prevent vertical overflow
                  final visible = snapshot.length > 5 ? snapshot.sublist(snapshot.length - 5) : snapshot;
                  return Positioned.fill(
                    child: IgnorePointer(
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 24, bottom: 120),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: visible.map((entry) {
                              return TweenAnimationBuilder<double>(
                                key: ValueKey(entry.value.microsecondsSinceEpoch),
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 2000),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: (value < 0.7 ? 1.0 : 1.0 - ((value - 0.7) / 0.3)).clamp(0.0, 1.0),
                                    child: Transform.translate(
                                      offset: Offset(0, -200 * value),
                                      child: Transform.scale(
                                        scale: 1.0 + (0.3 * value),
                                        child: child,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(entry.key, style: const TextStyle(fontSize: 48)),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ));
  }

  Widget bottomBar(AudioSpaceController controller) {
    return Obx(() {
      switch (controller.selectedType.value) {
        case AudioSpacePageType.room:
          return Container(
            color: cAudioSpaceDarkBG,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Left: Leave / End button (compact)
                  GestureDetector(
                    onTap: () => controller.isMySpace.value ? controller.endRoom() : controller.leaveSpace(),
                    child: Container(
                      decoration: ShapeDecoration(
                        shape: const StadiumBorder(side: BorderSide(color: cRed)),
                        color: cRed.withValues(alpha: 0.15),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Icon(Icons.call_end_rounded, color: cRed, size: 20),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Center: controls evenly spaced (adapts to audio/video mode)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Audio output toggle
                        _bottomBarIcon(
                          onTap: controller.toggleAudioOutput,
                          icon: controller.audioOutputMode.value == AudioOutputMode.speakerphone
                              ? Icons.volume_up_rounded
                              : controller.audioOutputMode.value == AudioOutputMode.earpiece
                                  ? Icons.phone_in_talk_rounded
                                  : Icons.volume_off_rounded,
                          color: controller.audioOutputMode.value == AudioOutputMode.muted ? cRed : cPrimary,
                          bgColor: cAudioSpaceLightBG,
                        ),
                        // Emoji reaction (Google Meet style) — for ALL users
                        _bottomBarIcon(
                          onTap: () => _showReactionPicker(controller),
                          icon: Icons.emoji_emotions_outlined,
                          color: cWhite,
                          bgColor: cAudioSpaceLightBG,
                        ),
                        // Video mode controls (camera, flip, screen share)
                        if (controller.isVideoMode.value && controller.amIHost.value) ...[
                          _bottomBarIcon(
                            onTap: controller.toggleCamera,
                            icon: controller.isCameraOn.value ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                            color: controller.isCameraOn.value ? cPrimary : cLightText,
                            bgColor: controller.isCameraOn.value ? cPrimary.withValues(alpha: 0.2) : cAudioSpaceLightBG,
                          ),
                          _bottomBarIcon(
                            onTap: controller.switchCamera,
                            icon: Icons.flip_camera_ios_rounded,
                            color: cWhite,
                            bgColor: cAudioSpaceLightBG,
                          ),
                          _bottomBarIcon(
                            onTap: controller.toggleScreenSharing,
                            icon: controller.isScreenSharing.value ? Icons.stop_screen_share_rounded : Icons.screen_share_rounded,
                            color: controller.isScreenSharing.value ? cGreen : cLightText,
                            bgColor: controller.isScreenSharing.value ? cGreen.withValues(alpha: 0.2) : cAudioSpaceLightBG,
                          ),
                        ],
                        // Audio↔Video mode toggle (ADMIN ONLY)
                        // Distinct icon: switch_video (clearly shows mode swap, NOT confused with mic)
                        if (controller.isMySpace.value)
                          _bottomBarIcon(
                            onTap: controller.toggleVideoMode,
                            icon: controller.isVideoMode.value ? Icons.headset_rounded : Icons.switch_video_rounded,
                            color: controller.isVideoMode.value ? cPrimary : cLightText,
                            bgColor: controller.isVideoMode.value ? cPrimary.withValues(alpha: 0.2) : cAudioSpaceLightBG,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Right: Mic toggle (host) OR Hand raise (listener)
                  controller.amIHost.value
                      ? _bottomBarIcon(
                          onTap: controller.toggleMic,
                          iconWidget: Image.asset(
                            controller.myUser.micStatus == AudioSpaceMicStatus.muted ? MyImages.micSlash : MyImages.audioMic,
                            color: controller.myUser.micStatus == AudioSpaceMicStatus.muted ? cLightText : cGreen,
                            height: 20,
                            width: 20,
                          ),
                          bgColor: controller.myUser.micStatus == AudioSpaceMicStatus.muted ? cAudioSpaceLightBG : cGreen.withValues(alpha: 0.2),
                        )
                      : _bottomBarIcon(
                          onTap: () => controller.requestForHost(controller.myUser),
                          iconWidget: Image.asset(
                            MyImages.handRaised,
                            color: controller.myUser.type == AudioSpaceUserType.requested ? cLightText : cAudioSpaceBG,
                            height: 20,
                            width: 20,
                          ),
                          bgColor: controller.myUser.type == AudioSpaceUserType.requested ? cAudioSpaceLightBG : cWhite,
                        ),
                ],
              ),
            ),
          );
        case AudioSpacePageType.messages:
          return Container(
            color: cAudioSpaceDarkBG,
            padding: const EdgeInsets.all(15),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: ShapeDecoration(color: cLightText.withValues(alpha: 0.15), shape: SmoothRectangleBorder(borderRadius: SmoothBorderRadius(cornerRadius: 20, cornerSmoothing: cornerSmoothing))),
                      padding: const EdgeInsets.only(left: 15, top: 2, right: 2, bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                child: TextField(
                                  controller: controller.messageTextController,
                                  maxLines: 5,
                                  minLines: 1,
                                  textCapitalization: TextCapitalization.sentences,
                                  decoration: InputDecoration(hintText: LKeys.writeHere.tr, hintStyle: MyTextStyle.gilroyRegular(color: cLightText.withValues(alpha: 0.6)), border: InputBorder.none, counterText: '', isDense: true, contentPadding: const EdgeInsets.all(0)),
                                  cursorColor: cPrimary,
                                  style: MyTextStyle.gilroyRegular(color: cWhite),
                                  textInputAction: TextInputAction.newline,
                                )),
                          ),
                          GestureDetector(onTap: controller.sendMessage, child: SendBtn())
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        case AudioSpacePageType.members:
          return controller.audioSpace.type == AudioSpaceType.private && controller.isMySpace.value
              ? Container(
                  color: cAudioSpaceDarkBG,
                  padding: const EdgeInsets.all(15),
                  child: SafeArea(
                    top: false,
                    child: GestureDetector(
                      onTap: controller.showAddUsersSheet,
                      child: Container(
                        decoration: BoxDecoration(color: cPrimary, borderRadius: SmoothBorderRadius(cornerRadius: 100, cornerSmoothing: cornerSmoothing)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Text(LKeys.addUsers.tr, style: MyTextStyle.gilroySemiBold(color: cBlack)),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink();
        default:
          return const SizedBox.shrink();
      }
    });
  }

  void _showReactionPicker(AudioSpaceController controller) {
    const emojis = ['👍', '❤️', '😂', '👏', '🔥', '🎉', '😮', '💯'];
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: const BoxDecoration(
          color: cAudioSpaceDarkBG,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: emojis.map((emoji) {
              return GestureDetector(
                onTap: () {
                  controller.sendReaction(emoji);
                },
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _bottomBarIcon({
    VoidCallback? onTap,
    IconData? icon,
    Widget? iconWidget,
    Color color = cLightText,
    Color bgColor = cAudioSpaceLightBG,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: ShapeDecoration(shape: const CircleBorder(), color: bgColor),
          padding: const EdgeInsets.all(7),
          child: iconWidget ?? Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget selectedScreen(AudioSpaceController controller) {
    switch (controller.selectedType.value) {
      case AudioSpacePageType.room:
        return AudioSpaceRoomView(controller);
      case AudioSpacePageType.messages:
        return AudioSpaceMessagesView(controller);
      case AudioSpacePageType.members:
        return AudioSpaceMembersView(controller);
      case AudioSpacePageType.requests:
        return AudioSpaceRequestsView(controller);
    }
  }
}

class AudioSpaceTabButton extends StatelessWidget {
  final AudioSpaceController controller;
  final AudioSpacePageType type;
  final int count;

  const AudioSpaceTabButton({super.key, required this.controller, required this.type, this.count = 0});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      var isSelected = type == controller.selectedType.value;
      final tabCount = controller.showOptionsShow ? 4 : 3;
      return GestureDetector(
        onTap: () => controller.selectType(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          height: 40,
          width: Get.width / tabCount,
          decoration: BoxDecoration(
            color: isSelected ? cPrimary : cAudioSpaceLightBG,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? cPrimary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type.icon,
                size: 14,
                color: isSelected ? cBlack : cLightText.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  type.title,
                  style: MyTextStyle.gilroySemiBold(color: isSelected ? cBlack : cLightText, size: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (count != 0) ...[
                const SizedBox(width: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? cBlack : cPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.makeToString(),
                    style: MyTextStyle.gilroySemiBold(color: isSelected ? cPrimary : cBlack, size: 9),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

enum AudioSpacePageType {
  room,
  messages,
  members,
  requests;

  String get title {
    switch (this) {
      case AudioSpacePageType.room:
        return LKeys.room.tr;
      case AudioSpacePageType.messages:
        return LKeys.messages.tr;
      case AudioSpacePageType.members:
        return LKeys.members.tr;
      case AudioSpacePageType.requests:
        return LKeys.requests.tr;
    }
  }

  IconData get icon {
    switch (this) {
      case AudioSpacePageType.room:
        return Icons.mic_rounded;
      case AudioSpacePageType.messages:
        return Icons.chat_bubble_outline_rounded;
      case AudioSpacePageType.members:
        return Icons.people_outline_rounded;
      case AudioSpacePageType.requests:
        return Icons.front_hand_outlined;
    }
  }
}

class AudioSpaceIconButton extends StatelessWidget {
  final bool isFromSheet;
  final String title;
  final String image;
  final Color? bgColor;
  final Color? borderColor;
  final double size;
  final Color? color;
  final Function() onTap;

  const AudioSpaceIconButton({super.key, required this.image, this.color, required this.onTap, this.size = 20, required this.title, this.bgColor, required this.isFromSheet, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: isFromSheet
          ? Container(
              decoration: ShapeDecoration(
                shape: StadiumBorder(side: BorderSide(color: borderColor ?? cWhite.withValues(alpha: 0.1))),
                color: bgColor ?? cBlack,
              ),
              padding: EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Image.asset(image, color: color ?? cLightText, width: size, height: size), const SizedBox(width: 10), Text(title.tr, style: MyTextStyle.gilroySemiBold(color: color))],
              ),
            )
          : CircleAvatar(
              backgroundColor: bgColor ?? const Color(0xFF474747),
              radius: 20,
              child: Image.asset(image, color: color ?? cLightText, width: size, height: size),
            ),
    );
  }
}
