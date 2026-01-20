/// Modelo de categoría
class CategoryModel {
  final int idCategory;
  final String nameCategory;
  final String? descriptionCategory;
  final String? icon;
  final bool stateCategory;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CategoryModel({
    required this.idCategory,
    required this.nameCategory,
    this.descriptionCategory,
    this.icon,
    this.stateCategory = true,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      idCategory: json['id_category'] as int? ?? 0,
      nameCategory: json['name_category'] as String? ?? '',
      descriptionCategory: json['description_category'] as String?,
      icon: json['icon'] as String?,
      stateCategory: json['state_category'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_category': idCategory,
      'name_category': nameCategory,
      'description_category': descriptionCategory,
      'icon': icon,
      'state_category': stateCategory,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

