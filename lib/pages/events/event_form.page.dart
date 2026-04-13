import 'dart:io';
import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/core/common/media_upload.service.dart';
import 'package:vcom_app/core/models/event.model.dart';
import 'package:vcom_app/pages/events/events.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class EventFormPage extends StatefulWidget {
  final EventModel? initialEvent;

  const EventFormPage({super.key, this.initialEvent});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _component = EventsComponent();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _linkController = TextEditingController();
  final _mediaUploadService = MediaUploadService();

  late String _startDate;
  late String _endDate;
  late String _startTime;
  late String _endTime;
  String? _imageUrl;
  File? _pendingImageFile;
  bool _stateEvent = true;
  bool _saving = false;
  bool _uploadingImage = false;
  List<EventItineraryItem> _items = [];

  bool get _isEditing => widget.initialEvent != null;

  @override
  void initState() {
    super.initState();
    final event = widget.initialEvent;
    final now = DateTime.now();
    _titleController.text = event?.titleEvent ?? '';
    _descriptionController.text = event?.descriptionEvent ?? '';
    _locationController.text = event?.locationEvent ?? '';
    _linkController.text = event?.linkAccess ?? '';
    _imageUrl = event?.imageEvent;
    _startDate = event?.startEvent ?? _formatDate(now);
    _endDate = event?.endEvent ?? _formatDate(now);
    _startTime = event?.startTime ?? '09:00:00';
    _endTime = event?.endTime ?? '11:00:00';
    _stateEvent = event?.stateEvent ?? true;
    _items = List<EventItineraryItem>.from(event?.itinerary?.items ?? const []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            radius: 1.3,
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    children: [
                      Text(
                        _isEditing ? 'Editar evento' : 'Nuevo evento',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: VcomColors.blancoCrema,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildField(
                        controller: _titleController,
                        label: 'Nombre evento',
                        hint: 'Escribe aquí el título',
                        icon: Icons.event_note_outlined,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Ingresa el nombre del evento'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      _buildField(
                        controller: _descriptionController,
                        label: 'Descripción',
                        hint: 'Describe el evento',
                        icon: Icons.edit_note_outlined,
                        minLines: 4,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        controller: _locationController,
                        label: 'Lugar',
                        hint: 'Ubicación',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        controller: _linkController,
                        label: 'Link acceso virtual',
                        hint: 'https://...',
                        icon: Icons.link,
                        suffixIcon: Icon(
                          Icons.open_in_new,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildImagePicker(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPickerCard(
                              label: 'Fecha inicio',
                              value: _formatDisplayDate(_startDate),
                              onTap: () async {
                                final value = await _pickDate(_startDate);
                                if (value != null) {
                                  setState(() => _startDate = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPickerCard(
                              label: 'Fecha fin',
                              value: _formatDisplayDate(_endDate),
                              onTap: () async {
                                final value = await _pickDate(_endDate);
                                if (value != null) {
                                  setState(() => _endDate = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPickerCard(
                              label: 'Inicio',
                              value: _formatDisplayTime(_startTime),
                              onTap: () async {
                                final value = await _pickTime(_startTime);
                                if (value != null) {
                                  setState(() => _startTime = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPickerCard(
                              label: 'Final',
                              value: _formatDisplayTime(_endTime),
                              onTap: () async {
                                final value = await _pickTime(_endTime);
                                if (value != null) {
                                  setState(() => _endTime = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Itinerario',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: VcomColors.blancoCrema,
                            ),
                          ),
                          Text(
                            '${_items.length} actividades',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_items.isEmpty)
                        _glassCard(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Aún no hay actividades en el itinerario.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        )
                      else
                        ..._items.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildItineraryCard(
                              item: entry.value,
                              index: entry.key,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => _openItineraryEditorRoute(),
                        borderRadius: BorderRadius.circular(7),
                        child: DottedBorder(
                          color: Colors.grey,
                          strokeWidth: 1.5,
                          dashPattern: const [6, 4],
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(7),
                          padding: EdgeInsets.zero,
                          child: _glassCard(
                            padding: const EdgeInsets.all(8),
                            child: SizedBox(
                              width: double.infinity,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_circle_outline,
                                    color: Color.fromARGB(120, 255, 254, 250),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'AGREGAR ACTIVIDAD AL ITINERARIO',
                                    style: const TextStyle(
                                      color: Color.fromARGB(120, 255, 254, 250),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 9,
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: VcomColors.blancoCrema,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            minimumSize: const Size(0, 36),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VcomColors.oroLujoso,
                            foregroundColor: VcomColors.azulMedianocheTexto,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            minimumSize: const Size(0, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _saving
                                ? 'Guardando...'
                                : _isEditing
                                ? 'Actualizar'
                                : 'Publicar',
                            style: const TextStyle(fontSize: 11),
                          ),
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
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String? value)? validator,
    int minLines = 1,
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 8,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          minLines: minLines,
          maxLines: maxLines,
          style: const TextStyle(color: VcomColors.blancoCrema, fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
            filled: false,
            isDense: true,
            contentPadding: const EdgeInsets.only(
              top: 2,
              left: 0,
              right: 0,
              bottom: 0,
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: VcomColors.oroLujoso, width: 2),
            ),
            suffixIcon: suffixIcon,
            suffixIconConstraints: suffixIcon != null
                ? const BoxConstraints(
                    minWidth: 24,
                    minHeight: 0,
                    maxHeight: 16,
                  )
                : null,
          ),
        ),
      ],
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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

  Widget _buildPickerCard({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: _glassCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 8,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: VcomColors.blancoCrema,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final hasPendingImage = _pendingImageFile != null;
    final hasRemoteImage = _imageUrl != null && _imageUrl!.trim().isNotEmpty;
    final hasImage = hasPendingImage || hasRemoteImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IMAGEN',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 8,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _uploadingImage ? null : _showImageSourcePicker,
          borderRadius: BorderRadius.circular(7),
          child: hasImage
              ? _glassCard(
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: hasPendingImage
                                ? Image.file(
                                    _pendingImageFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  )
                                : Image.network(
                                    _imageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: const Color(0xFF1A2740),
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            color: Colors.white54,
                                            size: 42,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _uploadingImage
                                    ? 'Preparando imagen...'
                                    : hasPendingImage
                                    ? 'Imagen lista para publicar'
                                    : 'Toca para cambiar la imagen',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _uploadingImage
                                  ? null
                                  : () => setState(() {
                                      _pendingImageFile = null;
                                      _imageUrl = null;
                                    }),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : DottedBorder(
                  color: Colors.grey,
                  strokeWidth: 1.5,
                  dashPattern: const [6, 4],
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(7),
                  padding: EdgeInsets.zero,
                  child: _glassCard(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_uploadingImage)
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: VcomColors.oroLujoso,
                              ),
                            )
                          else
                            const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Color.fromARGB(120, 255, 254, 250),
                              size: 15,
                            ),
                          const SizedBox(width: 12),
                          Text(
                            _uploadingImage
                                ? 'Preparando imagen...'
                                : 'AGREGAR IMAGEN',
                            style: const TextStyle(
                              color: Color.fromARGB(120, 255, 254, 250),
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildItineraryCard({
    required EventItineraryItem item,
    required int index,
  }) {
    return _glassCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: VcomColors.blancoCrema,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    _openItineraryEditorRoute(index: index, initialItem: item),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: VcomColors.oroLujoso,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _items.removeAt(index);
                  });
                },
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDisplayDate(item.date),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatDisplayTime(item.startTime)} - ${_formatDisplayTime(item.endTime)}',
            style: const TextStyle(
              color: VcomColors.oroLujoso,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      var imageUrl = _imageUrl?.trim().isEmpty == true ? null : _imageUrl;
      if (_pendingImageFile != null) {
        final upload = await _mediaUploadService.uploadFile(
          file: _pendingImageFile!,
          type: 'image',
        );
        imageUrl = upload.url;
      }

      final itineraryForRequest = _isEditing
          ? EventItinerary(
              idItinerary: widget.initialEvent?.itinerary?.idItinerary,
              items: List<EventItineraryItem>.from(_items),
              stateItinerary: true,
            )
          : _items.isEmpty
          ? null
          : EventItinerary(
              idItinerary: widget.initialEvent?.itinerary?.idItinerary,
              items: List<EventItineraryItem>.from(_items),
              stateItinerary: true,
            );

      final event = EventModel(
        idEvent: widget.initialEvent?.idEvent,
        titleEvent: _titleController.text.trim(),
        descriptionEvent: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        locationEvent: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        linkAccess: _linkController.text.trim().isEmpty
            ? null
            : _linkController.text.trim(),
        imageEvent: imageUrl?.trim().isEmpty == true ? null : imageUrl,
        startEvent: _startDate,
        endEvent: _endDate,
        startTime: _startTime,
        endTime: _endTime,
        stateEvent: _stateEvent,
        itinerary: itineraryForRequest,
      );

      if (_isEditing) {
        await _component.updateEvent(event);
      } else {
        await _component.createEvent(event);
      }

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
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // ignore: unused_element
  Future<void> _openItineraryEditor({
    int? index,
    EventItineraryItem? initialItem,
  }) async {
    final titleController = TextEditingController(
      text: initialItem?.title ?? '',
    );
    String date = initialItem?.date ?? _startDate;
    String startTime = initialItem?.startTime ?? '09:00:00';
    String endTime = initialItem?.endTime ?? '10:00:00';

    final result = await showDialog<EventItineraryItem>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final bottomInset = MediaQuery.of(dialogContext).viewInsets.bottom;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1628),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          initialItem == null
                              ? 'Nueva actividad'
                              : 'Editar actividad',
                          style: const TextStyle(
                            color: VcomColors.blancoCrema,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: titleController,
                          label: 'Título',
                          hint: 'Nombre de la actividad',
                          icon: Icons.title,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPickerCard(
                                label: 'Fecha',
                                value: _formatDisplayDate(date),
                                onTap: () async {
                                  final value = await _pickDate(date);
                                  if (value != null) {
                                    setDialogState(() => date = value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPickerCard(
                                label: 'Inicio',
                                value: _formatDisplayTime(startTime),
                                onTap: () async {
                                  final value = await _pickTime(startTime);
                                  if (value != null) {
                                    setDialogState(() => startTime = value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPickerCard(
                          label: 'Final',
                          value: _formatDisplayTime(endTime),
                          onTap: () async {
                            final value = await _pickTime(endTime);
                            if (value != null) {
                              setDialogState(() => endTime = value);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (titleController.text.trim().isEmpty) {
                                    return;
                                  }
                                  Navigator.of(dialogContext).pop(
                                    EventItineraryItem(
                                      title: titleController.text.trim(),
                                      date: date,
                                      startTime: startTime,
                                      endTime: endTime,
                                    ),
                                  );
                                },
                                child: const Text('Guardar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();

    if (result == null) return;

    setState(() {
      if (index == null) {
        _items.add(result);
      } else {
        _items[index] = result;
      }
    });
  }

  Future<void> _openItineraryEditorRoute({
    int? index,
    EventItineraryItem? initialItem,
  }) async {
    final result = await Navigator.of(context).push<EventItineraryItem>(
      MaterialPageRoute(
        builder: (_) => _ItineraryEditorPage(
          initialItem: initialItem,
          defaultDate: _startDate,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      if (index == null) {
        _items.add(result);
      } else {
        _items[index] = result;
      }
    });
  }

  Future<String?> _pickDate(String currentValue) async {
    final initialDate = DateTime.tryParse(currentValue) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (selected == null) return null;
    return _formatDate(selected);
  }

  Future<String?> _pickTime(String currentValue) async {
    final parts = currentValue.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (selected == null) return null;
    return _formatTime(selected);
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  String _formatDisplayDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  String _formatDisplayTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final date = DateTime(2026, 1, 1, hour, minute);
    return DateFormat('hh:mm a').format(date);
  }

  Future<void> _showImageSourcePicker() async {
    final fromCamera = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1628),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: VcomColors.oroLujoso,
                ),
                title: const Text(
                  'Galería',
                  style: TextStyle(color: VcomColors.blancoCrema),
                ),
                onTap: () => Navigator.of(context).pop(false),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: VcomColors.oroLujoso,
                ),
                title: const Text(
                  'Cámara',
                  style: TextStyle(color: VcomColors.blancoCrema),
                ),
                onTap: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
      },
    );

    if (fromCamera == null) return;
    await _pickLocalImage(fromCamera: fromCamera);
  }

  Future<void> _pickLocalImage({required bool fromCamera}) async {
    setState(() => _uploadingImage = true);

    try {
      final file = await _mediaUploadService.pickImage(fromCamera: fromCamera);

      if (!mounted || file == null) return;

      setState(() {
        _pendingImageFile = file;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingImage = false);
      }
    }
  }
}

class _ItineraryEditorPage extends StatefulWidget {
  final EventItineraryItem? initialItem;
  final String defaultDate;

  const _ItineraryEditorPage({
    required this.initialItem,
    required this.defaultDate,
  });

  @override
  State<_ItineraryEditorPage> createState() => _ItineraryEditorPageState();
}

class _ItineraryEditorPageState extends State<_ItineraryEditorPage> {
  late final TextEditingController _titleController;
  late String _date;
  late String _startTime;
  late String _endTime;

  bool get _isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialItem?.title ?? '',
    );
    _date = widget.initialItem?.date.isNotEmpty == true
        ? widget.initialItem!.date
        : widget.defaultDate;
    _startTime = widget.initialItem?.startTime ?? '09:00:00';
    _endTime = widget.initialItem?.endTime ?? '10:00:00';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            radius: 1.3,
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
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    Text(
                      _isEditing ? 'Editar actividad' : 'Nueva actividad',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: VcomColors.blancoCrema,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildField(
                      controller: _titleController,
                      label: 'Titulo',
                      hint: 'Nombre de la actividad',
                      icon: Icons.title,
                    ),
                    const SizedBox(height: 16),
                    _buildPickerCard(
                      label: 'Fecha',
                      value: _formatDisplayDate(_date),
                      onTap: () async {
                        final value = await _pickDate(_date);
                        if (value != null) {
                          setState(() => _date = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPickerCard(
                            label: 'Inicio',
                            value: _formatDisplayTime(_startTime),
                            onTap: () async {
                              final value = await _pickTime(_startTime);
                              if (value != null) {
                                setState(() => _startTime = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPickerCard(
                            label: 'Final',
                            value: _formatDisplayTime(_endTime),
                            onTap: () async {
                              final value = await _pickTime(_endTime);
                              if (value != null) {
                                setState(() => _endTime = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: VcomColors.blancoCrema,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VcomColors.oroLujoso,
                          foregroundColor: VcomColors.azulMedianocheTexto,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Guardar',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      EventItineraryItem(
        title: title,
        date: _date,
        startTime: _startTime,
        endTime: _endTime,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 8,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textAlignVertical: TextAlignVertical.bottom,
          style: const TextStyle(color: VcomColors.blancoCrema, fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
            filled: false,
            isDense: true,
            contentPadding: const EdgeInsets.only(
              top: 2,
              left: 0,
              right: 0,
              bottom: 0,
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: VcomColors.oroLujoso, width: 2),
            ),
          ),
        ),
      ],
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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

  Widget _buildPickerCard({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: _glassCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 8,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: VcomColors.blancoCrema,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickDate(String currentValue) async {
    final initialDate = DateTime.tryParse(currentValue) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (selected == null) return null;
    return DateFormat('yyyy-MM-dd').format(selected);
  }

  Future<String?> _pickTime(String currentValue) async {
    final parts = currentValue.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (selected == null) return null;
    final hour = selected.hour.toString().padLeft(2, '0');
    final minute = selected.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  String _formatDisplayDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  String _formatDisplayTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final date = DateTime(2026, 1, 1, hour, minute);
    return DateFormat('hh:mm a').format(date);
  }
}
