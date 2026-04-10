import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hrms_app/features/tasks/data/services/task_management_service.dart';
import 'package:hrms_app/features/tasks/presentation/screens/task_management_details_screen.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';

class TaskManagementScreen extends StatefulWidget {
  final String? token;

  const TaskManagementScreen({super.key, this.token});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  // ─── Theme Colors ───────────────────────────────────────────────────────────
  static const Color _bg = AppTheme.background;
  static const Color _card = AppTheme.surface;
  static const Color _input = AppTheme.surfaceVariant;
  static const Color _border = AppTheme.outline;
  static const Color _primary = AppTheme.primaryColor;
  static const Color _green = AppTheme.secondaryColor;
  static const Color _textLight = AppTheme.onBackground;
  static const Color _textGrey = Color(0xFF8E8E93);

  final TextEditingController _searchController = TextEditingController();

  String? _token;
  bool _loading = true;
  bool _creating = false;
  String? _error;

  List<TaskManagementEntry> _entries = [];
  List<TaskManagementEmployee> _employees = [];

  String _search = '';
  String _typeFilter = 'all';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final token = widget.token ?? await TokenStorageService().getToken();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      setState(() {
        _error = 'Authentication token not found';
        _loading = false;
      });
      return;
    }

    _token = token;
    await _loadData();
  }

  Future<void> _loadData() async {
    final token = _token;
    if (token == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    List<TaskManagementEntry> entries = _entries;
    List<TaskManagementEmployee> employees = _employees;
    String? loadError;

    try {
      entries = await TaskManagementService.getEntries(token);
    } catch (e) {
      loadError = e.toString().replaceFirst('Exception: ', '');
    }

    try {
      employees = await TaskManagementService.getEmployees(token);
    } catch (_) {
      // Keep existing employee list if this request fails.
    }

    if (!mounted) return;
    setState(() {
      _entries = entries;
      _employees = employees;
      _error = loadError;
      _loading = false;
    });
  }

  String? get _dateFilterValue {
    if (_selectedDate == null) return null;
    return DateFormat('yyyy-MM-dd').format(_selectedDate!);
  }

  List<TaskManagementEntry> get _filteredEntries {
    final search = _search.trim().toLowerCase();
    final dateFilter = _dateFilterValue;

    return _entries.where((entry) {
      final matchSearch =
          search.isEmpty || entry.employeeName.toLowerCase().contains(search);
      final matchDate = dateFilter == null || entry.date == dateFilter;
      final matchType = _typeFilter == 'all' || entry.type == _typeFilter;
      return matchSearch && matchDate && matchType;
    }).toList();
  }

  int get _bodCount => _entries.where((e) => e.type == 'BOD').length;
  int get _eodCount => _entries.where((e) => e.type == 'EOD').length;

  int get _completedCount {
    return _entries.where((entry) {
      if (entry.tasks.isEmpty) return false;
      return entry.tasks.every((task) => task.status == 'Completed');
    }).length;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );

    if (selected != null) {
      setState(() => _selectedDate = selected);
    }
  }

  Future<void> _showCreateDialog() async {
    if (_employees.isEmpty) {
      _showSnack('No employees available');
      return;
    }

    String employeeId = '';
    String search = '';

    final now = DateTime.now();
    final date = DateFormat('yyyy-MM-dd').format(now);
    final time = DateFormat('HH:mm').format(now);
    final type = now.hour < 14 ? 'BOD' : 'EOD';

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final visibleEmployees = _employees.where((emp) {
              if (search.isEmpty) return true;
              final q = search.toLowerCase();
              return emp.name.toLowerCase().contains(q) ||
                  emp.email.toLowerCase().contains(q);
            }).toList();

            final isMobile = MediaQuery.of(context).size.width < 600;
            final padding = isMobile ? 16.0 : 24.0;
            final maxWidth = isMobile ? double.infinity : 520.0;

            return Dialog(
              backgroundColor: AppTheme.surface,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Create Task Entry',
                                style: TextStyle(
                                  fontSize: isMobile ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.onBackground,
                                ),
                              ),
                            ),
                            if (!isMobile)
                              IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: AppTheme.onBackground,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 16 : 20),

                        // Employee Search Section
                        Text(
                          'Select Employee',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          style: const TextStyle(color: AppTheme.onBackground),
                          decoration: InputDecoration(
                            hintText: 'Search by name or email',
                            hintStyle: const TextStyle(
                              color: Color(0xFF8E8E93),
                            ),
                            labelStyle: const TextStyle(
                              color: Color(0xFF8E8E93),
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF8E8E93),
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: AppTheme.outline.withOpacity(0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: AppTheme.outline.withOpacity(0.5),
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
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) =>
                              setDialogState(() => search = value),
                        ),
                        const SizedBox(height: 12),

                        // Employee List
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.outline.withOpacity(0.5),
                            ),
                          ),
                          constraints: BoxConstraints(
                            maxHeight: isMobile ? 200 : 240,
                          ),
                          child: visibleEmployees.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person_off_rounded,
                                          size: 32,
                                          color: Color(0xFF8E8E93),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'No employees found',
                                          style: TextStyle(
                                            color: Color(0xFF8E8E93),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: visibleEmployees.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: AppTheme.outline.withOpacity(0.3),
                                  ),
                                  itemBuilder: (context, index) {
                                    final emp = visibleEmployees[index];
                                    final selected = emp.id == employeeId;
                                    return ListTile(
                                      dense: true,
                                      selected: selected,
                                      selectedTileColor: AppTheme.primaryColor
                                          .withValues(alpha: 0.1),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                      title: Text(
                                        emp.name,
                                        style: const TextStyle(
                                          color: AppTheme.onBackground,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text(
                                        emp.email,
                                        style: const TextStyle(
                                          color: Color(0xFF8E8E93),
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: selected
                                          ? const Icon(
                                              Icons.check_circle_rounded,
                                              color: AppTheme.primaryColor,
                                              size: 20,
                                            )
                                          : null,
                                      onTap: () => setDialogState(
                                        () => employeeId = emp.id,
                                      ),
                                      hoverColor: AppTheme.primaryColor
                                          .withOpacity(0.05),
                                    );
                                  },
                                ),
                        ),
                        SizedBox(height: isMobile ? 16 : 20),

                        // Date & Time
                        Text(
                          'Date & Time',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          readOnly: true,
                          initialValue: '$date $time',
                          style: const TextStyle(color: AppTheme.onBackground),
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.access_time_rounded,
                              color: Color(0xFF8E8E93),
                              size: 18,
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: AppTheme.outline.withOpacity(0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: AppTheme.outline.withOpacity(0.5),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Task Type
                        Text(
                          'Task Type',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          readOnly: true,
                          initialValue: type,
                          style: const TextStyle(color: AppTheme.onBackground),
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              type == 'BOD'
                                  ? Icons.wb_sunny_rounded
                                  : Icons.nights_stay_rounded,
                              color: type == 'BOD'
                                  ? Colors.amber
                                  : Colors.indigo,
                              size: 18,
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: AppTheme.outline.withOpacity(0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: AppTheme.outline.withOpacity(0.5),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 20 : 24),

                        // Action Buttons
                        if (isMobile)
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _creating
                                      ? null
                                      : () async {
                                          if (employeeId.isEmpty) {
                                            _showSnack(
                                              'Please select an employee',
                                            );
                                            return;
                                          }

                                          final token = _token;
                                          if (token == null) return;

                                          setState(() => _creating = true);
                                          try {
                                            await TaskManagementService.createEntry(
                                              token,
                                              employeeId: employeeId,
                                              date: date,
                                              time: time,
                                              type: type,
                                            );
                                            if (mounted) {
                                              Navigator.of(context).pop();
                                              _showSnack(
                                                'Task entry created successfully',
                                              );
                                              await _loadData();
                                            }
                                          } catch (e) {
                                            _showSnack(
                                              e.toString().replaceFirst(
                                                'Exception: ',
                                                '',
                                              ),
                                            );
                                          } finally {
                                            if (mounted) {
                                              setState(() => _creating = false);
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: _creating
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Text(
                                          'Create Entry',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: _creating
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.onBackground,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: AppTheme.outline.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _creating
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.onBackground,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _creating
                                    ? null
                                    : () async {
                                        if (employeeId.isEmpty) {
                                          _showSnack(
                                            'Please select an employee',
                                          );
                                          return;
                                        }

                                        final token = _token;
                                        if (token == null) return;

                                        setState(() => _creating = true);
                                        try {
                                          await TaskManagementService.createEntry(
                                            token,
                                            employeeId: employeeId,
                                            date: date,
                                            time: time,
                                            type: type,
                                          );
                                          if (mounted) {
                                            Navigator.of(context).pop();
                                            _showSnack(
                                              'Task entry created successfully',
                                            );
                                            await _loadData();
                                          }
                                        } catch (e) {
                                          _showSnack(
                                            e.toString().replaceFirst(
                                              'Exception: ',
                                              '',
                                            ),
                                          );
                                        } finally {
                                          if (mounted) {
                                            setState(() => _creating = false);
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _creating
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        'Create Entry',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
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
          },
        );
      },
    );
  }

  Future<void> _showDetails(TaskManagementEntry entry) async {
    final token = _token;
    if (token == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            TaskManagementDetailsScreen(entryId: entry.id, token: token),
      ),
    );
  }

  String _statusLabel(TaskManagementEntry entry) {
    if (entry.tasks.isEmpty) return 'No Tasks';
    final allCompleted = entry.tasks.every(
      (task) => task.status == 'Completed',
    );
    final anyInReview = entry.tasks.any((task) => task.status == 'In Review');
    if (allCompleted) return 'Completed';
    if (anyInReview) return 'In Review';
    return 'In Progress';
  }

  Color _statusColor(TaskManagementEntry entry) {
    final label = _statusLabel(entry);
    switch (label) {
      case 'Completed':
        return Colors.green;
      case 'In Review':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Task Management',
          style: TextStyle(
            color: _textLight,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: _textLight),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creating ? null : _showCreateDialog,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stats Row ────────────────────────────────────────
                    isMobile
                        ? GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.5,
                            children: _statsCards(),
                          )
                        : Row(
                            children: _statsCards()
                                .map(
                                  (c) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: c,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                    const SizedBox(height: 20),

                    // ── Tasks Card ───────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _border.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Padding(
                            padding: EdgeInsets.all(isMobile ? 14 : 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.assignment_rounded,
                                        color: _primary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Task Entries',
                                          style: TextStyle(
                                            color: _textLight,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'Manage employee tasks',
                                          style: TextStyle(
                                            color: _textGrey,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                // Search + Filters
                                isMobile
                                    ? Column(
                                        children: [
                                          _buildSearchBar(),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildTypeFilter(),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  setState(() {
                                                    _search = '';
                                                    _selectedDate = null;
                                                    _typeFilter = 'all';
                                                    _searchController.clear();
                                                  });
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: _primary,
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 0,
                                                      ),
                                                ),
                                                icon: const Icon(
                                                  Icons.clear_all,
                                                  size: 16,
                                                ),
                                                label: const Text('Clear'),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          _buildDatePicker(),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(child: _buildSearchBar()),
                                          const SizedBox(width: 10),
                                          _buildDatePicker(),
                                          const SizedBox(width: 10),
                                          _buildTypeFilter(),
                                          const SizedBox(width: 10),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _search = '';
                                                _selectedDate = null;
                                                _typeFilter = 'all';
                                                _searchController.clear();
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _primary,
                                              foregroundColor: Colors.white,
                                            ),
                                            icon: const Icon(
                                              Icons.clear_all,
                                              size: 16,
                                            ),
                                            label: const Text('Clear'),
                                          ),
                                        ],
                                      ),
                              ],
                            ),
                          ),

                          // List
                          _buildEntriesList(_filteredEntries, isMobile),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: _textGrey),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textGrey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats Cards ─────────────────────────────────────────────────────────────
  List<Widget> _statsCards() => [
    _statCard(Icons.assignment_rounded, _primary, 'Total', _entries.length),
    _statCard(Icons.wb_sunny, Colors.blue, 'BOD', _bodCount),
    _statCard(Icons.nights_stay, Colors.purple, 'EOD', _eodCount),
    _statCard(
      Icons.check_circle_outlined,
      _green,
      'Completed',
      _completedCount,
    ),
  ];

  Widget _statCard(IconData icon, Color color, String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  color: _textLight,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: _textGrey,
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

  // ── Search Bar ───────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: _input,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primary.withOpacity(0.5), width: 1.2),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: _textLight, fontSize: 13),
        onChanged: (v) {
          setState(() => _search = v);
        },
        decoration: InputDecoration(
          hintText: 'Search by employee...',
          hintStyle: TextStyle(color: _textGrey, fontSize: 13),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search_rounded, color: _textGrey, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  // ── Type Filter ──────────────────────────────────────────────────────────────
  Widget _buildTypeFilter() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _input,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border.withOpacity(0.6)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _typeFilter,
          dropdownColor: _card,
          style: const TextStyle(color: _textLight, fontSize: 13),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _textGrey,
            size: 18,
          ),
          items: const [
            DropdownMenuItem(
              value: 'all',
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt_outlined,
                    size: 14,
                    color: Color(0xFF8E8E93),
                  ),
                  SizedBox(width: 6),
                  Text('All Types'),
                ],
              ),
            ),
            DropdownMenuItem(value: 'BOD', child: Text('BOD')),
            DropdownMenuItem(value: 'EOD', child: Text('EOD')),
          ],
          onChanged: (v) {
            setState(() => _typeFilter = v ?? 'all');
          },
        ),
      ),
    );
  }

  // ── Date Picker ──────────────────────────────────────────────────────────────
  Widget _buildDatePicker() {
    return ElevatedButton.icon(
      onPressed: _pickDate,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: _input,
        foregroundColor: _primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: _border.withOpacity(0.6)),
        ),
      ),
      icon: const Icon(Icons.calendar_month, size: 16),
      label: Text(
        _selectedDate == null
            ? 'Date'
            : DateFormat('dd/MM').format(_selectedDate!),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  // ── Entries List ─────────────────────────────────────────────────────────────
  Widget _buildEntriesList(List<TaskManagementEntry> entries, bool isMobile) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 48, color: _textGrey),
              const SizedBox(height: 12),
              Text(
                'No tasks found',
                style: TextStyle(color: _textGrey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: _border, indent: 20, endIndent: 20),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final status = _statusLabel(entry);
        final statusIcon = _getStatusIcon(status);
        final statusColor = _getStatusColor(status);

        return ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 14 : 20,
            vertical: 10,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 18),
          ),
          title: Text(
            entry.employeeName,
            style: const TextStyle(
              color: _textLight,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            '${entry.date} • ${entry.type} • ${entry.tasks.length} tasks',
            style: const TextStyle(color: _textGrey, fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_rounded,
                  color: _primary,
                  size: 18,
                ),
                onPressed: () => _showDetails(entry),
                constraints: const BoxConstraints(minWidth: 40),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          onTap: () => _showDetails(entry),
        );
      },
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle_rounded;
      case 'In Review':
        return Icons.visibility_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return _green;
      case 'In Review':
        return Colors.orange;
      default:
        return _primary;
    }
  }
}
