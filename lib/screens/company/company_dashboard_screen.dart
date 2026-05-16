import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:untitled/common/api_service/company_service.dart';
import 'package:untitled/common/api_service/job_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/company_mode_controller.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/job_models.dart';
import 'package:untitled/screens/company/company_applications_screen.dart';
import 'package:untitled/screens/company/company_auth_screen.dart';
import 'package:untitled/screens/company/create_job_screen.dart';
import 'package:untitled/screens/tabbar/tabbar_screen.dart';

const _kDark = Color(0xFF030A14);
const _kCard = Color(0xFF0D1525);
const _kBorder = Color(0x14FFFFFF);
const _kAccent = Color(0xFF00C4D4);
const _kPurple = Color(0xFF7B2FFF);

class CompanyDashboardController extends BaseController {
  final int companyId;
  CompanyDashboardData? dashboard;
  String notice = '';

  CompanyDashboardController({required this.companyId});

  @override
  void onInit() {
    super.onInit();
    final box = GetStorage();
    notice = box.read('company_notice') ?? '';
    if (notice.isNotEmpty) {
      box.remove('company_notice');
    }
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    isLoading.value = true;
    update();
    try {
      final response = await CompanyService.shared.fetchDashboard(companyId: companyId);
      if (response.status == true && response.data != null) {
        dashboard = response.data;
      }
    } catch (_) {
      hasNetworkError = true;
    }
    isLoading.value = false;
    update();
  }

  Future<void> deleteJob(int jobId) async {
    final success = await JobService.shared.deleteJob(jobId: jobId, companyId: companyId);
    if (success) {
      dashboard?.recentOffers?.removeWhere((j) => j.id == jobId);
      update();
    }
  }

  void logout() {
    final box = GetStorage();
    box.remove('company_id');
    box.remove('company_name');
    box.remove('company_notice');
    CompanyModeController.to.deactivate();
    Get.offAll(() => const CompanyAuthScreen());
  }
}

