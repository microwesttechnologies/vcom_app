import 'package:flutter/material.dart';
import 'package:vcom_app/pages/training/training.component.dart';
import 'package:vcom_app/pages/training/video_player.page.dart';
import 'package:vcom_app/core/models/video.model.dart';
import 'package:vcom_app/components/shared/video_thumbnail.widget.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Página principal de Training
class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  late TrainingComponent _trainingComponent;

  @override
  void initState() {
    super.initState();
    _trainingComponent = TrainingComponent();
    _trainingComponent.addListener(_onComponentChanged);
    _trainingComponent.initialize();
  }

  @override
  void dispose() {
    _trainingComponent.removeListener(_onComponentChanged);
    super.dispose();
  }

  void _onComponentChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VcomColors.azulZafiroProfundo,
      body: Container(
        decoration: const BoxDecoration(
          gradient: VcomColors.gradienteNocturno,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildFilterTabs(),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: VcomColors.oroLujoso),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Training',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: VcomColors.oroLujoso,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance para el botón de retroceso
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    // Mapear categorías del backend a nombres de filtro
    final filters = ['Todos'];
    
    // Agregar categorías disponibles
    for (var category in _trainingComponent.categories) {
      if (!filters.contains(category.nameCategoryVideo)) {
        filters.add(category.nameCategoryVideo);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _trainingComponent.selectedFilter == filter;
            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (_) => _trainingComponent.filterByCategory(filter),
                backgroundColor: VcomColors.azulOverlayTransparente60,
                selectedColor: VcomColors.oroLujoso,
                labelStyle: TextStyle(
                  color: isSelected 
                      ? VcomColors.azulMedianocheTexto 
                      : VcomColors.blancoCrema,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected 
                        ? VcomColors.oroLujoso 
                        : VcomColors.oroLujoso.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
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

    if (_trainingComponent.error != null && _trainingComponent.allVideos.isEmpty) {
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
                color: VcomColors.blancoCrema.withOpacity(0.7),
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
              color: VcomColors.oroLujoso.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay videos disponibles',
              style: TextStyle(
                fontSize: 16,
                color: VcomColors.blancoCrema.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trainingComponent.videos.length,
      itemBuilder: (context, index) {
        return _buildVideoCard(_trainingComponent.videos[index]);
      },
    );
  }

  Widget _buildVideoCard(VideoModel video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: VcomColors.azulZafiroProfundo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: VcomColors.oroLujoso.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail con botón de play
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerPage(video: video),
                ),
              );
            },
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: VideoThumbnail(
                    videoUrl: video.urlSource,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      width: double.infinity,
                      height: 200,
                      color: VcomColors.azulOverlayTransparente60,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: VcomColors.oroLujoso,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: Container(
                      width: double.infinity,
                      height: 200,
                      color: VcomColors.azulOverlayTransparente60,
                      child: Icon(
                        Icons.video_library,
                        color: VcomColors.oroLujoso.withOpacity(0.5),
                        size: 50,
                      ),
                    ),
                  ),
                ),
                // Botón de play centrado
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: VcomColors.oroLujoso,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: VcomColors.azulMedianocheTexto,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                // Duración en la esquina inferior derecha (placeholder por ahora)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: VcomColors.oroLujoso,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Video', // Placeholder - la duración real requeriría metadata adicional
                      style: TextStyle(
                        color: VcomColors.oroLujoso,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Información del video
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  video.titleVideo,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: VcomColors.blancoCrema,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Subtítulo/Descripción
                if (video.subtitleVideo != null || video.description != null)
                  Text(
                    video.subtitleVideo ?? video.description ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: VcomColors.blancoCrema.withOpacity(0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                const SizedBox(height: 12),
                
                // Botón de categoría
                if (video.categoryVideo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: VcomColors.azulOverlayTransparente60,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: VcomColors.oroLujoso,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      video.categoryVideo!.nameCategoryVideo,
                      style: TextStyle(
                        color: VcomColors.oroLujoso,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
