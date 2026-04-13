import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/modelo_menubar.dart';
import 'package:vcom_app/core/models/hub_comment.model.dart';
import 'package:vcom_app/core/models/hub_media.model.dart';
import 'package:vcom_app/core/models/hub_post.model.dart';
import 'package:vcom_app/core/models/hub_tag.model.dart';
import 'package:vcom_app/pages/hub/create_post.page.dart';
import 'package:vcom_app/pages/hub/hub.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class HubPage extends StatefulWidget {
  const HubPage({super.key});

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {
  final HubComponent _component = HubComponent();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _component.addListener(_onChanged);
    _component.initialize();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _component.removeListener(_onChanged);
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;

    final threshold = position.maxScrollExtent * 0.8;
    if (position.pixels >= threshold) {
      _component.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      bottomNavigationBar: const ModeloMenuBar(activeRoute: 'hub'),
      floatingActionButton: _component.canCreatePosts
          ? Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: FloatingActionButton(
                onPressed: _openCreatePost,
                backgroundColor: VcomColors.oroLujoso,
                foregroundColor: VcomColors.azulMedianocheTexto,
                shape: const CircleBorder(),
                elevation: 8,
                child: const Icon(Icons.add, size: 34),
              ),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.8),
            radius: 1.2,
            colors: [
              Color(0xFF273C67),
              Color(0xFF1a2847),
              Color(0xFF0d1525),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildFeed()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              _HeaderDot(),
              SizedBox(width: 8),
              Text(
                'Chismes del studio',
                style: TextStyle(
                  color: VcomColors.blancoCrema,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                color: VcomColors.blancoCrema,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Buscar chisme...',
                hintStyle: TextStyle(
                  color: VcomColors.blancoCrema.withValues(alpha: 0.35),
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: VcomColors.blancoCrema.withValues(alpha: 0.55),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: _component.onSearchChanged,
            ),
          ),
          const SizedBox(height: 12),
          _buildTags(),
          const SizedBox(height: 10),
          Container(
            height: 3,
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    final tags = [
      const HubTagModel(id: 0, name: 'Todos los Articulos', slug: 'all'),
      ..._component.tags,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags
            .map((tag) {
              final isAll = tag.id == 0;
              final isSelected = isAll
                  ? _component.selectedTagId == null
                  : _component.selectedTagId == tag.id;

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: () => _component.setSelectedTag(isAll ? null : tag.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: isSelected
                          ? VcomColors.oroLujoso.withValues(alpha: 0.08)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? VcomColors.oroLujoso
                            : Colors.white.withValues(alpha: 0.28),
                        width: 1.1,
                      ),
                    ),
                    child: Text(
                      tag.name,
                      style: TextStyle(
                        color: isSelected
                            ? VcomColors.oroLujoso
                            : Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildFeed() {
    if (_component.isLoading && _component.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: VcomColors.oroLujoso),
      );
    }

    if (_component.error != null && _component.posts.isEmpty) {
      return _buildErrorState(_component.error!);
    }

    if (_component.posts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _component.refresh,
      color: VcomColors.oroLujoso,
      backgroundColor: const Color(0xFF071325),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
        itemCount: _component.posts.length + (_component.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _component.posts.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: VcomColors.oroLujoso),
              ),
            );
          }

          final post = _component.posts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _HubPostCard(
              post: post,
              onToggleReaction: () => _component.toggleReaction(post.id),
              onOpenComments: () => _openCommentsSheet(post),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: VcomColors.error, size: 42),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: VcomColors.blancoCrema.withValues(alpha: 0.85),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: _component.refresh,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: VcomColors.oroLujoso),
                foregroundColor: VcomColors.oroLujoso,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.feed_outlined,
            color: Colors.white.withValues(alpha: 0.5),
            size: 44,
          ),
          const SizedBox(height: 8),
          Text(
            'No hay publicaciones para este filtro',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreatePost() async {
    final result = await Navigator.push<HubPostModel>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostPage()),
    );
    if (result == null) return;
    await _component.refresh();
  }

  Future<void> _openCommentsSheet(HubPostModel post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HubCommentsSheet(post: post, component: _component),
    );
  }
}

