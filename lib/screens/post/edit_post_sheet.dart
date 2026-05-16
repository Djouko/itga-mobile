import 'package:detectable_text_field/detectable_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/post/post_controller.dart';
import 'package:untitled/utilities/const.dart';

class EditPostSheet extends StatefulWidget {
  final PostController controller;
  const EditPostSheet({super.key, required this.controller});

  @override
  State<EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<EditPostSheet> {
  late final DetectableTextEditingController textController;

  @override
  void initState() {
    super.initState();
    textController = DetectableTextEditingController(
      text: widget.controller.post.desc ?? '',
      regExp: RegExp(r'(?:#|@)([a-zA-Z0-9_]+)'),
      detectedStyle: MyTextStyle.outfitLight(size: 16, color: cHashtagColor).copyWith(height: 1.4),
    );
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cDarkBG,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cLightText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              LKeys.editPost.tr,
              style: MyTextStyle.gilroyBold(color: cWhite, size: 18),
            ),
            const SizedBox(height: 12),
            DetectableTextField(
              controller: textController,
              autofocus: true,
              maxLines: 5,
              minLines: 2,
              style: MyTextStyle.gilroyRegular(color: cWhite, size: 16),
              decoration: InputDecoration(
                hintText: LKeys.editPostHint.tr,
                hintStyle: MyTextStyle.gilroyRegular(color: cLightText, size: 16),
                filled: true,
                fillColor: cBlack.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cLightText.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cLightText.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cPrimary),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  widget.controller.saveEditedPost(desc: textController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cPrimary,
                  foregroundColor: cBlack,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                child: Text(
                  LKeys.save.tr,
                  style: MyTextStyle.gilroySemiBold(color: cBlack, size: 15),
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
