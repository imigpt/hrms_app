import 'package:equatable/equatable.dart';
import 'package:hrms_app/features/dashboard/data/models/dashboard_stats_model.dart';
import 'package:hrms_app/features/announcements/data/models/announcement_model.dart';
import 'package:hrms_app/features/leave/data/models/leave_management_model.dart';
import 'package:hrms_app/features/expenses/data/models/expense_model.dart';

/// Immutable Dashboard State using Equatable for proper comparison
class DashboardState extends Equatable {
  final DashboardData? dashboardData;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final DateTime? lastUpdated;
  
  /// Attendance state
  final bool isCheckedIn;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? checkInLocation;
  final String? checkOutLocation;
  final Duration workedDuration;
  
  /// Notifications & Chat
  final int unreadNotificationsCount;
  final int unreadChatCount;
  
  /// Announcements
  final List<Announcement> announcements;
  final bool announcementsLoading;

  const DashboardState({
    this.dashboardData,
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.lastUpdated,
    this.isCheckedIn = false,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLocation,
    this.checkOutLocation,
    this.workedDuration = const Duration(),
    this.unreadNotificationsCount = 0,
    this.unreadChatCount = 0,
    this.announcements = const [],
    this.announcementsLoading = false,
  });

  /// Create a copy of this state with optional property overrides
  DashboardState copyWith({
    DashboardData? dashboardData,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    DateTime? lastUpdated,
    bool? isCheckedIn,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? checkInLocation,
    String? checkOutLocation,
    Duration? workedDuration,
    int? unreadNotificationsCount,
    int? unreadChatCount,
    List<Announcement>? announcements,
    bool? announcementsLoading,
  }) {
    return DashboardState(
      dashboardData: dashboardData ?? this.dashboardData,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      workedDuration: workedDuration ?? this.workedDuration,
      unreadNotificationsCount:
          unreadNotificationsCount ?? this.unreadNotificationsCount,
      unreadChatCount: unreadChatCount ?? this.unreadChatCount,
      announcements: announcements ?? this.announcements,
      announcementsLoading: announcementsLoading ?? this.announcementsLoading,
    );
  }

  /// Computed properties for quick stats
  int get totalLeaveBalance {
    if (dashboardData?.stats.leaveBalance == null) return 0;
    return (dashboardData!.stats.leaveBalance!.annual ?? 0) +
        (dashboardData!.stats.leaveBalance!.sick ?? 0) +
        (dashboardData!.stats.leaveBalance!.casual ?? 0);
  }

  int get pendingLeaveRequests =>
      dashboardData?.stats.pendingLeaveRequests ?? 0;

  int get totalTasks => dashboardData?.tasks.length ?? 0;

  int get completedTasks =>
      dashboardData?.tasks.where((t) => t.status == 'completed').length ?? 0;

  int get pendingTasks =>
      dashboardData?.tasks.where((t) => t.status != 'completed').length ?? 0;

  int get totalExpenses =>
      dashboardData?.stats.expensesPending ?? 0;

  String get attendanceStatus {
    if (isCheckedIn) {
      return 'Checked In';
    }
    return 'Checked Out';
  }

  @override
  List<Object?> get props => [
    dashboardData,
    isLoading,
    isRefreshing,
    errorMessage,
    lastUpdated,
    isCheckedIn,
    checkInTime,
    checkOutTime,
    checkInLocation,
    checkOutLocation,
    workedDuration,
    unreadNotificationsCount,
    unreadChatCount,
    announcements,
    announcementsLoading,
  ];
}
