import 'package:vcom_app/core/models/hub_author.model.dart';

class HubCommentModel {
  final int id;
  final int postId;
  final HubAuthorModel author;
  final String content;
  final DateTime createdAt;

  const HubCommentModel({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  HubCommentModel copyWith({
    int? id,
    int? postId,
    HubAuthorModel? author,
    String? content,
    DateTime? createdAt,
  }) {
    return HubCommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      author: author ?? this.author,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory HubCommentModel.fromJson(Map<String, dynamic> json) {
    return HubCommentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      postId: (json['post_id'] as num?)?.toInt() ?? 0,
      author: HubAuthorModel.fromJson(
        (json['author'] as Map<String, dynamic>?) ?? const {},
      ),
      content: (json['content'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'author': author.toJson(),
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
