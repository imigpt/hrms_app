import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hrms_app/features/expenses/presentation/providers/expenses_state.dart';
import 'package:hrms_app/features/expenses/data/models/expense_model.dart';
import 'package:hrms_app/features/expenses/data/services/expense_service.dart';

typedef _GetExpensesFn = Future<ExpenseListResponse> Function({
  required String token,
});
typedef _SubmitExpenseFn = Future<ExpenseSubmitResponse> Function({
  required String token,
  required String category,
  required double amount,
  required String currency,
  required DateTime date,
  required String description,
  File? receiptFile,
});
typedef _UpdateExpenseFn = Future<ExpenseSubmitResponse> Function({
  required String token,
  required String expenseId,
  required String category,
  required double amount,
  required String currency,
  required DateTime date,
  required String description,
  File? receiptFile,
});
typedef _DeleteExpenseFn = Future<void> Function({
  required String token,
  required String expenseId,
});

/// Expenses Notifier - Manages all expenses state and business logic
class ExpensesNotifier extends ChangeNotifier {
  ExpensesState _state = const ExpensesState();

  final _GetExpensesFn _getExpenses;
  final _SubmitExpenseFn _submitExpense;
  final _UpdateExpenseFn _updateExpense;
  final _DeleteExpenseFn _deleteExpense;

  ExpensesNotifier({
    _GetExpensesFn? getExpenses,
    _SubmitExpenseFn? submitExpense,
    _UpdateExpenseFn? updateExpense,
    _DeleteExpenseFn? deleteExpense,
  })  : _getExpenses = getExpenses ?? ExpenseService.getExpenses,
        _submitExpense = submitExpense ?? ExpenseService.submitExpense,
        _updateExpense = updateExpense ?? ExpenseService.updateExpense,
        _deleteExpense = deleteExpense ?? ExpenseService.deleteExpense;

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
      final response = await _getExpenses(token: token);

      _setState(
        _state
            .copyWith(
              expenses: response.data,
              totalCount: response.count,
              currentPage: 1,
              hasMore: false,
              isLoading: false,
              lastUpdated: DateTime.now(),
            )
            .copyWith(
              totalSubmittedAmount: _stats(response.data).totalSubmitted,
              totalApprovedAmount: _stats(response.data).totalApproved,
              totalRejectedAmount: _stats(response.data).totalRejected,
              pendingExpenseCount: _stats(response.data).pending,
              approvedExpenseCount: _stats(response.data).approved,
              rejectedExpenseCount: _stats(response.data).rejected,
            ),
      );

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
      final response = await _getExpenses(token: token);

      _setState(
        _state
            .copyWith(
              expenses: response.data,
              totalCount: response.count,
              isLoading: false,
              lastUpdated: DateTime.now(),
            )
            .copyWith(
              totalSubmittedAmount: _stats(response.data).totalSubmitted,
              totalApprovedAmount: _stats(response.data).totalApproved,
              totalRejectedAmount: _stats(response.data).totalRejected,
              pendingExpenseCount: _stats(response.data).pending,
              approvedExpenseCount: _stats(response.data).approved,
              rejectedExpenseCount: _stats(response.data).rejected,
            ),
      );

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
      final response = await _submitExpense(
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

      _setState(
        _state
            .copyWith(
              expenses: updatedExpenses,
              totalCount: _state.totalCount + 1,
              isSubmitting: false,
              lastUpdated: DateTime.now(),
            )
            .copyWith(
              totalSubmittedAmount: _stats(updatedExpenses).totalSubmitted,
              totalApprovedAmount: _stats(updatedExpenses).totalApproved,
              totalRejectedAmount: _stats(updatedExpenses).totalRejected,
              pendingExpenseCount: _stats(updatedExpenses).pending,
              approvedExpenseCount: _stats(updatedExpenses).approved,
              rejectedExpenseCount: _stats(updatedExpenses).rejected,
            ),
      );

      debugPrint('✅ Expense submitted successfully');
    } catch (e) {
      debugPrint('❌ Error submitting expense: $e');
      _setState(_state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to submit expense: $e',
      ));
    }
  }

  /// Update an existing expense and sync local state.
  Future<void> updateExpense({
    required String token,
    required String expenseId,
    required String category,
    required double amount,
    required String currency,
    required DateTime date,
    required String description,
    File? receiptFile,
  }) async {
    debugPrint('✏️ ExpensesNotifier: Updating expense $expenseId');
    _setState(_state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      final response = await _updateExpense(
        token: token,
        expenseId: expenseId,
        category: category,
        amount: amount,
        currency: currency,
        date: date,
        description: description,
        receiptFile: receiptFile,
      );

      final updatedExpenses = _state.expenses
          .map((e) => e.id == expenseId ? response.data : e)
          .toList();

      final stats = _stats(updatedExpenses);
      _setState(
        _state.copyWith(
          expenses: updatedExpenses,
          isSubmitting: false,
          lastUpdated: DateTime.now(),
          totalSubmittedAmount: stats.totalSubmitted,
          totalApprovedAmount: stats.totalApproved,
          totalRejectedAmount: stats.totalRejected,
          pendingExpenseCount: stats.pending,
          approvedExpenseCount: stats.approved,
          rejectedExpenseCount: stats.rejected,
        ),
      );

      debugPrint('✅ Expense updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating expense: $e');
      _setState(
        _state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to update expense: $e',
        ),
      );
      rethrow;
    }
  }

  /// Delete an existing expense and sync local state.
  Future<void> deleteExpense({
    required String token,
    required String expenseId,
  }) async {
    debugPrint('🗑️ ExpensesNotifier: Deleting expense $expenseId');
    _setState(_state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      await _deleteExpense(token: token, expenseId: expenseId);

      final updatedExpenses = _state.expenses
          .where((e) => e.id != expenseId)
          .toList();

      final stats = _stats(updatedExpenses);
      _setState(
        _state.copyWith(
          expenses: updatedExpenses,
          totalCount: updatedExpenses.length,
          isSubmitting: false,
          lastUpdated: DateTime.now(),
          totalSubmittedAmount: stats.totalSubmitted,
          totalApprovedAmount: stats.totalApproved,
          totalRejectedAmount: stats.totalRejected,
          pendingExpenseCount: stats.pending,
          approvedExpenseCount: stats.approved,
          rejectedExpenseCount: stats.rejected,
        ),
      );

      debugPrint('✅ Expense deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting expense: $e');
      _setState(
        _state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to delete expense: $e',
        ),
      );
      rethrow;
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
  _ExpenseStats _stats(List<Expense> expensesList) {
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

    return _ExpenseStats(
      totalSubmitted: totalSubmitted,
      totalApproved: totalApproved,
      totalRejected: totalRejected,
      pending: pending,
      approved: approved,
      rejected: rejected,
    );
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

class _ExpenseStats {
  final double totalSubmitted;
  final double totalApproved;
  final double totalRejected;
  final int pending;
  final int approved;
  final int rejected;

  const _ExpenseStats({
    required this.totalSubmitted,
    required this.totalApproved,
    required this.totalRejected,
    required this.pending,
    required this.approved,
    required this.rejected,
  });
}
