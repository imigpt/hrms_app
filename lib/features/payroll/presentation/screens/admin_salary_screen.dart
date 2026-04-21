import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/features/payroll/presentation/providers/payroll_notifier.dart';
import 'package:hrms_app/features/admin/data/services/admin_employees_service.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';
import 'package:hrms_app/core/utils/responsive_utils.dart';

class AdminSalaryScreen extends StatefulWidget {
  final String? token;
  const AdminSalaryScreen({this.token, super.key});

  @override
  State<AdminSalaryScreen> createState() => _AdminSalaryScreenState();
}

class _AdminSalaryScreenState extends State<AdminSalaryScreen> {
  // Theme colors
  static const Color _cardDark = Color(0xFF0A0A0A);
  static const Color _border = Color(0xFF1A1A1A);
  static const Color _textGrey = Color(0xFF9E9E9E);
  static const Color _accentPink = Color(0xFFFF8FA3);

  late String _token;
  List<SalaryRecord> _salaries = [];
  List<dynamic> _employees = [];
  bool _isLoading = true;
  String _activeTab = 'all';
  SalaryRecord? _selectedRecord;
  bool _isEditMode = false;

  // Form controllers
  late TextEditingController _titleCtrl;
  late TextEditingController _basicSalaryCtrl;
  late TextEditingController _effectiveDateCtrl;
  late TextEditingController _notesCtrl;

