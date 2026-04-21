import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:hrms_app/features/payroll/data/models/payroll_model.dart';
import 'package:hrms_app/features/payroll/data/services/payroll_service.dart';
import 'package:hrms_app/features/payroll/presentation/providers/payroll_notifier.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';
import 'package:hrms_app/features/admin/data/services/admin_employees_service.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';
import 'package:hrms_app/core/utils/responsive_utils.dart';
import 'package:hrms_app/core/config/api_config.dart';

// ── Month Names Constant ────────────────────────────────────────────────────
const List<String> monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> monthNamesShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class PayrollScreen extends StatefulWidget {
  final String? role;

  const PayrollScreen({super.key, this.role});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  // Theme Colors
  final Color _bg = AppTheme.background;
  final Color _cardColor = AppTheme.cardColor;
  final Color _input = AppTheme.surface;
  final Color _border = AppTheme.outline;
  final Color _primary = AppTheme.primaryColor;
  final Color _success = AppTheme.successColor;
  final Color _warning = AppTheme.warningColor;
  final Color _error = AppTheme.errorColor;
  final Color _textGrey = const Color(0xFF9E9E9E);
  final Color _textLight = AppTheme.onSurface;

  String? _token;
  late bool _isAdmin;

  // Admin
  List<dynamic> _employees = [];
  bool _isLoadingEmployees = false;

  // Filters
  String _filterUserId = 'all';
  String _filterYear = 'all';
  String _filterMonth = 'all';
  bool _isGenerateOpen = false;
  bool _isViewOpen = false;

  // Generate dialog
  String _genUserId = '';
  String _genMonth = '';
  String _genYear = DateTime.now().year.toString();

  // Salary
  EmployeeSalary? _salary;
  bool _isLoadingSalary = true;

  Payroll? _selectedPayroll;

  // Pre-Payments
  List<PrePayment> _prePayments = [];
  bool _isLoadingPrePayments = true;

  // Increments
  List<IncrementPromotion> _increments = [];
  bool _isLoadingIncrements = true;

  @override
  void initState() {
    super.initState();
    _isAdmin = widget.role == 'admin';
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    final token = await TokenStorageService().getToken();
    if (token == null || !mounted) return;
    setState(() => _token = token);

    // Load all in parallel
    final futures = [
      _fetchPayrolls(token),
      _fetchPrePayments(token),
      _fetchIncrements(token),
    ];

    if (_isAdmin) {
      futures.add(_fetchEmployees(token));
    } else {
      futures.add(_fetchSalary(token));
    }

    await Future.wait(futures);
  }

  Future<void> _fetchSalary(String token) async {
    try {
      await context.read<PayrollNotifier>().loadMySalary(token);
      final res = context.read<PayrollNotifier>().state.mySalary;
      if (mounted)
        setState(() {
          _salary = res;
          _isLoadingSalary = false;
        });
    } catch (e) {
      print('Salary fetch error: $e');
      if (mounted) setState(() => _isLoadingSalary = false);
    }
  }

  Future<void> _fetchPayrolls(String token) async {
    try {
      if (_isAdmin) {
        await context.read<PayrollNotifier>().loadAllPayrolls(token);
      } else {
        await context.read<PayrollNotifier>().loadMyPayrolls(token);
      }
      _applyFilters();
    } catch (e) {
      print('Payrolls fetch error: $e');
    }
  }

  Future<void> _fetchPrePayments(String token) async {
    try {
      await context.read<PayrollNotifier>().loadPrePayments(token);
      final res = context.read<PayrollNotifier>().state.prePayments;
      if (mounted)
        setState(() {
          _prePayments = res;
          _isLoadingPrePayments = false;
        });
    } catch (e) {
      print('PrePayments fetch error: $e');
      if (mounted) setState(() => _isLoadingPrePayments = false);
    }
  }

  Future<void> _fetchIncrements(String token) async {
    try {
      await context.read<PayrollNotifier>().loadIncrements(token);
      final res = context.read<PayrollNotifier>().state.increments;
      if (mounted)
        setState(() {
          _increments = res;
          _isLoadingIncrements = false;
        });
    } catch (e) {
      print('Increments fetch error: $e');
      if (mounted) setState(() => _isLoadingIncrements = false);
    }
  }

  Future<void> _fetchEmployees(String token) async {
    if (!_isAdmin) return;
    setState(() => _isLoadingEmployees = true);
    try {
      final res = await AdminEmployeesService.getAllEmployees(token);
      if (mounted) {
        setState(() {
          _employees = (res['data'] as List<dynamic>?) ?? [];
          _isLoadingEmployees = false;
        });
      }
    } catch (e) {
      print('Employees fetch error: $e');
      if (mounted) setState(() => _isLoadingEmployees = false);
    }
  }

  void _applyFilters() {
    final notifier = context.read<PayrollNotifier>();
    notifier.filterByYear(_filterYear == 'all' ? null : int.tryParse(_filterYear));
    notifier.filterByMonth(_filterMonth == 'all' ? null : int.tryParse(_filterMonth));
  }

  List<Payroll> _applyUserFilter(List<Payroll> payrolls) {
    if (_filterUserId == 'all') return payrolls;
    return payrolls.where((p) => p.userId == _filterUserId).toList();
  }

  Future<void> _generatePayroll() async {
    if (_genUserId.isEmpty || _genMonth.isEmpty || _genYear.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select employee, month, and year'),
          backgroundColor: _error,
        ),
      );
      return;
    }
    if (_token == null) return;

    try {
      await context.read<PayrollNotifier>().generatePayroll(
        token: _token!,
        userId: _genUserId,
        month: int.parse(_genMonth),
        year: int.parse(_genYear),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payroll generated successfully'),
          backgroundColor: _success,
        ),
      );
      setState(() => _isGenerateOpen = false);
      _genUserId = '';
      _genMonth = '';
      _genYear = DateTime.now().year.toString();
      _fetchPayrolls(_token!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: _error,
        ),
      );
    }
  }

  Future<void> _markPayrollAsPaid(Payroll payroll) async {
    if (_token == null) return;
    try {
      await context.read<PayrollNotifier>().markPayrollAsPaid(
        token: _token!,
        payrollId: payroll.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payroll marked as paid'),
          backgroundColor: _success,
        ),
      );
      _fetchPayrolls(_token!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: _error,
        ),
      );
    }
  }

  Future<void> _deletePayroll(String payrollId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text(
          'Delete Payroll',
          style: TextStyle(color: _textLight),
        ),
        content: Text(
          'Are you sure you want to delete this payroll record?',
          style: TextStyle(color: _textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || _token == null) return;

    try {
      await context.read<PayrollNotifier>().deletePayroll(
        token: _token!,
        payrollId: payrollId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payroll deleted'),
          backgroundColor: _success,
        ),
      );
      _fetchPayrolls(_token!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: _error,
        ),
      );
    }
  }

  Future<void> _downloadPayslip(Payroll payroll) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating payslip PDF...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Generate payslip content as text for now
      // In production, you would use a PDF library like pdf or pdfx
      final payslipContent = _generatePayslipContent(payroll);

      // For now, display in dialog - in production, save to file
      if (mounted) {
        _showPayslipDownloadPreview(payroll, payslipContent);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payslip ready'),
          backgroundColor: _success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate payslip: ${e.toString()}'),
          backgroundColor: _error,
        ),
      );
    }
  }

  String _generatePayslipContent(Payroll payroll) {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln('PAYSLIP');
    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln('');
    buffer.writeln('Employee: ${payroll.userName ?? 'Unknown'}');
    buffer.writeln('Month: ${_monthNameFull(payroll.month)} ${payroll.year}');
    buffer.writeln('');
    buffer.writeln('───────────────── EARNINGS ─────────────────');
    buffer.writeln(
      'Basic Salary: ₹${NumberFormat('#,##,###.##').format(payroll.basicSalary)}',
    );
    if (payroll.allowances.isNotEmpty) {
      for (var allowance in payroll.allowances) {
        buffer.writeln(
          '${allowance.name}: ₹${NumberFormat('#,##,###.##').format(allowance.amount)}',
        );
      }
    }
    buffer.writeln('───────────────── DEDUCTIONS ─────────────────');
    if (payroll.deductions.isNotEmpty) {
      for (var deduction in payroll.deductions) {
        buffer.writeln(
          '${deduction.name}: ₹${NumberFormat('#,##,###.##').format(deduction.amount)}',
        );
      }
    }
    if (payroll.prePaymentDeductions > 0) {
      buffer.writeln(
        'Pre-Payment: ₹${NumberFormat('#,##,###.##').format(payroll.prePaymentDeductions)}',
      );
    }
    buffer.writeln('───────────────── SUMMARY ─────────────────');
    buffer.writeln(
      'Gross Salary: ₹${NumberFormat('#,##,###.##').format(payroll.grossSalary)}',
    );
    buffer.writeln(
      'Total Deductions: ₹${NumberFormat('#,##,###.##').format(payroll.totalDeductions)}',
    );
    buffer.writeln(
      'Net Salary: ₹${NumberFormat('#,##,###.##').format(payroll.netSalary)}',
    );
    if (payroll.paymentDate != null) {
      buffer.writeln(
        'Payment Date: ${DateFormat('dd MMM yyyy').format(payroll.paymentDate!)}',
      );
    }
    buffer.writeln('Status: ${payroll.status}');
    buffer.writeln('───────────────────────────────────────────────');
    return buffer.toString();
  }

  void _showPayslipDownloadPreview(Payroll payroll, String content) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payslip Preview',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white54),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      content,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _copyToClipboard(content);
                        },
                        icon: const Icon(Icons.copy, size: 14),
                        label: const Text('Copy'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.withOpacity(0.3),
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    // In a real app, you would use:
    // import 'package:flutter/services.dart';
    // Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Content copied (implement clipboard in production)'),
        backgroundColor: _success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: const Text(
          'Payroll',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isAdmin ? _buildAdminView() : _buildEmployeeView(),
    );
  }

  Widget _buildAdminView() {
    final responsive = ResponsiveUtils(context);
    final isMobile = responsive.screenWidth < 600;
    final payrollState = context.watch<PayrollNotifier>().state;
    final payrollRows = _applyUserFilter(payrollState.filteredPayrolls);

    return RefreshIndicator(
      onRefresh: () => _fetchPayrolls(_token ?? ''),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Cards
            _buildStatisticsCards(),
            const SizedBox(height: 16),

            // Info Alert Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                border: Border.all(color: Colors.blue.withOpacity(0.25)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.info, color: Colors.blue, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'If you want to generate payroll for an employee then first setup basic salary for that employee.',
                      style: TextStyle(
                        color: Colors.blue[300],
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Table Card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header: title + filters + buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: isMobile
                        ? _buildTableCardHeaderMobile()
                        : _buildTableCardHeaderDesktop(),
                  ),
                  Divider(color: Colors.white.withOpacity(0.06), height: 1),

                  // Column Headers
                  _buildTableColumnHeaders(isMobile),
                  Divider(color: Colors.white.withOpacity(0.04), height: 1),

                  // Table Rows
                  if (payrollState.isLoading)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: _loader(),
                    )
                  else if (payrollRows.isEmpty)
                    _emptyState('No payrolls found')
                  else
                    Column(
                      children: payrollRows.map((p) {
                        final isLast = p == payrollRows.last;
                        return Column(
                          children: [
                            _buildPayrollTableRow(p, isMobile: isMobile),
                            if (!isLast)
                              Divider(
                                color: Colors.white.withOpacity(0.04),
                                height: 1,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCardHeaderDesktop() {
    return Row(
      children: [
        // Title block
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.credit_card_rounded, color: _primary, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payroll',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'View your payroll history',
                  style: TextStyle(color: _textGrey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        // Filters row
        SizedBox(
          width: 100,
          child: _buildFilterDropdown(
            label: 'Year',
            value: _filterYear,
            items: [
              const DropdownMenuItem(value: 'all', child: Text('All Years')),
              ...List.generate(5, (i) {
                final year = DateTime.now().year - i;
                return DropdownMenuItem(
                  value: year.toString(),
                  child: Text(year.toString()),
                );
              }),
            ],
            onChanged: (v) {
              setState(() => _filterYear = v ?? DateTime.now().year.toString());
              _applyFilters();
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: _buildFilterDropdown(
            label: 'Month',
            value: _filterMonth,
            items: [
              const DropdownMenuItem(value: 'all', child: Text('All Months')),
              ...List.generate(
                12,
                (i) => DropdownMenuItem(
                  value: (i + 1).toString(),
                  child: Text(monthNames[i]),
                ),
              ),
            ],
            onChanged: (v) {
              setState(() => _filterMonth = v ?? 'all');
              _applyFilters();
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 130,
          child: _buildFilterDropdown(
            label: 'Employee',
            value: _filterUserId,
            items: [
              const DropdownMenuItem(value: 'all', child: Text('All Employees')),
              ..._employees.map(
                (e) => DropdownMenuItem(
                  value: e['_id']?.toString() ?? '',
                  child: Text(
                    e['name']?.toString() ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (v) {
              setState(() => _filterUserId = v ?? 'all');
              _applyFilters();
            },
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _applyFilters,
          icon: const Icon(Icons.filter_list, size: 14),
          label: const Text('Filter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.withOpacity(0.15),
            foregroundColor: const Color(0xFF64B5F6),
            side: BorderSide(color: Colors.blue.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _showGeneratePayrollDialog,
          icon: const Icon(Icons.add, size: 14),
          label: const Text('Generate Payroll'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.withOpacity(0.15),
            foregroundColor: const Color(0xFF81C784),
            side: BorderSide(color: Colors.green.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildTableCardHeaderMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title block
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.credit_card_rounded, color: _primary, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payroll',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'View your payroll history',
                  style: TextStyle(color: _textGrey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Filters row (scrollable)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: _buildFilterDropdown(
                  label: 'Year',
                  value: _filterYear,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All')),
                    ...List.generate(5, (i) {
                      final year = DateTime.now().year - i;
                      return DropdownMenuItem(
                        value: year.toString(),
                        child: Text(year.toString()),
                      );
                    }),
                  ],
                  onChanged: (v) {
                    setState(() => _filterYear = v ?? DateTime.now().year.toString());
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: _buildFilterDropdown(
                  label: 'Month',
                  value: _filterMonth,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All Months')),
                    ...List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: (i + 1).toString(),
                        child: Text(monthNamesShort[i]),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _filterMonth = v ?? 'all');
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: _buildFilterDropdown(
                  label: 'Employee',
                  value: _filterUserId,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All')),
                    ..._employees.map(
                      (e) => DropdownMenuItem(
                        value: e['_id']?.toString() ?? '',
                        child: Text(
                          (e['name']?.toString() ?? '').split(' ').first,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _filterUserId = v ?? 'all');
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _applyFilters,
                icon: const Icon(Icons.filter_list, size: 13),
                label: const Text('Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.withOpacity(0.15),
                  foregroundColor: const Color(0xFF64B5F6),
                  side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showGeneratePayrollDialog,
                icon: const Icon(Icons.add, size: 13),
                label: const Text('Generate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.15),
                  foregroundColor: const Color(0xFF81C784),
                  side: BorderSide(color: Colors.green.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableColumnHeaders(bool isMobile) {
    const headerStyle = TextStyle(
      color: Color(0xFF9E9E9E),
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: isMobile
          ? Row(
              children: [
                const Expanded(flex: 3, child: Text('User', style: headerStyle)),
                const Expanded(flex: 2, child: Text('Net Salary', style: headerStyle)),
                const Expanded(flex: 2, child: Text('Status', style: headerStyle)),
                const SizedBox(width: 64, child: Text('Action', style: headerStyle)),
              ],
            )
          : Row(
              children: [
                const Expanded(flex: 3, child: Text('User', style: headerStyle)),
                const Expanded(flex: 2, child: Text('Net Salary', style: headerStyle)),
                const Expanded(flex: 2, child: Text('Month', style: headerStyle)),
                const Expanded(flex: 2, child: Text('Payment Date', style: headerStyle)),
                const Expanded(flex: 2, child: Text('Status', style: headerStyle)),
                const SizedBox(width: 100, child: Text('Action', style: headerStyle)),
              ],
            ),
    );
  }

  void _showGeneratePayrollDialog() {
    final responsive = ResponsiveUtils(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        insetPadding: EdgeInsets.symmetric(
          horizontal: responsive.screenWidth > 600 ? 80 : 16,
          vertical: 16,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: responsive.screenWidth > 600 ? 400 : double.infinity,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Generate Payroll',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Employee Dropdown
                const Text(
                  'Employee',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _genUserId.isEmpty ? null : _genUserId,
                    items: _employees
                        .map(
                          (e) => DropdownMenuItem(
                            value: e['_id']?.toString() ?? '',
                            child: Text(
                              e['name']?.toString() ?? '',
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _genUserId = v ?? ''),
                    dropdownColor: const Color(0xFF1A1A1A),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    iconEnabledColor: Colors.white54,
                    underline: const SizedBox(),
                    isExpanded: true,
                    hint: const Text(
                      'Select employee',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Month & Year Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Month',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141414),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: _genMonth.isEmpty ? null : _genMonth,
                              items: List.generate(
                                12,
                                (i) => DropdownMenuItem(
                                  value: (i + 1).toString(),
                                  child: Text(
                                    monthNamesShort[i],
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ).toList(),
                              onChanged: (v) =>
                                  setState(() => _genMonth = v ?? ''),
                              dropdownColor: const Color(0xFF1A1A1A),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              iconEnabledColor: Colors.white54,
                              underline: const SizedBox(),
                              isExpanded: true,
                              hint: const Text(
                                'Month',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Year',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141414),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: _genYear,
                              items: List.generate(5, (i) {
                                final year = DateTime.now().year - i;
                                return DropdownMenuItem(
                                  value: year.toString(),
                                  child: Text(
                                    year.toString(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) => setState(
                                () => _genYear =
                                    v ?? DateTime.now().year.toString(),
                              ),
                              dropdownColor: const Color(0xFF1A1A1A),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              iconEnabledColor: Colors.white54,
                              underline: const SizedBox(),
                              isExpanded: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _generatePayroll();
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.check_circle, size: 16),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        label: const Text(
                          'Generate',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Statistics Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStatisticsCards(),
          ),
          // Salary Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Salary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textLight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSalaryTab(),
          ),
          // Payslips Section
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 12),
            child: Text(
              'Payslips',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textLight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPayslipsTab(),
          ),
          // Pre-Payments Section
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 12),
            child: Text(
              'Pre-Payments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textLight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPrePaymentsTab(),
          ),
          // Increments Section
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 12),
            child: Text(
              'Increments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textLight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _buildIncrementsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        dropdownColor: const Color(0xFF141414),
        style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 13, fontWeight: FontWeight.w500),
        iconEnabledColor: const Color(0xFF9E9E9E),
        underline: const SizedBox(),
        isExpanded: true,
      ),
    );
  }

  Widget _buildPayrollTableRow(Payroll payroll, {bool isMobile = false}) {
    final statusColor = _payrollStatusColor(payroll.status);
    final paymentDateStr = payroll.paymentDate != null
        ? DateFormat('dd MMM yyyy').format(payroll.paymentDate!)
        : '—';

    return InkWell(
      onTap: () => _showPayslipDetail(payroll),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: isMobile
            ? Row(
                children: [
                  // User col
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              (payroll.userName ?? 'U').characters.first.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                payroll.userName ?? payroll.userId ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (payroll.userDepartment != null)
                                Text(
                                  payroll.userDepartment!,
                                  style: TextStyle(color: _textGrey, fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Net Salary col
                  Expanded(
                    flex: 2,
                    child: Text(
                      _currency(payroll.netSalary),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Status col
                  Expanded(
                    flex: 2,
                    child: _statusBadge(payroll.status, statusColor),
                  ),
                  // Action col
                  SizedBox(
                    width: 64,
                    child: Row(
                      children: [
                        _tableIconButton(
                          icon: Icons.visibility_outlined,
                          color: Colors.blue,
                          tooltip: 'View',
                          onTap: () => _showPayslipDetail(payroll),
                        ),
                        const SizedBox(width: 4),
                        _tableIconButton(
                          icon: Icons.download_outlined,
                          color: Colors.purple,
                          tooltip: 'Download',
                          onTap: () => _downloadPayslip(payroll),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  // User col
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              (payroll.userName ?? 'U').characters.first.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                payroll.userName ?? payroll.userId ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (payroll.userDepartment != null)
                                Text(
                                  payroll.userDepartment!,
                                  style: TextStyle(color: _textGrey, fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Net Salary col
                  Expanded(
                    flex: 2,
                    child: Text(
                      _currency(payroll.netSalary),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Month col
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${_monthNameFull(payroll.month)} ${payroll.year}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  // Payment Date col
                  Expanded(
                    flex: 2,
                    child: Text(
                      paymentDateStr,
                      style: TextStyle(
                        color: payroll.paymentDate != null
                            ? Colors.white70
                            : _textGrey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  // Status col
                  Expanded(
                    flex: 2,
                    child: _statusBadge(payroll.status, statusColor),
                  ),
                  // Action col
                  SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        _tableIconButton(
                          icon: Icons.visibility_outlined,
                          color: Colors.blue,
                          tooltip: 'View',
                          onTap: () => _showPayslipDetail(payroll),
                        ),
                        const SizedBox(width: 4),
                        _tableIconButton(
                          icon: Icons.download_outlined,
                          color: Colors.purple,
                          tooltip: 'Download',
                          onTap: () => _downloadPayslip(payroll),
                        ),
                        if (_isAdmin && payroll.status == 'generated') ...[
                          const SizedBox(width: 4),
                          _tableIconButton(
                            icon: Icons.check_circle_outline,
                            color: Colors.green,
                            tooltip: 'Mark Paid',
                            onTap: () => _markPayrollAsPaid(payroll),
                          ),
                        ],
                        if (_isAdmin) ...[
                          const SizedBox(width: 4),
                          _tableIconButton(
                            icon: Icons.delete_outline,
                            color: Colors.red,
                            tooltip: 'Delete',
                            onTap: () => _deletePayroll(payroll.id),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _tableIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }

  String _monthName(int? month) {
    if (month == null || month < 1 || month > 12) return '';
    return monthNamesShort[month - 1];
  }

  String _monthNameFull(int? month) {
    if (month == null || month < 1 || month > 12) return '';
    return monthNames[month - 1];
  }

  Widget _buildStatisticsCards() {
    final responsive = ResponsiveUtils(context);
    final isMobile = responsive.screenWidth < 600;
    final payrolls = context.watch<PayrollNotifier>().state.payrolls;
    
    int generated = payrolls.where((p) => p.status == 'generated').length;
    int paid = payrolls.where((p) => p.status == 'paid').length;
    int pending = payrolls.where((p) => p.status == 'pending').length;
    double totalPaid = payrolls
        .where((p) => p.status == 'paid')
        .fold<double>(0, (sum, p) => sum + (p.netSalary ?? 0));

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isMobile ? 1.2 : 1.3,
      children: [
        _buildStatCard(
          'Generated',
          generated.toString(),
          Icons.file_present_rounded,
          const Color(0xFF2196F3),
        ),
        _buildStatCard(
          'Paid',
          paid.toString(),
          Icons.check_circle_rounded,
          const Color(0xFF4CAF50),
        ),
        _buildStatCard(
          'Pending',
          pending.toString(),
          Icons.schedule_rounded,
          const Color(0xFFFFC107),
        ),
        _buildStatCard(
          'Total Paid',
          _currency(totalPaid),
          Icons.currency_rupee_rounded,
          const Color(0xFF2196F3),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Salary Tab ────────────────────────────────────────────────────────────

  Widget _buildSalaryTab() {
    if (_isLoadingSalary) return _loader();
    if (_salary == null) return _emptyState('No salary information found');

    final s = _salary!;
    final ctc = s.basicSalary + s.totalAllowances;

    return RefreshIndicator(
      onRefresh: () => _fetchSalary(_token!),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main CTC Card with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[900]?.withOpacity(0.3) ?? Colors.transparent,
                    Colors.blue[700]?.withOpacity(0.2) ?? Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cost to Company',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currency(ctc),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.payments_rounded,
                          color: Colors.blue[300],
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSalaryBreakdown('Basic', s.basicSalary),
                      _buildSalaryBreakdown('Allowances', s.totalAllowances),
                      _buildSalaryBreakdown('Deductions', s.totalDeductions),
                    ],
                  ),
                  if (s.effectiveFrom != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Effective from ${DateFormat('dd MMM yyyy').format(s.effectiveFrom!)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Earnings Section
            if (s.allowances.isNotEmpty) ...[
              const Text(
                'Earnings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _card(
                child: Column(
                  children: [
                    _salaryRow('Basic Salary', s.basicSalary, Colors.green),
                    if (s.allowances.isNotEmpty)
                      const Divider(color: Colors.white12, height: 16),
                    ...s.allowances
                        .map(
                          (a) =>
                              _salaryRow(a.name, a.amount, Colors.greenAccent),
                        )
                        .toList(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Deductions Section
            if (s.deductions.isNotEmpty) ...[
              const Text(
                'Deductions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _card(
                child: Column(
                  children: [
                    ...s.deductions
                        .asMap()
                        .entries
                        .map(
                          (e) => Column(
                            children: [
                              _salaryRow(
                                e.value.name,
                                e.value.amount,
                                Colors.redAccent,
                                isDeduction: true,
                              ),
                              if (e.key < s.deductions.length - 1)
                                const Divider(
                                  color: Colors.white12,
                                  height: 16,
                                ),
                            ],
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Net Salary Summary
            _card(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gross Salary',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _currency(s.basicSalary + s.totalAllowances),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Net Monthly Salary',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _currency(s.netSalary),
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryBreakdown(String label, double amount) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[900]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _currency(amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _salaryRow(
    String label,
    double amount,
    Color color, {
    bool isDeduction = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              (isDeduction ? '- ' : '') + _currency(amount),
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Payslips Tab ──────────────────────────────────────────────────────────

  Widget _buildPayslipsTab() {
    final payrollState = context.watch<PayrollNotifier>().state;
    final payrolls = payrollState.payrolls;
    if (payrollState.isLoading) return _loader();
    if (payrolls.isEmpty) return _emptyState('No payslips generated yet');

    return RefreshIndicator(
      onRefresh: () => _fetchPayrolls(_token!),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: payrolls.length,
        itemBuilder: (_, i) {
          final p = payrolls[i];
          final statusColor = _payrollStatusColor(p.status);

          return _card(
            margin: const EdgeInsets.only(bottom: 12),
            onTap: () => _showPayslipDetail(p),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with month and status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${p.monthName} ${p.year}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _statusBadge(p.status, statusColor),
                  ],
                ),
                const SizedBox(height: 16),

                // Summary stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPayslipStat(
                      'Gross Salary',
                      _currency(p.grossSalary),
                      Colors.blue,
                    ),
                    _buildPayslipStat(
                      'Deductions',
                      '- ${_currency(p.totalDeductions)}',
                      Colors.red,
                    ),
                    _buildPayslipStat(
                      'Net Salary',
                      _currency(p.netSalary),
                      Colors.green,
                      highlight: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Payment date if available
                if (p.paymentDate != null)
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Paid on ${DateFormat('dd MMM yyyy').format(p.paymentDate!)}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: Colors.orange[400],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Payment pending',
                        style: TextStyle(
                          color: Colors.orange[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPayslipStat(
    String label,
    String value,
    Color color, {
    bool highlight = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: highlight ? color.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: highlight ? Colors.greenAccent : color.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPayslipDetail(Payroll p) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - User Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _payrollStatusColor(p.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              (p.userName?.characters.first ?? 'U').toUpperCase(),
                              style: TextStyle(
                                color: _payrollStatusColor(p.status),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.userName ?? p.userId ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_monthNameFull(p.month)} ${p.year}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(color: Colors.grey[800], thickness: 1),
                const SizedBox(height: 16),

                // Month, Year, Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Month',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_monthNameFull(p.month)} ${p.year}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _statusBadge(p.status, _payrollStatusColor(p.status)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: Colors.grey[800], thickness: 1),
                const SizedBox(height: 16),

                // EARNINGS Section
                Text(
                  'Earnings',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _payslipRow('Basic Salary', _currency(p.basicSalary ?? 0)),
                if (p.allowances.isNotEmpty)
                  ...p.allowances.map(
                    (a) => _payslipRow(a.name, _currency(a.amount ?? 0)),
                  ),
                const SizedBox(height: 8),
                _payslipRow(
                  'Gross Salary',
                  _currency(p.grossSalary ?? 0),
                  isBold: true,
                  isBottom: true,
                ),

                const SizedBox(height: 16),
                Divider(color: Colors.grey[800], thickness: 1),
                const SizedBox(height: 16),

                // DEDUCTIONS Section
                Text(
                  'Deductions',
                  style: const TextStyle(
                    color: Color(0xFFFF5252),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                if (p.deductions.isNotEmpty)
                  ...p.deductions.map(
                    (d) => _payslipRow(d.name, _currency(d.amount ?? 0)),
                  ),
                if (p.prePaymentDeductions > 0)
                  _payslipRow(
                    'Pre-Payment Advance',
                    _currency(p.prePaymentDeductions ?? 0),
                  ),
                const SizedBox(height: 8),
                _payslipRow(
                  'Total Deductions',
                  _currency(p.totalDeductions ?? 0),
                  isBold: true,
                  isBottom: true,
                ),

                const SizedBox(height: 20),
                Divider(color: Colors.grey[800], thickness: 1),
                const SizedBox(height: 16),

                // NET SALARY (Highlighted)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Salary',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _currency(p.netSalary ?? 0),
                        style: TextStyle(
                          color: _primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                if (p.paymentDate != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Paid on: ${DateFormat('dd MMM yyyy').format(p.paymentDate is String ? DateTime.parse(p.paymentDate as String) : p.paymentDate as DateTime)}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Download Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadPayslip(p),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download Payslip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _payslipRow(
    String label,
    String value, {
    bool isBold = false,
    bool isBottom = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isBottom ? 4 : 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Pre-Payments Tab ──────────────────────────────────────────────────────

  Widget _buildPrePaymentsTab() {
    if (_isLoadingPrePayments) return _loader();
    if (_prePayments.isEmpty) return _emptyState('No pre-payments found');

    // Calculate total approved and pending amounts
    final totalApproved = _prePayments
        .where((p) => p.status == 'approved')
        .fold<double>(0, (sum, p) => sum + p.amount);
    final totalPending = _prePayments
        .where((p) => p.status == 'pending')
        .fold<double>(0, (sum, p) => sum + p.amount);
    final totalRejected = _prePayments
        .where((p) => p.status == 'rejected')
        .fold<double>(0, (sum, p) => sum + p.amount);

    return RefreshIndicator(
      onRefresh: () => _fetchPrePayments(_token!),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildPrePaymentStat(
                        'Approved',
                        _currency(totalApproved),
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPrePaymentStat(
                        'Pending',
                        _currency(totalPending),
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPrePaymentStat(
                        'Rejected',
                        _currency(totalRejected),
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pre-Payment History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
              ]),
            ),
          ),

          // Pre-payments list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((_, i) {
                final pp = _prePayments[i];
                final color = _prePaymentColor(pp.status);

                return _card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with amount and status
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.payments_outlined,
                              color: color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currency(pp.amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pp.deductMonth ?? 'No deduction month',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _statusBadge(pp.status, color),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Description if available
                      if (pp.description != null && pp.description!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[900]?.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            pp.description!,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ),

                      // Date information
                      const SizedBox(height: 8),
                      if (pp.createdAt != null)
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Requested on ${DateFormat('dd MMM yyyy').format(pp.createdAt!)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              }, childCount: _prePayments.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrePaymentStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Increments Tab ────────────────────────────────────────────────────────

  Widget _buildIncrementsTab() {
    if (_isLoadingIncrements) return _loader();
    if (_increments.isEmpty)
      return _emptyState('No increment / promotion records');

    // Count statistics
    final increments = _increments.where((ip) => ip.type == 'increment').length;
    final promotions = _increments.where((ip) => ip.type == 'promotion').length;
    final others = _increments
        .where((ip) => ip.type != 'increment' && ip.type != 'promotion')
        .length;

    return RefreshIndicator(
      onRefresh: () => _fetchIncrements(_token!),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: _buildIncrementStat(
                        'Increments',
                        increments.toString(),
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildIncrementStat(
                        'Promotions',
                        promotions.toString(),
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildIncrementStat(
                        'Others',
                        others.toString(),
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Career Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
              ]),
            ),
          ),

          // Increments list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((_, i) {
                final ip = _increments[i];
                final isPositive =
                    ip.type == 'increment' || ip.type == 'promotion';
                final ctcChange = ip.newCTC != null && ip.previousCTC != null
                    ? ip.newCTC! - ip.previousCTC!
                    : 0.0;

                return _card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with type badge and date
                      Row(
                        children: [
                          _typeBadge(ip),
                          const Spacer(),
                          if (ip.effectiveDate != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(ip.effectiveDate!),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Designation change
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Designation',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ip.currentDesignation,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      if (ip.newDesignation != null &&
                          ip.newDesignation!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'New Designation',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ip.newDesignation!,
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.grey[600],
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // CTC change
                      if (ip.previousCTC != null && ip.newCTC != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isPositive
                                ? Colors.greenAccent.withOpacity(0.1)
                                : Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isPositive
                                  ? Colors.greenAccent.withOpacity(0.3)
                                  : Colors.redAccent.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Previous CTC',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _currency(ip.previousCTC!),
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    color: isPositive
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'New CTC',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          _currency(ip.newCTC!),
                                          style: TextStyle(
                                            color: isPositive
                                                ? Colors.greenAccent
                                                : Colors.redAccent,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (ctcChange != 0) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${isPositive ? '+' : ''} ${_currency(ctcChange)} change',
                                  style: TextStyle(
                                    color: isPositive
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      // Reason if available
                      if (ip.reason != null && ip.reason!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[900]?.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reason',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ip.reason!,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }, childCount: _increments.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncrementStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared UI helpers ─────────────────────────────────────────────────────

  Widget _loader() => const Center(child: CircularProgressIndicator());

  Widget _emptyState(String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey[700]),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    ),
  );

  Widget _card({
    required Widget child,
    EdgeInsets? margin,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: child,
      ),
    );
  }

  Widget _labelValue(
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
    bool large = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: large ? 14 : 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white70,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.w500,
              fontSize: large ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  );

  Widget _componentTile(String name, double amount, String type, Color color) {
    return _card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            type == 'percentage'
                ? '${amount.toStringAsFixed(1)}%'
                : _currency(amount),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      status[0].toUpperCase() + status.substring(1),
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );

  Widget _miniStat(String label, String value, {bool highlight = false}) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: highlight ? Colors.white : Colors.white70,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _typeBadge(IncrementPromotion ip) {
    final isPositive =
        ip.type == 'increment' ||
        ip.type == 'promotion' ||
        ip.type == 'increment-promotion';
    final color = isPositive ? Colors.greenAccent : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        ip.typeLabel,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _payrollStatusColor(String status) {
    switch (status) {
      case 'paid':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'generated':
      default:
        return AppTheme.primaryColor;
    }
  }

  Color _prePaymentColor(String status) {
    switch (status) {
      case 'deducted':
        return Colors.greenAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  String _currency(double amount) =>
      '\u{20B9}${NumberFormat('#,##,###.##').format(amount)}';
}
