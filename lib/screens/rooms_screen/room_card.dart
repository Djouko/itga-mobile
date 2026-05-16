import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/int_extension.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/room_model.dart';
import 'package:untitled/screens/chats_screen/chatting_screen/chatting_view.dart';
import 'package:untitled/screens/rooms_screen/room_controller.dart';
import 'package:untitled/screens/rooms_screen/room_sheet.dart';
import 'package:untitled/utilities/const.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final bool isFromHome;

  const RoomCard({Key? key, required this.room, this.isFromHome = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var controller = RoomController(room);
    return GetBuilder(
        tag: '${room.id}',
        init: controller,
        builder: (controller) {
          return GestureDetector(
            onTap: () {
              if (controller.room.getUserAccessType() == GroupUserAccessType.member || controller.room.getUserAccessType() == GroupUserAccessType.admin || controller.room.getUserAccessType() == GroupUserAccessType.coAdmin) {
                Get.to(() => ChattingView(room: controller.room))?.then(controller.onBack);
              } else {
                Get.bottomSheet(
                    RoomSheet(
                      controller: controller,
                      room: controller.room,
                    ),
                    isScrollControlled: true);
              }
            },
            child: isFromHome ? homeCard(controller) : simpleCard(controller),
          );
        });
  }

  Widget simpleCard(RoomController controller) {
    final hasDesc = (controller.room.desc ?? '').isNotEmpty;
    final interests = controller.room.getInterests();
    return Container(
      decoration: BoxDecoration(
        color: cLightBg.withValues(alpha: 0.4),
        borderRadius: const SmoothBorderRadius.all(SmoothRadius(cornerRadius: 14, cornerSmoothing: cornerSmoothing)),
        border: Border.all(color: cLightText.withValues(alpha: 0.08)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipSmoothRect(
                radius: const SmoothBorderRadius.all(SmoothRadius(cornerRadius: 14, cornerSmoothing: cornerSmoothing)),
                child: MyCachedImage(
                  imageUrl: controller.room.photo,
                  width: 52,
                  height: 52,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.room.title ?? '',
                      style: MyTextStyle.gilroyBold(size: 17, color: cNavy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.people_outline_rounded, size: 14, color: cLightText),
                        const SizedBox(width: 4),
                        Text(
                          '${(controller.room.totalMember ?? 0).makeToString()} ${LKeys.members.tr}',
                          style: MyTextStyle.gilroyMedium(size: 13, color: cLightText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _accessBadge(controller.room.getUserAccessType()),
            ],
          ),
          if (hasDesc) ...[
            const SizedBox(height: 10),
            Text(
              controller.room.desc!,
              style: MyTextStyle.gilroyRegular(color: cDarkText.withValues(alpha: 0.7), size: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (interests.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: interests.map((e) {
                return RoomCardInterestTagToShow(
                  tag: e.title ?? '',
                  color: cGreen,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _accessBadge(GroupUserAccessType accessType) {
    String label;
    Color color;
    switch (accessType) {
      case GroupUserAccessType.member:
      case GroupUserAccessType.admin:
      case GroupUserAccessType.coAdmin:
        label = LKeys.members.tr;
        color = cGreen;
        break;
      case GroupUserAccessType.invited:
        label = LKeys.invited.tr;
        color = cBlueTick;
        break;
      case GroupUserAccessType.requested:
        label = LKeys.requested.tr;
        color = cOrange;
        break;
      case GroupUserAccessType.none:
        label = LKeys.joinThisRoom.tr;
        color = cPrimary;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: MyTextStyle.gilroySemiBold(size: 11, color: color),
      ),
    );
  }

  Widget homeCard(RoomController controller) {
    return AspectRatio(
      aspectRatio: .7,
      child: ClipSmoothRect(
        radius: const SmoothBorderRadius.all(SmoothRadius(cornerRadius: 15, cornerSmoothing: cornerSmoothing)),
        child: Column(
          children: [
            ClipSmoothRect(
              radius: const SmoothBorderRadius.vertical(top: SmoothRadius(cornerRadius: 15, cornerSmoothing: cornerSmoothing)),
              child: MyCachedImage(imageUrl: controller.room.photo, width: double.infinity, height: 110),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: ShapeDecoration(color: cDarkGreen, shape: SmoothRectangleBorder(borderRadius: SmoothBorderRadius.vertical(bottom: SmoothRadius(cornerRadius: 15, cornerSmoothing: 1)))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.room.title ?? '',
                          style: MyTextStyle.gilroySemiBold(color: cWhite),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${controller.room.getInterestWithHashtag().toLowerCase()}',
                          style: MyTextStyle.gilroyRegular(color: cPrimary),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                        ),
                      ],
                    ),
                    RichText(
                      text: TextSpan(text: (controller.room.totalMember ?? 0).makeToString(), style: MyTextStyle.gilroySemiBold(size: 14, color: cWhite), children: [
                        TextSpan(
                          text: ' ${LKeys.members.tr}',
                          style: MyTextStyle.gilroyLight(size: 14, color: cWhite),
                        )
                      ]),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class RoomCardInterestTagToShow extends StatelessWidget {
  const RoomCardInterestTagToShow({Key? key, required this.tag, this.color = cPrimary}) : super(key: key);
  final String tag;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(100)),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      margin: const EdgeInsets.only(right: 5, top: 5, bottom: 5),
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          tag.toUpperCase(),
          style: MyTextStyle.gilroyBold(size: 13, color: color).copyWith(letterSpacing: 0.5),
        ),
      ),
    );
  }
}
