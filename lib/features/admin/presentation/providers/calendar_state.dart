class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? type; // 'event', 'task', 'follow-up', 'meeting', 'deadline', 'document-approval', 'reminder', 'holiday', 'leave'
  final String? priority; // 'low', 'medium', 'high', 'critical'
  final String? status; // 'scheduled', 'in-progress', 'completed', 'cancelled'
  final String? color;
  final bool allDay;
  final String? eventType; // 'manual', 'meeting', 'reminder'
  final List<String>? participants; // Email addresses
  final String? meetingUrl;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.startTime,
    this.endTime,
    this.type,
    this.priority,
    this.status,
    this.color,
    this.allDay = false,
    this.eventType,
    this.participants,
    this.meetingUrl,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    // Map backend field names to model fields
    final id = json['_id'] ?? json['id'] ?? '';
    final title = json['title'] ?? '';
    final description = json['description'] ?? '';
    
    // Backend uses eventDate, model uses date
    // Parse date carefully to avoid timezone issues
    final eventDate = json['eventDate'] ?? json['date'];
    DateTime date = DateTime.now();
    
    if (eventDate != null) {
      try {
        final dateStr = eventDate.toString().trim();
        print('[CALENDAR STATE] Parsing eventDate: "$dateStr" for event: "$title"');
        // If date is in YYYY-MM-DD format (date only)
        if (dateStr.length == 10 && dateStr.contains('-')) {
          final parts = dateStr.split('-');
          date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          print('[CALENDAR STATE]   ✓ Parsed as date: ${date.toString()}');
        } else {
          // Full datetime string - parse as is
          date = DateTime.parse(dateStr);
          print('[CALENDAR STATE]   ✓ Parsed as datetime: ${date.toString()}');
        }
      } catch (e) {
        print('[CALENDAR STATE] ❌ Error parsing eventDate: $e for input: "$eventDate"');
        date = DateTime.now();
      }
    }
    
    // Backend uses endDate for multi-day events, model uses endTime
    // For allDay events, endDate contains the end date
    // For timed events, this represents the end time
    final endDate = json['endDate'];
    DateTime? endTime;
    
    if (endDate != null) {
      try {
        final dateStr = endDate.toString().trim();
        if (dateStr.length == 10 && dateStr.contains('-')) {
          final parts = dateStr.split('-');
          endTime = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else {
          endTime = DateTime.parse(dateStr);
        }
      } catch (e) {
        print('[CALENDAR STATE] Error parsing endDate: $e');
        endTime = null;
      }
    }
    
    // Determine the type based on eventType or backend response
    final backendEventType = json['eventType'] ?? 'manual';
    String? displayType;
    if (backendEventType == 'holiday') {
      displayType = 'holiday';
    } else if (backendEventType == 'meeting') {
      displayType = 'meeting';
    } else if (backendEventType == 'reminder') {
      displayType = 'reminder';
    } else {
      displayType = json['type'] ?? 'event';
    }
    
    // Map participants - could be array of objects or array of strings
    final participantsList = json['participants'] ?? [];
    final participants = (participantsList is List
        ? participantsList
            .map((p) => p is String ? p : (p['email'] ?? p['name'] ?? ''))
            .where((p) => p.isNotEmpty)
            .cast<String>()
            .toList()
        : <String>[]) as List<String>?;
    
    return CalendarEvent(
      id: id,
      title: title,
      description: description,
      date: date,
      startTime: null, // Backend doesn't provide separate startTime
      endTime: endTime,
      type: displayType,
      priority: json['priority'],
      status: json['status'],
      color: json['color'] ?? _getDefaultColorForType(backendEventType),
      allDay: json['allDay'] ?? true, // Default to all-day
      eventType: backendEventType,
      participants: participants,
      meetingUrl: json['meetingUrl'] ?? json['meeting_url'],
    );
  }

  /// Get default color for event type
  static String _getDefaultColorForType(String? eventType) {
    switch (eventType?.toLowerCase()) {
      case 'holiday':
        return '#FF8FA3'; // Red-pink for holidays
      case 'meeting':
        return '#9575CD'; // Purple for meetings
      case 'reminder':
        return '#FFCA28'; // Amber for reminders
      case 'manual':
      default:
        return '#64B5F6'; // Blue for manual events
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'type': type,
      'priority': priority,
      'status': status,
      'color': color,
      'allDay': allDay,
      'eventType': eventType,
      'participants': participants,
      'meetingUrl': meetingUrl,
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
