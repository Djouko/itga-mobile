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
import 'package:untitled/utilities/const.dart';

class MyApplicationsController extends BaseController {
  final ScrollController scrollController = ScrollController();
  List<JobApplication> applications = [];
  bool hasMore = true;

  @override
  void onInit() {
    super.onInit();
    fetchApplications();
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
        loadMore();
      }
    });
  }

  Future<void> fetchApplications({bool refresh = false}) async {
    if (refresh) {
      applications.clear();
      hasMore = true;
    }
    if (!hasMore && !refresh) return;
    isLoading.value = applications.isEmpty;
    update();
    try {
      final newApps = await JobService.shared.fetchMyApplications(start: refresh ? 0 : applications.length);
      if (newApps.isEmpty) {
        hasMore = false;
      } else {
        applications.addAll(newApps);
      }
    } catch (_) {
      hasNetworkError = true;
    }
    isLoading.value = false;
    update();
  }

  void loadMore() {
    if (!isLoading.value && hasMore) fetchApplications();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(MyApplicationsController());
    return Scaffold(
      backgroundColor: cBG,
      body: Column(
        children: [
          TopBarForInView(title: LKeys.myApplications),
          Expanded(
            child: GetBuilder<MyApplicationsController>(
              builder: (ctrl) {
                if (ctrl.isLoading.value && ctrl.applications.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: cPrimary));
                }
                if (ctrl.hasNetworkError && ctrl.applications.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off_rounded, size: 44, color: cLightText.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text('Impossible de charger vos candidatures', style: MyTextStyle.gilroySemiBold(size: 14, color: cMainText), textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => ctrl.fetchApplications(refresh: true),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return NoDataView(
                  showShow: ctrl.applications.isEmpty,
                  title: LKeys.noApplications,
                  description: LKeys.noApplicationsDesc,
                  icon: Icons.description_outlined,
                  child: RefreshIndicator(
                    color: cPrimary,
                    onRefresh: () => ctrl.fetchApplications(refresh: true),
                    child: ListView.builder(
                      controller: ctrl.scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: ctrl.applications.length,
                      itemBuilder: (context, index) {
                        final app = ctrl.applications[index];
                        return _ApplicationCard(
                          application: app,
                          onTap: () {
                            if (app.jobOfferId != null) Get.to(() => JobDetailScreen(jobId: app.jobOfferId!));
                          },
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

class _ApplicationCard extends StatelessWidget {
  final JobApplication application;
  final VoidCallback onTap;

  const _ApplicationCard({required this.application, required this.onTap});

  Color _statusColor(String? status) {
    switch (status) {
      case 'accepted':
        return cGreen;
      case 'rejected':
        return cRed;
      case 'interview':
        return cOrange;
      case 'in_review':
        return cCyan;
      default:
        return cLightText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(application.status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: cBlack.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: cPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: application.jobOffer?.company?.logo != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(application.jobOffer!.company!.logo!, fit: BoxFit.cover))
                  : const Icon(Icons.business, color: cPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(application.jobOffer?.title ?? '', style: MyTextStyle.gilroyBold(size: 14, color: cMainText), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(application.jobOffer?.company?.name ?? '', style: MyTextStyle.gilroyRegular(size: 12, color: cLightText)),
                  if (application.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(application.createdAt!.split('T').first, style: MyTextStyle.gilroyRegular(size: 11, color: cLightText)),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      (application.status ?? LKeys.received).tr,
                      style: MyTextStyle.gilroySemiBold(size: 11, color: statusColor),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: cLightText, size: 20),
          ],
        ),
      ),
    );
  }
}