class _HeaderDot extends StatelessWidget {
  const _HeaderDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: VcomColors.oroLujoso,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HubPostCard extends StatelessWidget {
  const _HubPostCard({
    required this.post,
    required this.onToggleReaction,
    required this.onOpenComments,
  });

  final HubPostModel post;
  final VoidCallback onToggleReaction;
  final VoidCallback onOpenComments;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: VcomColors.oroLujoso.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: VcomColors.oroLujoso,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopRow(),
                const SizedBox(height: 10),
                Text(
                  post.content,
                  style: const TextStyle(
                    color: VcomColors.blancoCrema,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                if (post.media.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _PostMediaViewer(media: post.media),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      post.reactedByMe ? Icons.favorite : Icons.favorite_border,
                      color: post.reactedByMe
                          ? VcomColors.oroBrillante
                          : Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.reactionsCount}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.commentsCount}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onToggleReaction,
                        icon: Icon(
                          post.reactedByMe
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: post.reactedByMe
                              ? VcomColors.oroLujoso
                              : Colors.white.withValues(alpha: 0.85),
                          size: 18,
                        ),
                        label: Text(
                          'Me gusta',
                          style: TextStyle(
                            color: post.reactedByMe
                                ? VcomColors.oroLujoso
                                : Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onOpenComments,
                        icon: Icon(
                          Icons.mode_comment_outlined,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: 18,
                        ),
                        label: Text(
                          'Comentar',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: VcomColors.oroLujoso.withValues(alpha: 0.2),
          child: Text(
            post.author.name.isNotEmpty
                ? post.author.name.substring(0, 1).toUpperCase()
                : '?',
            style: const TextStyle(
              color: VcomColors.blancoCrema,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${post.author.name.toUpperCase()} - ${_timeAgo(post.createdAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: VcomColors.oroLujoso.withValues(alpha: 0.95),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          post.tag.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PostMediaViewer extends StatefulWidget {
  const _PostMediaViewer({required this.media});
  final List<HubMediaModel> media;

  @override
  State<_PostMediaViewer> createState() => _PostMediaViewerState();
}

class _PostMediaViewerState extends State<_PostMediaViewer> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.media.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (_, idx) => _buildItem(widget.media[idx]),
            ),
          ),
        ),
        if (widget.media.length > 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.media.length, (idx) {
              final isActive = idx == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? VcomColors.oroLujoso
                      : Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildItem(HubMediaModel media) {
    if (media.type == HubMediaType.video) {
      return Container(
        color: const Color(0xFF121212),
        alignment: Alignment.center,
        child: const Icon(
          Icons.play_circle_fill_rounded,
          color: VcomColors.oroLujoso,
          size: 56,
        ),
      );
    }

    if (media.isLocal) {
      return Image.file(
        File(media.url),
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => Container(
          color: const Color(0xFF121212),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined, color: Colors.white54),
        ),
      );
    }

    return Image.network(
      media.url,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFF121212),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: VcomColors.oroLujoso),
        );
      },
      errorBuilder: (_, error, stackTrace) => Container(
        color: const Color(0xFF121212),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, color: Colors.white54),
      ),
    );
  }
}

class _HubCommentsSheet extends StatefulWidget {
  const _HubCommentsSheet({required this.post, required this.component});

  final HubPostModel post;
  final HubComponent component;

  @override
  State<_HubCommentsSheet> createState() => _HubCommentsSheetState();
}

class _HubCommentsSheetState extends State<_HubCommentsSheet> {
  static const int _perPage = 10;

  final TextEditingController _commentController = TextEditingController();
  final List<HubCommentModel> _comments = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.74,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF071326),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Comentarios',
                style: TextStyle(
                  color: VcomColors.blancoCrema.withValues(alpha: 0.96),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
              Expanded(child: _buildCommentsList(controller)),
              _buildComposer(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentsList(ScrollController controller) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: VcomColors.oroLujoso),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Text(
          'Aun no hay comentarios. Se el primero en escribir.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: _comments.length + (_hasMore || _isLoadingMore ? 1 : 0),
      itemBuilder: (_, index) {
        if (index >= _comments.length) {
          if (_isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: VcomColors.oroLujoso,
                    strokeWidth: 2.2,
                  ),
                ),
              ),
            );
          }

          return TextButton(
            onPressed: _loadMore,
            child: const Text(
              'Ver mas comentarios',
              style: TextStyle(color: VcomColors.oroLujoso),
            ),
          );
        }

        final comment = _comments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: VcomColors.oroLujoso.withValues(alpha: 0.2),
                child: Text(
                  comment.author.name.isNotEmpty
                      ? comment.author.name.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: VcomColors.blancoCrema,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${comment.author.name} - ${_timeAgo(comment.createdAt)}',
                        style: TextStyle(
                          color: VcomColors.oroLujoso.withValues(alpha: 0.94),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.content,
                        style: const TextStyle(
                          color: VcomColors.blancoCrema,
                          fontSize: 14,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        10 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF050D19),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: VcomColors.blancoCrema),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
              decoration: InputDecoration(
                hintText: 'Escribe un comentario...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                ),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.45),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: VcomColors.oroLujoso),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 42,
            height: 42,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitComment,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                backgroundColor: VcomColors.oroLujoso,
                foregroundColor: VcomColors.azulMedianocheTexto,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: VcomColors.azulMedianocheTexto,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 19),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _comments.clear();
      _page = 1;
      _hasMore = true;
    });

    final result = await widget.component.loadComments(
      postId: widget.post.id,
      page: _page,
      perPage: _perPage,
    );

    if (!mounted) return;
    setState(() {
      _comments.addAll(result.data);
      _hasMore = result.hasMore;
      _isLoading = false;
      if (result.data.isNotEmpty) _page += 1;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final result = await widget.component.loadComments(
      postId: widget.post.id,
      page: _page,
      perPage: _perPage,
    );
    if (!mounted) return;

    setState(() {
      _comments.addAll(result.data);
      _hasMore = result.hasMore;
      _isLoadingMore = false;
      if (result.data.isNotEmpty) _page += 1;
    });
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final created = await widget.component.addComment(
      postId: widget.post.id,
      content: content,
    );
    if (!mounted) return;

    if (created != null) {
      _commentController.clear();
      setState(() {
        _comments.add(created);
      });
    }
    setState(() => _isSubmitting = false);
  }
}

String _timeAgo(DateTime value) {
  final now = DateTime.now();
  final diff = now.difference(value);
  if (diff.inSeconds < 60) return 'Hace ${diff.inSeconds}s';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
  if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
  if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
