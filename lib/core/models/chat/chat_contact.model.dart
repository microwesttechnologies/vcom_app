class ChatContactModel {
  final String idUser;
  final String nameUser;
  final String roleUser;
  final bool isOnline;

  ChatContactModel({
    required this.idUser,
    required this.nameUser,
    required this.roleUser,
    required this.isOnline,
  });

  factory ChatContactModel.fromJson(Map<String, dynamic> json) {
    return ChatContactModel(
      idUser: (json['id_user'] ?? json['id'] ?? '').toString(),
      nameUser: (json['name_user'] ?? json['name'] ?? 'Sin nombre').toString(),
      roleUser: (json['role_user'] ?? json['role'] ?? '').toString(),
      isOnline: json['is_online'] == true,
    );
  }
}
