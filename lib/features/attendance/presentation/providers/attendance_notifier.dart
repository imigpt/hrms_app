import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hrms_app/features/attendance/presentation/providers/attendance_state.dart';
import 'package:hrms_app/features/attendance/data/models/attendance_checkin_model.dart';
import 'package:hrms_app/features/attendance/data/models/attendance_history_model.dart'
    as history_model;
import 'package:hrms_app/features/attendance/data/models/attendance_summary_model.dart';
import 'package:hrms_app/features/attendance/data/models/today_attendance_model.dart';
import 'package:hrms_app/features/attendance/data/models/attendance_edit_request_model.dart';
import 'package:hrms_app/features/attendance/data/services/attendance_service.dart';

typedef _GetTodayAttendanceFn = Future<TodayAttendance?> Function({
  required String token,
});
typedef _GetAttendanceHistoryFn = Future<history_model.AttendanceHistory>
    Function({
      required String token,
      required int month,
      required int year,
    });
typedef _GetAttendanceSummaryFn = Future<AttendanceSummary> Function({
  required String token,
  required int month,
  required int year,
});
typedef _CheckInFn = Future<CheckInResponse> Function({
  required String token,
  required File photoFile,
  required double latitude,
  required double longitude,
});
typedef _CheckOutFn = Future<CheckInResponse> Function({
  required String token,
  required double latitude,
  required double longitude,
});
typedef _SubmitEditRequestFn = Future<AttendanceEditRequest> Function({
  required String token,
  required String attendanceId,
  required String requestedCheckIn,
  required String requestedCheckOut,
  required String reason,
});
typedef _SubmitHalfDayRequestFn = Future<Map<String, dynamic>> Function({
  required String token,
  required String date,
  required String reason,
});
typedef _GetEditRequestsFn = Future<AttendanceEditRequestsList> Function({
  required String token,
});

/// Attendance Notifier - Manages all attendance state and business logic
class AttendanceNotifier extends ChangeNotifier {
  AttendanceState _state = const AttendanceState();

  final _GetTodayAttendanceFn _getTodayAttendance;
  final _GetAttendanceHistoryFn _getAttendanceHistory;
  final _GetAttendanceSummaryFn _getAttendanceSummary;
  final _CheckInFn _checkIn;
  final _CheckOutFn _checkOut;
  final _SubmitEditRequestFn _submitEditRequest;
  final _SubmitHalfDayRequestFn _submitHalfDayRequest;
  final _GetEditRequestsFn _getEditRequests;

  AttendanceNotifier({
    _GetTodayAttendanceFn? getTodayAttendance,
    _GetAttendanceHistoryFn? getAttendanceHistory,
    _GetAttendanceSummaryFn? getAttendanceSummary,
    _CheckInFn? checkIn,
    _CheckOutFn? checkOut,
    _SubmitEditRequestFn? submitEditRequest,
    _SubmitHalfDayRequestFn? submitHalfDayRequest,
    _GetEditRequestsFn? getEditRequests,
  }) : _getTodayAttendance =
           getTodayAttendance ?? AttendanceService.getTodayAttendance,
       _getAttendanceHistory =
           getAttendanceHistory ?? AttendanceService.getAttendanceHistory,
       _getAttendanceSummary =
           getAttendanceSummary ?? AttendanceService.getAttendanceSummary,
       _checkIn = checkIn ?? AttendanceService.checkIn,
       _checkOut = checkOut ?? AttendanceService.checkOut,
       _submitEditRequest = submitEditRequest ?? AttendanceService.submitEditRequest,
       _submitHalfDayRequest = submitHalfDayRequest ?? AttendanceService.submitHalfDayRequest,
       _getEditRequests = getEditRequests ?? AttendanceService.getEditRequests;

  AttendanceState get state => _state;

