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
            holidays.add(CalendarEvent.fromJson({
              ...holiday,
              'type': 'holiday',
              'color': '#FF8FA3',
            }));
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

  /// Fetch all calendar events for a date range
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
      final res = await CalendarService.getCalendarEvents(
        token,
        userId,
        startDate,
        endDate,
      );

      if (res['success'] != false && res['data'] != null) {
        final List<CalendarEvent> events = [];
        if (res['data'] is List) {
          for (final event in res['data']) {
            events.add(CalendarEvent.fromJson(event));
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
  Future<bool> createEvent(
    String token,
    Map<String, dynamic> eventData,
  ) async {
    print('[CALENDAR NOTIFIER] createEvent: Starting - Event: ${eventData['title']}');
    _setState(_state.copyWith(isSaving: true, error: null));
    try {
      final res = await CalendarService.createEvent(token, eventData);

      if (res['success'] != false) {
        print('[CALENDAR NOTIFIER] ✅ createEvent: Success - EventId: ${res['data']?['id']}');
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

  /// Create a new holiday
  Future<bool> createHoliday(
    String token,
    String companyId,
    Map<String, dynamic> holidayData,
  ) async {
    print('[CALENDAR NOTIFIER] createHoliday: Starting - CompanyId: $companyId, Holiday: ${holidayData['name']}');
    _setState(_state.copyWith(isSaving: true, error: null));
    try {
      final res =
          await CalendarService.createHoliday(token, companyId, holidayData);

      if (res['success'] != false) {
        print('[CALENDAR NOTIFIER] ✅ createHoliday: Success - HolidayId: ${res['data']?['id']}');
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


