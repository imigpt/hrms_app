class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String? type; // 'holiday', 'leave', 'task', 'event'
  final String? color;
  final bool allDay;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.type,
    this.color,
    this.allDay = false,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      type: json['type'],
      color: json['color'],
      allDay: json['allDay'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'type': type,
      'color': color,
      'allDay': allDay,
    };
  }
}

class CalendarState {
  final bool isLoading;
  final bool isSaving;
  final List<CalendarEvent> events;
  final List<CalendarEvent> holidays;
  final String? error;
  final String? successMessage;

  const CalendarState({
    this.isLoading = false,
    this.isSaving = false,
    this.events = const [],
    this.holidays = const [],
    this.error,
    this.successMessage,
  });

  CalendarState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<CalendarEvent>? events,
    List<CalendarEvent>? holidays,
    String? error,
    String? successMessage,
  }) {
    return CalendarState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      events: events ?? this.events,
      holidays: holidays ?? this.holidays,
      error: error,
      successMessage: successMessage,
    );
  }
}
