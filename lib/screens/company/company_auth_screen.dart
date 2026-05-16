import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:untitled/common/api_service/company_service.dart';
import 'package:untitled/common/api_service/notification_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/firebase_notification_manager.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/job_models.dart';
import 'package:untitled/screens/company/company_dashboard_screen.dart';
import 'package:untitled/screens/extra_views/logo_tag.dart';
import 'package:untitled/utilities/const.dart';

const Color _kDark = cBG;
const Color _kCard = cWhite;
const Color _kBorder = Color(0x1A1B3A5C);
const Color _kAccent = cPrimary;
const Color _kText = cMainText;
const Color _kMuted = cLightText;
const Color _kField = cLightBg;

class CompanyAuthController extends BaseController {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final sectorCtrl = TextEditingController();
  final codeCtrl = TextEditingController();

  String mode = 'login'; // 'login' | 'register' | 'verify'
  bool showPassword = false;
  bool isSubmitting = false;
  bool isResending = false;
  int resendSecondsLeft = 0;
  String notice = '';
  Timer? _resendTimer;

  bool _isStrongPassword(String p) =>
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$')
          .hasMatch(p);

  bool _isValidEmail(String email) =>
     RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

  bool get canResendCode => !isResending && resendSecondsLeft == 0;

  void _startResendCooldown([int seconds = 30]) {
    _resendTimer?.cancel();
    resendSecondsLeft = seconds;
    update();

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSecondsLeft <= 1) {
        resendSecondsLeft = 0;
        timer.cancel();
      } else {
        resendSecondsLeft -= 1;
      }
      update();
    });
  }

  void setMode(String m) {
    mode = m;
    notice = '';
    update();
  }

  void togglePassword() {
    showPassword = !showPassword;
    update();
  }

  Future<void> resendCode() async {
    if (!canResendCode) {
      return;
    }

    if (emailCtrl.text.trim().isEmpty || !_isValidEmail(emailCtrl.text.trim())) {
      showSnackBar('Entrez un email valide pour renvoyer le code.',
          type: SnackBarType.error);
      return;
    }

    isResending = true;
    update();
    try {
      final res = await CompanyService.shared
          .resendVerification(email: emailCtrl.text.trim());
      notice = res.message ?? '';
    } catch (_) {
      notice = 'Erreur réseau. Réessayez.';
    }
    isResending = false;
    _startResendCooldown();
    update();
  }

  Future<void> submit() async {
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text;

    if (mode == 'verify') {
      final code = codeCtrl.text.trim();
      if (!_isValidEmail(email)) {
        showSnackBar('Email invalide.', type: SnackBarType.error);
        return;
      }
      if (code.length != 6) {
        showSnackBar('Le code doit contenir 6 chiffres.',
            type: SnackBarType.error);
        return;
      }
      isSubmitting = true;
      update();
      try {
        final deviceToken = await _resolveDeviceToken();
        final res = await CompanyService.shared.verifyEmail(
          email: email,
          code: code,
          deviceToken: deviceToken,
        );
        isSubmitting = false;
        update();
        if (res.status == true && res.data != null) {
          _saveAndGo(res.data!, res);
        } else {
          showSnackBar(res.message ?? 'Code invalide.',
              type: SnackBarType.error);
        }
      } catch (_) {
        isSubmitting = false;
        update();
        showSnackBar('Erreur réseau.', type: SnackBarType.error);
      }
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      showSnackBar('Email et mot de passe requis.', type: SnackBarType.error);
      return;
    }
    if (!_isValidEmail(email)) {
      showSnackBar('Email invalide.', type: SnackBarType.error);
      return;
    }
    if (mode == 'register') {
      if (nameCtrl.text.trim().isEmpty) {
        showSnackBar('Nom de l\'entreprise requis.', type: SnackBarType.error);
        return;
      }
      if (!_isStrongPassword(password)) {
        showSnackBar(
            'Mot de passe faible : 8 car. min avec majuscule, chiffre et symbole.',
            type: SnackBarType.error);
        return;
      }
    }

    isSubmitting = true;
    update();

    try {
      final deviceToken = await _resolveDeviceToken();
      late CompanyAuthResponse res;
      if (mode == 'login') {
        res = await CompanyService.shared.login(
          email: email,
          password: password,
          deviceToken: deviceToken,
        );
      } else {
        res = await CompanyService.shared.register(
          name: nameCtrl.text.trim(),
          email: email,
          password: password,
          sector: sectorCtrl.text.isNotEmpty ? sectorCtrl.text.trim() : null,
          deviceToken: deviceToken,
        );
      }
      isSubmitting = false;
      update();

      if (res.status == true && res.data != null && mode == 'login') {
        _saveAndGo(res.data!, res);
      } else if (res.status == true && mode == 'register') {
        notice = res.message ?? 'Vérifiez votre email.';
        mode = 'verify';
        update();
      } else if (res.errorCode == 'email_not_verified') {
        notice = res.message ?? 'Email non vérifié.';
        mode = 'verify';
        update();
      } else {
        showSnackBar(res.message ?? 'Une erreur est survenue.',
            type: SnackBarType.error);
      }
    } catch (_) {
      isSubmitting = false;
      update();
      showSnackBar('Erreur réseau.', type: SnackBarType.error);
    }
  }

  void _saveAndGo(Company company, CompanyAuthResponse res) {
    final box = GetStorage();
    box.write('company_id', company.id);
    box.write('company_name', company.name);
    SessionManager.shared.setApiAuthToken(res.authToken);
    final owner = res.ownerUser;
    if (owner != null) {
      SessionManager.shared.setUser(owner);
      SessionManager.shared.setLogin(true);
      if (owner.isPushNotifications == 1) {
        FirebaseNotificationManager.shared.subscribeToTopic(notificationTopic);
        NotificationService.shared.subscribeToAllMyRoom();
      }
    }
    final notice = _ownerNotice(res);
    if (notice.isNotEmpty) {
      box.write('company_notice', notice);
    }
    Get.offAll(() => CompanyDashboardScreen(companyId: company.id!));
  }

  Future<String> _resolveDeviceToken() async {
    final completer = Completer<String>();
    try {
      FirebaseNotificationManager.shared.getNotificationToken((token) {
        if (!completer.isCompleted) {
          completer.complete(token);
        }
      });
      return completer.future.timeout(
        const Duration(seconds: 6),
        onTimeout: () => 'No Token',
      );
    } catch (_) {
      return 'No Token';
    }
  }

  String _ownerNotice(CompanyAuthResponse res) {
    if (res.ownerUserAutoCreated == true) {
      return 'Un profil ITGA associe a ete cree automatiquement. Vous pouvez maintenant utiliser le feed en mode entreprise.';
    }
    if (res.ownerUserAutoLinked == true) {
      return 'Votre entreprise est maintenant associee a un profil ITGA. Le mode entreprise est disponible.';
    }
    return '';
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    nameCtrl.dispose();
    sectorCtrl.dispose();
    codeCtrl.dispose();
    super.onClose();
  }
}

