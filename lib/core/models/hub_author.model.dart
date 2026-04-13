class HubAuthorModel {
  final String id;
  final String type;
  final String name;
  final String role;
  final String? avatarUrl;

  const HubAuthorModel({
    required this.id,
    required this.type,
    required this.name,
    required this.role,
    this.avatarUrl,
  });

  HubAuthorModel copyWith({
    String? id,
    String? type,
    String? name,
    String? role,
    String? avatarUrl,
  }) {
    return HubAuthorModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory HubAuthorModel.fromJson(Map<String, dynamic> json) {
    return HubAuthorModel(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'role': role,
      'avatar_url': avatarUrl,
    };
  }
}
