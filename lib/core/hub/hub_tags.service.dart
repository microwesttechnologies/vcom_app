import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/hub_tag.model.dart';

class HubTagsService {
  static final HubTagsService _instance = HubTagsService._internal();
  factory HubTagsService() => _instance;
  HubTagsService._internal();

  static const List<HubTagModel> _seedTags = [
    HubTagModel(id: 1, name: 'Vivir bien', slug: 'vivir-bien'),
    HubTagModel(id: 2, name: 'Personal', slug: 'personal'),
    HubTagModel(id: 3, name: 'Moda', slug: 'moda'),
    HubTagModel(id: 4, name: 'Estudio', slug: 'estudio'),
  ];

  Future<List<HubTagModel>> fetchTags() async {
    final token = TokenService();
    final authHeaders = token.getAuthHeaders();

    try {
      final response = await http
          .get(
            Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.hubTags}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ...authHeaders,
            },
          )
          .timeout(const Duration(seconds: 10));

      token.handleUnauthorizedStatus(response.statusCode);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final rawList = body is Map<String, dynamic>
            ? (body['data'] as List<dynamic>? ?? const [])
            : const <dynamic>[];

        final tags = rawList
            .whereType<Map<String, dynamic>>()
            .map(HubTagModel.fromJson)
            .where((tag) => tag.isActive)
            .toList(growable: false);

        if (tags.isNotEmpty) return tags;
      }
    } catch (_) {}

    // Fallback local para entornos sin backend Hub desplegado.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return _seedTags.where((tag) => tag.isActive).toList(growable: false);
  }
}
