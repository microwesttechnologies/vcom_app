import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/dashboard_modelo.model.dart';

/// Componente del dashboard para rol MODELO
/// Obtiene saldo, usuario y próximo entrenamiento de los endpoints
class DashboardModeloComponent extends ChangeNotifier {
  final TokenService _tokenService = TokenService();

  ModelBalanceModel? _balance;
  double? _liquidatedAmountCop;
  NextTrainingModel? _nextTraining;
  String? _userName;
  String? _userAvatarUrl;
  bool _isLoading = false;
  String? _error;

  ModelBalanceModel? get balance => _balance;
  double? get liquidatedAmountCop => _liquidatedAmountCop;
  NextTrainingModel? get nextTraining => _nextTraining;
  String? get userName => _userName ?? _tokenService.getUserName();
  String? get userAvatarUrl => _userAvatarUrl;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, String> _getHeaders() {
    final token = _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Carga todos los datos del dashboard modelo
  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _error = null;
    _userName = _tokenService.getUserName();
    notifyListeners();

    try {
      await Future.wait([
        _fetchBalance(),
        _fetchLatestLiquidationAmount(),
        _fetchNextTraining(),
        _fetchUserInfo(),
      ]);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchBalance() async {
    try {
      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.modelsBalance}',
      );
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('Tiempo agotado'),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json is Map ? json['data'] ?? json : json;
        _balance = ModelBalanceModel.fromJson(data as Map<String, dynamic>);
      } else {
        _balance = ModelBalanceModel(amount: 0);
      }
    } catch (_) {
      _balance = ModelBalanceModel(amount: 0);
    }
  }

  Future<void> _fetchLatestLiquidationAmount() async {
    try {
      final modelId = _tokenService.getUserId();
      if (modelId == null || modelId.isEmpty) {
        _liquidatedAmountCop = null;
        return;
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

      if (response.statusCode != 200) {
        _liquidatedAmountCop = null;
        return;
      }

      final body = jsonDecode(response.body);
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

      if (list.isEmpty || list.first is! Map<String, dynamic>) {
        _liquidatedAmountCop = null;
        return;
      }

      final first = list.first as Map<String, dynamic>;
      _liquidatedAmountCop = _extractCopAmount(first);
    } catch (_) {
      _liquidatedAmountCop = null;
    }
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

  Future<void> _fetchNextTraining() async {
    try {
      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.modelsNextTraining}',
      );
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('Tiempo agotado'),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json is Map ? (json['data'] ?? json) : json;
        if (data != null) {
          _nextTraining = NextTrainingModel.fromJson(
            data as Map<String, dynamic>,
          );
        }
      }
      if (_nextTraining == null) {
        await _fetchFirstVideoAsFallback();
      }
    } catch (_) {
      await _fetchFirstVideoAsFallback();
    }
  }

  Future<void> _fetchFirstVideoAsFallback() async {
    try {
      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.videosList}',
      );
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('Tiempo agotado'),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        List<dynamic> list = json is List
            ? json
            : (json['data'] as List? ?? []);
        if (list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          _nextTraining = NextTrainingModel.fromVideo(first);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchUserInfo() async {
    try {
      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.authMe}',
      );
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('Tiempo agotado'),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final user = json['data'] ?? json['user'] ?? json;
        if (user is Map<String, dynamic>) {
          _userName =
              user['name'] as String? ??
              user['name_user'] as String? ??
              _userName;
          _userAvatarUrl =
              user['avatar_url'] as String? ??
              user['avatar'] as String? ??
              user['photo_url'] as String?;
        }
      }
    } catch (_) {}
  }
}
