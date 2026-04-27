import 'package:flutter/material.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/user_status.service.dart';
import 'package:vcom_app/pages/hub/hub_helpers.dart';
import 'package:vcom_app/style/vcom_colors.dart';

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
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        decoration: _cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Borde dorado izquierdo
              Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      VcomColors.oroLujoso,
                      VcomColors.oroLujoso.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
              // Contenido principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (images.isNotEmpty) _buildImage(images.first),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(author, createdAt, category),
                          const SizedBox(height: 12),
                          if (title.isNotEmpty) _buildTitle(title),
                          if (_contentText != null) ...[
                            const SizedBox(height: 6),
                            _buildContent(),
                          ],
                          const SizedBox(height: 14),
                          _buildActions(),
                          if (reactionExpandedWidget != null)
                            reactionExpandedWidget!,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      color: const Color(0xFF0D1520),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: VcomColors.oroLujoso.withValues(alpha: 0.12)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildHeader(String author, String createdAt, String category) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: VcomColors.oroLujoso.withValues(alpha: 0.2),
          child: Icon(Icons.person, size: 15, color: VcomColors.oroLujoso),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author.toUpperCase(),
                style: TextStyle(
                  color: VcomColors.oroLujoso,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                relativeTime(createdAt),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (category.isNotEmpty) _buildCategoryBadge(category),
      ],
    );
  }

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: VcomColors.oroLujoso.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VcomColors.oroLujoso.withValues(alpha: 0.3)),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: VcomColors.oroLujoso,
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
        fontSize: 17,
        fontWeight: FontWeight.w800,
        height: 1.3,
      ),
    );
  }

  Widget _buildContent() {
    return Text(
      _contentText!,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.65),
        fontSize: 13,
        height: 1.4,
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onReactionsTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite,
                  size: 18,
                  color: VcomColors.oroLujoso.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                reactionsLabel != null
                    ? Text(
                        reactionsLabel!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : _miniLoader(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onCommentsTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mode_comment_outlined,
                  size: 17,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                commentsCount != null
                    ? Text(
                        '$commentsCount',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : _miniLoader(),
              ],
            ),
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
    return ClipRRect(
      borderRadius: const BorderRadius.only(topRight: Radius.circular(15)),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              color: const Color(0xFF1A2740),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: VcomColors.oroLujoso.withValues(alpha: 0.5),
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
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
