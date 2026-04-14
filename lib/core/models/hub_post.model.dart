import 'package:vcom_app/core/models/hub_author.model.dart';
import 'package:vcom_app/core/models/hub_media.model.dart';
import 'package:vcom_app/core/models/hub_tag.model.dart';

class HubPostModel {
  final int id;
  final HubAuthorModel author;
  final HubTagModel tag;
  final String content;
  final List<HubMediaModel> media;
  final int reactionsCount;
  final int commentsCount;
  final DateTime createdAt;
  final bool reactedByMe;

  const HubPostModel({
    required this.id,
    required this.author,
    required this.tag,
    required this.content,
    required this.media,
    required this.reactionsCount,
    required this.commentsCount,
    required this.createdAt,
    this.reactedByMe = false,
  });

  HubPostModel copyWith({
    int? id,
    HubAuthorModel? author,
    HubTagModel? tag,
    String? content,
    List<HubMediaModel>? media,
    int? reactionsCount,
    int? commentsCount,
    DateTime? createdAt,
    bool? reactedByMe,
  }) {
    return HubPostModel(
      id: id ?? this.id,
      author: author ?? this.author,
      tag: tag ?? this.tag,
      content: content ?? this.content,
      media: media ?? this.media,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      reactedByMe: reactedByMe ?? this.reactedByMe,
    );
  }

  factory HubPostModel.fromJson(Map<String, dynamic> json) {
    final mediaList = (json['media'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(HubMediaModel.fromJson)
        .toList(growable: false);

    return HubPostModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      author: HubAuthorModel.fromJson(
        (json['author'] as Map<String, dynamic>?) ?? const {},
      ),
      tag: HubTagModel.fromJson(
        (json['tag'] as Map<String, dynamic>?) ?? const {},
      ),
      content: (json['content'] ?? '').toString(),
      media: mediaList,
      reactionsCount: (json['reactions_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      reactedByMe: json['reacted_by_me'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author.toJson(),
      'tag': tag.toJson(),
      'content': content,
      'media': media.map((item) => item.toJson()).toList(growable: false),
      'reactions_count': reactionsCount,
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
      'reacted_by_me': reactedByMe,
    };
  }
}

class HubPostPageResult {
  final List<HubPostModel> data;
  final int currentPage;
  final int perPage;
  final bool hasMore;

  const HubPostPageResult({
    required this.data,
    required this.currentPage,
    required this.perPage,
    required this.hasMore,
  });
}
