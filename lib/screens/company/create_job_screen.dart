import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/job_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/job_models.dart';

const _kDark = Color(0xFF030A14);
const _kCard = Color(0xFF0D1525);
const _kBorder = Color(0x14FFFFFF);
const _kAccent = Color(0xFF00C4D4);
const _kPurple = Color(0xFF7B2FFF);

class CreateJobController extends BaseController {
  final int companyId;
  final JobOffer? editJob;

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final missionsCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final domainCtrl = TextEditingController();
  final salaryMinCtrl = TextEditingController();
  final salaryMaxCtrl = TextEditingController();
  final deadlineCtrl = TextEditingController();
  final skillCtrl = TextEditingController();

  String contractType = 'cdi';
  String locationType = 'onsite';
  String experienceLevel = 'junior';
  String status = 'published';
  List<String> skills = [];
  bool isSubmitting = false;

  bool get isEdit => editJob != null;

  CreateJobController({required this.companyId, this.editJob});

  @override
  void onInit() {
    super.onInit();
    if (editJob != null) {
      titleCtrl.text = editJob!.title ?? '';
      descCtrl.text = editJob!.description ?? '';
      missionsCtrl.text = editJob!.missions ?? '';
      cityCtrl.text = editJob!.locationCity ?? '';
      domainCtrl.text = editJob!.domain ?? '';
      salaryMinCtrl.text = editJob!.salaryMin?.toString() ?? '';
      salaryMaxCtrl.text = editJob!.salaryMax?.toString() ?? '';
      deadlineCtrl.text = editJob!.deadline ?? '';
      contractType = editJob!.contractType ?? 'cdi';
      locationType = editJob!.locationType ?? 'onsite';
      experienceLevel = editJob!.experienceLevel ?? 'junior';
      status = editJob!.status ?? 'published';
      skills = List<String>.from(editJob!.requiredSkills ?? []);
    }
  }

  void addSkill() {
    final value = skillCtrl.text.trim();
    if (value.isNotEmpty && !skills.contains(value)) {
      skills.add(value);
      skillCtrl.clear();
      update();
    }
  }

  void removeSkill(int index) {
    skills.removeAt(index);
    update();
  }

  void setContractType(String v) {
    contractType = v;
    update();
  }

  void setLocationType(String v) {
    locationType = v;
    update();
  }

  void setExperienceLevel(String v) {
    experienceLevel = v;
    update();
  }

  void setStatus(String v) {
    status = v;
    update();
  }

  String? _validateSubmission() {
    final title = titleCtrl.text.trim();
    final description = descCtrl.text.trim();

    if (title.isEmpty || description.isEmpty) {
      return 'Titre et description requis.';
    }

    if (title.length < 3) {
      return 'Le titre doit contenir au moins 3 caracteres.';
    }

    if (description.length < 20) {
      return 'La description doit contenir au moins 20 caracteres.';
    }

    if (locationType != 'remote' && cityCtrl.text.trim().isEmpty) {
      return 'La ville est requise pour un poste sur site ou hybride.';
    }

    final salaryMin = _parseSalaryValue(salaryMinCtrl.text);
    final salaryMax = _parseSalaryValue(salaryMaxCtrl.text);

    if (salaryMinCtrl.text.trim().isNotEmpty && salaryMin == null) {
      return 'Salaire minimum invalide.';
    }

    if (salaryMaxCtrl.text.trim().isNotEmpty && salaryMax == null) {
      return 'Salaire maximum invalide.';
    }

    if (salaryMin != null && salaryMax != null && salaryMax < salaryMin) {
      return 'Le salaire maximum doit etre superieur ou egal au minimum.';
    }

    if (deadlineCtrl.text.trim().isNotEmpty) {
      final deadline = DateTime.tryParse(deadlineCtrl.text.trim());
      if (deadline == null) {
        return 'Date limite invalide (format attendu YYYY-MM-DD).';
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (deadline.isBefore(today)) {
        return 'La date limite ne peut pas etre dans le passe.';
      }
    }

    if (status == 'published' && skills.isEmpty) {
      return 'Ajoutez au moins une competence avant de publier.';
    }

    return null;
  }

  double? _parseSalaryValue(String rawValue) {
    final normalized = rawValue.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }

    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed < 0) {
      return null;
    }

