import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/attendance_records_model.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';

class AdminAttendanceScreen extends StatefulWidget {
  final String? token;

  const AdminAttendanceScreen({super.key, this.token});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  // ─── Theme Colors ───────────────────────────────────────────────────────────
  static const Color _bg = AppTheme.background;
  static const Color _card = AppTheme.surface;
  static const Color _input = AppTheme.surfaceVariant;
  static const Color _border = AppTheme.outline;
  static const Color _primary = AppTheme.primaryColor;
  static const Color _green = AppTheme.secondaryColor;
  static const Color _red = AppTheme.errorColor;
  static const Color _orange = AppTheme.warningColor;
  static const Color _textLight = AppTheme.onSurface;
  static const Color _textGrey = Color(0xFF8E8E93);

  // ─── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;
  List<AttendanceRecord> _allRecords = [];
  List<AttendanceRecord> _filteredRecords = [];

  // Filters
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _userFilter = 'all'; // future: per-user filtering

  // Stats
  int _presentCount = 0;
  int _lateCount = 0;
  int _absentCount = 0;
  int _halfDayCount = 0;

  // For photo dialog
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendance() async {
    if (widget.token == null || widget.token!.isEmpty) {
      setState(() {
        _error = 'No authentication token';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await AttendanceService.getAllAttendance(widget.token!);

      if (!mounted) return;

      if (result['success'] == true) {
        final rawList = result['data'] as List<dynamic>;
        final records = rawList
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          _allRecords = records;
          _computeStats(records);
          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load attendance';
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

  void _computeStats(List<AttendanceRecord> records) {
    _presentCount = records.where((r) => r.status == 'present').length;
    _lateCount = records.where((r) => r.status == 'late').length;
    _absentCount = records.where((r) => r.status == 'absent').length;
    _halfDayCount = records.where((r) => r.status == 'half-day').length;
  }

  void _applyFilters() {
    final q = _searchQuery.toLowerCase();
    setState(() {
      _filteredRecords = _allRecords.where((r) {
        // Text search: name, employeeId, department
        final matchSearch = q.isEmpty ||
            r.user.name.toLowerCase().contains(q) ||
            r.user.employeeId.toLowerCase().contains(q) ||
            r.user.department.toLowerCase().contains(q);

        // Status filter
        final matchStatus =
            _statusFilter == 'all' || r.status == _statusFilter;

        return matchSearch && matchStatus;
      }).toList();

      _computeStats(_filteredRecords);
    });
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('hh:mm a').format(dt.toLocal());
  }

  String _formatDate(DateTime dt) {
    return DateFormat('MMM d, yyyy').format(dt.toLocal());
  }

  String _formatWorkHours(double h) {
    if (h <= 0) return '-';
    final hInt = h.floor();
    final mInt = ((h - hInt) * 60).round();
    return '${hInt}h ${mInt}m';
  }

  String _statusLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'present':
        return 'Present';
      case 'late':
        return 'Late';
      case 'absent':
        return 'Absent';
      case 'half-day':
        return 'Half Day';
      case 'on-leave':
        return 'On Leave';
      default:
        return raw;
    }
  }

  Color _statusColor(String raw) {
    switch (raw.toLowerCase()) {
      case 'present':
        return _green;
      case 'late':
        return _orange;
      case 'absent':
        return _red;
      case 'half-day':
        return _primary;
      case 'on-leave':
        return Colors.blue;
      default:
        return _textGrey;
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showPhotoDialog(String photoUrl) {
    if (photoUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                photoUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, __, ___) => Container(
                  color: _card,
                  padding: const EdgeInsets.all(40),
                  child: Icon(Icons.broken_image, color: _textGrey, size: 60),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
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
          'Attendance',
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
            onPressed: _loadAttendance,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadAttendance,
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
                                childAspectRatio: 1.6,
                                children: _statsCards(),
                              )
                            : Row(
                                children: _statsCards()
                                    .map((c) => Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 12),
                                            child: c,
                                          ),
                                        ))
                                    .toList(),
                              ),
                        const SizedBox(height: 20),

                        // ── Attendance Records Card ───────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _border.withOpacity(0.4), width: 1),
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
                                          child: Icon(Icons.schedule_rounded, color: _primary, size: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Attendance Records',
                                              style: TextStyle(
                                                color: _textLight,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              "Today's attendance overview",
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
                                                  Expanded(child: _buildStatusFilter()),
                                                  const SizedBox(width: 8),
                                                  _buildExportButton(),
                                                ],
                                              ),
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              Expanded(child: _buildSearchBar()),
                                              const SizedBox(width: 10),
                                              _buildStatusFilter(),
                                              const SizedBox(width: 10),
                                              _buildExportButton(),
                                            ],
                                          ),
                                  ],
                                ),
                              ),

                              // Table
                              _filteredRecords.isEmpty
                                  ? _buildEmpty()
                                  : _buildTable(isMobile),
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

  // ── Stats Cards ─────────────────────────────────────────────────────────────
  List<Widget> _statsCards() => [
        _statCard(Icons.check_circle_outline_rounded, _green, 'Present', _presentCount),
        _statCard(Icons.schedule_rounded, _orange, 'Late', _lateCount),
        _statCard(Icons.cancel_outlined, _red, 'Absent', _absentCount),
        _statCard(Icons.timelapse_rounded, _primary, 'Half Day', _halfDayCount),
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
          _searchQuery = v;
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: 'Search employee...',
          hintStyle: TextStyle(color: _textGrey, fontSize: 13),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search_rounded, color: _textGrey, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  // ── Status Filter ────────────────────────────────────────────────────────────
  Widget _buildStatusFilter() {
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
          value: _statusFilter,
          dropdownColor: _card,
          style: const TextStyle(color: _textLight, fontSize: 13),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _textGrey, size: 18),
          items: const [
            DropdownMenuItem(value: 'all', child: Row(
              children: [Icon(Icons.filter_alt_outlined, size: 14, color: Color(0xFF8E8E93)), SizedBox(width: 6), Text('All Status')],
            )),
            DropdownMenuItem(value: 'present', child: Text('Present')),
            DropdownMenuItem(value: 'late', child: Text('Late')),
            DropdownMenuItem(value: 'absent', child: Text('Absent')),
            DropdownMenuItem(value: 'half-day', child: Text('Half Day')),
            DropdownMenuItem(value: 'on-leave', child: Text('On Leave')),
          ],
          onChanged: (v) {
            setState(() => _statusFilter = v ?? 'all');
            _applyFilters();
          },
        ),
      ),
    );
  }

  // ── Export Button ─────────────────────────────────────────────────────────────
  Widget _buildExportButton() {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export feature coming soon'), duration: Duration(seconds: 2)),
      ),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _input,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border.withOpacity(0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_rounded, color: _textGrey, size: 16),
            const SizedBox(width: 6),
            const Text(
              'Export',
              style: TextStyle(color: _textLight, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ── Table ────────────────────────────────────────────────────────────────────
  Widget _buildTable(bool isMobile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - (isMobile ? 24 : 40),
        ),
        child: Column(
          children: [
            // Column headers
            Container(
              decoration: BoxDecoration(
                color: _input,
                border: Border(
                  top: BorderSide(color: _border.withOpacity(0.3), width: 1),
                  bottom: BorderSide(color: _border.withOpacity(0.3), width: 1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _colHeader('Employee', 180),
                    _colHeader('Date', 110),
                    _colHeader('Punch In', 100),
                    _colHeader('Punch Out', 100),
                    _colHeader('Total Hours', 100),
                    _colHeader('Status', 100),
                    _colHeader('Photo', 80),
                    _colHeader('Check In Location', 150),
                    _colHeader('Check Out Location', 150),
                  ],
                ),
              ),
            ),
            // Rows
            ...List.generate(_filteredRecords.length, (i) {
              final r = _filteredRecords[i];
              return _buildRow(r, i);
            }),
          ],
        ),
      ),
    );
  }

  Widget _colHeader(String label, double width) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: const TextStyle(
          color: _textGrey,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRow(AttendanceRecord r, int index) {
    final isEven = index % 2 == 0;
    final statusColor = _statusColor(r.status);
    final checkInLat = r.checkIn.location?.latitude;
    final checkInLng = r.checkIn.location?.longitude;
    final checkOutLat = r.checkOut?.location?.latitude;
    final checkOutLng = r.checkOut?.location?.longitude;
    final photoUrl = r.checkIn.photo.url;

    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.transparent : _input.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: _border.withOpacity(0.2), width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Employee
            SizedBox(
              width: 180,
              child: Row(
                children: [
                  _avatar(r.user.name),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.user.name,
                          style: const TextStyle(
                            color: _textLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (r.user.department.isNotEmpty)
                          Text(
                            r.user.department,
                            style: const TextStyle(color: _textGrey, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Date
            SizedBox(
              width: 110,
              child: Text(
                _formatDate(r.date),
                style: const TextStyle(color: _textLight, fontSize: 12),
              ),
            ),
            // Punch In
            SizedBox(
              width: 100,
              child: Text(
                _formatTime(r.checkIn.time),
                style: TextStyle(
                  color: r.checkIn.time != null ? _textLight : _textGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Punch Out
            SizedBox(
              width: 100,
              child: Text(
                r.checkOut != null ? _formatTime(r.checkOut!.time) : '-',
                style: const TextStyle(color: _textGrey, fontSize: 12),
              ),
            ),
            // Total Hours
            SizedBox(
              width: 100,
              child: Text(
                _formatWorkHours(r.workHours),
                style: const TextStyle(color: _textLight, fontSize: 12),
              ),
            ),
            // Status
            SizedBox(
              width: 100,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  _statusLabel(r.status),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Photo
            SizedBox(
              width: 80,
              child: photoUrl.isNotEmpty
                  ? GestureDetector(
                      onTap: () => _showPhotoDialog(photoUrl),
                      child: Row(
                        children: [
                          Icon(Icons.image_rounded, color: _primary, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'View',
                            style: TextStyle(
                              color: _primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: _primary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text('-', style: TextStyle(color: _textGrey, fontSize: 12)),
            ),
            // Check In Location
            SizedBox(
              width: 150,
              child: checkInLat != null
                  ? GestureDetector(
                      onTap: () => _openMaps(checkInLat, checkInLng!),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: _primary.withOpacity(0.7), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${checkInLat.toStringAsFixed(4)},\n${checkInLng!.toStringAsFixed(4)}',
                            style: TextStyle(
                              color: _primary,
                              fontSize: 11,
                              decoration: TextDecoration.underline,
                              decorationColor: _primary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: _textGrey, size: 14),
                        const SizedBox(width: 4),
                        Text('-', style: TextStyle(color: _textGrey, fontSize: 12)),
                      ],
                    ),
            ),
            // Check Out Location
            SizedBox(
              width: 150,
              child: checkOutLat != null
                  ? GestureDetector(
                      onTap: () => _openMaps(checkOutLat, checkOutLng!),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: _primary.withOpacity(0.7), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${checkOutLat.toStringAsFixed(4)},\n${checkOutLng!.toStringAsFixed(4)}',
                            style: TextStyle(
                              color: _primary,
                              fontSize: 11,
                              decoration: TextDecoration.underline,
                              decorationColor: _primary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: _textGrey, size: 14),
                        const SizedBox(width: 4),
                        Text('-', style: TextStyle(color: _textGrey, fontSize: 12)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Avatar ───────────────────────────────────────────────────────────────────
  Widget _avatar(String name) {
    final initials = _getInitials(name);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [_primary.withOpacity(0.3), _primary.withOpacity(0.15)],
        ),
        border: Border.all(color: _primary.withOpacity(0.25), width: 1),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: _primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0] : '';
    final last = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + last).toUpperCase().isEmpty ? '?' : (first + last).toUpperCase();
  }

  // ── Empty / Error ─────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, color: _textGrey, size: 48),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty || _statusFilter != 'all'
                  ? 'No records match your filters'
                  : 'No attendance records found',
              style: const TextStyle(color: _textGrey, fontSize: 14),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: _red, size: 56),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Unknown error',
              style: const TextStyle(color: _textGrey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAttendance,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
