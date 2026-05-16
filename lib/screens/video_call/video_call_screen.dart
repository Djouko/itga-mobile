import 'dart:ui';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/models/chat.dart';
import 'package:untitled/common/extensions/int_extension.dart';
import 'package:untitled/screens/chats_screen/chatting_screen/chatting_view.dart';
import 'package:untitled/screens/video_call/add_participant_sheet.dart';
import 'package:untitled/screens/video_call/video_call_controller.dart';
import 'package:untitled/utilities/const.dart';

class VideoCallScreen extends StatefulWidget {
  final User? remoteUser;
  final String? channelId;
  final String? token;
  final bool isOutgoing;

  const VideoCallScreen({
    super.key,
    this.remoteUser,
    this.channelId,
    this.token,
    this.isOutgoing = true,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final VideoCallController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(VideoCallController(
      remoteUser: widget.remoteUser,
      channelId: widget.channelId,
      existingToken: widget.token,
      isOutgoing: widget.isOutgoing,
    ));
    // WhatsApp/FaceTime style pulsing animation for calling overlay
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _remoteIsCompany => widget.remoteUser?.profileType == 'company';

  Widget _companyProfilePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cPrimary.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.business_rounded, color: cPrimary, size: 14),
          const SizedBox(width: 5),
          Text(
            'Entreprise ITGA',
            style: MyTextStyle.gilroySemiBold(color: cPrimary, size: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDarkBG,
      body: Obx(() {
        return Stack(
          children: [
            _buildVideoViews(controller),
            _buildTopBar(controller),
            // Network quality banner (WhatsApp "poor connection" style)
            _buildNetworkQualityBanner(controller),
            // Floating emoji reactions (Google Meet style)
            _buildFloatingReactions(controller),
            _buildBottomControls(controller),
            if (controller.callStatus.value == 'connecting' ||
                controller.callStatus.value == 'waiting')
              Positioned.fill(
                child: _buildCallingOverlay(controller),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildVideoViews(VideoCallController controller) {
    if (!controller.isEngineReady.value || controller.engine == null) {
      return const SizedBox.expand(
        child: Center(
          child: CircularProgressIndicator(color: cPrimary),
        ),
      );
    }

    final hasRemote = controller.remoteUsers.isNotEmpty;

    return Stack(
      children: [
        // Remote video (full screen) — long-press for mute/message options
        GestureDetector(
          onLongPress: () => _showParticipantOptions(
              controller,
              controller.remoteUsers.isNotEmpty
                  ? controller.remoteUsers.first
                  : 0),
          child: hasRemote && controller.isRemoteVideoOn.value
              ? SizedBox.expand(
                  child: AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: controller.engine!,
                      canvas: VideoCanvas(uid: controller.remoteUsers.first),
                      connection:
                          RtcConnection(channelId: controller.activeChannelId),
                    ),
                  ),
                )
              : _buildRemotePlaceholder(controller),
        ),

        // Local video (small PiP in top-right) — FaceTime / WhatsApp style
        if (controller.isCameraOn.value)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 16,
            child: GestureDetector(
              onTap: controller.switchCamera,
              child: Container(
                width: 110,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: controller.engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 16,
            child: Container(
              width: 110,
              height: 150,
              decoration: BoxDecoration(
                color: cAudioSpaceLightBG,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08), width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.videocam_off_rounded,
                    color: Colors.white38, size: 32),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRemotePlaceholder(VideoCallController controller) {
    return SizedBox.expand(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cDarkBG, cAudioSpaceDarkBG],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1), width: 2),
                ),
                child: widget.remoteUser != null
                    ? MyCachedProfileImage(
                        imageUrl: widget.remoteUser?.profile,
                        fullName: widget.remoteUser?.fullName,
                        width: 100,
                        height: 100,
                        cornerRadius: 50,
                      )
                    : Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: cAudioSpaceLightBG,
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.white38, size: 48),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.remoteUser?.fullName ?? 'Participant',
                style:
                    MyTextStyle.gilroySemiBold(color: Colors.white, size: 22),
              ),
              const SizedBox(height: 6),
              if (_remoteIsCompany) ...[
                _companyProfilePill(),
                const SizedBox(height: 8),
              ],
              if (controller.callStatus.value == 'connected' &&
                  !controller.isRemoteVideoOn.value)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_off_rounded,
                        size: 14, color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Text(
                      'Camera off',
                      style: MyTextStyle.gilroyRegular(
                          color: Colors.white.withValues(alpha: 0.4), size: 14),
                    ),
                  ],
                )
              else
                Text(
                  _statusText(controller.callStatus.value),
                  style: MyTextStyle.gilroyRegular(
                      color: Colors.white54, size: 15),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallingOverlay(VideoCallController controller) {
    // WhatsApp pattern: overlay shows avatar + status + end call button at bottom.
    // The overlay must NOT block the system back gesture (user can go back to app).
    return Container(
      color: cDarkBG.withValues(alpha: 0.92),
      child: Column(
        children: [
          const Spacer(flex: 3),
          // WhatsApp/FaceTime style pulsing rings around avatar
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulsing ring
                  Container(
                    width: 160 + (_pulseAnimation.value * 30),
                    height: 160 + (_pulseAnimation.value * 30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cPrimary.withValues(
                            alpha: 0.1 + (_pulseAnimation.value * 0.1)),
                        width: 1.5,
                      ),
                    ),
                  ),
                  // Middle pulsing ring
                  Container(
                    width: 140 + (_pulseAnimation.value * 15),
                    height: 140 + (_pulseAnimation.value * 15),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cPrimary.withValues(
                            alpha: 0.15 + (_pulseAnimation.value * 0.1)),
                        width: 1.5,
                      ),
                    ),
                  ),
                  // Avatar
                  child!,
                ],
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: cPrimary.withValues(alpha: 0.3), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: cPrimary.withValues(alpha: 0.15),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: widget.remoteUser != null
                  ? MyCachedProfileImage(
                      imageUrl: widget.remoteUser?.profile,
                      fullName: widget.remoteUser?.fullName,
                      width: 110,
                      height: 110,
                      cornerRadius: 55,
                    )
                  : Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cPrimary.withValues(alpha: 0.15),
                      ),
                      child: const Icon(Icons.videocam_rounded,
                          color: cPrimary, size: 48),
                    ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            widget.remoteUser?.fullName ?? 'Video Call',
            style: MyTextStyle.gilroyBold(color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          if (_remoteIsCompany) ...[
            _companyProfilePill(),
            const SizedBox(height: 10),
          ],
          Text(
            _statusText(controller.callStatus.value),
            style: MyTextStyle.gilroyRegular(color: Colors.white54, size: 15),
          ),
          const SizedBox(height: 24),
          // Subtle animated dots indicator
          if (controller.callStatus.value == 'connecting')
            SizedBox(
              width: 40,
              height: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, _) {
                      final delay = i * 0.3;
                      final value = ((_pulseAnimation.value + delay) % 1.0);
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              cPrimary.withValues(alpha: 0.3 + (value * 0.7)),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          const Spacer(flex: 2),
          // End call button — always accessible (WhatsApp pattern)
          Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 40),
            child: GestureDetector(
              onTap: controller.endCall,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: cRed.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2),
                  ],
                ),
                child: const Icon(Icons.call_end_rounded,
                    color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(VideoCallController controller) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.65),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            if (controller.callStatus.value == 'connected') ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: cGreen, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Obx(() => Text(
                          controller.formattedDuration,
                          style: MyTextStyle.gilroySemiBold(
                              color: cGreen, size: 13),
                        )),
                  ],
                ),
              ),
            ],
            // Screen sharing active indicator
            if (controller.isScreenSharing.value) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.screen_share_rounded, size: 12, color: cGreen),
                    const SizedBox(width: 4),
                    Text('Sharing',
                        style: MyTextStyle.gilroySemiBold(
                            color: cGreen, size: 11)),
                  ],
                ),
              ),
            ],
            const Spacer(),
            // Participant count badge (WhatsApp group call style)
            if (controller.remoteUsers.length > 1)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_rounded,
                          size: 14, color: Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        '${controller.remoteUsers.length + 1}',
                        style: MyTextStyle.gilroySemiBold(
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 12),
                      ),
                    ],
                  ),
                ),
              ),
            // WhatsApp: Add participant button
            if (controller.callStatus.value == 'connected')
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    Get.bottomSheet(
                      AddParticipantSheet(callController: controller),
                      isScrollControlled: true,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: const Icon(Icons.person_add_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            // Screen share toggle (Google Meet style — in top bar)
            GestureDetector(
              onTap: controller.toggleScreenShare,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: controller.isScreenSharing.value
                      ? cGreen.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: controller.isScreenSharing.value
                        ? cGreen.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Icon(
                  controller.isScreenSharing.value
                      ? Icons.stop_screen_share_rounded
                      : Icons.screen_share_rounded,
                  color:
                      controller.isScreenSharing.value ? cGreen : Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Encryption indicator (WhatsApp style)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.lock_rounded,
                  size: 14, color: Colors.white.withValues(alpha: 0.4)),
            ),
            GestureDetector(
              onTap: controller.switchCamera,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Icon(Icons.flip_camera_ios_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(VideoCallController controller) {
    // WhatsApp 2024 / Google Meet floating pill bar
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: cAudioSpaceLightBG.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Audio output toggle (WhatsApp style)
                _controlButton(
                  icon: _audioOutputIcon(controller.audioOutputMode.value),
                  isActive: controller.audioOutputMode.value !=
                      VideoCallAudioOutput.muted,
                  activeColor: Colors.white,
                  inactiveColor: cRed,
                  onTap: controller.toggleAudioOutput,
                ),
                _controlButton(
                  icon: controller.isMicOn.value
                      ? Icons.mic_rounded
                      : Icons.mic_off_rounded,
                  isActive: controller.isMicOn.value,
                  activeColor: Colors.white,
                  inactiveColor: cRed,
                  onTap: controller.toggleMic,
                ),
                _controlButton(
                  icon: controller.isCameraOn.value
                      ? Icons.videocam_rounded
                      : Icons.videocam_off_rounded,
                  isActive: controller.isCameraOn.value,
                  activeColor: Colors.white,
                  inactiveColor: cRed,
                  onTap: controller.toggleCamera,
                ),
                // Message button (WhatsApp style — chat during call)
                _controlButton(
                  icon: Icons.chat_bubble_rounded,
                  isActive: true,
                  activeColor: Colors.white,
                  onTap: () => _openChatWithRemoteUser(controller),
                ),
                // Emoji reaction button (Google Meet/Zoom)
                _controlButton(
                  icon: Icons.emoji_emotions_rounded,
                  isActive: true,
                  activeColor: cGold,
                  onTap: () => _showReactionPicker(controller),
                ),
                _endCallButton(controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    Color activeColor = Colors.white,
    Color inactiveColor = cRed,
  }) {
    // Google Meet style: active = semi-transparent white, inactive = colored background
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.12)
              : inactiveColor.withValues(alpha: 0.25),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? Colors.white.withValues(alpha: 0.15)
                : inactiveColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? activeColor : inactiveColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _endCallButton(VideoCallController controller) {
    // FaceTime style large red end button
    return GestureDetector(
      onTap: controller.endCall,
      child: Container(
        width: 52,
        height: 42,
        decoration: BoxDecoration(
          color: cRed,
          borderRadius: BorderRadius.circular(21),
        ),
        child:
            const Icon(Icons.call_end_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  /// Floating emoji reactions that animate upward — covers most of the screen
  Widget _buildFloatingReactions(VideoCallController controller) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.only(
                right: 24, bottom: MediaQuery.of(context).padding.bottom + 100),
            child: Obx(() {
              // CRITICAL: snapshot to avoid ConcurrentModificationError
              final snapshot =
                  List<ReactionEmoji>.from(controller.activeReactions);
              if (snapshot.isEmpty) return const SizedBox.shrink();
              final visible = snapshot.length > 5
                  ? snapshot.sublist(snapshot.length - 5)
                  : snapshot;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: visible.map((reaction) {
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(reaction.id),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 2000),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity:
                            value < 0.7 ? 1.0 : 1.0 - ((value - 0.7) / 0.3),
                        child: Transform.translate(
                          offset: Offset(0, -200 * value),
                          child: Transform.scale(
                            scale: 1.0 + (0.3 * value),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      reaction.emoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                  );
                }).toList(),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Reaction picker — horizontal row of emojis (Google Meet style)
  void _showReactionPicker(VideoCallController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: const BoxDecoration(
          color: cAudioSpaceLightBG,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: VideoCallController.availableReactions.map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        controller.sendReaction(emoji);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child:
                              Text(emoji, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// WhatsApp-style "poor connection" banner — shown when network quality >= 3 (poor/bad/vbad/down)
  Widget _buildNetworkQualityBanner(VideoCallController controller) {
    final quality = controller.localNetworkQuality.value;
    // 0=unknown, 1=excellent, 2=good — no banner needed
    if (quality < 3) return const SizedBox.shrink();

    String message;
    Color bannerColor;
    if (quality <= 3) {
      message = 'Poor connection';
      bannerColor = cOrange;
    } else {
      message = 'Very poor connection';
      bannerColor = cRed;
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 56,
      left: 40,
      right: 40,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: bannerColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                  Icons.signal_cellular_connected_no_internet_0_bar_rounded,
                  color: Colors.white,
                  size: 14),
              const SizedBox(width: 6),
              Text(message,
                  style: MyTextStyle.gilroySemiBold(
                      color: Colors.white, size: 12)),
            ],
          ),
        ),
      ),
    );
  }

  IconData _audioOutputIcon(VideoCallAudioOutput mode) {
    switch (mode) {
      case VideoCallAudioOutput.speakerphone:
        return Icons.volume_up_rounded;
      case VideoCallAudioOutput.earpiece:
        return Icons.hearing_rounded;
      case VideoCallAudioOutput.muted:
        return Icons.volume_off_rounded;
    }
  }

  /// Long-press participant options (WhatsApp style)
  /// 1-on-1 call: mute only. Multi-person: mute + message.
  void _showParticipantOptions(VideoCallController controller, int remoteUid) {
    if (remoteUid == 0) return;
    final isMultiPerson = controller.remoteUsers.length > 1;
    final isMuted = controller.mutedRemoteUsers.contains(remoteUid);
    final remoteName = widget.remoteUser?.fullName ?? 'Participant';

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: const BoxDecoration(
          color: cAudioSpaceLightBG,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                remoteName,
                style:
                    MyTextStyle.gilroySemiBold(color: Colors.white, size: 16),
              ),
              const SizedBox(height: 16),
              // Mute option (always available)
              ListTile(
                leading: Icon(
                  isMuted ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: isMuted ? cGreen : cRed,
                ),
                title: Text(
                  isMuted ? 'Unmute $remoteName' : 'Mute $remoteName',
                  style:
                      MyTextStyle.gilroySemiBold(color: Colors.white, size: 14),
                ),
                onTap: () {
                  controller.toggleMuteRemoteUser(remoteUid);
                  Get.back();
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.white.withValues(alpha: 0.06),
              ),
              // Message option (multi-person calls only, like WhatsApp)
              if (isMultiPerson) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_rounded,
                      color: Colors.white70),
                  title: Text(
                    'Message $remoteName',
                    style: MyTextStyle.gilroySemiBold(
                        color: Colors.white, size: 14),
                  ),
                  onTap: () {
                    Get.back();
                    _openChatWithRemoteUser(controller);
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  tileColor: Colors.white.withValues(alpha: 0.06),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Open chat with the remote user during the call (WhatsApp pattern)
  void _openChatWithRemoteUser(VideoCallController controller) {
    final remoteUser = widget.remoteUser;
    if (remoteUser == null || remoteUser.id == null) return;
    final otherUserId = remoteUser.id!.toInt();
    final conversationId = otherUserId.toConversationId();
    final chatRoom = ChatUserRoom(
      conversationId: conversationId,
      userIdOrRoomId: otherUserId,
      type: 1,
    );
    Get.to(() => ChattingView(chatUserRoom: chatRoom));
  }

  String _statusText(String status) {
    switch (status) {
      case 'connecting':
        return 'Connecting...';
      case 'waiting':
        return 'Waiting for participant...';
      case 'connected':
        return 'Connected';
      case 'ended':
        return 'Call ended';
      case 'failed':
        return 'Connection failed';
      default:
        return '';
    }
  }
}
