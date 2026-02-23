import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payroll_model.dart';
import '../services/payroll_service.dart';
import '../services/token_storage_service.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _token;

  // Salary
  EmployeeSalary? _salary;
  bool _isLoadingSalary = true;

  // Payrolls (payslips)
  List<Payroll> _payrolls = [];
  bool _isLoadingPayrolls = true;

  // Pre-Payments
  List<PrePayment> _prePayments = [];
  bool _isLoadingPrePayments = true;

  // Increments
  List<IncrementPromotion> _increments = [];
  bool _isLoadingIncrements = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final token = await TokenStorageService().getToken();
    if (token == null || !mounted) return;
    setState(() => _token = token);

    // Load all in parallel
    await Future.wait([
      _fetchSalary(token),
      _fetchPayrolls(token),
      _fetchPrePayments(token),
      _fetchIncrements(token),
    ]);
  }

  Future<void> _fetchSalary(String token) async {
    try {
      final res = await PayrollService.getMySalary(token: token);
      if (mounted) setState(() { _salary = res.data; _isLoadingSalary = false; });
    } catch (e) {
      print('Salary fetch error: $e');
      if (mounted) setState(() => _isLoadingSalary = false);
    }
  }

  Future<void> _fetchPayrolls(String token) async {
    try {
      final res = await PayrollService.getMyPayrolls(token: token);
      if (mounted) setState(() { _payrolls = res.data; _isLoadingPayrolls = false; });
    } catch (e) {
      print('Payrolls fetch error: $e');
      if (mounted) setState(() => _isLoadingPayrolls = false);
    }
  }

  Future<void> _fetchPrePayments(String token) async {
    try {
      final res = await PayrollService.getPrePayments(token: token);
      if (mounted) setState(() { _prePayments = res.data; _isLoadingPrePayments = false; });
    } catch (e) {
      print('PrePayments fetch error: $e');
      if (mounted) setState(() => _isLoadingPrePayments = false);
    }
  }

  Future<void> _fetchIncrements(String token) async {
    try {
      final res = await PayrollService.getIncrements(token: token);
      if (mounted) setState(() { _increments = res.data; _isLoadingIncrements = false; });
    } catch (e) {
      print('Increments fetch error: $e');
      if (mounted) setState(() => _isLoadingIncrements = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('Payroll', style: TextStyle(fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Salary'),
            Tab(text: 'Payslips'),
            Tab(text: 'Pre-Payments'),
            Tab(text: 'Increments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSalaryTab(),
          _buildPayslipsTab(),
          _buildPrePaymentsTab(),
          _buildIncrementsTab(),
        ],
      ),
    );
  }

  // ── Salary Tab ────────────────────────────────────────────────────────────

  Widget _buildSalaryTab() {
    if (_isLoadingSalary) return _loader();
    if (_salary == null) return _emptyState('No salary information found');

    final s = _salary!;
    return RefreshIndicator(
      onRefresh: () => _fetchSalary(_token!),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Salary overview card
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _statusBadge(s.status, s.status == 'active' ? Colors.greenAccent : Colors.grey),
                    const Spacer(),
                    if (s.salaryGroup != null)
                      Text(s.salaryGroup!, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                _labelValue('Basic Salary', _currency(s.basicSalary)),
                const Divider(color: Colors.white12, height: 24),
                _labelValue('Total Allowances', _currency(s.totalAllowances), valueColor: Colors.greenAccent),
                _labelValue('Total Deductions', '- ${_currency(s.totalDeductions)}', valueColor: Colors.redAccent),
                const Divider(color: Colors.white12, height: 24),
                _labelValue('Net Salary', _currency(s.netSalary),
                    valueColor: Colors.white, valueBold: true, large: true),
                if (s.effectiveFrom != null) ...[
                  const SizedBox(height: 12),
                  Text('Effective from ${DateFormat('dd MMM yyyy').format(s.effectiveFrom!)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                ],
              ],
            ),
          ),
          if (s.allowances.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle('Allowances'),
            ...s.allowances.map((a) => _componentTile(a.name, a.amount, a.type, Colors.greenAccent)),
          ],
          if (s.deductions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle('Deductions'),
            ...s.deductions.map((d) => _componentTile(d.name, d.amount, d.type, Colors.redAccent)),
          ],
        ],
      ),
    );
  }

  // ── Payslips Tab ──────────────────────────────────────────────────────────

  Widget _buildPayslipsTab() {
    if (_isLoadingPayrolls) return _loader();
    if (_payrolls.isEmpty) return _emptyState('No payslips generated yet');

    return RefreshIndicator(
      onRefresh: () => _fetchPayrolls(_token!),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _payrolls.length,
        itemBuilder: (_, i) {
          final p = _payrolls[i];
          return _card(
            margin: const EdgeInsets.only(bottom: 12),
            onTap: () => _showPayslipDetail(p),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${p.monthName} ${p.year}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          )),
                    ),
                    const Spacer(),
                    _statusBadge(p.status, _payrollStatusColor(p.status)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _miniStat('Gross', _currency(p.grossSalary)),
                    _miniStat('Deductions', _currency(p.totalDeductions)),
                    _miniStat('Net', _currency(p.netSalary), highlight: true),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPayslipDetail(Payroll p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('${p.monthName} ${p.year} Payslip',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            _labelValue('Basic Salary', _currency(p.basicSalary)),
            if (p.allowances.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Allowances', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ...p.allowances.map((a) => _labelValue('  ${a.name}', _currency(a.amount), valueColor: Colors.greenAccent)),
            ],
            if (p.deductions.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Deductions', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ...p.deductions.map((d) => _labelValue('  ${d.name}', '- ${_currency(d.amount)}', valueColor: Colors.redAccent)),
            ],
            if (p.prePaymentDeductions > 0)
              _labelValue('  Pre-Payment', '- ${_currency(p.prePaymentDeductions)}', valueColor: Colors.redAccent),
            const Divider(color: Colors.white12, height: 24),
            _labelValue('Gross Salary', _currency(p.grossSalary)),
            _labelValue('Total Deductions', '- ${_currency(p.totalDeductions)}', valueColor: Colors.redAccent),
            const Divider(color: Colors.white12, height: 24),
            _labelValue('Net Salary', _currency(p.netSalary),
                valueColor: Colors.white, valueBold: true, large: true),
            if (p.paymentDate != null) ...[
              const SizedBox(height: 8),
              Text('Paid on ${DateFormat('dd MMM yyyy').format(p.paymentDate!)}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ],
            if (p.notes != null && p.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Note: ${p.notes}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Pre-Payments Tab ──────────────────────────────────────────────────────

  Widget _buildPrePaymentsTab() {
    if (_isLoadingPrePayments) return _loader();
    if (_prePayments.isEmpty) return _emptyState('No pre-payments found');

    return RefreshIndicator(
      onRefresh: () => _fetchPrePayments(_token!),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _prePayments.length,
        itemBuilder: (_, i) {
          final pp = _prePayments[i];
          return _card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _prePaymentColor(pp.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.payments_outlined, color: _prePaymentColor(pp.status), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_currency(pp.amount),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(pp.deductMonth != null ? 'Deduct: ${pp.deductMonth}' : 'No deduction month',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      if (pp.description != null && pp.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(pp.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                        ),
                    ],
                  ),
                ),
                _statusBadge(pp.status, _prePaymentColor(pp.status)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Increments Tab ────────────────────────────────────────────────────────

  Widget _buildIncrementsTab() {
    if (_isLoadingIncrements) return _loader();
    if (_increments.isEmpty) return _emptyState('No increment / promotion records');

    return RefreshIndicator(
      onRefresh: () => _fetchIncrements(_token!),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _increments.length,
        itemBuilder: (_, i) {
          final ip = _increments[i];
          return _card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _typeBadge(ip),
                    const Spacer(),
                    if (ip.effectiveDate != null)
                      Text(DateFormat('dd MMM yyyy').format(ip.effectiveDate!),
                          style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(ip.currentDesignation,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                if (ip.newDesignation != null && ip.newDesignation!.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.arrow_forward, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(ip.newDesignation!, style: const TextStyle(color: Colors.greenAccent)),
                    ],
                  ),
                if (ip.previousCTC != null || ip.newCTC != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (ip.previousCTC != null)
                        Text('CTC: ${_currency(ip.previousCTC!)}',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      if (ip.previousCTC != null && ip.newCTC != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward, size: 12, color: Colors.grey[600]),
                        ),
                      if (ip.newCTC != null)
                        Text(_currency(ip.newCTC!),
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
                if (ip.reason != null && ip.reason!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(ip.reason!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ],
            ),
          );
        },
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

  Widget _card({required Widget child, EdgeInsets? margin, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: child,
      ),
    );
  }

  Widget _labelValue(String label, String value,
      {Color? valueColor, bool valueBold = false, bool large = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: large ? 14 : 13)),
          Text(value,
              style: TextStyle(
                color: valueColor ?? Colors.white70,
                fontWeight: valueBold ? FontWeight.bold : FontWeight.w500,
                fontSize: large ? 16 : 13,
              )),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14)),
      );

  Widget _componentTile(String name, double amount, String type, Color color) {
    return _card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(
            type == 'percentage' ? '${amount.toStringAsFixed(1)}%' : _currency(amount),
            style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
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
        Text(value,
            style: TextStyle(
              color: highlight ? Colors.white : Colors.white70,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            )),
      ],
    );
  }

  Widget _typeBadge(IncrementPromotion ip) {
    final isPositive = ip.type == 'increment' || ip.type == 'promotion' || ip.type == 'increment-promotion';
    final color = isPositive ? Colors.greenAccent : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(ip.typeLabel,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Color _payrollStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.greenAccent;
      case 'pending':
        return Colors.orangeAccent;
      default:
        return Colors.blueAccent;
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

  String _currency(double amount) => '\u{20B9}${NumberFormat('#,##,###.##').format(amount)}';
}
