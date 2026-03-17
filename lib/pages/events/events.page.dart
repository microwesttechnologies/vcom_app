import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vcom_app/components/shared/modelo_menubar.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/event.model.dart';
import 'package:vcom_app/pages/events/event_detail.page.dart';
import 'package:vcom_app/pages/events/event_form.page.dart';
import 'package:vcom_app/pages/events/events.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final EventsComponent _component = EventsComponent();
  final TokenService _tokenService = TokenService();
  final TextEditingController _searchController = TextEditingController();

  bool get _canManageEvents {
    final role = (_tokenService.getRole() ?? '').trim().toUpperCase();
    return role == 'MONITOR' || role == 'ADMIN';
  }

  @override
  void initState() {
    super.initState();
    _component.addListener(_onChanged);
    _component.initialize();
  }

  @override
  void dispose() {
    _component.removeListener(_onChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final years = _component.getAvailableYears();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: const ModeloNavbar(),
      bottomNavigationBar: const ModeloMenuBar(activeRoute: 'event'),
      floatingActionButton: _canManageEvents && _component.canCreateEvents
          ? FloatingActionButton(
              onPressed: _openCreateEvent,
              backgroundColor: VcomColors.oroLujoso,
              foregroundColor: VcomColors.azulMedianocheTexto,
              child: const Icon(Icons.add),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.8),
            radius: 1.2,
            colors: [
              Color(0xFF273C67),
              Color(0xFF1a2847),
              Color(0xFF0d1525),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _component.refresh,
            color: VcomColors.oroLujoso,
            backgroundColor: VcomColors.azulZafiroProfundo,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                _buildSearchBar(),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _buildMonthDropdown()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownShell(
                        child: DropdownButton<int>(
                          value: _component.selectedYear,
                          isExpanded: true,
                          isDense: true,
                          underline: const SizedBox.shrink(),
                          dropdownColor: const Color(0xFF1A2740),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          iconSize: 22,
                          items: years
                              .map(
                                (year) => DropdownMenuItem(
                                  value: year,
                                  child: Text('$year'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _component.setYear(value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_component.isLoading && _component.allEvents.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: CircularProgressIndicator(color: VcomColors.oroLujoso),
                    ),
                  )
                else if (_component.error != null && _component.allEvents.isEmpty)
                  _buildErrorState()
                else if (_component.events.isEmpty)
                  _buildEmptyState()
                else
                  ..._component.events.map(_buildEventCard),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Buscar evento',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.6),
            size: 20,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        onChanged: _component.setSearchQuery,
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return _buildDropdownShell(
      child: DropdownButton<int?>(
        value: _component.selectedMonth,
        isExpanded: true,
        isDense: true,
        underline: const SizedBox.shrink(),
        dropdownColor: const Color(0xFF1A2740),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        iconSize: 22,
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('Todos'),
          ),
          ...List.generate(
            12,
            (index) => DropdownMenuItem<int?>(
              value: index + 1,
              child: Text(_monthName(index + 1)),
            ),
          ),
        ],
        onChanged: _component.setMonth,
      ),
    );
  }

  Widget _buildDropdownShell({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF506182).withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final startDate = DateTime.tryParse(event.startEvent);
    final dayLabel = startDate != null ? DateFormat('dd').format(startDate) : '--';
    final monthLabel = startDate != null ? DateFormat('MMM', 'es').format(startDate) : '--';
    final yearLabel = startDate != null ? DateFormat('yyyy').format(startDate) : '--';

    final loc = event.locationEvent?.trim() ?? '';
    final locParts = loc.contains(',') ? loc.split(',').map((s) => s.trim()).toList() : [loc];
    final locationName = locParts.isNotEmpty && locParts[0].isNotEmpty ? locParts[0] : 'Ubicación por definir';
    final locationSubtitle = locParts.length > 1 && locParts[1].isNotEmpty
        ? locParts[1]
        : (event.descriptionEvent?.trim().isNotEmpty == true ? event.descriptionEvent!.trim() : '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        onTap: () => _openDetail(event),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 12, 12, 12),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 150,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                      child: SizedBox.expand(
                        child: event.imageEvent?.isNotEmpty == true
                            ? Image.network(
                                event.imageEvent!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) =>
                                    _imagePlaceholder(),
                              )
                            : _imagePlaceholder(),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              const Color.fromARGB(255, 0, 0, 0),
                              const Color.fromARGB(0, 0, 0, 0).withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 130,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            event.titleEvent,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 5,
                      top: 18,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            width: 90,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFFD7E2FF).withValues(alpha: 0.14),
                                  const Color(0xFF42547B).withValues(alpha: 0.28),
                                  const Color(0xFF1A2740).withValues(alpha: 0.48),
                                ],
                                stops: const [0.0, 0.42, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.24),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$dayLabel DE ${monthLabel.toUpperCase()}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  yearLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    // color: Colors.white.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.10),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        _formatTime(event.startTime),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'HORA',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.4),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.fromLTRB(20, 10, 14, 18),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(5),
                        bottomRight: Radius.circular(5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (locationSubtitle.isNotEmpty) ...[
                          Text(
                            locationSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: VcomColors.oroLujoso,
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            const Icon(Icons.event_busy, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _component.error ?? 'No se pudieron cargar los eventos',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 56,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay eventos para los filtros actuales',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFF1A2740),
      child: Icon(
        Icons.event,
        size: 52,
        color: Colors.white.withValues(alpha: 0.25),
      ),
    );
  }

  Future<void> _openCreateEvent() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EventFormPage()),
    );
    if (created == true) {
      await _component.fetchEvents();
    }
  }

  Future<void> _openDetail(EventModel event) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventDetailPage(event: event),
      ),
    );
    if (result == true) {
      await _component.fetchEvents();
    }
  }

  String _monthName(int month) {
    final date = DateTime(2026, month, 1);
    return DateFormat('MMMM', 'es').format(date);
  }

  String _formatTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final parsed = DateTime(2026, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat('HH:mm').format(parsed);
  }
}
