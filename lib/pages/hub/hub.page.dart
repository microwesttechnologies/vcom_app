import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/modelo_menubar.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/pages/hub/comments_by_post/comments_by_post.page.dart';
import 'package:vcom_app/pages/hub/hub.component.dart';
import 'package:vcom_app/pages/hub/post/post.component.dart';
import 'package:vcom_app/pages/hub/post/post.page.dart';
import 'package:vcom_app/pages/hub/post/post_card.widget.dart';
import 'package:vcom_app/pages/hub/reaction_by_post/reaction_by_post.page.dart';
import 'package:vcom_app/pages/hub/tags/tags.page.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class HubPage extends StatefulWidget {
  const HubPage({super.key});

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> with WidgetsBindingObserver {
  static final HubComponent _component = HubComponent();
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _expandedPostReactions = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _component.addListener(_onChanged);
    _component.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _component.removeListener(_onChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_component.isCacheValid) {
      _component.initialize(force: true);
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  // ── Crear post ─────────────────────────────────────────────

  Future<void> _openCreatePostSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E1729),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CreatePostSheet(
        postComponent: PostComponent(),
        tags: _component.tags,
        initialTag: _component.selectedTag,
      ),
    );
    if (result == true) await _component.refresh();
  }

  // ── Comentarios ────────────────────────────────────────────

  Future<void> _openCommentsSheet(int postId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E1729),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => CommentsSheet(
        postId: postId,
        component: _component,
        rootMessenger: ScaffoldMessenger.of(context),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: const ModeloNavbar(),
      bottomNavigationBar: const ModeloMenuBar(activeRoute: 'hub'),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePostSheet,
        backgroundColor: VcomColors.oroLujoso,
        foregroundColor: VcomColors.azulMedianocheTexto,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
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
          child: RefreshIndicator(
            onRefresh: _component.refresh,
            color: VcomColors.oroLujoso,
            backgroundColor: VcomColors.azulZafiroProfundo,
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_component.isLoading && _component.posts.isEmpty) {
      return _buildLoading();
    }
    if (_component.error != null && _component.posts.isEmpty) {
      return _buildError();
    }
    final list = _component.posts.isEmpty
        ? <Map<String, dynamic>>[]
        : _applyUiFilters(_component.posts);
    final hasItems = list.isNotEmpty;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      itemCount: hasItems ? list.length + 2 : 3,
      itemBuilder: (_, index) {
        if (index == 0) return _buildSearchBar();
        if (index == 1) {
          return TagsChipsRow(
            tags: _component.tags,
            selectedTag: _component.selectedTag,
            onSelected: (tag) => _component.selectTag(tag),
          );
        }
        if (!hasItems) return _buildEmpty();
        return _buildPostItem(list[index - 2]);
      },
    );
  }

  // ── Sub-widgets de estado ──────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 60),
        child: CircularProgressIndicator(color: VcomColors.oroLujoso),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.newspaper, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _component.error ?? 'Error al cargar publicaciones',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.newspaper_outlined,
              size: 56,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay publicaciones disponibles',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Barra de búsqueda ──────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A2740).withValues(alpha: 0.72),
              const Color(0xFF0E1729).withValues(alpha: 0.72),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: Colors.white.withValues(alpha: 0.6),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar chisme...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 14,
                  ),
                  isDense: true,
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Post card con reacciones ───────────────────────────────

  Widget _buildPostItem(Map<String, dynamic> post) {
    final postId = PostComponent.extractLocalPostId(post);
    final reactions = postId != null
        ? _component.reactionsByPost[postId]
        : null;
    final comments = postId != null ? _component.commentsByPost[postId] : null;
    final isExpanded =
        postId != null && _expandedPostReactions.contains(postId);

    return PostCardWidget(
      post: post,
      reactionsLabel: reactions != null
          ? _formatReactionsCount(reactions)
          : null,
      commentsCount: comments?.length,
      onReactionsTap: () {
        if (postId == null) return;
        setState(() {
          if (_expandedPostReactions.contains(postId)) {
            _expandedPostReactions.remove(postId);
          } else {
            _expandedPostReactions.add(postId);
          }
        });
      },
      onCommentsTap: () {
        if (postId == null) return;
        _openCommentsSheet(postId);
      },
      reactionExpandedWidget: isExpanded
          ? PostReactionRow(
              postId: postId,
              currentReaction: _component.myPostReaction(postId),
              isInFlight: _component.isPostReactionInFlight(postId),
              onReact: (type) async {
                final ok = await _component.reactToPost(postId, type);
                if (ok && mounted) {
                  setState(() {
                    _expandedPostReactions.remove(postId);
                  });
                }
                return ok;
              },
            )
          : null,
    );
  }

  // ── Filtros locales ────────────────────────────────────────

  List<Map<String, dynamic>> _applyUiFilters(
    List<Map<String, dynamic>> source,
  ) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source
        .where((p) {
          final title = (p['title_post'] ?? p['title'] ?? '')
              .toString()
              .toLowerCase();
          final content = (p['content'] ?? p['text'] ?? '')
              .toString()
              .toLowerCase();
          return title.contains(q) || content.contains(q);
        })
        .toList(growable: false);
  }

  String _formatReactionsCount(Map<String, int>? summary) {
    if (summary == null || summary.isEmpty) return '0';
    return '${summary.values.fold<int>(0, (a, b) => a + b)}';
  }
}
