import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/permission.service.dart';
import 'package:vcom_app/core/common/session_cache.service.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/event.model.dart';

class EventsComponent extends ChangeNotifier {
  final TokenService _tokenService = TokenService();
  final PermissionService _permissionService = PermissionService();
  final SessionCacheService _cache = SessionCacheService();

  List<EventModel> _events = [];
  List<EventModel> _filteredEvents = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  int? _selectedMonth;
  int _selectedYear = DateTime.now().year;

  List<EventModel> get events => _filteredEvents;
  List<EventModel> get allEvents => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int? get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  String _cacheKey(String namespace, [String suffix = '']) {
    return _cache.scopedKey(
      namespace,
      role: _tokenService.getRole() ?? 'guest',
      userId: _tokenService.getUserId() ?? 'guest',
      suffix: suffix,
    );
  }

  bool get _isMonitorOrAdmin {
    final role = (_tokenService.getRole() ?? '').trim().toUpperCase();
    return role == 'MONITOR' || role == 'ADMIN';
  }

  bool get _canReadByRole {
    final role = (_tokenService.getRole() ?? '').trim().toUpperCase();
    return role == 'MONITOR' ||
        role == 'ADMIN' ||
        role == 'MODELO' ||
        role == 'MODEL' ||
        role == 'MODAL';
  }

  bool get canReadEvents =>
      _canReadByRole ||
      _permissionService.canReadModule(
        routeHints: const ['event', 'evento', 'calendar', 'calendario'],
      );
  bool get canCreateEvents =>
      _isMonitorOrAdmin ||
      _permissionService.canCreateModule(
        routeHints: const ['event', 'evento', 'calendar', 'calendario'],
      );
  bool get canUpdateEvents =>
      _isMonitorOrAdmin ||
      _permissionService.canUpdateModule(
        routeHints: const ['event', 'evento', 'calendar', 'calendario'],
      );
  bool get canDeleteEvents =>
      _isMonitorOrAdmin ||
      _permissionService.canDeleteModule(
        routeHints: const ['event', 'evento', 'calendar', 'calendario'],
      );