class CompanyAuthScreen extends StatelessWidget {
  const CompanyAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final storedId = box.read('company_id');
    if (storedId != null && SessionManager.shared.getUserID() > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.off(() => CompanyDashboardScreen(companyId: storedId));
      });
      return const Scaffold(
        backgroundColor: _kDark,
        body: Center(child: CircularProgressIndicator(color: _kAccent)),
      );
    } else if (storedId != null) {
      box.remove('company_id');
      box.remove('company_name');
    }

    Get.put(CompanyAuthController());
    return Scaffold(
      backgroundColor: _kDark,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.35, 1.0],
            colors: [cNavy, cBG, cBG],
          ),
        ),
        child: GetBuilder<CompanyAuthController>(
          builder: (ctrl) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 26),
                  _buildCard(ctrl, context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const LogoTag(width: 132),
        const SizedBox(height: 20),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: cWhite.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kAccent.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: cNavy.withValues(alpha: 0.14),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.business_rounded, color: _kAccent, size: 26),
        ),
        const SizedBox(height: 16),
        Text(
          LKeys.companyPortal.tr,
          textAlign: TextAlign.center,
          style: MyTextStyle.gilroyBold(size: 26, color: _kText),
        ),
        const SizedBox(height: 6),
        Text(
          'Connectez-vous ou creez votre espace recruteur ITGA',
          textAlign: TextAlign.center,
          style: MyTextStyle.gilroyRegular(size: 14, color: _kMuted),
        ),
      ],
    );
  }

  Widget _buildCard(CompanyAuthController ctrl, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: cNavy.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ctrl.mode != 'verify') ...[
            _tabRow(ctrl),
            const SizedBox(height: 20),
          ],
          if (ctrl.mode == 'verify') ...[
            _verifyHeader(ctrl),
            const SizedBox(height: 16),
          ],
          if (ctrl.mode == 'register') ...[
            _darkField(
                ctrl.nameCtrl, LKeys.companyName.tr, Icons.business_rounded),
            const SizedBox(height: 12),
            _darkField(ctrl.sectorCtrl, LKeys.companySector.tr,
                Icons.category_outlined),
            const SizedBox(height: 12),
          ],
          if (ctrl.mode != 'verify') ...[
            _darkField(
                ctrl.emailCtrl, LKeys.companyEmail.tr, Icons.email_outlined,
                type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _passwordField(ctrl),
            const SizedBox(height: 20),
          ],
          if (ctrl.mode == 'verify') ...[
            _codeField(ctrl),
            const SizedBox(height: 16),
          ],
          if (ctrl.notice.isNotEmpty) ...[
            _noticeBox(ctrl.notice),
            const SizedBox(height: 12),
          ],
          _submitBtn(ctrl),
          if (ctrl.mode == 'verify') ...[
            const SizedBox(height: 10),
            _resendBtn(ctrl),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () => ctrl.setMode('login'),
                child: Text('Retour a la connexion',
                    style:
                        MyTextStyle.gilroySemiBold(size: 13, color: _kAccent)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabRow(CompanyAuthController ctrl) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kField,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          _tab(ctrl, 'login', 'Connexion'),
          _tab(ctrl, 'register', 'Inscription'),
        ],
      ),
    );
  }

  Widget _tab(CompanyAuthController ctrl, String mode, String label) {
    final active = ctrl.mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => ctrl.setMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color:
                active ? _kAccent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: active
                ? Border.all(color: _kAccent.withValues(alpha: 0.4))
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: MyTextStyle.gilroySemiBold(
                  size: 13, color: active ? _kAccent : _kMuted),
            ),
          ),
        ),
      ),
    );
  }

  Widget _verifyHeader(CompanyAuthController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.shield_outlined,
              color: Color(0xFF10B981), size: 22),
        ),
        const SizedBox(height: 12),
        Text('Verifiez votre email',
            style: MyTextStyle.gilroyBold(size: 18, color: _kText)),
        const SizedBox(height: 4),
        Text(
          'Saisissez le code a 6 chiffres envoye a ${ctrl.emailCtrl.text.isNotEmpty ? ctrl.emailCtrl.text : "votre email"}.',
          style: MyTextStyle.gilroyRegular(size: 12, color: _kMuted),
        ),
      ],
    );
  }

  Widget _darkField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType? type,
    bool obscure = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      style: MyTextStyle.gilroyRegular(size: 14, color: _kText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: MyTextStyle.gilroyRegular(size: 13, color: _kMuted),
        prefixIcon: Icon(icon, color: cLightIcon, size: 18),
        filled: true,
        fillColor: _kField,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cNavy.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cNavy.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: _kAccent.withValues(alpha: 0.5), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _passwordField(CompanyAuthController ctrl) {
    return GetBuilder<CompanyAuthController>(
      builder: (c) => TextField(
        controller: c.passwordCtrl,
        obscureText: !c.showPassword,
        style: MyTextStyle.gilroyRegular(size: 14, color: _kText),
        decoration: InputDecoration(
          hintText: LKeys.companyPassword.tr,
          hintStyle: MyTextStyle.gilroyRegular(size: 13, color: _kMuted),
          prefixIcon:
              const Icon(Icons.lock_outline, color: cLightIcon, size: 18),
          suffixIcon: GestureDetector(
            onTap: c.togglePassword,
            child: Icon(
                c.showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: cLightIcon,
                size: 18),
          ),
          filled: true,
          fillColor: _kField,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cNavy.withValues(alpha: 0.08))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cNavy.withValues(alpha: 0.08))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: _kAccent.withValues(alpha: 0.5), width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _codeField(CompanyAuthController ctrl) {
    return TextField(
      controller: ctrl.codeCtrl,
      keyboardType: TextInputType.number,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: MyTextStyle.gilroyBold(size: 22, color: _kText),
      decoration: InputDecoration(
        hintText: '000000',
        hintStyle: MyTextStyle.gilroySemiBold(
            size: 22, color: _kMuted.withValues(alpha: 0.45)),
        counterText: '',
        filled: true,
        fillColor: _kField,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _kAccent.withValues(alpha: 0.3))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _kAccent.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _kAccent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  Widget _noticeBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kAccent.withValues(alpha: 0.25)),
      ),
      child: Text(text,
          style: MyTextStyle.gilroyRegular(size: 12, color: _kAccent)),
    );
  }

  Widget _submitBtn(CompanyAuthController ctrl) {
    final labels = {
      'login': LKeys.companyLoginBtn.tr,
      'register': LKeys.companyRegisterBtn.tr,
      'verify': 'Verifier mon email'
    };
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF00C4D4), Color(0xFF7B2FFF)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF7B2FFF).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: ElevatedButton(
          onPressed: ctrl.isSubmitting ? null : ctrl.submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: ctrl.isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(labels[ctrl.mode] ?? '',
                  style: MyTextStyle.gilroyBold(size: 14, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _resendBtn(CompanyAuthController ctrl) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton(
        onPressed: ctrl.canResendCode ? ctrl.resendCode : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cNavy.withValues(alpha: 0.12)),
          backgroundColor: _kField,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          foregroundColor: _kMuted,
        ),
        child: ctrl.isResending
            ? const SizedBox(
                width: 16,
                height: 16,
                child:
                    CircularProgressIndicator(color: _kMuted, strokeWidth: 2))
            : Text(
                ctrl.resendSecondsLeft > 0
                    ? 'Renvoyer le code (${ctrl.resendSecondsLeft}s)'
                    : 'Renvoyer le code',
                style: MyTextStyle.gilroySemiBold(size: 13, color: _kMuted)),
      ),
    );
  }
}
