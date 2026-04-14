import 'package:equatable/equatable.dart';

/// Modelo para Comentarios en Posts
class CommentModel extends Equatable {
  final int id;
  final int postId;
  final String content;
  final UserModel author;
  final DateTime createdAt;
  final int likesCount;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.likesCount,
  });

  // fromJson: Deserializar desde respuesta de API
  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      content: json['content'] as String,
      author: UserModel.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      likesCount: json['likes_count'] as int? ?? 0,
    );
  }

  // toJson: Serializar para enviar al backend
  Map<String, dynamic> toJson() {
    return {'post_id': postId, 'content': content};
  }

  @override
  List<Object?> get props => [
    id,
    postId,
    content,
    author,
    createdAt,
    likesCount,
  ];
}

/// Modelo para Reacciones (likes)
class ReactionModel extends Equatable {
  final int id;
  final int postId;
  final int? commentId;
  final int userId;
  final String type; // like, love, haha, wow, sad, angry
  final DateTime createdAt;

  const ReactionModel({
    required this.id,
    required this.postId,
    this.commentId,
    required this.userId,
    required this.type,
    required this.createdAt,
  });

  // fromJson
  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      commentId: json['comment_id'] as int?,
      userId: json['user_id'] as int,
      type: json['type'] as String? ?? 'like',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // toJson
  Map<String, dynamic> toJson() {
    return {'post_id': postId, 'comment_id': commentId, 'type': type};
  }

  @override
  List<Object?> get props => [id, postId, commentId, userId, type, createdAt];
}

/// Modelo de Usuario (para embeber en otros modelos)
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

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'avatar_url': avatarUrl};
  }

  @override
  List<Object?> get props => [id, name, avatarUrl];
}