  Map<String, String> _headers() {
    final token = _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token?.isNotEmpty == true) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> initialize({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!canReadEvents) {
        throw Exception('No tienes permiso para ver eventos');
      }
      await fetchEvents(forceRefresh: forceRefresh);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEvents({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!canReadEvents) {
        throw Exception('No tienes permiso para ver eventos');
      }

      final cacheKey = _cacheKey('events::list');
      if (!forceRefresh) {
        final cachedBody = await _cache.read(cacheKey);
        if (cachedBody != null) {
          final dynamic jsonResponse = jsonDecode(cachedBody);
          final list = _extractList(jsonResponse);
          _events =
              list
                  .map(
                    (item) => EventModel.fromJson(item as Map<String, dynamic>),
                  )
                  .where((event) => event.stateEvent)
                  .toList()
                ..sort((a, b) => a.startEvent.compareTo(b.startEvent));
          _applyFilters();
          _error = null;
          return;
        }
      }

      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.eventsList}',
      );
      final response = await http.get(url, headers: _headers());
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode != 200) {
        throw Exception('Error al obtener eventos: ${response.statusCode}');
      }

      final dynamic jsonResponse = jsonDecode(response.body);
      final list = _extractList(jsonResponse);
      _events =
          list
              .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
              .where((event) => event.stateEvent)
              .toList()
            ..sort((a, b) => a.startEvent.compareTo(b.startEvent));
      await _cache.write(cacheKey, response.body);

      _applyFilters();
      _error = null;
    } catch (e) {
      _events = [];
      _filteredEvents = [];
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<EventModel?> getEventById(int id) async {
    try {
      final cacheKey = _cacheKey('events::detail', '$id');
      final cachedBody = await _cache.read(cacheKey);
      if (cachedBody != null) {
        final dynamic jsonResponse = jsonDecode(cachedBody);
        final eventJson = _extractSingle(jsonResponse);
        return EventModel.fromJson(eventJson);
      }

      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.eventsGet(id)}',
      );
      final response = await http.get(url, headers: _headers());
      _tokenService.handleUnauthorizedStatus(response.statusCode);
      if (response.statusCode != 200) {
        throw Exception('Error al obtener evento: ${response.statusCode}');
      }

      final dynamic jsonResponse = jsonDecode(response.body);
      final eventJson = _extractSingle(jsonResponse);
      await _cache.write(cacheKey, response.body);
      return EventModel.fromJson(eventJson);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<void> createEvent(EventModel event) async {
    if (!canCreateEvents) {
      throw Exception('No tienes permiso para crear eventos');
    }

    final url = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.eventsCreate}',
    );
    final payload = event.toCreateJson();
    debugPrint('EventsComponent.createEvent payload: ${jsonEncode(payload)}');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(payload),
    );
    _tokenService.handleUnauthorizedStatus(response.statusCode);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Error al crear evento: ${response.statusCode}${_buildErrorSuffix(response.body)}',
      );
    }

    await _cache.removeByPrefix(_cacheKey('events::detail'));
    await fetchEvents(forceRefresh: true);
  }

  Future<void> updateEvent(EventModel event) async {
    if (!canUpdateEvents) {
      throw Exception('No tienes permiso para actualizar eventos');
    }
    if (event.idEvent == null) {
      throw Exception('El evento no tiene ID para actualizar');
    }

    final url = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.eventsUpdate(event.idEvent!)}',
    );
    final payload = event.toJson();
    debugPrint('EventsComponent.updateEvent payload: ${jsonEncode(payload)}');
    final response = await http.put(
      url,
      headers: _headers(),
      body: jsonEncode(payload),
    );
    _tokenService.handleUnauthorizedStatus(response.statusCode);

    if (response.statusCode != 200) {
      throw Exception(
        'Error al actualizar evento: ${response.statusCode}${_buildErrorSuffix(response.body)}',
      );
    }

    await _cache.removeByPrefix(_cacheKey('events::detail'));
    await fetchEvents(forceRefresh: true);
  }

  Future<void> deleteEvent(int eventId) async {
    if (!canDeleteEvents) {
      throw Exception('No tienes permiso para eliminar eventos');
    }

    final url = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.eventsDelete(eventId)}',
    );
    final response = await http.delete(url, headers: _headers());
    _tokenService.handleUnauthorizedStatus(response.statusCode);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar evento: ${response.statusCode}');
    }

    await _cache.removeByPrefix(_cacheKey('events::detail'));
    await fetchEvents(forceRefresh: true);
  }

  void setSearchQuery(String value) {
    _searchQuery = value.trim();
    _applyFilters();
    notifyListeners();
  }

  void setMonth(int? value) {
    _selectedMonth = value;
    _applyFilters();
    notifyListeners();
  }

  void setYear(int value) {
    _selectedYear = value;
    _applyFilters();
    notifyListeners();
  }

  List<int> getAvailableYears() {
    final years =
        _events
            .map((event) => DateTime.tryParse(event.startEvent)?.year)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort();

    final currentYear = DateTime.now().year;
    for (var year = currentYear; year <= 2037; year++) {
      if (!years.contains(year)) {
        years.add(year);
      }
    }

    if (!years.contains(_selectedYear)) {
      years.add(_selectedYear);
    }

    if (years.isEmpty) {
      return [_selectedYear];
    }

    years.sort();
    return years;
  }

  Future<void> refresh() async {
    await fetchEvents(forceRefresh: true);
  }

  void _applyFilters() {
    _filteredEvents = _events.where((event) {
      final startDate = DateTime.tryParse(event.startEvent);
      final normalizedSearch = _searchQuery.toLowerCase();

      final matchesSearch =
          normalizedSearch.isEmpty ||
          event.titleEvent.toLowerCase().contains(normalizedSearch) ||
          (event.descriptionEvent?.toLowerCase().contains(normalizedSearch) ??
              false) ||
          (event.locationEvent?.toLowerCase().contains(normalizedSearch) ??
              false);

      final matchesMonth =
          _selectedMonth == null || startDate?.month == _selectedMonth;
      final matchesYear = startDate == null || startDate.year == _selectedYear;

      return matchesSearch && matchesMonth && matchesYear;
    }).toList();
  }

  List<dynamic> _extractList(dynamic jsonResponse) {
    if (jsonResponse is List) {
      return jsonResponse;
    }
    if (jsonResponse is Map<String, dynamic>) {
      if (jsonResponse['data'] is List) {
        return jsonResponse['data'] as List<dynamic>;
      }
      if (jsonResponse['events'] is List) {
        return jsonResponse['events'] as List<dynamic>;
      }
    }
    throw Exception('Formato de respuesta de eventos no válido');
  }

  Map<String, dynamic> _extractSingle(dynamic jsonResponse) {
    if (jsonResponse is Map<String, dynamic>) {
      if (jsonResponse['data'] is Map<String, dynamic>) {
        return jsonResponse['data'] as Map<String, dynamic>;
      }
      return jsonResponse;
    }
    throw Exception('Formato de evento no válido');
  }

  String _buildErrorSuffix(String body) {
    final message = _extractErrorMessage(body);
    if (message == null || message.isEmpty) {
      return '';
    }
    return ' - $message';
  }

  String? _extractErrorMessage(String body) {
    final raw = body.trim();
    if (raw.isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final candidates = [
          decoded['message'],
          decoded['error'],
          decoded['detail'],
        ];
        for (final candidate in candidates) {
          final text = candidate?.toString().trim();
          if (text != null && text.isNotEmpty) {
            return text;
          }
        }
      }
    } catch (_) {
      // Ignore non-JSON error bodies and fall back to plain text below.
    }

    return raw.length > 220 ? '${raw.substring(0, 220)}...' : raw;
  }
}
