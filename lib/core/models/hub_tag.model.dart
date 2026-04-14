class HubTagModel {
  final int id;
  final String name;
  final String slug;
  final bool isActive;

  const HubTagModel({
    required this.id,
    required this.name,
    required this.slug,
    this.isActive = true,
  });

  HubTagModel copyWith({int? id, String? name, String? slug, bool? isActive}) {
    return HubTagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      isActive: isActive ?? this.isActive,
    );
  }

  factory HubTagModel.fromJson(Map<String, dynamic> json) {
    return HubTagModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug, 'is_active': isActive};
  }
}
