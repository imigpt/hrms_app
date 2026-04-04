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
    String normalizeType(String? raw) {
      final value = (raw ?? '').toLowerCase().trim();
      if (value.isEmpty) return '';
      if (value == 'followup' || value == 'follow_up') return 'follow-up';
      if (value == 'document_approval' || value == 'document approval') {
        return 'document-approval';
      }
      return value;
    }

    // Map backend field names to model fields
    final id = json['_id'] ?? json['id'] ?? '';
    final title = json['title'] ?? '';
    final description = json['description'] ?? '';
    
    // Backend can return eventDate/date (calendar API) or start/end (aggregated API)
    // Parse date carefully to avoid timezone issues
    final eventDate = json['eventDate'] ?? json['date'] ?? json['start'];
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
          date = DateTime.parse(dateStr).toLocal();
          print('[CALENDAR STATE]   ✓ Parsed as datetime: ${date.toString()}');
        }
      } catch (e) {
        print('[CALENDAR STATE] ❌ Error parsing eventDate: $e for input: "$eventDate"');
        date = DateTime.now();
      }
    }
    
    // Backend may return endDate (calendar API) or end (aggregated API)
    // For allDay events, endDate contains the end date
    // For timed events, this represents the end time
    final endDate = json['endDate'] ?? json['end'];
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
          endTime = DateTime.parse(dateStr).toLocal();
        }
      } catch (e) {
        print('[CALENDAR STATE] Error parsing endDate: $e');
        endTime = null;
      }
    }
    
    // Determine display type from backend eventType first, then fallback to type.
    final backendEventType = normalizeType(json['eventType']?.toString());
    final rawType = normalizeType(json['type']?.toString());
    const supportedTypes = {
      'event',
      'task',
      'follow-up',
      'meeting',
      'deadline',
      'document-approval',
      'reminder',
      'holiday',
      'leave',
    };

    String? displayType;
    if (supportedTypes.contains(backendEventType)) {
      displayType = backendEventType;
    } else if (supportedTypes.contains(rawType)) {
      displayType = rawType;
    } else {
      displayType = 'event';
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
      startTime: eventDate != null ? date : null,
      endTime: endTime,
      type: displayType,
      priority: json['priority'],
      status: json['status'],
      color: json['color'] ?? _getDefaultColorForType(displayType),
      allDay: json['allDay'] ?? true, // Default to all-day
      eventType: backendEventType.isNotEmpty ? backendEventType : null,
      participants: participants,
      meetingUrl: json['meetingUrl'] ?? json['meeting_url'],
    );
  }

  /// Get default color for event type
  static String _getDefaultColorForType(String? eventType) {
    switch (eventType?.toLowerCase()) {
      case 'holiday':
        return '#FF8FA3'; // Red-pink for holidays
      case 'leave':
        return '#FFB74D';
      case 'meeting':
        return '#9575CD'; // Purple for meetings
      case 'task':
        return '#64B5F6';
      case 'follow-up':
        return '#FFB74D';
      case 'deadline':
        return '#E57373';
      case 'document-approval':
        return '#4DB6AC';
      case 'reminder':
        return '#FFCA28'; // Amber for reminders
      case 'event':
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
