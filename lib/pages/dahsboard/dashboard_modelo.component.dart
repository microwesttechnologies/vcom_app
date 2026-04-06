import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/session_cache.service.dart';
import 'package:vcom_app/core/common/session_state_registry.service.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/dashboard_modelo.model.dart';
import 'package:vcom_app/core/models/event.model.dart';
import 'package:vcom_app/core/models/product.model.dart';
import 'package:vcom_app/pages/shop/shop.component.dart';

/// Componente del dashboard para rol MODELO
/// Obtiene saldo, usuario y próximo entrenamiento de los endpoints
class DashboardModeloComponent extends ChangeNotifier {
  static final DashboardModeloComponent _instance =
      DashboardModeloComponent._internal();
  factory DashboardModeloComponent() => _instance;

  DashboardModeloComponent._internal() {
    SessionStateRegistryService().register(
      'dashboard_modelo_component',
      resetSessionState,
    );
  }

  final TokenService _tokenService = TokenService();
  final SessionCacheService _cache = SessionCacheService();

  ModelBalanceModel? _balance;
  double? _liquidatedAmountCop;
  EventModel? _nextEvent;
  List<ProductModel> _latestProducts = [];
  String? _userName;
  String? _userAvatarUrl;
  bool _isLoading = false;
  String? _error;
  bool _hasHydratedSessionData = false;

  ModelBalanceModel? get balance => _balance;
  double? get liquidatedAmountCop => _liquidatedAmountCop;
  EventModel? get nextEvent => _nextEvent;
  List<ProductModel> get latestProducts => _latestProducts;
  String? get userName => _userName ?? _tokenService.getUserName();
  String? get userAvatarUrl => _userAvatarUrl;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasHydratedSessionData => _hasHydratedSessionData;

  String _cacheKey(String namespace, [String suffix = '']) {
    return _cache.scopedKey(
      namespace,
      role: _tokenService.getRole() ?? 'guest',
      userId: _tokenService.getUserId() ?? 'guest',
      suffix: suffix,
    );
  }

  Map<String, String> _getHeaders() {
    final token = _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Carga todos los datos del dashboard modelo
  Future<void> initialize({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await fetchDashboardData(forceRefresh: true);
      return;
    }

    if (_isLoading) return;

    if (_hasHydratedSessionData) {
      notifyListeners();
      return;
    }

    await fetchDashboardData();
  }

  Future<void> fetchDashboardData({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    _liquidatedAmountCop = null;
    _userName = _tokenService.getUserName();
    notifyListeners();

    try {
      await Future.wait([
        _fetchBalance(forceRefresh: forceRefresh),
        _fetchLatestLiquidationAmount(forceRefresh: forceRefresh),
        _fetchNextEvent(forceRefresh: forceRefresh),
        _fetchLatestProducts(forceRefresh: forceRefresh),
        _fetchUserInfo(forceRefresh: forceRefresh),
      ]);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _hasHydratedSessionData = _error == null;
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetSessionState() {
    _balance = null;
    _liquidatedAmountCop = null;
    _nextEvent = null;
    _latestProducts = [];
    _userName = null;
    _userAvatarUrl = null;
    _isLoading = false;
    _error = null;
    _hasHydratedSessionData = false;
    notifyListeners();
  }

  Future<void> _fetchBalance({bool forceRefresh = false}) async {
    try {
      final cacheKey = _cacheKey('dashboard_modelo::balance');
      if (!forceRefresh) {
        final cachedBody = await _cache.read(cacheKey);
        if (cachedBody != null) {
          final json = jsonDecode(cachedBody);
          final data = json is Map ? json['data'] ?? json : json;
          _balance = ModelBalanceModel.fromJson(data as Map<String, dynamic>);
          return;
        }
      }

      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.modelsBalance}',
      );
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('Tiempo agotado'),
          );
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json is Map ? json['data'] ?? json : json;
        _balance = ModelBalanceModel.fromJson(data as Map<String, dynamic>);
        await _cache.write(cacheKey, response.body);
      } else {
        _balance = ModelBalanceModel(amount: 0);
      }
    } catch (_) {
      _balance = ModelBalanceModel(amount: 0);
    }
  }

