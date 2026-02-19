// lib/screen/leave_api_test_screen.dart
// Leave API Integration Test Panel
// Tests all 6 user-accessible leave endpoints against the live backend.
// Test 4 (POST apply) creates a temporary leave request which is cancelled
// automatically by Test 6 — no permanent data is left in the database.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/leave_service.dart';
import '../services/token_storage_service.dart';
import '../models/apply_leave_model.dart';

// ─── Test result model ──────────────────────────────────────────────────────
enum _TestStatus { idle, running, passed, failed }

class _ApiTest {
  final String name;
  final String method;
  final String endpoint;
  final String description;

  _TestStatus status = _TestStatus.idle;
  int? httpStatusCode;
  String? responsePreview;
  String? errorMessage;
  DateTime? testedAt;

  _ApiTest({
    required this.name,
    required this.method,
    required this.endpoint,
    required this.description,
  });
}

// ─── Screen ─────────────────────────────────────────────────────────────────
class LeaveApiTestScreen extends StatefulWidget {
  const LeaveApiTestScreen({super.key});

  @override
  State<LeaveApiTestScreen> createState() => _LeaveApiTestScreenState();
}

class _LeaveApiTestScreenState extends State<LeaveApiTestScreen> {
  String? _token;
  bool _isInitializing = true;
  bool _isRunningAll = false;

  // IDs captured during test run
  String? _createdLeaveId; // from Test 4 (POST apply)

  // ── 6 leave API tests ─────────────────────────────────────────────────────
  late final List<_ApiTest> _tests = [
    _ApiTest(
      name: 'Get Leave Balance',
      method: 'GET',
      endpoint: '/api/leaves/balance',
      description:
          'Returns the current employee\'s remaining leave quota for each '
          'leave type: annual (21), sick (14), casual (7), maternity, '
          'paternity, unpaid.',
    ),
    _ApiTest(
      name: 'Get Leave Statistics',
      method: 'GET',
      endpoint: '/api/leaves/statistics',
      description:
          'Returns leave usage counts for the current year grouped by '
          'status (pending, approved, rejected, cancelled) plus total '
          'days taken and a per-type breakdown.',
    ),
    _ApiTest(
      name: 'Get All My Leaves',
      method: 'GET',
      endpoint: '/api/leaves',
      description:
          'Returns all leave requests for the current employee. '
          'Employees only see their own records regardless of role.',
    ),
    _ApiTest(
      name: 'Apply Leave (POST)',
      method: 'POST',
      endpoint: '/api/leaves',
      description:
          'Write test — creates a temporary sick-leave request one month '
          'from today. The generated ID is reused by Tests 5 & 6. '
          'Test 6 automatically cancels it, leaving no permanent data.',
    ),
    _ApiTest(
      name: 'Get Leave by ID',
      method: 'GET',
      endpoint: '/api/leaves/:id',
      description:
          'Fetches the single leave request created by Test 4 using its '
          'MongoDB ObjectId. Requires Test 4 to have run first.',
    ),
    _ApiTest(
      name: 'Cancel Leave (PUT)',
      method: 'PUT',
      endpoint: '/api/leaves/:id/cancel',
      description:
          'Cleanup test — cancels the leave request created by Test 4. '
          'Restores the balance deducted during POST. Requires Test 4.',
    ),
    _ApiTest(
      name: 'Get Pending Leaves',
      method: 'GET',
      endpoint: '/api/leaves?status=pending',
      description:
          'Filters the leave list to show only pending requests. '
          'Demonstrates the optional status query parameter.',
    ),
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final t = await TokenStorageService().getToken();
    if (!mounted) return;
    setState(() {
      _token = t;
      _isInitializing = false;
    });
    if (t != null) _runAllTests();
  }

  // ── Run all tests sequentially ────────────────────────────────────────────
  Future<void> _runAllTests() async {
    if (_isRunningAll) return;
    setState(() {
      _isRunningAll = true;
      _createdLeaveId = null; // reset cross-test state
    });
    for (final test in _tests) {
      await _runTest(test);
    }
    if (mounted) setState(() => _isRunningAll = false);
  }

