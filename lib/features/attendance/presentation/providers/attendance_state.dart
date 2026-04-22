import 'package:equatable/equatable.dart';
import 'package:hrms_app/features/attendance/data/models/today_attendance_model.dart';
import 'package:hrms_app/features/attendance/data/models/attendance_history_model.dart' as history_model;
import 'package:hrms_app/features/attendance/data/models/attendance_summary_model.dart';
import 'package:hrms_app/features/attendance/data/models/attendance_edit_request_model.dart';


/// Immutable Attendance State using Equatable for proper comparison
class AttendanceState extends Equatable {
  static const Object _unset = Object();

  final AttendanceData? todayAttendance;
  final List<history_model.AttendanceRecord>? attendanceHistory;
  final AttendanceSummary? attendanceSummary;
  final AttendanceEditRequestsList? myEditRequests;
  final bool isLoading;
  final bool isLoadingEditRequests;
  final bool isCheckingIn;
  final bool isCheckingOut;
  final bool isSubmittingEditRequest;
  final bool isSubmittingHalfDayRequest;
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
    this.myEditRequests,
    this.isLoading = false,
    this.isLoadingEditRequests = false,
    this.isCheckingIn = false,
    this.isCheckingOut = false,
    this.isSubmittingEditRequest = false,
    this.isSubmittingHalfDayRequest = false,
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
    Object? todayAttendance = _unset,
    Object? attendanceHistory = _unset,
    Object? attendanceSummary = _unset,
    Object? myEditRequests = _unset,
    bool? isLoading,
    bool? isLoadingEditRequests,
    bool? isCheckingIn,
    bool? isCheckingOut,
    bool? isSubmittingEditRequest,
    bool? isSubmittingHalfDayRequest,
    Object? errorMessage = _unset,
    Object? lastUpdated = _unset,
    Object? currentLatitude = _unset,
    Object? currentLongitude = _unset,
    Object? currentLocationError = _unset,
    Object? filterStartDate = _unset,
    Object? filterEndDate = _unset,
    String? selectedStatus,
    int? totalWorkingDays,
    int? presentDays,
    int? absentDays,
    int? lateDays,
    double? totalWorkHours,
    double? attendancePercentage,
  }) {
    return AttendanceState(
      todayAttendance: identical(todayAttendance, _unset)
        ? this.todayAttendance
        : todayAttendance as AttendanceData?,
      attendanceHistory: identical(attendanceHistory, _unset)
        ? this.attendanceHistory
        : attendanceHistory as List<history_model.AttendanceRecord>?,
      attendanceSummary: identical(attendanceSummary, _unset)
        ? this.attendanceSummary
        : attendanceSummary as AttendanceSummary?,
      myEditRequests: identical(myEditRequests, _unset)
        ? this.myEditRequests
        : myEditRequests as AttendanceEditRequestsList?,
      isLoading: isLoading ?? this.isLoading,
      isLoadingEditRequests: isLoadingEditRequests ?? this.isLoadingEditRequests,
      isCheckingIn: isCheckingIn ?? this.isCheckingIn,
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
      isSubmittingEditRequest: isSubmittingEditRequest ?? this.isSubmittingEditRequest,
      isSubmittingHalfDayRequest: isSubmittingHalfDayRequest ?? this.isSubmittingHalfDayRequest,
      errorMessage: identical(errorMessage, _unset)
        ? this.errorMessage
        : errorMessage as String?,
      lastUpdated: identical(lastUpdated, _unset)
        ? this.lastUpdated
        : lastUpdated as DateTime?,
      currentLatitude: identical(currentLatitude, _unset)
        ? this.currentLatitude
        : currentLatitude as double?,
      currentLongitude: identical(currentLongitude, _unset)
        ? this.currentLongitude
        : currentLongitude as double?,
      currentLocationError: identical(currentLocationError, _unset)
        ? this.currentLocationError
        : currentLocationError as String?,
      filterStartDate: identical(filterStartDate, _unset)
        ? this.filterStartDate
        : filterStartDate as DateTime?,
      filterEndDate: identical(filterEndDate, _unset)
        ? this.filterEndDate
        : filterEndDate as DateTime?,
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
    myEditRequests,
    isLoading,
    isLoadingEditRequests,
    isCheckingIn,
    isCheckingOut,
    isSubmittingEditRequest,
    isSubmittingHalfDayRequest,
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
