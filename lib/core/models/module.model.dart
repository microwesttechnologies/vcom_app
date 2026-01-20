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
      idModule: json['id_module'] as int,
      nameModule: json['name_module'] as String,
      descriptionModule: json['description_module'] as String,
      route: json['route'] as String,
      state: json['state'] as bool,
      icon: json['icon'] as String,
      permissions: ModulePermissions.fromJson(
        json['permissions'] as Map<String, dynamic>,
      ),
    );
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
      create: json['create'] as bool? ?? false,
      read: json['read'] as bool? ?? false,
      update: json['update'] as bool? ?? false,
      delete: json['delete'] as bool? ?? false,
      statePermission: json['state_permission'] as bool? ?? false,
    );
  }
}

