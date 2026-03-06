// lib/screen/attendance_api_test_screen.dart
// Attendance API Integration Test Panel
// Tests all 7 Attendance endpoints against the live backend.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/attendance_service.dart';
import '../services/token_storage_service.dart';

// ─── Test-result model ─────────────────────────────────────────────────────
enum _TestStatus { idle, running, passed, failed }

class _ApiTest {
  final String name;
  final String method;
  final String endpoint;
  final String description;
  final bool requiresAction; // POST endpoints that need user input

  // Mutable state updated during test execution — always starts idle.
  _TestStatus status = _TestStatus.idle;
  int? statusCode;
  String? responsePreview;
  String? errorMessage;
  DateTime? testedAt;

  _ApiTest({
    required this.name,
    required this.method,
    required this.endpoint,
    required this.description,
    this.requiresAction = false,
  });
}

// ─── Screen ─────────────────────────────────────────────────────────────────
class AttendanceApiTestScreen extends StatefulWidget {
  const AttendanceApiTestScreen({super.key});

  @override
  State<AttendanceApiTestScreen> createState() =>
      _AttendanceApiTestScreenState();
}

class _AttendanceApiTestScreenState extends State<AttendanceApiTestScreen> {
  String? _token;
  bool _isInitializing = true;
  bool _isRunningAll = false;

  // ── 7 attendance APIs ─────────────────────────────────────────────────────
  late final List<_ApiTest> _tests = [
    _ApiTest(
      name: 'Get Today Attendance',
      method: 'GET',
      endpoint: '/api/attendance/today',
      description:
          'Returns today\'s check-in / check-out status for the current user.',
    ),
    _ApiTest(
      name: 'Get Attendance Summary',
      method: 'GET',
      endpoint: '/api/attendance/summary',
      description:
          'Returns monthly attendance summary (present, late, absent, work-hours) for the current month.',
    ),
    _ApiTest(
      name: 'Get My Attendance Records',
      method: 'GET',
      endpoint: '/api/attendance/my-attendance',
      description:
          'Returns paginated attendance records for the authenticated employee filtered by current month.',
    ),
    _ApiTest(
      name: 'Get My Edit Requests',
      method: 'GET',
      endpoint: '/api/attendance/edit-requests',
      description:
          'Returns all attendance-edit requests submitted by the current user.',
    ),
    _ApiTest(
      name: 'Check In',
      method: 'POST',
      endpoint: '/api/attendance/check-in',
      description:
          'Marks the employee as checked-in with GPS location and an optional selfie photo. '
          'Use the main Attendance screen to perform a real check-in.',
      requiresAction: true,
    ),
    _ApiTest(
      name: 'Check Out',
      method: 'POST',
      endpoint: '/api/attendance/check-out',
      description:
          'Marks the employee as checked-out with GPS location. '
          'Use the main Attendance screen to perform a real check-out.',
      requiresAction: true,
    ),
    _ApiTest(
      name: 'Submit Edit Request',
      method: 'POST',
      endpoint: '/api/attendance/edit-request',
      description:
          'Submits a correction request for an existing attendance record. '
          'Requires a valid attendanceId, desired check-in / check-out times, and a reason.',
      requiresAction: true,
    ),
  ];

