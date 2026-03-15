class EventModel {
  final int? idEvent;
  final String titleEvent;
  final String? descriptionEvent;
  final String? locationEvent;
  final String? linkAccess;
  final String? imageEvent;
  final String startEvent;
  final String endEvent;
  final String startTime;
  final String endTime;
  final bool stateEvent;
  final EventItinerary? itinerary;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EventModel({
    this.idEvent,
    required this.titleEvent,
    this.descriptionEvent,
    this.locationEvent,
    this.linkAccess,
    this.imageEvent,
    required this.startEvent,
    required this.endEvent,
    required this.startTime,
    required this.endTime,
    this.stateEvent = true,
    this.itinerary,
    this.createdAt,
    this.updatedAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      idEvent: _parseInt(json['id_event']),
      titleEvent: json['title_event'] as String? ?? '',
      descriptionEvent: json['description_event'] as String?,
      locationEvent: json['location_event'] as String?,
      linkAccess: json['link_access'] as String?,
      imageEvent: json['image_event'] as String?,
      startEvent: json['start_event'] as String? ?? '',
      endEvent: json['end_event'] as String? ?? '',
      startTime: _normalizeTime(json['start_time'] as String? ?? ''),
      endTime: _normalizeTime(json['end_time'] as String? ?? ''),
      stateEvent: json['state_event'] as bool? ?? false,
      itinerary: json['itinerary'] is Map<String, dynamic>
          ? EventItinerary.fromJson(json['itinerary'] as Map<String, dynamic>)
          : null,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title_event': titleEvent,
      'description_event': descriptionEvent,
      'location_event': locationEvent,
      'link_access': linkAccess,
      'image_event': imageEvent,
      'start_event': startEvent,
      'end_event': endEvent,
      'start_time': _serializeTime(startTime),
      'end_time': _serializeTime(endTime),
      'state_event': stateEvent,
      if (itinerary != null) 'itinerary': itinerary!.toJson(),
    };
  }

  EventModel copyWith({
    int? idEvent,
    String? titleEvent,
    String? descriptionEvent,
    String? locationEvent,
    String? linkAccess,
    String? imageEvent,
    String? startEvent,
    String? endEvent,
    String? startTime,
    String? endTime,
    bool? stateEvent,
    EventItinerary? itinerary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      idEvent: idEvent ?? this.idEvent,
      titleEvent: titleEvent ?? this.titleEvent,
      descriptionEvent: descriptionEvent ?? this.descriptionEvent,
      locationEvent: locationEvent ?? this.locationEvent,
      linkAccess: linkAccess ?? this.linkAccess,
      imageEvent: imageEvent ?? this.imageEvent,
      startEvent: startEvent ?? this.startEvent,
      endEvent: endEvent ?? this.endEvent,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      stateEvent: stateEvent ?? this.stateEvent,
      itinerary: itinerary ?? this.itinerary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static String _normalizeTime(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return '';
    if (normalized.length == 5) return '$normalized:00';
    return normalized;
  }

  static String _serializeTime(String value) {
    final normalized = _normalizeTime(value);
    if (normalized.length >= 5) return normalized.substring(0, 5);
    return normalized;
  }
}

class EventItinerary {
  final int? idItinerary;
  final List<EventItineraryItem> items;
  final bool stateItinerary;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EventItinerary({
    this.idItinerary,
    this.items = const [],
    this.stateItinerary = true,
    this.createdAt,
    this.updatedAt,
  });

  factory EventItinerary.fromJson(Map<String, dynamic> json) {
    return EventItinerary(
      idItinerary: EventModel._parseInt(json['id_itinerary']),
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) => EventItineraryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      stateItinerary: json['state_itinerary'] as bool? ?? true,
      createdAt: EventModel._parseDateTime(json['created_at']),
      updatedAt: EventModel._parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idItinerary != null) 'id_itinerary': idItinerary,
      'items': items.map((item) => item.toJson()).toList(),
      'state_itinerary': stateItinerary,
    };
  }

  EventItinerary copyWith({
    int? idItinerary,
    List<EventItineraryItem>? items,
    bool? stateItinerary,
  }) {
    return EventItinerary(
      idItinerary: idItinerary ?? this.idItinerary,
      items: items ?? this.items,
      stateItinerary: stateItinerary ?? this.stateItinerary,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class EventItineraryItem {
  final String title;
  final String date;
  final String startTime;
  final String endTime;

  const EventItineraryItem({
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  factory EventItineraryItem.fromJson(Map<String, dynamic> json) {
    return EventItineraryItem(
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      startTime: EventModel._normalizeTime(json['start_time'] as String? ?? ''),
      endTime: EventModel._normalizeTime(json['end_time'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (date.trim().isNotEmpty) 'date': date,
      'start_time': EventModel._serializeTime(startTime),
      'end_time': EventModel._serializeTime(endTime),
    };
  }

  EventItineraryItem copyWith({
    String? title,
    String? date,
    String? startTime,
    String? endTime,
  }) {
    return EventItineraryItem(
      title: title ?? this.title,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
