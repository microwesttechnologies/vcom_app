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
    final id = (json['id'] ?? json['id_post'] ?? 0) as int;
    final title = (json['title'] ?? json['text'] ?? json['content'] ?? '')
        .toString();
    final content = (json['content'] ?? json['text'] ?? '').toString();
    final authorName =
        (json['author']?['name'] ??
                json['user']?['name'] ??
                json['author_name'] ??
                '')
            .toString();
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

    final reactions = json['reactions'] is Map<String, dynamic>
        ? (json['reactions'] as Map<String, dynamic>).values
              .whereType<num>()
              .fold<int>(0, (sum, v) => sum + v.toInt())
        : (json['reactions_count'] ?? json['likes'] ?? 0) as int;

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
  });

  factory HubCommentModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['id_comment'] ?? 0) as int;
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
    final authorName =
        (json['author']?['name'] ??
                json['user']?['name'] ??
                json['author_name'] ??
                '')
            .toString();
    final content = (json['content'] ?? json['text'] ?? '').toString();
    final createdAt = (json['created_at'] ?? json['date'] ?? '').toString();

    final reactions = json['reactions'] is Map<String, dynamic>
        ? (json['reactions'] as Map<String, dynamic>).values
              .whereType<num>()
              .fold<int>(0, (sum, v) => sum + v.toInt())
        : (json['reactions_count'] ?? json['likes'] ?? 0) as int;

    return HubCommentModel(
      id: id,
      apiKey: (apiKey != null && apiKey.isNotEmpty) ? apiKey : null,
      authorName: authorName,
      content: content,
      createdAt: createdAt,
      reactionsCount: reactions,
    );
  }
}
