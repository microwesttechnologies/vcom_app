import 'package:flutter/material.dart';
import 'package:vcom_app/pages/hub/hub.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Fila de input + botón para agregar un comentario.
class AddCommentRow extends StatefulWidget {
  const AddCommentRow({
    required this.postId,
    required this.component,
    super.key,
  });

  final int postId;
  final HubComponent component;

  @override
  State<AddCommentRow> createState() => _AddCommentRowState();
}

class _AddCommentRowState extends State<AddCommentRow> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    final isSubmitting =
        widget.component.isCommentCreateInFlight(widget.postId);
    if (isSubmitting) return;

    final ok = await widget.component.addComment(widget.postId, value);
    if (!mounted) return;

    if (ok) {
      _controller.clear();
      _showSnack('Comentario publicado');
    } else {
      _showSnack(widget.component.error ?? 'Error desconocido');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        widget.component.isCommentCreateInFlight(widget.postId);
    return Row(
      children: [
        const CircleAvatar(
          radius: 14,
          child: Icon(Icons.person, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(child: _input()),
        const SizedBox(width: 8),
        IconButton(
          onPressed: isSubmitting ? null : _submit,
          icon: const Icon(
            Icons.send,
            color: VcomColors.oroLujoso,
            size: 20,
          ),
          tooltip: 'Comentar',
        ),
      ],
    );
  }

  Widget _input() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: const InputDecoration(
          hintText: 'Escribe un comentario...',
          hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
          border: InputBorder.none,
        ),
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}
