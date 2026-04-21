import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/features/expenses/data/models/expense_model.dart';
import 'package:hrms_app/features/expenses/data/services/expense_service.dart';
import 'package:hrms_app/features/expenses/presentation/providers/expenses_notifier.dart';

Expense _expense({
  required String id,
  required String status,
  double amount = 100,
  String category = 'travel',
  String description = 'desc',
}) {
  return Expense(
    id: id,
    category: category,
    amount: amount,
    currency: 'INR',
    date: DateTime(2024, 1, 10),
    description: description,
    status: status,
    isLocked: false,
    createdAt: DateTime(2024, 1, 10),
    updatedAt: DateTime(2024, 1, 10),
  );
}

void main() {
  group('ExpensesNotifier', () {
    test('loadExpenses fetches expenses and computes statistics', () async {
      final items = [
        _expense(id: 'e1', status: 'pending', amount: 100),
        _expense(id: 'e2', status: 'approved', amount: 50),
        _expense(id: 'e3', status: 'rejected', amount: 25),
      ];

      final notifier = ExpensesNotifier(
        expenseService: ExpenseService(),
        getExpenses: ({required String token}) async => ExpenseListResponse(
          success: true,
          count: items.length,
          data: items,
        ),
      );

      await notifier.loadExpenses('token');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.totalCount, 3);
      expect(notifier.state.pendingExpenseCount, 1);
      expect(notifier.state.approvedExpenseCount, 1);
      expect(notifier.state.rejectedExpenseCount, 1);
      expect(notifier.state.totalSubmittedAmount, 175);
      expect(notifier.state.totalApprovedAmount, 50);
      expect(notifier.state.totalRejectedAmount, 25);
    });

    test('filterByStatus updates filteredExpenses', () async {
      final items = [
        _expense(id: 'e1', status: 'pending'),
        _expense(id: 'e2', status: 'approved'),
        _expense(id: 'e3', status: 'approved'),
      ];

      final notifier = ExpensesNotifier(
        expenseService: ExpenseService(),
        getExpenses: ({required String token}) async => ExpenseListResponse(
          success: true,
          count: items.length,
          data: items,
        ),
      );

      await notifier.loadExpenses('token');
      notifier.filterByStatus('approved');

      expect(notifier.state.selectedStatus, 'approved');
      expect(notifier.state.filteredExpenses.length, 2);
    });

    test('submitExpense prepends item and updates stats', () async {
      final created = _expense(id: 'new', status: 'pending', amount: 200);

      final notifier = ExpensesNotifier(
        expenseService: ExpenseService(),
        getExpenses: ({required String token}) async => ExpenseListResponse(
          success: true,
          count: 0,
          data: const [],
        ),
        submitExpense: ({
          required String token,
          required String category,
          required double amount,
          required String currency,
          required DateTime date,
          required String description,
          receiptFile,
        }) async => ExpenseSubmitResponse(
          success: true,
          message: 'ok',
          data: created,
        ),
      );

      await notifier.loadExpenses('token');
      await notifier.submitExpense(
        token: 'token',
        category: 'travel',
        amount: 200,
        currency: 'INR',
        date: DateTime(2024, 1, 10),
        description: 'Train',
      );

      expect(notifier.state.expenses.first.id, 'new');
      expect(notifier.state.totalCount, 1);
      expect(notifier.state.totalSubmittedAmount, 200);
    });

    test('updateExpense replaces matching item', () async {
      final initial = _expense(
        id: 'e1',
        status: 'pending',
        amount: 100,
        description: 'old',
      );
      final updated = _expense(
        id: 'e1',
        status: 'pending',
        amount: 150,
        description: 'new',
      );

      final notifier = ExpensesNotifier(
        expenseService: ExpenseService(),
        getExpenses: ({required String token}) async => ExpenseListResponse(
          success: true,
          count: 1,
          data: [initial],
        ),
        updateExpense: ({
          required String token,
          required String expenseId,
          required String category,
          required double amount,
          required String currency,
          required DateTime date,
          required String description,
          receiptFile,
        }) async => ExpenseSubmitResponse(
          success: true,
          message: 'updated',
          data: updated,
        ),
      );

      await notifier.loadExpenses('token');
      await notifier.updateExpense(
        token: 'token',
        expenseId: 'e1',
        category: 'travel',
        amount: 150,
        currency: 'INR',
        date: DateTime(2024, 1, 10),
        description: 'new',
      );

      expect(notifier.state.expenses.length, 1);
      expect(notifier.state.expenses.first.description, 'new');
      expect(notifier.state.totalSubmittedAmount, 150);
    });

    test('deleteExpense removes item and recalculates', () async {
      final items = [
        _expense(id: 'e1', status: 'pending', amount: 100),
        _expense(id: 'e2', status: 'approved', amount: 50),
      ];

      final notifier = ExpensesNotifier(
        expenseService: ExpenseService(),
        getExpenses: ({required String token}) async => ExpenseListResponse(
          success: true,
          count: 2,
          data: items,
        ),
        deleteExpense: ({required String token, required String expenseId}) async {},
      );

      await notifier.loadExpenses('token');
      await notifier.deleteExpense(token: 'token', expenseId: 'e2');

      expect(notifier.state.expenses.length, 1);
      expect(notifier.state.expenses.first.id, 'e1');
      expect(notifier.state.totalApprovedAmount, 0);
      expect(notifier.state.totalSubmittedAmount, 100);
    });

    test('clearFilters resets all filter fields', () async {
      final notifier = ExpensesNotifier(
        expenseService: ExpenseService(),
        getExpenses: ({required String token}) async => ExpenseListResponse(
          success: true,
          count: 1,
          data: [_expense(id: 'e1', status: 'pending')],
        ),
      );

      await notifier.loadExpenses('token');
      notifier.filterByStatus('pending');
      notifier.filterByCategory('travel');
      notifier.setAmountFilter(10, 1000);
      notifier.setDateFilter(DateTime(2024, 1, 1), DateTime(2024, 1, 31));

      notifier.clearFilters();

      expect(notifier.state.selectedStatus, 'all');
      expect(notifier.state.selectedCategory, 'all');
      expect(notifier.state.filterAmountMin, null);
      expect(notifier.state.filterAmountMax, null);
      expect(notifier.state.filterDateFrom, null);
      expect(notifier.state.filterDateTo, null);
    });

    test('loadExpenses sets error message on failure', () async {
      final notifier = ExpensesNotifier(
        expenseService: ExpenseService(),
        getExpenses: ({required String token}) async {
          throw Exception('network');
        },
      );

      await notifier.loadExpenses('token');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, contains('Failed to load expenses'));
    });

    test('reset restores initial defaults', () async {
      final notifier = ExpensesNotifier(
        expenseService: ExpenseService(),
        getExpenses: ({required String token}) async => ExpenseListResponse(
          success: true,
          count: 1,
          data: [_expense(id: 'e1', status: 'pending')],
        ),
      );

      await notifier.loadExpenses('token');
      notifier.filterByStatus('pending');
      notifier.reset();

      expect(notifier.state.expenses, isEmpty);
      expect(notifier.state.selectedStatus, 'all');
      expect(notifier.state.totalSubmittedAmount, 0);
      expect(notifier.state.errorMessage, null);
    });
  });
}
