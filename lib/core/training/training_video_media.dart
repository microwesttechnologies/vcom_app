import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/hub/hub_post_media.dart';

/// URL absoluta del video de training (rutas /storage/ → API storage).
String resolveTrainingVideoUrl(String raw) => resolveHubMediaUrl(raw);

/// Cabeceras para [VideoPlayerController] (en web el <video> no las usa en rangos).
Map<String, String> trainingVideoRequestHeadersForUrl(
  String url,
  TokenService tokenService,
) =>
    hubVideoRequestHeadersForUrl(url, tokenService);