  void _setState(AttendanceState newState) {
    _state = newState;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Load Attendance Data
  // ─────────────────────────────────────────────────────────────────────────

  /// Load today's attendance status
  Future<void> loadTodayAttendance(String token) async {
    debugPrint('📍 AttendanceNotifier: Loading today\'s attendance...');
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await _getTodayAttendance(token: token);

      if (response != null) {
        _setState(_state.copyWith(
          todayAttendance: response.data,
          isLoading: false,
          lastUpdated: DateTime.now(),
        ));

        final checkedInStatus = response.data?.hasCheckedIn ?? false;
        debugPrint(
          '✅ Today\'s attendance loaded: ${checkedInStatus ? "Checked In" : "Not Checked In"}',
        );
      } else {
        _setState(_state.copyWith(
          todayAttendance: null,
          isLoading: false,
          lastUpdated: DateTime.now(),
        ));
        debugPrint('✅ No attendance record for today');
      }
    } catch (e) {
      debugPrint('❌ Error loading today\'s attendance: $e');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load attendance: $e',
      ));
    }
  }

  /// Load attendance history
  Future<void> loadAttendanceHistory(
    String token, {
    int? month,
    int? year,
  }) async {
    debugPrint('📊 AttendanceNotifier: Loading attendance history...');
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final now = DateTime.now();
      final resolvedMonth = month ?? now.month;
      final resolvedYear = year ?? now.year;
      final response = await _getAttendanceHistory(
        token: token,
        month: resolvedMonth,
        year: resolvedYear,
      );

      _calculateStatistics(response.data);

      _setState(_state.copyWith(
        attendanceHistory: response.data,
        isLoading: false,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ Attendance history loaded: ${response.data.length} records');
    } catch (e) {
      debugPrint('❌ Error loading attendance history: $e');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load history: $e',
      ));
    }
  }

  /// Load attendance summary
  Future<void> loadAttendanceSummary(
    String token, {
    int? month,
    int? year,
  }) async {
    debugPrint('📈 AttendanceNotifier: Loading attendance summary...');

    try {
      final now = DateTime.now();
      final resolvedMonth = month ?? now.month;
      final resolvedYear = year ?? now.year;
      final response = await _getAttendanceSummary(
        token: token,
        month: resolvedMonth,
        year: resolvedYear,
      );

      _setState(_state.copyWith(
        attendanceSummary: response,
        totalWorkingDays: response.data.totalDays,
        presentDays: response.data.present,
        absentDays: response.data.absent,
        lateDays: response.data.late,
        totalWorkHours: response.data.totalWorkHours,
        attendancePercentage: _calculatePercentage(
          response.data.present,
          response.data.totalDays,
        ),
      ));

      debugPrint('✅ Attendance summary loaded');
    } catch (e) {
      debugPrint('❌ Error loading attendance summary: $e');
      _setState(_state.copyWith(
        errorMessage: 'Failed to load summary: $e',
      ));
    }
  }

  /// Refresh all attendance data
  Future<void> refreshAttendance(
    String token, {
    int? month,
    int? year,
  }) async {
    debugPrint('🔄 AttendanceNotifier: Refreshing attendance data...');
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      await Future.wait([
        loadTodayAttendance(token),
        loadAttendanceHistory(token, month: month, year: year),
        loadAttendanceSummary(token, month: month, year: year),
      ]);

      debugPrint('✅ Attendance refreshed successfully');
    } catch (e) {
      debugPrint('❌ Error refreshing attendance: $e');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to refresh: $e',
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Check In / Check Out
  // ─────────────────────────────────────────────────────────────────────────

  /// Check in with photo and location
  Future<CheckInResponse> checkInWithCoordinates(
    String token,
    File photoFile, {
    required double latitude,
    required double longitude,
  }) async {
    debugPrint('➡️  AttendanceNotifier: Checking in...');
    _setState(_state.copyWith(isCheckingIn: true, errorMessage: null));

    try {
      final response = await _checkIn(
        token: token,
        photoFile: photoFile,
        latitude: latitude,
        longitude: longitude,
      );

      // Reload today's attendance to get the updated state
      await loadTodayAttendance(token);

      _setState(_state.copyWith(
        isCheckingIn: false,
        currentLatitude: latitude,
        currentLongitude: longitude,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ Check in successful');
      return response;
    } catch (e) {
      debugPrint('❌ Error checking in: $e');
      _setState(_state.copyWith(
        isCheckingIn: false,
        errorMessage: 'Failed to check in: $e',
      ));
      rethrow;
    }
  }

  Future<void> checkIn(
    String token,
    File photoFile,
    Position position,
  ) async {
    await checkInWithCoordinates(
      token,
      photoFile,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<CheckInResponse> checkOutWithCoordinates(
    String token, {
    required double latitude,
    required double longitude,
  }) async {
    debugPrint('⬅️  AttendanceNotifier: Checking out...');
    _setState(_state.copyWith(isCheckingOut: true, errorMessage: null));

    try {
      final response = await _checkOut(
        token: token,
        latitude: latitude,
        longitude: longitude,
      );

      // Reload today's attendance to get the updated state
      await loadTodayAttendance(token);

      _setState(_state.copyWith(
        isCheckingOut: false,
        currentLatitude: latitude,
        currentLongitude: longitude,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ Check out successful');
      return response;
    } catch (e) {
      debugPrint('❌ Error checking out: $e');
      _setState(_state.copyWith(
        isCheckingOut: false,
        errorMessage: 'Failed to check out: $e',
      ));
      rethrow;
    }
  }

  /// Check out with location (no photo required)
  Future<void> checkOut(
    String token,
    Position position,
  ) async {
    await checkOutWithCoordinates(
      token,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }



  // ─────────────────────────────────────────────────────────────────────────
  // Requests
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> submitEditRequest({
    required String token,
    required String attendanceId,
    required String requestedCheckIn,
    required String requestedCheckOut,
    required String reason,
  }) async {
    debugPrint('📝 AttendanceNotifier: Submitting edit request...');
    _setState(_state.copyWith(isSubmittingEditRequest: true, errorMessage: null));

    try {
      await _submitEditRequest(
        token: token,
        attendanceId: attendanceId,
        requestedCheckIn: requestedCheckIn,
        requestedCheckOut: requestedCheckOut,
        reason: reason,
      );

      _setState(_state.copyWith(isSubmittingEditRequest: false));
      debugPrint('✅ Edit request submitted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error submitting edit request: $e');
      _setState(_state.copyWith(
        isSubmittingEditRequest: false,
        errorMessage: 'Failed to submit edit request: $e',
      ));
      return false;
    }
  }

  Future<bool> submitHalfDayRequest({
    required String token,
    required String date,
    required String reason,
  }) async {
    debugPrint('🕒 AttendanceNotifier: Submitting half-day request...');
    _setState(_state.copyWith(isSubmittingHalfDayRequest: true, errorMessage: null));

    try {
      await _submitHalfDayRequest(
        token: token,
        date: date,
        reason: reason,
      );

      _setState(_state.copyWith(isSubmittingHalfDayRequest: false));
      debugPrint('✅ Half-day request submitted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error submitting half-day request: $e');
      _setState(_state.copyWith(
        isSubmittingHalfDayRequest: false,
        errorMessage: 'Failed to submit half-day request: $e',
      ));
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fetch Edit Requests
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadMyEditRequests(String token) async {
    debugPrint('📋 AttendanceNotifier: Loading my edit requests...');
    _setState(_state.copyWith(isLoadingEditRequests: true, errorMessage: null));

    try {
      final response = await _getEditRequests(token: token);

      _setState(_state.copyWith(
        myEditRequests: response,
        isLoadingEditRequests: false,
      ));

      debugPrint('✅ My edit requests loaded');
    } catch (e) {
      debugPrint('❌ Error loading my edit requests: $e');
      _setState(_state.copyWith(
        isLoadingEditRequests: false,
        errorMessage: 'Failed to load edit requests: $e',
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Location Management
  // ─────────────────────────────────────────────────────────────────────────

  /// Update current location
  void updateCurrentLocation(double latitude, double longitude) {
    debugPrint('📍 AttendanceNotifier: Location updated: $latitude, $longitude');
    _setState(_state.copyWith(
      currentLatitude: latitude,
      currentLongitude: longitude,
      currentLocationError: null,
    ));
  }

  /// Set location error
  void setLocationError(String error) {
    debugPrint('❌ AttendanceNotifier: Location error: $error');
    _setState(_state.copyWith(currentLocationError: error));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Filtering & Search
  // ─────────────────────────────────────────────────────────────────────────

  /// Filter by date range
  void filterByDateRange(DateTime? startDate, DateTime? endDate) {
    debugPrint('🔍 AttendanceNotifier: Filtering by date: $startDate - $endDate');
    _setState(_state.copyWith(
      filterStartDate: startDate,
      filterEndDate: endDate,
    ));
  }

  /// Filter by status
  void filterByStatus(String status) {
    debugPrint('🔍 AttendanceNotifier: Filtering by status: $status');
    _setState(_state.copyWith(selectedStatus: status));
  }

  /// Clear all filters
  void clearFilters() {
    debugPrint('🔍 AttendanceNotifier: Clearing all filters');
    _setState(_state.copyWith(
      filterStartDate: null,
      filterEndDate: null,
      selectedStatus: 'all',
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Statistics Calculation
  // ─────────────────────────────────────────────────────────────────────────

  /// Calculate attendance statistics from history records (handles all status variants)
  void _calculateStatistics(List<history_model.AttendanceRecord> records) {
    int present = 0;
    int absent = 0;
    int late = 0;
    int inProgress = 0;
    int halfDay = 0;

    for (var record in records) {
      final status = record.status.toLowerCase().trim();
      if (status == 'present') {
        present++;
      } else if (status == 'absent') {
        absent++;
      } else if (status == 'late') {
        late++;
      } else if (status == 'in-progress' ||
          status == 'in_progress' ||
          status == 'in progress') {
        inProgress++;
      } else if (status == 'halfday' ||
          status == 'half_day' ||
          status == 'half day' ||
          status == 'half-day') {
        halfDay++;
      }
      // 'leave', 'on-leave', 'wfh' are not counted toward attendance percentage
    }

    // For percentage: present + late count as "present", inProgress also counts
    final effectivePresent = present + late + inProgress;
    final total = present + absent + late + inProgress + halfDay;
    final percentage = total > 0 ? (effectivePresent / total) * 100 : 0.0;

    _setState(_state.copyWith(
      presentDays: present + late, // official present (including late)
      absentDays: absent,
      lateDays: late,
      totalWorkingDays: total,
      attendancePercentage: percentage,
    ));
  }

  /// Calculate attendance percentage
  double _calculatePercentage(int present, int total) {
    if (total == 0) return 0.0;
    return (present / total) * 100;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Error Handling
  // ─────────────────────────────────────────────────────────────────────────

  /// Clear error message
  void clearError() {
    _setState(_state.copyWith(errorMessage: null));
  }

  /// Reset to initial state
  void reset() {
    _setState(const AttendanceState());
  }
}