  String _selectedEmployee = '';
  String _selectedStatus = 'active';
  List<Map<String, dynamic>> _allowances = [];
  List<Map<String, dynamic>> _deductions = [];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _basicSalaryCtrl = TextEditingController();
    _effectiveDateCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _basicSalaryCtrl.dispose();
    _effectiveDateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final token = widget.token ?? await TokenStorageService().getToken();
    if (token == null) return;
    setState(() => _token = token);
    await Future.wait([_fetchSalaries(token), _fetchEmployees(token)]);
  }

  Future<void> _fetchSalaries(String token) async {
    try {
      await context.read<PayrollNotifier>().loadAllSalaries(token);
      final salaries = context.read<PayrollNotifier>().state.allSalaries ?? const [];
      if (mounted) {
        setState(() {
          _salaries = salaries
              .map((e) => SalaryRecord(
                    id: e.id,
                    user: SalaryUser(
                      id: e.user?.id ?? '',
                      name: e.user?.name ?? 'Unknown',
                      position: e.user?.position,
                      department: e.user?.department,
                      email: e.user?.email,
                    ),
                    basicSalary: e.basicSalary,
                    allowances: e.allowances
                        .map((a) =>
                            SalaryComponent(name: a.name, amount: a.amount, type: a.type))
                        .toList(),
                    deductions: e.deductions
                        .map((d) =>
                            SalaryComponent(name: d.name, amount: d.amount, type: d.type))
                        .toList(),
                    status: e.status,
                    effectiveFrom: e.effectiveFrom?.toString(),
                    notes: e.notes,
                    totalAllowances: e.totalAllowances,
                    totalDeductions: e.totalDeductions,
                  ))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching salaries: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchEmployees(String token) async {
    try {
      final result = await AdminEmployeesService.getAllEmployees(token);
      if (mounted) {
        setState(() {
          // Extract employees list from response
          _employees = (result['data'] as List?) ?? [];
        });
      }
    } catch (e) {
      print('Error fetching employees: $e');
    }
  }

  void _resetForm() {
    _titleCtrl.clear();
    _basicSalaryCtrl.clear();
    _effectiveDateCtrl.clear();
    _notesCtrl.clear();
    _selectedEmployee = '';
    _selectedStatus = 'active';
    _allowances = [];
    _deductions = [];
    _isEditMode = false;
    _selectedRecord = null;
  }

  void _openAddDialog() {
    _resetForm();
    _showSalaryDialog();
  }

  void _openEditDialog(SalaryRecord record) {
    _selectedRecord = record;
    _isEditMode = true;
    _basicSalaryCtrl.text = record.basicSalary.toString();
    _effectiveDateCtrl.text = record.effectiveFrom ?? '';
    _notesCtrl.text = record.notes ?? '';
    _selectedStatus = record.status;
    _allowances = record.allowances
        .map((a) => {'name': a.name, 'amount': a.amount, 'type': a.type})
        .toList();
    _deductions = record.deductions
        .map((d) => {'name': d.name, 'amount': d.amount, 'type': d.type})
        .toList();
    _showSalaryDialog();
  }

  void _showSalaryDialog() {
    final responsive = ResponsiveUtils(context);
    final isMobile = responsive.isMobile;
    final dialogWidth = isMobile ? double.infinity : 500.0;
    final dialogPadding = isMobile ? 16.0 : 24.0;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 40,
          vertical: 24,
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: dialogWidth),
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
                            _isEditMode ? 'Edit Salary' : 'Add New Salary',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isEditMode
                                ? 'Update salary details'
                                : 'Create a new salary record',
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
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // Content
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(dialogPadding),
                  child: isMobile
                      ? _buildMobileSalaryForm()
                      : _buildDesktopSalaryForm(),
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
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _submitForm();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              _isEditMode ? 'Update' : 'Create',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppTheme.outline,
                                width: 1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppTheme.onSurface.withOpacity(0.6),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppTheme.outline,
                                  width: 1,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppTheme.onSurface.withOpacity(0.6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _submitForm();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                _isEditMode ? 'Update' : 'Create',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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

  Widget _buildMobileSalaryForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Employee Selection (only for create)
        if (!_isEditMode) ...[
          _buildFormLabel('Employee *'),
          const SizedBox(height: 8),
          _buildDropdownField(
            value: _selectedEmployee.isEmpty ? null : _selectedEmployee,
            items: _employees
                .map<DropdownMenuItem<String>>((e) => DropdownMenuItem(
                      value: e['_id']?.toString() ?? e['id']?.toString() ?? '',
                      child: Text(
                        e['name']?.toString() ?? 'Unknown',
                        style: const TextStyle(color: AppTheme.onSurface),
                      ),
                    ))
                .toList(),
            onChanged: (val) =>
                setState(() => _selectedEmployee = val ?? ''),
            hint: 'Select Employee',
          ),
          const SizedBox(height: 16),
        ],
        // Basic Salary
        _buildFormLabel('Basic Salary *'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _basicSalaryCtrl,
          hintText: '50000',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        // Effective From
        _buildFormLabel('Effective From'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _effectiveDateCtrl,
          hintText: 'YYYY-MM-DD',
          keyboardType: TextInputType.datetime,
        ),
        const SizedBox(height: 16),
        // Status
        _buildFormLabel('Status'),
        const SizedBox(height: 8),
        _buildDropdownField(
          value: _selectedStatus,
          items: const [
            DropdownMenuItem(
              value: 'active',
              child: Text('Active', style: TextStyle(color: AppTheme.onSurface)),
            ),
            DropdownMenuItem(
              value: 'inactive',
              child: Text('Inactive', style: TextStyle(color: AppTheme.onSurface)),
            ),
          ],
          onChanged: (val) =>
              setState(() => _selectedStatus = val ?? 'active'),
        ),
        const SizedBox(height: 16),
        // Notes
        _buildFormLabel('Notes'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _notesCtrl,
          hintText: 'Add any notes...',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildDesktopSalaryForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Employee & Basic Salary Row
        if (!_isEditMode)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Employee *'),
                    const SizedBox(height: 8),
                    _buildDropdownField(
                      value: _selectedEmployee.isEmpty ? null : _selectedEmployee,
                      items: _employees
                          .map<DropdownMenuItem<String>>((e) => DropdownMenuItem(
                                value: e['_id']?.toString() ?? e['id']?.toString() ?? '',
                                child: Text(
                                  e['name']?.toString() ?? 'Unknown',
                                  style: const TextStyle(color: AppTheme.onSurface),
                                ),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedEmployee = val ?? ''),
                      hint: 'Select Employee',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Basic Salary *'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _basicSalaryCtrl,
                      hintText: '50000',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormLabel('Basic Salary *'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _basicSalaryCtrl,
                hintText: '50000',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        const SizedBox(height: 20),
        // Effective From & Status Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormLabel('Effective From'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _effectiveDateCtrl,
                    hintText: 'YYYY-MM-DD',
                    keyboardType: TextInputType.datetime,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormLabel('Status'),
                  const SizedBox(height: 8),
                  _buildDropdownField(
                    value: _selectedStatus,
                    items: const [
                      DropdownMenuItem(
                        value: 'active',
                        child: Text('Active',
                            style: TextStyle(color: AppTheme.onSurface)),
                      ),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('Inactive',
                            style: TextStyle(color: AppTheme.onSurface)),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedStatus = val ?? 'active'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Notes
        _buildFormLabel('Notes'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _notesCtrl,
          hintText: 'Add any notes...',
          maxLines: 3,
        ),
      ],
    );
  }

  void _openViewDialog(SalaryRecord record) {
    _selectedRecord = record;
    _showViewDialog();
  }

  Future<void> _submitForm() async {
    if (_basicSalaryCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter basic salary'),
          backgroundColor: Color(0xFFFF5252),
        ),
      );
      return;
    }

    if (!_isEditMode && _selectedEmployee.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an employee'),
          backgroundColor: Color(0xFFFF5252),
        ),
      );
      return;
    }

    try {
      final payload = {
        'basicSalary': double.parse(_basicSalaryCtrl.text),
        'allowances': _allowances,
        'deductions': _deductions,
        'effectiveFrom': _effectiveDateCtrl.text.isEmpty ? null : _effectiveDateCtrl.text,
        'notes': _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
        'status': _selectedStatus,
      };

      if (_isEditMode && _selectedRecord != null) {
        await context.read<PayrollNotifier>().updateSalary(
          token: _token,
          id: _selectedRecord!.id,
          data: payload,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Salary updated successfully'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      } else if (_selectedEmployee.isNotEmpty) {
        payload['user'] = _selectedEmployee;
        await context.read<PayrollNotifier>().createSalary(
          token: _token,
          data: payload,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Salary created successfully'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      }

      _resetForm();
      await _fetchSalaries(_token);
    } catch (e) {
      String errorMsg = 'Failed to save salary';
      if (e.toString().contains('already exists')) {
        errorMsg = 'Salary record already exists for this employee';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: const Color(0xFFFF5252),
          ),
        );
      }
    }
  }

  Future<void> _deleteSalary(String id) async {
    if (!await _showConfirmDialog('Delete this salary record?')) return;
    try {
      await context.read<PayrollNotifier>().deleteSalary(
        token: _token,
        id: id,
      );
      await _fetchSalaries(_token);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _cardDark,
            title: const Text('Confirm'),
            content: Text(message),
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
        ) ??
        false;
  }

  String _currency(double amount) =>
      '₹${NumberFormat('#,##,###.##').format(amount)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.wallet, color: Color(0xFFFF8FA3), size: 24),
            SizedBox(width: 12),
            Text('Employee Salaries', style: TextStyle(fontSize: 18)),
          ],
        ),
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.all(8),
        //     child: ElevatedButton.icon(
        //       onPressed: _openAddDialog,
        //       icon: const Icon(Icons.add, size: 18),
        //       label: const Text('New Salary'),
        //       style: ElevatedButton.styleFrom(
        //         backgroundColor: const Color(0xFFFF8FA3),
        //         foregroundColor: Colors.black,
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(8),
        //         ),
        //       ),
        //     ),
        //   ),
        // ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tabs
                Container(
                  color: _cardDark,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: ['all', 'active', 'inactive'].map((tab) {
                      bool isActive = _activeTab == tab;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () async {
                            setState(() {
                              _activeTab = tab;
                              _isLoading = true;
                            });
                            await _fetchSalaries(_token);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive ? _accentPink.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isActive ? _accentPink : _border,
                              ),
                            ),
                            child: Text(
                              tab[0].toUpperCase() + tab.substring(1),
                              style: TextStyle(
                                color: isActive ? _accentPink : _textGrey,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Salary List
                Expanded(
                  child: _salaries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wallet_outlined, size: 48, color: _textGrey),
                              const SizedBox(height: 16),
                              const Text('No salary records found'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _salaries.length,
                          itemBuilder: (_, i) => _buildSalaryCard(_salaries[i]),
                        ),
                )
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        backgroundColor: const Color(0xFFFF8FA3),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSalaryCard(SalaryRecord record) {
    final netSalary = record.basicSalary +
        record.totalAllowances -
        record.totalDeductions;
    final employeeName = record.user.name;
    final initials = employeeName.isNotEmpty
        ? employeeName.split(' ').map((e) => e[0]).take(2).join()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Employee info + Actions
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFFF8FA3).withOpacity(0.2),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFFFF8FA3),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employeeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      record.user.position ?? '',
                      style: const TextStyle(color: _textGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: record.status == 'active'
                      ? const Color(0xFF69F0AE).withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  record.status[0].toUpperCase() + record.status.substring(1),
                  style: TextStyle(
                    color: record.status == 'active' ? const Color(0xFF69F0AE) : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Salary info
          Row(
            children: [
              Expanded(
                child: _buildSalaryInfoCell('Basic', record.basicSalary),
              ),
              Expanded(
                child: _buildSalaryInfoCell('Allowance', record.totalAllowances),
              ),
              Expanded(
                child: _buildSalaryInfoCell('Deduction', record.totalDeductions),
              ),
              Expanded(
                child: _buildSalaryInfoCell('Net', netSalary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                onPressed: () => _openViewDialog(record),
                tooltip: 'View',
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _openEditDialog(record),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                onPressed: () => _deleteSalary(record.id),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryInfoCell(String label, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: _textGrey, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          _currency(amount),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.onSurface,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppTheme.onSurface.withOpacity(0.4),
        ),
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required dynamic value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        border: Border.all(color: AppTheme.outline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppTheme.surfaceVariant,
        style: const TextStyle(
          color: AppTheme.onSurface,
          fontSize: 14,
        ),
        iconEnabledColor: AppTheme.onSurface,
        hint: Text(
          hint ?? 'Select option',
          style: TextStyle(color: AppTheme.onSurface.withOpacity(0.4)),
        ),
      ),
    );
  }

  // View Dialog
  void _showViewDialog() {
    if (_selectedRecord == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _cardDark,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Salary Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child:
                          const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const Divider(color: _border),
                const SizedBox(height: 16),
                _buildDetailRow('Employee', _selectedRecord!.user.name),
                _buildDetailRow('Position', _selectedRecord!.user.position ?? '-'),
                _buildDetailRow('Basic Salary',
                    _currency(_selectedRecord!.basicSalary)),
                _buildDetailRow('Total Allowance',
                    _currency(_selectedRecord!.totalAllowances)),
                _buildDetailRow('Total Deduction',
                    _currency(_selectedRecord!.totalDeductions)),
                const Divider(color: _border),
                _buildDetailRow(
                  'Net Salary',
                  _currency(
                    _selectedRecord!.basicSalary +
                        _selectedRecord!.totalAllowances -
                        _selectedRecord!.totalDeductions,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentPink,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
          Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

// Models
class SalaryRecord {
  final String id;
  final SalaryUser user;
  final double basicSalary;
  final List<SalaryComponent> allowances;
  final List<SalaryComponent> deductions;
  final String status;
  final String? effectiveFrom;
  final String? notes;
  final double totalAllowances;
  final double totalDeductions;

  SalaryRecord({
    required this.id,
    required this.user,
    required this.basicSalary,
    required this.allowances,
    required this.deductions,
    required this.status,
    this.effectiveFrom,
    this.notes,
    double? totalAllowances,
    double? totalDeductions,
  })  : totalAllowances =
            totalAllowances ?? allowances.fold(0, (sum, a) => sum + a.amount),
        totalDeductions =
            totalDeductions ?? deductions.fold(0, (sum, d) => sum + d.amount);

  factory SalaryRecord.fromJson(dynamic json) {
    if (json == null) {
      throw Exception('Cannot create SalaryRecord from null');
    }

    final user = json['user'] ?? {};
    final allowances = (json['allowances'] as List?)
            ?.map((a) => SalaryComponent(
                  name: a['name'] ?? '',
                  amount: (a['amount'] as num?)?.toDouble() ?? 0,
                  type: a['type'] ?? 'fixed',
                ))
            .toList() ??
        [];
    final deductions = (json['deductions'] as List?)
            ?.map((d) => SalaryComponent(
                  name: d['name'] ?? '',
                  amount: (d['amount'] as num?)?.toDouble() ?? 0,
                  type: d['type'] ?? 'fixed',
                ))
            .toList() ??
        [];

    return SalaryRecord(
      id: json['_id']?.toString() ?? '',
      user: SalaryUser(
        id: user['_id']?.toString() ?? '',
        name: user['name']?.toString() ?? 'Unknown',
        position: user['position']?.toString(),
        department: user['department']?.toString(),
        email: user['email']?.toString(),
      ),
      basicSalary: (json['basicSalary'] as num?)?.toDouble() ?? 0,
      allowances: allowances,
      deductions: deductions,
      status: json['status']?.toString() ?? 'active',
      effectiveFrom: json['effectiveFrom']?.toString(),
      notes: json['notes']?.toString(),
      totalAllowances: (json['totalAllowances'] as num?)?.toDouble(),
      totalDeductions: (json['totalDeductions'] as num?)?.toDouble(),
    );
  }
}

class SalaryUser {
  final String id;
  final String name;
  final String? position;
  final String? department;
  final String? email;

  SalaryUser({
    required this.id,
    required this.name,
    this.position,
    this.department,
    this.email,
  });
}

class SalaryComponent {
  final String name;
  final double amount;
  final String type;

  SalaryComponent({
    required this.name,
    required this.amount,
    required this.type,
  });
}
