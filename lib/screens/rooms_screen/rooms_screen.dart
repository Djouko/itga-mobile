import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/widgets/network_error_view.dart';
import 'package:untitled/common/widgets/shimmer_loading.dart';
import 'package:untitled/screens/rooms_screen/room_card.dart';
import 'package:untitled/screens/rooms_screen/room_screen_top_bar.dart';
import 'package:untitled/screens/rooms_screen/rooms_by_interest/room_explore_by_interests.dart';
import 'package:untitled/screens/rooms_screen/rooms_by_interest/rooms_by_interest_controller.dart';

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var controller = RoomsByInterestController();
    return GetBuilder(
        init: controller,
        builder: (controller) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RoomScreenTopBar(),
              Expanded(
                child: GetBuilder(
                    init: controller,
                    tag: 'all',
                    builder: (controller) {
                      if (controller.hasNetworkError && controller.rooms.isEmpty) {
                        return NetworkErrorView(onRetry: () => controller.fetchRandomRooms());
                      }
                      return CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          const SliverToBoxAdapter(
                            child: RoomExploreByInterests(),
                          ),
                          if (controller.isLoading.value && controller.rooms.isEmpty)
                            const SliverToBoxAdapter(child: RoomShimmerPlaceholder())
                          else
                            SliverList.builder(
                              itemCount: controller.rooms.length,
                              itemBuilder: (context, index) {
                                return RepaintBoundary(
                                  child: RoomCard(room: controller.rooms[index]),
                                );
                              },
                            ),
                          const SliverPadding(padding: EdgeInsets.only(bottom: 10)),
                        ],
                      );
                    }),
              ),
            ],
          );
        });
  }
}
