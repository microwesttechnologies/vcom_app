import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vcom_app/pages/hub/hub_constants.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Archivo multimedia seleccionado con su tipo.
class PickedMedia {
  final File file;
  final String type; // 'image' | 'video'
  PickedMedia({required this.file, required this.type});
}

/// Widget para seleccionar fotos y videos desde galería o cámara.
class MediaPickerWidget extends StatefulWidget {
  const MediaPickerWidget({
    required this.pickedMedia,
    required this.onChanged,
    super.key,
  });

  final List<PickedMedia> pickedMedia;
  final ValueChanged<List<PickedMedia>> onChanged;

  @override
  State<MediaPickerWidget> createState() => _MediaPickerWidgetState();
}

class _MediaPickerWidgetState extends State<MediaPickerWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false;

  int get _imageCount =>
      widget.pickedMedia.where((m) => m.type == 'image').length;
  int get _videoCount =>
      widget.pickedMedia.where((m) => m.type == 'video').length;
  bool get _canAddImage => _imageCount < HubConstants.maxImagesPerPost;
  bool get _canAddVideo => _videoCount < HubConstants.maxVideosPerPost;

  Future<void> _pickImage(ImageSource source) async {
    if (_isPicking || !_canAddImage) return;
    setState(() => _isPicking = true);
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 80,
      );
      if (xFile == null) return;
      final updated = [
        ...widget.pickedMedia,
        PickedMedia(file: File(xFile.path), type: 'image'),
      ];
      widget.onChanged(updated);
    } catch (e) {
      if (mounted) _showError('Error al seleccionar imagen');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    if (_isPicking || !_canAddVideo) return;
    setState(() => _isPicking = true);
    try {
      final xFile = await _picker.pickVideo(
        source: source,
        maxDuration: Duration(seconds: HubConstants.maxVideoDurationSeconds),
      );
      if (xFile == null) return;
      final updated = [
        ...widget.pickedMedia,
        PickedMedia(file: File(xFile.path), type: 'video'),
      ];
      widget.onChanged(updated);
    } catch (e) {
      if (mounted) _showError('Error al seleccionar video');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _remove(int index) {
    final updated = [...widget.pickedMedia]..removeAt(index);
    widget.onChanged(updated);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: VcomColors.error),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: VcomColors.azulZafiroProfundo,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _optionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _addButton(),
        if (widget.pickedMedia.isNotEmpty) ...[
          const SizedBox(height: 10),
          _thumbnailGrid(),
        ],
        _limitsLabel(),
      ],
    );
  }

  Widget _addButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _isPicking ? null : _showPickerOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: VcomColors.azulOverlayTransparente50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: VcomColors.oroLujoso.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: VcomColors.oroLujoso,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.pickedMedia.isEmpty
                    ? 'Agregar fotos o videos'
                    : '${widget.pickedMedia.length} archivo(s) seleccionado(s)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ),
            if (_isPicking)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: VcomColors.oroLujoso,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailGrid() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.pickedMedia.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _thumbnailItem(i),
      ),
    );
  }

  Widget _thumbnailItem(int index) {
    final media = widget.pickedMedia[index];
    final isVideo = media.type == 'video';
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 80,
            height: 80,
            color: const Color(0xFF1A2740),
            child: isVideo
                ? Center(
                    child: Icon(
                      Icons.videocam_rounded,
                      color: VcomColors.oroLujoso,
                      size: 32,
                    ),
                  )
                : Image.file(media.file, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _remove(index),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: VcomColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
        if (isVideo)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'VIDEO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _limitsLabel() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        'Fotos: $_imageCount/${HubConstants.maxImagesPerPost}  ·  '
        'Videos: $_videoCount/${HubConstants.maxVideosPerPost}',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _optionsSheet() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_canAddImage) ...[
              _optionTile(
                icon: Icons.photo_library_outlined,
                label: 'Foto desde galería',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              _optionTile(
                icon: Icons.camera_alt_outlined,
                label: 'Foto desde cámara',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
            if (_canAddVideo) ...[
              _optionTile(
                icon: Icons.video_library_outlined,
                label: 'Video desde galería',
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.gallery);
                },
              ),
              _optionTile(
                icon: Icons.videocam_outlined,
                label: 'Video desde cámara',
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.camera);
                },
              ),
            ],
            if (!_canAddImage && !_canAddVideo)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Límite de archivos alcanzado',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: VcomColors.oroLujoso),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