    return parsed;
  }

  Future<void> pickDeadline() async {
    final date = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      deadlineCtrl.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      update();
    }
  }

  Future<void> submit() async {
    final validationError = _validateSubmission();
    if (validationError != null) {
      showSnackBar(validationError, type: SnackBarType.error);
      return;
    }

    final salaryMin = _parseSalaryValue(salaryMinCtrl.text);
    final salaryMax = _parseSalaryValue(salaryMaxCtrl.text);

    isSubmitting = true;
    update();

    final data = <String, dynamic>{
      'title': titleCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'contract_type': contractType,
      'location_type': locationType,
      'experience_level': experienceLevel,
      'status': status,
    };
    if (missionsCtrl.text.isNotEmpty) data['missions'] = missionsCtrl.text.trim();
    if (cityCtrl.text.isNotEmpty) data['location_city'] = cityCtrl.text.trim();
    if (domainCtrl.text.isNotEmpty) data['domain'] = domainCtrl.text.trim();
    if (salaryMin != null) data['salary_min'] = salaryMin;
    if (salaryMax != null) data['salary_max'] = salaryMax;
    if (deadlineCtrl.text.isNotEmpty) data['deadline'] = deadlineCtrl.text.trim();
    if (skills.isNotEmpty) data['required_skills'] = skills;

    try {
      bool success;
      if (isEdit) {
        success = await JobService.shared.editJob(jobId: editJob!.id!, companyId: companyId, data: data);
      } else {
        success = await JobService.shared.createJob(companyId: companyId, data: data);
      }

      isSubmitting = false;
      update();

      if (success) {
        Get.back();
        showSnackBar(isEdit ? LKeys.saveChanges.tr : LKeys.createJobBtn.tr, type: SnackBarType.success);
      }
    } catch (_) {
      isSubmitting = false;
      update();
    }
  }

  @override
  void onClose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    missionsCtrl.dispose();
    cityCtrl.dispose();
    domainCtrl.dispose();
    salaryMinCtrl.dispose();
    salaryMaxCtrl.dispose();
    deadlineCtrl.dispose();
    skillCtrl.dispose();
    super.onClose();
  }
}

class CreateJobScreen extends StatelessWidget {
  final int companyId;
  final JobOffer? editJob;