  Future<void> _runTest(_ApiTest test) async {
    if (_token == null) return;
    setState(() {
      test.status = _TestStatus.running;
      test.httpStatusCode = null;
      test.responsePreview = null;
      test.errorMessage = null;
      test.testedAt = null;
    });

    try {
      switch (test.name) {
        case 'Get Leave Balance':
          await _testGetLeaveBalance(test);

        case 'Get Leave Statistics':
          await _testGetLeaveStatistics(test);

        case 'Get All My Leaves':
          await _testGetMyLeaves(test);

        case 'Apply Leave (POST)':
          await _testApplyLeave(test);

        case 'Get Leave by ID':
          await _testGetLeaveById(test);

        case 'Cancel Leave (PUT)':
          await _testCancelLeave(test);

        case 'Get Pending Leaves':
          await _testGetPendingLeaves(test);

        default:
          _setFailed(test, 'Unknown test name');
      }
    } catch (e) {
      _setFailed(test, e.toString());
    }
  }

  // ── Individual test implementations ────────────────────────────────────────

  Future<void> _testGetLeaveBalance(_ApiTest test) async {
    final raw = await LeaveService.getLeaveBalance(token: _token!);
    final resp = LeaveBalanceResponse.fromJson(raw);
    if (!resp.success) {
      _setFailed(test, raw['message'] ?? 'success=false');
      return;
    }
    final b = resp.data;
    _setPassed(test, [
      'annual: ${b?.annual ?? 0}',
      'sick: ${b?.sick ?? 0}',
      'casual: ${b?.casual ?? 0}',
      'unpaid: ${b?.unpaid ?? 0}',
    ].join(' | '));
  }

  Future<void> _testGetLeaveStatistics(_ApiTest test) async {
    final raw = await LeaveService.getLeaveStatistics(token: _token!);
    final resp = LeaveStatisticsResponse.fromJson(raw);
    if (!resp.success) {
      _setFailed(test, raw['message'] ?? 'success=false');
      return;
    }
    final s = resp.data;
    _setPassed(test, [
      'total: ${s?.total ?? 0}',
      'approved: ${s?.approved ?? 0}',
      'pending: ${s?.pending ?? 0}',
      'daysTaken: ${s?.daysTaken ?? 0}',
    ].join(' | '));
  }

  Future<void> _testGetMyLeaves(_ApiTest test) async {
    final raw = await LeaveService.getMyLeaves(token: _token!);
    final resp = LeaveListResponse.fromJson(raw);
    if (!resp.success) {
      _setFailed(test, raw['message'] ?? 'success=false');
      return;
    }
    _setPassed(test, 'count: ${resp.count} | returned: ${resp.data.length}');
  }

  Future<void> _testApplyLeave(_ApiTest test) async {
    // Use a date far in the future so it doesn't clash with existing leaves
    final start = DateTime.now().add(const Duration(days: 60));
    final end = start.add(const Duration(days: 1));

    final resp = await LeaveService.applyLeave(
      token: _token!,
      leaveType: 'sick',
      startDate: start,
      endDate: end,
      reason: '[API Test] Temporary leave — will be cancelled automatically.',
    );
    if (!resp.success) {
      _setFailed(test, resp.message);
      return;
    }
    _createdLeaveId = resp.data.id;
    _setPassed(test, 'id: ${resp.data.id} | status: ${resp.data.status}');
  }

  Future<void> _testGetLeaveById(_ApiTest test) async {
    if (_createdLeaveId == null) {
      _setFailed(test, 'No leave ID available — run "Apply Leave" first');
      return;
    }
    final raw = await LeaveService.getLeaveById(
      token: _token!,
      leaveId: _createdLeaveId!,
    );
    final resp = LeaveDetailResponse.fromJson(raw);
    if (!resp.success || resp.data == null) {
      _setFailed(test, raw['message'] ?? 'success=false or null data');
      return;
    }
    _setPassed(test, [
      'id: ${resp.data!.id.substring(0, 8)}…',
      'type: ${resp.data!.leaveType}',
      'status: ${resp.data!.status}',
      'days: ${resp.data!.days}',
    ].join(' | '));
  }

  Future<void> _testCancelLeave(_ApiTest test) async {
    if (_createdLeaveId == null) {
      _setFailed(test, 'No leave ID available — run "Apply Leave" first');
      return;
    }
    final raw = await LeaveService.cancelLeave(
      token: _token!,
      leaveId: _createdLeaveId!,
    );
    final resp = LeaveDetailResponse.fromJson(raw);
    if (!resp.success) {
      _setFailed(test, raw['message'] ?? 'success=false');
      return;
    }
    _createdLeaveId = null; // cleaned up
    _setPassed(test,
        'status: ${resp.data?.status ?? "cancelled"} | msg: ${resp.message ?? "ok"}');
  }

