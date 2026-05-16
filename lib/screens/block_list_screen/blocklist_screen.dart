import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/common/widgets/no_data_view.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/block_list_screen/block_list_controller.dart';
import 'package:untitled/screens/extra_views/back_button.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/utilities/const.dart';

class BlockListScreen extends StatelessWidget {
  const BlockListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    BlockListController controller = BlockListController();
    return Scaffold(
      body: Column(
        children: [
          TopBarForInView(title: LKeys.blockList.tr),
          Expanded(
            child: GetBuilder(
              init: controller,
              builder: (controller) {
                return NoDataView(
                  showShow: controller.users.isEmpty && !controller.isLoading.value,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: controller.users.length,
                    itemBuilder: (context, index) {
                      var user = controller.users[index];
                      return card(user, controller);
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget card(User user, BlockListController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cLightText.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          MyCachedProfileImage(
            imageUrl: user.profile,
            fullName: user.fullName,
            width: 50,
            height: 50,
            cornerRadius: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName ?? '',
                        style: MyTextStyle.gilroyBold(size: 15, color: cNavy),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 3),
                    VerifyIcon(user: user)
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "@${user.username ?? ''}",
                  style: MyTextStyle.gilroyRegular(color: cLightText, size: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              controller.unblockUser(user, () {
                controller.users.removeWhere((element) => element.id == user.id);
                controller.update();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: ShapeDecoration(
                color: cRed.withValues(alpha: 0.12),
                shape: const SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 8, cornerSmoothing: cornerSmoothing)),
                ),
              ),
              child: Text(
                LKeys.unBlock.tr.toUpperCase(),
                style: MyTextStyle.gilroySemiBold(size: 11).copyWith(letterSpacing: 1, color: cRed),
              ),
            ),
          )
        ],
      ),
    );
  }
}
