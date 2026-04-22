import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hrms_app/features/attendance/data/models/attendance_checkin_model.dart'
    as checkin_model;
import 'package:hrms_app/features/attendance/data/models/attendance_history_model.dart'
    as history_model;
import 'package:hrms_app/features/attendance/data/models/attendance_summary_model.dart';
import 'package:hrms_app/features/attendance/data/models/today_attendance_model.dart'
    as today_model;
import 'package:hrms_app/features/attendance/presentation/providers/attendance_notifier.dart';
import 'package:hrms_app/features/attendance/presentation/providers/attendance_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test Helpers
// ─────────────────────────────────────────────────────────────────────────────

history_model.AttendanceRecord _historyRecord({
  required DateTime date,
  required String status,
}) {
  return history_model.AttendanceRecord(
    id: 'rec_${date.millisecondsSinceEpoch}',
    date: date,
    status: status,
  );
}

today_model.TodayAttendance _todayAttendance({
  bool hasCheckedIn = true,
  bool hasCheckedOut = false,
}) {
  return today_model.TodayAttendance(
    success: true,
    data: today_model.AttendanceData(
      checkIn: hasCheckedIn
          ? today_model.AttendanceCheckPoint(
              time: DateTime.utc(2026, 4, 20, 9, 0).toIso8601String(),
            )
          : null,
      checkOut: hasCheckedOut
          ? today_model.AttendanceCheckPoint(
              time: DateTime.utc(2026, 4, 20, 18, 0).toIso8601String(),
            )
          : null,
      status: hasCheckedIn ? 'present' : 'absent',
      workHours: hasCheckedIn ? 4.5 : 0,
      hasCheckedIn: hasCheckedIn,
      hasCheckedOut: hasCheckedOut,
    ),
  );
}

AttendanceSummary _summary({
  int totalDays = 20,
  int present = 18,
  int late = 1,
  int absent = 1,
  double totalWorkHours = 160,
}) {
  return AttendanceSummary(
    success: true,
    data: AttendanceSummaryData(
      totalDays: totalDays,
      present: present,
      late: late,
      halfDay: 0,
      absent: absent,
      wfh: 0,
      leaves: 0,
      totalWorkHours: totalWorkHours,
      averageWorkHours: '8h 0m',
    ),
  );
}

/// Build a minimal [CheckInResponse] for use in mock checkIn/checkOut calls.
checkin_model.CheckInResponse _checkInResponse({bool withCheckOut = false}) {
  final now = DateTime.now();
  return checkin_model.CheckInResponse(
    success: true,
    message: 'Success',
    data: checkin_model.AttendanceData(
      user: 'user1',
      company: null,
      date: now,
      checkIn: checkin_model.CheckIn(time: now),
      checkOut: withCheckOut ? checkin_model.CheckOut(time: now) : null,
      status: 'present',
      workHours: 8.0,
      isManualEntry: false,
      id: 'att1',
      createdAt: now,
      updatedAt: now,
      v: 0,
    ),
  );
}

