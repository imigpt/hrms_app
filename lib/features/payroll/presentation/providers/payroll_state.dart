import 'package:equatable/equatable.dart';
import 'package:hrms_app/features/payroll/data/models/payroll_model.dart';

/// Immutable Payroll State using Equatable for proper comparison
class PayrollState extends Equatable {
  final List<Payroll> payrolls;
  final Payroll? selectedPayroll;
  final EmployeeSalary? mySalary;
  final List<EmployeeSalary>? allSalaries;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final DateTime? lastUpdated;
  final int currentPage;
  final int totalCount;
  final bool hasMore;
  
  /// Filter & Search
  final int? filterYear;
  final int? filterMonth;
  final String selectedStatus; // 'all', 'generated', 'paid', 'pending'
  final String searchQuery;

  /// Statistics
  final double totalNetSalaryPaid;    // Sum of paid salary
  final double totalNetSalaryPending; // Sum of pending/generated
  final double totalAllowances;
  final double totalDeductions;
  final int paidPayrollCount;
  final int pendingPayrollCount;
  final int generatedPayrollCount;

  const PayrollState({
    this.payrolls = const [],
    this.selectedPayroll,
    this.mySalary,
    this.allSalaries,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.lastUpdated,
    this.currentPage = 1,
    this.totalCount = 0,
    this.hasMore = false,
    this.filterYear,
    this.filterMonth,
    this.selectedStatus = 'all',
    this.searchQuery = '',
    this.totalNetSalaryPaid = 0.0,
    this.totalNetSalaryPending = 0.0,
    this.totalAllowances = 0.0,
    this.totalDeductions = 0.0,
    this.paidPayrollCount = 0,
    this.pendingPayrollCount = 0,
    this.generatedPayrollCount = 0,
  });

  /// Create a copy of this state with optional property overrides
  PayrollState copyWith({
    List<Payroll>? payrolls,
    Payroll? selectedPayroll,
    EmployeeSalary? mySalary,
    List<EmployeeSalary>? allSalaries,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    DateTime? lastUpdated,
    int? currentPage,
    int? totalCount,
    bool? hasMore,
    int? filterYear,
    int? filterMonth,
    String? selectedStatus,
    String? searchQuery,
    double? totalNetSalaryPaid,
    double? totalNetSalaryPending,
    double? totalAllowances,
    double? totalDeductions,
    int? paidPayrollCount,
    int? pendingPayrollCount,
    int? generatedPayrollCount,
  }) {
    return PayrollState(
      payrolls: payrolls ?? this.payrolls,
      selectedPayroll: selectedPayroll ?? this.selectedPayroll,
      mySalary: mySalary ?? this.mySalary,
      allSalaries: allSalaries ?? this.allSalaries,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      filterYear: filterYear ?? this.filterYear,
      filterMonth: filterMonth ?? this.filterMonth,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      totalNetSalaryPaid: totalNetSalaryPaid ?? this.totalNetSalaryPaid,
      totalNetSalaryPending: totalNetSalaryPending ?? this.totalNetSalaryPending,
      totalAllowances: totalAllowances ?? this.totalAllowances,
      totalDeductions: totalDeductions ?? this.totalDeductions,
      paidPayrollCount: paidPayrollCount ?? this.paidPayrollCount,
      pendingPayrollCount: pendingPayrollCount ?? this.pendingPayrollCount,
      generatedPayrollCount: generatedPayrollCount ?? this.generatedPayrollCount,
    );
  }

  /// Filtered payrolls based on current filters
  List<Payroll> get filteredPayrolls {
    return payrolls.where((payroll) {
      // Filter by year
      if (filterYear != null && payroll.year != filterYear) {
        return false;
      }

      // Filter by month
      if (filterMonth != null && payroll.month != filterMonth) {
        return false;
      }

      // Filter by status
      if (selectedStatus != 'all' && payroll.status != selectedStatus) {
        return false;
      }

      // Filter by search query (employee name)
      if (searchQuery.isNotEmpty && 
          !(payroll.userName?.toLowerCase() ?? '').contains(searchQuery.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Latest salary stub (most recent payroll)
  Payroll? get latestPayroll {
    if (payrolls.isEmpty) return null;
    return payrolls.reduce((a, b) {
      final aDate =
          DateTime(a.year, a.month);
      final bDate = DateTime(b.year, b.month);
      return bDate.isAfter(aDate) ? b : a;
    });
  }

  @override
  List<Object?> get props => [
    payrolls,
    selectedPayroll,
    mySalary,
    allSalaries,
    isLoading,
    isLoadingMore,
    errorMessage,
    lastUpdated,
    currentPage,
    totalCount,
    hasMore,
    filterYear,
    filterMonth,
    selectedStatus,
    searchQuery,
    totalNetSalaryPaid,
    totalNetSalaryPending,
    totalAllowances,
    totalDeductions,
    paidPayrollCount,
    pendingPayrollCount,
    generatedPayrollCount,
  ];
}
