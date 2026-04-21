import 'package:flutter/foundation.dart';
import 'package:hrms_app/features/leave/data/models/apply_leave_model.dart';
import 'package:hrms_app/features/leave/data/models/leave_management_model.dart';
import 'package:hrms_app/features/leave/data/services/leave_service.dart';
import 'package:hrms_app/features/leave/presentation/providers/leave_state.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';

class LeaveNotifier extends ChangeNotifier {
  LeaveState _state = const LeaveState();
  final TokenStorageService _tokenStorage = TokenStorageService();

  LeaveState get state => _state;

  void _setState(LeaveState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Load user's leave balance data
  Future<void> loadLeaveBalance() async {
    _setState(_state.copyWith(isLoadingBalance: true, errorMessage: null));
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        _setState(_state.copyWith(
          isLoadingBalance: false,
          errorMessage: 'Authentication data not found',
          errorType: 'balance',
        ));
        return;
      }

      final response = await LeaveService.getLeaveBalance(token: token);

      if (response.success) {
        _setState(_state.copyWith(
          userBalance: response.data != null
              ? {
                  'paid': response.data!.paid,
                  'sick': response.data!.sick,
                  'unpaid': response.data!.unpaid,
                  'usedPaid': response.data!.usedPaid,
                  'usedSick': response.data!.usedSick,
                  'usedUnpaid': response.data!.usedUnpaid,
                }
              : null,
          isLoadingBalance: false,
          errorMessage: null,
        ));
      } else {
        _setState(_state.copyWith(
          isLoadingBalance: false,
          errorMessage: 'Failed to load leave balance',
          errorType: 'balance',
        ));
      }
    } catch (e) {
      debugPrint('Error loading leave balance: $e');
      _setState(_state.copyWith(
        isLoadingBalance: false,
        errorMessage: 'Error: ${e.toString()}',
        errorType: 'balance',
      ));
    }
  }

  /// Load user's leave requests/applications
  Future<void> loadLeaveRequests({String? filter}) async {
    _setState(_state.copyWith(
      isLoading: true,
      errorMessage: null,
      selectedFilter: filter ?? _state.selectedFilter,
    ));
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        _setState(_state.copyWith(
          isLoading: false,
          errorMessage: 'Authentication data not found',
          errorType: 'leaves',
        ));
        return;
      }

      final response = await LeaveService.getMyLeaves(token: token);

      if (response['success'] == true && response['data'] != null) {
        /// Parse the response data into AdminLeaveData objects
        final leavesData = (response['data'] as List<dynamic>)
            .map((e) => AdminLeaveData.fromJson(e as Map<String, dynamic>))
            .toList();

        _setState(_state.copyWith(
          leaves: leavesData,
          isLoading: false,
          errorMessage: null,
        ));
      } else {
        _setState(_state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load leave requests',
          errorType: 'leaves',
        ));
      }
    } catch (e) {
      debugPrint('Error loading leave requests: $e');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: 'Error: ${e.toString()}',
        errorType: 'leaves',
      ));
    }
  }

  /// Load all leaves for management (admin/HR view)
  Future<void> loadAllLeaves({
    String statusFilter = 'all',
    String typeFilter = 'all',
  }) async {
    _setState(_state.copyWith(
      isLoadingLeaves: true,
      errorMessage: null,
      statusFilter: statusFilter,
      typeFilter: typeFilter,
    ));
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        _setState(_state.copyWith(
          isLoadingLeaves: false,
          errorMessage: 'Authentication data not found',
          errorType: 'leaves',
        ));
        return;
      }

      final response = await LeaveService.getAdminLeaves(token: token);

      if (response.success) {
        _setState(_state.copyWith(
          leaves: response.data,
          isLoadingLeaves: false,
          errorMessage: null,
        ));
      } else {
        _setState(_state.copyWith(
          isLoadingLeaves: false,
          errorMessage: 'Failed to load leaves',
          errorType: 'leaves',
        ));
      }
    } catch (e) {
      debugPrint('Error loading all leaves: $e');
      _setState(_state.copyWith(
        isLoadingLeaves: false,
        errorMessage: 'Error: ${e.toString()}',
        errorType: 'leaves',
      ));
    }
  }

  /// Load leave balances list for admin/HR management screen
  Future<void> loadLeaveBalances() async {
    _setState(_state.copyWith(
      isLoadingLeaveBalances: true,
      errorMessage: null,
      errorType: null,
    ));

    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        _setState(_state.copyWith(
          isLoadingLeaveBalances: false,
          errorMessage: 'Authentication data not found',
          errorType: 'leaveBalances',
        ));
        return;
      }

      final response = await LeaveService.getLeaveBalances(token: token);

      _setState(_state.copyWith(
        leaveBalances: response.data,
        isLoadingLeaveBalances: false,
        errorMessage: null,
        errorType: null,
      ));
    } catch (e) {
      debugPrint('Error loading leave balances: $e');
      _setState(_state.copyWith(
        isLoadingLeaveBalances: false,
        errorMessage: e.toString().replaceFirst('Exception:', '').trim(),
        errorType: 'leaveBalances',
      ));
    }
  }

  /// Assign leave balance for single user (admin/HR action)
  Future<void> assignLeaveBalance({
    required String userId,
    required int paid,
    required int sick,
    required int unpaid,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        _setState(_state.copyWith(
          errorMessage: 'Authentication data not found',
          errorType: 'leaveBalances',
        ));
        return;
      }

      await LeaveService.assignLeaveBalance(
        token: token,
        userId: userId,
        paid: paid,
        sick: sick,
        unpaid: unpaid,
      );
    } catch (e) {
      debugPrint('Error assigning leave balance: $e');
      _setState(_state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception:', '').trim(),
        errorType: 'leaveBalances',
      ));
    }
  }

  /// Bulk assign leave balances (admin/HR action)
  Future<void> bulkAssignLeaveBalance({
    required List<String> userIds,
    required int paid,
    required int sick,
    required int unpaid,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        _setState(_state.copyWith(
          errorMessage: 'Authentication data not found',
          errorType: 'leaveBalances',
        ));
        return;
      }

      await LeaveService.bulkAssignLeaveBalance(
        token: token,
        userIds: userIds,
        paid: paid,
        sick: sick,
        unpaid: unpaid,
      );
    } catch (e) {
      debugPrint('Error bulk assigning leave balances: $e');
      _setState(_state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception:', '').trim(),
        errorType: 'leaveBalances',
      ));
    }
  }

  /// Approve a leave request (admin action)
  Future<void> approveLeave(String leaveId) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return;
      }

      await LeaveService.approveAdminLeave(
        token: token,
        leaveId: leaveId,
      );

      // Reload leaves after approval
      await loadAllLeaves(
        statusFilter: _state.statusFilter,
        typeFilter: _state.typeFilter,
      );
    } catch (e) {
      debugPrint('Error approving leave: $e');
      _setState(_state.copyWith(
        errorMessage: 'Error: ${e.toString()}',
        errorType: 'approval',
      ));
    }
  }

  /// Reject a leave request (admin action)
  Future<void> rejectLeave(String leaveId, String reviewNote) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return;
      }

      await LeaveService.rejectAdminLeave(
        token: token,
        leaveId: leaveId,
        reviewNote: reviewNote,
      );

      // Reload leaves after rejection
      await loadAllLeaves(
        statusFilter: _state.statusFilter,
        typeFilter: _state.typeFilter,
      );
    } catch (e) {
      debugPrint('Error rejecting leave: $e');
      _setState(_state.copyWith(
        errorMessage: 'Error: ${e.toString()}',
        errorType: 'rejection',
      ));
    }
  }

  /// Update role filter for balance view
  void setRoleFilter(String role) {
    _setState(_state.copyWith(roleFilter: role));
  }

  /// Update status filter for management view
  void setStatusFilter(String status) {
    _setState(_state.copyWith(statusFilter: status));
  }

  /// Update type filter for management view
  void setTypeFilter(String type) {
    _setState(_state.copyWith(typeFilter: type));
  }

  /// Update search query
  void setSearchQuery(String query) {
    _setState(_state.copyWith(searchQuery: query));
  }

  /// Apply full-day leave request.
  Future<ApplyLeaveResponse> applyLeave({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    double? days,
  }) async {
    final token = await _tokenStorage.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    _setState(_state.copyWith(isLoading: true, errorMessage: null, errorType: null));
    try {
      final response = await LeaveService.applyLeave(
        token: token,
        leaveType: leaveType,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        days: days,
      );

      // Keep both balances and leave requests in sync after successful apply.
      await Future.wait([
        loadLeaveBalance(),
        loadLeaveRequests(),
      ]);
      _setState(_state.copyWith(isLoading: false));
      return response;
    } catch (e) {
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception:', '').trim(),
        errorType: 'apply',
      ));
      rethrow;
    }
  }

  /// Apply half-day leave request.
  Future<ApplyLeaveResponse> applyHalfDayLeave({
    required DateTime date,
    required String session,
    required String reason,
    String leaveType = 'paid',
  }) async {
    final token = await _tokenStorage.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    _setState(_state.copyWith(isLoading: true, errorMessage: null, errorType: null));
    try {
      final response = await LeaveService.applyHalfDayLeave(
        token: token,
        date: date,
        session: session,
        reason: reason,
        leaveType: leaveType,
      );

      await Future.wait([
        loadLeaveBalance(),
        loadLeaveRequests(),
      ]);
      _setState(_state.copyWith(isLoading: false));
      return response;
    } catch (e) {
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception:', '').trim(),
        errorType: 'apply',
      ));
      rethrow;
    }
  }

  /// Clear errors
  void clearError() {
    _setState(_state.copyWith(errorMessage: null, errorType: null));
  }
}