  Future<void> _testGetPendingLeaves(_ApiTest test) async {
    final raw =
        await LeaveService.getMyLeaves(token: _token!, status: 'pending');
    final resp = LeaveListResponse.fromJson(raw);
    if (!resp.success) {
      _setFailed(test, raw['message'] ?? 'success=false');
      return;
    }
    _setPassed(test, 'pending count: ${resp.count}');
  }

  // ── State helpers ─────────────────────────────────────────────────────────
  void _setPassed(_ApiTest test, String preview) {
    if (!mounted) return;
    setState(() {
      test.status = _TestStatus.passed;
      test.responsePreview = preview;
      test.testedAt = DateTime.now();
    });
  }

  void _setFailed(_ApiTest test, String message) {
    if (!mounted) return;
    setState(() {
      test.status = _TestStatus.failed;
      test.errorMessage = message;
      test.testedAt = DateTime.now();
    });
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        foregroundColor: Colors.white,
        title: const Text(
          'Leave API Tests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          if (!_isInitializing)
            IconButton(
              icon: _isRunningAll
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.pinkAccent,
                      ),
                    )
                  : const Icon(Icons.refresh, color: Colors.pinkAccent),
              onPressed: _isRunningAll ? null : _runAllTests,
              tooltip: 'Re-run all tests',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isInitializing
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent))
          : _token == null
              ? _buildNoToken()
              : _buildTestList(),
    );
  }

  Widget _buildNoToken() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, color: Colors.redAccent, size: 64),
            SizedBox(height: 16),
            Text(
              'Not authenticated',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please log in to run the leave API tests.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestList() {
    final passed = _tests.where((t) => t.status == _TestStatus.passed).length;
    final failed = _tests.where((t) => t.status == _TestStatus.failed).length;

    return Column(
      children: [
        // Summary bar
        Container(
          color: const Color(0xFF0F0F0F),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _chip('$passed Passed', Colors.greenAccent),
              const SizedBox(width: 8),
              _chip('$failed Failed', Colors.redAccent),
              const SizedBox(width: 8),
              _chip('${_tests.length} Total', Colors.white54),
              const Spacer(),
              if (_isRunningAll)
                const Text(
                  'Running…',
                  style: TextStyle(color: Colors.pinkAccent, fontSize: 12),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _tests.length,
            separatorBuilder: (_, i) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _buildTestCard(_tests[i]),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTestCard(_ApiTest test) {
    Color statusColor;
    IconData statusIcon;
    switch (test.status) {
      case _TestStatus.idle:
        statusColor = Colors.white24;
        statusIcon = Icons.radio_button_unchecked;
      case _TestStatus.running:
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.timelapse;
      case _TestStatus.passed:
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle_outline;
      case _TestStatus.failed:
        statusColor = Colors.redAccent;
        statusIcon = Icons.error_outline;
    }

    final isWrite =
        test.method == 'POST' || test.method == 'PUT';

    return GestureDetector(
      onTap: () => _runTest(test),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: statusColor.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    test.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                _methodBadge(test.method, isWrite),
              ],
            ),
            const SizedBox(height: 6),
            // Endpoint (tap to copy)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: test.endpoint));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Endpoint copied'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Colors.pinkAccent,
                  ),
                );
              },
              child: Text(
                test.endpoint,
                style: const TextStyle(
                  color: Colors.pinkAccent,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              test.description,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            // Progress / result
            if (test.status == _TestStatus.running) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(
                backgroundColor: Colors.white12,
                color: Colors.pinkAccent,
              ),
            ] else if (test.responsePreview != null) ...[
              const SizedBox(height: 8),
              _resultBox(test.responsePreview!, Colors.white.withAlpha(8),
                  Colors.white70),
            ] else if (test.errorMessage != null) ...[
              const SizedBox(height: 8),
              _resultBox(test.errorMessage!,
                  Colors.redAccent.withAlpha(20), Colors.redAccent),
            ],
            if (test.testedAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Tested at ${_fmt(test.testedAt!)}',
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _methodBadge(String method, bool isWrite) {
    final color = isWrite ? Colors.orangeAccent : Colors.blueAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        method,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _resultBox(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
