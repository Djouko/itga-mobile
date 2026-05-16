import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/utilities/const.dart';

import 'audio_space_controller.dart';

class AudioSpaceMessagesView extends StatelessWidget {
  final AudioSpaceController controller;

  AudioSpaceMessagesView(this.controller);

  @override
  Widget build(BuildContext context) {
    // L'Expanded doit être à l'extérieur de l'Obx pour être un enfant direct de la Column dans AudioSpaceScreen
    return Expanded(
      child: Obx(() {
        if (controller.messages.isEmpty) {
          return Container(
            alignment: Alignment.center,
            child: Text(
              LKeys.noMessages.tr,
              style: MyTextStyle.gilroySemiBold(color: cLightText),
            ),
          );
        } else {
          return ListView.builder(
            reverse: true,
            controller: controller.messageScrollController,
            itemCount: controller.messages.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              // On récupère les messages dans l'ordre inverse pour le reverse: true
              var message = controller.messages.reversed.toList()[index];
              final senderName = (message.senderName?.trim().isNotEmpty == true
                      ? message.senderName
                      : message.user?.displayName ?? message.user?.fullName) ??
                  '';
              final senderAvatar =
                  (message.senderAvatar?.trim().isNotEmpty == true
                      ? message.senderAvatar
                      : message.user?.displayAvatar ?? message.user?.image);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: MyCachedProfileImage(
                        imageUrl: senderAvatar,
                        fullName: senderName,
                        width: 40,
                        height: 40,
                        cornerRadius: 100,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: cAudioSpaceLightBG,
                          borderRadius: SmoothBorderRadius(
                              cornerRadius: 12,
                              cornerSmoothing: cornerSmoothing),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    message.senderProfileType == 'company'
                                        ? 'Entreprise · $senderName'
                                        : senderName,
                                    style: MyTextStyle.gilroySemiBold(
                                        color: cAudioSpaceText),
                                  ),
                                ),
                                Text(
                                  message.getChatTime(),
                                  style: MyTextStyle.gilroyRegular(
                                      color: cLightText.withValues(alpha: 0.7),
                                      size: 12),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              message.content ?? '',
                              style: MyTextStyle.gilroyMedium(
                                  color: cLightText.withValues(alpha: 0.7)),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        }
      }),
    );
  }
}
