import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/features/payroll/data/models/payroll_model.dart';
import 'package:hrms_app/features/payroll/presentation/providers/payroll_notifier.dart';

Payroll _payroll({
  required String id,
  required String status,
  required double netSalary,
  int month = 1,
  int year = 2026,
  String? userName,
}) {
  return Payroll(
    id: id,
    status: status,
    netSalary: netSalary,
    month: month,
    year: year,
    basicSalary: 1000,
    grossSalary: 1200,
    totalDeductions: 200,
    userName: userName,
    allowances: [PayrollItem(name: 'HRA', amount: 100)],
    deductions: [PayrollItem(name: 'Tax', amount: 50)],
  );
}

void main() {
  group('PayrollNotifier', () {
    test('loadMyPayrolls fetches payrolls and computes statistics', () async {
      final data = [
        _payroll(id: 'p1', status: 'paid', netSalary: 1000),
        _payroll(id: 'p2', status: 'pending', netSalary: 2000),
        _payroll(id: 'p3', status: 'generated', netSalary: 3000),
      ];

      final notifier = PayrollNotifier(
        getMyPayrolls: ({required token}) async {
          return PayrollListResponse(success: true, count: data.length, data: data);
        },
      );

      await notifier.loadMyPayrolls('token');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.payrolls.length, 3);
      expect(notifier.state.totalCount, 3);
      expect(notifier.state.totalNetSalaryPaid, 1000);
      expect(notifier.state.totalNetSalaryPending, 5000);
      expect(notifier.state.paidPayrollCount, 1);
      expect(notifier.state.pendingPayrollCount, 1);
      expect(notifier.state.generatedPayrollCount, 1);
    });

    test('filter and search update filteredPayrolls', () async {
      final data = [
        _payroll(
          id: 'p1',
          status: 'paid',
          netSalary: 1000,
          month: 1,
          year: 2026,
          userName: 'Alice',
        ),
        _payroll(
          id: 'p2',
          status: 'pending',
          netSalary: 2000,
          month: 2,
          year: 2026,
          userName: 'Bob',
        ),
      ];

      final notifier = PayrollNotifier(
        getMyPayrolls: ({required token}) async {
          return PayrollListResponse(success: true, count: data.length, data: data);
        },
      );

      await notifier.loadMyPayrolls('token');
      notifier.filterByMonth(1);
      notifier.filterByStatus('paid');
      notifier.searchByName('ali');

      expect(notifier.state.filteredPayrolls.length, 1);
      expect(notifier.state.filteredPayrolls.first.id, 'p1');
    });

    test('generatePayroll prepends payroll and recalculates stats', () async {
      final existing = _payroll(id: 'p1', status: 'paid', netSalary: 1000);
      final generated = _payroll(id: 'p2', status: 'generated', netSalary: 2500);

      final notifier = PayrollNotifier(
        getMyPayrolls: ({required token}) async {
          return PayrollListResponse(success: true, count: 1, data: [existing]);
        },
        generatePayroll: ({required token, required userId, required month, required year}) async {
          return generated;
        },
      );

      await notifier.loadMyPayrolls('token');
      await notifier.generatePayroll(
        token: 'token',
        userId: 'u1',
        month: 1,
        year: 2026,
      );

      expect(notifier.state.payrolls.length, 2);
      expect(notifier.state.payrolls.first.id, 'p2');
      expect(notifier.state.totalNetSalaryPaid, 1000);
      expect(notifier.state.totalNetSalaryPending, 2500);
    });

    test('markPayrollAsPaid updates item and stats', () async {
      final pending = _payroll(id: 'p1', status: 'pending', netSalary: 2000);
      final paid = _payroll(id: 'p1', status: 'paid', netSalary: 2000);

      final notifier = PayrollNotifier(
        getMyPayrolls: ({required token}) async {
          return PayrollListResponse(success: true, count: 1, data: [pending]);
        },
        updatePayroll: ({required token, required id, required data}) async {
          return paid;
        },
      );

      await notifier.loadMyPayrolls('token');
      await notifier.markPayrollAsPaid(token: 'token', payrollId: 'p1');

      expect(notifier.state.payrolls.first.status, 'paid');
      expect(notifier.state.totalNetSalaryPaid, 2000);
      expect(notifier.state.totalNetSalaryPending, 0);
      expect(notifier.state.paidPayrollCount, 1);
      expect(notifier.state.pendingPayrollCount, 0);
    });

    test('deletePayroll removes payroll and updates counts', () async {
      final data = [
        _payroll(id: 'p1', status: 'paid', netSalary: 1000),
        _payroll(id: 'p2', status: 'pending', netSalary: 2000),
      ];

      final notifier = PayrollNotifier(
        getMyPayrolls: ({required token}) async {
          return PayrollListResponse(success: true, count: data.length, data: data);
        },
        deletePayroll: ({required token, required id}) async {
          return true;
        },
      );

      await notifier.loadMyPayrolls('token');
      await notifier.deletePayroll(token: 'token', payrollId: 'p2');

      expect(notifier.state.payrolls.length, 1);
      expect(notifier.state.payrolls.first.id, 'p1');
      expect(notifier.state.totalCount, 1);
    });

    test('loadMyPayrolls sets error message on failure', () async {
      final notifier = PayrollNotifier(
        getMyPayrolls: ({required token}) async {
          throw Exception('network');
        },
      );

      await notifier.loadMyPayrolls('token');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, contains('Failed to load payrolls'));
      expect(notifier.state.errorMessage, contains('network'));
    });

    test('clearFilters resets nullable and string filters', () async {
      final notifier = PayrollNotifier();

      notifier.filterByYear(2026);
      notifier.filterByMonth(4);
      notifier.filterByStatus('paid');
      notifier.searchByName('alice');

      notifier.clearFilters();

      expect(notifier.state.filterYear, isNull);
      expect(notifier.state.filterMonth, isNull);
      expect(notifier.state.selectedStatus, 'all');
      expect(notifier.state.searchQuery, '');
    });

    test('reset restores initial defaults', () async {
      final notifier = PayrollNotifier(
        getMyPayrolls: ({required token}) async {
          final data = [_payroll(id: 'p1', status: 'paid', netSalary: 1000)];
          return PayrollListResponse(success: true, count: data.length, data: data);
        },
      );

      await notifier.loadMyPayrolls('token');
      notifier.reset();

      expect(notifier.state.payrolls, isEmpty);
      expect(notifier.state.totalCount, 0);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.filterYear, isNull);
      expect(notifier.state.filterMonth, isNull);
      expect(notifier.state.selectedStatus, 'all');
      expect(notifier.state.searchQuery, '');
    });
  });
}
