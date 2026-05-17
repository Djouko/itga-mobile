import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/job_models.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/job_board/job_detail_screen.dart';
import 'package:untitled/screens/job_board/job_list_controller.dart';
import 'package:untitled/screens/job_board/saved_jobs_screen.dart';
import 'package:untitled/screens/job_board/my_applications_screen.dart';
import 'package:untitled/screens/company/company_auth_screen.dart';
import 'package:untitled/utilities/const.dart';

class JobListScreen extends StatelessWidget {
  const JobListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(JobListController());
    return Scaffold(
      backgroundColor: cBG,
      body: Column(
        children: [
          TopBarForInView(
            title: LKeys.jobBoard,
            child: Row(
              children: [
                _iconBtn(Icons.bookmark_outline, () => Get.to(() => const SavedJobsScreen())),
                const SizedBox(width: 8),
                _iconBtn(Icons.description_outlined, () => Get.to(() => const MyApplicationsScreen())),
                const SizedBox(width: 8),
                _iconBtn(Icons.business_outlined, () => Get.to(() => const CompanyAuthScreen())),
              ],
            ),
          ),
          _searchBar(controller),
          _filterRow(controller),
          Expanded(
            child: GetBuilder<JobListController>(
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
                          Icon(Icons.wifi_off_rounded, size: 48, color: cLightText.withValues(alpha: 0.5)),
                          const SizedBox(height: 10),
                          Text('Connexion indisponible', style: MyTextStyle.gilroySemiBold(size: 16, color: cMainText)),
                          const SizedBox(height: 6),
                          Text('Vérifiez votre réseau puis réessayez.', style: MyTextStyle.gilroyRegular(size: 13, color: cLightText), textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => ctrl.fetchJobs(refresh: true),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (ctrl.jobs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.work_off_outlined, size: 48, color: cLightText.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(LKeys.noJobOffers.tr, style: MyTextStyle.gilroySemiBold(size: 16, color: cMainText)),
                          const SizedBox(height: 6),
                          Text(LKeys.noJobOffersDesc.tr, style: MyTextStyle.gilroyRegular(size: 13, color: cLightText), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  color: cPrimary,
                  onRefresh: () => ctrl.fetchJobs(refresh: true),
                  child: ListView.builder(
                    controller: ctrl.scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: ctrl.jobs.length + (ctrl.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= ctrl.jobs.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator(color: cPrimary, strokeWidth: 2)),
                        );
                      }
                      return _JobCard(
                        job: ctrl.jobs[index],
                        onTap: () => Get.to(() => JobDetailScreen(jobId: ctrl.jobs[index].id!)),
                        onSave: () => ctrl.toggleSave(index),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: cWhite.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: cWhite, size: 20),
      ),
    );
  }

  Widget _searchBar(JobListController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.onSearch,
        style: MyTextStyle.gilroyRegular(size: 14, color: cMainText),
        decoration: InputDecoration(
          hintText: LKeys.searchJobs.tr,
          hintStyle: MyTextStyle.gilroyRegular(size: 14, color: cLightText),
          prefixIcon: const Icon(Icons.search, color: cLightText, size: 20),
          filled: true,
          fillColor: cWhite,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _filterRow(JobListController controller) {
    return GetBuilder<JobListController>(
      builder: (ctrl) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _filterChip(ctrl.sortBy == 'date' ? LKeys.sortRecent.tr : LKeys.sortRelevance.tr, () {
                ctrl.setSortBy(ctrl.sortBy == 'date' ? 'relevance' : 'date');
              }, isActive: true),
              const SizedBox(width: 8),
              _filterChip(ctrl.selectedContractType ?? LKeys.allContracts.tr, () {
                _showContractPicker(ctrl);
              }, isActive: ctrl.selectedContractType != null),
              const SizedBox(width: 8),
              _filterChip(ctrl.selectedLocationType ?? LKeys.allLocations.tr, () {
                _showLocationPicker(ctrl);
              }, isActive: ctrl.selectedLocationType != null),
              const SizedBox(width: 8),
              _filterChip(ctrl.selectedExperienceLevel ?? LKeys.allLevels.tr, () {
                _showLevelPicker(ctrl);
              }, isActive: ctrl.selectedExperienceLevel != null),
              const SizedBox(width: 8),
              _filterChip(_domainLabel(ctrl.selectedDomain), () {
                _showDomainPicker(ctrl);
              }, isActive: ctrl.selectedDomain != null),
            ],
          ),
        );
      },
    );
  }

  String _domainLabel(String? domain) {
    const labels = {
      'data': 'Data',
      'dev': 'Dev',
      'engineering': 'Ingénierie',
      'design': 'Design',
      'marketing': 'Marketing',
      'other': 'Autre',
    };
    return domain != null ? (labels[domain] ?? domain) : 'Domaine';
  }

  Widget _filterChip(String label, VoidCallback onTap, {bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? cPrimary.withValues(alpha: 0.1) : cWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? cPrimary : cLightText.withValues(alpha: 0.2)),
        ),
        child: Text(label, style: MyTextStyle.gilroySemiBold(size: 12, color: isActive ? cPrimary : cMainText)),
      ),
    );
  }

  void _showContractPicker(JobListController ctrl) {
    final options = [null, 'stage', 'alternance', 'cdi', 'cdd', 'freelance'];
    final labels = [LKeys.allContracts, LKeys.stage, LKeys.alternance, LKeys.cdi, LKeys.cdd, LKeys.freelance];
    Get.bottomSheet(
      _PickerSheet(options: options, labels: labels, selected: ctrl.selectedContractType, onSelect: ctrl.setContractFilter),
      backgroundColor: cWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    );
  }

  void _showLevelPicker(JobListController ctrl) {
    final options = [null, 'junior', 'mid', 'senior'];
    final labels = [LKeys.allLevels, LKeys.junior, LKeys.mid, LKeys.senior];
    Get.bottomSheet(
      _PickerSheet(options: options, labels: labels, selected: ctrl.selectedExperienceLevel, onSelect: ctrl.setExperienceFilter),
      backgroundColor: cWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    );
  }

  void _showLocationPicker(JobListController ctrl) {
    final options = [null, 'remote', 'hybrid', 'onsite'];
    final labels = [LKeys.allLocations, LKeys.remote, LKeys.hybrid, LKeys.onsite];
    Get.bottomSheet(
      _PickerSheet(options: options, labels: labels, selected: ctrl.selectedLocationType, onSelect: ctrl.setLocationFilter),
      backgroundColor: cWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    );
  }

  void _showDomainPicker(JobListController ctrl) {
    final options = [null, 'data', 'dev', 'engineering', 'design', 'marketing', 'other'];
    final labels = ['Tous les domaines', 'Data', 'Dev', 'Ingénierie', 'Design', 'Marketing', 'Autre'];
    Get.bottomSheet(
      _PickerSheet(options: options, labels: labels, selected: ctrl.selectedDomain, onSelect: ctrl.setDomainFilter),
      backgroundColor: cWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final List<String?> options;
  final List<String> labels;
  final String? selected;
  final Function(String?) onSelect;

  const _PickerSheet({required this.options, required this.labels, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(options.length, (i) {
            final isSelected = options[i] == selected;
            return ListTile(
              title: Text(labels[i].tr, style: MyTextStyle.gilroySemiBold(size: 15, color: isSelected ? cPrimary : cMainText)),
              trailing: isSelected ? const Icon(Icons.check_rounded, color: cPrimary, size: 20) : null,
              onTap: () {
                onSelect(options[i]);
                Get.back();
              },
            );
          }),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobOffer job;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const _JobCard({required this.job, required this.onTap, required this.onSave});

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: job.company?.logo != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(job.company!.logo!, fit: BoxFit.cover))
                      : const Icon(Icons.business, color: cPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title ?? '', style: MyTextStyle.gilroyBold(size: 15, color: cMainText), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(job.company?.name ?? '', style: MyTextStyle.gilroyRegular(size: 13, color: cLightText)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onSave,
                  child: Icon(
                    job.isSaved == 1 ? Icons.bookmark : Icons.bookmark_border,
                    color: job.isSaved == 1 ? cPrimary : cLightText,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (job.contractType != null) _tag(job.contractType!.tr),
                if (job.locationType != null) _tag(job.locationType!.tr),
                if (job.locationCity != null) _tag(job.locationCity!),
                if (job.experienceLevel != null) _tag(job.experienceLevel!.tr),
              ],
            ),
            if (job.salaryMin != null || job.salaryMax != null) ...[
              const SizedBox(height: 8),
              Text(
                '${job.salaryMin ?? '?'} - ${job.salaryMax ?? '?'} €${job.salaryPeriod != null ? ' / ${job.salaryPeriod}' : ''}',
                style: MyTextStyle.gilroySemiBold(size: 13, color: cPrimary),
              ),
            ],
            if (job.isMatch == 1) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: cMagenta),
                  const SizedBox(width: 4),
                  Text(LKeys.matchSkills.tr, style: MyTextStyle.gilroySemiBold(size: 11, color: cMagenta)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: MyTextStyle.gilroySemiBold(size: 11, color: cNavy)),
    );
  }
}
