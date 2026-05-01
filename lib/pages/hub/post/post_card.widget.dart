import 'package:flutter/material.dart';
import 'package:vcom_app/core/hub/hub_post_media.dart';
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
    final images = extractPostImageUrls(post);
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
                    if (images.isNotEmpty) _buildMediaPreview(images),
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

  static const double _mediaAspect = 4 / 3;
  static const double _gridGap = 2;

  Widget _buildMediaPreview(List<String> urls) {
    final n = urls.length;
    if (n == 1) return _buildSingleImage(urls.first);
    if (n == 2) return _buildTwoImagesRow(urls);
    if (n == 3) return _buildThreeImagesRow(urls);
    return _buildFourQuadrantGrid(urls);
  }

  Widget _buildSingleImage(String url) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(topRight: Radius.circular(15)),
      child: AspectRatio(
        aspectRatio: _mediaAspect,
        child: _buildNetworkImage(url),
      ),
    );
  }

  /// Dos recursos: 50% · 50% (ancho).
  Widget _buildTwoImagesRow(List<String> urls) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(topRight: Radius.circular(15)),
      child: AspectRatio(
        aspectRatio: _mediaAspect,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: ClipRect(child: _buildNetworkImage(urls[0])),
            ),
            SizedBox(width: _gridGap),
            Expanded(
              flex: 1,
              child: ClipRect(child: _buildNetworkImage(urls[1])),
            ),
          ],
        ),
      ),
    );
  }

  /// Tres recursos: mitad izquierda con dos miniaturas apiladas (25%+25% del área),
  /// mitad derecha una miniatura a altura completa (50% del ancho).
  Widget _buildThreeImagesRow(List<String> urls) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(topRight: Radius.circular(15)),
      child: AspectRatio(
        aspectRatio: _mediaAspect,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(
                    child: ClipRect(child: _buildNetworkImage(urls[0])),
                  ),
                  SizedBox(height: _gridGap),
                  Expanded(
                    child: ClipRect(child: _buildNetworkImage(urls[1])),
                  ),
                ],
              ),
            ),
            SizedBox(width: _gridGap),
            Expanded(
              flex: 1,
              child: ClipRect(child: _buildNetworkImage(urls[2])),
            ),
          ],
        ),
      ),
    );
  }

  /// Cuatro o más: cuadrícula 2×2 (máx. 4 miniaturas); "+N" abajo a la derecha si hay más.
  Widget _buildFourQuadrantGrid(List<String> urls) {
    final total = urls.length;
    final visible = urls.take(4).toList(growable: false);
    final extra = total > 4 ? total - 4 : 0;

    return ClipRRect(
      borderRadius: const BorderRadius.only(topRight: Radius.circular(15)),
      child: AspectRatio(
        aspectRatio: _mediaAspect,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _gridCell(visible, 0)),
                  SizedBox(width: _gridGap),
                  Expanded(child: _gridCell(visible, 1)),
                ],
              ),
            ),
            SizedBox(height: _gridGap),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _gridCell(visible, 2)),
                  SizedBox(width: _gridGap),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.hardEdge,
                      children: [
                        _gridCell(visible, 3),
                        if (extra > 0)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: _moreResourcesBadge(extra),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridCell(List<String> visible, int index) {
    if (index < visible.length) {
      return ClipRect(
        child: _buildNetworkImage(visible[index]),
      );
    }
    return ColoredBox(color: const Color(0xFF1A2740));
  }

  Widget _moreResourcesBadge(int n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: VcomColors.oroLujoso.withValues(alpha: 0.55),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '+$n',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _buildNetworkImage(String url) {
    final headers = hubImageRequestHeadersForUrl(url, TokenService());
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      headers: headers,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFF1A2740),
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: VcomColors.oroLujoso.withValues(alpha: 0.5),
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[Hub PostCard] Error cargando imagen: $url | $error');
        return Container(
          color: const Color(0xFF1A2740),
          alignment: Alignment.center,
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 28,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        );
      },
    );
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