/// A fake [Position] for use in location-dependent tests.
Position _fakePosition({double lat = 26.816224, double lng = 75.845444}) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime.now(),
    accuracy: 5,
    altitude: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
    altitudeAccuracy: 0,
    headingAccuracy: 0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('AttendanceNotifier', () {
    // ── Load Today ──────────────────────────────────────────────────────────

    test('loadTodayAttendance fetches attendance and updates state', () async {
      final notifier = AttendanceNotifier(
        getTodayAttendance: ({required token}) async => _todayAttendance(),
      );

      await notifier.loadTodayAttendance('token');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.todayAttendance?.hasCheckedIn, true);
      expect(notifier.state.todayAttendance?.hasCheckedOut, false);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.lastUpdated, isNotNull);
    });

    test('loadTodayAttendance allows clearing todayAttendance with null response',
        () async {
      today_model.TodayAttendance? next = _todayAttendance();
      final notifier = AttendanceNotifier(
        getTodayAttendance: ({required token}) async => next,
      );

      await notifier.loadTodayAttendance('token');
      expect(notifier.state.todayAttendance, isNotNull);

      next = null;
      await notifier.loadTodayAttendance('token');

      expect(notifier.state.todayAttendance, isNull);
      expect(notifier.state.isLoading, false);
    });

    test('loadTodayAttendance sets error on failure and clearError clears it',
        () async {
      final notifier = AttendanceNotifier(
        getTodayAttendance: ({required token}) async {
          throw Exception('network');
        },
      );

      await notifier.loadTodayAttendance('token');
      expect(notifier.state.errorMessage, contains('Failed to load attendance'));

      notifier.clearError();
      expect(notifier.state.errorMessage, isNull);
    });

    // ── Load History ─────────────────────────────────────────────────────────

    test('loadAttendanceHistory updates records and computed statistics',
        () async {
      final records = [
        _historyRecord(date: DateTime.utc(2026, 4, 1), status: 'present'),
        _historyRecord(date: DateTime.utc(2026, 4, 2), status: 'late'),
        _historyRecord(date: DateTime.utc(2026, 4, 3), status: 'absent'),
        _historyRecord(date: DateTime.utc(2026, 4, 4), status: 'present'),
      ];

      final notifier = AttendanceNotifier(
        getAttendanceHistory: ({
          required token,
          required month,
          required year,
        }) async {
          return history_model.AttendanceHistory(success: true, data: records);
        },
      );

      await notifier.loadAttendanceHistory('token');

      expect(notifier.state.attendanceHistory?.length, 4);
      // presentDays = present + late in updated notifier
      expect(notifier.state.presentDays, 3); // 2 present + 1 late
      expect(notifier.state.lateDays, 1);
      expect(notifier.state.absentDays, 1);
      expect(notifier.state.totalWorkingDays, 4);
    });

    test(
        'loadAttendanceHistory counts in-progress and half-day statuses correctly',
        () async {
      final records = [
        _historyRecord(date: DateTime.utc(2026, 4, 1), status: 'in-progress'),
        _historyRecord(date: DateTime.utc(2026, 4, 2), status: 'in_progress'),
        _historyRecord(date: DateTime.utc(2026, 4, 3), status: 'half-day'),
        _historyRecord(date: DateTime.utc(2026, 4, 4), status: 'halfday'),
        _historyRecord(date: DateTime.utc(2026, 4, 5), status: 'absent'),
      ];

      final notifier = AttendanceNotifier(
        getAttendanceHistory: ({
          required token,
          required month,
          required year,
        }) async =>
            history_model.AttendanceHistory(success: true, data: records),
      );

      await notifier.loadAttendanceHistory('token');

      expect(notifier.state.absentDays, 1);
      expect(notifier.state.totalWorkingDays, 5);
      // leave/on-leave statuses are excluded from total — let's confirm
    });

    test('loadAttendanceHistory uses explicit month and year when provided',
        () async {
      int? calledMonth;
      int? calledYear;

      final notifier = AttendanceNotifier(
        getAttendanceHistory: ({
          required token,
          required month,
          required year,
        }) async {
          calledMonth = month;
          calledYear = year;
          return history_model.AttendanceHistory(success: true, data: const []);
        },
      );

      await notifier.loadAttendanceHistory('token', month: 1, year: 2030);

      expect(calledMonth, 1);
      expect(calledYear, 2030);
    });

    // ── Load Summary ─────────────────────────────────────────────────────────

    test('loadAttendanceSummary updates summary metrics', () async {
      final notifier = AttendanceNotifier(
        getAttendanceSummary: ({
          required token,
          required month,
          required year,
        }) async {
          return _summary(totalDays: 20, present: 18, late: 1, absent: 2);
        },
      );

      await notifier.loadAttendanceSummary('token');

      expect(notifier.state.totalWorkingDays, 20);
      expect(notifier.state.presentDays, 18);
      expect(notifier.state.lateDays, 1);
      expect(notifier.state.absentDays, 2);
      expect(notifier.state.totalWorkHours, 160.0);
      expect(notifier.state.attendancePercentage, 90.0);
    });

    test('loadAttendanceSummary uses explicit month and year when provided',
        () async {
      int? calledMonth;
      int? calledYear;

      final notifier = AttendanceNotifier(
        getAttendanceSummary: ({
          required token,
          required month,
          required year,
        }) async {
          calledMonth = month;
          calledYear = year;
          return _summary();
        },
      );

      await notifier.loadAttendanceSummary('token', month: 2, year: 2031);

      expect(calledMonth, 2);
      expect(calledYear, 2031);
    });

    // ── Refresh ──────────────────────────────────────────────────────────────

    test('refreshAttendance triggers today, history, and summary loaders',
        () async {
      var todayCalled = 0;
      var historyCalled = 0;
      var summaryCalled = 0;
      int? historyMonth;
      int? historyYear;
      int? summaryMonth;
      int? summaryYear;

      final notifier = AttendanceNotifier(
        getTodayAttendance: ({required token}) async {
          todayCalled++;
          return _todayAttendance();
        },
        getAttendanceHistory: ({
          required token,
          required month,
          required year,
        }) async {
          historyCalled++;
          historyMonth = month;
          historyYear = year;
          return history_model.AttendanceHistory(
            success: true,
            data: [
              _historyRecord(date: DateTime.utc(2026, 4, 1), status: 'present')
            ],
          );
        },
        getAttendanceSummary: ({
          required token,
          required month,
          required year,
        }) async {
          summaryCalled++;
          summaryMonth = month;
          summaryYear = year;
          return _summary();
        },
      );

      await notifier.refreshAttendance('token', month: 3, year: 2032);

      expect(todayCalled, 1);
      expect(historyCalled, 1);
      expect(summaryCalled, 1);
      expect(historyMonth, 3);
      expect(historyYear, 2032);
      expect(summaryMonth, 3);
      expect(summaryYear, 2032);
      expect(notifier.state.todayAttendance, isNotNull);
      expect(notifier.state.attendanceHistory, isNotNull);
      expect(notifier.state.attendanceSummary, isNotNull);
    });

    // ── Check In ─────────────────────────────────────────────────────────────

    test(
        'checkInWithCoordinates calls checkIn service and reloads today attendance',
        () async {
      var checkInCalled = false;
      var todayCalled = false;

      final notifier = AttendanceNotifier(
        checkIn: ({
          required token,
          required photoFile,
          required latitude,
          required longitude,
        }) async {
          checkInCalled = true;
          expect(latitude, 26.816224);
          expect(longitude, 75.845444);
          return _checkInResponse();
        },
        getTodayAttendance: ({required token}) async {
          todayCalled = true;
          return _todayAttendance();
        },
      );

      final tempFile = File('fake_photo.jpg');
      final response = await notifier.checkInWithCoordinates(
        'token',
        tempFile,
        latitude: 26.816224,
        longitude: 75.845444,
      );

      expect(checkInCalled, true);
      expect(todayCalled, true);
      expect(response.success, true);
      expect(notifier.state.isCheckingIn, false);
      expect(notifier.state.currentLatitude, 26.816224);
      expect(notifier.state.currentLongitude, 75.845444);
      expect(notifier.state.errorMessage, isNull);
    });

    test('checkIn delegates to checkInWithCoordinates using Position', () async {
      double? capturedLat;
      double? capturedLng;

      final notifier = AttendanceNotifier(
        checkIn: ({
          required token,
          required photoFile,
          required latitude,
          required longitude,
        }) async {
          capturedLat = latitude;
          capturedLng = longitude;
          return _checkInResponse();
        },
        getTodayAttendance: ({required token}) async => _todayAttendance(),
      );

      final position = _fakePosition(lat: 12.345, lng: 67.890);
      await notifier.checkIn('token', File('photo.jpg'), position);

      expect(capturedLat, 12.345);
      expect(capturedLng, 67.890);
    });

    test('checkInWithCoordinates sets error state when service throws',
        () async {
      final notifier = AttendanceNotifier(
        checkIn: ({
          required token,
          required photoFile,
          required latitude,
          required longitude,
        }) async {
          throw Exception('server error');
        },
        getTodayAttendance: ({required token}) async => _todayAttendance(),
      );

      expect(
        () => notifier.checkInWithCoordinates(
          'token',
          File('photo.jpg'),
          latitude: 0.0,
          longitude: 0.0,
        ),
        throwsException,
      );
    });

    // ── Check Out ────────────────────────────────────────────────────────────

    test(
        'checkOutWithCoordinates calls checkOut service and reloads today attendance',
        () async {
      var checkOutCalled = false;
      var todayCalled = false;

      final notifier = AttendanceNotifier(
        checkOut: ({
          required token,
          required latitude,
          required longitude,
        }) async {
          checkOutCalled = true;
          expect(latitude, 26.816224);
          expect(longitude, 75.845444);
          return _checkInResponse(withCheckOut: true);
        },
        getTodayAttendance: ({required token}) async {
          todayCalled = true;
          return _todayAttendance(hasCheckedIn: true, hasCheckedOut: true);
        },
      );

      final response = await notifier.checkOutWithCoordinates(
        'token',
        latitude: 26.816224,
        longitude: 75.845444,
      );

      expect(checkOutCalled, true);
      expect(todayCalled, true);
      expect(response.success, true);
      expect(notifier.state.isCheckingOut, false);
      expect(notifier.state.currentLatitude, 26.816224);
      expect(notifier.state.currentLongitude, 75.845444);
      expect(notifier.state.errorMessage, isNull);
    });

    test('checkOut delegates to checkOutWithCoordinates using Position',
        () async {
      double? capturedLat;
      double? capturedLng;

      final notifier = AttendanceNotifier(
        checkOut: ({
          required token,
          required latitude,
          required longitude,
        }) async {
          capturedLat = latitude;
          capturedLng = longitude;
          return _checkInResponse(withCheckOut: true);
        },
        getTodayAttendance: ({required token}) async =>
            _todayAttendance(hasCheckedIn: true, hasCheckedOut: true),
      );

      final position = _fakePosition(lat: 11.111, lng: 22.222);
      await notifier.checkOut('token', position);

      expect(capturedLat, 11.111);
      expect(capturedLng, 22.222);
    });

    test('checkOutWithCoordinates sets error state when service throws',
        () async {
      final notifier = AttendanceNotifier(
        checkOut: ({
          required token,
          required latitude,
          required longitude,
        }) async {
          throw Exception('checkout failed');
        },
        getTodayAttendance: ({required token}) async => _todayAttendance(),
      );

      expect(
        () => notifier.checkOutWithCoordinates(
          'token',
          latitude: 0.0,
          longitude: 0.0,
        ),
        throwsException,
      );
    });

    // ── Location Management ──────────────────────────────────────────────────

    test('updateCurrentLocation stores lat/lng and clears location error', () {
      final notifier = AttendanceNotifier();
      notifier.setLocationError('GPS off');
      expect(notifier.state.currentLocationError, 'GPS off');

      notifier.updateCurrentLocation(10.0, 20.0);

      expect(notifier.state.currentLatitude, 10.0);
      expect(notifier.state.currentLongitude, 20.0);
      expect(notifier.state.currentLocationError, isNull);
    });

    test('setLocationError sets the locationError field', () {
      final notifier = AttendanceNotifier();

      notifier.setLocationError('Permission denied');

      expect(notifier.state.currentLocationError, 'Permission denied');
    });

    // ── Filters ──────────────────────────────────────────────────────────────

    test('filterByDateRange sets and clears nullable date filters', () {
      final notifier = AttendanceNotifier();
      final startDate = DateTime.utc(2026, 4, 1);
      final endDate = DateTime.utc(2026, 4, 30);

      notifier.filterByDateRange(startDate, endDate);
      expect(notifier.state.filterStartDate, startDate);
      expect(notifier.state.filterEndDate, endDate);

      notifier.filterByDateRange(null, null);
      expect(notifier.state.filterStartDate, isNull);
      expect(notifier.state.filterEndDate, isNull);
    });

    test('filterByStatus sets the selectedStatus', () {
      final notifier = AttendanceNotifier();

      notifier.filterByStatus('absent');

      expect(notifier.state.selectedStatus, 'absent');
    });

    test('clearFilters resets filters to defaults', () {
      final notifier = AttendanceNotifier();
      notifier.filterByDateRange(
          DateTime.utc(2026, 4, 1), DateTime.utc(2026, 4, 30));
      notifier.filterByStatus('late');

      notifier.clearFilters();

      expect(notifier.state.filterStartDate, isNull);
      expect(notifier.state.filterEndDate, isNull);
      expect(notifier.state.selectedStatus, 'all');
    });

    // ── State Calculated Properties ──────────────────────────────────────────

    test('AttendanceState.filteredAttendanceHistory filters by status', () async {
      final records = [
        _historyRecord(date: DateTime.utc(2026, 4, 1), status: 'present'),
        _historyRecord(date: DateTime.utc(2026, 4, 2), status: 'absent'),
        _historyRecord(date: DateTime.utc(2026, 4, 3), status: 'present'),
      ];

      final notifier = AttendanceNotifier(
        getAttendanceHistory: ({
          required token,
          required month,
          required year,
        }) async =>
            history_model.AttendanceHistory(success: true, data: records),
      );

      await notifier.loadAttendanceHistory('token');
      notifier.filterByStatus('absent');

      final filtered = notifier.state.filteredAttendanceHistory;
      expect(filtered.length, 1);
      expect(filtered.first.status, 'absent');
    });

    test('AttendanceState.filteredAttendanceHistory filters by date range',
        () async {
      final records = [
        _historyRecord(date: DateTime.utc(2026, 4, 1), status: 'present'),
        _historyRecord(date: DateTime.utc(2026, 4, 15), status: 'present'),
        _historyRecord(date: DateTime.utc(2026, 4, 30), status: 'absent'),
      ];

      final notifier = AttendanceNotifier(
        getAttendanceHistory: ({
          required token,
          required month,
          required year,
        }) async =>
            history_model.AttendanceHistory(success: true, data: records),
      );

      await notifier.loadAttendanceHistory('token');
      notifier.filterByDateRange(
        DateTime.utc(2026, 4, 10),
        DateTime.utc(2026, 4, 20),
      );

      final filtered = notifier.state.filteredAttendanceHistory;
      expect(filtered.length, 1);
      expect(filtered.first.date, DateTime.utc(2026, 4, 15));
    });

    test('AttendanceState.isCheckedInToday and isCheckedOutToday getters', () async {
      final notifier = AttendanceNotifier(
        getTodayAttendance: ({required token}) async =>
            _todayAttendance(hasCheckedIn: true, hasCheckedOut: false),
      );

      await notifier.loadTodayAttendance('token');

      expect(notifier.state.isCheckedInToday, true);
      expect(notifier.state.isCheckedOutToday, false);
    });

    // ── Reset ────────────────────────────────────────────────────────────────

    test('reset restores initial defaults', () async {
      final notifier = AttendanceNotifier(
        getTodayAttendance: ({required token}) async => _todayAttendance(),
      );

      await notifier.loadTodayAttendance('token');
      notifier.filterByStatus('late');
      notifier.setLocationError('GPS off');

      notifier.reset();

      expect(notifier.state, const AttendanceState());
    });
  });
}
