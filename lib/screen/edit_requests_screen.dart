import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../models/attendance_edit_request_model.dart';
import '../services/attendance_service.dart';
import '../services/token_storage_service.dart';
import '../theme/app_theme.dart';

class EditRequestsScreen extends StatefulWidget {
  final String? token;

  const EditRequestsScreen({super.key, this.token});

  @override
  State<EditRequestsScreen> createState() => _EditRequestsScreenState();
}

class _EditRequestsScreenState extends State<EditRequestsScreen>
    with TickerProviderStateMixin {
  //  Theme
  static const Color _bg = AppTheme.background;
  static const Color _card = Color(0xFF111111);
  static const Color _border = Color(0xFF1E1E1E);
  static const Color _primary = AppTheme.primaryColor;
  static const Color _green = AppTheme.secondaryColor;
  static const Color _red = AppTheme.errorColor;
  static const Color _orange = AppTheme.warningColor;

  //  State
  bool _isLoading = true;
  String? _error;
  String? _resolvedToken;

  List<AdminEditRequestData> _allRequests = [];
  String _filterView = 'pending'; // 'pending' | 'all'

  final Set<String> _processingIds = {};
  final Map<String, bool> _expandedCards = {};
  late AnimationController _animationController;
  late List<AnimationController> _cardAnimations = [];

  bool get _isEmployeeView =>
      _allRequests.isEmpty || _allRequests.every((r) => r.employee == null);

  int get _pendingCount =>
      _allRequests.where((r) => r.status == 'pending').length;
  int get _approvedCount =>
      _allRequests.where((r) => r.status == 'approved').length;
  int get _rejectedCount =>
      _allRequests.where((r) => r.status == 'rejected').length;

  List<AdminEditRequestData> get _visibleRequests {
    if (_filterView == 'pending') {
      return _allRequests.where((r) => r.status == 'pending').toList();
    }
    return _allRequests;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _init();
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var ctrl in _cardAnimations) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _init() async {
    String? tok = widget.token;
    if (tok == null || tok.isEmpty) {
      tok = await TokenStorageService().getToken();
    }
    _resolvedToken = tok;
    await _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    if (_cardAnimations.isNotEmpty) {
      for (var ctrl in _cardAnimations) {
        ctrl.dispose();
      }
      _cardAnimations.clear();
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tok = _resolvedToken;
      if (tok == null) throw Exception('No token. Please login again.');

      try {
        final pending = await AttendanceService.getPendingAdminEditRequests(
          token: tok,
        );
        final allRaw = await AttendanceService.getAllAdminEditRequests(
          token: tok,
        );
        if (!mounted) return;
        final pendingIds = pending.data.map((e) => e.id).toSet();
        final combined = [
          ...pending.data,
          ...allRaw.where((e) => !pendingIds.contains(e.id)),
        ];
        setState(() {
          _allRequests = combined;
          _isLoading = false;
        });
      } catch (_) {
        // fallback for employee role
        final fb = await AttendanceService.getEditRequests(token: tok);
        if (!mounted) return;
        setState(() {
          _allRequests = fb.data
              .map(
                (d) => AdminEditRequestData(
                  id: d.id,
                  attendanceId: d.attendance,
                  date: d.date,
                  originalCheckIn: d.originalCheckIn,
                  originalCheckOut: d.originalCheckOut,
                  requestedCheckIn: d.requestedCheckIn,
                  requestedCheckOut: d.requestedCheckOut,
                  reason: d.reason,
                  status: d.status,
                  createdAt: d.createdAt,
                  updatedAt: d.updatedAt,
                ),
              )
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  //  Approve / Reject

  Future<void> _approveRequest(AdminEditRequestData req) async {
    final ok = await _confirmDialog(
      title: 'Approve Request?',
      message:
          'Approve attendance correction for ${req.employee?.name ?? "this employee"} on '
          '${DateFormat("MMM d, yyyy").format(req.date.toLocal())}?',
      actionLabel: 'Approve',
      actionColor: _green,
    );
    if (ok != true) return;
    setState(() => _processingIds.add(req.id));
    try {
      await AttendanceService.reviewEditRequest(
        token: _resolvedToken!,
        requestId: req.id,
        action: 'approved',
      );
      _snack('Request approved successfully', _green);
      await _fetchRequests();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception:', '').trim(), _red);
    } finally {
      if (mounted) setState(() => _processingIds.remove(req.id));
    }
  }

  Future<void> _rejectRequest(AdminEditRequestData req) async {
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
          'Reject Request',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject attendance correction for ${req.employee?.name ?? "this employee"}?',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Add a review note (optional)...',
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
    setState(() => _processingIds.add(req.id));
    try {
      await AttendanceService.reviewEditRequest(
        token: _resolvedToken!,
        requestId: req.id,
        action: 'rejected',
        reviewNote: noteCtrl.text.trim().isNotEmpty
            ? noteCtrl.text.trim()
            : null,
      );
      _snack('Request rejected', _orange);
      await _fetchRequests();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception:', '').trim(), _red);
    } finally {
      if (mounted) setState(() => _processingIds.remove(req.id));
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

  //  Build

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isMobile),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                  ? _buildError()
                  : _buildContent(isMobile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
        SizedBox(height: 16),
        Text(
          'Loading requests...',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    ),
  );

  //  Header

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 16,
        12,
        isMobile ? 12 : 16,
        14,
      ),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // back + title
          Row(
            children: [
              GestureDetector(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          color: _primary,
                          size: 20,
                        ),
                        const SizedBox(width: 7),
                        const Flexible(
                          child: Text(
                            'Attendance Edit Requests',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isEmployeeView
                          ? 'Your attendance correction requests'
                          : 'Review and manage employee attendance correction requests',
                      style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // filter row
          Row(
            children: [
              _filterBtn(
                label: 'Pending',
                count: _pendingCount,
                active: _filterView == 'pending',
                onTap: () => setState(() => _filterView = 'pending'),
              ),
              const SizedBox(width: 8),
              _filterBtn(
                label: 'All Requests',
                count: null,
                active: _filterView == 'all',
                onTap: () => setState(() => _filterView = 'all'),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _fetchRequests,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
        ],
      ),
    );
  }

  Widget _filterBtn({
    required String label,
    required int? count,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _primary.withOpacity(0.16) : _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? _primary.withOpacity(0.45) : _border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active && count != null && count > 0) ...[
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            Text(
              label,
              style: TextStyle(
                color: active ? _primary : Colors.white60,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //  Error

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
            onPressed: _fetchRequests,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(backgroundColor: _primary),
          ),
        ],
      ),
    ),
  );

  //  Content

  Widget _buildContent(bool isMobile) {
    return RefreshIndicator(
      onRefresh: _fetchRequests,
      color: _primary,
      backgroundColor: _card,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildStats(isMobile)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 12 : 16,
                12,
                isMobile ? 12 : 16,
                6,
              ),
              child: Text(
                _filterView == 'pending' ? 'Pending Requests' : 'All Requests',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 13 : 15,
                ),
              ),
            ),
          ),
          if (_visibleRequests.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      color: Colors.white24,
                      size: 56,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _filterView == 'pending'
                          ? 'No pending requests'
                          : 'No requests found',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 12 : 16,
                0,
                isMobile ? 12 : 16,
                32,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, i) {
                  if (_cardAnimations.length <= i) {
                    _cardAnimations.add(
                      AnimationController(
                        duration: const Duration(milliseconds: 400),
                        vsync: this,
                      ),
                    );
                    _cardAnimations[i].forward();
                  }
                  return FadeSlideTransition(
                    animation: _cardAnimations[i],
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRequestCard(_visibleRequests[i], isMobile),
                    ),
                  );
                }, childCount: _visibleRequests.length),
              ),
            ),
        ],
      ),
    );
  }

  //  Stats row

  Widget _buildStats(bool isMobile) {
    final stats = [
      (Icons.pending_actions_rounded, _orange, _pendingCount, 'Pending Review'),
      (Icons.check_circle_outline_rounded, _green, _approvedCount, 'Approved'),
      (Icons.cancel_outlined, _red, _rejectedCount, 'Rejected'),
    ];

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          children: [
            for (int i = 0; i < stats.length; i++) ...[
              _statCard(
                stats[i].$1,
                stats[i].$2,
                stats[i].$3,
                stats[i].$4,
                isMobile,
              ),
              if (i < stats.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              stats[0].$1,
              stats[0].$2,
              stats[0].$3,
              stats[0].$4,
              false,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              stats[1].$1,
              stats[1].$2,
              stats[1].$3,
              stats[1].$4,
              false,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              stats[2].$1,
              stats[2].$2,
              stats[2].$3,
              stats[2].$4,
              false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    IconData icon,
    Color color,
    int count,
    String label,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 10,
        vertical: isMobile ? 14 : 12,
      ),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 16 : 18,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: isMobile ? 9 : 9.5,
                  ),
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

  //  Request card

  Widget _buildRequestCard(AdminEditRequestData req, bool isMobile) {
    if (req.employee == null) return _buildEmployeeCard(req, isMobile);
    final isPending = req.status == 'pending';
    final isProcessing = _processingIds.contains(req.id);
    final isExpanded = _expandedCards[req.id] ?? false;
    final dateStr = isMobile
        ? DateFormat('MMM d').format(req.date.toLocal())
        : DateFormat('EEE, MMM d, yyyy').format(req.date.toLocal());
    final createdStr = DateFormat(
      'MMM d, yyyy  hh:mm a',
    ).format(req.createdAt.toLocal());
    final statusColor = _statusColor(req.status);

    return GestureDetector(
      onLongPress: isPending ? () => _showQuickActions(context, req) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPending ? _orange.withOpacity(0.3) : _border,
          ),
          boxShadow: [
            BoxShadow(
              color: isPending ? _orange.withOpacity(0.15) : Colors.transparent,
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (isPending)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 3, color: _orange),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //  Employee info + date/status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _avatar(req.employee),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.employee?.name ?? 'Employee',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if ((req.employee?.department ?? '').isNotEmpty)
                              Text(
                                req.employee!.department!,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 11,
                                color: Colors.white38,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              req.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(color: _border, height: 1),
                  const SizedBox(height: 12),

                  //  Times
                  if (isMobile && !isExpanded)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _expandedCards[req.id] = true),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_outlined,
                              size: 13,
                              color: _primary,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Tap to view times',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.expand_more_rounded,
                              size: 16,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (!isMobile || isExpanded)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _timesBlock(
                                label: 'Original Times',
                                labelColor: Colors.white38,
                                blockBg: const Color(0xFF181818),
                                inTime: req.originalCheckIn,
                                outTime: req.originalCheckOut,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: _primary.withOpacity(0.55),
                                size: 17,
                              ),
                            ),
                            Expanded(
                              child: _timesBlock(
                                label: 'Requested Changes',
                                labelColor: _primary,
                                blockBg: _primary.withOpacity(0.07),
                                blockBorder: _primary.withOpacity(0.18),
                                inTime: req.requestedCheckIn,
                                outTime: req.requestedCheckOut,
                                highlight: true,
                              ),
                            ),
                          ],
                        ),
                        if (isMobile && isExpanded) ...[
                          const SizedBox(height: 8),
                          Divider(color: _border, height: 1),
                        ],
                      ],
                    ),

                  const SizedBox(height: 10),

                  //  Reason
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161616),
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
                          req.reason,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  //  Review note (rejected)
                  if (req.reviewNote != null && req.reviewNote!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _red.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _red.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Review Note',
                            style: TextStyle(
                              color: _red.withOpacity(0.7),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            req.reviewNote!,
                            style: TextStyle(
                              color: _red.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  //  Footer / action buttons
                  if (isMobile && isPending) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _actionBtn(
                            label: 'Reject',
                            icon: Icons.close_rounded,
                            color: _red,
                            filled: false,
                            loading: isProcessing,
                            onTap: isProcessing
                                ? null
                                : () => _rejectRequest(req),
                            isMobile: isMobile,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _actionBtn(
                            label: 'Approve',
                            icon: Icons.check_rounded,
                            color: _green,
                            filled: true,
                            loading: isProcessing,
                            onTap: isProcessing
                                ? null
                                : () => _approveRequest(req),
                            isMobile: isMobile,
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 10,
                          color: Colors.white24,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Submitted: $createdStr',
                          style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 10,
                          ),
                        ),
                        if (!isMobile && isPending) ...[
                          const Spacer(),
                          _actionBtn(
                            label: 'Reject',
                            icon: Icons.close_rounded,
                            color: _red,
                            filled: false,
                            loading: isProcessing,
                            onTap: isProcessing
                                ? null
                                : () => _rejectRequest(req),
                            isMobile: isMobile,
                          ),
                          const SizedBox(width: 8),
                          _actionBtn(
                            label: 'Approve',
                            icon: Icons.check_rounded,
                            color: _green,
                            filled: true,
                            loading: isProcessing,
                            onTap: isProcessing
                                ? null
                                : () => _approveRequest(req),
                            isMobile: isMobile,
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),

            if (isProcessing)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(
                    color: Colors.black45,
                    child: const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            if (isMobile && isPending)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.transparent, _green.withOpacity(0.2)],
                    ),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white24,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Employee-facing card ──────────────────────────────────────────────────

  Widget _buildEmployeeCard(AdminEditRequestData req, bool isMobile) {
    final statusColor = _statusColor(req.status);
    final fmt = DateFormat('hh:mm a');
    final fullDateStr =
        DateFormat('EEE, MMM d, yyyy').format(req.date.toLocal());
    final submittedStr =
        DateFormat('M/d/yyyy').format(req.createdAt.toLocal());
    final statusLabel =
        req.status[0].toUpperCase() + req.status.substring(1);

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.35)),
      ),
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: date | status badge ──────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.white60,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    fullDateStr,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 13 : 14,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Submitted $submittedStr',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: isMobile ? 10 : 12),

          // ── Original Times | Requested Changes ───────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Original Times
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Original Times',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _empTimeRow(
                        'In:',
                        req.originalCheckIn != null
                            ? fmt.format(req.originalCheckIn!.toLocal())
                            : '--:--',
                        false,
                      ),
                      const SizedBox(height: 3),
                      _empTimeRow(
                        'Out:',
                        req.originalCheckOut != null
                            ? fmt.format(req.originalCheckOut!.toLocal())
                            : '--:--',
                        false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Requested Changes
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Requested Changes',
                        style: TextStyle(
                          color: _primary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _empTimeRow(
                        'In:',
                        fmt.format(req.requestedCheckIn.toLocal()),
                        true,
                      ),
                      const SizedBox(height: 3),
                      _empTimeRow(
                        'Out:',
                        fmt.format(req.requestedCheckOut.toLocal()),
                        true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Reason ───────────────────────────────────────────────────
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12),
              children: [
                const TextSpan(
                  text: 'Reason: ',
                  style: TextStyle(color: Colors.white54),
                ),
                TextSpan(
                  text: req.reason,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Status message ───────────────────────────────────────────
          _buildEmployeeStatusMessage(req),
        ],
      ),
    );
  }

  Widget _buildEmployeeStatusMessage(AdminEditRequestData req) {
    if (req.status == 'approved') {
      return Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 14,
            color: _green,
          ),
          const SizedBox(width: 6),
          Text(
            'Approved by HR or Admin',
            style: TextStyle(color: _green, fontSize: 11.5),
          ),
        ],
      );
    } else if (req.status == 'rejected') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel_outlined, size: 14, color: _red),
              const SizedBox(width: 6),
              Text(
                'Request was rejected',
                style: TextStyle(color: _red, fontSize: 11.5),
              ),
            ],
          ),
          if (req.reviewNote != null && req.reviewNote!.isNotEmpty) ...[  
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                req.reviewNote!,
                style: TextStyle(
                  color: _red.withOpacity(0.8),
                  fontSize: 10.5,
                ),
              ),
            ),
          ],
        ],
      );
    }
    // pending
    return Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 14, color: _orange),
        const SizedBox(width: 6),
        const Text(
          'Awaiting review by HR or Admin',
          style: TextStyle(color: _orange, fontSize: 11.5),
        ),
      ],
    );
  }

  Widget _empTimeRow(String label, String time, bool highlight) => Row(
    children: [
      Text(
        label,
        style: TextStyle(
          color: highlight ? _primary.withOpacity(0.75) : Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(width: 4),
      Text(
        time,
        style: TextStyle(
          color: highlight ? Colors.white : Colors.white70,
          fontSize: 11.5,
          fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ],
  );

  void _showQuickActions(BuildContext context, AdminEditRequestData req) {
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
            const SizedBox(height: 20),
            _quickActionButton(
              icon: Icons.check_rounded,
              label: 'Approve Request',
              color: _green,
              onTap: () {
                Navigator.pop(ctx);
                _approveRequest(req);
              },
            ),
            const SizedBox(height: 10),
            _quickActionButton(
              icon: Icons.close_rounded,
              label: 'Reject Request',
              color: _red,
              onTap: () {
                Navigator.pop(ctx);
                _rejectRequest(req);
              },
            ),
            const SizedBox(height: 10),
            _quickActionButton(
              icon: Icons.view_agenda_rounded,
              label: 'View Details',
              color: _primary,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _expandedCards[req.id] = true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
  }

  Widget _avatar(EmployeeInfo? emp) {
    final photo = emp?.profilePhoto;
    final initials = (emp?.name ?? 'E')
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    if (photo != null && photo.isNotEmpty && photo.startsWith('http')) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: _primary.withOpacity(0.2),
        backgroundImage: NetworkImage(photo),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: _primary.withOpacity(0.2),
      child: Text(
        initials,
        style: TextStyle(
          color: _primary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _timesBlock({
    required String label,
    required Color labelColor,
    required Color blockBg,
    Color? blockBorder,
    DateTime? inTime,
    DateTime? outTime,
    bool highlight = false,
  }) {
    final fmt = DateFormat('hh:mm a');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: blockBg,
        borderRadius: BorderRadius.circular(9),
        border: blockBorder != null ? Border.all(color: blockBorder) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 5),
          _timeRow(
            Icons.login_rounded,
            'In:',
            inTime != null ? fmt.format(inTime.toLocal()) : '--:--',
            highlight,
          ),
          const SizedBox(height: 3),
          _timeRow(
            Icons.logout_rounded,
            'Out:',
            outTime != null ? fmt.format(outTime.toLocal()) : '--:--',
            highlight,
          ),
        ],
      ),
    );
  }

  Widget _timeRow(IconData icon, String label, String time, bool highlight) =>
      Row(
        children: [
          Icon(
            icon,
            size: 10,
            color: highlight ? _primary.withOpacity(0.7) : Colors.white38,
          ),
          const SizedBox(width: 4),
          Text(
            '$label ',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          Text(
            time,
            style: TextStyle(
              color: highlight ? Colors.white : Colors.white70,
              fontSize: 11,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      );

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required bool filled,
    required bool loading,
    VoidCallback? onTap,
    required bool isMobile,
  }) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 12,
        vertical: isMobile ? 9 : 7,
      ),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: filled ? null : Border.all(color: color.withOpacity(0.5)),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: filled ? Colors.white : color,
              ),
            )
          else
            Icon(
              icon,
              size: isMobile ? 15 : 13,
              color: filled ? Colors.white : color,
            ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : color,
              fontSize: isMobile ? 13 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return _green;
      case 'rejected':
        return _red;
      default:
        return _orange;
    }
  }
}

//  Scale Animation Button
class ScaleAnimationButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;

  const ScaleAnimationButton({super.key, this.onTap, required this.child});

  @override
  State<ScaleAnimationButton> createState() => _ScaleAnimationButtonState();
}

class _ScaleAnimationButtonState extends State<ScaleAnimationButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

//  Fade Slide Transition
class FadeSlideTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const FadeSlideTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }
}
