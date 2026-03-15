import 'package:flutter/material.dart';
import 'package:vcom_app/core/common/permission.service.dart';
import 'package:vcom_app/core/models/module.model.dart';

class DashboardComponent extends ChangeNotifier {
  final PermissionService _permissionService = PermissionService();
  List<ModuleModel> _modules = [];
  bool _isLoading = false;
  String? _error;

  List<ModuleModel> get modules => _modules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Obtiene los módulos visibles desde el backend o desde el caché de permisos.
  Future<void> fetchModules({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _modules = await _permissionService.loadPermissions(
        forceRefresh: forceRefresh,
      );
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _modules = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getToken() {
    return 'Permisos gestionados por backend';
  }
}
