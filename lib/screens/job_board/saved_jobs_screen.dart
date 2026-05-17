import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/job_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/widgets/no_data_view.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/job_models.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/job_board/job_detail_screen.dart';
import 'package:untitled/screens/job_board/job_theme.dart';
import 'package:untitled/utilities/const.dart';

class SavedJobsController extends BaseController {
  final ScrollController scrollController = ScrollController();
  List<JobOffer> jobs = [];
  bool hasMore = true;

  @override
  void onInit() {
    super.onInit();
    fetchSavedJobs();
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
        loadMore();
      }
    });
  }

  Future<void> fetchSavedJobs({bool refresh = false}) async {
    if (refresh) {
      jobs.clear();
      hasMore = true;
    }
    if (!hasMore && !refresh) return;
    isLoading.value = jobs.isEmpty;
    update();
    try {
      final newJobs = await JobService.shared.fetchSavedJobs(start: refresh ? 0 : jobs.length);
      if (newJobs.isEmpty) {
        hasMore = false;
      } else {
        jobs.addAll(newJobs);
      }
    } catch (_) {
      hasNetworkError = true;
    }
    isLoading.value = false;
    update();
  }

  void loadMore() {
    if (!isLoading.value && hasMore) fetchSavedJobs();
  }

  void unsave(int index) async {
    final job = jobs[index];
    if (job.id == null) return;
    final success = await JobService.shared.toggleSaveJob(jobId: job.id!);
    if (success) {
      jobs.removeAt(index);
      update();
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}

class SavedJobsScreen extends StatelessWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SavedJobsController());
    return Scaffold(
      backgroundColor: jobSurface(context),
      body: Column(
        children: [
          TopBarForInView(title: LKeys.savedJobs),
          Expanded(
            child: GetBuilder<SavedJobsController>(
              builder: (ctrl) {
                if (ctrl.isLoading.value && ctrl.jobs.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: cPrimary));
                }
                if (ctrl.hasNetworkError && ctrl.jobs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off_rounded, size: 44, color: cLightText.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text('Impossible de charger vos offres sauvegardées', style: MyTextStyle.gilroySemiBold(size: 14, color: jobMainText(context)), textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => ctrl.fetchSavedJobs(refresh: true),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return NoDataView(
                  showShow: ctrl.jobs.isEmpty,
                  title: LKeys.noSavedJobs,
                  description: LKeys.noSavedJobsDesc,
                  icon: Icons.bookmark_border,
                  child: RefreshIndicator(
                    color: cPrimary,
                    onRefresh: () => ctrl.fetchSavedJobs(refresh: true),
                    child: ListView.builder(
                      controller: ctrl.scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: ctrl.jobs.length,
                      itemBuilder: (context, index) {
                        final job = ctrl.jobs[index];
                        return _SavedJobCard(
                          job: job,
                          onTap: () => Get.to(() => JobDetailScreen(jobId: job.id!)),
                          onUnsave: () => ctrl.unsave(index),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedJobCard extends StatelessWidget {
  final JobOffer job;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  const _SavedJobCard({required this.job, required this.onTap, required this.onUnsave});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: jobCard(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: jobBorder(context)),
          boxShadow: jobCardShadow(context),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: cPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: job.company?.logo != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(job.company!.logo!, fit: BoxFit.cover))
                  : const Icon(Icons.business, color: cPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title ?? '', style: MyTextStyle.gilroyBold(size: 14, color: jobMainText(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(job.company?.name ?? '', style: MyTextStyle.gilroyRegular(size: 12, color: jobMutedText(context))),
                  if (job.contractType != null) ...[
                    const SizedBox(height: 4),
                    Text(job.contractType!.tr, style: MyTextStyle.gilroySemiBold(size: 11, color: cPrimary)),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: onUnsave,
              child: const Icon(Icons.bookmark, color: cPrimary, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
