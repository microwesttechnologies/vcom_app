import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/session_cache.service.dart';
import 'package:vcom_app/core/common/session_state_registry.service.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/dashboard_modelo.model.dart';
import 'package:vcom_app/core/models/production.model.dart';

class WalletComponent extends ChangeNotifier {
  static final WalletComponent _instance = WalletComponent._internal();
  factory WalletComponent() => _instance;

  WalletComponent._internal() {
    _calculateDateRanges();
    SessionStateRegistryService().register(
      'wallet_component',
      resetSessionState,
    );
  }

  final SessionCacheService _cache = SessionCacheService();

  // ── Estado ──────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _error;

  ModelBalanceModel? _balance;
  double _trmValue = 0;
  List<ProductionRecord> _weeklyProductions = [];
  List<ProductionRecord> _monthlyProductions = [];
  List<LiquidationRecord> _liquidations = [];
  List<ProductionRecord> _lastLiquidationProductions = [];

  // Semana seleccionada por el usuario en el buscador
  List<ProductionRecord> _selectedWeekProductions = [];
  LiquidationRecord? _selectedWeekLiquidation;
  bool _isLoadingWeekData = false;
  bool _hasHydratedSessionData = false;

  // ── Rango de fechas calculado ────────────────────────────────────────────────
  late DateTime _weekStart;
  late DateTime _weekEnd;
  late DateTime _monthStart;
  late DateTime _monthEnd;

  // ── Getters ─────────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  ModelBalanceModel? get balance => _balance;
  double get trmValue => _trmValue;
  List<ProductionRecord> get weeklyProductions =>
      List.unmodifiable(_weeklyProductions);
  List<ProductionRecord> get monthlyProductions =>
      List.unmodifiable(_monthlyProductions);
  List<LiquidationRecord> get liquidations => List.unmodifiable(_liquidations);
  List<ProductionRecord> get lastLiquidationProductions =>
      List.unmodifiable(_lastLiquidationProductions);

  /// Última liquidación (la más reciente)
  LiquidationRecord? get lastLiquidation =>
      _liquidations.isNotEmpty ? _liquidations.first : null;

  List<ProductionRecord> get selectedWeekProductions =>
      List.unmodifiable(_selectedWeekProductions);
  LiquidationRecord? get selectedWeekLiquidation => _selectedWeekLiquidation;
  bool get isLoadingWeekData => _isLoadingWeekData;
  bool get hasHydratedSessionData => _hasHydratedSessionData;

  DateTime get weekStart => _weekStart;
  DateTime get weekEnd => _weekEnd;

  /// Total de horas trabajadas en la semana actual
  double get weeklyHours =>
      _weeklyProductions.fold(0.0, (sum, r) => sum + r.hoursWorked);

  /// Total de horas trabajadas en el mes actual
  double get monthlyHours =>
      _monthlyProductions.fold(0.0, (sum, r) => sum + r.hoursWorked);

  /// Horas trabajadas en el período de la última liquidación
  double get lastLiquidationHours =>
      _lastLiquidationProductions.fold(0.0, (sum, r) => sum + r.hoursWorked);

  /// Ganancias totales de la semana en USD
  double get weeklyEarningsUsd =>
      _weeklyProductions.fold(0.0, (sum, r) => sum + r.earningsUsd);

  String _cacheKey(String namespace, [String suffix = '']) {
    final token = TokenService();
    return _cache.scopedKey(
      namespace,
      role: token.getRole() ?? 'guest',
      userId: token.getUserId() ?? 'guest',
      suffix: suffix,
    );
  }

  // ── Inicializar ──────────────────────────────────────────────────────────────
  Future<void> initialize({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await fetchWalletData(forceRefresh: true);
      return;
    }

    if (_isLoading || _isLoadingWeekData) return;

    if (_hasHydratedSessionData) {
      notifyListeners();
      return;
    }

    await fetchWalletData();
  }

