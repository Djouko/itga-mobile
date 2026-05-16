import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/utils/media_compressor.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/tabbar/tabbar_screen.dart';
import 'package:untitled/screens/username_screen/username_controller.dart';
import 'package:untitled/utilities/const.dart';

class ProfilePictureController extends UsernameController {
  final ImagePicker picker = ImagePicker();
  String imagePath = "";
  XFile? file;

  void pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      XFile? image = await picker.pickImage(source: source, maxHeight: Limits.imageSize, maxWidth: Limits.imageSize, imageQuality: Limits.quality);
      print(image);
      if (image != null) {
        file = image;
        imagePath = image.path;
        update();
      }
    } catch (e) {
      showSnackBar("Invalid Image");
    }
  }

  void uploadImage() async {
    if (file == null) {
      showSnackBar(LKeys.pleaseSelectImage.tr);
      return;
    }
    startLoading();
    // Instagram/WhatsApp: compress profile image to WebP 400px before upload
    final compressed = await MediaCompressor.shared.compressProfileImage(file!);
    UserService.shared.editProfile(
      profileImage: compressed,
      completion: (p0) {
        stopLoading();
        Get.offAll(() => TabBarScreen());
      },
    );
  }
}
