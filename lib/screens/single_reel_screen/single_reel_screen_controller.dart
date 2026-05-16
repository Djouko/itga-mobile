import 'package:get/get.dart';
import 'package:untitled/common/api_service/reel_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/connectivity_service.dart';
import 'package:untitled/models/reel_model.dart';

class SingleReelScreenController extends BaseController {
  RxList<Reel> reels = RxList();
  num reelId;

  SingleReelScreenController(this.reelId);

  @override
  void onReady() {
    fetchReel();
    ConnectivityService.instance.addOnBackOnline('single_reel_$reelId', () {
      if (hasNetworkError) {
        hasNetworkError = false;
        fetchReel();
      }
    });
    super.onReady();
  }

  @override
  void onClose() {
    ConnectivityService.instance.removeOnBackOnline('single_reel_$reelId');
    super.onClose();
  }

  void fetchReel() async {
    isLoading.value = true;
    hasNetworkError = false;
    try {
      var reel = await ReelService.shared.fetchReelById(reelId: reelId);
      if (reel != null) {
        reels.value = [reel];
        hasNetworkError = false;
      }
    } catch (_) {
      hasNetworkError = true;
    } finally {
      isLoading.value = false;
    }
  }
}
