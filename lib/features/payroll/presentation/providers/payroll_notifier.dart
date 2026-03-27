import 'package:flutter/foundation.dart';
import 'package:hrms_app/features/payroll/presentation/providers/payroll_state.dart';
import 'package:hrms_app/features/payroll/data/models/payroll_model.dart';
import 'package:hrms_app/features/payroll/data/services/payroll_service.dart';

/// Payroll Notifier - Manages all payroll state and business logic
class PayrollNotifier extends ChangeNotifier {
  PayrollState _state = const PayrollState();

  final PayrollService _payrollService;

  PayrollNotifier({required PayrollService payrollService})
      : _payrollService = payrollService;

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
      final response = await PayrollService.getMyPayrolls(token: token);

      _calculateStatistics(response.data);

      _setState(_state.copyWith(
        payrolls: response.data,
        totalCount: response.count,
        currentPage: 1,
        hasMore: false,
        isLoading: false,
        lastUpdated: DateTime.now(),
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
      final response = await PayrollService.getAllPayrolls(token: token);

      _calculateStatistics(response.data);

      _setState(_state.copyWith(
        payrolls: response.data,
        totalCount: response.count,
        currentPage: 1,
        hasMore: false,
        isLoading: false,
        lastUpdated: DateTime.now(),
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
      final response = await PayrollService.getMySalary(token: token);

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
      final response = await PayrollService.getSalaries(token: token);

      _setState(_state.copyWith(allSalaries: response.data));

      debugPrint('✅ All salaries loaded: ${response.data.length}');
    } catch (e) {
      debugPrint('❌ Error loading salaries: $e');
      _setState(_state.copyWith(
        errorMessage: 'Failed to load salaries: $e',
      ));
    }
  }

  /// Refresh payroll data
  Future<void> refreshPayrolls(String token) async {
    debugPrint('🔄 PayrollNotifier: Refreshing payrolls...');
    _setState(_state.copyWith(isRefreshing: true, errorMessage: null));

    try {
      // Refresh using the same endpoint (assumes loadMyPayrolls was called first)
      final response = await PayrollService.getMyPayrolls(token: token);

      _calculateStatistics(response.data);

      _setState(_state.copyWith(
        payrolls: response.data,
        totalCount: response.count,
        isRefreshing: false,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ Payrolls refreshed successfully');
    } catch (e) {
      debugPrint('❌ Error refreshing payrolls: $e');
      _setState(_state.copyWith(
        isRefreshing: false,
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
  void _calculateStatistics(List<Payroll> payrollsList) {
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
          .fold(0, (sum, item) => sum + (item.amount ?? 0));
      totalDeductions += payroll.deductions
          .fold(0, (sum, item) => sum + (item.amount ?? 0));

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

    _setState(_state.copyWith(
      totalNetSalaryPaid: totalPaid,
      totalNetSalaryPending: totalPending,
      totalAllowances: totalAllowances,
      totalDeductions: totalDeductions,
      paidPayrollCount: paid,
      pendingPayrollCount: pending,
      generatedPayrollCount: generated,
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
    _setState(const PayrollState());
  }
}
