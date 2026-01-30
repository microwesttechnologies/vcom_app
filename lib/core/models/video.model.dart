/// Modelo de categoría de video
class CategoryVideoModel {
  final int idCategoryVideo;
  final String nameCategoryVideo;
  final String? descriptionCategoryVideo;
  final String? icon;
  final bool stateCategoryVideo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CategoryVideoModel({
    required this.idCategoryVideo,
    required this.nameCategoryVideo,
    this.descriptionCategoryVideo,
    this.icon,
    this.stateCategoryVideo = true,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryVideoModel.fromJson(Map<String, dynamic> json) {
    return CategoryVideoModel(
      idCategoryVideo: json['id_category_video'] as int,
      nameCategoryVideo: json['name_category_video'] as String? ?? '',
      descriptionCategoryVideo: json['description_category_video'] as String?,
      icon: json['icon'] as String?,
      stateCategoryVideo: json['state_category_video'] as bool? ?? true,
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
      'id_category_video': idCategoryVideo,
      'name_category_video': nameCategoryVideo,
      'description_category_video': descriptionCategoryVideo,
      'icon': icon,
      'state_category_video': stateCategoryVideo,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Modelo de video
class VideoModel {
  final int idVideo;
  final String titleVideo;
  final String? subtitleVideo;
  final String? description;
  final String urlSource;
  final int? idCategoryVideo;
  final CategoryVideoModel? categoryVideo;
  final String idUser;
  final bool stateVideo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VideoModel({
    required this.idVideo,
    required this.titleVideo,
    this.subtitleVideo,
    this.description,
    required this.urlSource,
    this.idCategoryVideo,
    this.categoryVideo,
    required this.idUser,
    this.stateVideo = true,
    this.createdAt,
    this.updatedAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      idVideo: json['id_video'] as int,
      titleVideo: json['title_video'] as String? ?? '',
      subtitleVideo: json['subtitle_video'] as String?,
      description: json['description'] as String?,
      urlSource: json['url_source'] as String? ?? '',
      idCategoryVideo: json['id_category_video'] as int?,
      categoryVideo: json['category_video'] != null
          ? CategoryVideoModel.fromJson(json['category_video'] as Map<String, dynamic>)
          : null,
      idUser: json['id_user'] as String? ?? '',
      stateVideo: json['state_video'] as bool? ?? true,
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
      'id_video': idVideo,
      'title_video': titleVideo,
      'subtitle_video': subtitleVideo,
      'description': description,
      'url_source': urlSource,
      'id_category_video': idCategoryVideo,
      'category_video': categoryVideo?.toJson(),
      'id_user': idUser,
      'state_video': stateVideo,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
