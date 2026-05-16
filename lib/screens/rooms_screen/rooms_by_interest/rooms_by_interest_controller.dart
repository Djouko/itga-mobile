import 'package:untitled/common/api_service/room_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/managers/connectivity_service.dart';
import 'package:untitled/models/room_model.dart';

class RoomsByInterestController extends BaseController {
  List<Room> rooms = [];
  int? interestId;

  RoomsByInterestController({this.interestId});

  @override
  void onReady() {
    if (interestId != null) {
      fetchRooms((interestId ?? 0).toInt());
    } else {
      fetchRandomRooms();
    }
    ConnectivityService.instance.addOnBackOnline('rooms_$hashCode', () {
      if (hasNetworkError) {
        hasNetworkError = false;
        if (interestId != null) {
          fetchRooms((interestId ?? 0).toInt());
        } else {
          fetchRandomRooms();
        }
      }
    });
    super.onReady();
  }

  @override
  void onClose() {
    ConnectivityService.instance.removeOnBackOnline('rooms_$hashCode');
    super.onClose();
  }

  Future<void> fetchRandomRooms() async {
    isLoading.value = true;
    hasNetworkError = false;
    update();
    try {
      await RoomService.shared.fetchRooms((rooms) {
        isLoading.value = false;
        hasNetworkError = false;
        this.rooms = rooms;
        update();
      });
    } catch (_) {
      isLoading.value = false;
      hasNetworkError = true;
      update();
    }
  }

  Future<void> fetchRooms(int interestId) async {
    if (rooms.isEmpty) {
      isLoading.value = true;
      update();
    }

    try {
      await RoomService.shared.fetchRoomByInterest(interestId, rooms.length, (rooms) {
        isLoading.value = false;
        this.rooms.addAll(rooms);
        update();
      });
    } catch (_) {
      isLoading.value = false;
      hasNetworkError = true;
      update();
    }
  }
}
