import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hrms_app/features/attendance/presentation/providers/attendance_state.dart';
import 'package:hrms_app/features/attendance/data/models/today_attendance_model.dart';
import 'package:hrms_app/features/attendance/data/services/attendance_service.dart';

/// Attendance Notifier - Manages all attendance state and business logic
class AttendanceNotifier extends ChangeNotifier {
  AttendanceState _state = const AttendanceState();

  final AttendanceService _attendanceService;

  AttendanceNotifier({required AttendanceService attendanceService})
      : _attendanceService = attendanceService;

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
      final response = await AttendanceService.getTodayAttendance(token: token);

      _setState(_state.copyWith(
        todayAttendance: response.data,
        isLoading: false,
        lastUpdated: DateTime.now(),
      ));

      debugPrint(
        '✅ Today\'s attendance loaded: ${response.data.hasCheckedIn ? "Checked In" : "Not Checked In"}',
      );
    } catch (e) {
      debugPrint('❌ Error loading today\'s attendance: $e');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load attendance: $e',
      ));
    }
  }

  /// Load attendance history
  Future<void> loadAttendanceHistory(String token) async {
    debugPrint('📊 AttendanceNotifier: Loading attendance history...');
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await AttendanceService.getAttendanceHistory(
        token: token,
      );

      _calculateStatistics(response.records);

      _setState(_state.copyWith(
        attendanceHistory: response.records,
        isLoading: false,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ Attendance history loaded: ${response.records.length} records');
    } catch (e) {
      debugPrint('❌ Error loading attendance history: $e');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load history: $e',
      ));
    }
  }

  /// Load attendance summary
  Future<void> loadAttendanceSummary(String token) async {
    debugPrint('📈 AttendanceNotifier: Loading attendance summary...');

    try {
      final response = await AttendanceService.getAttendanceSummary(
        token: token,
      );

      _setState(_state.copyWith(
        attendanceSummary: response.data,
        totalWorkingDays: response.data.workingDays,
        presentDays: response.data.presentDays,
        absentDays: response.data.absentDays,
        lateDays: response.data.lateDays,
        totalWorkHours: response.data.totalWorkingHours?.toDouble() ?? 0.0,
        attendancePercentage: _calculatePercentage(
          response.data.presentDays,
          response.data.workingDays,
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
  Future<void> refreshAttendance(String token) async {
    debugPrint('🔄 AttendanceNotifier: Refreshing attendance data...');
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      await Future.wait([
        loadTodayAttendance(token),
        loadAttendanceHistory(token),
        loadAttendanceSummary(token),
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
  Future<void> checkIn(
    String token,
    File photoFile,
    Position position,
  ) async {
    debugPrint('➡️  AttendanceNotifier: Checking in...');
    _setState(_state.copyWith(isCheckingIn: true, errorMessage: null));

    try {
      final response = await AttendanceService.checkIn(
        token: token,
        photoFile: photoFile,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      _setState(_state.copyWith(
        todayAttendance: response.data,
        isCheckingIn: false,
        currentLatitude: position.latitude,
        currentLongitude: position.longitude,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ Check in successful');
    } catch (e) {
      debugPrint('❌ Error checking in: $e');
      _setState(_state.copyWith(
        isCheckingIn: false,
        errorMessage: 'Failed to check in: $e',
      ));
    }
  }

  /// Check out with photo and location
  Future<void> checkOut(
    String token,
    File photoFile,
    Position position,
  ) async {
    debugPrint('⬅️  AttendanceNotifier: Checking out...');
    _setState(_state.copyWith(isCheckingOut: true, errorMessage: null));

    try {
      final response = await AttendanceService.checkOut(
        token: token,
        photoFile: photoFile,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      _setState(_state.copyWith(
        todayAttendance: response.data,
        isCheckingOut: false,
        currentLatitude: position.latitude,
        currentLongitude: position.longitude,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ Check out successful');
    } catch (e) {
      debugPrint('❌ Error checking out: $e');
      _setState(_state.copyWith(
        isCheckingOut: false,
        errorMessage: 'Failed to check out: $e',
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

  /// Calculate attendance statistics from history
  void _calculateStatistics(List<dynamic> records) {
    int present = 0;
    int absent = 0;
    int late = 0;

    for (var record in records) {
      final status = record.status?.toLowerCase() ?? '';
      if (status == 'present') {
        present++;
      } else if (status == 'absent') {
        absent++;
      } else if (status == 'late') {
        late++;
      }
    }

    final total = present + absent + late;
    final percentage = total > 0 ? (present / total) * 100 : 0.0;

    _setState(_state.copyWith(
      presentDays: present,
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
