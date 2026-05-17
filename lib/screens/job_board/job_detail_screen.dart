import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/common/api_service/job_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/job_models.dart';
import 'package:untitled/screens/company/company_public_profile_screen.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/job_board/job_theme.dart';
import 'package:untitled/utilities/const.dart';

class JobDetailScreen extends StatefulWidget {
  final int jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  JobOffer? job;
  bool isLoading = true;
  bool isApplying = false;
  final coverLetterCtrl = TextEditingController();
  XFile? selectedCvFile;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  Future<void> _loadJob() async {
    try {
      final result = await JobService.shared.fetchJobDetail(jobId: widget.jobId);
      setState(() {
        job = result;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  void _openCompanyProfile() {
    final companyId = job?.company?.id;
    if (companyId == null) return;
    Get.to(() => CompanyPublicProfileScreen(companyId: companyId));
  }

  void _showApplySheet() {
    Get.bottomSheet(
      _ApplySheet(
        coverLetterCtrl: coverLetterCtrl,
        selectedFile: selectedCvFile,
        onPickFile: _pickCv,
        onSubmit: _submitApplication,
        isApplying: isApplying,
      ),
      isScrollControlled: true,
      backgroundColor: jobCard(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    );
  }

  Future<void> _pickCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => selectedCvFile = XFile(result.files.single.path!));
      Get.back();
      _showApplySheet();
    }
  }

  Future<void> _submitApplication() async {
    if (job?.id == null) return;
    setState(() => isApplying = true);
    try {
      final success = await JobService.shared.applyToJob(
        jobId: job!.id!,
        coverLetter: coverLetterCtrl.text.isNotEmpty ? coverLetterCtrl.text : null,
        cvFile: selectedCvFile,
      );
      setState(() => isApplying = false);
      Get.back();
      if (success) {
        setState(() => job!.isApplied = 1);
        BaseController.share.showSnackBar(LKeys.applicationSent.tr, type: SnackBarType.success);
      }
    } catch (_) {
      setState(() => isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: jobSurface(context),
      body: Column(
        children: [
          TopBarForInView(title: LKeys.jobBoard),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: cPrimary))
                : job == null
                    ? Center(child: Text(LKeys.jobNotFound.tr, style: MyTextStyle.gilroySemiBold(size: 16, color: jobMainText(context))))
                    : _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: (!isLoading && job != null && job!.isApplied != 1)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _showApplySheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cPrimary,
                    foregroundColor: cWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(LKeys.applyNow.tr, style: MyTextStyle.gilroyBold(size: 15, color: cWhite)),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: jobCard(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: jobBorder(context)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _openCompanyProfile(),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: cPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                    child: job!.company?.logo != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(job!.company!.logo!, fit: BoxFit.cover))
                        : const Icon(Icons.business, color: cPrimary, size: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job!.title ?? '', style: MyTextStyle.gilroyBold(size: 18, color: jobMainText(context))),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _openCompanyProfile(),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(job!.company?.name ?? '', style: MyTextStyle.gilroySemiBold(size: 14, color: cPrimary), overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.open_in_new, size: 12, color: cPrimary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (job?.id == null) return;
                    final success = await JobService.shared.toggleSaveJob(jobId: job!.id!);
                    if (success) setState(() => job!.isSaved = (job!.isSaved == 1) ? 0 : 1);
                  },
                  child: Icon(job!.isSaved == 1 ? Icons.bookmark : Icons.bookmark_border, color: job!.isSaved == 1 ? cPrimary : cLightText, size: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (job!.contractType != null) _tag(job!.contractType!.tr),
              if (job!.locationType != null) _tag(job!.locationType!.tr),
              if (job!.locationCity != null) _tag(job!.locationCity!),
              if (job!.experienceLevel != null) _tag(job!.experienceLevel!.tr),
            ],
          ),
          if (job!.salaryMin != null || job!.salaryMax != null) ...[
            const SizedBox(height: 12),
            Text(
              '${job!.salaryMin ?? '?'} - ${job!.salaryMax ?? '?'} €${job!.salaryPeriod != null ? ' / ${job!.salaryPeriod}' : ''}',
              style: MyTextStyle.gilroyBold(size: 16, color: cPrimary),
            ),
          ],
          if (job!.isMatch == 1) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: cMagenta.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 16, color: cMagenta),
                  const SizedBox(width: 6),
                  Text(LKeys.matchSkills.tr, style: MyTextStyle.gilroySemiBold(size: 12, color: cMagenta)),
                ],
              ),
            ),
          ],
          if (job!.isApplied == 1) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: cGreen.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 16, color: cGreen),
                  const SizedBox(width: 6),
                  Text(job!.applicationStatus?.tr ?? LKeys.received.tr, style: MyTextStyle.gilroySemiBold(size: 12, color: cGreen)),
                ],
              ),
            ),
          ],
          // Description
          _section(LKeys.jobDescription, job!.description),
          // Missions
          if (job!.missions != null && job!.missions!.isNotEmpty) _section(LKeys.jobMissions, job!.missions),
          // Skills
          if (job!.requiredSkills != null && job!.requiredSkills!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(LKeys.jobRequiredSkills.tr, style: MyTextStyle.gilroyBold(size: 16, color: jobMainText(context))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: job!.requiredSkills!.map((s) => _tag(s)).toList(),
            ),
          ],
          // About Company
          if (job!.company?.description != null) _section(LKeys.aboutCompany, job!.company!.description),
          if (job!.company?.rseCommitments != null) _section(LKeys.rseCommitments, job!.company!.rseCommitments),
          // Deadline
          if (job!.deadline != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.event, size: 18, color: cOrange),
                const SizedBox(width: 6),
                Text('${LKeys.jobDeadline.tr}: ${job!.deadline}', style: MyTextStyle.gilroySemiBold(size: 13, color: cOrange)),
              ],
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _section(String titleKey, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(titleKey.tr, style: MyTextStyle.gilroyBold(size: 16, color: jobMainText(context))),
        const SizedBox(height: 8),
        Text(content, style: MyTextStyle.gilroyRegular(size: 14, color: jobBodyText(context))),
      ],
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: cPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: MyTextStyle.gilroySemiBold(size: 12, color: jobIsDark(context) ? cCyan : cNavy)),
    );
  }

  @override
  void dispose() {
    coverLetterCtrl.dispose();
    super.dispose();
  }
}

