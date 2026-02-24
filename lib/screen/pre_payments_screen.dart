import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payroll_model.dart';
import '../services/payroll_service.dart';
import '../services/token_storage_service.dart';

class PrePaymentsScreen extends StatefulWidget {
  const PrePaymentsScreen({super.key});

  @override
  State<PrePaymentsScreen> createState() => _PrePaymentsScreenState();
}

class _PrePaymentsScreenState extends State<PrePaymentsScreen> {
  String? _token;
  List<PrePayment> _prePayments = [];
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = await TokenStorageService().getToken();
    if (token == null || !mounted) return;
    setState(() => _token = token);
    await _fetchPrePayments(token);
  }

  Future<void> _fetchPrePayments(String token) async {
    try {
      final res = await PayrollService.getPrePayments(token: token);
      if (mounted) {
        setState(() {
          _prePayments = res.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('PrePayments fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _endDate = picked);
    }
  }

  List<PrePayment> _getFilteredPayments() {
    return _prePayments.where((p) {
      if (p.createdAt == null) return false;
      if (_startDate != null && p.createdAt!.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && p.createdAt!.isAfter(_endDate!)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: const Text(
          'Pre Payments',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadData(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'View your pre-payment records',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Date Filters
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateField(
                                  label: 'Start Date',
                                  date: _startDate,
                                  onTap: _selectStartDate,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDateField(
                                  label: 'End Date',
                                  date: _endDate,
                                  onTap: _selectEndDate,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Stats
                          _buildStatsCard(),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final filtered = _getFilteredPayments();
                        if (filtered.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.payment_rounded,
                                    size: 64,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No pre-payment records found',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final payment = filtered[index];
                        return _buildPaymentCard(payment);
                      },
                      childCount: _getFilteredPayments().isEmpty ? 1 : _getFilteredPayments().length,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[800]!, width: 1),
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
            const SizedBox(height: 4),
            Text(
              date != null ? DateFormat('dd-MMM-yyyy').format(date) : 'dd-mm-yyyy',
              style: TextStyle(
                color: date != null ? Colors.white : Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final filtered = _getFilteredPayments();
    final total = filtered.fold<double>(0, (sum, p) => sum + (double.tryParse(p.amount.toString()) ?? 0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A3A1A).withOpacity(0.5),
            const Color(0xFF1A2A4A).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Total Records', '${filtered.length}'),
          Container(width: 1, height: 40, color: Colors.grey[800]),
          _buildStatItem('Total Amount', _currency(total)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(PrePayment payment) {
    Color statusColor = _getStatusColor(payment.status);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[900]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currency(double.tryParse(payment.amount.toString()) ?? 0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.5), width: 1),
                  ),
                  child: Text(
                    payment.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Request Date', payment.createdAt != null ? DateFormat('dd MMM yyyy').format(payment.createdAt!) : 'N/A'),
            const SizedBox(height: 8),
            _buildDetailRow('Deduct Month', payment.deductMonth ?? 'N/A'),
            if (payment.description != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Description', payment.description ?? 'N/A'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _currency(double amount) => '\u{20B9}${NumberFormat('#,##,###.##').format(amount)}';
}
