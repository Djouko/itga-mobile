import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/widgets/buttons/floating_btn_for_creating.dart';
import 'package:untitled/common/widgets/network_error_view.dart';
import 'package:untitled/common/widgets/shimmer_loading.dart';
import 'package:untitled/common/widgets/no_data_view.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/room_model.dart';
import 'package:untitled/screens/feed_screen/feed_screen_controller.dart';
import 'package:untitled/screens/feed_screen/feed_screen_top_bar.dart';
import 'package:untitled/screens/feed_screen/feed_stories_controller.dart';
import 'package:untitled/screens/feed_screen/feed_story_screen.dart';
import 'package:untitled/screens/post/post_card.dart';
import 'package:untitled/screens/rooms_screen/room_card.dart';
import 'package:untitled/utilities/const.dart';

final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
    new GlobalKey<RefreshIndicatorState>();

class FeedScreen extends StatelessWidget {
  final ScrollController scrollController;

  const FeedScreen({Key? key, required this.scrollController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    FeedScreenController controller = FeedScreenController(
        isFromFeedScreen: true, scrollController: scrollController);
    FeedStoriesController feedStoriesController = FeedStoriesController();
    return Scaffold(
      body: Stack(
        children: [
          GetBuilder(
              init: controller,
              builder: (controller) {
                return Container(
                  color: cLightBg,
                  height: (controller.posts.isEmpty ? (0) : Get.height / 2),
                );
              }),
          GetBuilder(
              init: feedStoriesController,
              builder: (feedStoriesController) {
                return GetBuilder(
                    init: controller,
                    builder: (controller) {
                      return Column(
                        children: [
                          const FeedScreenTopBar(),
                          _FeedTypeToggle(controller: controller),
                          Expanded(
                            child: Stack(
                              children: [
                                if (controller.hasNetworkError &&
                                    controller.posts.isEmpty)
                                  NetworkErrorView(
                                      onRetry: () => controller.fetchFeeds())
                                else if (controller.isLoading.value &&
                                    controller.posts.isEmpty)
                                  const SingleChildScrollView(
                                      child: FeedShimmerPlaceholder())
                                else
                                  RefreshIndicator(
                                    key: refreshIndicatorKey,
                                    triggerMode:
                                        RefreshIndicatorTriggerMode.anywhere,
                                    color: refreshIndicatorColor,
                                    backgroundColor: refreshIndicatorBgColor,
                                    child: CustomScrollView(
                                      controller: controller.scrollController,
                                      slivers: [
                                        SliverToBoxAdapter(
                                            child: FeedStoryScreen(
                                                controller:
                                                    feedStoriesController)),
                                        SliverToBoxAdapter(
                                            child: Container(
                                                color: cLightBg, height: 5)),
                                        if (controller
                                            .suggestedRooms.isNotEmpty)
                                          SliverToBoxAdapter(
                                            child: _SuggestedRoomsSection(
                                              rooms: controller.suggestedRooms,
                                            ),
                                          ),
                                        if (controller.posts.isEmpty &&
                                            controller.suggestedRooms.isEmpty &&
                                            !controller.isLoading.value)
                                          SliverFillRemaining(
                                            hasScrollBody: false,
                                            child: NoDataView(
                                                title: LKeys.noPosts.tr),
                                          )
                                        else
                                          SliverList(
                                            delegate:
                                                SliverChildBuilderDelegate(
                                              (context, index) {
                                                return Container(
                                                  color: cWhite,
                                                  child: Column(
                                                    children: [
                                                      if (index == 0)
                                                        const SizedBox(
                                                            height: 5),
                                                      RepaintBoundary(
                                                        child: PostCard(
                                                          post: controller
                                                              .posts[index],
                                                          onDeletePost:
                                                              (postID) {
                                                            controller.posts
                                                                .removeWhere(
                                                                    (element) =>
                                                                        element
                                                                            .id ==
                                                                        postID);
                                                            controller.update();
                                                          },
                                                          refreshView: () {
                                                            controller.update();
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              childCount:
                                                  controller.posts.length,
                                            ),
                                          ),
                                      ],
                                    ),
                                    onRefresh: () async {
                                      await controller.fetchFeeds(
                                          isForRefresh: true);
                                      await feedStoriesController
                                          .fetchStories();
                                      return await feedStoriesController
                                          .fetchMyStories();
                                    },
                                  ),
                                FloatingBtnForCreating(
                                  onPostBack: (feed) {
                                    Future.delayed(Duration(milliseconds: 100),
                                        () {
                                      controller.posts.insert(0, feed);
                                      controller.update();
                                    });
                                  },
                                  onStoryBack: () {
                                    feedStoriesController.fetchMyStories();
                                  },
                                )
                              ],
                            ),
                          ),
                        ],
                      );
                    });
              }),
        ],
      ),
    );
  }
}

class _SuggestedRoomsSection extends StatelessWidget {
  final List<Room> rooms;

  const _SuggestedRoomsSection({required this.rooms});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cBlack,
      padding: const EdgeInsets.only(top: 20, right: 10, left: 10, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                LKeys.suggested.tr,
                style: MyTextStyle.gilroyLight(color: cWhite, size: 17),
              ),
              const SizedBox(width: 5),
              Text(
                LKeys.rooms.tr,
                style: MyTextStyle.gilroyBold(color: cWhite, size: 17),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: rooms.length,
              separatorBuilder: (_, __) => SizedBox(width: Get.width / 50),
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: Get.width / 80),
                  child: RoomCard(
                    room: rooms[index],
                    isFromHome: true,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class FeedsView extends StatelessWidget {
  const FeedsView({
    super.key,
    required this.controller,
    required this.id,
  });

  final FeedScreenController controller;
  final String id;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: controller,
      tag: id,
      builder: (controller) {
        final hasSuggestedRooms = controller.suggestedRooms.isNotEmpty;
        return NoDataView(
          showShow: controller.posts.isEmpty &&
              !hasSuggestedRooms &&
              !controller.isLoading.value,
          title: LKeys.noPosts.tr,
          child: SafeArea(
            top: false,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 5),
              itemCount: controller.posts.length + (hasSuggestedRooms ? 1 : 0),
              itemBuilder: (context, index) {
                if (hasSuggestedRooms && index == 0) {
                  return _SuggestedRoomsSection(
                    rooms: controller.suggestedRooms,
                  );
                }

                final postIndex = hasSuggestedRooms ? index - 1 : index;
                return RepaintBoundary(
                  child: Column(
                    children: [
                      PostCard(
                        post: controller.posts[postIndex],
                        onDeletePost: (postID) {
                          controller.posts
                              .removeWhere((element) => element.id == postID);
                          controller.update();
                        },
                        refreshView: () {
                          controller.update();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _FeedTypeToggle extends StatelessWidget {
  final FeedScreenController controller;
  const _FeedTypeToggle({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cBG,
      child: Obx(() => Column(
            children: [
              Row(
                children: [
                  _tab(LKeys.forYou.tr, 0),
                  _tab(LKeys.following.tr, 2),
                ],
              ),
              Container(height: 0.5, color: cLightText.withValues(alpha: 0.12)),
            ],
          )),
    );
  }

  Widget _tab(String label, int type) {
    final selected = controller.selectedFeedType.value == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.switchFeedType(type),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: MyTextStyle.gilroySemiBold(
                  color: selected ? cMainText : cLightText,
                  size: 14,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2.5,
              width: 40,
              decoration: BoxDecoration(
                color: selected ? cPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
