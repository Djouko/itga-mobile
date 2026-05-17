import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/company_service.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/job_models.dart';
import 'package:untitled/screens/company/company_dashboard_screen.dart';
import 'package:untitled/screens/job_board/job_detail_screen.dart';
import 'package:untitled/utilities/const.dart';

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
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _following = false;
  bool _followBusy = false;
  int _followersCount = 0;

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
      _loadingMore = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final userId = SessionManager.shared.getUserID();
    if (userId <= 0 || _followBusy || _company == null) return;
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

  bool get _isOwner {
    final userId = SessionManager.shared.getUserID();
    return userId > 0 && _company?.ownerUserId == userId;
  }

  bool get _isActingAsThisCompany =>
      SessionManager.shared.getActingCompanyId() == widget.companyId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBlack,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: cPrimary))
          : _company == null
              ? _emptyState()
              : RefreshIndicator(
                  color: refreshIndicatorColor,
                  backgroundColor: refreshIndicatorBgColor,
                  onRefresh: () => _load(start: 0, reset: true),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scroll) {
                      if (scroll.metrics.pixels >=
                              scroll.metrics.maxScrollExtent - 220 &&
                          _hasMore &&
                          !_loadingMore) {
                        _load(start: _jobs.length);
                      }
                      return false;
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        _companyHeader(_company!),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(15, 14, 15, 36),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _actionRow(),
                                const SizedBox(height: 14),
                                _aboutSection(_company!),
                                if ((_company!.rseCommitments ?? '')
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _rseSection(_company!.rseCommitments!),
                                ],
                                const SizedBox(height: 18),
                                _jobsHeader(_company!),
                                const SizedBox(height: 10),
                                if (_jobs.isEmpty)
                                  _emptyJobsCard()
                                else
                                  ..._jobs.map(_jobCard),
                                if (_loadingMore && _hasMore)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: cPrimary,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _emptyState() {
    return SafeArea(
      child: Column(
        children: [
          _topBar(title: ''),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.apartment_rounded,
                      size: 52, color: cPrimary.withValues(alpha: 0.8)),
                  const SizedBox(height: 12),
                  Text(
                    'Entreprise introuvable',
                    style: MyTextStyle.gilroySemiBold(
                        size: 15, color: cLightIcon),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _companyHeader(Company company) {
    final isCertified = company.isVerified == 1;
    final location = [company.city, company.country]
        .where((item) => (item ?? '').isNotEmpty)
        .join(', ');

    return SliverToBoxAdapter(
      child: Container(
        color: cBlack,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(title: company.name ?? ''),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 142,
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 48),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cPrimary.withValues(alpha: 0.55),
                        cNavy.withValues(alpha: 0.92),
                        cDarkBG,
                      ],
                    ),
                  ),
                  child: CustomPaint(painter: _CompanyPatternPainter()),
                ),
                Positioned(
                  left: 15,
                  bottom: 0,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cBlack,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: cBlack.withValues(alpha: 0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: MyCachedImage(
                          imageUrl: company.logo,
                          width: 88,
                          height: 88,
                          cornerRadius: 20,
                        ),
                      ),
                      if (isCertified)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: cBlueTick,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: cBlack, width: 3),
                            ),
                            child: const Icon(Icons.check,
                                color: cWhite, size: 17),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 4, 15, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          company.name ?? '',
                          style: MyTextStyle.gilroyBlack(
                              color: cWhite, size: 25),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCertified)
                        const Icon(Icons.verified,
                            color: cBlueTick, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if ((company.sector ?? '').isNotEmpty)
                    Text(
                      company.sector!,
                      style: MyTextStyle.gilroyRegular(
                          color: cLightIcon, size: 14),
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _metaChip(Icons.business_center_outlined,
                          '${company.publishedOffersCount ?? 0} offres'),
                      _metaChip(Icons.people_alt_outlined,
                          '$_followersCount abonnes'),
                      if (location.isNotEmpty)
                        _metaChip(Icons.location_on_outlined, location),
                      if (company.companySize != null)
                        _metaChip(Icons.groups_2_outlined,
                            '${company.companySize} personnes'),
                      if ((company.website ?? '').isNotEmpty)
                        _metaChip(Icons.link_rounded, company.website!),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _certificationCard(isCertified),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar({required String title}) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: cBlack,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.chevron_left_rounded,
                  color: cWhite, size: 30),
            ),
            Expanded(
              child: Text(
                title,
                style: MyTextStyle.gilroyBold(color: cWhite, size: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_isOwner || _isActingAsThisCompany)
              TextButton.icon(
                onPressed: () => Get.to(
                  () => CompanyDashboardScreen(companyId: widget.companyId),
                ),
                icon: const Icon(Icons.tune_rounded, color: cPrimary, size: 16),
                label: Text(
                  'Gerer',
                  style: MyTextStyle.gilroySemiBold(
                      color: cPrimary, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionRow() {
    if (_isOwner || _isActingAsThisCompany) {
      return _wideButton(
        label: LKeys.companyDashboard.tr,
        icon: Icons.dashboard_outlined,
        filled: true,
        onTap: () => Get.to(
          () => CompanyDashboardScreen(companyId: widget.companyId),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _wideButton(
            label: _following ? LKeys.following.tr : LKeys.follow.tr,
            icon: _following ? Icons.check_rounded : Icons.add_rounded,
            filled: !_following,
            busy: _followBusy,
            onTap: _toggleFollow,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _wideButton(
            label: 'Offres',
            icon: Icons.work_outline_rounded,
            filled: false,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _wideButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback? onTap,
    bool busy = false,
  }) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: filled ? cPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: filled ? cPrimary : cPrimary.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: filled ? cBlack : cPrimary,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(icon, color: filled ? cBlack : cPrimary, size: 18),
            const SizedBox(width: 7),
            Text(
              label,
              style: MyTextStyle.gilroyBold(
                  color: filled ? cBlack : cPrimary, size: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aboutSection(Company company) {
    final description = (company.description ?? '').trim();
    final text = description.isEmpty
        ? 'Cette entreprise n a pas encore ajoute de presentation.'
        : description;
    return _darkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.info_outline_rounded, LKeys.aboutCompany.tr),
          const SizedBox(height: 9),
          Text(
            text,
            style: MyTextStyle.gilroyRegular(
                color: description.isEmpty ? cLightText : cLightIcon,
                size: 14),
          ),
        ],
      ),
    );
  }

  Widget _rseSection(String content) {
    return _darkCard(
      borderColor: cPrimary.withValues(alpha: 0.26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.eco_outlined, LKeys.rseCommitments.tr,
              color: cPrimary),
          const SizedBox(height: 9),
          Text(
            content,
            style: MyTextStyle.gilroyRegular(color: cLightIcon, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _jobsHeader(Company company) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: cPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "Offres d'emploi",
          style: MyTextStyle.gilroyBlack(color: cWhite, size: 16),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: cPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${company.publishedOffersCount ?? _jobs.length}',
            style: MyTextStyle.gilroySemiBold(color: cPrimary, size: 11),
          ),
        ),
      ],
    );
  }

  Widget _emptyJobsCard() {
    return _darkCard(
      child: Column(
        children: [
          Icon(Icons.work_outline_rounded,
              size: 34, color: cLightText.withValues(alpha: 0.9)),
          const SizedBox(height: 8),
          Text(
            'Aucune offre publiee pour le moment.',
            style: MyTextStyle.gilroyRegular(color: cLightText, size: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _jobCard(JobOffer job) {
    return GestureDetector(
      onTap: () {
        if (job.id != null) Get.to(() => JobDetailScreen(jobId: job.id!));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cDarkBG,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cLightText.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title ?? '',
                    style: MyTextStyle.gilroyBold(color: cWhite, size: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if ((job.contractType ?? '').isNotEmpty)
                        _tag(job.contractType!.tr, cPrimary),
                      if ((job.locationType ?? '').isNotEmpty)
                        _tag(job.locationType!.tr, cCyan),
                      if ((job.locationCity ?? '').isNotEmpty)
                        _tag(job.locationCity!, cLightText),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 22, color: cLightText),
          ],
        ),
      ),
    );
  }

  Widget _certificationCard(bool isCertified) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCertified
            ? cBlueTick.withValues(alpha: 0.12)
            : cOrange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCertified
              ? cBlueTick.withValues(alpha: 0.30)
              : cOrange.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCertified ? Icons.verified_user_rounded : Icons.shield_outlined,
            color: isCertified ? cBlueTick : cOrange,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isCertified
                  ? 'Certification ITGA validee'
                  : 'Certification ITGA en attente',
              style: MyTextStyle.gilroySemiBold(
                color: isCertified ? cBlueTick : cOrange,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkCard({required Widget child, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cDarkBG,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ?? cLightText.withValues(alpha: 0.10),
        ),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(IconData icon, String title, {Color color = cWhite}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 7),
        Text(
          title,
          style: MyTextStyle.gilroyBold(color: color, size: 14),
        ),
      ],
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cDarkBG,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cLightText.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cPrimary, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: MyTextStyle.gilroyMedium(color: cLightIcon, size: 11),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: MyTextStyle.gilroySemiBold(size: 10, color: color),
      ),
    );
  }
}

class _CompanyPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cWhite.withValues(alpha: 0.12)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    for (double x = 14; x < size.width; x += 28) {
      for (double y = 14; y < size.height; y += 28) {
        canvas.drawLine(Offset(x - 3, y), Offset(x + 3, y), paint);
        canvas.drawLine(Offset(x, y - 3), Offset(x, y + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
