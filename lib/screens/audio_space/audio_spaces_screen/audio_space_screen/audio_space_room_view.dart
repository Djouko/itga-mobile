import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/audio_space/models/audio_space_user.dart';
import 'package:untitled/screens/rooms_you_own/create_room_screen/create_room_screen.dart';
import 'package:untitled/utilities/const.dart';

import 'audio_space_controller.dart';

class AudioSpaceRoomView extends StatelessWidget {
  final AudioSpaceController controller;

  AudioSpaceRoomView(this.controller);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Obx(() {
          final isVideo = controller.isVideoMode.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isVideo ? _videoHostsGrid() : _audioHostsGrid(),
              // Listeners section header — Clubhouse style
              Padding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 12, bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.headphones_rounded,
                        size: 14, color: cWhite.withValues(alpha: 0.4)),
                    const SizedBox(width: 6),
                    Text(
                      LKeys.otherListeners.tr,
                      style: MyTextStyle.gilroySemiBold(
                          size: 13, color: cWhite.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cWhite.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${controller.allListener.length}',
                        style: MyTextStyle.gilroySemiBold(
                            size: 11, color: cWhite.withValues(alpha: 0.4)),
                      ),
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: cAudioSpaceLightBG,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  padding: const EdgeInsets.only(right: 15, left: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: MyTextField(
                          color: cAudioSpaceLightBG,
                          controller: controller.searchController,
                          placeHolder: LKeys.searchHere,
                          onChange: (text) {
                            controller.filterListeners();
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
              // Listeners grid — compact circular avatars
              GridView.builder(
                  shrinkWrap: true,
                  primary: false,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: Get.width < 340 ? 4 : 5,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: controller.allListener.length,
                  padding: const EdgeInsets.only(top: 8, right: 10, left: 10),
                  itemBuilder: (BuildContext context, int index) {
                    var user = controller.allListener[index];
                    final listenerSize =
                        (Get.width / (Get.width < 340 ? 4 : 5)) - 18;
                    return GestureDetector(
                      onTap: () {
                        controller.showUserDetails(user);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MyCachedProfileImage(
                            imageUrl: user.image,
                            fullName: user.fullName,
                            height: listenerSize,
                            width: listenerSize,
                            cornerRadius: listenerSize / 2,
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              user.fullName ?? '',
                              style: MyTextStyle.gilroySemiBold(
                                  size: 11,
                                  color: cWhite.withValues(alpha: 0.4)),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    );
                  }),
            ],
          );
        }),
      ),
    );
  }

