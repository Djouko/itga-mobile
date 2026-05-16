import 'dart:math' as math;

import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/audio_space/audio_spaces_screen/audio_space_screen/audio_space_screen.dart';
import 'package:untitled/screens/audio_space/audio_spaces_screen/audio_spaces_controller.dart';
import 'package:untitled/screens/audio_space/models/audio_space.dart';
import 'package:untitled/screens/audio_space/models/audio_space_user.dart';
import 'package:untitled/screens/extra_views/buttons.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/rooms_screen/rooms_by_interest/room_explore_by_interests.dart';
import 'package:untitled/utilities/const.dart';

import '../create_audio_space_screen/create_audio_space_screen.dart';

class AudioSpacesScreen extends StatelessWidget {
  const AudioSpacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AudioSpacesController controller = AudioSpacesController();
    return Scaffold(
      body: GetBuilder(
          init: controller,
          builder: (controller) {
            return Column(
              children: [
                top(),
                Expanded(
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: RoomExploreByInterests(
                            audioSpaces: controller.filteredSpaces,
                            controller: controller),
                      ),
                      SliverToBoxAdapter(
                        child: _SpaceFilterTabs(controller: controller),
                      ),
                      if (controller.filteredSpaces.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptySpacesState(
                              filter: controller.currentFilter),
                        )
                      else
                        SliverList.builder(
                          itemCount: controller.filteredSpaces.length,
                          itemBuilder: (context, index) {
                            return AudioSpaceCard(
                                audioSpace: controller.filteredSpaces[index]);
                          },
                        ),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 10)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: CommonButton(
                      text: LKeys.startRoom,
                      onTap: () {
                        Get.to(() => CreateAudioSpaceScreen());
                      }),
                )
              ],
            );
          }),
    );
  }

  Widget top() {
    return Container(
      color: cBG,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const BackButton(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TopBarForLogin(
                  titleEnd: LKeys.spaces,
                  alignment: MainAxisAlignment.start,
                  titleStart: LKeys.audio,
                  size: 20,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class AudioSpaceCard extends StatefulWidget {
  final AudioSpace audioSpace;

  const AudioSpaceCard({super.key, required this.audioSpace});

  @override
  State<AudioSpaceCard> createState() => _AudioSpaceCardState();
}

class _AudioSpaceCardState extends State<AudioSpaceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;
  bool _isPressed = false;

  AudioSpace get audioSpace => widget.audioSpace;

  @override
  void initState() {
    super.initState();
    // Twitter Spaces style waveform animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _onTapHandler(BuildContext context) {
    var listenersLimit =
        SessionManager.shared.getSettings()?.audioSpaceListenersLimit ?? 0;
    var myID = SessionManager.shared.getUserID();
    var isAdmin = audioSpace.admins.isNotEmpty &&
        audioSpace.admins.first.id?.toInt() == myID;
    if (listenersLimit == 0 ||
        audioSpace.requestsAndListener.length < listenersLimit ||
        isAdmin) {
      var user = ((audioSpace.users ?? []) + (audioSpace.leavedUsers ?? []))
          .firstWhereOrNull((u) => u.id?.toInt() == myID);

      if (user?.type == AudioSpaceUserType.kickedOut) {
        BaseController.share.showSnackBar(LKeys.adminHasKickedYouOut.tr);
      } else {
        Get.to(() => AudioSpaceScreen(audioSpace: audioSpace));
      }
    } else {
      BaseController.share.showSnackBar(LKeys.listenerLimitReached.tr,
          type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => _onTapHandler(context),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
          decoration: BoxDecoration(
            color: cAudioSpaceBG,
            borderRadius: SmoothBorderRadius.all(SmoothRadius(
                cornerRadius: 16, cornerSmoothing: cornerSmoothing)),
            border: Border.all(color: cWhite.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        audioSpace.title ?? '',
                        style: MyTextStyle.gilroyBold(
                            size: 18, color: cWhite.withValues(alpha: 0.9)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (audioSpace.isVideoConference)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: cPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: cPrimary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.videocam_rounded,
                                  size: 12, color: cPrimary),
                              const SizedBox(width: 3),
                              Text('VIDEO',
                                  style: MyTextStyle.gilroyBold(
                                      size: 9, color: cPrimary)),
                            ],
                          ),
                        ),
                      ),
                    _buildLiveBadge(),
                  ],
                ),
              ),
              if (audioSpace.interests.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: _buildInterests(),
                ),
              if ((audioSpace.description ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Text(
                    audioSpace.description!,
                    style: MyTextStyle.gilroyRegular(
                        size: 13, color: cWhite.withValues(alpha: 0.5)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _buildHostsList(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _buildBottomRow(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    // Twitter Spaces style LIVE badge with animated waveform bars
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated waveform bars
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(3, (i) {
                  final phase = i * 0.35;
                  final value =
                      math.sin((_waveController.value + phase) * math.pi);
                  final height = 4.0 + (value.abs() * 6.0);
                  return Container(
                    width: 2,
                    height: height,
                    margin: EdgeInsets.only(right: i < 2 ? 1.5 : 0),
                    decoration: BoxDecoration(
                      color: cGreen,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 4),
          Text('LIVE', style: MyTextStyle.gilroyBold(size: 9, color: cGreen)),
        ],
      ),
    );
  }

  Widget _buildInterests() {
    return Wrap(
      spacing: 0,
      children: audioSpace.interests.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              e.title ?? '',
              style: MyTextStyle.gilroyMedium(
                  size: 13, color: cPrimary.withValues(alpha: 0.7)),
            ),
            if (audioSpace.interests.last != e)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('·',
                    style: MyTextStyle.gilroyBold(
                        size: 16, color: cLightText.withValues(alpha: 0.3))),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHostsList() {
    final hosts = audioSpace.hostsWithAdmin;
    if (hosts.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox(
            width: (hosts.length.clamp(0, 5) * 30) + 8,
            height: 38,
            child: Stack(
              clipBehavior: Clip.none,
              children: List.generate(hosts.length.clamp(0, 5), (index) {
                return Positioned(
                  left: index * 26.0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cAudioSpaceBG, width: 2),
                    ),
                    child: MyCachedProfileImage(
                      height: 34,
                      width: 34,
                      fullName: hosts[index].fullName,
                      imageUrl: hosts[index].image,
                      cornerRadius: 17,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hosts.map((h) => h.fullName ?? '').take(2).join(', ') +
                  (hosts.length > 2 ? ' +${hosts.length - 2}' : ''),
              style: MyTextStyle.gilroyMedium(
                  size: 12, color: cWhite.withValues(alpha: 0.5)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomRow() {
    final speakerCount = audioSpace.hostsWithAdmin.length;
    final listenerCount = audioSpace.requestsAndListener.length;
    final timeAgo = _formatTimeAgo(audioSpace.createdAt);
    return Row(
      children: [
        // Twitter Spaces style: "X speakers · Y listeners"
        Text(
          '$speakerCount ${speakerCount == 1 ? 'speaker' : 'speakers'}',
          style: MyTextStyle.gilroySemiBold(
              size: 12, color: cWhite.withValues(alpha: 0.45)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text('·',
              style: MyTextStyle.gilroyBold(
                  size: 14, color: cWhite.withValues(alpha: 0.25))),
        ),
        Text(
          '$listenerCount ${listenerCount == 1 ? 'listener' : 'listeners'}',
          style: MyTextStyle.gilroySemiBold(
              size: 12, color: cWhite.withValues(alpha: 0.45)),
        ),
        if (timeAgo.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text('·',
                style: MyTextStyle.gilroyBold(
                    size: 14, color: cWhite.withValues(alpha: 0.25))),
          ),
          Text(
            timeAgo,
            style: MyTextStyle.gilroyRegular(
                size: 11, color: cWhite.withValues(alpha: 0.3)),
          ),
        ],
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cPrimary.withValues(alpha: 0.25)),
          ),
          child: Text(
            LKeys.joinThisRoom.tr,
            style: MyTextStyle.gilroySemiBold(size: 12, color: cPrimary),
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _EmptySpacesState extends StatelessWidget {
  final SpaceFilter filter;
  const _EmptySpacesState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final icon = filter == SpaceFilter.video
        ? Icons.videocam_off_rounded
        : filter == SpaceFilter.audio
            ? Icons.mic_off_rounded
            : Icons.spatial_audio_off_rounded;
    final text = filter == SpaceFilter.video
        ? 'No video rooms live'
        : filter == SpaceFilter.audio
            ? 'No audio spaces live'
            : 'No spaces live right now';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cWhite.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: cWhite.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: MyTextStyle.gilroySemiBold(
                size: 16, color: cWhite.withValues(alpha: 0.35)),
          ),
          const SizedBox(height: 6),
          Text(
            'Start a room and invite others to join!',
            style: MyTextStyle.gilroyRegular(
                size: 13, color: cWhite.withValues(alpha: 0.2)),
          ),
        ],
      ),
    );
  }
}

class _SpaceFilterTabs extends StatelessWidget {
  final AudioSpacesController controller;
  const _SpaceFilterTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: SpaceFilter.values.map((filter) {
          final isSelected = controller.currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => controller.setFilter(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? cPrimary : cAudioSpaceBG,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isSelected ? cPrimary : cWhite.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (filter == SpaceFilter.audio)
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Icon(Icons.mic_rounded,
                            size: 14, color: isSelected ? cBlack : cLightText),
                      ),
                    if (filter == SpaceFilter.video)
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Icon(Icons.videocam_rounded,
                            size: 14, color: isSelected ? cBlack : cLightText),
                      ),
                    Text(
                      filter == SpaceFilter.all
                          ? LKeys.allRooms.tr
                          : filter == SpaceFilter.audio
                              ? LKeys.audioRooms.tr
                              : LKeys.videoRooms.tr,
                      style: MyTextStyle.gilroySemiBold(
                        size: 13,
                        color:
                            isSelected ? cBlack : cWhite.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
