import 'package:flutter/foundation.dart';
import 'package:hrms_app/features/payroll/presentation/providers/payroll_state.dart';
import 'package:hrms_app/features/payroll/data/models/payroll_model.dart';
import 'package:hrms_app/features/payroll/data/services/payroll_service.dart';

typedef _GetPayrollListFn = Future<PayrollListResponse> Function({
  required String token,
});
typedef _GetSalaryFn = Future<SalaryResponse> Function({
  required String token,
});
typedef _GetSalariesFn = Future<SalaryListResponse> Function({
  required String token,
});
typedef _CreateSalaryFn = Future<EmployeeSalary> Function({
  required String token,
  required Map<String, dynamic> data,
});
typedef _UpdateSalaryFn = Future<EmployeeSalary> Function({
  required String token,
  required String id,
  required Map<String, dynamic> data,
});
typedef _DeleteSalaryFn = Future<bool> Function({
  required String token,
  required String id,
});
typedef _GetPrePaymentsFn = Future<PrePaymentListResponse> Function({
  required String token,
});
typedef _GetIncrementsFn = Future<IncrementListResponse> Function({
  required String token,
});
typedef _CreatePrePaymentFn = Future<PrePayment> Function({
  required String token,
  required Map<String, dynamic> data,
});
typedef _UpdatePrePaymentFn = Future<PrePayment> Function({
  required String token,
  required String id,
  required Map<String, dynamic> data,
});
typedef _DeletePrePaymentFn = Future<bool> Function({
  required String token,
  required String id,
});
typedef _GeneratePayrollFn = Future<Payroll> Function({
  required String token,
  required String userId,
  required int month,
  required int year,
});
typedef _UpdatePayrollFn = Future<Payroll> Function({
  required String token,
  required String id,
  required Map<String, dynamic> data,
});
typedef _DeletePayrollFn = Future<bool> Function({
  required String token,
  required String id,
});

/// Payroll Notifier - Manages all payroll state and business logic
class PayrollNotifier extends ChangeNotifier {
  PayrollState _state = const PayrollState();

  final _GetPayrollListFn _getMyPayrolls;
  final _GetPayrollListFn _getAllPayrolls;
  final _GetSalaryFn _getMySalary;
  final _GetSalariesFn _getSalaries;
  final _CreateSalaryFn _createSalary;
  final _UpdateSalaryFn _updateSalaryRecord;
  final _DeleteSalaryFn _deleteSalaryRecord;
  final _GetPrePaymentsFn _getPrePayments;
  final _GetIncrementsFn _getIncrements;
  final _CreatePrePaymentFn _createPrePayment;
  final _UpdatePrePaymentFn _updatePrePayment;
  final _DeletePrePaymentFn _deletePrePayment;
  final _GeneratePayrollFn _generatePayroll;
  final _UpdatePayrollFn _updatePayroll;
  final _DeletePayrollFn _deletePayroll;

  PayrollNotifier({
    _GetPayrollListFn? getMyPayrolls,
    _GetPayrollListFn? getAllPayrolls,
    _GetSalaryFn? getMySalary,
    _GetSalariesFn? getSalaries,
    _CreateSalaryFn? createSalary,
    _UpdateSalaryFn? updateSalaryRecord,
    _DeleteSalaryFn? deleteSalaryRecord,
    _GetPrePaymentsFn? getPrePayments,
    _GetIncrementsFn? getIncrements,
    _CreatePrePaymentFn? createPrePayment,
    _UpdatePrePaymentFn? updatePrePayment,
    _DeletePrePaymentFn? deletePrePayment,
    _GeneratePayrollFn? generatePayroll,
    _UpdatePayrollFn? updatePayroll,
    _DeletePayrollFn? deletePayroll,
  })  : _getMyPayrolls = getMyPayrolls ?? PayrollService.getMyPayrolls,
        _getAllPayrolls = getAllPayrolls ?? PayrollService.getAllPayrolls,
        _getMySalary = getMySalary ?? PayrollService.getMySalary,
        _getSalaries = getSalaries ?? PayrollService.getSalaries,
      _createSalary = createSalary ?? PayrollService.createSalary,
      _updateSalaryRecord = updateSalaryRecord ?? PayrollService.updateSalary,
      _deleteSalaryRecord = deleteSalaryRecord ?? PayrollService.deleteSalary,
      _getPrePayments = getPrePayments ?? PayrollService.getPrePayments,
      _getIncrements = getIncrements ?? PayrollService.getIncrements,
      _createPrePayment = createPrePayment ?? PayrollService.createPrePayment,
      _updatePrePayment = updatePrePayment ?? PayrollService.updatePrePayment,
      _deletePrePayment = deletePrePayment ?? PayrollService.deletePrePayment,
        _generatePayroll = generatePayroll ?? PayrollService.generatePayroll,
        _updatePayroll = updatePayroll ?? PayrollService.updatePayroll,
        _deletePayroll = deletePayroll ?? PayrollService.deletePayroll;