  Widget _audioHostsGrid() {
    final hosts = controller.audioSpace.hostsWithAdmin;
    // Responsive: 3 columns on normal phones, 2 on very small screens
    final crossAxisCount = Get.width < 340 ? 2 : 3;
    final tileSize = (Get.width - 40) / crossAxisCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header — Clubhouse/Twitter Spaces style
        Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.record_voice_over_rounded, size: 16, color: cPrimary),
              const SizedBox(width: 6),
              Text(
                'On Stage',
                style: MyTextStyle.gilroySemiBold(
                    size: 13, color: cWhite.withValues(alpha: 0.6)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${hosts.length}',
                  style: MyTextStyle.gilroySemiBold(size: 11, color: cPrimary),
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          primary: false,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.78,
            mainAxisSpacing: 4,
          ),
          itemCount: hosts.length,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemBuilder: (context, index) {
            var user = hosts[index];
            return _audioSpeakerTile(user, tileSize);
          },
        ),
      ],
    );
  }

  Widget _audioSpeakerTile(AudioSpaceUser user, double tileSize) {
    final isSpeaking = user.micStatus == AudioSpaceMicStatus.on;
    final isAdmin = user.type == AudioSpaceUserType.admin;
    final avatarSize = tileSize * 0.65;

    return GestureDetector(
      onTap: () => controller.showUserDetails(user),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar with speaking glow
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: avatarSize + 6,
                height: avatarSize + 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSpeaking ? cPrimary : Colors.white12,
                    width: isSpeaking ? 2.5 : 1,
                  ),
                  boxShadow: isSpeaking
                      ? [
                          BoxShadow(
                              color: cPrimary.withValues(alpha: 0.35),
                              blurRadius: 16,
                              spreadRadius: 2),
                          BoxShadow(
                              color: cPrimary.withValues(alpha: 0.15),
                              blurRadius: 30,
                              spreadRadius: 6),
                        ]
                      : [],
                ),
              ),
              MyCachedProfileImage(
                width: avatarSize,
                height: avatarSize,
                imageUrl: user.image,
                fullName: user.fullName,
                cornerRadius: avatarSize / 2,
              ),
              // Mic badge (bottom-right)
              Positioned(
                bottom: 0,
                right: (tileSize - avatarSize) / 2 - 2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSpeaking ? cGreen : const Color(0xFF3A3A3C),
                    shape: BoxShape.circle,
                    border: Border.all(color: cAudioSpaceBG, width: 2),
                  ),
                  child: Image.asset(
                    isSpeaking ? MyImages.audioMic : MyImages.micSlash,
                    height: 10,
                    width: 10,
                    color: cWhite,
                  ),
                ),
              ),
              // Admin star badge (top-right)
              if (isAdmin)
                Positioned(
                  top: 0,
                  right: (tileSize - avatarSize) / 2 - 2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: cPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(color: cAudioSpaceBG, width: 2),
                    ),
                    child: const Icon(Icons.star_rounded,
                        size: 10, color: Colors.black),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: tileSize - 10,
            child: Text(
              user.fullName ?? '',
              style: MyTextStyle.gilroySemiBold(
                size: 12,
                color: isSpeaking
                    ? cWhite.withValues(alpha: 0.95)
                    : cWhite.withValues(alpha: 0.55),
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoHostsGrid() {
    final hosts = controller.audioSpace.hostsWithAdmin;
    final myID = SessionManager.shared.getUserID();
    final sharingUid = controller.screenSharingUid.value;
    final isAnybodySharing = sharingUid > 0;

    // Google Meet style: if someone is sharing screen, show large screen share + small participant strip
    if (isAnybodySharing) {
      return Column(
        children: [
          // Large screen share frame (dominant, like Google Meet/Teams)
          Container(
            height: Get.height * 0.55,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cAudioSpaceLightBG,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: cPrimary.withValues(alpha: 0.4), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (controller.engine != null &&
                      controller.isEngineInitialized.value)
                    sharingUid == myID
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.screen_share_rounded,
                                    color: cGreen, size: 48),
                                const SizedBox(height: 8),
                                Text(
                                  LKeys.screenSharing.tr,
                                  style: MyTextStyle.gilroySemiBold(
                                      size: 16, color: cGreen),
                                ),
                              ],
                            ),
                          )
                        : AgoraVideoView(
                            controller: VideoViewController.remote(
                              rtcEngine: controller.engine!,
                              canvas: VideoCanvas(
                                uid: sharingUid,
                                renderMode: RenderModeType.renderModeFit,
                              ),
                              connection: RtcConnection(
                                  channelId: controller.audioSpace.id),
                            ),
                          )
                  else
                    const Center(
                        child: CircularProgressIndicator(color: cPrimary)),
                  // Label overlay
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.screen_share_rounded,
                              size: 14, color: cGreen),
                          const SizedBox(width: 4),
                          Text(
                            _getSharerName(hosts, sharingUid, myID),
                            style: MyTextStyle.gilroySemiBold(
                                size: 11, color: cWhite),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Small participant strip (horizontal scroll)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: hosts.length,
              itemBuilder: (context, index) {
                var user = hosts[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child:
                      _videoParticipantTile(user, myID, width: 80, height: 100),
                );
              },
            ),
          ),
        ],
      );
    }

    // Normal grid view (no screen sharing)
    return GridView.builder(
      shrinkWrap: true,
      primary: false,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: hosts.length <= 2 ? 1 : 2,
        childAspectRatio: hosts.length <= 2 ? 1.4 : 0.75,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: hosts.length,
      padding: const EdgeInsets.all(10),
      itemBuilder: (context, index) {
        var user = hosts[index];
        return _videoParticipantTile(user, myID);
      },
    );
  }

  String _getSharerName(List<AudioSpaceUser> hosts, int sharingUid, int myID) {
    if (sharingUid == myID) return 'You';
    final sharer = hosts.firstWhereOrNull((u) => u.id?.toInt() == sharingUid);
    return sharer?.fullName ?? 'Participant';
  }

  Widget _videoParticipantTile(AudioSpaceUser user, int myID,
      {double? width, double? height}) {
    final isSpeaking = user.micStatus == AudioSpaceMicStatus.on;
    final isMe = user.id?.toInt() == myID;
    final hasVideo = user.isCameraOn &&
        controller.engine != null &&
        controller.isEngineInitialized.value;

    return GestureDetector(
      onTap: () => controller.showUserDetails(user),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: cAudioSpaceLightBG,
          borderRadius: BorderRadius.circular(16),
          border: isSpeaking
              ? Border.all(color: cPrimary.withValues(alpha: 0.6), width: 2)
              : Border.all(color: Colors.white12, width: 1),
          boxShadow: isSpeaking
              ? [
                  BoxShadow(
                      color: cPrimary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 1)
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasVideo && isMe)
                AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: controller.engine!,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                )
              else if (hasVideo &&
                  !isMe &&
                  controller.remoteVideoUsers.contains(user.id?.toInt()))
                AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: controller.engine!,
                    canvas: VideoCanvas(uid: user.id?.toInt() ?? 0),
                    connection:
                        RtcConnection(channelId: controller.audioSpace.id),
                  ),
                )
              else
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MyCachedProfileImage(
                        width: width != null ? 40 : 64,
                        height: width != null ? 40 : 64,
                        imageUrl: user.image,
                        fullName: user.fullName,
                        cornerRadius: width != null ? 20 : 32,
                      ),
                      if (width == null) ...[
                        const SizedBox(height: 6),
                        if (!user.isCameraOn)
                          Icon(Icons.videocam_off_rounded,
                              color: Colors.white38, size: 18),
                      ],
                    ],
                  ),
                ),
              // Name + mic overlay at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: width != null ? 4 : 8,
                      vertical: width != null ? 3 : 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      if (user.type == AudioSpaceUserType.admin &&
                          width == null)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.star_rounded,
                              size: 14, color: cPrimary),
                        ),
                      Expanded(
                        child: Text(
                          user.fullName ?? '',
                          style: MyTextStyle.gilroySemiBold(
                              size: width != null ? 9 : 12, color: cWhite),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Image.asset(
                        isSpeaking ? MyImages.audioMic : MyImages.micSlash,
                        height: width != null ? 10 : 14,
                        width: width != null ? 10 : 14,
                        color: isSpeaking ? cGreen : Colors.white38,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
