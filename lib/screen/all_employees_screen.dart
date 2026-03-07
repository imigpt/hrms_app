import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/admin_employees_service.dart';
import '../services/chat_service.dart';
import '../services/token_storage_service.dart';
import '../models/chat_room_model.dart';
import '../utils/responsive_utils.dart';
import 'package:hrms_app/theme/app_theme.dart';
import 'chat_screen.dart';

class AllEmployeesScreen extends StatefulWidget {
  final String? token;

  const AllEmployeesScreen({super.key, this.token});

  @override
  State<AllEmployeesScreen> createState() => _AllEmployeesScreenState();
}

class _AllEmployeesScreenState extends State<AllEmployeesScreen> {
  // Theme (use centralized AppTheme values)
  static const Color _bg = AppTheme.background;
  static const Color _card = AppTheme.cardColor;
  static const Color _input = AppTheme.surface;
  static const Color _border = AppTheme.outline;
  static const Color _pink = AppTheme.primaryColor;
  static const Color _green = AppTheme.successColor;
  static const Color _yellow = AppTheme.warningColor;
  static const Color _red = AppTheme.errorColor;
  static const Color _textGrey = Color(0xFF9E9E9E);
  static const Color _textLight = AppTheme.onSurface;
  static const Color _tableHeader = AppTheme.surfaceVariant;

  // State
  bool _isLoading = true;
  String? _error;
  List<dynamic> _allEmployees = [];
  List<dynamic> _filtered = [];

  String _searchQuery = '';
  String _selectedCompanyId = '';
  String _selectedDepartment = '';
  String _selectedStatus = '';

