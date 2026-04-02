import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hrms_app/features/expenses/presentation/providers/expenses_state.dart';
import 'package:hrms_app/features/expenses/data/models/expense_model.dart';
import 'package:hrms_app/features/expenses/data/services/expense_service.dart';

/// Expenses Notifier - Manages all expenses state and business logic
class ExpensesNotifier extends ChangeNotifier {
  ExpensesState _state = const ExpensesState();

  final ExpenseService _expenseService;

  ExpensesNotifier({required ExpenseService expenseService})
      : _expenseService = expenseService;

  ExpensesState get state => _state;

  void _setState(ExpensesState newState) {
    _state = newState;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Load Expenses
  // ─────────────────────────────────────────────────────────────────────────

  /// Load all expenses
  Future<void> loadExpenses(String token) async {
    debugPrint('💰 ExpensesNotifier: Loading expenses...');
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await ExpenseService.getExpenses(token: token);

      _calculateStatistics(response.data);

      _setState(_state.copyWith(
        expenses: response.data,
        totalCount: response.count,
        currentPage: 1,
        hasMore: false,
        isLoading: false,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ Expenses loaded: ${response.data.length}');
    } catch (e) {
      debugPrint('❌ Error loading expenses: $e');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load expenses: $e',
      ));
    }
  }

  /// Refresh expenses
  Future<void> refreshExpenses(String token) async {
    debugPrint('🔄 ExpensesNotifier: Refreshing expenses...');
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await ExpenseService.getExpenses(token: token);

      _calculateStatistics(response.data);

      _setState(_state.copyWith(
        expenses: response.data,
        totalCount: response.count,
        isLoading: false,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ Expenses refreshed successfully');
    } catch (e) {
      debugPrint('❌ Error refreshing expenses: $e');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to refresh expenses: $e',
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Submit Expense
  // ─────────────────────────────────────────────────────────────────────────

  /// Submit a new expense
  Future<void> submitExpense({
    required String token,
    required String category,
    required double amount,
    required String currency,
    required DateTime date,
    required String description,
    File? receiptFile,
  }) async {
    debugPrint('📤 ExpensesNotifier: Submitting expense...');
    _setState(_state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      final response = await ExpenseService.submitExpense(
        token: token,
        category: category,
        amount: amount,
        currency: currency,
        date: date,
        description: description,
        receiptFile: receiptFile,
      );

      // Add new expense to list
      final updatedExpenses = [response.data, ..._state.expenses];

      _calculateStatistics(updatedExpenses);

      _setState(_state.copyWith(
        expenses: updatedExpenses,
        totalCount: _state.totalCount + 1,
        isSubmitting: false,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ Expense submitted successfully');
    } catch (e) {
      debugPrint('❌ Error submitting expense: $e');
      _setState(_state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to submit expense: $e',
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Select Expense
  // ─────────────────────────────────────────────────────────────────────────

  /// Select an expense for detailed view
  void selectExpense(Expense expense) {
    debugPrint('👁️ ExpensesNotifier: Selecting expense ${expense.id}');
    _setState(_state.copyWith(selectedExpense: expense));
  }

  /// Deselect current expense
  void deselectExpense() {
    _setState(_state.copyWith(selectedExpense: null));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Filtering & Searching
  // ─────────────────────────────────────────────────────────────────────────

  /// Filter by category
  void filterByCategory(String category) {
    debugPrint('🔍 ExpensesNotifier: Filtering by category: $category');
    _setState(_state.copyWith(selectedCategory: category));
  }

  /// Filter by status
  void filterByStatus(String status) {
    debugPrint('🔍 ExpensesNotifier: Filtering by status: $status');
    _setState(_state.copyWith(selectedStatus: status));
  }

  /// Set amount range filter
  void setAmountFilter(double? min, double? max) {
    debugPrint('🔍 ExpensesNotifier: Setting amount filter: $min - $max');
    _setState(_state.copyWith(
      filterAmountMin: min,
      filterAmountMax: max,
    ));
  }

  /// Set date range filter
  void setDateFilter(DateTime? from, DateTime? to) {
    debugPrint('🔍 ExpensesNotifier: Setting date filter: $from - $to');
    _setState(_state.copyWith(
      filterDateFrom: from,
      filterDateTo: to,
    ));
  }

  /// Clear all filters
  void clearFilters() {
    debugPrint('🔍 ExpensesNotifier: Clearing all filters');
    _setState(_state.copyWith(
      selectedCategory: 'all',
      selectedStatus: 'all',
      filterAmountMin: null,
      filterAmountMax: null,
      filterDateFrom: null,
      filterDateTo: null,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Statistics Calculation
  // ─────────────────────────────────────────────────────────────────────────

  /// Calculate expense statistics
  void _calculateStatistics(List<Expense> expensesList) {
    double totalSubmitted = 0;
    double totalApproved = 0;
    double totalRejected = 0;
    int pending = 0;
    int approved = 0;
    int rejected = 0;

    for (var expense in expensesList) {
      totalSubmitted += expense.amount;

      switch (expense.status) {
        case 'approved':
          totalApproved += expense.amount;
          approved++;
          break;
        case 'rejected':
          totalRejected += expense.amount;
          rejected++;
          break;
        case 'pending':
        default:
          pending++;
      }
    }

    _setState(_state.copyWith(
      totalSubmittedAmount: totalSubmitted,
      totalApprovedAmount: totalApproved,
      totalRejectedAmount: totalRejected,
      pendingExpenseCount: pending,
      approvedExpenseCount: approved,
      rejectedExpenseCount: rejected,
    ));
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
    _setState(const ExpensesState());
  }
}