  // ── Carga principal ──────────────────────────────────────────────────────────
  Future<void> fetchWalletData({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    _balance = null;
    _trmValue = 0;
    _weeklyProductions = [];
    _monthlyProductions = [];
    _liquidations = [];
    _lastLiquidationProductions = [];
    _selectedWeekProductions = [];
    _selectedWeekLiquidation = null;
    _calculateDateRanges();
    notifyListeners();

    // Primera ronda: balance, TRM, producciones actuales y lista de liquidaciones
    await Future.wait([
      _fetchBalance(forceRefresh: forceRefresh),
      _fetchTrm(forceRefresh: forceRefresh),
      _fetchWeeklyProductions(forceRefresh: forceRefresh),
      _fetchMonthlyProductions(forceRefresh: forceRefresh),
      _fetchLiquidations(forceRefresh: forceRefresh),
    ]);

    // Segunda ronda: producciones del último período liquidado (depende de _liquidations)
    await _fetchLastLiquidationProductions(forceRefresh: forceRefresh);

    // Inicializar semana seleccionada con la última liquidación
    final last = lastLiquidation;
    if (last != null) {
      _selectedWeekProductions = _lastLiquidationProductions;
      _selectedWeekLiquidation = last;
    }

    _isLoading = false;
    assert(() {
      debugPrint(
        '[Wallet] liquidations=${_liquidations.length}, '
        'selectedLiq=${_selectedWeekLiquidation?.idLiquidation}, '
        'selectedTotalCop=${_selectedWeekLiquidation?.totalCop}, '
        'balance=${_balance?.amount} ${_balance?.currency}, '
        'trm=$_trmValue, selectedProductions=${_selectedWeekProductions.length}',
      );
      return true;
    }());
    _hasHydratedSessionData = _error == null;
    notifyListeners();
  }

  // ── Cálculo de fechas (semana domingo-sábado, mes) ───────────────────────────
  void _calculateDateRanges() {
    final now = DateTime.now();
    // weekday: 1=Lun ... 7=Dom
    final daysFromSunday = now.weekday == 7 ? 0 : now.weekday;
    final sunday = DateTime(now.year, now.month, now.day - daysFromSunday);
    _weekStart = sunday;
    _weekEnd = sunday.add(const Duration(days: 6));
    _monthStart = DateTime(now.year, now.month, 1);
    // Primer día del mes siguiente menos 1 día = último día del mes actual
    _monthEnd = DateTime(now.year, now.month + 1, 0);
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Fetch saldo ──────────────────────────────────────────────────────────────
  Future<void> _fetchBalance({bool forceRefresh = false}) async {
    try {
      final token = TokenService();
      final cacheKey = _cacheKey('wallet::balance');
      if (!forceRefresh) {
        final cachedBody = await _cache.read(cacheKey);
        if (cachedBody != null) {
          final body = jsonDecode(cachedBody);
          final data = body is Map ? (body['data'] ?? body) : body;
          _balance = ModelBalanceModel.fromJson(data as Map<String, dynamic>);
          return;
        }
      }

      final uri = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.modelsBalance}',
      );
      final res = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ...token.getAuthHeaders(),
            },
          )
          .timeout(const Duration(seconds: 10));
      token.handleUnauthorizedStatus(res.statusCode);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body is Map ? (body['data'] ?? body) : body;
        _balance = ModelBalanceModel.fromJson(data as Map<String, dynamic>);
        await _cache.write(cacheKey, res.body);
      }
    } catch (_) {}
  }

  // ── Fetch TRM ────────────────────────────────────────────────────────────────
  Future<void> _fetchTrm({bool forceRefresh = false}) async {
    try {
      final token = TokenService();
      final cacheKey = _cacheKey('wallet::trm');
      if (!forceRefresh) {
        final cachedBody = await _cache.read(cacheKey);
        if (cachedBody != null) {
          final body = jsonDecode(cachedBody);
          final data = body is Map ? (body['data'] ?? body) : body;
          if (data is Map) {
            _trmValue = (data['trm_value'] as num?)?.toDouble() ?? 0.0;
          }
          return;
        }
      }

      final uri = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.trmLatest}',
      );
      final res = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ...token.getAuthHeaders(),
            },
          )
          .timeout(const Duration(seconds: 10));
      token.handleUnauthorizedStatus(res.statusCode);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body is Map ? (body['data'] ?? body) : body;
        if (data is Map) {
          _trmValue = (data['trm_value'] as num?)?.toDouble() ?? 0.0;
          await _cache.write(cacheKey, res.body);
        }
      }
    } catch (_) {}
  }

  // ── Fetch producciones semanales ─────────────────────────────────────────────
  Future<void> _fetchWeeklyProductions({bool forceRefresh = false}) async {
    _weeklyProductions = await _fetchProductions(
      _fmt(_weekStart),
      _fmt(_weekEnd),
      forceRefresh: forceRefresh,
    );
  }

  // ── Fetch producciones mensuales ─────────────────────────────────────────────
  Future<void> _fetchMonthlyProductions({bool forceRefresh = false}) async {
    _monthlyProductions = await _fetchProductions(
      _fmt(_monthStart),
      _fmt(_monthEnd),
      forceRefresh: forceRefresh,
    );
  }

  Future<List<ProductionRecord>> _fetchProductions(
    String startDate,
    String endDate, {
    bool forceRefresh = false,
  }) async {
    try {
      final token = TokenService();
      final modelId = token.getUserId();
      if (modelId == null || modelId.isEmpty) return [];

      final cacheKey = _cacheKey('wallet::productions', '$startDate::$endDate');
      if (!forceRefresh) {
        final cachedBody = await _cache.read(cacheKey);
        if (cachedBody != null) {
          final body = jsonDecode(cachedBody);
          List<dynamic> list;
          if (body is List) {
            list = body;
          } else if (body is Map) {
            list = _extractListFromResponse(body);
          } else {
            list = [];
          }
          return list
              .map((e) => ProductionRecord.fromJson(e as Map<String, dynamic>))
              .where(
                (record) => record.idModel.isEmpty || record.idModel == modelId,
              )
              .toList();
        }
      }

      final uri = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.productionsByModel(modelId)}'
        '?start_date=$startDate&end_date=$endDate',
      );
      final res = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ...token.getAuthHeaders(),
            },
          )
          .timeout(const Duration(seconds: 15));
      token.handleUnauthorizedStatus(res.statusCode);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List<dynamic> list;
        if (body is List) {
          list = body;
        } else if (body is Map) {
          list = _extractListFromResponse(body);
        } else {
          list = [];
        }
        // Debug: mostrar las claves del primer registro para detectar campo de ganancias
        if (list.isNotEmpty && list.first is Map) {
          debugPrint(
            '[Wallet][Production] keys=${(list.first as Map).keys.toList()}',
          );
          debugPrint('[Wallet][Production] first=${list.first}');
        }
        final records = list
            .map((e) => ProductionRecord.fromJson(e as Map<String, dynamic>))
            .where(
              (record) => record.idModel.isEmpty || record.idModel == modelId,
            )
            .toList();
        await _cache.write(cacheKey, res.body);
        return records;
      }
    } catch (e) {
      debugPrint('[Wallet][Production] error=$e');
    }
    return [];
  }

  // ── Fetch liquidaciones (historial de desprendibles) ─────────────────────────
  Future<void> _fetchLiquidations({bool forceRefresh = false}) async {
    try {
      final token = TokenService();
      final modelId = token.getUserId();
      if (modelId == null || modelId.isEmpty) return;

      final cacheKey = _cacheKey('wallet::liquidations');
      if (!forceRefresh) {
        final cachedBody = await _cache.read(cacheKey);
        if (cachedBody != null) {
          final body = jsonDecode(cachedBody);
          List<dynamic> list;
          if (body is List) {
            list = body;
          } else if (body is Map) {
            list = _extractListFromResponse(body);
          } else {
            list = [];
          }
          _liquidations = list
              .map((e) => LiquidationRecord.fromJson(e as Map<String, dynamic>))
              .where(
                (record) => record.idModel.isEmpty || record.idModel == modelId,
              )
              .toList();
          _liquidations.sort(
            (a, b) => b.liquidationDate.compareTo(a.liquidationDate),
          );
          return;
        }
      }

      final uri = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.productionsLiquidations}'
        '?id_model=$modelId&per_page=50',
      );
      final res = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ...token.getAuthHeaders(),
            },
          )
          .timeout(const Duration(seconds: 15));
      token.handleUnauthorizedStatus(res.statusCode);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List<dynamic> list;
        if (body is List) {
          list = body;
        } else if (body is Map) {
          list = _extractListFromResponse(body);
        } else {
          list = [];
        }
        _liquidations = list
            .map((e) => LiquidationRecord.fromJson(e as Map<String, dynamic>))
            .where(
              (record) => record.idModel.isEmpty || record.idModel == modelId,
            )
            .toList();
        // Más reciente primero
        _liquidations.sort(
          (a, b) => b.liquidationDate.compareTo(a.liquidationDate),
        );
        await _cache.write(cacheKey, res.body);
      }
    } catch (_) {}
  }

  // ── Fetch producciones de la última liquidación ───────────────────────────────
  Future<void> _fetchLastLiquidationProductions({
    bool forceRefresh = false,
  }) async {
    final last = lastLiquidation;
    if (last == null || last.startDate.isEmpty || last.endDate.isEmpty) {
      _lastLiquidationProductions = [];
      return;
    }
    _lastLiquidationProductions = await _fetchProductions(
      last.startDate,
      last.endDate,
      forceRefresh: forceRefresh,
    );
  }

  // ── Cargar datos de una semana específica ────────────────────────────────────
  Future<void> fetchWeekData(
    String startDate,
    String endDate, {
    bool forceRefresh = false,
  }) async {
    _isLoadingWeekData = true;
    notifyListeners();

    _selectedWeekProductions = await _fetchProductions(
      startDate,
      endDate,
      forceRefresh: forceRefresh,
    );

    // Buscar si esa semana ya tiene una liquidación registrada
    _selectedWeekLiquidation = _liquidations
        .cast<LiquidationRecord?>()
        .firstWhere(
          (l) =>
              _normalizeIsoDate(l!.startDate) == _normalizeIsoDate(startDate) &&
              _normalizeIsoDate(l.endDate) == _normalizeIsoDate(endDate),
          orElse: () => null,
        );

    _isLoadingWeekData = false;
    assert(() {
      debugPrint(
        '[Wallet] week=$startDate..$endDate, '
        'productions=${_selectedWeekProductions.length}, '
        'weekLiq=${_selectedWeekLiquidation?.idLiquidation}, '
        'weekTotalCop=${_selectedWeekLiquidation?.totalCop}',
      );
      return true;
    }());
    notifyListeners();
  }

  List<dynamic> _extractListFromResponse(Map<dynamic, dynamic> body) {
    final data = body['data'];
    if (data is List) return data;
    if (data is Map) {
      if (data['data'] is List) return data['data'] as List<dynamic>;
      if (data['items'] is List) return data['items'] as List<dynamic>;
      if (data['rows'] is List) return data['rows'] as List<dynamic>;
    }
    if (body['items'] is List) return body['items'] as List<dynamic>;
    if (body['rows'] is List) return body['rows'] as List<dynamic>;
    return [];
  }

  String _normalizeIsoDate(String value) {
    if (value.isEmpty) return '';
    return value.length >= 10 ? value.substring(0, 10) : value;
  }

  // ── Fetch deducciones del modelo por período ─────────────────────────────────
  Future<List<DeductionRecord>> fetchDeductions(
    String startDate,
    String endDate, {
    bool forceRefresh = false,
  }) async {
    try {
      final token = TokenService();
      final modelId = token.getUserId();
      if (modelId == null || modelId.isEmpty) return [];

      final cacheKey = _cacheKey('wallet::deductions', '$startDate::$endDate');
      if (!forceRefresh) {
        final cachedBody = await _cache.read(cacheKey);
        if (cachedBody != null) {
          final body = jsonDecode(cachedBody);
          List<dynamic> list;
          if (body is List) {
            list = body;
          } else if (body is Map) {
            list = _extractListFromResponse(body);
          } else {
            list = [];
          }
          return list
              .map((e) => DeductionRecord.fromJson(e as Map<String, dynamic>))
              .where(
                (record) => record.idModel.isEmpty || record.idModel == modelId,
              )
              .toList();
        }
      }

      final uri = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.deductionsByModel(modelId)}'
        '?start_date=$startDate&end_date=$endDate',
      );
      final res = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ...token.getAuthHeaders(),
            },
          )
          .timeout(const Duration(seconds: 15));
      token.handleUnauthorizedStatus(res.statusCode);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List<dynamic> list;
        if (body is List) {
          list = body;
        } else if (body is Map) {
          list = _extractListFromResponse(body);
        } else {
          list = [];
        }
        final records = list
            .map((e) => DeductionRecord.fromJson(e as Map<String, dynamic>))
            .where(
              (record) => record.idModel.isEmpty || record.idModel == modelId,
            )
            .toList();
        await _cache.write(cacheKey, res.body);
        return records;
      }
    } catch (e) {
      debugPrint('[Wallet] fetchDeductions error: $e');
    }
    return [];
  }

  // ── Calcular y obtener un desprendible ───────────────────────────────────────
  Future<LiquidationDetail?> fetchDesprendible(
    String startDate,
    String endDate, {
    bool forceRefresh = false,
  }) async {
    try {
      final token = TokenService();
      final modelId = token.getUserId();
      if (modelId == null || modelId.isEmpty) return null;

      final cacheKey = _cacheKey(
        'wallet::desprendible',
        '$startDate::$endDate',
      );
      if (!forceRefresh) {
        final cachedBody = await _cache.read(cacheKey);
        if (cachedBody != null) {
          final body = jsonDecode(cachedBody);
          final data = body is Map ? (body['data'] ?? body) : body;
          return LiquidationDetail.fromJson(data as Map<String, dynamic>);
        }
      }

      final uri = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.productionsCalculatePayment}',
      );
      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ...token.getAuthHeaders(),
            },
            body: jsonEncode({
              'id_model': modelId,
              'start_date': startDate,
              'end_date': endDate,
            }),
          )
          .timeout(const Duration(seconds: 20));
      token.handleUnauthorizedStatus(res.statusCode);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        final data = body is Map ? (body['data'] ?? body) : body;
        await _cache.write(cacheKey, res.body);
        return LiquidationDetail.fromJson(data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('fetchDesprendible error: $e');
    }
    return null;
  }

  Future<void> refresh() async {
    await fetchWalletData(forceRefresh: true);
  }

  void resetSessionState() {
    _isLoading = false;
    _error = null;
    _balance = null;
    _trmValue = 0;
    _weeklyProductions = [];
    _monthlyProductions = [];
    _liquidations = [];
    _lastLiquidationProductions = [];
    _selectedWeekProductions = [];
    _selectedWeekLiquidation = null;
    _isLoadingWeekData = false;
    _hasHydratedSessionData = false;
    _calculateDateRanges();
    notifyListeners();
  }
}
