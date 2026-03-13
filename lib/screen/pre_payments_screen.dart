import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payroll_model.dart';
import '../models/profile_model.dart';
import '../services/payroll_service.dart';
import '../services/token_storage_service.dart';
import '../services/admin_employees_service.dart';
import '../utils/responsive_utils.dart';
import '../theme/app_theme.dart';

class PrePaymentsScreen extends StatefulWidget {
  const PrePaymentsScreen({super.key});

  @override
  State<PrePaymentsScreen> createState() => _PrePaymentsScreenState();
}

class _PrePaymentsScreenState extends State<PrePaymentsScreen> {
  String? _token;
  String? _userRole;
  List<PrePayment> _prePayments = [];
  List<ProfileUser> _employees = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _selectedFilterUser = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  // Form state
  bool _isDialogOpen = false;
  bool _isViewOpen = false;
  bool _isEditMode = false;
  PrePayment? _selectedRecord;

  final _formKey = GlobalKey<FormState>();
  String? _selectedUserId;
  final _amountCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _deductMonthCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _accountNumberCtrl.dispose();
    _bankNameCtrl.dispose();
    _deductMonthCtrl.dispose();
    _descriptionCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final token = await TokenStorageService().getToken();
    final role = await TokenStorageService().getUserRole();

    if (token == null || !mounted) return;

    setState(() {
      _token = token;
      _userRole = role;
    });

