class HubPostModel {
  final int id;
  final String title;
  final String content;
  final String authorName;
  final String createdAt;
  final List<String> images;
  final int reactionsCount;

  HubPostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    required this.createdAt,
    required this.images,
    required this.reactionsCount,
  });

  factory HubPostModel.fromJson(Map<String, dynamic> json) {
    final rawPostId = json['id'] ?? json['id_post'] ?? 0;
    final id = rawPostId is int
        ? rawPostId
        : int.tryParse(rawPostId.toString()) ?? 0;
    final title = (json['title'] ?? json['text'] ?? json['content'] ?? '')
        .toString();
    final content = (json['content'] ?? json['text'] ?? '').toString();
    String authorName = '';
    final directAuthorCandidates = <dynamic>[
      json['author_name'],
      json['authorName'],
      json['name_user'],
      json['creator_name'],
      json['created_by_name'],
      json['employee_name'],
      json['model_name'],
      json['full_name'],
      json['name'],
    ];
    for (final candidate in directAuthorCandidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        authorName = value;
        break;
      }
    }

    if (authorName.isEmpty) {
      final nestedMaps = <Map<String, dynamic>?>[
        json['author'] is Map<String, dynamic>
            ? json['author'] as Map<String, dynamic>
            : null,
        json['user'] is Map<String, dynamic>
            ? json['user'] as Map<String, dynamic>
            : null,
        json['creator'] is Map<String, dynamic>
            ? json['creator'] as Map<String, dynamic>
            : null,
        json['created_by'] is Map<String, dynamic>
            ? json['created_by'] as Map<String, dynamic>
            : null,
        json['employee'] is Map<String, dynamic>
            ? json['employee'] as Map<String, dynamic>
            : null,
        json['model'] is Map<String, dynamic>
            ? json['model'] as Map<String, dynamic>
            : null,
      ];
      for (final nested in nestedMaps) {
        if (nested == null) continue;
        final nestedCandidates = <dynamic>[
          nested['name'],
          nested['full_name'],
          nested['display_name'],
          nested['username'],
        ];
        for (final candidate in nestedCandidates) {
          final value = candidate?.toString().trim() ?? '';
          if (value.isNotEmpty) {
            authorName = value;
            break;
          }
        }
        if (authorName.isNotEmpty) break;
      }
    }
    final createdAt = (json['created_at'] ?? json['date'] ?? '').toString();

    final dynamic imagesRaw = json['images'] ?? json['media'] ?? json['photos'];
    List<String> images = [];
    if (imagesRaw is List) {
      images = imagesRaw
          .map(
            (e) => e is String
                ? e
                : (e is Map<String, dynamic>
                      ? (e['url'] ?? e['src'] ?? '')
                      : ''),
          )
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      final cover = json['cover'] ?? json['image'] ?? json['picture'];
      if (cover is String && cover.isNotEmpty) images = [cover];
    }

    final rawReactionsCount = json['reactions_count'] ?? json['likes'] ?? 0;
    final reactions = json['reactions'] is Map<String, dynamic>
        ? (json['reactions'] as Map<String, dynamic>).values
              .whereType<num>()
              .fold<int>(0, (sum, v) => sum + v.toInt())
        : (rawReactionsCount is int
              ? rawReactionsCount
              : int.tryParse(rawReactionsCount.toString()) ?? 0);

    return HubPostModel(
      id: id,
      title: title,
      content: content,
      authorName: authorName,
      createdAt: createdAt,
      images: images,
      reactionsCount: reactions,
    );
  }
}

class HubCommentModel {
  final int id;
  final String? apiKey; // backend identifier (e.g., UUID)
  final String? authorId;
  final String authorName;
  final String content;
  final String createdAt;
  final int reactionsCount;

  HubCommentModel({
    required this.id,
    required this.authorName,
    required this.content,
    required this.createdAt,
    required this.reactionsCount,
    this.apiKey,
    this.authorId,
  });

  HubCommentModel copyWith({int? reactionsCount}) {
    return HubCommentModel(
      id: id,
      apiKey: apiKey,
      authorId: authorId,
      authorName: authorName,
      content: content,
      createdAt: createdAt,
      reactionsCount: reactionsCount ?? this.reactionsCount,
    );
  }

