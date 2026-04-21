import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/features/attendance/data/models/attendance_history_model.dart'
    as history_model;
import 'package:hrms_app/features/attendance/data/models/attendance_summary_model.dart';
import 'package:hrms_app/features/attendance/data/models/today_attendance_model.dart'
    as today_model;
import 'package:hrms_app/features/attendance/presentation/providers/attendance_notifier.dart';
import 'package:hrms_app/features/attendance/presentation/providers/attendance_state.dart';

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

void main() {
  group('AttendanceNotifier', () {
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

    test('loadTodayAttendance allows clearing todayAttendance with null response', () async {
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

    test('loadAttendanceHistory updates records and computed statistics', () async {
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
      expect(notifier.state.presentDays, 2);
      expect(notifier.state.lateDays, 1);
      expect(notifier.state.absentDays, 1);
      expect(notifier.state.totalWorkingDays, 4);
      expect(notifier.state.attendancePercentage, 50.0);
    });

    test('loadAttendanceHistory uses explicit month and year when provided', () async {
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

    test('loadAttendanceSummary uses explicit month and year when provided', () async {
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

    test('clearFilters resets filters to defaults', () {
      final notifier = AttendanceNotifier();
      notifier.filterByDateRange(DateTime.utc(2026, 4, 1), DateTime.utc(2026, 4, 30));
      notifier.filterByStatus('late');

      notifier.clearFilters();

      expect(notifier.state.filterStartDate, isNull);
      expect(notifier.state.filterEndDate, isNull);
      expect(notifier.state.selectedStatus, 'all');
    });

    test('refreshAttendance triggers today, history, and summary loaders', () async {
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
            data: [_historyRecord(date: DateTime.utc(2026, 4, 1), status: 'present')],
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

    test('loadTodayAttendance sets error on failure and clearError clears it', () async {
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
