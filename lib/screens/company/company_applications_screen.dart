import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/job_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/job_models.dart';
import 'package:untitled/utilities/const.dart';

const _kDark = Color(0xFF030A14);
const _kCard = Color(0xFF0D1525);
const _kBorder = Color(0x14FFFFFF);
const _kAccent = Color(0xFF00C4D4);

class CompanyApplicationsController extends BaseController {
  final int jobId;
  final int companyId;
  final ScrollController scrollController = ScrollController();
  List<JobApplication> applications = [];
  bool hasMore = true;
  String statusFilter = 'all';

  CompanyApplicationsController({required this.jobId, required this.companyId});

  List<JobApplication> get visibleApplications {
    if (statusFilter == 'all') {
      return applications;
    }
    return applications.where((application) => application.status == statusFilter).toList();
  }

  Map<String, int> get statusCounts {
    final counts = <String, int>{
      'all': applications.length,
      'received': 0,
      'in_review': 0,
      'interview': 0,
      'accepted': 0,
      'rejected': 0,
    };

    for (final application in applications) {
      final status = application.status;
      if (status != null && counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }

    return counts;
  }

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
      final newApps = await JobService.shared.fetchJobApplications(
        jobId: jobId,
        companyId: companyId,
        start: refresh ? 0 : applications.length,
      );
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

  void setStatusFilter(String nextFilter) {
    statusFilter = nextFilter;
    update();
  }

  Future<void> updateStatus(int applicationId, String newStatus) async {
    final index = applications.indexWhere((application) => application.id == applicationId);
    if (index < 0) {
      return;
    }

    final app = applications[index];
    if (app.id == null) return;
    final success = await JobService.shared.updateApplicationStatus(
      applicationId: app.id!,
      companyId: companyId,
      status: newStatus,
    );
    if (success) {
      applications[index].status = newStatus;
      update();
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}

class CompanyApplicationsScreen extends StatelessWidget {
  final int jobId;
  final int companyId;

  const CompanyApplicationsScreen({super.key, required this.jobId, required this.companyId});

  @override
  Widget build(BuildContext context) {
    Get.put(CompanyApplicationsController(jobId: jobId, companyId: companyId));
    return Scaffold(
      backgroundColor: _kDark,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: GetBuilder<CompanyApplicationsController>(
                builder: (ctrl) {
                  if (ctrl.isLoading.value && ctrl.applications.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2));
                  }

                  if (ctrl.applications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_outlined, color: Colors.white12, size: 48),
                          const SizedBox(height: 14),
                          Text(LKeys.noApplicationsYet.tr, style: MyTextStyle.gilroyRegular(size: 14, color: Colors.white24)),
                        ],
                      ),
                    );
                  }

                  final visible = ctrl.visibleApplications;
                  return RefreshIndicator(
                    color: _kAccent,
                    backgroundColor: _kCard,
                    onRefresh: () => ctrl.fetchApplications(refresh: true),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: visible.length + (ctrl.hasMore ? 1 : 0) + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _statusFilters(ctrl);
                        }

                        final adjustedIndex = index - 1;
                        if (adjustedIndex >= visible.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2)),
                          );
                        }

                        final application = visible[adjustedIndex];
                        return _ApplicationTile(
                          application: application,
                          onStatusChange: (status) {
                            if (application.id != null) {
                              ctrl.updateStatus(application.id!, status);
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusFilters(CompanyApplicationsController ctrl) {
    final labels = <String, String>{
      'all': 'Toutes',
      'received': 'Recues',
      'in_review': 'En examen',
      'interview': 'Entretien',
      'accepted': 'Acceptees',
      'rejected': 'Refusees',
    };

    final counts = ctrl.statusCounts;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: labels.entries.map((entry) {
            final key = entry.key;
            final isSelected = ctrl.statusFilter == key;
            final count = counts[key] ?? 0;
            return GestureDetector(
              onTap: () => ctrl.setStatusFilter(key),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? _kAccent.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _kAccent.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  '${entry.value} ($count)',
                  style: MyTextStyle.gilroySemiBold(
                    size: 11,
                    color: isSelected ? _kAccent : Colors.white54,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: _kCard,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBorder)),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white60, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(LKeys.companyApplications.tr, style: MyTextStyle.gilroyBold(size: 17, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  final JobApplication application;
  final Function(String) onStatusChange;

  const _ApplicationTile({required this.application, required this.onStatusChange});

  static const _statusCfg = {
    'received':  {'label': 'Reçue',     'color': Color(0xFF60A5FA)},
    'in_review': {'label': 'En examen', 'color': Color(0xFFFBBF24)},
    'interview': {'label': 'Entretien', 'color': Color(0xFFA78BFA)},
    'accepted':  {'label': 'Acceptée',  'color': Color(0xFF10B981)},
    'rejected':  {'label': 'Refusée',   'color': Color(0xFFF43F5E)},
  };

  Color get _currentColor => (_statusCfg[application.status]?['color'] as Color?) ?? Colors.white38;
  String get _currentLabel => (_statusCfg[application.status]?['label'] as String?) ?? (application.status ?? '');

  @override
  Widget build(BuildContext context) {
    final name = application.user?.fullName?.isNotEmpty == true
        ? application.user!.fullName!
        : (application.user?.username ?? 'Candidat');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _kAccent.withValues(alpha: 0.12),
                  backgroundImage: application.user?.profile != null
                      ? NetworkImage(application.user!.profile!.addBaseURL())
                      : null,
                  child: application.user?.profile == null
                      ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: MyTextStyle.gilroyBold(size: 16, color: _kAccent))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: MyTextStyle.gilroySemiBold(size: 14, color: Colors.white)),
                      if (application.user?.username != null) ...[
                        const SizedBox(height: 2),
                        Text('@${application.user!.username}', style: MyTextStyle.gilroyRegular(size: 11, color: Colors.white38)),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _currentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _currentColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(_currentLabel, style: MyTextStyle.gilroySemiBold(size: 11, color: _currentColor)),
                ),
              ],
            ),
          ),
          if (application.coverLetter != null && application.coverLetter!.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: Text(
                application.coverLetter!,
                style: MyTextStyle.gilroyRegular(size: 12, color: Colors.white54),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (application.cvFile != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _kAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kAccent.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.attach_file, size: 13, color: _kAccent),
                        const SizedBox(width: 4),
                        Text('CV joint', style: MyTextStyle.gilroySemiBold(size: 11, color: _kAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _kBorder)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusCfg.entries.map((entry) {
                  final isActive = application.status == entry.key;
                  final color = entry.value['color'] as Color;
                  final label = entry.value['label'] as String;
                  return GestureDetector(
                    onTap: isActive ? null : () => onStatusChange(entry.key),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isActive ? color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text(label, style: MyTextStyle.gilroySemiBold(size: 11, color: isActive ? color : Colors.white38)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
