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
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

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
    var filtered = _increments;
    
    if (_selectedFilter != 'all') {
      filtered = filtered
          .where((ip) => ip.type.toLowerCase() == _selectedFilter.toLowerCase())
          .toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((ip) {
        final employeeName = ip.user?.name?.toLowerCase() ?? '';
        final currentDesignation = ip.currentDesignation.toLowerCase();
        final newDesignation = ip.newDesignation?.toLowerCase() ?? '';
        final typeFormatted = _formatType(ip.type).toLowerCase();
        
        return employeeName.contains(query) ||
            currentDesignation.contains(query) ||
            newDesignation.contains(query) ||
            typeFormatted.contains(query);
      }).toList();
    }
    
    return filtered;
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
                          const SizedBox(height: 16),

                          // Search Bar
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by employee, designation, type...',
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.96,
          expand: false,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0A0A0A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8FA3).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isEditMode
                              ? Icons.edit_rounded
                              : Icons.trending_up_rounded,
                          color: const Color(0xFFFF8FA3),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditMode
                                  ? 'Edit Record'
                                  : 'Add Increment / Promotion',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isEditMode
                                  ? 'Update the record details below'
                                  : 'Fill in the details to create a new record',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _resetForm();
                        },
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.grey[900], height: 24),
                // Form content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section: Employee & Type
                          _sectionLabel('Basic Info'),
                          _buildFormField(
                            child: DropdownButtonFormField<String>(
                              value: _selectedUserId,
                              dropdownColor: const Color(0xFF1A1A1A),
                              onChanged: (value) =>
                                  setState(() => _selectedUserId = value),
                              decoration: _inputDecoration(
                                'Employee *',
                                prefixIcon: Icons.person_rounded,
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
                          ),
                          _buildFormField(
                            child: DropdownButtonFormField<String>(
                              value: _selectedType,
                              dropdownColor: const Color(0xFF1A1A1A),
                              onChanged: (value) =>
                                  setState(() => _selectedType = value),
                              decoration: _inputDecoration(
                                'Type *',
                                prefixIcon: Icons.category_rounded,
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
                                  child: Text('Increment / Promotion'),
                                ),
                                DropdownMenuItem(
                                  value: 'decrement',
                                  child: Text('Decrement'),
                                ),
                                DropdownMenuItem(
                                  value: 'decrement-demotion',
                                  child: Text('Decrement / Demotion'),
                                ),
                              ],
                            ),
                          ),
                          // Section: Designation
                          _sectionLabel('Designation'),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFormField(
                                  child: TextFormField(
                                    controller: _currentDesignationCtrl,
                                    decoration: _inputDecoration(
                                      'Current *',
                                      prefixIcon: Icons.work_rounded,
                                    ),
                                    validator: (v) =>
                                        v?.isEmpty ?? true ? 'Required' : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildFormField(
                                  child: TextFormField(
                                    controller: _newDesignationCtrl,
                                    decoration: _inputDecoration(
                                      'New',
                                      prefixIcon: Icons.work_outline_rounded,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Section: Salary
                          _sectionLabel('Salary (Annual CTC)'),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFormField(
                                  child: TextFormField(
                                    controller: _prevCTCCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDecoration(
                                      'Previous ₹',
                                      prefixIcon: Icons.currency_rupee_rounded,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildFormField(
                                  child: TextFormField(
                                    controller: _newCTCCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDecoration(
                                      'New ₹',
                                      prefixIcon: Icons.trending_up_rounded,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Section: Date
                          _sectionLabel('Schedule'),
                          _buildFormField(
                            child: TextFormField(
                              controller: _effectiveDateCtrl,
                              readOnly: true,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  _effectiveDateCtrl.text =
                                      DateFormat('yyyy-MM-dd').format(date);
                                }
                              },
                              decoration: _inputDecoration(
                                'Effective Date *',
                                prefixIcon: Icons.calendar_month_rounded,
                              ),
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          // Section: Notes
                          _sectionLabel('Notes'),
                          _buildFormField(
                            child: TextFormField(
                              controller: _reasonCtrl,
                              maxLines: 2,
                              decoration: _inputDecoration(
                                'Reason',
                                prefixIcon: Icons.description_rounded,
                              ),
                            ),
                          ),
                          _buildFormField(
                            child: TextFormField(
                              controller: _descriptionCtrl,
                              maxLines: 2,
                              decoration: _inputDecoration(
                                'Description',
                                prefixIcon: Icons.note_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Footer actions
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    12 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D0D),
                    border: Border(
                      top: BorderSide(color: Colors.grey[900]!, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _resetForm();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[400],
                            side: BorderSide(color: Colors.grey[800]!),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8FA3),
                            foregroundColor: Colors.black,
                            disabledBackgroundColor:
                                const Color(0xFFFF8FA3).withOpacity(0.5),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                )
                              : Icon(
                                  _isEditMode
                                      ? Icons.check_rounded
                                      : Icons.add_rounded,
                                  size: 18,
                                ),
                          label: Text(
                            _isEditMode ? 'Update Record' : 'Create Record',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
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
        );
      },
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(color: Colors.grey[900], height: 1),
          ),
        ],
      ),
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
      hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
      labelStyle: TextStyle(
        color: Colors.grey[500],
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: Colors.grey[700],
              size: 20,
            )
          : null,
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFFF8FA3),
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }
}