  List<Map<String, dynamic>> _companies = [];
  List<String> _departments = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Data loading
  Future<void> _loadEmployees() async {
    if (widget.token == null || widget.token!.isEmpty) {
      setState(() {
        _error = 'No authentication token provided';
        _isLoading = false;
      });
      return;
    }
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final result = await AdminEmployeesService.getAllEmployees(widget.token!);
      if (!mounted) return;
      if (result['success'] == true) {
        final data = (result['data'] as List<dynamic>?) ?? [];
        final seenCompanies = <String>{};
        final companiesList = <Map<String, dynamic>>[];
        final deptSet = <String>{};

        for (final emp in data) {
          final compObj = emp['company'];
          if (compObj is Map) {
            final id = compObj['_id']?.toString() ?? '';
            final name = compObj['name']?.toString() ?? '';
            if (id.isNotEmpty && !seenCompanies.contains(id)) {
              seenCompanies.add(id);
              companiesList.add({'_id': id, 'name': name});
            }
          }
          final dept = emp['department']?.toString() ?? '';
          if (dept.isNotEmpty) deptSet.add(dept);
        }

        setState(() {
          _allEmployees = data;
          _companies = companiesList;
          _departments = deptSet.toList()..sort();
          _isLoading = false;
        });
        _applyFilters();
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load employees';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    final q = _searchQuery.toLowerCase();
    setState(() {
      _filtered = _allEmployees.where((emp) {
        if (_selectedCompanyId.isNotEmpty) {
          final compId = (emp['company'] is Map)
              ? (emp['company']['_id']?.toString() ?? '')
              : '';
          if (compId != _selectedCompanyId) return false;
        }
        if (_selectedDepartment.isNotEmpty) {
          if ((emp['department']?.toString() ?? '') != _selectedDepartment)
            return false;
        }
        if (_selectedStatus.isNotEmpty) {
          if ((emp['status']?.toString() ?? '') != _selectedStatus)
            return false;
        }
        if (q.isNotEmpty) {
          final name = (emp['name'] ?? '').toString().toLowerCase();
          final email = (emp['email'] ?? '').toString().toLowerCase();
          final empId = (emp['employeeId'] ?? '').toString().toLowerCase();
          final phone = (emp['phone'] ?? '').toString().toLowerCase();
          final dept = (emp['department'] ?? '').toString().toLowerCase();
          final pos = (emp['position'] ?? '').toString().toLowerCase();
          if (!name.contains(q) &&
              !email.contains(q) &&
              !empId.contains(q) &&
              !phone.contains(q) &&
              !dept.contains(q) &&
              !pos.contains(q))
            return false;
        }
        return true;
      }).toList();
    });
  }

  // Stats
  int get _totalCount => _allEmployees.length;
  int get _activeCount =>
      _allEmployees.where((e) => e['status'] == 'active').length;
  int get _onLeaveCount =>
      _allEmployees.where((e) => e['status'] == 'on-leave').length;
  int get _inactiveCount =>
      _allEmployees.where((e) => e['status'] == 'inactive').length;

  // Helpers
  String _formatDate(dynamic d) {
    if (d == null) return '-';
    try {
      return DateFormat('d/M/yyyy').format(DateTime.parse(d.toString()));
    } catch (_) {
      return '-';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFFAF52DE),
      Color(0xFF007AFF),
      Color(0xFF34C759),
      Color(0xFFFF9500),
      Color(0xFFFF3B30),
      Color(0xFF5AC8FA),
      Color(0xFFFF2D55),
      Color(0xFF4CD964),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status.toLowerCase()) {
      case 'active':
        bg = _green.withOpacity(0.15);
        fg = _green;
        label = 'Active';
        break;
      case 'on-leave':
        bg = _yellow.withOpacity(0.15);
        fg = _yellow;
        label = 'On Leave';
        break;
      case 'inactive':
        bg = _red.withOpacity(0.15);
        fg = _red;
        label = 'Inactive';
        break;
      default:
        bg = _textGrey.withOpacity(0.15);
        fg = _textGrey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Build
  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final isMobile = responsive.isMobile;

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(isMobile),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _pink))
            : _error != null
            ? _buildError()
            : _buildBody(isMobile, responsive),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return AppBar(
      backgroundColor: _card,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'All Employees',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        if (isMobile)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _addEmployeeBtn(compact: true),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _addEmployeeBtn(compact: false),
          ),
      ],
    );
  }

  Widget _buildBody(bool isMobile, ResponsiveUtils responsive) {
    return RefreshIndicator(
      color: _pink,
      backgroundColor: _card,
      onRefresh: _loadEmployees,
      child: CustomScrollView(
        slivers: [
          // Desktop subtitle
          if (!isMobile)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 4),
                child: Text(
                  'View and manage employees across all companies',
                  style: TextStyle(color: _textGrey, fontSize: 13),
                ),
              ),
            ),

          // Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                16,
                isMobile ? 16 : 24,
                16,
              ),
              child: _buildStatsRow(isMobile),
            ),
          ),

          // Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              child: isMobile ? _buildMobileFilters() : _buildDesktopFilters(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Results count
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 4,
              ),
              child: Text(
                'Showing ${_filtered.length} of $_totalCount employees',
                style: const TextStyle(color: _textGrey, fontSize: 12),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // List / Table
          if (_filtered.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else if (isMobile)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildMobileCard(_filtered[i]),
                  childCount: _filtered.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(child: _buildTable()),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // Add Employee button
  Widget _addEmployeeBtn({required bool compact}) {
    return ElevatedButton.icon(
      onPressed: () => _showAddEmployeeDialog(context),
      icon: Icon(Icons.add, size: compact ? 16 : 18, color: Colors.black),
      label: Text(
        compact ? 'Add' : 'Add Employee',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: compact ? 13 : 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _pink,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 18,
          vertical: compact ? 8 : 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  // Stats row
  Widget _buildStatsRow(bool isMobile) {
    final stats = [
      {
        'label': 'Total Employees',
        'value': _totalCount,
        'icon': Icons.people_rounded,
        'iconColor': _pink,
        'iconBg': _pink.withOpacity(0.15),
      },
      {
        'label': 'Active',
        'value': _activeCount,
        'icon': Icons.person_rounded,
        'iconColor': _green,
        'iconBg': _green.withOpacity(0.15),
      },
      {
        'label': 'On Leave',
        'value': _onLeaveCount,
        'icon': Icons.person_rounded,
        'iconColor': _yellow,
        'iconBg': _yellow.withOpacity(0.15),
      },
      {
        'label': 'Inactive',
        'value': _inactiveCount,
        'icon': Icons.person_off_rounded,
        'iconColor': _red,
        'iconBg': _red.withOpacity(0.15),
      },
    ];

    if (isMobile) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          // Slightly taller tiles to avoid bottom overflow on small screens
          childAspectRatio: 1.9,
        ),
        itemCount: stats.length,
        itemBuilder: (_, i) => _statsCard(stats[i]),
      );
    }

    return Row(
      children: stats.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return Expanded(
          child: Padding(
            padding: i < stats.length - 1
                ? const EdgeInsets.only(right: 14)
                : EdgeInsets.zero,
            child: _statsCard(s),
          ),
        );
      }).toList(),
    );
  }

  Widget _statsCard(Map<String, dynamic> stat) {
    final accent = stat['iconColor'] as Color;
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      // Use IntrinsicHeight so the left accent strip can stretch to the
      // intrinsic height of the content without causing overflow.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent strip
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Icon bubble (centered vertically)
            Container(
              width: 44,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(stat['icon'] as IconData, color: accent, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                // Slightly reduced vertical padding to avoid overflow
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${stat['value']}',
                      style: TextStyle(
                        color: accent,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stat['label'] as String,
                      style: const TextStyle(
                        color: _textGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile filters
  Widget _buildMobileFilters() {
    return Column(
      children: [
        _searchField(),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _companyDropdown()),
            const SizedBox(width: 8),
            Expanded(child: _statusDropdown()),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: _departmentDropdown()),
      ],
    );
  }

  // Desktop filters
  Widget _buildDesktopFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _searchField()),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _companyDropdown()),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _departmentDropdown()),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _statusDropdown()),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: _input,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onChanged: (v) {
          setState(() => _searchQuery = v);
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: 'Search by name, email, ID, department...',
          hintStyle: TextStyle(color: _textGrey.withOpacity(0.5), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _textGrey,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _textGrey,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _applyFilters();
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _companyDropdown() {
    // Hardcoded companies with their display labels
    final companies = [
      {'id': '', 'name': 'All Companies'},
      {'id': 'aselea', 'name': 'Aselea Technologies'},
      {'id': 'innovation', 'name': 'Innovation Corp'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _dropdownField<String>(
          value: _selectedCompanyId.isEmpty ? '' : _selectedCompanyId,
          items: companies.map((c) => c['id'].toString()).toList(),
          labels: companies.map((c) => c['name'].toString()).toList(),
          onChanged: (v) {
            setState(() => _selectedCompanyId = v ?? '');
            _applyFilters();
          },
        ),
      ],
    );
  }

  Widget _departmentDropdown() {
    return _dropdownField<String>(
      value: _selectedDepartment.isEmpty ? '' : _selectedDepartment,
      items: ['', ..._departments],
      labels: ['All Departments', ..._departments],
      onChanged: (v) {
        setState(() => _selectedDepartment = v ?? '');
        _applyFilters();
      },
    );
  }

  Widget _statusDropdown() {
    return _dropdownField<String>(
      value: _selectedStatus.isEmpty ? '' : _selectedStatus,
      items: const ['', 'active', 'on-leave', 'inactive'],
      labels: const ['All Status', 'Active', 'On Leave', 'Inactive'],
      onChanged: (v) {
        setState(() => _selectedStatus = v ?? '');
        _applyFilters();
      },
    );
  }

  Widget _dropdownField<T>({
    required T value,
    required List<T> items,
    required List<String> labels,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _input,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          onChanged: onChanged,
          items: items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final label = labels[i];
            final isSelected = item == value;
            return DropdownMenuItem<T>(
              value: item,
              child: Row(
                children: [
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.check_rounded, color: _pink, size: 14),
                    )
                  else
                    const SizedBox(width: 22),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? _pink : _textLight,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          dropdownColor: const Color(0xFF1A1A1A),
          iconEnabledColor: _textGrey,
          style: const TextStyle(color: _textLight, fontSize: 13),
          isExpanded: true,
        ),
      ),
    );
  }

  // Desktop table
  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          const Divider(color: _border, height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filtered.length,
            separatorBuilder: (_, __) =>
                const Divider(color: _border, height: 1),
            itemBuilder: (_, i) => _buildTableRow(_filtered[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    const style = TextStyle(
      color: _textGrey,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
    return Container(
      color: _tableHeader,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: const [
          Expanded(flex: 5, child: Text('EMPLOYEE', style: style)),
          Expanded(flex: 5, child: Text('CONTACT', style: style)),
          Expanded(flex: 3, child: Text('COMPANY', style: style)),
          Expanded(flex: 3, child: Text('DEPARTMENT', style: style)),
          Expanded(flex: 3, child: Text('POSITION', style: style)),
          Expanded(flex: 3, child: Text('JOIN DATE', style: style)),
          Expanded(flex: 2, child: Text('STATUS', style: style)),
          SizedBox(width: 40, child: Text('', style: style)),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> emp) {
    final name = emp['name']?.toString() ?? 'Unknown';
    final empId = emp['employeeId']?.toString() ?? '';
    final email = emp['email']?.toString() ?? '-';
    final phone = emp['phone']?.toString() ?? '-';
    final companyName = (emp['company'] is Map)
        ? (emp['company']['name']?.toString() ?? 'N/A')
        : 'N/A';
    final dept = emp['department']?.toString() ?? '-';
    final position = emp['position']?.toString() ?? '-';
    final joinDate = _formatDate(emp['joinDate']);
    final status = emp['status']?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Employee
          Expanded(
            flex: 5,
            child: Row(
              children: [
                _avatar(name, radius: 18, photoUrl: _empPhotoUrl(emp)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (empId.isNotEmpty)
                        Text(
                          empId,
                          style: const TextStyle(
                            color: _textGrey,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Contact
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      color: _textGrey,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        email,
                        style: const TextStyle(color: _textLight, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      color: _textGrey,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        phone,
                        style: const TextStyle(color: _textLight, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Company
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const Icon(Icons.business_rounded, color: _textGrey, size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    companyName,
                    style: const TextStyle(color: _textLight, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Dept
          Expanded(
            flex: 3,
            child: Text(
              dept,
              style: const TextStyle(color: _textLight, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Position
          Expanded(
            flex: 3,
            child: Text(
              position,
              style: const TextStyle(color: _textLight, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Join date
          Expanded(
            flex: 3,
            child: Text(
              joinDate,
              style: const TextStyle(color: _textLight, fontSize: 12),
            ),
          ),
          // Status
          Expanded(flex: 2, child: _statusBadge(status)),
          // Action
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(
                Icons.visibility_rounded,
                color: _textGrey,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              onPressed: () => _showDetailsSheet(context, emp),
              tooltip: 'View details',
            ),
          ),
        ],
      ),
    );
  }

  // Mobile card
  Widget _buildMobileCard(Map<String, dynamic> emp) {
    final name = emp['name']?.toString() ?? 'Unknown';
    final empId = emp['employeeId']?.toString() ?? '';
    final email = emp['email']?.toString() ?? '-';
    final phone = emp['phone']?.toString() ?? '-';
    final companyName = (emp['company'] is Map)
        ? (emp['company']['name']?.toString() ?? 'N/A')
        : 'N/A';
    final dept = emp['department']?.toString() ?? '-';
    final position = emp['position']?.toString() ?? '-';
    final joinDate = _formatDate(emp['joinDate']);
    final status = emp['status']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetailsSheet(context, emp),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top
              Row(
                children: [
                  _avatar(name, radius: 22, photoUrl: _empPhotoUrl(emp)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (empId.isNotEmpty)
                          Text(
                            empId,
                            style: const TextStyle(
                              color: _textGrey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: _border, height: 1),
              const SizedBox(height: 12),
              // Details
              _cardRow(Icons.email_outlined, email),
              const SizedBox(height: 6),
              _cardRow(Icons.phone_outlined, phone),
              const SizedBox(height: 6),
              _cardRow(Icons.business_rounded, companyName),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: _cardRow(Icons.workspaces_rounded, dept)),
                  Expanded(
                    child: _cardRow(Icons.work_outline_rounded, position),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _cardRow(Icons.calendar_today_rounded, 'Joined: $joinDate'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: _textGrey, size: 13),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _textLight, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Detail bottom sheet
  void _showDetailsSheet(BuildContext context, Map<String, dynamic> emp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EmployeeDetailPage(employee: emp, token: widget.token),
      ),
    );
  }

  // Profile photo URL extractor
  String _empPhotoUrl(Map<String, dynamic> emp) {
    final raw = emp['profilePhoto'];
    if (raw is String && (raw as String).isNotEmpty) return raw;
    if (raw is Map<String, dynamic>) {
      return (raw as Map<String, dynamic>)['url']?.toString() ?? '';
    }
    return '';
  }

  // Avatar
  Widget _avatar(String name, {double radius = 20, String photoUrl = ''}) {
    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: _avatarColor(name),
        backgroundImage: NetworkImage(photoUrl),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _avatarColor(name),
      child: Text(
        _initials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.65,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Empty / Error
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: _textGrey,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No employees found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search or filters',
              style: TextStyle(color: _textGrey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedCompanyId = '';
                  _selectedDepartment = '';
                  _selectedStatus = '';
                });
                _applyFilters();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Clear Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _pink,
                side: const BorderSide(color: _pink),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: _red,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load employees',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textGrey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadEmployees,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 16,
                color: Colors.black,
              ),
              label: const Text('Retry', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _pink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add employee dialog
  void _showAddEmployeeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddEmployeeDialog(
        token: widget.token,
        companies: _companies,
        departments: _departments,
        onEmployeeAdded: _loadEmployees,
      ),
    );
  }
}

/// Add Employee Dialog Widget
class _AddEmployeeDialog extends StatefulWidget {
  final String? token;
  final List<Map<String, dynamic>> companies;
  final List<String> departments;
  final VoidCallback onEmployeeAdded;

  const _AddEmployeeDialog({
    required this.token,
    required this.companies,
    required this.departments,
    required this.onEmployeeAdded,
  });

  @override
  State<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<_AddEmployeeDialog> {
  // Theme colors
  static const Color _bg = Color(0xFF080808);
  static const Color _section = Color(0xFF181818);
  static const Color _input = Color(0xFF1E1E1E);
  static const Color _border = Color(0xFF2A2A2A);
  static const Color _pink = Color(0xFFFF8FA3);
  static const Color _blue = Color(0xFF448AFF);
  static const Color _green = Color(0xFF00C853);
  static const Color _textGrey = Color(0xFF9E9E9E);
  static const Color _textLight = Color(0xFFE0E0E0);
  static const Color _red = Color(0xFFEF5350);

  /// Form field state
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;
  String _fullName = '';
  String _employeeId = '';
  String _password = '';
  String _email = '';
  String _phone = '';
  String _dob = '';
  String _address = '';
  String _selectedDepartment = '';
  String _position = '';
  String _joinDate = '';

  bool _isSubmitting = false;
  String? _errorMessage;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _pink.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: _pink,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Employee',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Fill in the details to create a new employee account',
                        style: TextStyle(color: _textGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: _textGrey,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _border),
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Profile Photo ─────────────────────────────────
                    _buildPhotoSection(),
                    const SizedBox(height: 22),

                    // ── SECTION: Account Info ─────────────────────────
                    _sectionHeader(
                      Icons.lock_rounded,
                      'Account Information',
                      _pink,
                    ),
                    const SizedBox(height: 12),
                    _formCard(
                      children: [
                        _buildTextField(
                          label: 'Employee ID',
                          hint: 'EMP-001 or john.doe',
                          subtitle: 'Used as username for login',
                          icon: Icons.badge_outlined,
                          isRequired: true,
                          onChanged: (v) => _employeeId = v,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          label: 'Password',
                          hint: 'Initial login password',
                          icon: Icons.lock_outline_rounded,
                          isRequired: true,
                          isPassword: true,
                          onChanged: (v) => _password = v,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── SECTION: Personal Info ────────────────────────
                    _sectionHeader(
                      Icons.person_rounded,
                      'Personal Information',
                      _blue,
                    ),
                    const SizedBox(height: 12),
                    _formCard(
                      children: [
                        _buildTextField(
                          label: 'Full Name',
                          hint: 'John Doe',
                          icon: Icons.person_outline_rounded,
                          isRequired: true,
                          onChanged: (v) => _fullName = v,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Email',
                                hint: 'employee@company.com',
                                icon: Icons.email_outlined,
                                isRequired: true,
                                isEmail: true,
                                onChanged: (v) => _email = v,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                label: 'Phone',
                                hint: '+1 (555) 000-0000',
                                icon: Icons.phone_outlined,
                                isRequired: true,
                                onChanged: (v) => _phone = v,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildDateField(
                          label: 'Date of Birth',
                          hint: 'Select date of birth',
                          icon: Icons.cake_outlined,
                          value: _dob,
                          onChanged: (v) => setState(() => _dob = v),
                        ),
                        const SizedBox(height: 14),
                        _buildTextAreaField(
                          label: 'Address',
                          hint: 'Full home address',
                          icon: Icons.location_on_outlined,
                          onChanged: (v) => _address = v,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── SECTION: Work Info ────────────────────────────
                    _sectionHeader(Icons.work_rounded, 'Work Details', _green),
                    const SizedBox(height: 12),
                    _formCard(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildDepartmentDropdown()),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                label: 'Position',
                                hint: 'Job Title',
                                icon: Icons.work_outline_rounded,
                                isRequired: true,
                                onChanged: (v) => _position = v,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildDateField(
                          label: 'Join Date',
                          hint: 'Select join date',
                          icon: Icons.calendar_today_rounded,
                          isRequired: true,
                          value: _joinDate,
                          onChanged: (v) => setState(() => _joinDate = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Error message
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: _red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: _red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _textLight,
                              side: const BorderSide(color: _border),
                              padding: const EdgeInsets.symmetric(vertical: 13),
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
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pink,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: _border,
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.black,
                                      ),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_add_rounded, size: 16),
                                      SizedBox(width: 8),
                                      Text(
                                        'Add Employee',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: color.withOpacity(0.2))),
      ],
    );
  }

  Widget _formCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _section,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: _input,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedImage != null ? _pink : _border,
                  width: 2,
                ),
              ),
              child: _selectedImage != null
                  ? ClipOval(
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : const Icon(
                      Icons.person_rounded,
                      color: _textGrey,
                      size: 34,
                    ),
            ),
            if (_selectedImage != null)
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedImage = null),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _red,
                      shape: BoxShape.circle,
                      border: Border.all(color: _section, width: 2),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _input,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _pink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.upload_rounded,
                      color: _pink,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'PNG, JPG · Max 5MB',
                        style: TextStyle(color: _textGrey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    IconData? icon,
    String? subtitle,
    bool isRequired = false,
    bool isPassword = false,
    bool isEmail = false,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _textLight,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: _red, fontSize: 13)),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: _textGrey, fontSize: 11),
          ),
        ],
        const SizedBox(height: 7),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: _input,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: TextFormField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: _textGrey.withOpacity(0.5),
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              prefixIcon: icon != null
                  ? Icon(icon, color: _textGrey, size: 16)
                  : const SizedBox(width: 12),
              suffixIcon: isPassword
                  ? const Icon(
                      Icons.visibility_off_outlined,
                      color: _textGrey,
                      size: 16,
                    )
                  : null,
            ),
            onChanged: onChanged,
            validator: (v) {
              if (isRequired && (v == null || v.isEmpty)) {
                return '$label is required';
              }
              if (isEmail && v != null && v.isNotEmpty) {
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) {
                  return 'Enter a valid email';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField({
    required String label,
    required String hint,
    IconData? icon,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textLight,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          decoration: BoxDecoration(
            color: _input,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: TextFormField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 3,
            minLines: 2,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: _textGrey.withOpacity(0.5),
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String hint,
    IconData? icon,
    bool isRequired = false,
    String value = '',
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _textLight,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: _red, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 7),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value.isNotEmpty
                  ? (DateTime.tryParse(value) ?? DateTime.now())
                  : DateTime.now(),
              firstDate: DateTime(1950),
              lastDate: DateTime(2100),
              builder: (ctx, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(primary: _pink),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              onChanged(DateFormat('yyyy-MM-dd').format(picked));
            }
          },
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: _input,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: value.isNotEmpty ? _pink.withOpacity(0.5) : _border,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  icon ?? Icons.calendar_today_rounded,
                  color: value.isNotEmpty ? _pink : _textGrey,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value.isEmpty ? hint : value,
                    style: TextStyle(
                      color: value.isEmpty
                          ? _textGrey.withOpacity(0.5)
                          : Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Icon(
                  Icons.expand_more_rounded,
                  color: _textGrey,
                  size: 18,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentDropdown() {
    final items = widget.departments.isEmpty
        ? <String>['Engineering', 'Finance', 'HR', 'Marketing', 'Sales']
        : widget.departments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Department',
          style: TextStyle(
            color: _textLight,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: _input,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDepartment.isEmpty ? null : _selectedDepartment,
              hint: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text(
                  'Select department',
                  style: TextStyle(color: _textGrey, fontSize: 13),
                ),
              ),
              items: items
                  .map(
                    (d) => DropdownMenuItem(
                      value: d,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          d,
                          style: const TextStyle(
                            color: _textLight,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() => _selectedDepartment = v ?? '');
              },
              dropdownColor: const Color(0xFF1A1A1A),
              iconEnabledColor: _textGrey,
              style: const TextStyle(color: _textLight, fontSize: 13),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fullName.isEmpty ||
        _employeeId.isEmpty ||
        _email.isEmpty ||
        _phone.isEmpty) {
      setState(
        () => _errorMessage =
            'Please fill all required fields (Name, Employee ID, Email, Phone)',
      );
      return;
    }
    if (_selectedDepartment.isEmpty) {
      setState(() => _errorMessage = 'Please select a department');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await AdminEmployeesService.addEmployee(
        token: widget.token ?? '',
        name: _fullName,
        employeeId: _employeeId,
        password: _password,
        email: _email,
        phone: _phone,
        dateOfBirth: _dob,
        address: _address,
        department: _selectedDepartment,
        position: _position,
        joinDate: _joinDate,
        profilePhoto: _selectedImage,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee added successfully'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
        Navigator.pop(context);
        widget.onEmployeeAdded();
      } else {
        setState(
          () => _errorMessage = result['message'] ?? 'Failed to add employee',
        );
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

// ─── Employee Detail Page ─────────────────────────────────────────────────────

class _EmployeeDetailPage extends StatefulWidget {
  final Map<String, dynamic> employee;
  final String? token;

  const _EmployeeDetailPage({required this.employee, required this.token});

  @override
  State<_EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<_EmployeeDetailPage>
    with SingleTickerProviderStateMixin {
  // Use AppTheme for consistency
  static const Color _bg = AppTheme.background;
  static const Color _card = AppTheme.cardColor;
  static const Color _input = AppTheme.surface;
  static const Color _border = AppTheme.outline;
  static const Color _pink = AppTheme.primaryColor;
  static const Color _green = AppTheme.successColor;
  static const Color _yellow = AppTheme.warningColor;
  static const Color _red = AppTheme.errorColor;
  static const Color _blue = AppTheme.primaryColor;
  static const Color _textGrey = Color(0xFF9E9E9E);
  static const Color _textLight = AppTheme.onSurface;

  late final TabController _tabController;

  bool _loadingAttendance = false;
  bool _attendanceLoaded = false;
  List<dynamic> _attendanceRecords = [];
  String? _attendanceError;

  bool _loadingTasks = false;
  bool _tasksLoaded = false;
  List<dynamic> _tasks = [];
  String? _tasksError;
  Map<String, dynamic>? _selectedTask;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    if (_tabController.index == 1 && !_attendanceLoaded) _loadAttendance();
    if (_tabController.index == 2 && !_tasksLoaded) _loadTasks();
  }

  String get _userId =>
      widget.employee['_id']?.toString() ??
      widget.employee['id']?.toString() ??
      '';

  Future<void> _loadAttendance() async {
    if (widget.token == null || _userId.isEmpty) return;
    setState(() {
      _loadingAttendance = true;
      _attendanceError = null;
    });
    try {
      final records = await AdminEmployeesService.getEmployeeAttendance(
        widget.token!,
        _userId,
      );
      if (mounted) {
        setState(() {
          _attendanceRecords = records;
          _loadingAttendance = false;
          _attendanceLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _attendanceError = e.toString().replaceAll('Exception: ', '');
          _loadingAttendance = false;
          _attendanceLoaded = true;
        });
      }
    }
  }

  Future<void> _loadTasks() async {
    if (widget.token == null || _userId.isEmpty) return;
    setState(() {
      _loadingTasks = true;
      _tasksError = null;
    });
    try {
      final tasks = await AdminEmployeesService.getEmployeeTasks(
        widget.token!,
        _userId,
      );
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _loadingTasks = false;
          _tasksLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tasksError = e.toString().replaceAll('Exception: ', '');
          _loadingTasks = false;
          _tasksLoaded = true;
        });
      }
    }
  }

  void _showEditEmployeeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditEmployeeDialog(
        employee: widget.employee,
        token: widget.token,
        onEmployeeUpdated: () {
          Navigator.pop(context, true); // Return true to indicate refresh
        },
      ),
    ).then((refreshed) {
      if (refreshed == true && mounted) {
        setState(() {
          // Data will be refreshed in parent screen
        });
      }
    });
  }

  String _formatDate(dynamic d) {
    if (d == null) return '-';
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(d.toString()));
    } catch (_) {
      return '-';
    }
  }

  String _formatDateTime(dynamic d) {
    if (d == null) return '-';
    try {
      return DateFormat(
        'd MMM yyyy, h:mm a',
      ).format(DateTime.parse(d.toString()));
    } catch (_) {
      return '-';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFFAF52DE),
      Color(0xFF007AFF),
      Color(0xFF34C759),
      Color(0xFFFF9500),
      Color(0xFFFF3B30),
      Color(0xFF5AC8FA),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return _green;
      case 'on-leave':
        return _yellow;
      case 'inactive':
        return _red;
      default:
        return _textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.employee['name']?.toString() ?? 'Unknown';
    final empId = widget.employee['employeeId']?.toString() ?? '';
    final status = widget.employee['status']?.toString() ?? 'active';
    final position = widget.employee['position']?.toString() ?? '-';
    final dept = widget.employee['department']?.toString() ?? '-';
    final companyName = (widget.employee['company'] is Map)
        ? (widget.employee['company']['name']?.toString() ?? 'N/A')
        : 'N/A';
    final photoUrl = _empPhotoUrl(widget.employee);

    final responsive = ResponsiveUtils(context);
    final isMobile = responsive.isMobile;

    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: _card,
            expandedHeight: isMobile ? 180 : 220,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Chat button
              IconButton(
                icon: const Icon(Icons.chat_rounded, color: _pink),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        recipientId: _userId,
                      ),
                    ),
                  );
                },
                tooltip: 'Message Employee',
              ),
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: _pink),
                onPressed: _showEditEmployeeDialog,
                tooltip: 'Edit Employee',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(color: _card),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    isMobile ? 70 : 80,
                    isMobile ? 16 : 24,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: isMobile ? 25 : 30,
                            backgroundColor: _avatarColor(name),
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            onBackgroundImageError:
                                photoUrl.isNotEmpty
                                ? (_, __) {}
                                : null,
                            child: photoUrl.isEmpty
                                ? Text(
                                    _initials(name),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMobile ? 16 : 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(width: isMobile ? 12 : 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isMobile ? 16 : 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (empId.isNotEmpty) ...[
                                  SizedBox(height: isMobile ? 2 : 4),
                                  Text(
                                    empId,
                                    style: TextStyle(
                                      color: _textGrey,
                                      fontSize: isMobile ? 11 : 13,
                                    ),
                                  ),
                                ],
                                SizedBox(height: isMobile ? 4 : 6),
                                Row(
                                  children: [
                                    _infoChip(
                                      Icons.work_outline_rounded,
                                      position,
                                    ),
                                    SizedBox(width: isMobile ? 6 : 8),
                                    _statusChip(status),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 8 : 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.business_rounded,
                            color: _textGrey,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            companyName,
                            style: const TextStyle(
                              color: _textGrey,
                              fontSize: 12,
                            ),
                          ),
                          if (dept != '-') ...[
                            SizedBox(width: isMobile ? 8 : 12),
                            const Icon(
                              Icons.workspaces_rounded,
                              color: _textGrey,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              dept,
                              style: const TextStyle(
                                color: _textGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: _pink,
              indicatorWeight: 3,
              labelColor: _pink,
              unselectedLabelColor: _textGrey,
              labelStyle: TextStyle(
                fontSize: isMobile ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(
                  icon: Icon(
                    Icons.person_outline_rounded,
                    size: isMobile ? 16 : 18,
                  ),
                  text: 'Overview',
                ),
                Tab(
                  icon: Icon(
                    Icons.calendar_today_rounded,
                    size: isMobile ? 16 : 18,
                  ),
                  text: 'Attendance',
                ),
                Tab(
                  icon: Icon(Icons.task_alt_rounded, size: isMobile ? 16 : 18),
                  text: 'Tasks',
                ),
                Tab(
                  icon: Icon(Icons.chat_rounded, size: isMobile ? 16 : 18),
                  text: 'Chat',
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildAttendanceTab(),
            _buildTasksTab(),
            _buildChatTab(),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _input,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _textGrey, size: 11),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: _textLight, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final c = _statusColor(status);
    String label;
    switch (status.toLowerCase()) {
      case 'active':
        label = 'Active';
        break;
      case 'on-leave':
        label = 'On Leave';
        break;
      case 'inactive':
        label = 'Inactive';
        break;
      default:
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final e = widget.employee;
    final email = e['email']?.toString() ?? '-';
    final phone = e['phone']?.toString() ?? '-';
    final address = e['address']?.toString() ?? '-';
    final role = e['role']?.toString() ?? '-';
    final joinDate = _formatDate(e['joinDate']);
    final dob = _formatDate(e['dateOfBirth'] ?? e['dob']);
    final companyName = (e['company'] is Map)
        ? (e['company']['name']?.toString() ?? 'N/A')
        : 'N/A';
    final dept = e['department']?.toString() ?? '-';
    final position = e['position']?.toString() ?? '-';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          icon: Icons.person_rounded,
          title: 'Personal Information',
          color: _pink,
          children: [
            _infoRow(Icons.email_outlined, 'Email', email),
            _infoRow(Icons.phone_outlined, 'Phone', phone),
            _infoRow(Icons.cake_outlined, 'Date of Birth', dob),
            _infoRow(Icons.location_on_outlined, 'Address', address),
          ],
        ),
        const SizedBox(height: 14),
        _sectionCard(
          icon: Icons.work_rounded,
          title: 'Work Details',
          color: _blue,
          children: [
            _infoRow(Icons.business_rounded, 'Company', companyName),
            _infoRow(Icons.workspaces_rounded, 'Department', dept),
            _infoRow(Icons.work_outline_rounded, 'Position', position),
            _infoRow(Icons.badge_outlined, 'Role', role.toUpperCase()),
            _infoRow(Icons.calendar_today_rounded, 'Join Date', joinDate),
          ],
        ),
        const SizedBox(height: 14),
        _sectionCard(
          icon: Icons.lock_rounded,
          title: 'Login Credentials',
          color: _yellow,
          children: [
            _infoRow(Icons.email_outlined, 'Login Email', email),
            _credentialRow(
              icon: Icons.badge_outlined,
              label: 'Employee ID',
              value: e['employeeId']?.toString() ?? '-',
            ),
            const Divider(color: Color(0xFF2A2A2A), height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _yellow.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _yellow.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: _yellow, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Password is hidden for security. Use reset password to change it.',
                      style: TextStyle(color: _yellow, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _textGrey, size: 15),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: _textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _credentialRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: _textGrey, size: 15),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: _textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _input,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    if (_loadingAttendance) {
      return const Center(
        child: CircularProgressIndicator(color: _pink, strokeWidth: 2),
      );
    }
    if (_attendanceError != null) {
      return _errorView(
        _attendanceError!,
        onRetry: () {
          setState(() => _attendanceLoaded = false);
          _loadAttendance();
        },
      );
    }
    if (!_attendanceLoaded) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: _loadAttendance,
          icon: const Icon(
            Icons.download_rounded,
            size: 16,
            color: Colors.black,
          ),
          label: const Text(
            'Load Attendance',
            style: TextStyle(color: Colors.black),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _pink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
    if (_attendanceRecords.isEmpty) {
      return _emptyView(
        'No attendance records found',
        Icons.calendar_today_rounded,
        _pink,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attendanceRecords.length,
      itemBuilder: (_, i) => _attendanceCard(_attendanceRecords[i]),
    );
  }

  Widget _attendanceCard(dynamic record) {
    final checkIn = record['checkIn'];
    final checkOut = record['checkOut'];
    final date = record['date'] ?? record['createdAt'];
    final status = record['status']?.toString() ?? '-';
    final workHours =
        record['workHours']?.toString() ??
        record['hoursWorked']?.toString() ??
        '-';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'present':
        statusColor = _green;
        break;
      case 'late':
        statusColor = _yellow;
        break;
      case 'absent':
        statusColor = _red;
        break;
      default:
        statusColor = _textGrey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: statusColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (workHours != '-')
                      Text(
                        '$workHours hrs worked',
                        style: const TextStyle(color: _textGrey, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _capitalizeFirst(status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (checkIn != null || checkOut != null) ...[
            const SizedBox(height: 10),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _timeWidget(
                    Icons.login_rounded,
                    'Check In',
                    _formatDateTime(checkIn is Map ? checkIn['time'] : checkIn),
                    _green,
                  ),
                ),
                Expanded(
                  child: _timeWidget(
                    Icons.logout_rounded,
                    'Check Out',
                    _formatDateTime(
                      checkOut is Map ? checkOut['time'] : checkOut,
                    ),
                    _red,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeWidget(IconData icon, String label, String time, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: _textGrey, fontSize: 10)),
            Text(
              time,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTasksTab() {
    if (_loadingTasks) {
      return const Center(
        child: CircularProgressIndicator(color: _pink, strokeWidth: 2),
      );
    }
    if (_tasksError != null) {
      return _errorView(
        _tasksError!,
        onRetry: () {
          setState(() => _tasksLoaded = false);
          _loadTasks();
        },
      );
    }
    if (!_tasksLoaded) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: _loadTasks,
          icon: const Icon(Icons.download_rounded, size: 16, color: Colors.black),
          label: const Text('Load Tasks', style: TextStyle(color: Colors.black)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _pink,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    final employeeName =
        widget.employee['name']?.toString() ?? 'Employee';
    final total = _tasks.length;
    final assigned = _tasks
        .where((t) => (t as Map)['createdBy'] != 'employee')
        .length;
    final inProgress = _tasks
        .where((t) => (t as Map)['status'] == 'in-progress')
        .length;
    final completed = _tasks
        .where((t) => (t as Map)['status'] == 'completed')
        .length;
    final overdue = _tasks.where((t) {
      final due = (t as Map)['dueDate'];
      if (due == null) return false;
      try {
        return DateTime.parse(due.toString()).isBefore(DateTime.now()) &&
            t['status'] != 'completed';
      } catch (_) {
        return false;
      }
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header bar ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "$employeeName's Tasks",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _tasksLoaded = false;
                  });
                  _loadTasks();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _pink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.refresh_rounded, size: 13, color: Colors.black),
                      SizedBox(width: 5),
                      Text(
                        'Refresh',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── Stat cards ──
        SizedBox(
          height: 72,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _taskStatCard('Total', total, Icons.assignment_rounded,
                  const Color(0xFF9E9E9E)),
              const SizedBox(width: 8),
              _taskStatCard('Assigned', assigned,
                  Icons.person_add_alt_1_rounded, const Color(0xFF448AFF)),
              const SizedBox(width: 8),
              _taskStatCard('In Progress', inProgress,
                  Icons.timelapse_rounded, const Color(0xFFFF9500)),
              const SizedBox(width: 8),
              _taskStatCard('Completed', completed,
                  Icons.check_circle_rounded, AppTheme.successColor),
              const SizedBox(width: 8),
              _taskStatCard(
                  'Overdue', overdue, Icons.warning_rounded, AppTheme.errorColor),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── Task count chip ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3A3A3A)),
                ),
                child: Text(
                  '$total task${total == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // ── Table header ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Task',
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  'Priority',
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 90,
                child: Text(
                  'Progress',
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  'Status',
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Task rows ──
        if (_tasks.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              border: Border.all(color: const Color(0xFF2A2A2A)),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: const Center(
              child: Text(
                'No tasks assigned',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tasks.length,
            itemBuilder: (_, i) => _taskRow(_tasks[i], i == _tasks.length - 1),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Table row (tappable)
  Widget _taskRow(dynamic task, bool isLast) {
    final title = task['title']?.toString() ?? 'Untitled';
    final description = task['description']?.toString() ?? '';
    final status = task['status']?.toString() ?? 'todo';
    final priority = task['priority']?.toString() ?? 'medium';
    final dueDate = _formatDate(task['dueDate']);
    final startDate = _formatDate(task['startDate'] ?? task['createdAt']);
    final progress = (task['progress'] as num?)?.toInt() ?? 0;

    Color statusColor;
    String statusLabel;
    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = _green;
        statusLabel = 'Completed';
        break;
      case 'in-progress':
        statusColor = const Color(0xFF448AFF);
        statusLabel = 'In Progress';
        break;
      case 'cancelled':
        statusColor = _red;
        statusLabel = 'Cancelled';
        break;
      case 'todo':
        statusColor = _textGrey;
        statusLabel = 'Draft';
        break;
      default:
        statusColor = _yellow;
        statusLabel = _capitalizeFirst(status);
    }

    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'high':
        priorityColor = _red;
        break;
      case 'medium':
        priorityColor = _yellow;
        break;
      default:
        priorityColor = _green;
    }

    final borderRadius = isLast
        ? const BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          )
        : BorderRadius.zero;

    return GestureDetector(
      onTap: () => _showTaskDetailSheet(task as Map<String, dynamic>),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          border: Border(
            left: BorderSide(color: const Color(0xFF2A2A2A)),
            right: BorderSide(color: const Color(0xFF2A2A2A)),
            bottom: BorderSide(color: const Color(0xFF2A2A2A)),
          ),
          borderRadius: borderRadius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Task name + description
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Priority badge
            SizedBox(
              width: 70,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _capitalizeFirst(priority),
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Progress bar + %
            SizedBox(
              width: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: const Color(0xFF2A2A2A),
                      color: statusColor,
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$progress%',
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            // Status + due date
            SizedBox(
              width: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (dueDate != '-') ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: Color(0xFF9E9E9E),
                          size: 9,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            dueDate,
                            style: const TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 9,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (startDate != '-')
                      Text(
                        'Started $startDate',
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 9,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  void _showTaskDetailSheet(Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskDetailSheet(task: task),
    );
  }

  // Keep old _taskCard for potential use (unused, but no error)
  Widget _taskCard(dynamic task) => _taskRow(task, false);

  Widget _taskBadge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 10),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskStatCard(String label, int count, IconData icon, Color color) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView(String error, {required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: _red, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textGrey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 14, color: Colors.black),
              label: const Text('Retry', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _pink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView(String msg, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: _textGrey, fontSize: 14)),
        ],
      ),
    );
  }

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  static String _empPhotoUrl(Map<String, dynamic> emp) {
    final raw = emp['profilePhoto'];
    if (raw is String && (raw as String).isNotEmpty) return raw;
    if (raw is Map<String, dynamic>) {
      return (raw as Map<String, dynamic>)['url']?.toString() ?? '';
    }
    return '';
  }

  Widget _buildChatTab() {
    return _EmployeeChatTab(
      employeeId: _userId,
      employeeName: widget.employee['name']?.toString() ?? 'Employee',
      token: widget.token,
    );
  }
}

// ─── Task Detail Sheet ────────────────────────────────────────────────────────

class _TaskDetailSheet extends StatefulWidget {
  final Map<String, dynamic> task;
  const _TaskDetailSheet({required this.task});
  @override
  State<_TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<_TaskDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late double _progress;
  late TextEditingController _progressController;
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 0;

  static const _bg = Color(0xFF0D0D0D);
  static const _card = Color(0xFF181818);
  static const _border = Color(0xFF2A2A2A);
  static const _textGrey = Color(0xFF9E9E9E);
  static const _pink = Color(0xFFFF8FA3);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _progress = ((widget.task['progress'] as num?)?.toDouble() ?? 0).clamp(0, 100);
    _progressController = TextEditingController(text: _progress.toInt().toString());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _progressController.dispose();
    _reviewController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high': return const Color(0xFFFF5252);
      case 'low': return const Color(0xFF69F0AE);
      default: return const Color(0xFFFFD740);
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'completed': return const Color(0xFF69F0AE);
      case 'in-progress': return const Color(0xFFFF9500);
      case 'overdue': return const Color(0xFFFF5252);
      default: return const Color(0xFF448AFF);
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'completed': return 'Completed';
      case 'in-progress': return 'In Progress';
      case 'overdue': return 'Overdue';
      case 'todo': return 'To Do';
      default: return s;
    }
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  Widget _statBox(String value, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: _textGrey, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final title = task['title']?.toString() ?? 'Untitled';
    final description = task['description']?.toString() ?? '';
    final status = task['status']?.toString() ?? 'todo';
    final priority = task['priority']?.toString() ?? 'medium';
    final dueDate = _formatDate(task['dueDate']);
    final startDate = _formatDate(task['startDate'] ?? task['createdAt']);
    final subtaskCount = (task['subtasks'] as List?)?.length ?? 0;
    final commentCount = (task['comments'] as List?)?.length ?? 0;
    final fileCount = (task['files'] as List?)?.length ?? 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.93,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40, height: 4,
                decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(description,
                                  style: const TextStyle(color: _textGrey, fontSize: 13),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: [
                                  _badge(_statusLabel(status), _statusColor(status)),
                                  _badge(
                                    '${priority[0].toUpperCase()}${priority.substring(1)} Priority',
                                    _priorityColor(priority)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: _textGrey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Workflow Action ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Workflow Actions',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _commentController,
                            maxLines: 2,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Optional comment for transition...',
                              hintStyle: const TextStyle(color: _textGrey, fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFF111111),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: _border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: _border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: _pink.withOpacity(0.6)),
                              ),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: const Text('Submit for Approval'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _pink,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Stat Boxes ───────────────────────────────────────────
                    Row(
                      children: [
                        _statBox('${_progress.toInt()}%', 'Progress', _pink),
                        const SizedBox(width: 6),
                        _statBox('$subtaskCount', 'Subtasks', const Color(0xFF448AFF)),
                        const SizedBox(width: 6),
                        _statBox('$commentCount', 'Comments', const Color(0xFFFF9500)),
                        const SizedBox(width: 6),
                        _statBox('$fileCount', 'Files', const Color(0xFF69F0AE)),
                        const SizedBox(width: 6),
                        _statBox('0m', 'Time Logged', const Color(0xFFAA80FF)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Overall Progress ─────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Overall Progress',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                              const Spacer(),
                              Text('${_progress.toInt()}%',
                                style: TextStyle(color: _pink, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _pink,
                              inactiveTrackColor: _border,
                              thumbColor: _pink,
                              overlayColor: _pink.withOpacity(0.15),
                              trackHeight: 5,
                            ),
                            child: Slider(
                              value: _progress,
                              min: 0, max: 100,
                              onChanged: (v) => setState(() {
                                _progress = v;
                                _progressController.text = v.toInt().toString();
                              }),
                            ),
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 64,
                                child: TextField(
                                  controller: _progressController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    filled: true,
                                    fillColor: const Color(0xFF111111),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: _border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: _border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(color: _pink.withOpacity(0.6)),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  onSubmitted: (v) {
                                    final parsed = double.tryParse(v);
                                    if (parsed != null) {
                                      setState(() { _progress = parsed.clamp(0, 100); });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _pink,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Tab Bar ──────────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            labelColor: _pink,
                            unselectedLabelColor: _textGrey,
                            indicatorColor: _pink,
                            dividerColor: _border,
                            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            tabs: const [
                              Tab(text: 'Details'),
                              Tab(text: 'Subtasks'),
                              Tab(text: 'Files'),
                              Tab(text: 'History'),
                            ],
                          ),
                          SizedBox(
                            height: 220,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Details
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _detailRow(Icons.flag_rounded, 'Priority',
                                        _badge(
                                          '${priority[0].toUpperCase()}${priority.substring(1)}',
                                          _priorityColor(priority))),
                                      const SizedBox(height: 10),
                                      _detailRow(Icons.calendar_today_rounded, 'Due Date',
                                        Text(dueDate,
                                          style: const TextStyle(color: Colors.white, fontSize: 13))),
                                      const SizedBox(height: 10),
                                      _detailRow(Icons.play_circle_outline_rounded, 'Start Date',
                                        Text(startDate,
                                          style: const TextStyle(color: Colors.white, fontSize: 13))),
                                    ],
                                  ),
                                ),
                                // Subtasks
                                const Center(
                                  child: Text('No subtasks yet',
                                    style: TextStyle(color: _textGrey, fontSize: 13))),
                                // Files
                                const Center(
                                  child: Text('No files attached',
                                    style: TextStyle(color: _textGrey, fontSize: 13))),
                                // History
                                const Center(
                                  child: Text('No history available',
                                    style: TextStyle(color: _textGrey, fontSize: 13))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Add Review ───────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Add Review',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 10),
                          // Star rating
                          Row(
                            children: List.generate(5, (i) => GestureDetector(
                              onTap: () => setState(() => _selectedRating = i + 1),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  i < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: i < _selectedRating ? const Color(0xFFFFD740) : _textGrey,
                                  size: 28,
                                ),
                              ),
                            )),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _reviewController,
                            maxLines: 3,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Write your review...',
                              hintStyle: const TextStyle(color: _textGrey, fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFF111111),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: _border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: _border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: _pink.withOpacity(0.6)),
                              ),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _pink,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Submit Review',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
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

  Widget _detailRow(IconData icon, String label, Widget valueWidget) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Icon(icon, color: _textGrey, size: 16),
      const SizedBox(width: 8),
      SizedBox(
        width: 80,
        child: Text(label,
          style: const TextStyle(color: _textGrey, fontSize: 13)),
      ),
      valueWidget,
    ],
  );
}

// ─── Embedded Chat Tab ───────────────────────────────────────────────────────

class _EmployeeChatTab extends StatefulWidget {
  final String employeeId;
  final String employeeName;
  final String? token;

  const _EmployeeChatTab({
    required this.employeeId,
    required this.employeeName,
    required this.token,
  });

  @override
  State<_EmployeeChatTab> createState() => _EmployeeChatTabState();
}

class _EmployeeChatTabState extends State<_EmployeeChatTab> {
  static const Color _card = AppTheme.cardColor;
  static const Color _input = AppTheme.surface;
  static const Color _border = AppTheme.outline;
  static const Color _pink = AppTheme.primaryColor;
  static const Color _textGrey = Color(0xFF9E9E9E);

  List<ChatRoom> _rooms = [];
  List<ChatRoom> _filteredRooms = [];
  ChatRoom? _selectedRoom;
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _loadingMessages = false;
  String? _error;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchRooms() async {
    if (widget.token == null || widget.token!.isEmpty) {
      setState(() {
        _error = 'No authentication token';
        _loading = false;
      });
      return;
    }
    try {
      final resp = await ChatService.getChatRooms(token: widget.token!);
      if (mounted) {
        setState(() {
          _rooms = resp.data;
          _filteredRooms = List.from(resp.data);
          _loading = false;
          if (_rooms.isNotEmpty && _selectedRoom == null) {
            _selectedRoom = _rooms.first;
          }
        });
        if (_rooms.isNotEmpty) {
          _fetchMessages(_rooms.first.id);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchMessages(String roomId) async {
    if (widget.token == null) return;
    setState(() => _loadingMessages = true);
    try {
      final resp = await ChatService.getRoomMessages(
        token: widget.token!,
        roomId: roomId,
        limit: 50,
      );
      if (mounted) {
        setState(() {
          _messages = List.from(resp.data);
          _loadingMessages = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRooms = List.from(_rooms);
      } else {
        final lower = query.toLowerCase();
        _filteredRooms = _rooms
            .where((r) => _getRoomName(r).toLowerCase().contains(lower))
            .toList();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getRoomName(ChatRoom room) {
    if (room.type == 'personal' && room.otherUser != null) {
      return room.otherUser!.name.isNotEmpty
          ? room.otherUser!.name
          : 'Unknown User';
    }
    return room.name.isNotEmpty ? room.name : 'Group';
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  String _formatTime(DateTime dt) =>
      DateFormat('h:mm a').format(dt.toLocal());

  String _formatDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return DateFormat('d MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _pink, strokeWidth: 2),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: _pink, size: 36),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textGrey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _fetchRooms();
                },
                style: ElevatedButton.styleFrom(backgroundColor: _pink),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isNarrow = constraints.maxWidth < 520;
        // On narrow screens: show rooms list first, then messages when selected
        if (isNarrow && _selectedRoom != null) {
          return _buildMessagesPanel(showBack: true);
        }
        if (isNarrow) {
          return _buildRoomsList();
        }
        // Wide: side-by-side
        return Row(
          children: [
            SizedBox(width: 220, child: _buildRoomsList()),
            Expanded(
              child: _selectedRoom == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.message_rounded,
                            color: _textGrey,
                            size: 40,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Select a conversation to view',
                            style: TextStyle(color: _textGrey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : _buildMessagesPanel(showBack: false),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoomsList() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFF2A2A2A)),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.employeeName}'s Messages",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: _input,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search conversations...',
                      hintStyle: TextStyle(color: _textGrey, fontSize: 12),
                      prefixIcon: Icon(
                        Icons.search,
                        color: _textGrey,
                        size: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(right: 8),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rooms
          Expanded(
            child: _filteredRooms.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.message_rounded,
                        color: _textGrey,
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No conversations found',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _textGrey, fontSize: 12),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    itemCount: _filteredRooms.length,
                    itemBuilder: (_, i) => _buildRoomTile(_filteredRooms[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTile(ChatRoom room) {
    final name = _getRoomName(room);
    final lastMsg = room.lastMessage?.content ?? 'No messages yet';
    final isSelected = _selectedRoom?.id == room.id;
    final timeStr = room.lastMessage != null
        ? _formatTime(room.lastMessage!.createdAt)
        : '';

    return GestureDetector(
      onTap: () {
        setState(() => _selectedRoom = room);
        _fetchMessages(room.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _pink.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: _pink.withOpacity(0.2))
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _pink.withOpacity(0.2),
              child: room.isGroup
                  ? const Icon(
                      Icons.group_rounded,
                      color: _pink,
                      size: 16,
                    )
                  : Text(
                      _initials(name),
                      style: const TextStyle(
                        color: _pink,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: _textGrey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastMsg,
                    style: const TextStyle(color: _textGrey, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (room.unreadCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                constraints:
                    const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: const BoxDecoration(
                  color: _pink,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: Center(
                  child: Text(
                    room.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesPanel({required bool showBack}) {
    final room = _selectedRoom!;
    final name = _getRoomName(room);
    final participantCount = room.participants.length;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF2A2A2A)),
            ),
          ),
          child: Row(
            children: [
              if (showBack)
                GestureDetector(
                  onTap: () => setState(() => _selectedRoom = null),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: _pink,
                      size: 16,
                    ),
                  ),
                ),
              CircleAvatar(
                radius: 16,
                backgroundColor: _pink.withOpacity(0.2),
                child: room.isGroup
                    ? const Icon(
                        Icons.group_rounded,
                        color: _pink,
                        size: 14,
                      )
                    : Text(
                        _initials(name),
                        style: const TextStyle(
                          color: _pink,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      room.isGroup
                          ? '$participantCount members'
                          : 'Personal chat',
                      style: const TextStyle(
                        color: _textGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: _loadingMessages
              ? const Center(
                  child: CircularProgressIndicator(
                    color: _pink,
                    strokeWidth: 2,
                  ),
                )
              : _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages in this conversation',
                        style: TextStyle(color: _textGrey, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final msg = _messages[i];
                        final showDate = i == 0 ||
                            _formatDateLabel(msg.createdAt) !=
                                _formatDateLabel(_messages[i - 1].createdAt);
                        return Column(
                          children: [
                            if (showDate)
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _input,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _formatDateLabel(msg.createdAt),
                                      style: const TextStyle(
                                        color: _textGrey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            _buildBubble(msg),
                          ],
                        );
                      },
                    ),
        ),
        // Read-only notice
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF141414),
            border: Border(
              top: BorderSide(color: Color(0xFF2A2A2A)),
            ),
          ),
          child: const Center(
            child: Text(
              '📋 Read-only monitoring view',
              style: TextStyle(color: _textGrey, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    // Messages from the employee being viewed → right; others → left
    final isFromEmployee = msg.sender?.id == widget.employeeId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment:
            isFromEmployee ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.62,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isFromEmployee
                ? _pink.withOpacity(0.85)
                : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isFromEmployee ? 14 : 4),
              bottomRight: Radius.circular(isFromEmployee ? 4 : 14),
            ),
            border: isFromEmployee ? null : Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: isFromEmployee
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isFromEmployee && (msg.sender?.name.isNotEmpty ?? false))
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    msg.sender!.name,
                    style: const TextStyle(
                      color: _pink,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Text(
                msg.isDeleted
                    ? '(This message was deleted)'
                    : msg.content,
                style: TextStyle(
                  color: isFromEmployee ? Colors.black : Colors.white,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _formatTime(msg.createdAt),
                style: TextStyle(
                  color: isFromEmployee ? Colors.black54 : _textGrey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Edit Employee Dialog ─────────────────────────────────────────────────────

class _EditEmployeeDialog extends StatefulWidget {
  final Map<String, dynamic> employee;
  final String? token;
  final VoidCallback onEmployeeUpdated;

  const _EditEmployeeDialog({
    required this.employee,
    required this.token,
    required this.onEmployeeUpdated,
  });

  @override
  State<_EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<_EditEmployeeDialog> {
  // Use AppTheme for consistency
  static const Color _bg = AppTheme.background;
  static const Color _section = AppTheme.surface;
  static const Color _input = AppTheme.surface;
  static const Color _border = AppTheme.outline;
  static const Color _blue = AppTheme.primaryColor;
  static const Color _green = AppTheme.successColor;
  static const Color _textGrey = Color(0xFF9E9E9E);
  static const Color _textLight = AppTheme.onSurface;
  static const Color _red = AppTheme.errorColor;
  static const Color _purple = AppTheme.primaryColor;

  // Form fields - pre-filled from employee data
  final _formKey = GlobalKey<FormState>();
  late String _fullName;
  late String _email;
  late String _phone;
  late String _dob;
  late String _address;
  late String _selectedDepartment;
  late String _position;
  late String _joinDate;
  late String _selectedStatus;

  File? _selectedImage;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize with existing employee data
    _fullName = widget.employee['name']?.toString() ?? '';
    _email = widget.employee['email']?.toString() ?? '';
    _phone = widget.employee['phone']?.toString() ?? '';
    _dob = widget.employee['dateOfBirth']?.toString() ?? '';
    _address = widget.employee['address']?.toString() ?? '';
    _selectedDepartment = (widget.employee['department']?.toString() ?? '')
        .toLowerCase();
    _position = widget.employee['position']?.toString() ?? '';
    _joinDate = widget.employee['joinDate']?.toString() ?? '';
    _selectedStatus = widget.employee['status']?.toString() ?? 'active';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _border.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _border.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header with gradient background
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                gradient: LinearGradient(
                  colors: [_blue.withOpacity(0.08), _purple.withOpacity(0.04)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 20, 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _blue.withOpacity(0.2),
                          _blue.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: _blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Employee Profile',
                          style: TextStyle(
                            color: _textLight,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Update employee information',
                          style: TextStyle(
                            color: _textGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _border.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border, width: 1),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: _textGrey,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: _border.withOpacity(0.4)),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── SECTION: Personal Info ────────────────────────
                      _sectionHeader(
                        Icons.person_rounded,
                        'Personal Information',
                        _blue,
                      ),
                      const SizedBox(height: 14),
                      _formCard(
                        children: [
                          _buildTextField(
                            label: 'Full Name',
                            hint: 'John Doe',
                            icon: Icons.person_outline_rounded,
                            initialValue: _fullName,
                            onChanged: (v) => _fullName = v,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: 'Email',
                                  hint: 'employee@company.com',
                                  icon: Icons.email_outlined,
                                  initialValue: _email,
                                  isEmail: true,
                                  onChanged: (v) => _email = v,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildTextField(
                                  label: 'Phone',
                                  hint: '+1 (555) 000-0000',
                                  icon: Icons.phone_outlined,
                                  initialValue: _phone,
                                  onChanged: (v) => _phone = v,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDateField(
                            label: 'Date of Birth',
                            hint: 'Select date of birth',
                            icon: Icons.cake_outlined,
                            initialValue: _dob,
                            onChanged: (v) => _dob = v,
                          ),
                          const SizedBox(height: 16),
                          _buildTextAreaField(
                            label: 'Address',
                            hint: 'Full home address',
                            icon: Icons.location_on_outlined,
                            initialValue: _address,
                            onChanged: (v) => _address = v,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // ── SECTION: Work Info ────────────────────────────
                      _sectionHeader(
                        Icons.work_rounded,
                        'Work Details',
                        _green,
                      ),
                      const SizedBox(height: 14),
                      _formCard(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildDepartmentDropdown()),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildTextField(
                                  label: 'Position',
                                  hint: 'Job Title',
                                  icon: Icons.work_outline_rounded,
                                  initialValue: _position,
                                  onChanged: (v) => _position = v,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateField(
                                  label: 'Join Date',
                                  hint: 'Select join date',
                                  icon: Icons.calendar_today_rounded,
                                  initialValue: _joinDate,
                                  onChanged: (v) => _joinDate = v,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: _buildStatusDropdown()),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Error message
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: _red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _red.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: _red,
                                size: 17,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: _red,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _textLight,
                                side: BorderSide(
                                  color: _border.withOpacity(0.8),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_blue, _blue.withOpacity(0.85)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(13),
                                boxShadow: [
                                  BoxShadow(
                                    color: _blue.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isSubmitting ? null : _submitForm,
                                  borderRadius: BorderRadius.circular(13),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    child: Center(
                                      child: _isSubmitting
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                      Color(0xFF0A0E27),
                                                    ),
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.check_rounded,
                                                  size: 17,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Save Changes',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                    letterSpacing: 0.3,
                                                    color: Color(0xFF0A0E27),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.3), color.withOpacity(0)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _formCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _section,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border.withOpacity(0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    String? initialValue,
    bool isEmail = false,
    bool isPassword = false,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textLight,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          style: const TextStyle(color: _textLight, fontSize: 14),
          obscureText: isPassword,
          onChanged: onChanged,
          validator: isEmail
              ? (v) => (v?.isEmpty ?? true) || !v!.contains('@')
                    ? 'Enter valid email'
                    : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _textGrey, fontSize: 13),
            prefixIcon: Icon(icon, size: 17, color: _textGrey),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 13,
            ),
            filled: true,
            fillColor: _input,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: _border.withOpacity(0.6), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: _border.withOpacity(0.6), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _blue, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _red, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField({
    required String label,
    required String hint,
    required IconData icon,
    String? initialValue,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textLight,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          style: const TextStyle(color: _textLight, fontSize: 14),
          maxLines: 3,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _textGrey, fontSize: 13),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Icon(icon, size: 17, color: _textGrey),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 13,
            ),
            filled: true,
            fillColor: _input,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: _border.withOpacity(0.6), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: _border.withOpacity(0.6), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _blue, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String hint,
    required IconData icon,
    String? initialValue,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textLight,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        StatefulBuilder(
          builder: (context, setState) => GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: (initialValue?.isNotEmpty ?? false)
                    ? DateTime.parse(initialValue!)
                    : DateTime.now(),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                final formatted =
                    '${picked.year}-${String.fromCharCode(48 + picked.month ~/ 10)}${String.fromCharCode(48 + picked.month % 10)}-${String.fromCharCode(48 + picked.day ~/ 10)}${String.fromCharCode(48 + picked.day % 10)}';
                setState(() {});
                onChanged(formatted);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: _input,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: _textGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      initialValue?.isNotEmpty ?? false ? initialValue! : hint,
                      style: TextStyle(
                        color: (initialValue?.isNotEmpty ?? false)
                            ? _textLight
                            : _textGrey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Department',
          style: TextStyle(
            color: _textLight,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _input,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDepartment.isEmpty ? null : _selectedDepartment,
              hint: const Padding(
                padding: EdgeInsets.only(left: 2),
                child: Text(
                  'Select department',
                  style: TextStyle(color: _textGrey, fontSize: 12),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'engineering',
                  child: Text('Engineering'),
                ),
                DropdownMenuItem(value: 'marketing', child: Text('Marketing')),
                DropdownMenuItem(value: 'sales', child: Text('Sales')),
                DropdownMenuItem(value: 'hr', child: Text('HR')),
                DropdownMenuItem(value: 'finance', child: Text('Finance')),
                DropdownMenuItem(
                  value: 'operations',
                  child: Text('Operations'),
                ),
              ],
              onChanged: (v) => setState(() => _selectedDepartment = v ?? ''),
              dropdownColor: const Color(0xFF1A1A1A),
              iconEnabledColor: _textGrey,
              style: const TextStyle(color: _textLight, fontSize: 12),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            color: _textLight,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _input,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'on-leave', child: Text('On Leave')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (v) => setState(() => _selectedStatus = v ?? 'active'),
              dropdownColor: const Color(0xFF1A1A1A),
              iconEnabledColor: _textGrey,
              style: const TextStyle(color: _textLight, fontSize: 12),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await AdminEmployeesService.updateEmployee(
        token: widget.token ?? '',
        employeeId: widget.employee['_id'].toString(),
        name: _fullName,
        email: _email,
        phone: _phone,
        dateOfBirth: _dob,
        address: _address,
        department: _selectedDepartment,
        position: _position,
        joinDate: _joinDate,
        status: _selectedStatus,
        profilePhoto: _selectedImage,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee updated successfully'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
        widget.onEmployeeUpdated();
        Navigator.pop(context, true);
      } else {
        setState(
          () =>
              _errorMessage = result['message'] ?? 'Failed to update employee',
        );
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
