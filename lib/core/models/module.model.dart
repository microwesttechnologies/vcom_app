/// Modelo de módulo con permisos
class ModuleModel {
  final int idModule;
  final String nameModule;
  final String descriptionModule;
  final String route;
  final bool state;
  final String icon;
  final ModulePermissions permissions;

  ModuleModel({
    required this.idModule,
    required this.nameModule,
    required this.descriptionModule,
    required this.route,
    required this.state,
    required this.icon,
    required this.permissions,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      idModule: _parseInt(json['id_module']),
      nameModule: json['name_module'] as String? ?? '',
      descriptionModule: json['description_module'] as String? ?? '',
      route: json['route'] as String? ?? '',
      state: _parseBool(json['state']),
      icon: json['icon'] as String? ?? '',
      permissions: ModulePermissions.fromJson(
        (json['permissions'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }
}

/// Modelo de permisos del módulo
class ModulePermissions {
  final bool create;
  final bool read;
  final bool update;
  final bool delete;
  final bool statePermission;

  ModulePermissions({
    required this.create,
    required this.read,
    required this.update,
    required this.delete,
    required this.statePermission,
  });

  factory ModulePermissions.fromJson(Map<String, dynamic> json) {
    return ModulePermissions(
      create: _parseBool(json['create']),
      read: _parseBool(json['read']),
      update: _parseBool(json['update']),
      delete: _parseBool(json['delete']),
      statePermission: _parseBool(json['state_permission']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }
}
