import 'package:flutter/material.dart';
import 'package:vcom_app/pages/training/training.component.dart';
import 'package:vcom_app/pages/training/video_player.page.dart' show VideoPlayerBody;
import 'package:vcom_app/core/models/video.model.dart';
import 'package:vcom_app/components/shared/video_thumbnail.widget.dart';
import 'package:vcom_app/components/shared/modelo_menubar.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  late TrainingComponent _trainingComponent;
  final _searchController = TextEditingController();
  VideoModel? _currentVideo;

  @override
  void initState() {
    super.initState();
    _trainingComponent = TrainingComponent();
    _trainingComponent.addListener(_onComponentChanged);
    _trainingComponent.initialize();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _trainingComponent.removeListener(_onComponentChanged);
    super.dispose();
  }

  void _onComponentChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged() {
    _trainingComponent.setSearchQuery(_searchController.text);
  }

  void _openVideo(VideoModel video) {
    setState(() => _currentVideo = video);
  }

  void _closeVideo() {
    setState(() => _currentVideo = null);
  }

  @override
  Widget build(BuildContext context) {
    final inDetail = _currentVideo != null;

    return PopScope(
      canPop: !inDetail,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && inDetail) _closeVideo();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: ModeloNavbar(
          showBackButton: inDetail,
          onBackTap: inDetail ? _closeVideo : null,
        ),
        extendBodyBehindAppBar: true,
        extendBody: true,
        bottomNavigationBar: const ModeloMenuBar(activeRoute: 'training'),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: inDetail
              ? VideoPlayerBody(
                  key: ValueKey(_currentVideo!.idVideo),
                  video: _currentVideo!,
                )
              : Container(
                  key: const ValueKey('training-list'),
                  width: double.infinity,
                  height: double.infinity,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchBar(),
                        _buildCategoryFilters(),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                          child: Text(
                            'Entrenamientos siguientes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(child: _buildContent()),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Buscar artículos de lujo...',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.6),
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final filters = ['Todos los Artículos'];
    for (var cat in _trainingComponent.categories) {
      if (!filters.contains(cat.nameCategoryVideo)) {
        filters.add(cat.nameCategoryVideo);
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters.map((filter) {
          final isSelected = _trainingComponent.selectedFilter == filter;
          return GestureDetector(
            onTap: () => _trainingComponent.filterByCategory(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? VcomColors.oroLujoso
                      : const Color(0xFFD4D4D8),
                  width: 0.6,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? VcomColors.oroLujoso
                      : const Color(0xFFD4D4D8),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    if (_trainingComponent.isLoading && _trainingComponent.allVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: VcomColors.oroLujoso,
              strokeWidth: 4,
            ),
            const SizedBox(height: 24),
            Text(
              'Cargando videos...',
              style: TextStyle(
                fontSize: 16,
                color: VcomColors.blancoCrema,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_trainingComponent.error != null &&
        _trainingComponent.allVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: VcomColors.error),
            const SizedBox(height: 16),
            Text(
              'Error al cargar videos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VcomColors.blancoCrema,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _trainingComponent.error!,
              style: TextStyle(
                fontSize: 14,
                color: VcomColors.blancoCrema.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _trainingComponent.refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: VcomColors.oroLujoso,
                foregroundColor: VcomColors.azulMedianocheTexto,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_trainingComponent.videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: VcomColors.oroLujoso.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay videos disponibles',
              style: TextStyle(
                fontSize: 16,
                color: VcomColors.blancoCrema.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _trainingComponent.refresh(),
      color: VcomColors.oroLujoso,
      backgroundColor: const Color(0xFF1a2847),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _trainingComponent.videos.length,
        itemBuilder: (context, index) {
          return _buildVideoCard(_trainingComponent.videos[index]);
        },
      ),
    );
  }

  Widget _buildVideoCard(VideoModel video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openVideo(video),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail cuadrado
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: VideoThumbnail(
                      videoUrl: video.urlSource,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: const Color(0xFF1a2847),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: VcomColors.oroLujoso,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: Container(
                        color: const Color(0xFF1a2847),
                        child: Icon(
                          Icons.video_library,
                          color: VcomColors.oroLujoso.withValues(alpha: 0.5),
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Título, descripción, categoría
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.titleVideo,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        video.subtitleVideo ??
                            video.description ??
                            'Lorem ipsum dolor sit amet consectetur adipisicing elit.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.65),
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      if (video.categoryVideo != null)
                        Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              size: 14,
                              color: VcomColors.oroLujoso,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              video.categoryVideo!.nameCategoryVideo,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: VcomColors.oroLujoso,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
