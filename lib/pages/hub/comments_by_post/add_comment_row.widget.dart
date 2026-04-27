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
    final isSubmitting = widget.component.isCommentCreateInFlight(
      widget.postId,
    );
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = widget.component.isCommentCreateInFlight(
      widget.postId,
    );
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: VcomColors.oroLujoso,
          child: const Icon(
            Icons.person,
            size: 18,
            color: VcomColors.azulMedianocheTexto,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _input()),
        const SizedBox(width: 6),
        _sendButton(isSubmitting),
      ],
    );
  }

  Widget _sendButton(bool isSubmitting) {
    return GestureDetector(
      onTap: isSubmitting ? null : _submit,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSubmitting
              ? VcomColors.oroLujoso.withValues(alpha: 0.3)
              : VcomColors.oroLujoso,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.send_rounded,
          size: 18,
          color: isSubmitting
              ? const Color.fromARGB(255, 10, 35, 5).withValues(alpha: 0.5)
              : VcomColors.azulMedianocheTexto,
        ),
      ),
    );
  }

  Widget _input() {
    return Container(
      decoration: BoxDecoration(
        color: VcomColors.azulOverlayTransparente50,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Escribe un comentario...',
          hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}
