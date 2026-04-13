enum HubMediaType { image, video }

class HubMediaModel {
  final String id;
  final HubMediaType type;
  final String url;
  final String? thumbnailUrl;
  final String? mimeType;
  final int? fileSize;
  final int sortOrder;
  final bool isLocal;

  const HubMediaModel({
    required this.id,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.mimeType,
    this.fileSize,
    this.sortOrder = 0,
    this.isLocal = false,
  });

  HubMediaModel copyWith({
    String? id,
    HubMediaType? type,
    String? url,
    String? thumbnailUrl,
    String? mimeType,
    int? fileSize,
    int? sortOrder,
    bool? isLocal,
  }) {
    return HubMediaModel(
      id: id ?? this.id,
      type: type ?? this.type,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      sortOrder: sortOrder ?? this.sortOrder,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  factory HubMediaModel.fromJson(Map<String, dynamic> json) {
    final typeValue = (json['type'] ?? '').toString().toLowerCase();
    final mediaType = typeValue == 'video'
        ? HubMediaType.video
        : HubMediaType.image;

    return HubMediaModel(
      id: (json['id'] ?? '').toString(),
      type: mediaType,
      url: (json['file_url'] ?? json['url'] ?? '').toString(),
      thumbnailUrl: json['thumbnail_url'] as String?,
      mimeType: json['mime_type'] as String?,
      fileSize: (json['file_size'] as num?)?.toInt(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isLocal: json['is_local'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'file_url': url,
      'thumbnail_url': thumbnailUrl,
      'mime_type': mimeType,
      'file_size': fileSize,
      'sort_order': sortOrder,
      'is_local': isLocal,
    };
  }
}
