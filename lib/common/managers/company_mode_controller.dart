import 'package:get/get.dart';
import 'package:untitled/common/managers/session_manager.dart';

/// Contrôleur singleton qui gère le "mode entreprise actif" :
/// un utilisateur a activé le mode entreprise pour naviguer et interagir
/// sur le feed au nom de son entreprise.
class CompanyModeController extends GetxController {
  /// Accès singleton avec auto-enregistrement.
  static CompanyModeController get to {
    if (!Get.isRegistered<CompanyModeController>()) {
      Get.put(CompanyModeController(), permanent: true);
    }
    return Get.find<CompanyModeController>();
  }

  final actingId = Rx<int?>(null);
  final actingName = ''.obs;

  bool get isActing => (actingId.value ?? 0) > 0;

  @override
  void onInit() {
    super.onInit();
    actingId.value = SessionManager.shared.getActingCompanyId();
    actingName.value = SessionManager.shared.getActingCompanyName() ?? '';
  }

  /// Active le mode entreprise et persiste dans GetStorage.
  void activate(int id, String name) {
    actingId.value = id;
    actingName.value = name;
    SessionManager.shared.setActingCompany(id, name);
  }

  /// Désactive le mode entreprise et efface la persistance.
  void deactivate() {
    actingId.value = null;
    actingName.value = '';
    SessionManager.shared.setActingCompany(null, null);
  }
}
