import 'package:equatable/equatable.dart';
import 'package:hrms_app/features/leave/data/models/leave_management_model.dart';

/// Immutable state for leave feature
class LeaveState extends Equatable {
  final Map<String, dynamic>? userBalance; // Current user's balance
  final List<AdminLeaveData> leaves;
  final bool isLoading;
  final bool isLoadingBalance;
  final bool isLoadingLeaves;
  final String? errorMessage;
  final String? errorType; // 'balance', 'leaves', 'approval', 'rejection'
  final String selectedFilter;
  final String roleFilter; // for balance: 'all' | 'hr' | 'employee'
  final String statusFilter; // for management: 'all' | 'pending' | 'approved' | 'rejected' | 'cancelled'
  final String typeFilter; // 'all' | 'sick' | 'paid' | 'unpaid'
  final String searchQuery;

  const LeaveState({
    this.userBalance,
    this.leaves = const [],
    this.isLoading = false,
    this.isLoadingBalance = false,
    this.isLoadingLeaves = false,
    this.errorMessage,
    this.errorType,
    this.selectedFilter = 'All',
    this.roleFilter = 'all',
    this.statusFilter = 'all',
    this.typeFilter = 'all',
    this.searchQuery = '',
  });

  LeaveState copyWith({
    Map<String, dynamic>? userBalance,
    List<AdminLeaveData>? leaves,
    bool? isLoading,
    bool? isLoadingBalance,
    bool? isLoadingLeaves,
    String? errorMessage,
    String? errorType,
    String? selectedFilter,
    String? roleFilter,
    String? statusFilter,
    String? typeFilter,
    String? searchQuery,
  }) {
    return LeaveState(
      userBalance: userBalance ?? this.userBalance,
      leaves: leaves ?? this.leaves,
      isLoading: isLoading ?? this.isLoading,
      isLoadingBalance: isLoadingBalance ?? this.isLoadingBalance,
      isLoadingLeaves: isLoadingLeaves ?? this.isLoadingLeaves,
      errorMessage: errorMessage ?? this.errorMessage,
      errorType: errorType ?? this.errorType,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      roleFilter: roleFilter ?? this.roleFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      typeFilter: typeFilter ?? this.typeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    userBalance,
    leaves,
    isLoading,
    isLoadingBalance,
    isLoadingLeaves,
    errorMessage,
    errorType,
    selectedFilter,
    roleFilter,
    statusFilter,
    typeFilter,
    searchQuery,
  ];
}
