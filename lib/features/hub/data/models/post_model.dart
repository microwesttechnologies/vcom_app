// PHASE 5: Modelado de Datos
// Ubicación: lib/features/hub/data/models/post_model.dart

import 'package:equatable/equatable.dart';

class PostModel extends Equatable {
  final int id;
  final String title;
  final String content;
  final UserModel author;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final int commentsCount;
  final String visibility;

  const PostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
    required this.likesCount,
    required this.commentsCount,
    required this.visibility,
  });

  // PHASE 5: Implementar en FASE 5
  // fromJson debe deserializar la respuesta del backend
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      author: UserModel.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      visibility: json['visibility'] as String? ?? 'public',
    );
  }

  // toJson para enviar post al backend (crear/actualizar)
  Map<String, dynamic> toJson() {
    return {'title': title, 'content': content, 'visibility': visibility};
  }

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    author,
    createdAt,
    updatedAt,
    likesCount,
    commentsCount,
    visibility,
  ];
}

// PHASE 5: Crear también
// user_model.dart
// comment_model.dart
// reaction_model.dart
// api_response_model.dart

class UserModel extends Equatable {
  final int id;
  final String name;
  final String? avatarUrl;

  const UserModel({required this.id, required this.name, this.avatarUrl});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, avatarUrl];
}
