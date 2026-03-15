import 'package:vcom_app/core/auth/login/login.services.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/module.model.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final TokenService _tokenService = TokenService();
  final LoginService _loginService = LoginService();

  List<ModuleModel> get modules => _tokenService.getModules();

  List<ModuleModel> get readableModules => modules
      .where((module) => module.state && module.permissions.read)
      .toList(growable: false);

  Future<List<ModuleModel>> loadPermissions({bool forceRefresh = false}) async {
    if (!forceRefresh && _tokenService.hasPermissions()) {
      return readableModules;
    }

    return refreshPermissions();
  }

  Future<List<ModuleModel>> refreshPermissions() async {
    final token = _tokenService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación');
    }

    final response = await _loginService.getPermissions(token);
    _tokenService.setPermissions(response);
    return readableModules;
  }

  ModuleModel? findModule({
    List<String> routeHints = const [],
    List<String> nameHints = const [],
  }) {
    final normalizedRouteHints = routeHints.map(_normalize).where((hint) => hint.isNotEmpty).toList();
    final normalizedNameHints = nameHints.map(_normalize).where((hint) => hint.isNotEmpty).toList();

    for (final module in modules) {
      final route = _normalize(module.route);
      final name = _normalize(module.nameModule);

      final routeMatch = normalizedRouteHints.any((hint) => route.contains(hint));
      final nameMatch = normalizedNameHints.any((hint) => name.contains(hint));

      if (routeMatch || nameMatch) {
        return module;
      }
    }

    return null;
  }

  bool canReadModule({
    List<String> routeHints = const [],
    List<String> nameHints = const [],
  }) {
    final module = findModule(routeHints: routeHints, nameHints: nameHints);
    return module?.state == true && module?.permissions.read == true;
  }

  bool canCreateModule({
    List<String> routeHints = const [],
    List<String> nameHints = const [],
  }) {
    final module = findModule(routeHints: routeHints, nameHints: nameHints);
    return module?.state == true && module?.permissions.create == true;
  }

  bool canUpdateModule({
    List<String> routeHints = const [],
    List<String> nameHints = const [],
  }) {
    final module = findModule(routeHints: routeHints, nameHints: nameHints);
    return module?.state == true && module?.permissions.update == true;
  }

  bool canDeleteModule({
    List<String> routeHints = const [],
    List<String> nameHints = const [],
  }) {
    final module = findModule(routeHints: routeHints, nameHints: nameHints);
    return module?.state == true && module?.permissions.delete == true;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}
