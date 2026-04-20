import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/modelo_menubar.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/pages/hub/hub.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';
import 'package:vcom_app/core/hub/hub_tags.service.dart';

class HubPage extends StatefulWidget {
  const HubPage({super.key});

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {
  final HubComponent _component = HubComponent();
  final TextEditingController _searchController = TextEditingController();
  String _selectedChip = 'todos';
  final Set<int> _expandedPostReactions = <int>{};
  final Set<String> _expandedCommentReactions = <String>{};
  final Set<int> _expandedPostComments = <int>{};

  @override
  void initState() {
    super.initState();
    _component.addListener(_onChanged);
    _component.initialize();
  }

  Future<void> _openCreatePostSheet() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final mediaUrlCtrl = TextEditingController();
    HubTag? selectedTag = _component.selectedTag;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E1729),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Crear publicación',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Contenido',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<HubTag>(
                  value: selectedTag,
                  dropdownColor: const Color(0xFF0E1729),
                  iconEnabledColor: Colors.white,
                  items: _component.tags
                      .map(
                        (t) => DropdownMenuItem<HubTag>(
                          value: t,
                          child: Text(
                            t.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    selectedTag = v;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Tag (opcional)',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mediaUrlCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'URL de imagen (opcional)',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final content = contentCtrl.text.trim();
                    final mediaUrl = mediaUrlCtrl.text.trim();
                    if (title.isEmpty || content.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Completa título y contenido'),
                        ),
                      );
                      return;
                    }
                    final ok = await _component.debugCreatePost(
                      context,
                      title: title,
                      content: content,
                      tag: selectedTag,
                      mediaUrl: mediaUrl.isEmpty ? null : mediaUrl,
                    );
                    if (!mounted) return;
                    if (ok) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Publicación creada')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _component.error ??
                                'No se pudo crear la publicación',
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VcomColors.oroLujoso,
                    foregroundColor: VcomColors.azulMedianocheTexto,
                  ),
                  child: const Text('Publicar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleComment(int postId, dynamic c) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 10, child: Icon(Icons.person, size: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.authorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  c.content,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        final key = '$postId:${c.id}';
                        setState(() {
                          if (_expandedCommentReactions.contains(key)) {
                            _expandedCommentReactions.remove(key);
                          } else {
                            _expandedCommentReactions.add(key);
                          }
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.thumb_up_alt_outlined,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${c.reactionsCount}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      c.createdAt,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (_expandedCommentReactions.contains('$postId:${c.id}'))
                  Row(
                    children: [
                      for (final r in const [
                        ['👍', 'like'],
                        ['❤️', 'love'],
                        ['😂', 'haha'],
                        ['😮', 'wow'],
                        ['😢', 'sad'],
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final ok = await _component.debugReactToComment(
                                context,
                                postId,
                                (c.apiKey ?? c.id),
                                r[1].toString(),
                              );
                              if (!mounted) return;
                              if (!ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'No se pudo reaccionar: ${_component.error ?? 'Error desconocido'}',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Text(
                                r[0].toString(),
                                style: const TextStyle(fontSize: 12),
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

  Widget _buildAddCommentRow(int postId) {
    final controller = TextEditingController();
    return Row(
      children: [
        const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Escribe un comentario...',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                border: InputBorder.none,
              ),
              onSubmitted: (text) async {
                final value = text.trim();
                if (value.isEmpty) return;
                final ok = await _component.debugAddComment(
                  context,
                  postId,
                  value,
                );
                if (!mounted) return;
                if (ok) {
                  controller.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comentario publicado')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_component.error ?? 'Error desconocido'),
                    ),
                  );
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () async {
            final value = controller.text.trim();
            if (value.isEmpty) return;
            final ok = await _component.debugAddComment(context, postId, value);
            if (!mounted) return;
            if (ok) {
              controller.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Comentario publicado')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_component.error ?? 'Error desconocido'),
                ),
              );
            }
          },
          icon: const Icon(Icons.send, color: VcomColors.oroLujoso, size: 20),
          tooltip: 'Comentar',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _component.removeListener(_onChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openCommentsSheet(int postId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E1729),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return AnimatedBuilder(
              animation: _component,
              builder: (_, __) {
                final comments = _component.commentsByPost[postId] ?? const [];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildAddCommentRow(postId),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            return _buildSingleComment(postId, comments[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

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
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 60),
          child: CircularProgressIndicator(color: VcomColors.oroLujoso),
        ),
      );
    }

    if (_component.error != null && _component.posts.isEmpty) {
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

    if (_component.posts.isEmpty) {
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

    final list = _applyUiFilters(_component.posts);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      itemCount: list.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) return _buildSearchBar();
        if (index == 1) return _buildChipsRow();
        final post = list[index - 2];
        return _buildPostCard(post);
      },
    );
  }

  List<Map<String, dynamic>> _applyUiFilters(
    List<Map<String, dynamic>> source,
  ) {
    final q = _searchController.text.trim().toLowerCase();
    return source
        .where((p) {
          final title = (p['title_post'] ?? p['title'] ?? '')
              .toString()
              .toLowerCase();
          final content = (p['content'] ?? p['text'] ?? '')
              .toString()
              .toLowerCase();
          final author =
              (p['author']?['name'] ??
                      p['user']?['name'] ??
                      p['author_name'] ??
                      '')
                  .toString()
                  .toLowerCase();
          final matchesQ =
              q.isEmpty ||
              title.contains(q) ||
              content.contains(q) ||
              author.contains(q);
          return matchesQ;
        })
        .toList(growable: false);
  }

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

  Widget _buildChipsRow() {
    final tags = _component.tags;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Chip: Todos los Artículos
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: _component.selectedTag == null,
                    onSelected: (_) {
                      setState(() => _selectedChip = 'todos');
                      _component.selectTag(null);
                    },
                    label: const Text('Todos los Artículos'),
                    labelStyle: TextStyle(
                      color: _component.selectedTag == null
                          ? VcomColors.azulMedianocheTexto
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    selectedColor: VcomColors.oroLujoso,
                    backgroundColor: const Color(0xFF1A2740),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                // Chips para cada tag del backend
                for (final t in tags)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: _component.selectedTag?.id == t.id,
                      onSelected: (_) {
                        setState(() => _selectedChip = t.slug);
                        _component.selectTag(t);
                      },
                      label: Text(t.name),
                      labelStyle: TextStyle(
                        color: _component.selectedTag?.id == t.id
                            ? VcomColors.azulMedianocheTexto
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      selectedColor: VcomColors.oroLujoso,
                      backgroundColor: const Color(0xFF1A2740),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final author =
        (post['author']?['name'] ??
                post['user']?['name'] ??
                post['author_name'] ??
                '')
            .toString();
    final title = (post['title_post'] ?? post['title'] ?? '').toString();
    final createdAt = (post['created_at'] ?? post['date'] ?? '').toString();
    final images = _extractImages(post);
    final rawId = post['id'] ?? post['id_post'];
    final int? postId = rawId is int
        ? rawId
        : int.tryParse((rawId ?? '').toString());
    final reactions = postId != null
        ? _component.reactionsByPost[postId]
        : null;
    final comments = postId != null ? _component.commentsByPost[postId] : null;
    final dynamic catRaw = post['tag'] ?? post['category'] ?? post['label'];
    final String category = (() {
      if (catRaw is Map<String, dynamic>) {
        return (catRaw['name'] ?? catRaw['title'] ?? catRaw['slug'] ?? '')
            .toString();
      }
      return (catRaw ?? '').toString();
    })().trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildImage(images.first),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${author.isNotEmpty ? author.toUpperCase() : 'AUTOR DESCONOCIDO'} · ${_relativeTime(createdAt)}',
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E1729),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  if ((post['content'] ?? post['text']) != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      (post['content'] ?? post['text']).toString(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.80),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (postId == null) return;
                          setState(() {
                            if (_expandedPostReactions.contains(postId)) {
                              _expandedPostReactions.remove(postId);
                            } else {
                              _expandedPostReactions.add(postId);
                            }
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite_border,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatReactionsCount(reactions),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (postId == null) return;
                          _openCommentsSheet(postId);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.mode_comment_outlined,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              comments == null ? '0' : '${comments.length}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Reacciones al post (5 emojis más usados)
                  if (postId != null && _expandedPostReactions.contains(postId))
                    Row(
                      children: [
                        for (final r in const [
                          ['👍', 'like'],
                          ['❤️', 'love'],
                          ['😂', 'haha'],
                          ['😮', 'wow'],
                          ['😢', 'sad'],
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                final ok = await _component.debugReactToPost(
                                  context,
                                  postId,
                                  r[1].toString(),
                                );
                                if (!mounted) return;
                                if (!ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _component.error ?? 'Error desconocido',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Text(
                                  r[0].toString(),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  // Los comentarios y el input ahora se muestran en un Modal Bottom Sheet
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Eliminado _buildReactionsRow por no usarse

  Widget _buildCommentsPreview(int postId, List comments) {
    final visible = comments.take(2).toList();
    return Column(
      children: [
        for (final c in visible)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 10,
                  child: Icon(Icons.person, size: 12),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.authorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.content,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              final key = '$postId:${c.id}';
                              setState(() {
                                if (_expandedCommentReactions.contains(key)) {
                                  _expandedCommentReactions.remove(key);
                                } else {
                                  _expandedCommentReactions.add(key);
                                }
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.thumb_up_alt_outlined,
                                  size: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${c.reactionsCount}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            c.createdAt,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Reacciones al comentario (5 emojis más usados)
                      if (_expandedCommentReactions.contains('$postId:${c.id}'))
                        Row(
                          children: [
                            for (final r in const [
                              ['👍', 'like'],
                              ['❤️', 'love'],
                              ['😂', 'haha'],
                              ['😮', 'wow'],
                              ['😢', 'sad'],
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    final ok = await _component
                                        .debugReactToComment(
                                          context,
                                          postId,
                                          (c.apiKey ?? c.id),
                                          r[1].toString(),
                                        );
                                    if (!mounted) return;
                                    if (!ok) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'No se pudo reaccionar: ${_component.error ?? 'Error desconocido'}',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.08,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      r[0].toString(),
                                      style: const TextStyle(fontSize: 12),
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
          ),
      ],
    );
  }

  List<String> _extractImages(Map<String, dynamic> post) {
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

  Widget _buildImage(String url) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
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

  String _formatReactionsCount(Map<String, int>? summary) {
    if (summary == null || summary.isEmpty) return '0';
    final total = summary.values.fold<int>(0, (a, b) => a + b);
    return '$total';
  }

  String _relativeTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return 'HACE ${diff.inMinutes}M';
      if (diff.inHours < 24) return 'HACE ${diff.inHours}H';
      return 'HACE ${diff.inDays}D';
    } catch (_) {
      return raw.toString();
    }
  }
}
