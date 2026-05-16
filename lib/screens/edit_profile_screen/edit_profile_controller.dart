import 'package:detectable_text_field/detectable_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/utils/media_compressor.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/utilities/const.dart';

import '../profile_picture_screen/profile_picture_controller.dart';

class EditProfileController extends ProfilePictureController {
  TextEditingController fullNameController = TextEditingController();
  DetectableTextEditingController bioEditController = DetectableTextEditingController(
    detectedStyle: MyTextStyle.gilroyRegular(color: cPrimary).copyWith(height: 1.2),
    regExp: detectionRegExp(atSign: false, url: true, hashtag: false)!,
  );
  TextEditingController headlineController = TextEditingController();
  TextEditingController aboutController = TextEditingController();
  TextEditingController skillsController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController websiteController = TextEditingController();
  TextEditingController pronounsController = TextEditingController();
  XFile? backgroundImageFile;

  @override
  void onInit() {
    fetchOldValues();
    bioEditController.addListener(() {
      update(['bio']);
    });
    super.onInit();
  }

  void pickBGImage({ImageSource source = ImageSource.gallery}) async {
    try {
      XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        backgroundImageFile = image;
        update();
      }
    } catch (e) {
      showSnackBar("Invalid Image");
    }
  }

  void fetchOldValues() {
    var user = SessionManager.shared.getUser();
    if (user != null) {
      textController.text = user.username ?? '';
      fullNameController.text = user.fullName ?? '';
      bioEditController.text = user.bio ?? '';
      headlineController.text = user.headline ?? '';
      aboutController.text = user.about ?? '';
      skillsController.text = user.skills ?? '';
      locationController.text = user.location ?? '';
      websiteController.text = user.website ?? '';
      pronounsController.text = user.pronouns ?? '';
      selectedInterests = user.getInterests();
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    bioEditController.dispose();
    headlineController.dispose();
    aboutController.dispose();
    skillsController.dispose();
    locationController.dispose();
    websiteController.dispose();
    pronounsController.dispose();
    super.onClose();
  }

  void onSubmit() async {
    if (fullNameController.text.isEmpty) {
      showSnackBar(LKeys.pleaseEnterFullName.tr, type: SnackBarType.error);
      return;
    }
    startLoading();
    // Instagram/LinkedIn: compress images before upload
    XFile? compressedProfile = file != null
        ? await MediaCompressor.shared.compressProfileImage(file!)
        : null;
    XFile? compressedBg = backgroundImageFile != null
        ? await MediaCompressor.shared.compressImage(backgroundImageFile!)
        : null;

    checkForUsername(completion: (isAvailable) {
      stopLoading();
      if (!isAvailable) {
        showSnackBar(LKeys.thisUsernameIsNotAvailable.tr, type: SnackBarType.error);
      } else {
        startLoading();
        UserService.shared.editProfile(
          profileImage: compressedProfile,
          bgImage: compressedBg,
          fullName: fullNameController.text,
          username: textController.text,
          bio: bioEditController.text,
          interests: selectedInterests,
          headline: headlineController.text.isNotEmpty ? headlineController.text : null,
          about: aboutController.text.isNotEmpty ? aboutController.text : null,
          skills: skillsController.text.isNotEmpty ? skillsController.text : null,
          location: locationController.text.isNotEmpty ? locationController.text : null,
          website: websiteController.text.isNotEmpty ? websiteController.text : null,
          pronouns: pronounsController.text.isNotEmpty ? pronounsController.text : null,
          completion: (p0) {
            stopLoading();
            Get.back();
            showSnackBar(LKeys.profileUpdatedSuccessfully.tr, type: SnackBarType.success);
          },
        );
      }
    });
  }
}