  const CreateJobScreen({super.key, required this.companyId, this.editJob});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateJobController(companyId: companyId, editJob: editJob));
    return Scaffold(
      backgroundColor: _kDark,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(controller),
            Expanded(
              child: GetBuilder<CreateJobController>(
                builder: (ctrl) => SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section([
                        _field(ctrl.titleCtrl, LKeys.jobTitleHint.tr, Icons.title, label: LKeys.jobTitleLabel.tr),
                        const SizedBox(height: 14),
                        _label(LKeys.contractTypeLabel.tr),
                        _chips(ctrl, ['cdi', 'cdd', 'stage', 'alternance', 'freelance'],
                            [LKeys.cdi, LKeys.cdd, LKeys.stage, LKeys.alternance, LKeys.freelance], ctrl.contractType, ctrl.setContractType),
                        const SizedBox(height: 14),
                        _label(LKeys.locationTypeLabel.tr),
                        _chips(ctrl, ['onsite', 'remote', 'hybrid'], [LKeys.onsite, LKeys.remote, LKeys.hybrid], ctrl.locationType, ctrl.setLocationType),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: _field(ctrl.cityCtrl, LKeys.locationCityLabel.tr, Icons.location_on_outlined, label: LKeys.locationCityLabel.tr)),
                          const SizedBox(width: 10),
                          Expanded(child: _field(ctrl.domainCtrl, LKeys.domainLabel.tr, Icons.category_outlined, label: LKeys.domainLabel.tr)),
                        ]),
                      ]),
                      const SizedBox(height: 12),
                      _section([
                        _field(ctrl.descCtrl, LKeys.jobDescLabel.tr, Icons.description_outlined, label: LKeys.jobDescLabel.tr, maxLines: 5),
                        const SizedBox(height: 14),
                        _field(ctrl.missionsCtrl, LKeys.jobMissionsLabel.tr, Icons.checklist_outlined, label: LKeys.jobMissionsLabel.tr, maxLines: 3),
                      ]),
                      const SizedBox(height: 12),
                      _section([
                        _label(LKeys.jobRequiredSkills.tr),
                        _skillsInput(ctrl),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: _field(ctrl.salaryMinCtrl, '0', Icons.attach_money, label: LKeys.salaryMinLabel.tr, type: TextInputType.number)),
                          const SizedBox(width: 10),
                          Expanded(child: _field(ctrl.salaryMaxCtrl, '0', Icons.attach_money, label: LKeys.salaryMaxLabel.tr, type: TextInputType.number)),
                        ]),
                        const SizedBox(height: 14),
                        _label(LKeys.experienceLevelLabel.tr),
                        _chips(ctrl, ['junior', 'mid', 'senior'], [LKeys.junior, LKeys.mid, LKeys.senior], ctrl.experienceLevel, ctrl.setExperienceLevel),
                        const SizedBox(height: 14),
                        _label(LKeys.deadlineLabel.tr),
                        GestureDetector(
                          onTap: ctrl.pickDeadline,
                          child: AbsorbPointer(child: _field(ctrl.deadlineCtrl, 'YYYY-MM-DD', Icons.calendar_today_outlined)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _section([
                        _label(LKeys.publishStatusLabel.tr),
                        _chips(ctrl, ['published', 'draft'], [LKeys.publish, LKeys.draft], ctrl.status, ctrl.setStatus),
                      ]),
                      const SizedBox(height: 20),
                      _submitBtn(ctrl),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(CreateJobController ctrl) {
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
            child: Text(
              (ctrl.isEdit ? LKeys.editJobOffer : LKeys.newJobOffer).tr,
              style: MyTextStyle.gilroyBold(size: 17, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: MyTextStyle.gilroySemiBold(size: 12, color: Colors.white54)),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {String? label, int maxLines = 1, TextInputType? type}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) _label(label),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: type,
          style: MyTextStyle.gilroyRegular(size: 14, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: MyTextStyle.gilroyRegular(size: 13, color: Colors.white24),
            prefixIcon: Icon(icon, color: Colors.white24, size: 17),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _kAccent.withValues(alpha: 0.5), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _chips(CreateJobController ctrl, List<String> values, List<String> labels, String selected, Function(String) onTap) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(values.length, (i) {
          final isSelected = values[i] == selected;
          return GestureDetector(
            onTap: () => onTap(values[i]),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? _kAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? _kAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1)),
              ),
              child: Text(
                labels[i].tr,
                style: MyTextStyle.gilroySemiBold(size: 12, color: isSelected ? _kAccent : Colors.white54),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _skillsInput(CreateJobController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl.skillCtrl,
                style: MyTextStyle.gilroyRegular(size: 13, color: Colors.white),
                onSubmitted: (_) => ctrl.addSkill(),
                decoration: InputDecoration(
                  hintText: LKeys.addSkillHint.tr,
                  hintStyle: MyTextStyle.gilroyRegular(size: 13, color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _kAccent.withValues(alpha: 0.5), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: ctrl.addSkill,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.add, color: _kAccent, size: 20),
              ),
            ),
          ],
        ),
        if (ctrl.skills.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(ctrl.skills.length, (i) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kAccent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(ctrl.skills[i], style: MyTextStyle.gilroySemiBold(size: 12, color: _kAccent)),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () => ctrl.removeSkill(i),
                      child: Icon(Icons.close_rounded, size: 13, color: _kAccent.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _submitBtn(CreateJobController ctrl) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kAccent, _kPurple]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: _kPurple.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: ElevatedButton(
          onPressed: ctrl.isSubmitting ? null : ctrl.submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: ctrl.isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  ctrl.isEdit ? LKeys.saveChanges.tr : LKeys.createJobBtn.tr,
                  style: MyTextStyle.gilroyBold(size: 15, color: Colors.white),
                ),
        ),
      ),
    );
  }
}
