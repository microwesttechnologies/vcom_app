import 'package:flutter/material.dart';
import 'package:vcom_app/pages/hub/hub.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Fila de input + botón para agregar un comentario.
class AddCommentRow extends StatefulWidget {
  const AddCommentRow({
    required this.postId,
    required this.component,
    this.rootMessenger,
    super.key,
  });

  final int postId;
  final HubComponent component;
  final ScaffoldMessengerState? rootMessenger;

  @override
  State<AddCommentRow> createState() => _AddCommentRowState();
}

class _AddCommentRowState extends State<AddCommentRow> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (value.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    final ok = await widget.component.addComment(widget.postId, value);
    if (!mounted) return;

    setState(() => _isSending = false);

    if (ok) {
      _controller.clear();
      _showSnack('Comentario agregado', isSuccess: true);
    } else {
      _showSnack(
        widget.component.error ?? 'Error al enviar comentario',
        isSuccess: false,
      );
    }
  }

  void _showSnack(String msg, {required bool isSuccess}) {
    final messenger = widget.rootMessenger ?? ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isSuccess ? VcomColors.success : VcomColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        _sendButton(),
      ],
    );
  }

  Widget _sendButton() {
    return GestureDetector(
      onTap: _isSending ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _isSending
              ? VcomColors.oroLujoso.withValues(alpha: 0.3)
              : VcomColors.oroLujoso,
          shape: BoxShape.circle,
        ),
        child: _isSending
            ? const Padding(
                padding: EdgeInsets.all(9),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: VcomColors.azulMedianocheTexto,
                ),
              )
            : const Icon(
                Icons.send_rounded,
                size: 18,
                color: VcomColors.azulMedianocheTexto,
              ),
      ),
    );
  }

  Widget _input() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _isSending ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: VcomColors.azulOverlayTransparente50,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: TextField(
          controller: _controller,
          enabled: !_isSending,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Escribe un comentario...',
            hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
          onSubmitted: (_) => _submit(),
        ),
      ),
    );
  }
}
