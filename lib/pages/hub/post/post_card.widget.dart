import 'package:flutter/material.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/user_status.service.dart';
import 'package:vcom_app/pages/hub/hub_helpers.dart';

/// Widget que renderiza una tarjeta individual de post.
class PostCardWidget extends StatelessWidget {
  const PostCardWidget({
    required this.post,
    required this.onReactionsTap,
    required this.onCommentsTap,
    required this.reactionExpandedWidget,
    this.reactionsLabel,
    this.commentsCount,
    super.key,
  });

  final Map<String, dynamic> post;

  /// Null = still loading, non-null = ready.
  final String? reactionsLabel;

  /// Null = still loading, non-null = ready.
  final int? commentsCount;
  final VoidCallback onReactionsTap;
  final VoidCallback onCommentsTap;
  final Widget? reactionExpandedWidget;

  @override
  Widget build(BuildContext context) {
    final author = resolvePostAuthorName(
      post,
      TokenService(),
      UserStatusService(),
    );
    final title = (post['title_post'] ?? post['title'] ?? '').toString();
    final createdAt = (post['created_at'] ?? post['date'] ?? '').toString();
    final images = _extractImages(post);
    final category = _extractCategory(post);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty) _buildImage(images.first),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(author, createdAt, category),
                  const SizedBox(height: 8),
                  if (title.isNotEmpty) _buildTitle(title),
                  if (_contentText != null) ...[
                    const SizedBox(height: 6),
                    _buildContent(),
                  ],
                  const SizedBox(height: 10),
                  _buildActions(),
                  if (reactionExpandedWidget != null) reactionExpandedWidget!,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? get _contentText {
    final raw = post['content'] ?? post['text'];
    return raw?.toString();
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color.fromARGB(255, 12, 12, 12),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _buildHeader(String author, String createdAt, String category) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: const Icon(Icons.person, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${author.toUpperCase()} · ${relativeTime(createdAt)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (category.isNotEmpty) ...[
          const SizedBox(width: 10),
          _buildCategoryBadge(category),
        ],
      ],
    );
  }

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1729),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        height: 1.25,
      ),
    );
  }

  Widget _buildContent() {
    return Text(
      _contentText!,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.80),
        fontSize: 12,
        height: 1.35,
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onReactionsTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_border,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              reactionsLabel != null
                  ? Text(
                      reactionsLabel!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : _miniLoader(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onCommentsTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mode_comment_outlined,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              commentsCount != null
                  ? Text(
                      '$commentsCount',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : _miniLoader(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniLoader() {
    return SizedBox(
      width: 12,
      height: 12,
      child: CircularProgressIndicator(
        strokeWidth: 1.5,
        color: Colors.white.withValues(alpha: 0.45),
      ),
    );
  }

  Widget _buildImage(String url) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: const Color(0xFF1A2740),
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 52,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static List<String> _extractImages(Map<String, dynamic> post) {
    final dynamic images = post['images'] ?? post['media'] ?? post['photos'];
    if (images is List) {
      return images
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
    }
    final cover = post['cover'] ?? post['image'] ?? post['picture'];
    if (cover is String && cover.isNotEmpty) return [cover];
    return const [];
  }

  static String _extractCategory(Map<String, dynamic> post) {
    final dynamic catRaw = post['tag'] ?? post['category'] ?? post['label'];
    if (catRaw is Map<String, dynamic>) {
      return (catRaw['name'] ?? catRaw['title'] ?? catRaw['slug'] ?? '')
          .toString()
          .trim();
    }
    return (catRaw ?? '').toString().trim();
  }
}
