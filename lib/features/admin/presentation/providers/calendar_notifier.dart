import 'package:flutter/foundation.dart';
import 'package:hrms_app/features/admin/presentation/providers/calendar_state.dart';
import 'package:hrms_app/shared/services/core/calendar_service.dart';

class CalendarNotifier extends ChangeNotifier {
  CalendarState _state = const CalendarState();

  CalendarState get state => _state;

  void _setState(CalendarState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Fetch holidays for a company in the given month
  /// Holidays are calendar events with eventType='holiday'
  Future<void> fetchHolidays(
    String token,
    String companyId,
    int year,
    int month,
  ) async {
    print('[CALENDAR NOTIFIER] fetchHolidays: Starting - CompanyId: $companyId, Month: $month/$year');
    _setState(_state.copyWith(isLoading: true, error: null));
    try {
      final res = await CalendarService.getCompanyHolidays(
        token,
        companyId,
        year,
        month,
      );

      if (res['success'] != false && res['data'] != null) {
        final List<CalendarEvent> holidays = [];
        if (res['data'] is List) {
          for (final holiday in res['data']) {
            // Backend returns eventType='holiday', parse it with fromJson
            final parsedHoliday = CalendarEvent.fromJson(holiday);
            print('[CALENDAR NOTIFIER] ✓ Holiday: ${parsedHoliday.title} on ${parsedHoliday.date}');
            holidays.add(parsedHoliday);
          }
        }
        print('[CALENDAR NOTIFIER] ✅ fetchHolidays: Success - ${holidays.length} holidays loaded');
        _setState(_state.copyWith(holidays: holidays));
      } else {
        print('[CALENDAR NOTIFIER] ❌ fetchHolidays: Failed - ${res['message']}');
        _setState(_state.copyWith(
            error: res['message'] ?? 'Failed to fetch holidays'));
      }
    } catch (e) {
      print('[CALENDAR NOTIFIER] ❌ fetchHolidays: Exception - $e');
      _setState(_state.copyWith(error: 'Error: $e'));
    } finally {
      _setState(_state.copyWith(isLoading: false));
    }
  }

  /// Fetch all calendar events for a date range (excludes holidays)
  Future<void> fetchEvents(
    String token,
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    print('[CALENDAR NOTIFIER] fetchEvents: Starting - UserId: $userId');
    print('[CALENDAR NOTIFIER] fetchEvents: Date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
    _setState(_state.copyWith(isLoading: true, error: null));
    try {
      // Use aggregated feed so tasks and follow-ups appear with events.
      final res = await CalendarService.getAggregatedCalendar(
        token,
        startDate,
        endDate,
      );

      if (res['success'] != false && res['data'] != null) {
        final List<CalendarEvent> events = [];
        if (res['data'] is List) {
          for (final event in res['data']) {
            final calendarEvent = CalendarEvent.fromJson(event);
            print('[CALENDAR NOTIFIER] ✓ Event: ${calendarEvent.title} on ${calendarEvent.date}');
            // Filter out holidays from events list (they'll be in holidays list)
            if (calendarEvent.eventType != 'holiday') {
              events.add(calendarEvent);
            }
          }
        }
        print('[CALENDAR NOTIFIER] ✅ fetchEvents: Success - ${events.length} events loaded');
        _setState(_state.copyWith(events: events));
      } else {
        print('[CALENDAR NOTIFIER] ❌ fetchEvents: Failed - ${res['message']}');
        _setState(_state.copyWith(
            error: res['message'] ?? 'Failed to fetch events'));
      }
    } catch (e) {
      print('[CALENDAR NOTIFIER] ❌ fetchEvents: Exception - $e');
      _setState(_state.copyWith(error: 'Error: $e'));
    } finally {
      _setState(_state.copyWith(isLoading: false));
    }
  }

  /// Create a new event
  /// Event data should include: title, eventDate, eventType, and optionally description, endDate, allDay, priority, status
  Future<bool> createEvent(
    String token,
    Map<String, dynamic> eventData,
  ) async {
    print('[CALENDAR NOTIFIER] createEvent: Starting - Event: ${eventData['title']}');
    _setState(_state.copyWith(isSaving: true, error: null));
    try {
      // Preserve full DateTime values for event/meeting precision.
      final rawEventDate = eventData['eventDate'] ?? eventData['date'];
      final rawEndDate = eventData['endDate'] ?? eventData['date'];
      
      String? formattedEventDate;
      String? formattedEndDate;
      
      if (rawEventDate is DateTime) {
        formattedEventDate = rawEventDate.toIso8601String();
      } else {
        formattedEventDate = rawEventDate?.toString();
      }
      
      if (rawEndDate is DateTime) {
        formattedEndDate = rawEndDate.toIso8601String();
      } else {
        formattedEndDate = rawEndDate?.toString();
      }
      
      // Ensure eventDate is properly formatted
      final payload = {
        'title': eventData['title'] ?? '',
        'eventDate': formattedEventDate,
        'eventType': eventData['eventType'] ?? 'manual',
        'description': eventData['description'] ?? '',
        'endDate': formattedEndDate,
        'allDay': eventData['allDay'] ?? true,
        'priority': eventData['priority'] ?? 'medium',
        'status': eventData['status'] ?? 'scheduled',
        ...eventData, // Include any other fields passed in
      };
      
      print('[CALENDAR NOTIFIER] createEvent: Formatted payload - eventDate: $formattedEventDate, endDate: $formattedEndDate');

      final res = await CalendarService.createEvent(token, payload);

      if (res['success'] != false) {
        print('[CALENDAR NOTIFIER] ✅ createEvent: Success - EventId: ${res['data']?['_id'] ?? res['data']?['id']}');
        _setState(_state.copyWith(
          successMessage: 'Event created successfully',
          isSaving: false,
        ));
        return true;
      } else {
        print('[CALENDAR NOTIFIER] ❌ createEvent: Failed - ${res['message']}');
        _setState(_state.copyWith(
          error: res['message'] ?? 'Failed to create event',
          isSaving: false,
        ));
        return false;
      }
    } catch (e) {
      print('[CALENDAR NOTIFIER] ❌ createEvent: Exception - $e');
      _setState(_state.copyWith(error: 'Error: $e', isSaving: false));
      return false;
    }
  }

  /// Create a new holiday as a calendar event
  /// Holiday data should include: title, eventDate, and optionally description, allDay
  Future<bool> createHoliday(
    String token,
    String companyId,
    Map<String, dynamic> holidayData,
  ) async {
    print('[CALENDAR NOTIFIER] createHoliday: Starting - CompanyId: $companyId, Holiday: ${holidayData['title']}');
    _setState(_state.copyWith(isSaving: true, error: null));
    try {
      // Format date as YYYY-MM-DD (without time) to avoid timezone issues
      final rawEventDate = holidayData['eventDate'] ?? holidayData['date'];
      String? formattedEventDate;
      
      if (rawEventDate is DateTime) {
        formattedEventDate = '${rawEventDate.year.toString().padLeft(4, '0')}-${rawEventDate.month.toString().padLeft(2, '0')}-${rawEventDate.day.toString().padLeft(2, '0')}';
      } else {
        formattedEventDate = rawEventDate?.toString();
      }
      
      // Ensure the holiday has the required backend fields
      final payload = {
        'title': holidayData['title'] ?? holidayData['name'] ?? '',
        'eventDate': formattedEventDate,
        'description': holidayData['description'] ?? '',
        'allDay': holidayData['allDay'] ?? true,
        // eventType='holiday' will be added by the service
      };
      
      print('[CALENDAR NOTIFIER] createHoliday: Formatted payload - eventDate: $formattedEventDate');

      final res = await CalendarService.createHoliday(token, companyId, payload);

      if (res['success'] != false) {
        print('[CALENDAR NOTIFIER] ✅ createHoliday: Success - HolidayId: ${res['data']?['_id'] ?? res['data']?['id']}');
        _setState(_state.copyWith(
          successMessage: 'Holiday created successfully',
          isSaving: false,
        ));
        return true;
      } else {
        print('[CALENDAR NOTIFIER] ❌ createHoliday: Failed - ${res['message']}');
        _setState(_state.copyWith(
          error: res['message'] ?? 'Failed to create holiday',
          isSaving: false,
        ));
        return false;
      }
    } catch (e) {
      print('[CALENDAR NOTIFIER] ❌ createHoliday: Exception - $e');
      _setState(_state.copyWith(error: 'Error: $e', isSaving: false));
      return false;
    }
  }

  /// Delete an event
  Future<bool> deleteEvent(String token, String eventId) async {
    print('[CALENDAR NOTIFIER] deleteEvent: Starting - EventId: $eventId');
    _setState(_state.copyWith(isSaving: true, error: null));
    try {
      final res = await CalendarService.deleteEvent(token, eventId);

      if (res['success'] != false) {
        print('[CALENDAR NOTIFIER] ✅ deleteEvent: Success - EventId: $eventId');
        _setState(_state.copyWith(
          events: _state.events.where((e) => e.id != eventId).toList(),
          successMessage: 'Event deleted successfully',
          isSaving: false,
        ));
        return true;
      } else {
        print('[CALENDAR NOTIFIER] ❌ deleteEvent: Failed - ${res['message']}');
        _setState(_state.copyWith(
          error: res['message'] ?? 'Failed to delete event',
          isSaving: false,
        ));
        return false;
      }
    } catch (e) {
      print('[CALENDAR NOTIFIER] ❌ deleteEvent: Exception - $e');
      _setState(_state.copyWith(error: 'Error: $e', isSaving: false));
      return false;
    }
  }

  /// Delete a holiday
  Future<bool> deleteHoliday(
    String token,
    String companyId,
    String holidayId,
  ) async {
    print('[CALENDAR NOTIFIER] deleteHoliday: Starting - CompanyId: $companyId, HolidayId: $holidayId');
    _setState(_state.copyWith(isSaving: true, error: null));
    try {
      final res =
          await CalendarService.deleteHoliday(token, companyId, holidayId);

      if (res['success'] != false) {
        print('[CALENDAR NOTIFIER] ✅ deleteHoliday: Success - HolidayId: $holidayId');
        _setState(_state.copyWith(
          holidays: _state.holidays.where((h) => h.id != holidayId).toList(),
          successMessage: 'Holiday deleted successfully',
          isSaving: false,
        ));
        return true;
      } else {
        print('[CALENDAR NOTIFIER] ❌ deleteHoliday: Failed - ${res['message']}');
        _setState(_state.copyWith(
          error: res['message'] ?? 'Failed to delete holiday',
          isSaving: false,
        ));
        return false;
      }
    } catch (e) {
      print('[CALENDAR NOTIFIER] ❌ deleteHoliday: Exception - $e');
      _setState(_state.copyWith(error: 'Error: $e', isSaving: false));
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _setState(_state.copyWith(error: null));
  }

  /// Clear success message
  void clearSuccess() {
    _setState(_state.copyWith(successMessage: null));
  }
}


