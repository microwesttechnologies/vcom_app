import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
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
    this.scaffoldMessenger,
    this.snackBarBottomMargin,
    super.key,
  });

  final PostComponent postComponent;
  final List<HubTag> tags;
  final HubTag? initialTag;
  final ScaffoldMessengerState? scaffoldMessenger;
  /// Margen inferior del SnackBar flotante (encima del menú inferior del Hub).
  final double? snackBarBottomMargin;

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  HubTag? _selectedTag;
  List<PickedMedia> _pickedMedia = [];
  bool _isSubmitting = false;
  String? _progressMsg;
  OverlayEntry? _errorOverlayEntry;
  Timer? _errorAutoHideTimer;
  GlobalKey<_AnimatedScreenTopErrorBannerState>? _errorBannerKey;

  @override
  void initState() {
    super.initState();
    _selectedTag = widget.initialTag;
  }

  @override
  void dispose() {
    _errorAutoHideTimer?.cancel();
    _removeErrorOverlayImmediate();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (title.isEmpty || content.isEmpty) {
      _showSheetTopError('Completa título y contenido');
      return;
    }

    _removeErrorOverlayImmediate();
    setState(() {
      _isSubmitting = true;
      _progressMsg = 'Preparando publicación...';
    });

    try {
      final files = await _prepareFiles();
      if (!mounted) return;

      setState(() => _progressMsg = 'Publicando...');

      final ok = await widget.postComponent.createPost(
        title: title,
        content: content,
        tagId: _selectedTag?.id,
        mediaFiles: files,
      );

      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
        _showSuccessSnack('Publicación creada');
      } else {
        _showSheetTopError(
          widget.postComponent.error ?? 'No se pudo crear la publicación',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSheetTopError(
          'Error: ${e.toString().replaceFirst("Exception: ", "")}',
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

  Future<List<File>> _prepareFiles() async {
    if (_pickedMedia.isEmpty) return [];
    final files = <File>[];

    for (var i = 0; i < _pickedMedia.length; i++) {
      final media = _pickedMedia[i];
      if (mounted) {
        setState(
          () =>
              _progressMsg = 'Comprimiendo ${i + 1}/${_pickedMedia.length}...',
        );
      }

      if (media.type == 'image') {
        files.add(await _compressImage(media.file));
      } else {
        files.add(media.file);
      }
    }
    return files;
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

  void _showSheetTopError(String message) {
    if (!mounted) return;
    _errorAutoHideTimer?.cancel();
    _removeErrorOverlayImmediate();

    final bannerKey = GlobalKey<_AnimatedScreenTopErrorBannerState>();
    _errorBannerKey = bannerKey;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayCtx) => _AnimatedScreenTopErrorBanner(
        key: bannerKey,
        message: message,
        entry: entry,
        onRemoved: () {
          if (!mounted) return;
          _errorOverlayEntry = null;
          _errorBannerKey = null;
        },
      ),
    );
    _errorOverlayEntry = entry;
    Overlay.of(context).insert(entry);

    _errorAutoHideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      unawaited(_dismissErrorOverlayAnimated());
    });
  }

  void _removeErrorOverlayImmediate() {
    _errorAutoHideTimer?.cancel();
    _errorAutoHideTimer = null;
    final e = _errorOverlayEntry;
    _errorOverlayEntry = null;
    _errorBannerKey = null;
    if (e != null) {
      e.remove();
      e.dispose();
    }
  }

  Future<void> _dismissErrorOverlayAnimated() async {
    _errorAutoHideTimer?.cancel();
    _errorAutoHideTimer = null;
    final state = _errorBannerKey?.currentState;
    if (state != null) {
      await state.dismissAndRemove();
    } else {
      _removeErrorOverlayImmediate();
    }
  }

  void _showSuccessSnack(String message) {
    final messenger =
        widget.scaffoldMessenger ?? ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    final bottomMargin = widget.snackBarBottomMargin ??
        (MediaQuery.paddingOf(context).bottom + 24);
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: VcomColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearSheetErrorIfAny() {
    if (_errorOverlayEntry != null) {
      unawaited(_dismissErrorOverlayAnimated());
    }
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
      onChanged: (_) => _clearSheetErrorIfAny(),
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

class _AnimatedScreenTopErrorBanner extends StatefulWidget {
  const _AnimatedScreenTopErrorBanner({
    super.key,
    required this.message,
    required this.entry,
    required this.onRemoved,
  });

  final String message;
  final OverlayEntry entry;
  final VoidCallback onRemoved;

  @override
  State<_AnimatedScreenTopErrorBanner> createState() =>
      _AnimatedScreenTopErrorBannerState();
}

class _AnimatedScreenTopErrorBannerState extends State<_AnimatedScreenTopErrorBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  bool _removing = false;

  static const _inDuration = Duration(milliseconds: 380);
  static const _outDuration = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _inDuration,
      reverseDuration: _outDuration,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> dismissAndRemove() async {
    if (_removing) return;
    _removing = true;
    await _controller.reverse();
    if (!mounted) return;
    widget.entry.remove();
    widget.entry.dispose();
    widget.onRemoved();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 8;
    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
          child: Material(
            color: VcomColors.error,
            elevation: 8,
            shadowColor: Colors.black54,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.25,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: dismissAndRemove,
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
