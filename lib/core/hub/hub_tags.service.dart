import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';

class HubTagsService {
  final TokenService _tokenService = TokenService();

  Future<List<HubTag>> fetchTags({int page = 1, int perPage = 15}) async {
    final url = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.hubTagsList}?page=$page&per_page=$perPage',
    );
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        ..._tokenService.getAuthHeaders(),
      },
    );
    if (response.statusCode >= 400) {
      throw Exception('No fue posible cargar tags (${response.statusCode})');
    }
    final dynamic body = jsonDecode(response.body);
    final list = _extractList(body);
    return list
        .whereType<Map<String, dynamic>>()
        .map(HubTag.fromJson)
        .toList(growable: false);
  }

  List<dynamic> _extractList(dynamic json) {
    if (json is List) return json;
    if (json is Map<String, dynamic>) {
      final data = json['data'] ?? json['items'] ?? json['tags'];
      if (data is List) return data;
    }
    return const [];
  }
}

class HubTag {
  final int id;
  final String name;
  final String slug;

  const HubTag({required this.id, required this.name, required this.slug});

  factory HubTag.fromJson(Map<String, dynamic> json) {
    return HubTag(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
    );
  }
}
