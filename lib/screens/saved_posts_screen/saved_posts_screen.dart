import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/widgets/no_data_view.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/feed_screen/feed_screen.dart';
import 'package:untitled/screens/saved_posts_screen/saved_posts_screen_controller.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SavedPostsScreenController controller = Get.put(SavedPostsScreenController());
    return Scaffold(
      body: Column(
        children: [
          TopBarForInView(title: LKeys.savedPosts),
          Expanded(
            child: GetBuilder(
              init: controller,
              tag: 'saved_posts',
              builder: (ctx) {
                return NoDataView(
                  showShow: controller.posts.isEmpty && !controller.isLoading.value,
                  title: LKeys.savedItems,
                  description: LKeys.noSavedPostsYet,
                  child: FeedsView(controller: controller, id: 'saved_posts'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
