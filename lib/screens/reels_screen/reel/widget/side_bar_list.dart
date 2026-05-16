import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/extensions/int_extension.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/models/reel_model.dart';
import 'package:untitled/models/reel_model_extension.dart';
import 'package:untitled/screens/reels_screen/reel/reel_page_controller.dart';
import 'package:untitled/utilities/const.dart';

class SideBarList extends StatelessWidget {
  final ReelController controller;

  const SideBarList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          InkWell(
            onTap: controller.onProfileTap,
            child: MyCachedProfileImage(
              imageUrl: controller.reel.value?.company?.logo ??
                  controller.reel.value?.user?.profile,
              fullName: controller.reel.value?.company?.name ??
                  controller.reel.value?.user?.fullName,
              width: 40,
              height: 40,
              cornerRadius: 40,
            ),
          ),
          const SizedBox(height: 13),
          Obx(() {
            final reel = controller.reel.value;
            final isLiked = reel?.isLike == 1;
            return GestureDetector(
              onTap: controller.onLikeTap,
              child: Column(
                children: [
                  AnimatedScale(
                    scale: isLiked ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Image.asset(
                      isLiked ? MyImages.heartFill : MyImages.heart,
                      width: 28,
                      height: 28,
                      color: isLiked ? cRed : cWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (reel?.likesCount ?? 0).makeToString(),
                    style: MyTextStyle.gilroyMedium(size: 13, color: cWhite),
                  ),
                ],
              ),
            );
          }),
          Obx(() {
            Reel? reel = controller.reel.value;
            return IconWithLabel(
              onTap: controller.onCommentTap,
              image: MyImages.comment,
              value: reel?.commentsCount ?? 0, // Sécurisation contre le null
            );
          }),
          Obx(() {
            Reel? reel = controller.reel.value;
            return IconWithLabel(
              onTap: controller.onSaved,
              image: (reel?.isSaved == true)
                  ? MyImages.bookmarkFill
                  : MyImages.bookmark,
            );
          }),
          IconWithLabel(
            onTap: controller.onShareTap,
            image: MyImages.share,
            size: 32,
          ),
          if (!controller.isMyReel)
            IconWithLabel(
              onTap: controller.reportReel,
              image: MyImages.report,
              size: 32,
            ),
          const SizedBox(height: 2),
          Obx(() {
            Reel? reel = controller.reel.value;
            return Visibility(
              visible: reel?.music != null,
              child: IconWithMusic(
                onAudioTap: controller.onAudioTap,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class IconWithMusic extends StatelessWidget {
  final VoidCallback onAudioTap;

  const IconWithMusic({super.key, required this.onAudioTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAudioTap,
      child: Container(
        height: 37,
        width: 37,
        margin: const EdgeInsets.only(top: 7.5),
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: cPrimary, shape: BoxShape.circle),
        child: CircleAvatar(
          radius: 10,
          backgroundColor: cBlack,
          foregroundColor: cPrimary,
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Image.asset(
              MyImages.musicNote,
              height: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class IconWithLabel extends StatelessWidget {
  final VoidCallback onTap;
  final String image;
  final num? value;
  final double size;
  final Color iconColor;

  const IconWithLabel({
    super.key,
    required this.onTap,
    required this.image,
    this.value,
    this.iconColor = cWhite,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.5),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child:
                Image.asset(image, width: size, height: size, color: iconColor),
          ),
          if (value != null) ...[
            SizedBox(height: 5),
            Text(
              value?.makeToString() ?? '0',
              style: MyTextStyle.gilroyMedium(size: 13, color: cWhite).copyWith(
                shadows: <Shadow>[
                  Shadow(
                    offset: const Offset(0.0, 1.0),
                    blurRadius: 3.0,
                    color: cLightText,
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}
