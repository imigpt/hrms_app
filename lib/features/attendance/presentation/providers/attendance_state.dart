import 'package:equatable/equatable.dart';
import 'package:hrms_app/features/attendance/data/models/today_attendance_model.dart';
import 'package:hrms_app/features/attendance/data/models/attendance_history_model.dart' as history_model;
import 'package:hrms_app/features/attendance/data/models/attendance_summary_model.dart';

/// Immutable Attendance State using Equatable for proper comparison
class AttendanceState extends Equatable {
  final AttendanceData? todayAttendance;
  final List<history_model.AttendanceRecord>? attendanceHistory;
  final AttendanceSummary? attendanceSummary;
  final bool isLoading;
  final bool isCheckingIn;
  final bool isCheckingOut;
  final String? errorMessage;
  final DateTime? lastUpdated;
  
  /// Location tracking for check-in/out
  final double? currentLatitude;
  final double? currentLongitude;
  final String? currentLocationError;
  
  /// Filter & Date Range
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final String selectedStatus; // 'all', 'present', 'absent', 'late'
  
  /// Statistics
  final int totalWorkingDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final double totalWorkHours;
  final double attendancePercentage;

  const AttendanceState({
    this.todayAttendance,
    this.attendanceHistory,
    this.attendanceSummary,
    this.isLoading = false,
    this.isCheckingIn = false,
    this.isCheckingOut = false,
    this.errorMessage,
    this.lastUpdated,
    this.currentLatitude,
    this.currentLongitude,
    this.currentLocationError,
    this.filterStartDate,
    this.filterEndDate,
    this.selectedStatus = 'all',
    this.totalWorkingDays = 0,
    this.presentDays = 0,
    this.absentDays = 0,
    this.lateDays = 0,
    this.totalWorkHours = 0.0,
    this.attendancePercentage = 0.0,
  });

  /// Create a copy of this state with optional property overrides
  AttendanceState copyWith({
    AttendanceData? todayAttendance,
    List<history_model.AttendanceRecord>? attendanceHistory,
    AttendanceSummary? attendanceSummary,
    bool? isLoading,
    bool? isCheckingIn,
    bool? isCheckingOut,
    String? errorMessage,
    DateTime? lastUpdated,
    double? currentLatitude,
    double? currentLongitude,
    String? currentLocationError,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    String? selectedStatus,
    int? totalWorkingDays,
    int? presentDays,
    int? absentDays,
    int? lateDays,
    double? totalWorkHours,
    double? attendancePercentage,
  }) {
    return AttendanceState(
      todayAttendance: todayAttendance ?? this.todayAttendance,
      attendanceHistory: attendanceHistory ?? this.attendanceHistory,
      attendanceSummary: attendanceSummary ?? this.attendanceSummary,
      isLoading: isLoading ?? this.isLoading,
      isCheckingIn: isCheckingIn ?? this.isCheckingIn,
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      currentLocationError: currentLocationError ?? this.currentLocationError,
      filterStartDate: filterStartDate ?? this.filterStartDate,
      filterEndDate: filterEndDate ?? this.filterEndDate,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      totalWorkingDays: totalWorkingDays ?? this.totalWorkingDays,
      presentDays: presentDays ?? this.presentDays,
      absentDays: absentDays ?? this.absentDays,
      lateDays: lateDays ?? this.lateDays,
      totalWorkHours: totalWorkHours ?? this.totalWorkHours,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
    );
  }

  /// Whether employee is checked in today
  bool get isCheckedInToday => todayAttendance?.hasCheckedIn ?? false;

  /// Whether employee is checked out today
  bool get isCheckedOutToday => todayAttendance?.hasCheckedOut ?? false;

  /// Check-in time for today
  DateTime? get todayCheckInTime {
    final timeStr = todayAttendance?.checkIn?.time;
    if (timeStr == null) return null;
    try {
      return DateTime.parse(timeStr);
    } catch (e) {
      return null;
    }
  }

  /// Check-out time for today
  DateTime? get todayCheckOutTime {
    final timeStr = todayAttendance?.checkOut?.time;
    if (timeStr == null) return null;
    try {
      return DateTime.parse(timeStr);
    } catch (e) {
      return null;
    }
  }

  /// Worked hours today
  double get todayWorkedHours => todayAttendance?.workHours ?? 0.0;

  /// Filtered attendance history based on date range and status
  List<history_model.AttendanceRecord> get filteredAttendanceHistory {
    if (attendanceHistory == null) return [];
    
    return attendanceHistory!.where((record) {
      // Filter by date range
      if (filterStartDate != null && record.date.isBefore(filterStartDate!)) {
        return false;
      }
      if (filterEndDate != null && record.date.isAfter(filterEndDate!)) {
        return false;
      }

      // Filter by status
      if (selectedStatus != 'all') {
        final recordStatus = record.status?.toLowerCase() ?? '';
        if (recordStatus != selectedStatus.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  List<Object?> get props => [
    todayAttendance,
    attendanceHistory,
    attendanceSummary,
    isLoading,
    isCheckingIn,
    isCheckingOut,
    errorMessage,
    lastUpdated,
    currentLatitude,
    currentLongitude,
    currentLocationError,
    filterStartDate,
    filterEndDate,
    selectedStatus,
    totalWorkingDays,
    presentDays,
    absentDays,
    lateDays,
    totalWorkHours,
    attendancePercentage,
  ];
}
