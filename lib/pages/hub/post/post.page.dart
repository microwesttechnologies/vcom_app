import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vcom_app/core/common/media_upload.service.dart';
import 'package:vcom_app/core/hub/hub_tags.service.dart';
import 'package:vcom_app/pages/hub/hub_constants.dart';
import 'package:vcom_app/pages/hub/post/media_picker.widget.dart';
import 'package:vcom_app/pages/hub/post/post.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Bottom sheet para crear un nuevo post.
class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({
    required this.postComponent,
    required this.tags,
    required this.initialTag,
    super.key,
  });

  final PostComponent postComponent;
  final List<HubTag> tags;
  final HubTag? initialTag;

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _uploadService = MediaUploadService();
  HubTag? _selectedTag;
  List<PickedMedia> _pickedMedia = [];
  bool _isSubmitting = false;
  String? _progressMsg;

  @override
  void initState() {
    super.initState();
    _selectedTag = widget.initialTag;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (title.isEmpty || content.isEmpty) {
      _showSnack('Completa título y contenido', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _progressMsg = 'Preparando publicación...';
    });

    try {
      final media = await _processMedia();
      if (!mounted) return;

      setState(() => _progressMsg = 'Publicando...');

      final ok = await widget.postComponent.createPost(
        title: title,
        content: content,
        tagId: _selectedTag?.id,
        media: media.isEmpty ? null : media,
      );

      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
        _showSnack('Publicación creada', isError: false);
      } else {
        _showSnack(
          widget.postComponent.error ?? 'No se pudo crear la publicación',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          'Error: ${e.toString().replaceFirst("Exception: ", "")}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _progressMsg = null;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _processMedia() async {
    if (_pickedMedia.isEmpty) return [];
    final results = <Map<String, dynamic>>[];

    for (var i = 0; i < _pickedMedia.length; i++) {
      final media = _pickedMedia[i];
      if (mounted) {
        setState(
          () => _progressMsg =
              'Comprimiendo y subiendo ${i + 1}/${_pickedMedia.length}...',
        );
      }

      if (media.type == 'image') {
        final compressed = await _compressImage(media.file);
        final upload = await _uploadService.uploadFile(
          file: compressed,
          type: 'image',
        );
        results.add({
          'type': 'image',
          'url': upload.url,
          'mime_type': upload.contentType ?? 'image/jpeg',
          'file_size': await compressed.length(),
          'sort_order': i,
        });
      } else {
        final upload = await _uploadService.uploadFile(
          file: media.file,
          type: 'video',
        );
        results.add({
          'type': 'video',
          'url': upload.url,
          'mime_type': upload.contentType ?? 'video/mp4',
          'file_size': await media.file.length(),
          'sort_order': i,
          if (upload.thumbnailUrl != null) 'thumbnail': upload.thumbnailUrl,
        });
      }
    }
    return results;
  }

  Future<File> _compressImage(File original) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final outPath = '${tempDir.path}${Platform.pathSeparator}hub_$ts.jpg';
      final compressed = await FlutterImageCompress.compressAndGetFile(
        original.absolute.path,
        outPath,
        quality: HubConstants.mediaCompressionQuality,
        format: CompressFormat.jpeg,
        minWidth: 1280,
        minHeight: 1280,
        keepExif: false,
      );
      if (compressed == null) return original;
      final compFile = File(compressed.path);
      final origSize = await original.length();
      final compSize = await compFile.length();
      debugPrint(
        'Hub imagen comprimida: '
        '${(origSize / 1024).toStringAsFixed(0)}KB → '
        '${(compSize / 1024).toStringAsFixed(0)}KB',
      );
      return compSize > 0 && compSize < origSize ? compFile : original;
    } catch (e) {
      debugPrint('Compresión falló, usando original: $e');
      return original;
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? VcomColors.error : VcomColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('Crear publicación'),
            const SizedBox(height: 12),
            _textField(_titleCtrl, 'Título'),
            const SizedBox(height: 12),
            _textField(_contentCtrl, 'Contenido', maxLines: 5),
            const SizedBox(height: 12),
            _buildTagDropdown(),
            const SizedBox(height: 12),
            MediaPickerWidget(
              pickedMedia: _pickedMedia,
              onChanged: (list) => setState(() => _pickedMedia = list),
            ),
            const SizedBox(height: 16),
            _submitButton(),
          ],
        ),
      ),
    );
  }

  Widget _submitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: VcomColors.oroLujoso,
        foregroundColor: VcomColors.azulMedianocheTexto,
        disabledBackgroundColor: VcomColors.oroLujoso.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: _isSubmitting
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: VcomColors.azulMedianocheTexto,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _progressMsg ?? 'Publicando...',
                  style: TextStyle(
                    color: VcomColors.azulMedianocheTexto,
                    fontSize: 14,
                  ),
                ),
              ],
            )
          : const Text('Publicar'),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      enabled: !_isSubmitting,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildTagDropdown() {
    return DropdownButtonFormField<HubTag>(
      initialValue: _selectedTag,
      dropdownColor: const Color(0xFF0E1729),
      iconEnabledColor: Colors.white,
      items: widget.tags
          .map(
            (t) => DropdownMenuItem<HubTag>(
              value: t,
              child: Text(t.name, style: const TextStyle(color: Colors.white)),
            ),
          )
          .toList(),
      onChanged: _isSubmitting ? null : (v) => setState(() => _selectedTag = v),
      decoration: const InputDecoration(
        labelText: 'Tag (opcional)',
        labelStyle: TextStyle(color: Colors.white70),
        border: OutlineInputBorder(),
      ),
    );
  }
}
