import 'package:flutter/material.dart';
import 'package:vcom_app/core/hub/hub_tags.service.dart';
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
  final _mediaUrlCtrl = TextEditingController();
  HubTag? _selectedTag;

  @override
  void initState() {
    super.initState();
    _selectedTag = widget.initialTag;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _mediaUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    final mediaUrl = _mediaUrlCtrl.text.trim();

    if (title.isEmpty || content.isEmpty) {
      _showSnack('Completa título y contenido');
      return;
    }

    final media = mediaUrl.isNotEmpty
        ? [
            {
              'type': 'image',
              'url': mediaUrl,
              'mime_type': 'image/*',
              'file_size': 0,
              'sort_order': 0,
            },
          ]
        : <Map<String, dynamic>>[];

    final ok = await widget.postComponent.createPost(
      title: title,
      content: content,
      tagId: _selectedTag?.id,
      media: media.isEmpty ? null : media,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      _showSnack('Publicación creada');
    } else {
      _showSnack(
        widget.postComponent.error ?? 'No se pudo crear la publicación',
      );
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
            _textField(_mediaUrlCtrl, 'URL de imagen (opcional)'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submit,
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
      onChanged: (v) => setState(() => _selectedTag = v),
      decoration: const InputDecoration(
        labelText: 'Tag (opcional)',
        labelStyle: TextStyle(color: Colors.white70),
        border: OutlineInputBorder(),
      ),
    );
  }
}
