import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payroll_model.dart';
import '../models/profile_model.dart';
import '../services/payroll_service.dart';
import '../services/token_storage_service.dart';
import '../services/admin_employees_service.dart';

class IncrementPromotionScreen extends StatefulWidget {
  const IncrementPromotionScreen({super.key});

  @override
  State<IncrementPromotionScreen> createState() =>
      _IncrementPromotionScreenState();
}

class _IncrementPromotionScreenState extends State<IncrementPromotionScreen> {
  String? _token;
  String? _userRole;
  List<IncrementPromotion> _increments = [];
  List<ProfileUser> _employees = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _selectedFilter = 'all';
  Map<String, bool> _showCTC = {};

  // Form state
  bool _isDialogOpen = false;
  bool _isEditMode = false;
  IncrementPromotion? _selectedRecord;

  final _formKey = GlobalKey<FormState>();
  String? _selectedUserId;
  String? _selectedType;
  final _currentDesignationCtrl = TextEditingController();
  final _newDesignationCtrl = TextEditingController();
  final _prevCTCCtrl = TextEditingController();
  final _newCTCCtrl = TextEditingController();
  final _effectiveDateCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _currentDesignationCtrl.dispose();
    _newDesignationCtrl.dispose();
    _prevCTCCtrl.dispose();
    _newCTCCtrl.dispose();
    _effectiveDateCtrl.dispose();
    _reasonCtrl.dispose();
    _descriptionCtrl.dispose();
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
      _fetchIncrements(token),
      if (role?.toLowerCase() == 'admin') _fetchEmployees(token),
    ]);
  }

  Future<void> _fetchIncrements(String token) async {
    try {
      debugPrint('🔄 Fetching increments...');
      final res = await PayrollService.getIncrements(token: token);
      debugPrint('✅ Increments fetched: ${res.data.length} records');
      debugPrint(
        '📊 Response data: ${res.data.map((e) => '${e.id} - ${e.user?.name ?? "Unknown"}').join(", ")}',
      );
      if (mounted) {
        setState(() {
          _increments = res.data;
          _isLoading = false;
        });
        debugPrint('✓ UI updated with ${_increments.length} increments');
      }
    } catch (e) {
      debugPrint('❌ Increments fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchEmployees(String token) async {
    try {
      debugPrint('🔄 Fetching employees...');
      final res = await AdminEmployeesService.getAllEmployees(token);
      debugPrint(
        '📦 Response received: ${res.toString().substring(0, 200)}...',
      );
      if (mounted && res['data'] != null) {
        final List<dynamic> employeeList = res['data'] is List
            ? res['data']
            : (res['data']['employees'] ?? []);
        debugPrint('✅ Employees parsed: ${employeeList.length} employees');
        setState(() {
          _employees = employeeList
              .whereType<Map<String, dynamic>>()
              .map((e) => ProfileUser.fromJson(e))
              .toList();
        });
        debugPrint('✓ UI updated with ${_employees.length} employees');
      } else {
        debugPrint('⚠ No employee data in response');
      }
    } catch (e) {
      debugPrint('❌ Employees fetch error: $e');
    }
  }

  List<IncrementPromotion> _getFilteredIncrements() {
    if (_selectedFilter == 'all') return _increments;
    return _increments
        .where((ip) => ip.type.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  String _formatType(String type) {
    return type
        .split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' / ');
  }

  String _currency(double? amount) {
    if (amount == null) return '₹0';
    return '₹${NumberFormat('#,##,###.##').format(amount)}';
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'increment':
        return Colors.green.shade600;
      case 'promotion':
        return Colors.blue.shade600;
      case 'increment-promotion':
        return Colors.purple.shade600;
      case 'decrement':
        return Colors.orange.shade600;
      case 'decrement-demotion':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  void _resetForm() {
    _selectedUserId = null;
    _selectedType = null;
    _currentDesignationCtrl.clear();
    _newDesignationCtrl.clear();
    _prevCTCCtrl.clear();
    _newCTCCtrl.clear();
    _effectiveDateCtrl.clear();
    _reasonCtrl.clear();
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

  void _openEditDialog(IncrementPromotion record) {
    _selectedRecord = record;
    _selectedUserId = record.user?.id;
    _selectedType = record.type;
    _currentDesignationCtrl.text = record.currentDesignation;
    _newDesignationCtrl.text = record.newDesignation ?? '';
    _prevCTCCtrl.text = record.previousCTC?.toString() ?? '';
    _newCTCCtrl.text = record.newCTC?.toString() ?? '';
    _effectiveDateCtrl.text = record.effectiveDate != null
        ? DateFormat('yyyy-MM-dd').format(record.effectiveDate!)
        : '';
    _reasonCtrl.text = record.reason ?? '';
    _descriptionCtrl.text = record.description ?? '';

    setState(() {
      _isDialogOpen = true;
      _isEditMode = true;
    });
    _showFormDialog();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedUserId == null || _selectedType == null) {
      _showSnackBar('Please select employee and type', Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'user': _selectedUserId,
        'type': _selectedType,
        'currentDesignation': _currentDesignationCtrl.text.trim(),
        'newDesignation': _newDesignationCtrl.text.trim().isEmpty
            ? null
            : _newDesignationCtrl.text.trim(),
        'previousCTC': _prevCTCCtrl.text.isEmpty
            ? null
            : double.parse(_prevCTCCtrl.text),
        'newCTC': _newCTCCtrl.text.isEmpty
            ? null
            : double.parse(_newCTCCtrl.text),
        'effectiveDate': _effectiveDateCtrl.text,
        'reason': _reasonCtrl.text.trim().isEmpty
            ? null
            : _reasonCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
      };

      if (_isEditMode && _selectedRecord != null) {
        await PayrollService.updateIncrement(
          token: _token!,
          id: _selectedRecord!.id,
          data: payload,
        );
        _showSnackBar('Record updated successfully', Colors.green);
      } else {
        await PayrollService.createIncrement(token: _token!, data: payload);
        _showSnackBar('Record created successfully', Colors.green);
      }

      if (mounted) Navigator.pop(context);
      setState(() => _isDialogOpen = false);
      await _fetchIncrements(_token!);
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleDelete(String id) async {
    final confirm = await _showConfirmDialog(
      'Delete Record',
      'Are you sure you want to delete this record?',
    );
    if (!confirm) return;

    try {
      await PayrollService.deleteIncrement(token: _token!, id: id);
      _showSnackBar('Record deleted successfully', Colors.green);
      await _fetchIncrements(_token!);
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    }
  }

  void _toggleCTC(String id) {
    setState(() => _showCTC[id] = !(_showCTC[id] ?? false));
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
    final filtered = _getFilteredIncrements();

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: const Text(
          'Increment / Promotion',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_userRole?.toLowerCase() == 'admin')
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
                                    ? 'Manage increments and promotions'
                                    : 'Your increment and promotion history',
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
                          const SizedBox(height: 20),

                          // Filter Tabs
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('all', 'All'),
                                _buildFilterChip('increment', 'Increment'),
                                _buildFilterChip('promotion', 'Promotion'),
                                _buildFilterChip(
                                  'increment-promotion',
                                  'Inc/Promo',
                                ),
                                _buildFilterChip('decrement', 'Decrement'),
                                _buildFilterChip(
                                  'decrement-demotion',
                                  'Dec/Demotion',
                                ),
                              ],
                            ),
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
                                  Icons.trending_up,
                                  size: 64,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No records found',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isAdmin
                                      ? 'Create your first increment or promotion record'
                                      : 'No increment or promotion records yet',
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
                                _buildIncrementCard(filtered[index], isAdmin),
                            childCount: filtered.length,
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[900] : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[800]!,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue[200] : Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(List<IncrementPromotion> records) {
    final totalAmount = records.fold<double>(
      0,
      (sum, ip) => sum + (ip.newCTC ?? 0),
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
          _buildStatItem('Total Records', '${records.length}'),
          Container(width: 1, height: 40, color: Colors.grey[800]),
          _buildStatItem('New Amount', _currency(totalAmount)),
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

  Widget _buildIncrementCard(IncrementPromotion increment, bool isAdmin) {
    final typeColor = _getTypeColor(increment.type);
    final showAmount = _showCTC[increment.id] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => _showDetailsModal(increment),
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
              // Top row with name and type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          increment.user?.name ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          increment.user?.department ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: typeColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      _formatType(increment.type),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: typeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Middle row with designations
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          increment.currentDesignation,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'New',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          increment.newDesignation ?? '—',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bottom row with CTC and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Effective Date',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      Text(
                        increment.effectiveDate != null
                            ? DateFormat(
                                'dd MMM yyyy',
                              ).format(increment.effectiveDate!)
                            : 'N/A',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _toggleCTC(increment.id),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'New CTC',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          showAmount
                              ? _currency(
                                  increment.newCTC ?? increment.previousCTC,
                                )
                              : '₹ ••••••',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF8FA3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons for admin
                  if (isAdmin)
                    PopupMenuButton(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openEditDialog(increment);
                        } else if (value == 'delete') {
                          _handleDelete(increment.id);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailsModal(IncrementPromotion increment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                _detailItem('Employee', increment.user?.name ?? 'N/A'),
                _detailItem('Type', _formatType(increment.type)),
                _detailItem(
                  'Effective Date',
                  increment.effectiveDate != null
                      ? DateFormat(
                          'dd MMM yyyy',
                        ).format(increment.effectiveDate!)
                      : 'N/A',
                ),
                _detailItem(
                  'Current Designation',
                  increment.currentDesignation,
                ),
                _detailItem(
                  'New Designation',
                  increment.newDesignation ?? 'N/A',
                ),
                _detailItem(
                  'Previous Salary',
                  _currency(increment.previousCTC),
                ),
                _detailItem('New Salary', _currency(increment.newCTC)),
                if (increment.reason != null && increment.reason!.isNotEmpty)
                  _detailItem('Reason', increment.reason!),
                if (increment.description != null &&
                    increment.description!.isNotEmpty)
                  _detailItem('Description', increment.description!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showFormDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isEditMode ? 'Edit Record' : 'Add Increment / Promotion',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Employee dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedUserId,
                    onChanged: (value) =>
                        setState(() => _selectedUserId = value),
                    decoration: InputDecoration(
                      labelText: 'Employee *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0A0A0A),
                    ),
                    items: _employees
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.name),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),

                  // Type dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    onChanged: (value) => setState(() => _selectedType = value),
                    decoration: InputDecoration(
                      labelText: 'Type *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0A0A0A),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'increment',
                        child: Text('Increment'),
                      ),
                      DropdownMenuItem(
                        value: 'promotion',
                        child: Text('Promotion'),
                      ),
                      DropdownMenuItem(
                        value: 'increment-promotion',
                        child: Text('Increment/Promotion'),
                      ),
                      DropdownMenuItem(
                        value: 'decrement',
                        child: Text('Decrement'),
                      ),
                      DropdownMenuItem(
                        value: 'decrement-demotion',
                        child: Text('Decrement/Demotion'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Current Designation
                  TextFormField(
                    controller: _currentDesignationCtrl,
                    decoration: InputDecoration(
                      labelText: 'Current Designation *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0A0A0A),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // New Designation
                  TextFormField(
                    controller: _newDesignationCtrl,
                    decoration: InputDecoration(
                      labelText: 'New Designation',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0A0A0A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Previous CTC
                  TextFormField(
                    controller: _prevCTCCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Previous Annual CTC (₹)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0A0A0A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // New CTC
                  TextFormField(
                    controller: _newCTCCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'New Annual CTC (₹)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0A0A0A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Effective Date
                  TextFormField(
                    controller: _effectiveDateCtrl,
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        _effectiveDateCtrl.text = DateFormat(
                          'yyyy-MM-dd',
                        ).format(date);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Effective Date *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0A0A0A),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Reason
                  TextFormField(
                    controller: _reasonCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0A0A0A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0A0A0A),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8FA3),
                            foregroundColor: Colors.black,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_isEditMode ? 'Update' : 'Create'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