  factory HubCommentModel.fromJson(Map<String, dynamic> json) {
    final rawCommentId =
        json['id'] ?? json['id_comment'] ?? json['comment_id'] ?? 0;
    final id = rawCommentId is int
        ? rawCommentId
        : int.tryParse(rawCommentId.toString()) ?? 0;
    final String? apiKey =
        (json['uuid'] ??
                json['uid'] ??
                json['slug'] ??
                json['public_id'] ??
                json['publicId'] ??
                json['comment_uuid'] ??
                json['id_uuid'] ??
                json['id_comment_uuid'] ??
                json['hash'] ??
                json['comment'])
            ?.toString();
    final String? authorIdRaw =
        (json['author_id'] ??
                json['authorId'] ??
                json['user_id'] ??
                json['userId'] ??
                json['employee_id'] ??
                json['employeeId'] ??
                json['model_id'] ??
                json['modelId'] ??
                json['creator_id'] ??
                json['created_by_id'] ??
                (json['author'] is Map<String, dynamic>
                    ? (json['author'] as Map<String, dynamic>)['id']
                    : null) ??
                (json['user'] is Map<String, dynamic>
                    ? (json['user'] as Map<String, dynamic>)['id']
                    : null) ??
                (json['creator'] is Map<String, dynamic>
                    ? (json['creator'] as Map<String, dynamic>)['id']
                    : null) ??
                (json['created_by'] is Map<String, dynamic>
                    ? (json['created_by'] as Map<String, dynamic>)['id']
                    : null) ??
                (json['employee'] is Map<String, dynamic>
                    ? (json['employee'] as Map<String, dynamic>)['id']
                    : null) ??
                (json['model'] is Map<String, dynamic>
                    ? (json['model'] as Map<String, dynamic>)['id']
                    : null))
            ?.toString();

    String authorName = '';
    final directAuthorCandidates = <dynamic>[
      json['author_name'],
      json['authorName'],
      json['name_user'],
      json['name'],
      json['full_name'],
      json['creator_name'],
      json['created_by_name'],
      json['employee_name'],
      json['model_name'],
    ];
    for (final candidate in directAuthorCandidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        authorName = value;
        break;
      }
    }

    if (authorName.isEmpty) {
      final nestedMaps = <Map<String, dynamic>?>[
        json['author'] is Map<String, dynamic>
            ? json['author'] as Map<String, dynamic>
            : null,
        json['user'] is Map<String, dynamic>
            ? json['user'] as Map<String, dynamic>
            : null,
        json['creator'] is Map<String, dynamic>
            ? json['creator'] as Map<String, dynamic>
            : null,
        json['created_by'] is Map<String, dynamic>
            ? json['created_by'] as Map<String, dynamic>
            : null,
        json['employee'] is Map<String, dynamic>
            ? json['employee'] as Map<String, dynamic>
            : null,
        json['model'] is Map<String, dynamic>
            ? json['model'] as Map<String, dynamic>
            : null,
      ];
      for (final nested in nestedMaps) {
        if (nested == null) continue;
        final nestedCandidates = <dynamic>[
          nested['name'],
          nested['name_user'],
          nested['full_name'],
          nested['display_name'],
          nested['username'],
        ];
        for (final candidate in nestedCandidates) {
          final value = candidate?.toString().trim() ?? '';
          if (value.isNotEmpty) {
            authorName = value;
            break;
          }
        }
        if (authorName.isNotEmpty) break;
      }
    }
    final content = (json['content'] ?? json['text'] ?? '').toString();
    final createdAt = (json['created_at'] ?? json['date'] ?? '').toString();

    final rawReactionsCount = json['reactions_count'] ?? json['likes'] ?? 0;
    final reactions = json['reactions'] is Map<String, dynamic>
        ? (json['reactions'] as Map<String, dynamic>).values
              .whereType<num>()
              .fold<int>(0, (sum, v) => sum + v.toInt())
        : (rawReactionsCount is int
              ? rawReactionsCount
              : int.tryParse(rawReactionsCount.toString()) ?? 0);

    return HubCommentModel(
      id: id,
      apiKey: (apiKey != null && apiKey.isNotEmpty) ? apiKey : null,
      authorId: (authorIdRaw != null && authorIdRaw.trim().isNotEmpty)
          ? authorIdRaw.trim()
          : null,
      authorName: authorName.isEmpty ? 'Autor' : authorName,
      content: content,
      createdAt: createdAt,
      reactionsCount: reactions,
    );
  }
}