class _ApplySheet extends StatelessWidget {
  final TextEditingController coverLetterCtrl;
  final XFile? selectedFile;
  final VoidCallback onPickFile;
  final VoidCallback onSubmit;
  final bool isApplying;

  const _ApplySheet({
    required this.coverLetterCtrl,
    required this.selectedFile,
    required this.onPickFile,
    required this.onSubmit,
    required this.isApplying,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LKeys.applyToJob.tr, style: MyTextStyle.gilroyBold(size: 18, color: jobMainText(context))),
          const SizedBox(height: 16),
          Text(LKeys.coverLetterLabel.tr, style: MyTextStyle.gilroySemiBold(size: 14, color: jobMainText(context))),
          const SizedBox(height: 6),
          TextField(
            controller: coverLetterCtrl,
            maxLines: 4,
            style: MyTextStyle.gilroyRegular(size: 14, color: jobMainText(context)),
            decoration: InputDecoration(
              hintText: LKeys.coverLetterHint.tr,
              hintStyle: MyTextStyle.gilroyRegular(size: 14, color: cLightText),
              filled: true,
              fillColor: jobMutedSurface(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),
          Text(LKeys.cvUploadLabel.tr, style: MyTextStyle.gilroySemiBold(size: 14, color: jobMainText(context))),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onPickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(color: jobMutedSurface(context), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.attach_file, color: cPrimary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedFile != null ? selectedFile!.name : LKeys.cvUploadLabel.tr,
                      style: MyTextStyle.gilroyRegular(size: 14, color: selectedFile != null ? jobMainText(context) : jobMutedText(context)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isApplying ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: cPrimary,
                foregroundColor: cWhite,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: isApplying
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: cWhite, strokeWidth: 2))
                  : Text(LKeys.submitApplication.tr, style: MyTextStyle.gilroyBold(size: 15, color: cWhite)),
            ),
          ),
        ],
      ),
    );
  }
}
