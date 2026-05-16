import 'package:detectable_text_field/detectable_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/post/post_controller.dart';
import 'package:untitled/utilities/const.dart';

class RepostSheet extends StatefulWidget {
  final PostController controller;

  const RepostSheet({super.key, required this.controller});

  @override
  State<RepostSheet> createState() => _RepostSheetState();
}

class _RepostSheetState extends State<RepostSheet> {
  bool showTextField = false;
  late final DetectableTextEditingController textController;

  @override
  void initState() {
    super.initState();
    textController = DetectableTextEditingController(
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
              LKeys.repost.tr,
              style: MyTextStyle.gilroyBold(color: cWhite, size: 18),
            ),
            const SizedBox(height: 14),
            if (!showTextField) ...[
              _buildOption(
                icon: Icons.repeat_rounded,
                title: LKeys.repostInstantly.tr,
                onTap: () {
                  Get.back();
                  widget.controller.repostPost();
                },
              ),
              const SizedBox(height: 10),
              _buildOption(
                icon: Icons.edit_note_rounded,
                title: LKeys.repostWithThoughts.tr,
                onTap: () {
                  setState(() => showTextField = true);
                },
              ),
            ] else ...[
              DetectableTextField(
                controller: textController,
                autofocus: true,
                maxLines: 4,
                minLines: 2,
                style: MyTextStyle.gilroyRegular(color: cWhite, size: 16),
                decoration: InputDecoration(
                  hintText: LKeys.addYourThoughts.tr,
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
                    widget.controller.repostPost(desc: textController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cPrimary,
                    foregroundColor: cBlack,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: Text(
                    LKeys.repost.tr,
                    style: MyTextStyle.gilroySemiBold(color: cBlack, size: 15),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cBlack.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cLightText.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: cPrimary, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: MyTextStyle.gilroySemiBold(color: cWhite, size: 16),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cLightText, size: 22),
          ],
        ),
      ),
    );
  }
}