  PayrollState get state => _state;

  void _setState(PayrollState newState) {
    _state = newState;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Load Payroll Data
  // ─────────────────────────────────────────────────────────────────────────

  /// Load all payrolls for current user
  Future<void> loadMyPayrolls(String token) async {
    debugPrint('💰 PayrollNotifier: Loading my payrolls...');
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await _getMyPayrolls(token: token);
      final stats = _calculateStatistics(response.data);

      _setState(_state.copyWith(
        payrolls: response.data,
        totalCount: response.count,
        currentPage: 1,
        hasMore: false,
        isLoading: false,
        lastUpdated: DateTime.now(),
        totalNetSalaryPaid: stats.totalPaid,
        totalNetSalaryPending: stats.totalPending,
        totalAllowances: stats.totalAllowances,
        totalDeductions: stats.totalDeductions,
        paidPayrollCount: stats.paid,
        pendingPayrollCount: stats.pending,
        generatedPayrollCount: stats.generated,
      ));

      debugPrint('✅ Payrolls loaded: ${response.data.length}');
    } catch (e) {
      debugPrint('❌ Error loading payrolls: $e');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load payrolls: $e',
      ));
    }
  }

  /// Load all payrolls (HR/Admin only)
  Future<void> loadAllPayrolls(String token) async {
    debugPrint('💰 PayrollNotifier: Loading all payrolls...');
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await _getAllPayrolls(token: token);
      final stats = _calculateStatistics(response.data);

      _setState(_state.copyWith(
        payrolls: response.data,
        totalCount: response.count,
        currentPage: 1,
        hasMore: false,
        isLoading: false,
        lastUpdated: DateTime.now(),
        totalNetSalaryPaid: stats.totalPaid,
        totalNetSalaryPending: stats.totalPending,
        totalAllowances: stats.totalAllowances,
        totalDeductions: stats.totalDeductions,
        paidPayrollCount: stats.paid,
        pendingPayrollCount: stats.pending,
        generatedPayrollCount: stats.generated,
      ));

      debugPrint('✅ All payrolls loaded: ${response.data.length}');
    } catch (e) {
      debugPrint('❌ Error loading all payrolls: $e');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load payrolls: $e',
      ));
    }
  }

  /// Get my salary details
  Future<void> loadMySalary(String token) async {
    debugPrint('💰 PayrollNotifier: Loading my salary...');

    try {
      final response = await _getMySalary(token: token);

      _setState(_state.copyWith(mySalary: response.data));

      debugPrint('✅ Salary loaded');
    } catch (e) {
      debugPrint('❌ Error loading salary: $e');
      _setState(_state.copyWith(
        errorMessage: 'Failed to load salary: $e',
      ));
    }
  }

  /// Load all employee salaries (HR/Admin only)
  Future<void> loadAllSalaries(String token) async {
    debugPrint('💰 PayrollNotifier: Loading all salaries...');

    try {
      final response = await _getSalaries(token: token);

      _setState(_state.copyWith(allSalaries: response.data));

      debugPrint('✅ All salaries loaded: ${response.data.length}');
    } catch (e) {
      debugPrint('❌ Error loading salaries: $e');
      _setState(_state.copyWith(
        errorMessage: 'Failed to load salaries: $e',
      ));
    }
  }

  Future<void> createSalary({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _createSalary(token: token, data: data);
      await loadAllSalaries(token);
      _setState(_state.copyWith(isLoading: false));
    } catch (e) {
      _setState(_state.copyWith(isLoading: false, errorMessage: 'Failed to create salary: $e'));
      rethrow;
    }
  }

  Future<void> updateSalary({
    required String token,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _updateSalaryRecord(token: token, id: id, data: data);
      await loadAllSalaries(token);
      _setState(_state.copyWith(isLoading: false));
    } catch (e) {
      _setState(_state.copyWith(isLoading: false, errorMessage: 'Failed to update salary: $e'));
      rethrow;
    }
  }

  Future<void> deleteSalary({
    required String token,
    required String id,
  }) async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _deleteSalaryRecord(token: token, id: id);
      final current = _state.allSalaries ?? const <EmployeeSalary>[];
      final updated = current.where((s) => s.id != id).toList();
      _setState(_state.copyWith(allSalaries: updated, isLoading: false));
    } catch (e) {
      _setState(_state.copyWith(isLoading: false, errorMessage: 'Failed to delete salary: $e'));
      rethrow;
    }
  }

  Future<void> loadPrePayments(String token) async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      final response = await _getPrePayments(token: token);
      _setState(_state.copyWith(prePayments: response.data, isLoading: false, lastUpdated: DateTime.now()));
    } catch (e) {
      _setState(_state.copyWith(isLoading: false, errorMessage: 'Failed to load pre-payments: $e'));
    }
  }

  Future<void> loadIncrements(String token) async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      final response = await _getIncrements(token: token);
      _setState(_state.copyWith(increments: response.data, isLoading: false, lastUpdated: DateTime.now()));
    } catch (e) {
      _setState(_state.copyWith(isLoading: false, errorMessage: 'Failed to load increments: $e'));
    }
  }

  Future<void> createPrePayment({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      final created = await _createPrePayment(token: token, data: data);
      _setState(_state.copyWith(prePayments: [created, ..._state.prePayments], isLoading: false, lastUpdated: DateTime.now()));
    } catch (e) {
      _setState(_state.copyWith(isLoading: false, errorMessage: 'Failed to create pre-payment: $e'));
      rethrow;
    }
  }

  Future<void> updatePrePayment({
    required String token,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      final updatedItem = await _updatePrePayment(token: token, id: id, data: data);
      final updated = _state.prePayments.map((p) => p.id == id ? updatedItem : p).toList();
      _setState(_state.copyWith(prePayments: updated, isLoading: false, lastUpdated: DateTime.now()));
    } catch (e) {
      _setState(_state.copyWith(isLoading: false, errorMessage: 'Failed to update pre-payment: $e'));
      rethrow;
    }
  }

  Future<void> deletePrePayment({
    required String token,
    required String id,
  }) async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _deletePrePayment(token: token, id: id);
      final updated = _state.prePayments.where((p) => p.id != id).toList();
      _setState(_state.copyWith(prePayments: updated, isLoading: false, lastUpdated: DateTime.now()));
    } catch (e) {
      _setState(_state.copyWith(isLoading: false, errorMessage: 'Failed to delete pre-payment: $e'));
      rethrow;
    }
  }

  /// Refresh payroll data
  Future<void> refreshPayrolls(String token) async {
    debugPrint('🔄 PayrollNotifier: Refreshing payrolls...');
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      // Refresh using the same endpoint (assumes loadMyPayrolls was called first)
      final response = await _getMyPayrolls(token: token);
      final stats = _calculateStatistics(response.data);

      _setState(_state.copyWith(
        payrolls: response.data,
        totalCount: response.count,
        isLoading: false,
        lastUpdated: DateTime.now(),
        totalNetSalaryPaid: stats.totalPaid,
        totalNetSalaryPending: stats.totalPending,
        totalAllowances: stats.totalAllowances,
        totalDeductions: stats.totalDeductions,
        paidPayrollCount: stats.paid,
        pendingPayrollCount: stats.pending,
        generatedPayrollCount: stats.generated,
      ));

      debugPrint('✅ Payrolls refreshed successfully');
    } catch (e) {
      debugPrint('❌ Error refreshing payrolls: $e');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to refresh payrolls: $e',
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Select Payroll
  // ─────────────────────────────────────────────────────────────────────────

  /// Select a payroll for detailed view
  void selectPayroll(Payroll payroll) {
    debugPrint('👁️ PayrollNotifier: Selecting payroll ${payroll.id}');
    _setState(_state.copyWith(selectedPayroll: payroll));
  }

  /// Deselect current payroll
  void deselectPayroll() {
    _setState(_state.copyWith(selectedPayroll: null));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Filtering & Searching
  // ─────────────────────────────────────────────────────────────────────────

  /// Filter by year
  void filterByYear(int? year) {
    debugPrint('🔍 PayrollNotifier: Filtering by year: $year');
    _setState(_state.copyWith(filterYear: year));
  }

  /// Filter by month
  void filterByMonth(int? month) {
    debugPrint('🔍 PayrollNotifier: Filtering by month: $month');
    _setState(_state.copyWith(filterMonth: month));
  }

  /// Filter by status
  void filterByStatus(String status) {
    debugPrint('🔍 PayrollNotifier: Filtering by status: $status');
    _setState(_state.copyWith(selectedStatus: status));
  }

  /// Search by employee name
  void searchByName(String query) {
    debugPrint('🔍 PayrollNotifier: Searching: $query');
    _setState(_state.copyWith(searchQuery: query));
  }

  /// Clear all filters
  void clearFilters() {
    debugPrint('🔍 PayrollNotifier: Clearing all filters');
    _setState(_state.copyWith(
      filterYear: null,
      filterMonth: null,
      selectedStatus: 'all',
      searchQuery: '',
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Statistics Calculation
  // ─────────────────────────────────────────────────────────────────────────

  /// Calculate payroll statistics
  _PayrollStats _calculateStatistics(List<Payroll> payrollsList) {
    double totalPaid = 0;
    double totalPending = 0;
    double totalAllowances = 0;
    double totalDeductions = 0;
    int paid = 0;
    int pending = 0;
    int generated = 0;

    for (var payroll in payrollsList) {
      // Sum allowances and deductions
        totalAllowances += payroll.allowances
          .fold<double>(0.0, (sum, item) => sum + item.amount);
        totalDeductions += payroll.deductions
          .fold<double>(0.0, (sum, item) => sum + item.amount);

      switch (payroll.status) {
        case 'paid':
          totalPaid += payroll.netSalary;
          paid++;
          break;
        case 'pending':
          totalPending += payroll.netSalary;
          pending++;
          break;
        case 'generated':
        default:
          totalPending += payroll.netSalary;
          generated++;
      }
    }

    return _PayrollStats(
      totalPaid: totalPaid,
      totalPending: totalPending,
      totalAllowances: totalAllowances,
      totalDeductions: totalDeductions,
      paid: paid,
      pending: pending,
      generated: generated,
    );
  }

  Future<Payroll> generatePayroll({
    required String token,
    required String userId,
    required int month,
    required int year,
  }) async {
    debugPrint('🧾 PayrollNotifier: Generating payroll for $userId');
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final payroll = await _generatePayroll(
        token: token,
        userId: userId,
        month: month,
        year: year,
      );

      final updatedPayrolls = [payroll, ..._state.payrolls];
      final stats = _calculateStatistics(updatedPayrolls);
      _setState(
        _state.copyWith(
          payrolls: updatedPayrolls,
          totalCount: updatedPayrolls.length,
          isLoading: false,
          lastUpdated: DateTime.now(),
          totalNetSalaryPaid: stats.totalPaid,
          totalNetSalaryPending: stats.totalPending,
          totalAllowances: stats.totalAllowances,
          totalDeductions: stats.totalDeductions,
          paidPayrollCount: stats.paid,
          pendingPayrollCount: stats.pending,
          generatedPayrollCount: stats.generated,
        ),
      );

      return payroll;
    } catch (e) {
      _setState(
        _state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to generate payroll: $e',
        ),
      );
      rethrow;
    }
  }

  Future<void> markPayrollAsPaid({
    required String token,
    required String payrollId,
  }) async {
    debugPrint('💵 PayrollNotifier: Marking payroll as paid: $payrollId');

    try {
      final updated = await _updatePayroll(
        token: token,
        id: payrollId,
        data: {
          'status': 'paid',
          'paymentDate': DateTime.now().toIso8601String(),
        },
      );

      final updatedPayrolls = _state.payrolls
          .map((p) => p.id == payrollId ? updated : p)
          .toList();
      final stats = _calculateStatistics(updatedPayrolls);
      _setState(
        _state.copyWith(
          payrolls: updatedPayrolls,
          lastUpdated: DateTime.now(),
          totalNetSalaryPaid: stats.totalPaid,
          totalNetSalaryPending: stats.totalPending,
          totalAllowances: stats.totalAllowances,
          totalDeductions: stats.totalDeductions,
          paidPayrollCount: stats.paid,
          pendingPayrollCount: stats.pending,
          generatedPayrollCount: stats.generated,
        ),
      );
    } catch (e) {
      _setState(_state.copyWith(errorMessage: 'Failed to update payroll: $e'));
      rethrow;
    }
  }

  Future<void> deletePayroll({
    required String token,
    required String payrollId,
  }) async {
    debugPrint('🗑️ PayrollNotifier: Deleting payroll: $payrollId');

    try {
      await _deletePayroll(token: token, id: payrollId);
      final updatedPayrolls = _state.payrolls
          .where((p) => p.id != payrollId)
          .toList();
      final stats = _calculateStatistics(updatedPayrolls);
      _setState(
        _state.copyWith(
          payrolls: updatedPayrolls,
          totalCount: updatedPayrolls.length,
          lastUpdated: DateTime.now(),
          totalNetSalaryPaid: stats.totalPaid,
          totalNetSalaryPending: stats.totalPending,
          totalAllowances: stats.totalAllowances,
          totalDeductions: stats.totalDeductions,
          paidPayrollCount: stats.paid,
          pendingPayrollCount: stats.pending,
          generatedPayrollCount: stats.generated,
        ),
      );
    } catch (e) {
      _setState(_state.copyWith(errorMessage: 'Failed to delete payroll: $e'));
      rethrow;
    }
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
    _setState(const PayrollState());
  }
}

class _PayrollStats {
  final double totalPaid;
  final double totalPending;
  final double totalAllowances;
  final double totalDeductions;
  final int paid;
  final int pending;
  final int generated;

  const _PayrollStats({
    required this.totalPaid,
    required this.totalPending,
    required this.totalAllowances,
    required this.totalDeductions,
    required this.paid,
    required this.pending,
    required this.generated,
  });
}
