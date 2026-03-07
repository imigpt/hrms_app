import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/leave_management_model.dart';
import '../services/leave_service.dart';
import '../services/token_storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class LeaveManagementScreen extends StatefulWidget {
  final String? token;

  const LeaveManagementScreen({super.key, this.token});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen>
    with TickerProviderStateMixin {
  // â”€â”€ Colors â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const Color _bg = AppTheme.background;
  static const Color _card = Color(0xFF111111);
  static const Color _border = Color(0xFF1E1E1E);
  static const Color _primary = AppTheme.primaryColor;
  static const Color _green = AppTheme.secondaryColor;
  static const Color _red = AppTheme.errorColor;
  static const Color _orange = AppTheme.warningColor;
  static const Color _blue = Color(0xFF4FC3F7);

  // â”€â”€ State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  bool _isLoading = true;
  String? _error;
  String? _resolvedToken;
  List<AdminLeaveData> _allLeaves = [];

  // Filters
  String _statusFilter =
      'all'; // all | pending | approved | rejected | cancelled
  String _typeFilter = 'all'; // all | sick | paid | unpaid
  String _deptFilter = 'all'; // all | <department>

  final Set<String> _processingIds = {};
  List<AnimationController> _rowAnims = [];

  // â”€â”€ Computed â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  int get _totalCount => _allLeaves.length;
  int get _pendingCount =>
      _allLeaves.where((l) => l.status == 'pending').length;
  int get _approvedCount =>
      _allLeaves.where((l) => l.status == 'approved').length;
  int get _rejectedCount =>
      _allLeaves.where((l) => l.status == 'rejected').length;

  List<String> get _departments {
    final depts = <String>{};
    for (final l in _allLeaves) {
      if (l.user?.department != null && l.user!.department!.isNotEmpty) {
        depts.add(l.user!.department!);
      }
    }
    return ['all', ...depts.toList()..sort()];
  }

  List<AdminLeaveData> get _visibleLeaves {
    return _allLeaves.where((l) {
      final matchesStatus = _statusFilter == 'all' || l.status == _statusFilter;
      final matchesType = _typeFilter == 'all' || l.leaveType == _typeFilter;
      final matchesDept =
          _deptFilter == 'all' || (l.user?.department ?? '') == _deptFilter;
      return matchesStatus && matchesType && matchesDept;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // â”€â”€ Lifecycle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    for (final c in _rowAnims) c.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    String? tok = widget.token;
    if (tok == null || tok.isEmpty) {
      tok = await TokenStorageService().getToken();
    }
    _resolvedToken = tok;
    await _fetchLeaves();
  }

  Future<void> _fetchLeaves() async {
    for (final c in _rowAnims) c.dispose();
    _rowAnims = [];

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tok = _resolvedToken;
      if (tok == null) throw Exception('No token. Please login again.');

      final response = await LeaveService.getAdminLeaves(token: tok);

      if (!mounted) return;
      setState(() {
        _allLeaves = response.data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  // â”€â”€ Approve / Reject â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _approveLeave(AdminLeaveData leave) async {
    final ok = await _confirmDialog(
      title: 'Approve Leave?',
      message:
          'Approve ${leave.days == 0.5 ? "half-day" : "${leave.days.toStringAsFixed(leave.days == leave.days.truncate() ? 0 : 1)} day(s)"} '
          '${_leaveTypeLabel(leave.leaveType)} leave for '
          '${leave.user?.name ?? "this employee"}?',
      actionLabel: 'Approve',
      actionColor: _green,
    );
    if (ok != true) return;

    setState(() => _processingIds.add(leave.id));
    try {
      await LeaveService.approveAdminLeave(
        token: _resolvedToken!,
        leaveId: leave.id,
      );
      _snack('Leave approved successfully', _green);

      // Show notification for leave approval
      await NotificationService().showLeaveApprovedNotification(
        employeeName: leave.user?.name ?? 'Employee',
        leaveType: _leaveTypeLabel(leave.leaveType),
        startDate: DateFormat(
          'MMM dd',
        ).format(leave.startDate ?? DateTime.now()),
        endDate: DateFormat('MMM dd').format(leave.endDate ?? DateTime.now()),
      );

      await _fetchLeaves();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception:', '').trim(), _red);
    } finally {
      if (mounted) setState(() => _processingIds.remove(leave.id));
    }
  }

  Future<void> _rejectLeave(AdminLeaveData leave) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _border),
        ),
        title: const Text(
          'Reject Leave Request',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject ${_leaveTypeLabel(leave.leaveType)} leave for ${leave.user?.name ?? "this employee"}?',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Add rejection note (optional)...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _red, width: 1.2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _processingIds.add(leave.id));
    try {
      await LeaveService.rejectAdminLeave(
        token: _resolvedToken!,
        leaveId: leave.id,
        reviewNote: noteCtrl.text.trim().isNotEmpty
            ? noteCtrl.text.trim()
            : null,
      );
      _snack('Leave request rejected', _orange);

      // Show notification for leave rejection
      await NotificationService().showLeaveRejectedNotification(
        employeeName: leave.user?.name ?? 'Employee',
        leaveType: _leaveTypeLabel(leave.leaveType),
        reason: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
      );

      await _fetchLeaves();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception:', '').trim(), _red);
    } finally {
      if (mounted) setState(() => _processingIds.remove(leave.id));
    }
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String actionLabel,
    required Color actionColor,
  }) => showDialog<bool>(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => AlertDialog(
      backgroundColor: _card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _border),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: actionColor),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(actionLabel),
        ),
      ],
    ),
  );

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // â”€â”€ Root build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final isMob = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isMob),
            Expanded(
              child: _isLoading
                  ? _buildLoader()
                  : _error != null
                  ? _buildError()
                  : _buildBody(isMob),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Top bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTopBar(bool isMob) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMob ? 14 : 20, vertical: 14),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          _TapScaler(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Leaves',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Manage leave requests from all employees and HR managers',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _TapScaler(
            onTap: _fetchLeaves,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white60,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Refresh',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
        const SizedBox(height: 14),
        const Text(
          'Loading leave requests...',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: _red, size: 52),
          const SizedBox(height: 14),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _fetchLeaves,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(backgroundColor: _primary),
          ),
        ],
      ),
    ),
  );

  // â”€â”€ Body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildBody(bool isMob) {
    return RefreshIndicator(
      onRefresh: _fetchLeaves,
      color: _primary,
      backgroundColor: _card,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMob ? 14 : 20,
                18,
                isMob ? 14 : 20,
                0,
              ),
              child: _buildStats(isMob),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMob ? 14 : 20,
                16,
                isMob ? 14 : 20,
                0,
              ),
              child: _buildFilters(isMob),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMob ? 14 : 20,
                18,
                isMob ? 14 : 20,
                32,
              ),
              child: _buildTableSection(isMob),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Stats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildStats(bool isMob) {
    final defs = [
      _StatDef(
        Icons.calendar_today_rounded,
        const Color(0xFF7B3F00),
        Colors.orange.shade700,
        _totalCount,
        'Total Requests',
      ),
      _StatDef(
        Icons.calendar_month_rounded,
        const Color(0xFF5A4000),
        Colors.amber.shade600,
        _pendingCount,
        'Pending',
      ),
      _StatDef(
        Icons.check_circle_rounded,
        const Color(0xFF003A1F),
        _green,
        _approvedCount,
        'Approved',
      ),
      _StatDef(
        Icons.cancel_rounded,
        const Color(0xFF3A0010),
        _red,
        _rejectedCount,
        'Rejected',
      ),
    ];

    if (isMob) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.9,
        children: defs.map((d) => _statCard(d)).toList(),
      );
    }

    return Row(
      children: defs
          .map(
            (d) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: d == defs.last ? 0 : 12),
                child: _statCard(d),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _statCard(_StatDef d) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: d.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(d.icon, color: d.iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  d.label,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Filters â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildFilters(bool isMob) {
    final depts = _departments;

    if (isMob) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filterGroupLabel('Status'),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  'all',
                  'All Status',
                  Colors.white54,
                  _statusFilter,
                  (v) => setState(() => _statusFilter = v),
                ),
                const SizedBox(width: 6),
                _filterChip(
                  'pending',
                  'Pending',
                  _orange,
                  _statusFilter,
                  (v) => setState(() => _statusFilter = v),
                ),
                const SizedBox(width: 6),
                _filterChip(
                  'approved',
                  'Approved',
                  _green,
                  _statusFilter,
                  (v) => setState(() => _statusFilter = v),
                ),
                const SizedBox(width: 6),
                _filterChip(
                  'rejected',
                  'Rejected',
                  _red,
                  _statusFilter,
                  (v) => setState(() => _statusFilter = v),
                ),
                const SizedBox(width: 6),
                _filterChip(
                  'cancelled',
                  'Cancelled',
                  Colors.white38,
                  _statusFilter,
                  (v) => setState(() => _statusFilter = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _filterGroupLabel('Leave Type'),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  'all',
                  'All Types',
                  Colors.white54,
                  _typeFilter,
                  (v) => setState(() => _typeFilter = v),
                ),
                const SizedBox(width: 6),
                _filterChip(
                  'sick',
                  'Sick',
                  _blue,
                  _typeFilter,
                  (v) => setState(() => _typeFilter = v),
                ),
                const SizedBox(width: 6),
                _filterChip(
                  'paid',
                  'Paid',
                  _green,
                  _typeFilter,
                  (v) => setState(() => _typeFilter = v),
                ),
                const SizedBox(width: 6),
                _filterChip(
                  'unpaid',
                  'Unpaid',
                  _orange,
                  _typeFilter,
                  (v) => setState(() => _typeFilter = v),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          if (depts.length > 1) ...[
            Expanded(
              child: _dropdownFilter(
                icon: Icons.business_outlined,
                label: _deptFilter == 'all' ? 'All Departments' : _deptFilter,
                isActive: _deptFilter != 'all',
                items: depts
                    .map(
                      (d) => PopupMenuItem<String>(
                        value: d,
                        child: Text(
                          d == 'all' ? 'All Departments' : d,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onSelected: (v) => setState(() => _deptFilter = v),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: _dropdownFilter(
              icon: Icons.filter_list_rounded,
              label: _statusFilter == 'all'
                  ? 'All Status'
                  : _capitalize(_statusFilter),
              isActive: _statusFilter != 'all',
              items: [
                _popItem('all', 'All Status'),
                _popItem('pending', 'Pending'),
                _popItem('approved', 'Approved'),
                _popItem('rejected', 'Rejected'),
                _popItem('cancelled', 'Cancelled'),
              ],
              onSelected: (v) => setState(() => _statusFilter = v),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _dropdownFilter(
              icon: Icons.label_outline_rounded,
              label: _typeFilter == 'all'
                  ? 'All Types'
                  : _leaveTypeLabel(_typeFilter),
              isActive: _typeFilter != 'all',
              items: [
                _popItem('all', 'All Types'),
                _popItem('sick', 'Sick Leave'),
                _popItem('paid', 'Paid Leave'),
                _popItem('unpaid', 'Unpaid Leave'),
              ],
              onSelected: (v) => setState(() => _typeFilter = v),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _popItem(String value, String label) =>
      PopupMenuItem<String>(
        value: value,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      );

  Widget _dropdownFilter({
    required IconData icon,
    required String label,
    required bool isActive,
    required List<PopupMenuItem<String>> items,
    required void Function(String) onSelected,
  }) => PopupMenuButton<String>(
    onSelected: onSelected,
    color: const Color(0xFF1A1A1A),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: _border),
    ),
    itemBuilder: (ctx) => items,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? _primary.withOpacity(0.08) : const Color(0xFF161616),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: isActive ? _primary.withOpacity(0.5) : _border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: isActive ? _primary : Colors.white38),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? _primary : Colors.white60,
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: isActive ? _primary : Colors.white38,
          ),
        ],
      ),
    ),
  );

  Widget _filterGroupLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white54,
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _filterChip(
    String value,
    String label,
    Color color,
    String current,
    void Function(String) onTap,
  ) {
    final active = current == value;
    return _TapScaler(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.14) : _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? color.withOpacity(0.5) : _border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : Colors.white54,
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // â”€â”€ Table section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTableSection(bool isMob) {
    final visible = _visibleLeaves;

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Text(
                  'All Leave Requests',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${visible.length}',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: _border, height: 1),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      color: Colors.white24,
                      size: 52,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _statusFilter == 'all'
                          ? 'No leave requests found'
                          : 'No $_statusFilter requests',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isMob)
            _buildMobileCards(visible)
          else
            _buildDesktopTable(visible),
        ],
      ),
    );
  }

  // â”€â”€ Desktop table â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildDesktopTable(List<AdminLeaveData> rows) {
    const hdStyle = TextStyle(
      color: Colors.white38,
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: const Color(0xFF0D0D0D),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 180,
                    child: Text('Applicant', style: hdStyle),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text('Department', style: hdStyle),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text('Leave Type', style: hdStyle),
                  ),
                  SizedBox(width: 150, child: Text('Duration', style: hdStyle)),
                  SizedBox(width: 200, child: Text('Reason', style: hdStyle)),
                  SizedBox(
                    width: 110,
                    child: Text('Applied On', style: hdStyle),
                  ),
                  SizedBox(width: 100, child: Text('Status', style: hdStyle)),
                  SizedBox(width: 90, child: Text('Actions', style: hdStyle)),
                ],
              ),
            ),
            Divider(color: _border, height: 1),
            ...rows.asMap().entries.map((entry) {
              final i = entry.key;
              final leave = entry.value;
              if (_rowAnims.length <= i) {
                final ctrl = AnimationController(
                  duration: const Duration(milliseconds: 350),
                  vsync: this,
                );
                _rowAnims.add(ctrl);
                ctrl.forward();
              }
              return _FadeSlide(
                animation: _rowAnims[i],
                child: _buildTableRow(leave, i),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(AdminLeaveData leave, int index) {
    final isPending = leave.status == 'pending';
    final isProcessing = _processingIds.contains(leave.id);
    final isEven = index % 2 == 0;

    final fmt = DateFormat('d/M/yyyy');
    final startStr = fmt.format(leave.startDate.toLocal());
    final endStr = fmt.format(leave.endDate.toLocal());
    final appliedStr = DateFormat(
      'MMM d, yyyy',
    ).format(leave.createdAt.toLocal());

    final sameDay =
        leave.startDate.toLocal().day == leave.endDate.toLocal().day &&
        leave.startDate.toLocal().month == leave.endDate.toLocal().month &&
        leave.startDate.toLocal().year == leave.endDate.toLocal().year;

    return Stack(
      children: [
        Container(
          color: isEven ? Colors.transparent : const Color(0xFF0A0A0A),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Applicant
              SizedBox(
                width: 180,
                child: Row(
                  children: [
                    _avatar(leave.user),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.user?.name ?? 'Employee',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((leave.user?.employeeId ?? '').isNotEmpty)
                            Text(
                              leave.user!.employeeId!,
                              style: const TextStyle(
                                color: Colors.white38,
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
              // Department
              SizedBox(
                width: 120,
                child: Row(
                  children: [
                    const Icon(
                      Icons.business_outlined,
                      size: 12,
                      color: Colors.white24,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        leave.user?.department ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Leave type badge
              SizedBox(width: 110, child: _leaveTypeBadge(leave.leaveType)),
              // Duration
              SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sameDay)
                      Text(
                        startStr,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      )
                    else ...[
                      Text(
                        startStr,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'to $endStr',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        leave.days == 0.5
                            ? '0.5 day'
                            : '${leave.days.toStringAsFixed(leave.days % 1 == 0 ? 0 : 1)} day${leave.days == 1 ? "" : "s"}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Reason
              SizedBox(
                width: 200,
                child: Text(
                  leave.reason,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Applied On
              SizedBox(
                width: 110,
                child: Text(
                  appliedStr,
                  style: const TextStyle(color: Colors.white38, fontSize: 11.5),
                ),
              ),
              // Status badge
              SizedBox(width: 100, child: _statusBadge(leave.status)),
              // Actions
              SizedBox(
                width: 90,
                child: isPending
                    ? Row(
                        children: [
                          _iconAction(
                            icon: Icons.check_rounded,
                            color: _green,
                            tooltip: 'Approve',
                            onTap: () => _approveLeave(leave),
                          ),
                          const SizedBox(width: 8),
                          _iconAction(
                            icon: Icons.close_rounded,
                            color: _red,
                            tooltip: 'Reject',
                            onTap: () => _rejectLeave(leave),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        if (isPending)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 3, color: _orange),
          ),
        if (isProcessing)
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Divider(color: _border, height: 1),
        ),
      ],
    );
  }

  // â”€â”€ Mobile cards â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildMobileCards(List<AdminLeaveData> rows) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final leave = entry.value;
          if (_rowAnims.length <= i) {
            final ctrl = AnimationController(
              duration: const Duration(milliseconds: 350),
              vsync: this,
            );
            _rowAnims.add(ctrl);
            ctrl.forward();
          }
          return _FadeSlide(
            animation: _rowAnims[i],
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMobileCard(leave),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileCard(AdminLeaveData leave) {
    final isPending = leave.status == 'pending';
    final isProcessing = _processingIds.contains(leave.id);
    final fmt = DateFormat('d MMM yyyy');
    final startStr = fmt.format(leave.startDate.toLocal());
    final endStr = fmt.format(leave.endDate.toLocal());
    final appliedStr = DateFormat(
      'd MMM yyyy',
    ).format(leave.createdAt.toLocal());

    final sameDay =
        leave.startDate.toLocal().day == leave.endDate.toLocal().day &&
        leave.startDate.toLocal().month == leave.endDate.toLocal().month &&
        leave.startDate.toLocal().year == leave.endDate.toLocal().year;

    return GestureDetector(
      onLongPress: isPending ? () => _showQuickActions(leave) : null,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPending ? _orange.withOpacity(0.3) : _border,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Row(
                    children: [
                      _avatar(leave.user),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              leave.user?.name ?? 'Employee',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if ((leave.user?.employeeId ?? '').isNotEmpty)
                              Text(
                                leave.user!.employeeId!,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _statusBadge(leave.status),
                    ],
                  ),
                ),
                Divider(color: _border, height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _leaveTypeBadge(leave.leaveType),
                      if (leave.isHalfDay)
                        _infoBadge(
                          icon: Icons.timelapse_rounded,
                          text:
                              'Â½ ${leave.session != null ? _capitalize(leave.session!) : "Day"}',
                          color: _blue,
                        ),
                      _infoBadge(
                        icon: Icons.calendar_today_outlined,
                        text: sameDay ? startStr : '$startStr â€“ $endStr',
                        color: Colors.white38,
                      ),
                      _infoBadge(
                        icon: Icons.timer_outlined,
                        text: leave.days == 0.5
                            ? '0.5 day'
                            : '${leave.days.toStringAsFixed(leave.days % 1 == 0 ? 0 : 1)} day${leave.days == 1 ? "" : "s"}',
                        color: Colors.white38,
                      ),
                      if ((leave.user?.department ?? '').isNotEmpty)
                        _infoBadge(
                          icon: Icons.business_outlined,
                          text: leave.user!.department!,
                          color: Colors.white38,
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D0D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reason',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          leave.reason,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if ((leave.reviewNote ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _red.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _red.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.note_outlined,
                            color: _red.withOpacity(0.6),
                            size: 13,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              leave.reviewNote!,
                              style: TextStyle(
                                color: _red.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: _border)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: Colors.white24,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Applied: $appliedStr',
                            style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                      if (isPending) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _actionBtn(
                                label: 'Reject',
                                icon: Icons.close_rounded,
                                color: _red,
                                filled: false,
                                loading: false,
                                onTap: () => _rejectLeave(leave),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _actionBtn(
                                label: 'Approve',
                                icon: Icons.check_rounded,
                                color: _green,
                                filled: true,
                                loading: false,
                                onTap: () => _approveLeave(leave),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isPending)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: const BoxDecoration(
                  color: _orange,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            ),
          if (isProcessing)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                  child: Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // â”€â”€ Quick actions sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showQuickActions(AdminLeaveData leave) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _avatar(leave.user),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leave.user?.name ?? 'Employee',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_leaveTypeLabel(leave.leaveType)} â€¢ ${leave.days} day(s)',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: _border),
            const SizedBox(height: 10),
            _qBtn(
              icon: Icons.check_rounded,
              label: 'Approve Leave',
              color: _green,
              onTap: () {
                Navigator.pop(ctx);
                _approveLeave(leave);
              },
            ),
            const SizedBox(height: 10),
            _qBtn(
              icon: Icons.close_rounded,
              label: 'Reject Leave',
              color: _red,
              onTap: () {
                Navigator.pop(ctx);
                _rejectLeave(leave);
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _qBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );

  // â”€â”€ Widget helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _avatar(LeaveUser? user) {
    final photo = user?.profilePhoto;
    final initials = (user?.name ?? 'E')
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    if (photo != null && photo.isNotEmpty && photo.startsWith('http')) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: _primary.withOpacity(0.2),
        backgroundImage: NetworkImage(photo),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: _primary.withOpacity(0.2),
      child: Text(
        initials,
        style: TextStyle(
          color: _primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _leaveTypeBadge(String type) {
    final color = _typeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _leaveTypeLabel(type),
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _infoBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _iconAction({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) => _TapScaler(
    onTap: onTap,
    child: Tooltip(
      message: tooltip,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    ),
  );

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required bool filled,
    required bool loading,
    VoidCallback? onTap,
  }) => _TapScaler(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: filled ? null : Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: filled ? Colors.white : color,
              ),
            )
          else
            Icon(icon, size: 15, color: filled ? Colors.white : color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );

  // â”€â”€ Color / label helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return _green;
      case 'rejected':
        return _red;
      case 'cancelled':
        return Colors.white38;
      default:
        return _orange;
    }
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'sick':
        return _blue;
      case 'unpaid':
        return _orange;
      default:
        return _primary;
    }
  }

  String _leaveTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'sick':
        return 'Sick';
      case 'unpaid':
        return 'Unpaid';
      default:
        return 'Paid';
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// â”€â”€ Stat definition â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _StatDef {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final int count;
  final String label;
  const _StatDef(
    this.icon,
    this.bgColor,
    this.iconColor,
    this.count,
    this.label,
  );
}

// ── Reusable scale-press animation ────────────────────────────────────────────

class _TapScaler extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _TapScaler({this.onTap, required this.child});

  @override
  State<_TapScaler> createState() => _TapScalerState();
}

class _TapScalerState extends State<_TapScaler>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    duration: const Duration(milliseconds: 100),
    vsync: this,
    value: 1,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: Tween(
          begin: 0.93,
          end: 1.0,
        ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)),
        child: widget.child,
      ),
    );
  }
}

// ── Fade + slide entrance ─────────────────────────────────────────────────────

class _FadeSlide extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _FadeSlide({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - animation.value)),
          child: child,
        ),
      ),
    );
  }
}