    await Future.wait([
      _fetchPrePayments(token),
      if (role?.toLowerCase() == 'admin') _fetchEmployees(token),
    ]);
  }

  Future<void> _fetchPrePayments(String token) async {
    try {
      debugPrint('🔄 Fetching pre-payments...');
      final res = await PayrollService.getPrePayments(token: token);
      debugPrint('✅ Pre-payments fetched: ${res.data.length} records');
      if (mounted) {
        setState(() {
          _prePayments = res.data;
          _isLoading = false;
        });
        debugPrint('✓ UI updated with ${_prePayments.length} pre-payments');
      }
    } catch (e) {
      debugPrint('❌ Pre-payments fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchEmployees(String token) async {
    try {
      debugPrint('🔄 Fetching employees...');
      final res = await AdminEmployeesService.getAllEmployees(token);
      if (mounted && res['data'] != null) {
        final List<dynamic> employeeList = res['data'] is List
            ? res['data']
            : (res['data']['employees'] ?? []);
        setState(() {
          _employees = employeeList
              .whereType<Map<String, dynamic>>()
              .map((e) => ProfileUser.fromJson(e))
              .toList();
        });
        debugPrint('✅ Loaded ${_employees.length} employees');
      }
    } catch (e) {
      debugPrint('❌ Employees fetch error: $e');
    }
  }

  List<PrePayment> _getFilteredPayments() {
    return _prePayments.where((p) {
      // Filter by user
      if (_selectedFilterUser != 'all' && p.user?.id != _selectedFilterUser) {
        return false;
      }

      // Filter by date range
      if (p.createdAt == null) return false;
      if (_startDate != null && p.createdAt!.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null &&
          p.createdAt!.isAfter(_endDate!.add(const Duration(days: 1)))) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final employeeName = p.user?.name.toLowerCase() ?? '';
        final amount = p.amount.toString();
        final month = p.deductMonth?.toLowerCase() ?? '';
        final bankName = p.bankDetails?.bankName?.toLowerCase() ?? '';
        
        if (!employeeName.contains(query) &&
            !amount.contains(query) &&
            !month.contains(query) &&
            !bankName.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _resetForm() {
    _selectedUserId = null;
    _amountCtrl.clear();
    _accountNumberCtrl.clear();
    _bankNameCtrl.clear();
    _deductMonthCtrl.clear();
    _descriptionCtrl.clear();
    _isEditMode = false;
    _selectedRecord = null;
  }

  void _openAddDialog() {
    _resetForm();
    setState(() {
      _isDialogOpen = true;
      _isEditMode = false;
    });
    _showFormDialog();
  }

  void _openEditDialog(PrePayment record) {
    _selectedRecord = record;
    _selectedUserId = record.user?.id;
    _amountCtrl.text = record.amount.toString();
    _accountNumberCtrl.text = record.bankDetails?.accountNumber ?? '';
    _bankNameCtrl.text = record.bankDetails?.bankName ?? '';
    _deductMonthCtrl.text = record.deductMonth ?? '';
    _descriptionCtrl.text = record.description ?? '';

    setState(() {
      _isDialogOpen = true;
      _isEditMode = true;
    });
    _showFormDialog();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedUserId == null ||
        _amountCtrl.text.isEmpty ||
        _deductMonthCtrl.text.isEmpty) {
      _showSnackBar('Please fill all required fields', Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'user': _selectedUserId,
        'amount': double.parse(_amountCtrl.text),
        'bankDetails': {
          'accountNumber': _accountNumberCtrl.text.isEmpty
              ? null
              : _accountNumberCtrl.text,
          'bankName': _bankNameCtrl.text.isEmpty ? null : _bankNameCtrl.text,
        },
        'deductMonth': _deductMonthCtrl.text,
        'description': _descriptionCtrl.text.isEmpty
            ? null
            : _descriptionCtrl.text,
      };

      if (_isEditMode && _selectedRecord != null) {
        await PayrollService.updatePrePayment(
          token: _token!,
          id: _selectedRecord!.id,
          data: payload,
        );
        _showSnackBar('Pre-payment updated successfully', Colors.green);
      } else {
        await PayrollService.createPrePayment(token: _token!, data: payload);
        _showSnackBar('Pre-payment created successfully', Colors.green);
      }

      if (mounted) Navigator.pop(context);
      setState(() => _isDialogOpen = false);
      await _fetchPrePayments(_token!);
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleDelete(String id) async {
    final confirm = await _showConfirmDialog(
      'Delete Pre-Payment',
      'Are you sure you want to delete this pre-payment?',
    );
    if (!confirm) return;

    try {
      await PayrollService.deletePrePayment(token: _token!, id: id);
      _showSnackBar('Pre-payment deleted successfully', Colors.green);
      await _fetchPrePayments(_token!);
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Text(message, style: const TextStyle(color: Colors.grey)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _userRole?.toLowerCase() == 'admin';
    final filtered = _getFilteredPayments();

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
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                debugPrint('🔄 Manual refresh triggered');
                _loadData();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF8FA3)),
            )
          : RefreshIndicator(
              onRefresh: () => _loadData(),
              color: const Color(0xFFFF8FA3),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isAdmin
                                    ? 'Manage pre-payments'
                                    : 'Your pre-payment records',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              if (isAdmin)
                                ElevatedButton.icon(
                                  onPressed: _openAddDialog,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add New'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF8FA3),
                                    foregroundColor: Colors.black,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Search Bar
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by employee, amount, month, bank...',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFFFF8FA3),
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(0xFF1A1A1A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[800]!,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[800]!,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFF8FA3),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 20),

                          // Filters
                          if (isAdmin)
                            Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: _selectedFilterUser,
                                  onChanged: (value) => setState(
                                    () => _selectedFilterUser = value ?? 'all',
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Filter by Employee',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF0A0A0A),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: 'all',
                                      child: Text('All Employees'),
                                    ),
                                    ..._employees.map(
                                      (e) => DropdownMenuItem(
                                        value: e.id,
                                        child: Text(e.name),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),

                          // Date Filters
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _startDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null)
                                      setState(() => _startDate = picked);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[800]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Start Date',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _startDate != null
                                              ? DateFormat(
                                                  'dd-MMM-yyyy',
                                                ).format(_startDate!)
                                              : 'Select date',
                                          style: TextStyle(
                                            color: _startDate != null
                                                ? Colors.white
                                                : Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _endDate ?? DateTime.now(),
                                      firstDate: _startDate ?? DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null)
                                      setState(() => _endDate = picked);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[800]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'End Date',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _endDate != null
                                              ? DateFormat(
                                                  'dd-MMM-yyyy',
                                                ).format(_endDate!)
                                              : 'Select date',
                                          style: TextStyle(
                                            color: _endDate != null
                                                ? Colors.white
                                                : Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Stats
                          _buildStatsCard(filtered),
                        ],
                      ),
                    ),
                  ),
                  // Records List
                  filtered.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 40,
                              horizontal: 16,
                            ),
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isAdmin
                                      ? 'Create your first pre-payment record'
                                      : 'No pre-payment records yet',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (isAdmin) ...[
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _openAddDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Create Record'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF8FA3),
                                      foregroundColor: Colors.black,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _buildPaymentCard(filtered[index], isAdmin),
                            childCount: filtered.length,
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
              date != null
                  ? DateFormat('dd-MMM-yyyy').format(date)
                  : 'dd-mm-yyyy',
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

  Widget _buildStatsCard(List<PrePayment> filtered) {
    final total = filtered.fold<double>(
      0,
      (sum, p) => sum + (double.tryParse(p.amount.toString()) ?? 0),
    );

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

  Widget _buildPaymentCard(PrePayment payment, bool isAdmin) {
    Color statusColor = _getStatusColor(payment.status);
    final user = payment.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[900]!, width: 1),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.3),
                child: Icon(
                  Icons.payment_rounded,
                  color: statusColor,
                  size: 28,
                ),
              ),
              title: Text(
                user?.name ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    user?.position ?? 'N/A',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    user?.department ?? 'N/A',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              trailing: isAdmin
                  ? PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openEditDialog(payment);
                        } else if (value == 'delete') {
                          _handleDelete(payment.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    )
                  : null,
            ),
            Divider(height: 1, color: Colors.grey[900]),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currency(
                          double.tryParse(payment.amount.toString()) ?? 0,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4FC3F7),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deduct Month',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payment.deductMonth ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Status',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: statusColor.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          payment.status.replaceFirst(
                            payment.status[0],
                            payment.status[0].toUpperCase(),
                          ),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFormDialog() {
    final responsive = ResponsiveUtils(context);
    final isMobile = responsive.isMobile;
    final dialogWidth = isMobile ? double.infinity : 500.0;
    final dialogPadding = isMobile ? 16.0 : 20.0;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 40,
          vertical: 24,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.outline,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(dialogPadding),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.outline,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditMode ? 'Edit Pre-Payment' : 'Add Pre-Payment',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isEditMode
                                ? 'Update payment details'
                                : 'Create a new pre-payment record',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.onSurface,
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _resetForm();
                      },
                    ),
                  ],
                ),
              ),
              // Content
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(dialogPadding),
                  child: isMobile
                      ? _buildMobileFormContent()
                      : _buildDesktopFormContent(),
                ),
              ),
              // Actions
              Container(
                padding: EdgeInsets.all(dialogPadding),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.outline,
                      width: 1,
                    ),
                  ),
                ),
                child: isMobile
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    Navigator.pop(context);
                                    _handleSubmit();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                            ),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    _isEditMode
                                        ? Icons.edit_rounded
                                        : Icons.add_rounded,
                                  ),
                            label: Text(
                              _isEditMode ? 'Update' : 'Create',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _resetForm();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  AppTheme.onSurface.withOpacity(0.6),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _resetForm();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  AppTheme.onSurface.withOpacity(0.6),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    Navigator.pop(context);
                                    _handleSubmit();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    _isEditMode
                                        ? Icons.edit_rounded
                                        : Icons.add_rounded,
                                  ),
                            label: Text(
                              _isEditMode ? 'Update' : 'Create',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Employee Dropdown/Field
        if (_userRole?.toLowerCase() == 'admin')
          _buildFormField(
            child: DropdownButtonFormField<String>(
              value: _selectedUserId,
              onChanged: (value) => setState(() => _selectedUserId = value),
              decoration: _inputDecoration('Select Employee *'),
              items: _employees
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(e.name),
                    ),
                  )
                  .toList(),
            ),
          )
        else
          _buildFormField(
            child: TextFormField(
              readOnly: true,
              initialValue: (_employees
                      .where((e) => e.id == _selectedUserId)
                      .firstOrNull)
                  ?.name ??
                  'Unknown',
              decoration: _inputDecoration('Employee'),
            ),
          ),
        _buildFormField(
          child: TextFormField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(
              'Amount *',
              hint: 'Enter amount',
              prefixIcon: Icons.currency_rupee_rounded,
            ),
          ),
        ),
        _buildFormField(
          child: TextFormField(
            controller: _deductMonthCtrl,
            decoration: _inputDecoration(
              'Deduct Month *',
              hint: 'YYYY-MM',
              prefixIcon: Icons.calendar_month_rounded,
            ),
          ),
        ),
        _buildFormField(
          child: TextFormField(
            controller: _bankNameCtrl,
            decoration: _inputDecoration(
              'Bank Name',
              hint: 'Optional',
              prefixIcon: Icons.account_balance_rounded,
            ),
          ),
        ),
        _buildFormField(
          child: TextFormField(
            controller: _accountNumberCtrl,
            decoration: _inputDecoration(
              'Account Number',
              hint: 'Optional',
              prefixIcon: Icons.numbers_rounded,
            ),
          ),
        ),
        _buildFormField(
          child: TextFormField(
            controller: _descriptionCtrl,
            maxLines: 3,
            decoration: _inputDecoration(
              'Description',
              hint: 'Optional',
              prefixIcon: Icons.description_rounded,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Employee & Amount Row
        Row(
          children: [
            Expanded(
              child: _userRole?.toLowerCase() == 'admin'
                  ? _buildFormField(
                      child: DropdownButtonFormField<String>(
                        value: _selectedUserId,
                        onChanged: (value) =>
                            setState(() => _selectedUserId = value),
                        decoration: _inputDecoration('Select Employee *'),
                        items: _employees
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.id,
                                child: Text(e.name),
                              ),
                            )
                            .toList(),
                      ),
                    )
                  : _buildFormField(
                      child: TextFormField(
                        readOnly: true,
                        initialValue: (_employees
                                .where((e) => e.id == _selectedUserId)
                                .firstOrNull)
                            ?.name ??
                            'Unknown',
                        decoration: _inputDecoration('Employee'),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                child: TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    'Amount *',
                    hint: 'Enter amount',
                    prefixIcon: Icons.currency_rupee_rounded,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Deduct Month & Bank Name Row
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                child: TextFormField(
                  controller: _deductMonthCtrl,
                  decoration: _inputDecoration(
                    'Deduct Month *',
                    hint: 'YYYY-MM',
                    prefixIcon: Icons.calendar_month_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                child: TextFormField(
                  controller: _bankNameCtrl,
                  decoration: _inputDecoration(
                    'Bank Name',
                    hint: 'Optional',
                    prefixIcon: Icons.account_balance_rounded,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Account Number & Description Row
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                child: TextFormField(
                  controller: _accountNumberCtrl,
                  decoration: _inputDecoration(
                    'Account Number',
                    hint: 'Optional',
                    prefixIcon: Icons.numbers_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                child: TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    'Description',
                    hint: 'Optional',
                    prefixIcon: Icons.description_rounded,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormField({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: child,
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(
        color: AppTheme.onSurface.withOpacity(0.4),
        fontSize: 13,
      ),
      labelStyle: TextStyle(
        color: AppTheme.onSurface.withOpacity(0.6),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: AppTheme.onSurface.withOpacity(0.5),
              size: 20,
            )
          : null,
      filled: true,
      fillColor: AppTheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: AppTheme.outline,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: AppTheme.outline,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppTheme.primaryColor,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
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
      case 'pending':
        return const Color(0xFFFFA500); // Orange
      case 'deducted':
        return const Color(0xFF00C853); // Green
      case 'cancelled':
        return const Color(0xFFFF5252); // Red
      default:
        return Colors.grey[600]!;
    }
  }

  String _currency(double amount) =>
      '\u{20B9}${NumberFormat('#,##,###.##').format(amount)}';
}
