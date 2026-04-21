import 'package:equatable/equatable.dart';
import 'package:hrms_app/features/expenses/data/models/expense_model.dart';

/// Immutable Expenses State using Equatable for proper comparison
class ExpensesState extends Equatable {
  static const Object _unset = Object();

  final List<Expense> expenses;
  final Expense? selectedExpense;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSubmitting;
  final String? errorMessage;
  final DateTime? lastUpdated;
  final int currentPage;
  final int totalCount;
  final bool hasMore;
  
  /// Filter & Search
  final String selectedCategory;
  final String selectedStatus; // 'all', 'pending', 'approved', 'rejected'
  final double? filterAmountMin;
  final double? filterAmountMax;
  final DateTime? filterDateFrom;
  final DateTime? filterDateTo;

  /// Statistics
  final double totalSubmittedAmount; // Total submitted
  final double totalApprovedAmount;  // Total approved
  final double totalRejectedAmount;  // Total rejected
  final int pendingExpenseCount;
  final int approvedExpenseCount;
  final int rejectedExpenseCount;

  const ExpensesState({
    this.expenses = const [],
    this.selectedExpense,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.lastUpdated,
    this.currentPage = 1,
    this.totalCount = 0,
    this.hasMore = false,
    this.selectedCategory = 'all',
    this.selectedStatus = 'all',
    this.filterAmountMin,
    this.filterAmountMax,
    this.filterDateFrom,
    this.filterDateTo,
    this.totalSubmittedAmount = 0.0,
    this.totalApprovedAmount = 0.0,
    this.totalRejectedAmount = 0.0,
    this.pendingExpenseCount = 0,
    this.approvedExpenseCount = 0,
    this.rejectedExpenseCount = 0,
  });

  /// Create a copy of this state with optional property overrides
  ExpensesState copyWith({
    List<Expense>? expenses,
    Object? selectedExpense = _unset,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSubmitting,
    Object? errorMessage = _unset,
    DateTime? lastUpdated,
    int? currentPage,
    int? totalCount,
    bool? hasMore,
    String? selectedCategory,
    String? selectedStatus,
    Object? filterAmountMin = _unset,
    Object? filterAmountMax = _unset,
    Object? filterDateFrom = _unset,
    Object? filterDateTo = _unset,
    double? totalSubmittedAmount,
    double? totalApprovedAmount,
    double? totalRejectedAmount,
    int? pendingExpenseCount,
    int? approvedExpenseCount,
    int? rejectedExpenseCount,
  }) {
    return ExpensesState(
      expenses: expenses ?? this.expenses,
      selectedExpense: identical(selectedExpense, _unset)
        ? this.selectedExpense
        : selectedExpense as Expense?,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _unset)
        ? this.errorMessage
        : errorMessage as String?,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      filterAmountMin: identical(filterAmountMin, _unset)
        ? this.filterAmountMin
        : filterAmountMin as double?,
      filterAmountMax: identical(filterAmountMax, _unset)
        ? this.filterAmountMax
        : filterAmountMax as double?,
      filterDateFrom: identical(filterDateFrom, _unset)
        ? this.filterDateFrom
        : filterDateFrom as DateTime?,
      filterDateTo: identical(filterDateTo, _unset)
        ? this.filterDateTo
        : filterDateTo as DateTime?,
      totalSubmittedAmount: totalSubmittedAmount ?? this.totalSubmittedAmount,
      totalApprovedAmount: totalApprovedAmount ?? this.totalApprovedAmount,
      totalRejectedAmount: totalRejectedAmount ?? this.totalRejectedAmount,
      pendingExpenseCount: pendingExpenseCount ?? this.pendingExpenseCount,
      approvedExpenseCount: approvedExpenseCount ?? this.approvedExpenseCount,
      rejectedExpenseCount: rejectedExpenseCount ?? this.rejectedExpenseCount,
    );
  }

  /// Filtered expenses based on current filters
  List<Expense> get filteredExpenses {
    return expenses.where((expense) {
      // Filter by category
      if (selectedCategory != 'all' && expense.category != selectedCategory) {
        return false;
      }

      // Filter by status
      if (selectedStatus != 'all' && expense.status != selectedStatus) {
        return false;
      }

      // Filter by amount range
      if (filterAmountMin != null && expense.amount < filterAmountMin!) {
        return false;
      }
      if (filterAmountMax != null && expense.amount > filterAmountMax!) {
        return false;
      }

      // Filter by date range
      if (filterDateFrom != null &&
          expense.date.isBefore(filterDateFrom!)) {
        return false;
      }
      if (filterDateTo != null && expense.date.isAfter(filterDateTo!)) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  List<Object?> get props => [
    expenses,
    selectedExpense,
    isLoading,
    isLoadingMore,
    isSubmitting,
    errorMessage,
    lastUpdated,
    currentPage,
    totalCount,
    hasMore,
    selectedCategory,
    selectedStatus,
    filterAmountMin,
    filterAmountMax,
    filterDateFrom,
    filterDateTo,
    totalSubmittedAmount,
    totalApprovedAmount,
    totalRejectedAmount,
    pendingExpenseCount,
    approvedExpenseCount,
    rejectedExpenseCount,
  ];
}
