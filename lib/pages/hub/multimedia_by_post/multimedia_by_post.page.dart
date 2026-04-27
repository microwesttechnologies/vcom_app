import 'package:flutter/material.dart';
import 'package:vcom_app/pages/hub/hub_constants.dart';

/// Widget informativo de reglas de multimedia por post.
/// Se puede embeber en un formulario de creación de post.
class MultimediaByPostInfo extends StatelessWidget {
  const MultimediaByPostInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reglas de multimedia',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        _rule('Máx. ${HubConstants.maxImagesPerPost} imágenes'),
        _rule('Máx. ${HubConstants.maxVideosPerPost} videos'),
        _rule(
          'Duración máx. por video: '
          '${HubConstants.maxVideoDurationSeconds}s',
        ),
        _rule(
          'Compresión al ${HubConstants.mediaCompressionQuality}%',
        ),
      ],
    );
  }

  Widget _rule(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
