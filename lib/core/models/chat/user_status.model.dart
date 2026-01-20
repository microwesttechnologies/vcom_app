/// Modelo de estado de usuario
class UserStatusModel {
  final String idUser; // Cambiado a String porque el backend usa UUID
  final String userName;
  final String? userAvatar;
  final String status; // 'online', 'offline', 'away'
  final DateTime? lastSeen; // Última vez visto (si está offline)
  final bool isActive; // Si está activo (solo para modelos)

  UserStatusModel({
    required this.idUser,
    required this.userName,
    this.userAvatar,
    this.status = 'offline',
    this.lastSeen,
    this.isActive = true,
  });

  factory UserStatusModel.fromJson(Map<String, dynamic> json) {
    return UserStatusModel(
      idUser: json['id_user']?.toString() ?? 
              json['id']?.toString() ?? '',
      userName: json['user_name'] as String? ?? json['name'] as String? ?? 'Usuario',
      userAvatar: json['user_avatar'] as String? ?? json['avatar'] as String?,
      status: json['status'] as String? ?? 'offline',
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'user_name': userName,
      'user_avatar': userAvatar,
      'status': status,
      'last_seen': lastSeen?.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Obtiene el texto descriptivo del estado
  String get statusText {
    switch (status.toLowerCase()) {
      case 'online':
        return 'En línea';
      case 'away':
        return 'Ausente';
      case 'offline':
        return 'Desconectado';
      default:
        return 'Desconectado';
    }
  }

  /// Obtiene el color del indicador de estado
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'online':
        return 'green';
      case 'away':
        return 'orange';
      case 'offline':
        return 'grey';
      default:
        return 'grey';
    }
  }
}