  // ── Summary counters ───────────────────────────────────────────────────────
  int get _passedCount =>
      _tests.where((t) => t.status == _TestStatus.passed).length;
  int get _failedCount =>
      _tests.where((t) => t.status == _TestStatus.failed).length;
  int get _totalAutoTests => _tests.where((t) => !t.requiresAction).length;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initToken();
  }

  Future<void> _initToken() async {
    final token = await TokenStorageService().getToken();
    setState(() {
      _token = token;
      _isInitializing = false;
    });
    if (token != null) _runAllAutoTests();
  }

  // ── Run all GET (auto) tests sequentially ─────────────────────────────────
  Future<void> _runAllAutoTests() async {
    if (_token == null || _isRunningAll) return;
    setState(() => _isRunningAll = true);

    final autoTests = _tests.where((t) => !t.requiresAction).toList();
    for (final test in autoTests) {
      await _runSingleTest(test);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() => _isRunningAll = false);
  }

  // ── Run a single test ─────────────────────────────────────────────────────
  Future<void> _runSingleTest(_ApiTest test) async {
    if (_token == null) return;
    setState(() {
      test.status = _TestStatus.running;
      test.statusCode = null;
      test.responsePreview = null;
      test.errorMessage = null;
      test.testedAt = null;
    });

    try {
      final now = DateTime.now();
      final month = now.month;
      final year = now.year;

      switch (test.endpoint) {
        // ── 1. Today attendance ──────────────────────────────────────────
        case '/api/attendance/today':
          final result = await AttendanceService.getTodayAttendance(
            token: _token!,
          );
          _markPassed(
            test,
            200,
            result != null
                ? 'data: ${_prettyPreview(result.toJson())}'
                : '{ "data": null }',
          );
          break;

        // ── 2. Attendance Summary ────────────────────────────────────────
        case '/api/attendance/summary':
          final result = await AttendanceService.getAttendanceSummary(
            token: _token!,
            month: month,
            year: year,
          );
          _markPassed(
            test,
            200,
            'month: $month/$year\n${_prettyPreview(result.toJson())}',
          );
          break;

        // ── 3. My Attendance Records ─────────────────────────────────────
        case '/api/attendance/my-attendance':
          final startDate = DateTime(year, month, 1);
          final endDate = DateTime(year, month + 1, 0);
          final result = await AttendanceService.getAttendanceRecords(
            token: _token!,
            startDate: DateFormat('yyyy-MM-dd').format(startDate),
            endDate: DateFormat('yyyy-MM-dd').format(endDate),
            month: month,
            year: year,
          );
          _markPassed(
            test,
            200,
            'count: ${result.count}\n'
            'success: ${result.success}\n'
            '${result.data.isNotEmpty ? "latest date: ${result.data.first.date.toLocal().toString().substring(0, 10)}" : "No records this month"}',
          );
          break;

        // ── 4. My Edit Requests ──────────────────────────────────────────
        case '/api/attendance/edit-requests':
          final result = await AttendanceService.getEditRequests(
            token: _token!,
          );
          _markPassed(
            test,
            200,
            'count: ${result.count}\n'
            'success: ${result.success}\n'
            '${result.data.isNotEmpty ? "latest status: ${result.data.first.status}" : "No edit requests yet"}',
          );
          break;

        default:
          break;
      }
    } catch (e) {
      // Extract clean error message
      final raw = e.toString();
      final msg = raw.startsWith('Exception:')
          ? raw.replaceFirst('Exception:', '').trim()
          : raw;
      setState(() {
        test.status = _TestStatus.failed;
        test.errorMessage = msg;
        test.testedAt = DateTime.now();
      });
    }
  }

  void _markPassed(_ApiTest test, int code, String preview) {
    setState(() {
      test.status = _TestStatus.passed;
      test.statusCode = code;
      test.responsePreview = preview;
      test.testedAt = DateTime.now();
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _prettyPreview(Map<String, dynamic> json) {
    final encoder = JsonEncoder.withIndent('  ');
    final str = encoder.convert(json);
    return str.length > 400 ? '${str.substring(0, 400)}…' : str;
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance API Tests',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isRunningAll ? Icons.hourglass_top : Icons.play_circle_outline,
              color: _isRunningAll ? Colors.amber : Colors.greenAccent,
              size: 26,
            ),
            tooltip: 'Run all auto-tests',
            onPressed: _isRunningAll ? null : _runAllAutoTests,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isInitializing
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            )
          : _token == null
          ? _buildNoTokenMessage()
          : _buildBody(),
    );
  }

  // ── No-token state ─────────────────────────────────────────────────────────
  Widget _buildNoTokenMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, color: Colors.red[400], size: 56),
            const SizedBox(height: 16),
            const Text(
              'Not Authenticated',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please log in first to run the API tests.',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Main body ──────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Column(
      children: [
        _buildSummaryBanner(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _runAllAutoTests,
            color: Colors.pinkAccent,
            backgroundColor: const Color(0xFF1A1A1A),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._tests.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTestCard(e.key + 1, e.value),
                  ),
                ),
                const SizedBox(height: 8),
                _buildLegend(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Summary banner ─────────────────────────────────────────────────────────
  Widget _buildSummaryBanner() {
    final total = _totalAutoTests;
    final passed = _passedCount;
    final failed = _failedCount;
    final pending = total - passed - failed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          _summaryChip('Passed', passed, Colors.greenAccent),
          const SizedBox(width: 12),
          _summaryChip('Failed', failed, Colors.red[400]!),
          const SizedBox(width: 12),
          _summaryChip('Pending', pending, Colors.grey[600]!),
          const Spacer(),
          Text(
            '$passed / $total auto-tests',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$count $label',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ],
    );
  }

  // ── Individual test card ───────────────────────────────────────────────────
  Widget _buildTestCard(int index, _ApiTest test) {
    final isAuto = !test.requiresAction;
    final methodColor = test.method == 'GET'
        ? Colors.cyanAccent
        : const Color(0xFFFFB347); // orange for POST

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor(test.status), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Index
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
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
                        test.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Method badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: methodColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              test.method,
                              style: TextStyle(
                                color: methodColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Endpoint
                          Expanded(
                            child: GestureDetector(
                              onLongPress: () {
                                Clipboard.setData(
                                  ClipboardData(text: test.endpoint),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Endpoint copied'),
                                    duration: Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Text(
                                test.endpoint,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Status indicator / run button
                if (isAuto) _buildStatusWidget(test) else _buildActionBadge(),
              ],
            ),
          ),

          // ── Description ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              test.description,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),

          // ── Divider + response / error ────────────────────────────────
          if (test.status == _TestStatus.passed && test.responsePreview != null)
            _buildResponseSection(test),
          if (test.status == _TestStatus.failed && test.errorMessage != null)
            _buildErrorSection(test),

          // ── Footer: re-run button for auto tests ──────────────────────
          if (isAuto)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (test.testedAt != null)
                    Text(
                      'Tested at ${DateFormat('hh:mm:ss a').format(test.testedAt!)}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 10),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: test.status == _TestStatus.running
                        ? null
                        : () => _runSingleTest(test),
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text(
                      'Re-test',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.pinkAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),

          // ── Footer: info for manual (POST) tests ─────────────────────
          if (!isAuto)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        test.endpoint == '/api/attendance/check-in'
                            ? 'Use the Attendance screen → Check In button to test this live.'
                            : test.endpoint == '/api/attendance/check-out'
                            ? 'Use the Attendance screen → Check Out button to test this live.'
                            : 'Use the Attendance screen → Edit Request dialog to test this live.',
                        style: TextStyle(
                          color: Colors.amber[300],
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Status icon widget (for auto tests) ───────────────────────────────────
  Widget _buildStatusWidget(_ApiTest test) {
    switch (test.status) {
      case _TestStatus.running:
        return const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.amber,
          ),
        );
      case _TestStatus.passed:
        return Row(
          children: [
            if (test.statusCode != null)
              Text(
                '${test.statusCode}',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
          ],
        );
      case _TestStatus.failed:
        return Row(
          children: [
            if (test.statusCode != null)
              Text(
                '${test.statusCode}',
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(width: 6),
            Icon(Icons.cancel, color: Colors.red[400], size: 22),
          ],
        );
      case _TestStatus.idle:
        return Icon(
          Icons.radio_button_unchecked,
          color: Colors.grey[700],
          size: 22,
        );
    }
  }

  // ── "Manual" badge for POST tests ─────────────────────────────────────────
  Widget _buildActionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'MANUAL',
        style: TextStyle(
          color: Colors.amber,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Response section ───────────────────────────────────────────────────────
  Widget _buildResponseSection(_ApiTest test) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.white.withOpacity(0.05), height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              const Icon(
                Icons.arrow_downward,
                color: Colors.greenAccent,
                size: 13,
              ),
              const SizedBox(width: 4),
              const Text(
                'Response',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.15)),
            ),
            child: SelectableText(
              test.responsePreview!,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Error section ──────────────────────────────────────────────────────────
  Widget _buildErrorSection(_ApiTest test) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.white.withOpacity(0.05), height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 13),
              const SizedBox(width: 4),
              Text(
                'Error',
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: SelectableText(
              test.errorMessage!,
              style: TextStyle(
                color: Colors.red[300],
                fontSize: 11,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Legend ─────────────────────────────────────────────────────────────────
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legend',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _legendRow(
            Icons.check_circle,
            Colors.greenAccent,
            'Passed — API responded with 2xx status',
          ),
          const SizedBox(height: 6),
          _legendRow(
            Icons.cancel,
            Colors.red,
            'Failed — API error, network issue, or no token',
          ),
          const SizedBox(height: 6),
          _legendRow(
            Icons.radio_button_unchecked,
            Colors.grey,
            'Idle — not tested yet',
          ),
          const SizedBox(height: 6),
          _legendRow(
            Icons.label,
            Colors.amber,
            'Manual — requires user action (POST endpoint)',
          ),
        ],
      ),
    );
  }

  Widget _legendRow(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ],
    );
  }

  // ── Border color based on status ──────────────────────────────────────────
  Color _borderColor(_TestStatus status) {
    switch (status) {
      case _TestStatus.passed:
        return Colors.greenAccent.withOpacity(0.3);
      case _TestStatus.failed:
        return Colors.red.withOpacity(0.3);
      case _TestStatus.running:
        return Colors.amber.withOpacity(0.3);
      case _TestStatus.idle:
        return Colors.white.withOpacity(0.07);
    }
  }
}