  Future<void> _fetchLatestLiquidationAmount({
    bool forceRefresh = false,
  }) async {
    try {
      final modelId = _tokenService.getUserId();
      if (modelId == null || modelId.isEmpty) {
        _liquidatedAmountCop = null;
        return;
      }

      final cacheKey = _cacheKey('dashboard_modelo::liquidation');
      if (!forceRefresh) {
        final cachedBody = await _cache.read(cacheKey);
        if (cachedBody != null) {
          final body = jsonDecode(cachedBody);
          final filtered = _extractFilteredLiquidations(body, modelId);
          if (filtered.isEmpty) {
            _liquidatedAmountCop = null;
            return;
          }
          _liquidatedAmountCop = _extractCopAmount(filtered.first);
          return;
        }
      }

      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.productionsLiquidations}'
        '?id_model=$modelId&per_page=1',
      );
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('Tiempo agotado'),
          );
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode != 200) {
        _liquidatedAmountCop = null;
        return;
      }

      final body = jsonDecode(response.body);
      final filtered = _extractFilteredLiquidations(body, modelId);

      if (filtered.isEmpty) {
        _liquidatedAmountCop = null;
        return;
      }

      final first = filtered.first;
      _liquidatedAmountCop = _extractCopAmount(first);
      await _cache.write(cacheKey, response.body);
    } catch (_) {
      _liquidatedAmountCop = null;
    }
  }

  List<Map<String, dynamic>> _extractFilteredLiquidations(
    dynamic body,
    String modelId,
  ) {
    List<dynamic> list;
    if (body is List) {
      list = body;
    } else if (body is Map) {
      final data = body['data'];
      if (data is List) {
        list = data;
      } else if (data is Map && data['data'] is List) {
        list = data['data'] as List<dynamic>;
      } else if (body['items'] is List) {
        list = body['items'] as List<dynamic>;
      } else {
        list = [];
      }
    } else {
      list = [];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .where((item) {
          final recordModelId = item['id_model']?.toString().trim() ?? '';
          return recordModelId.isEmpty || recordModelId == modelId;
        })
        .toList(growable: false);
  }

  double? _extractCopAmount(Map<String, dynamic> liquidation) {
    final finalPayment = liquidation['final_payment'];

    final candidates = [
      liquidation['total_cop'],
      liquidation['final_amount_cop'],
      liquidation['amount_cop'],
      finalPayment is Map ? finalPayment['final_amount_cop'] : null,
      finalPayment is Map ? finalPayment['amount_cop'] : null,
    ];

    for (final value in candidates) {
      final parsed = _tryParseDouble(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  double? _tryParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      String sanitized = value.replaceAll(RegExp(r'[^0-9,.-]'), '').trim();
      if (sanitized.isEmpty) return null;

      final hasComma = sanitized.contains(',');
      final hasDot = sanitized.contains('.');
      if (hasComma && hasDot) {
        if (sanitized.lastIndexOf(',') > sanitized.lastIndexOf('.')) {
          // 1.234,56 -> 1234.56
          sanitized = sanitized.replaceAll('.', '').replaceAll(',', '.');
        } else {
          // 1,234.56 -> 1234.56
          sanitized = sanitized.replaceAll(',', '');
        }
      } else if (hasComma) {
        sanitized = sanitized.replaceAll(',', '.');
      }

      return double.tryParse(sanitized);
    }
    return null;
  }

  Future<void> _fetchNextEvent({bool forceRefresh = false}) async {
    try {
      final cacheKey = _cacheKey('dashboard_modelo::next_event');
      if (!forceRefresh) {
        final cachedBody = await _cache.read(cacheKey);
        if (cachedBody != null) {
          final json = jsonDecode(cachedBody);
          final list = _extractEventList(json);
          if (list.isNotEmpty) {
            _nextEvent = _pickNextEvent(list);
            return;
          }
        }
      }

      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.eventsList}',
      );
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('Tiempo agotado'),
          );
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final list = _extractEventList(json);
        if (list.isNotEmpty) {
          _nextEvent = _pickNextEvent(list);
          await _cache.write(cacheKey, response.body);
        } else {
          _nextEvent = null;
        }
      } else {
        _nextEvent = null;
      }
    } catch (_) {
      _nextEvent = null;
    }
  }

  List<Map<String, dynamic>> _extractEventList(dynamic json) {
    if (json is List) return json.whereType<Map<String, dynamic>>().toList();
    if (json is Map) {
      final data = json['data'] ?? json['events'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
    }
    return [];
  }

  EventModel? _pickNextEvent(List<Map<String, dynamic>> list) {
    final now = DateTime.now();
    final events = list
        .map((e) => EventModel.fromJson(e))
        .where((e) => e.stateEvent)
        .toList()
      ..sort((a, b) {
        final cmp = a.startEvent.compareTo(b.startEvent);
        if (cmp != 0) return cmp;
        return a.startTime.compareTo(b.startTime);
      });

    for (final e in events) {
      final start = _parseEventStart(e);
      if (start != null && start.isAfter(now)) return e;
    }
    return events.isNotEmpty ? events.first : null;
  }

  DateTime? _parseEventStart(EventModel e) {
    final dateStr = e.startEvent.trim();
    final timeStr = e.startTime.trim();
    if (dateStr.isEmpty) return null;
    final timePart = timeStr.length >= 5 ? timeStr.substring(0, 5) : '09:00';
    return DateTime.tryParse('$dateStr $timePart');
  }

  Future<void> _fetchLatestProducts({bool forceRefresh = false}) async {
    try {
      final shop = ShopComponent();
      await shop.initialize(forceRefresh: forceRefresh);
      _latestProducts = shop.allProducts.take(3).toList();
    } catch (_) {
      _latestProducts = [];
    }
  }

  Future<void> _fetchUserInfo({bool forceRefresh = false}) async {
    try {
      final cacheKey = _cacheKey('dashboard_modelo::me');
      if (!forceRefresh) {
        final cachedBody = await _cache.read(cacheKey);
        if (cachedBody != null) {
          final json = jsonDecode(cachedBody) as Map<String, dynamic>;
          final user = json['data'] ?? json['user'] ?? json;
          if (user is Map<String, dynamic>) {
            _userName =
                user['name'] as String? ??
                user['name_user'] as String? ??
                _userName;
            if (_userName != null && _userName!.trim().isNotEmpty) {
              _tokenService.setUserName(_userName!.trim());
            }
            _userAvatarUrl =
                user['avatar_url'] as String? ??
                user['avatar'] as String? ??
                user['photo_url'] as String?;
          }
          return;
        }
      }

      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.authMe}',
      );
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('Tiempo agotado'),
          );
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final user = json['data'] ?? json['user'] ?? json;
        if (user is Map<String, dynamic>) {
          _userName =
              user['name'] as String? ??
              user['name_user'] as String? ??
              _userName;
          if (_userName != null && _userName!.trim().isNotEmpty) {
            _tokenService.setUserName(_userName!.trim());
          }
          _userAvatarUrl =
              user['avatar_url'] as String? ??
              user['avatar'] as String? ??
              user['photo_url'] as String?;
          await _cache.write(cacheKey, response.body);
        }
      }
    } catch (_) {}
  }
}