class CompanyDashboardScreen extends StatelessWidget {
  final int companyId;
  const CompanyDashboardScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(CompanyDashboardController(companyId: companyId));
    return Scaffold(
      backgroundColor: _kDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(ctrl),
            Expanded(
              child: GetBuilder<CompanyDashboardController>(
                builder: (c) {
                  if (c.isLoading.value && c.dashboard == null) {
                    return const Center(child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2));
                  }
                  if (c.dashboard == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 40),
                          const SizedBox(height: 12),
                          Text('Erreur de chargement', style: MyTextStyle.gilroySemiBold(size: 15, color: Colors.white38)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: c.fetchDashboard,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: _kAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
                              ),
                              child: Text('Réessayer', style: MyTextStyle.gilroySemiBold(size: 13, color: _kAccent)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: _kAccent,
                    backgroundColor: _kCard,
                    onRefresh: c.fetchDashboard,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _companyBanner(c),
                          if (c.notice.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _ownerNotice(c.notice),
                          ],
                          const SizedBox(height: 12),
                          _userModeButton(c),
                          const SizedBox(height: 16),
                          _statsGrid(c.dashboard!.stats),
                          const SizedBox(height: 16),
                          _createBtn(c),
                          const SizedBox(height: 20),
                          _sectionTitle('Offres récentes'),
                          const SizedBox(height: 10),
                          if (c.dashboard!.recentOffers == null || c.dashboard!.recentOffers!.isEmpty)
                            _emptyState()
                          else
                            ...c.dashboard!.recentOffers!.map((job) => _JobTile(
                                  job: job,
                                  companyId: companyId,
                                  onDelete: () => c.deleteJob(job.id!),
                                  onRefresh: c.fetchDashboard,
                                )),
                          const SizedBox(height: 24),
                        ],
                      ),
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

  Widget _buildTopBar(CompanyDashboardController ctrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kAccent, _kPurple]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.business_rounded, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(LKeys.companyDashboard.tr, style: MyTextStyle.gilroyBold(size: 17, color: Colors.white)),
          ),
          GestureDetector(
            onTap: () => Get.to(() => CreateJobScreen(companyId: companyId))?.then((_) => ctrl.fetchDashboard()),
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: _kAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.add, color: _kAccent, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: ctrl.logout,
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: Icon(Icons.logout_rounded, color: Colors.white.withValues(alpha: 0.5), size: 17),
            ),
          ),
        ],
      ),
    );
  }

  Widget _companyBanner(CompanyDashboardController ctrl) {
    final name = ctrl.dashboard?.company?.name ?? '';
    final sector = ctrl.dashboard?.company?.sector ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1525), Color(0xFF0A1020)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_kAccent.withValues(alpha: 0.25), _kPurple.withValues(alpha: 0.15)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'C',
                style: MyTextStyle.gilroyBold(size: 20, color: _kAccent),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: MyTextStyle.gilroyBold(size: 16, color: Colors.white)),
                if (sector.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(sector, style: MyTextStyle.gilroyRegular(size: 12, color: Colors.white38)),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text('Actif', style: MyTextStyle.gilroySemiBold(size: 11, color: Color(0xFF10B981))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownerNotice(String notice) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mode entreprise pret', style: MyTextStyle.gilroySemiBold(size: 13, color: Colors.white)),
                const SizedBox(height: 3),
                Text(notice, style: MyTextStyle.gilroyRegular(size: 11, color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(DashboardStats? stats) {
    return Column(
      children: [
        Row(
          children: [
            _statCard('${stats?.totalOffers ?? 0}', 'Offres', Icons.work_outline, _kAccent),
            const SizedBox(width: 10),
            _statCard('${stats?.totalApplications ?? 0}', 'Candidatures', Icons.description_outlined, _kPurple),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _statCard('${stats?.totalViews ?? 0}', 'Vues', Icons.visibility_outlined, const Color(0xFFFF6BAC)),
            const SizedBox(width: 10),
            _statCard('${stats?.publishedOffers ?? 0}', 'Publiées', Icons.check_circle_outline, const Color(0xFF10B981)),
          ],
        ),
      ],
    );
  }

  Widget _userModeButton(CompanyDashboardController ctrl) {
    final companyName = ctrl.dashboard?.company?.name ?? GetStorage().read('company_name') ?? '';
    final canActAsCompany = (ctrl.dashboard?.company?.ownerUserId ?? 0) > 0;
    return GestureDetector(
      onTap: () {
        if (!canActAsCompany) {
          ctrl.showSnackBar('Associez cette entreprise a votre compte ITGA pour utiliser le feed.', type: SnackBarType.error);
          return;
        }
        CompanyModeController.to.activate(ctrl.companyId, companyName);
        Get.offAll(() => TabBarScreen());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _kPurple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kPurple.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _kPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.swap_horiz_rounded, color: _kPurple, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mode utilisateur', style: MyTextStyle.gilroySemiBold(size: 14, color: Colors.white)),
                  Text(
                    canActAsCompany
                        ? 'Naviguez et interagissez comme un utilisateur'
                        : 'Connexion ITGA requise pour agir sur le feed',
                    style: MyTextStyle.gilroyRegular(size: 11, color: Colors.white38),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: _kPurple.withValues(alpha: 0.6), size: 13),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(value, style: MyTextStyle.gilroyBold(size: 20, color: Colors.white)),
            const SizedBox(height: 2),
            Text(label, style: MyTextStyle.gilroyRegular(size: 10, color: Colors.white38), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _createBtn(CompanyDashboardController ctrl) {
    return GestureDetector(
      onTap: () => Get.to(() => CreateJobScreen(companyId: companyId))?.then((_) => ctrl.fetchDashboard()),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kAccent, _kPurple]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: _kPurple.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(LKeys.createNewJob.tr, style: MyTextStyle.gilroyBold(size: 14, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: _kAccent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: MyTextStyle.gilroyBold(size: 15, color: Colors.white)),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.work_outline, color: Colors.white12, size: 44),
          const SizedBox(height: 12),
          Text(LKeys.noCompanyOffers.tr, style: MyTextStyle.gilroyRegular(size: 14, color: Colors.white24), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  final JobOffer job;
  final int companyId;
  final VoidCallback onDelete;
  final Future<void> Function() onRefresh;

  const _JobTile({required this.job, required this.companyId, required this.onDelete, required this.onRefresh});

  Color get _statusColor {
    switch (job.status) {
      case 'published': return const Color(0xFF10B981);
      case 'draft': return const Color(0xFF94A3B8);
      case 'closed': return const Color(0xFFF43F5E);
      default: return const Color(0xFF94A3B8);
    }
  }

  String get _statusLabel {
    switch (job.status) {
      case 'published': return 'Publiée';
      case 'draft': return 'Brouillon';
      case 'closed': return 'Fermée';
      default: return job.status ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.work_outline, color: _kAccent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title ?? '', style: MyTextStyle.gilroySemiBold(size: 14, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(_statusLabel, style: MyTextStyle.gilroySemiBold(size: 10, color: _statusColor)),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.people_outline, color: Colors.white24, size: 12),
                    const SizedBox(width: 3),
                    Text('${job.applicationsCount ?? 0}', style: MyTextStyle.gilroyRegular(size: 11, color: Colors.white38)),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: const Color(0xFF1A2C44),
            icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.35), size: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _kBorder)),
            onSelected: (value) {
              switch (value) {
                case 'applications':
                  Get.to(() => CompanyApplicationsScreen(jobId: job.id!, companyId: companyId));
                  break;
                case 'edit':
                  Get.to(() => CreateJobScreen(companyId: companyId, editJob: job))?.then((_) => onRefresh());
                  break;
                case 'delete':
                  Get.defaultDialog(
                    backgroundColor: const Color(0xFF0D1525),
                    titleStyle: const TextStyle(color: Colors.white),
                    middleTextStyle: const TextStyle(color: Colors.white54),
                    title: 'Supprimer',
                    middleText: LKeys.confirmDeleteJob.tr,
                    textConfirm: 'Supprimer',
                    textCancel: 'Annuler',
                    confirmTextColor: Colors.white,
                    buttonColor: const Color(0xFFF43F5E),
                    cancelTextColor: Colors.white54,
                    onConfirm: () { Get.back(); onDelete(); },
                  );
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'applications', child: Row(children: [const Icon(Icons.people_outline, size: 16, color: _kAccent), const SizedBox(width: 8), Text(LKeys.viewApplications.tr, style: const TextStyle(color: Colors.white70, fontSize: 13))])),
              PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined, size: 16, color: Colors.white54), const SizedBox(width: 8), Text(LKeys.edit.tr, style: const TextStyle(color: Colors.white70, fontSize: 13))])),
              PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 16, color: Color(0xFFF43F5E)), const SizedBox(width: 8), Text('Supprimer', style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 13))])),
            ],
          ),
        ],
      ),
    );
  }
}
