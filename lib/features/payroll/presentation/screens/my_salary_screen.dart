import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hrms_app/features/payroll/data/models/payroll_model.dart';
import 'package:hrms_app/features/payroll/data/services/payroll_service.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';

class MySalaryScreen extends StatefulWidget {
  const MySalaryScreen({super.key});

  @override
  State<MySalaryScreen> createState() => _MySalaryScreenState();
}

class _MySalaryScreenState extends State<MySalaryScreen> {
  // Theme colors
  static const Color _bgDark = Color(0xFF050505);
  static const Color _cardDark = Color(0xFF0A0A0A);
  static const Color _border = Color(0xFF1A1A1A);
  static const Color _textGrey = Color(0xFF9E9E9E);
  static const Color _accentGreen = Color(0xFF69F0AE);

  String? _token;
  EmployeeSalary? _salary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = await TokenStorageService().getToken();
    if (token == null || !mounted) return;
    setState(() => _token = token);
    await _fetchSalary(token);
  }

  Future<void> _fetchSalary(String token) async {
    try {
      final res = await PayrollService.getMySalary(token: token);
      if (mounted) {
        setState(() {
          _salary = res.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Salary fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _cardDark,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.wallet, color: _accentGreen, size: 24),
            SizedBox(width: 12),
            Text(
              'My Salary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _salary == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.money_rounded,
                            size: 64,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No salary records found',
                            style: TextStyle(
                              color: _textGrey,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMainCard(),
                                const SizedBox(height: 24),
                                _buildComponentsSection(),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildMainCard() {
    if (_salary == null) return const SizedBox();

    final salary = _salary!;
    final ctc = salary.basicSalary + salary.totalAllowances;
    final netSalary = ctc - salary.totalDeductions;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Annual Salary (CTC)',
                      style: TextStyle(
                        color: _textGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currency(ctc),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: salary.status == 'active'
                      ? _accentGreen.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: salary.status == 'active'
                        ? _accentGreen.withOpacity(0.5)
                        : Colors.orange.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  salary.status[0].toUpperCase() +
                      salary.status.substring(1).toLowerCase(),
                  style: TextStyle(
                    color:
                        salary.status == 'active' ? _accentGreen : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: _border),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSalaryInfoItem('Basic', salary.basicSalary),
              ),
              Expanded(
                child: _buildSalaryInfoItem(
                    'Allowances', salary.totalAllowances),
              ),
              Expanded(
                child: _buildSalaryInfoItem('Deductions', salary.totalDeductions),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _border,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Salary (Monthly)',
                  style: TextStyle(
                    color: _textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _currency(netSalary / 12),
                  style: const TextStyle(
                    color: _accentGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryInfoItem(String label, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _textGrey,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _currency(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildComponentsSection() {
    if (_salary == null) return const SizedBox();

    final salary = _salary!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0),
          child: Text(
            'Salary Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildComponentCard(
          'Basic Salary',
          salary.basicSalary,
          _accentGreen,
        ),
        if (salary.allowances.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 12),
            child: Text(
              'Allowances',
              style: TextStyle(
                color: _textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...salary.allowances.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildComponentCard(a.name, a.amount, Colors.blue),
            ),
          ),
        ],
        if (salary.deductions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 12),
            child: Text(
              'Deductions',
              style: TextStyle(
                color: _textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...salary.deductions.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildComponentCard(
                d.name,
                d.amount,
                Colors.red,
                isDeduction: true,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildComponentCard(
    String name,
    double amount,
    Color color, {
    bool isDeduction = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              (isDeduction ? '- ' : '') + _currency(amount),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _currency(double amount) =>
      '\u{20B9}${NumberFormat('#,##,###.##').format(amount)}';
}
