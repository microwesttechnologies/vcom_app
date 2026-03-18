import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/core/common/permission.service.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/event.model.dart';
import 'package:vcom_app/pages/events/event_form.page.dart';
import 'package:vcom_app/pages/events/events.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class EventDetailPage extends StatefulWidget {
  final EventModel event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final EventsComponent _component = EventsComponent();
  final PermissionService _permissionService = PermissionService();
  final TokenService _tokenService = TokenService();

  late EventModel _event;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  bool get _canManageEvents {
    final role = (_tokenService.getRole() ?? '').trim().toUpperCase();
    return role == 'MONITOR' || role == 'ADMIN';
  }

  bool get _canUpdateEvents => _permissionService.canUpdateModule(
    routeHints: const ['event', 'evento', 'calendar', 'calendario'],
  );
  bool get _canDeleteEvents =>
      _canManageEvents ||
      _permissionService.canDeleteModule(
        routeHints: const ['event', 'evento', 'calendar', 'calendario'],
      );

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupItems(_event.itinerary?.items ?? const []);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: ModeloNavbar(
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pop(),
      ),
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
          child: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            children: [
              _buildHero(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Transform.translate(
                offset: const Offset(0, -16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_canManageEvents && (_canUpdateEvents || _canDeleteEvents))
                      _buildActions(),
                    if (_canManageEvents && (_canUpdateEvents || _canDeleteEvents))
                      const SizedBox(height: 12),
                    _buildInfoGrid(),
                    const SizedBox(height: 12),
                    if ((_event.linkAccess ?? '').isNotEmpty) _buildLinkCard(),
                    if ((_event.linkAccess ?? '').isNotEmpty)
                      const SizedBox(height: 12),
                    _buildDescription(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Itinerario',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: VcomColors.blancoCrema,
                          ),
                        ),
                        Text(
                          '${_event.itinerary?.items.length ?? 0} actividades',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (groupedItems.isEmpty)
                      Text(
                        'Este evento no tiene actividades cargadas.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      )
                    else
                      ...groupedItems.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildDayBlock(entry.key, entry.value),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    final imageUrl = _event.imageEvent;

    return Container(
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        image: imageUrl != null && imageUrl.isNotEmpty
            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
            : null,
        gradient: imageUrl == null || imageUrl.isEmpty
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF252D3D), Color(0xFF0B0F18)],
              )
            : null,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 52),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.12),
              Colors.black.withValues(alpha: 0.72),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              _event.titleEvent,
              style: const TextStyle(
                fontSize: 28,
                height: 1.05,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              _event.descriptionEvent?.trim().isNotEmpty == true
                  ? _event.descriptionEvent!
                  : 'Evento programado para el equipo.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (_canUpdateEvents)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _editEvent,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
            ),
          ),
        if (_canUpdateEvents && _canDeleteEvents) const SizedBox(width: 12),
        if (_canDeleteEvents)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _deleteEvent,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: BorderSide(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _infoCard(
                label: 'Fecha',
                value: _formatDateRange(_event.startEvent, _event.endEvent),
                icon: Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoCard(
                label: 'Hora',
                value: '${_formatTime(_event.startTime)}',
                icon: Icons.access_time,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _infoCard(
          label: 'Lugar',
          value: (_event.locationEvent ?? '').isNotEmpty
              ? _event.locationEvent!
              : 'Sin ubicación',
          icon: Icons.location_on,
        ),
      ],
    );
  }

  Widget _buildLinkCard() {
    final link = _event.linkAccess!;

    return _infoCard(
      label: 'Link de acceso',
      value: link,
      icon: Icons.link,
      trailing: IconButton(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: link));
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Link copiado')));
        },
        icon: const Icon(Icons.copy_rounded, color: Color.fromARGB(121, 255, 255, 255)),
        iconSize: 18,
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(32, 32),
        ),
      ),
      onTap: () => _openLink(link),
    );
  }

  Widget _buildDescription() {
    return _glassCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 12,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                'DESCRIPCION',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            _event.descriptionEvent?.trim().isNotEmpty == true
                ? _event.descriptionEvent!
                : 'Sin descripción adicional.',
            style: const TextStyle(
              color: VcomColors.oroLujoso,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayBlock(String date, List<EventItineraryItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horario ${_formatLongDate(date)}',
          style: const TextStyle(
            color: VcomColors.blancoCrema,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => _glassCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatTime(item.startTime)} - ${_formatTime(item.endTime)}',
                  style: const TextStyle(
                    color: VcomColors.oroLujoso,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: const TextStyle(
                    color: VcomColors.blancoCrema,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required String label,
    required String value,
    IconData? icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final content = _glassCard(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: VcomColors.oroLujoso,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: content,
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: const Color(0xFF23314A).withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Map<String, List<EventItineraryItem>> _groupItems(
    List<EventItineraryItem> items,
  ) {
    final grouped = <String, List<EventItineraryItem>>{};
    final sortedItems = List<EventItineraryItem>.from(items)
      ..sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;
        return a.startTime.compareTo(b.startTime);
      });

    for (final item in sortedItems) {
      final key = item.date.isEmpty ? _event.startEvent : item.date;
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return grouped;
  }

  Future<void> _openLink(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final hasValidScheme = trimmed.toLowerCase().startsWith('http://') ||
        trimmed.toLowerCase().startsWith('https://');
    if (!hasValidScheme) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El enlace debe comenzar con http:// o https://',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo abrir el enlace: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editEvent() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EventFormPage(initialEvent: _event)),
    );

    if (updated != true || !mounted || _event.idEvent == null) return;

    final refreshed = await _component.getEventById(_event.idEvent!);
    if (refreshed != null && mounted) {
      setState(() => _event = refreshed);
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: const Text('¿Seguro que deseas eliminar este evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || _event.idEvent == null) return;

    try {
      await _component.deleteEvent(_event.idEvent!);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateRange(String start, String end) {
    if (start == end) return _formatLongDate(start);
    return '${_formatLongDate(start)} - ${_formatLongDate(end)}';
  }

  String _formatLongDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('MMM d, y').format(parsed);
  }

  String _formatTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final parsed = DateTime(
      2026,
      1,
      1,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    return DateFormat('hh:mm a').format(parsed);
  }
}
