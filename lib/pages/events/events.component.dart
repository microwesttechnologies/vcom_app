import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/permission.service.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/event.model.dart';

class EventsComponent extends ChangeNotifier {
  final TokenService _tokenService = TokenService();
  final PermissionService _permissionService = PermissionService();

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

  bool get _isMonitorOrAdmin {
    final role = (_tokenService.getRole() ?? '').trim().toUpperCase();
    return role == 'MONITOR' || role == 'ADMIN';
  }

  bool get canReadEvents => _permissionService.canReadModule(
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

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!canReadEvents) {
        throw Exception('No tienes permiso para ver eventos');
      }
      await fetchEvents();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!canReadEvents) {
        throw Exception('No tienes permiso para ver eventos');
      }

      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.eventsList}');
      final response = await http.get(url, headers: _headers());

      if (response.statusCode != 200) {
        throw Exception('Error al obtener eventos: ${response.statusCode}');
      }

      final dynamic jsonResponse = jsonDecode(response.body);
      final list = _extractList(jsonResponse);
      _events = list
          .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
          .where((event) => event.stateEvent)
          .toList()
        ..sort((a, b) => a.startEvent.compareTo(b.startEvent));

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
      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.eventsGet(id)}');
      final response = await http.get(url, headers: _headers());
      if (response.statusCode != 200) {
        throw Exception('Error al obtener evento: ${response.statusCode}');
      }

      final dynamic jsonResponse = jsonDecode(response.body);
      final eventJson = _extractSingle(jsonResponse);
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

    final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.eventsCreate}');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(event.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al crear evento: ${response.statusCode}');
    }

    await fetchEvents();
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
    final response = await http.put(
      url,
      headers: _headers(),
      body: jsonEncode(event.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar evento: ${response.statusCode}');
    }

    await fetchEvents();
  }

  Future<void> deleteEvent(int eventId) async {
    if (!canDeleteEvents) {
      throw Exception('No tienes permiso para eliminar eventos');
    }

    final url = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.eventsDelete(eventId)}',
    );
    final response = await http.delete(url, headers: _headers());

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar evento: ${response.statusCode}');
    }

    await fetchEvents();
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
    final years = _events
        .map((event) => DateTime.tryParse(event.startEvent)?.year)
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();

    if (!years.contains(_selectedYear)) {
      years.add(_selectedYear);
      years.sort();
    }

    if (years.isEmpty) {
      return [_selectedYear];
    }

    return years;
  }

  Future<void> refresh() async {
    await fetchEvents();
  }

  void _applyFilters() {
    _filteredEvents = _events.where((event) {
      final startDate = DateTime.tryParse(event.startEvent);
      final normalizedSearch = _searchQuery.toLowerCase();

      final matchesSearch = normalizedSearch.isEmpty ||
          event.titleEvent.toLowerCase().contains(normalizedSearch) ||
          (event.descriptionEvent?.toLowerCase().contains(normalizedSearch) ?? false) ||
          (event.locationEvent?.toLowerCase().contains(normalizedSearch) ?? false);

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
}
