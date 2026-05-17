import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/company_service.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/job_models.dart';
import 'package:untitled/screens/job_board/job_detail_screen.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/common/managers/session_manager.dart';

/// Public company profile (LinkedIn-like).
/// Accessible to any authenticated ITGA user to discover and follow companies.
class CompanyPublicProfileScreen extends StatefulWidget {
  final int companyId;
  const CompanyPublicProfileScreen({super.key, required this.companyId});

  @override
  State<CompanyPublicProfileScreen> createState() =>
      _CompanyPublicProfileScreenState();
}

class _CompanyPublicProfileScreenState
    extends State<CompanyPublicProfileScreen> {
  Company? _company;
  List<JobOffer> _jobs = [];
  bool _loading = true;
  bool _hasMore = true;
  bool _following = false;
  int _followersCount = 0;
  bool _followBusy = false;
  bool _loadingMore = false;

  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _load(start: 0, reset: true);
  }

  Future<void> _load({required int start, bool reset = false}) async {
    if (_loadingMore) return;
    _loadingMore = true;
    try {
      final userId = SessionManager.shared.getUserID();
      final res = await CompanyService.shared.publicProfile(
        companyId: widget.companyId,
        userId: userId > 0 ? userId : null,
        start: start,
        limit: _pageSize,
      );
      if (!mounted) return;
      if (res.status == true && res.data != null) {
        final newJobs = res.data!.jobs ?? [];
        setState(() {
          if (reset) {
            _company = res.data!.company;
            _following = (_company?.isFollowing ?? 0) == 1;
            _followersCount = _company?.followersCount ?? 0;
            _jobs = newJobs;
          } else {
            _jobs = [..._jobs, ...newJobs];
          }
          _hasMore = newJobs.length == _pageSize;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      _loadingMore = false;
    }
  }

  Future<void> _toggleFollow() async {
    final userId = SessionManager.shared.getUserID();
    if (userId <= 0 || _followBusy) return;
    setState(() => _followBusy = true);
    try {
      final res = _following
          ? await CompanyService.shared
              .unfollowCompany(userId: userId, companyId: widget.companyId)
          : await CompanyService.shared
              .followCompany(userId: userId, companyId: widget.companyId);
      if (!mounted) return;
      if (res.status == true) {
        setState(() {
          _following = (res.isFollowing ?? 0) == 1;
          _followersCount = res.followersCount ?? _followersCount;
        });
      }
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBG,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: cPrimary))
          : _company == null
              ? _buildEmpty()
              : _buildContent(),
    );
  }

  Widget _buildEmpty() {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(showTitle: false),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.business, size: 48, color: cLightIcon),
                  const SizedBox(height: 12),
                  Text('Entreprise introuvable',
                      style: MyTextStyle.gilroySemiBold(
                          size: 15, color: cLightText)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final company = _company!;
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(showTitle: true),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scroll) {
                if (scroll.metrics.pixels >=
                        scroll.metrics.maxScrollExtent - 200 &&
                    _hasMore &&
                    !_loadingMore) {
                  _load(start: _jobs.length);
                }
                return false;
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCard(company),
                    const SizedBox(height: 16),
                    if ((company.description ?? '').isNotEmpty)
                      _buildSection(
                          LKeys.aboutCompany.tr, company.description!),
                    if ((company.rseCommitments ?? '').isNotEmpty)
                      _buildRseSection(company.rseCommitments!),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                            width: 3,
                            height: 14,
                            decoration: BoxDecoration(
                                color: cPrimary,
                                borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        Text("Offres d'emploi",
                            style: MyTextStyle.gilroyBold(
                                size: 16, color: cMainText)),
                        if ((company.publishedOffersCount ?? 0) > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: cPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text('${company.publishedOffersCount}',
                                style: MyTextStyle.gilroySemiBold(
                                    size: 11, color: cPrimary)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_jobs.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                            color: cWhite,
                            borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          children: [
                            const Icon(Icons.work_outline,
                                size: 36, color: cLightIcon),
                            const SizedBox(height: 8),
                            Text('Aucune offre publiée pour le moment.',
                                style: MyTextStyle.gilroyRegular(
                                    size: 13, color: cLightText)),
                          ],
                        ),
                      )
                    else
                      ..._jobs.map((j) => _buildJobCard(j)),
                    if (_loadingMore && _hasMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: cPrimary, strokeWidth: 2)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar({required bool showTitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cWhite,
        boxShadow: [
          BoxShadow(
              color: cBlack.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: cLightBg, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back, size: 18, color: cMainText),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: showTitle && _company != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _company!.name ?? '',
                        style:
                            MyTextStyle.gilroyBold(size: 15, color: cMainText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((_company!.sector ?? '').isNotEmpty)
                        Text(
                          _company!.sector!,
                          style: MyTextStyle.gilroyRegular(
                              size: 11, color: cLightText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          _buildFollowButton(compact: true),
        ],
      ),
    );
  }

  Widget _buildFollowButton({bool compact = false}) {
    final userId = SessionManager.shared.getUserID();
    if (userId <= 0) return const SizedBox.shrink();
    if (SessionManager.shared.getActingCompanyId() == widget.companyId) {
      return const SizedBox.shrink();
    }
    if (_company?.ownerUserId == userId) {
      return const SizedBox.shrink();
    }

    final bg = _following ? cPrimary.withValues(alpha: 0.1) : cPrimary;
    final fg = _following ? cPrimary : cWhite;
    final label = _following ? LKeys.following.tr : LKeys.follow.tr;
    final icon = _following ? Icons.check : Icons.add;

    return GestureDetector(
      onTap: _followBusy ? null : _toggleFollow,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 18, vertical: compact ? 8 : 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: _following
              ? Border.all(color: cPrimary.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_followBusy)
              SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: fg))
            else
              Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(label,
                style:
                    MyTextStyle.gilroyBold(size: compact ? 12 : 13, color: fg)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(Company company) {
    final isCertified = company.isVerified == 1;

    return Container(
      decoration: BoxDecoration(
        color: cWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: cBlack.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner gradient
          Container(
            height: 88,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cPrimary.withValues(alpha: 0.22),
                  cHashtagColor.withValues(alpha: 0.18)
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: cPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cWhite, width: 3),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: (company.logo != null && company.logo!.isNotEmpty)
                        ? Image.network(company.logo!, fit: BoxFit.cover)
                        : const Icon(Icons.business, color: cPrimary, size: 28),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              company.name ?? '',
                              style: MyTextStyle.gilroyBold(
                                  size: 19, color: cMainText),
                              maxLines: 2,
                            ),
                          ),
                          if (isCertified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified,
                                size: 18, color: cBlueTick),
                          ],
                        ],
                      ),
                      if ((company.sector ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(company.sector!,
                            style: MyTextStyle.gilroyRegular(
                                size: 13, color: cLightText)),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if ((company.city ?? '').isNotEmpty)
                            _chip(
                                Icons.location_on_outlined,
                                [company.city, company.country]
                                    .where((s) => (s ?? '').isNotEmpty)
                                    .join(', ')),
                          if (company.companySize != null)
                            _chip(Icons.people_outline,
                                '${company.companySize} employés'),
                          if ((company.website ?? '').isNotEmpty)
                            _chip(Icons.link, LKeys.website.tr),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _stat('${company.publishedOffersCount ?? 0}',
                              'Offres actives', cPrimary),
                          const SizedBox(width: 8),
                          _stat('$_followersCount', LKeys.followers.tr,
                              cHashtagColor),
                          const SizedBox(width: 8),
                          _stat(
                            null,
                            isCertified ? 'Certifiee ITGA' : 'Non certifiee',
                            isCertified ? cGreen : cLightText,
                            icon: isCertified
                                ? Icons.verified_user
                                : Icons.shield_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: cLightBg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cDarkText),
          const SizedBox(width: 5),
          Text(label,
              style: MyTextStyle.gilroySemiBold(size: 11, color: cDarkText)),
        ],
      ),
    );
  }

  Widget _stat(String? value, String label, Color color, {IconData? icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            if (icon != null)
              Icon(icon, size: 18, color: color)
            else
              Text(value ?? '',
                  style: MyTextStyle.gilroyBold(size: 16, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: MyTextStyle.gilroyRegular(size: 10, color: cLightText),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: cWhite, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: MyTextStyle.gilroyBold(size: 14, color: cMainText)),
          const SizedBox(height: 8),
          Text(content,
              style: MyTextStyle.gilroyRegular(size: 13, color: cDarkText)),
        ],
      ),
    );
  }

  Widget _buildRseSection(String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cGreen.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_outlined, size: 16, color: cGreen),
              const SizedBox(width: 6),
              Text(LKeys.rseCommitments.tr,
                  style: MyTextStyle.gilroyBold(size: 13, color: cGreen)),
            ],
          ),
          const SizedBox(height: 8),
          Text(content,
              style: MyTextStyle.gilroyRegular(size: 13, color: cDarkText)),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobOffer job) {
    return GestureDetector(
      onTap: () {
        if (job.id != null) Get.to(() => JobDetailScreen(jobId: job.id!));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: cWhite, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title ?? '',
                      style: MyTextStyle.gilroyBold(size: 14, color: cMainText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      if ((job.contractType ?? '').isNotEmpty)
                        _tag(job.contractType!.tr, cPrimary),
                      if ((job.locationType ?? '').isNotEmpty)
                        _tag(job.locationType!.tr, cHashtagColor),
                      if ((job.locationCity ?? '').isNotEmpty)
                        _tag(job.locationCity!, cLightText),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: cLightIcon),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: MyTextStyle.gilroySemiBold(size: 10, color: color)),
    );
  }
}
