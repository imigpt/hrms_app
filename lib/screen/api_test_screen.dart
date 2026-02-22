// lib/screen/api_test_screen.dart
// Comprehensive API Integration Test Screen
// Tests all backend endpoints without modifying backend code

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/token_storage_service.dart';

// ── Test result model ─────────────────────────────────────────────────────────
enum TestStatus { pending, running, passed, failed, skipped }

class ApiTest {
  final String id;
  final String name;
  final String method;
  final String endpoint;
  final String category;
  TestStatus status;
  String? responseCode;
  String? responseBody;
  String? errorMessage;
  Duration? duration;

  ApiTest({
    required this.id,
    required this.name,
    required this.method,
    required this.endpoint,
    required this.category,
    this.status = TestStatus.pending,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────
class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen>
    with SingleTickerProviderStateMixin {
  static const String _baseUrl = 'https://hrms-backend-zzzc.onrender.com/api';

  String? _token;
  bool _isRunningAll = false;
  String _selectedCategory = 'All';
  ApiTest? _selectedTest;
  late TabController _tabController;

  final _tokenStorage = TokenStorageService();

  // Track summary
  int get _passedCount => _tests.where((t) => t.status == TestStatus.passed).length;
  int get _failedCount => _tests.where((t) => t.status == TestStatus.failed).length;
  int get _totalCount => _tests.length;

  final List<String> _categories = [
    'All', 'Auth', 'Attendance', 'Leave', 'Expense', 'Tasks', 'Profile', 'Chat', 'Employee'
  ];

  late List<ApiTest> _tests;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initTests();
    _loadToken();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initTests() {
    _tests = [
      //  AUTH
      ApiTest(id: 'auth_me', name: 'Get Current User (me)', method: 'GET', endpoint: '/auth/me', category: 'Auth'),
      ApiTest(id: 'auth_login_history', name: 'Login History', method: 'GET', endpoint: '/auth/login-history/:userId', category: 'Auth'),

      // EMPLOYEE DASHBOARD
      ApiTest(id: 'emp_dashboard', name: 'Employee Dashboard Stats', method: 'GET', endpoint: '/employees/dashboard', category: 'Employee'),
      ApiTest(id: 'emp_profile', name: 'Get My Profile', method: 'GET', endpoint: '/employees/profile', category: 'Employee'),
      ApiTest(id: 'emp_tasks', name: 'My Tasks', method: 'GET', endpoint: '/employees/tasks', category: 'Employee'),
      ApiTest(id: 'emp_leaves', name: 'My Leaves', method: 'GET', endpoint: '/employees/leaves', category: 'Employee'),
      ApiTest(id: 'emp_expenses', name: 'My Expenses', method: 'GET', endpoint: '/employees/expenses', category: 'Employee'),
      ApiTest(id: 'emp_attendance', name: 'My Attendance', method: 'GET', endpoint: '/employees/attendance', category: 'Employee'),
      ApiTest(id: 'emp_leave_balance', name: 'Leave Balance (Employee)', method: 'GET', endpoint: '/employees/leave-balance', category: 'Employee'),
      ApiTest(id: 'emp_team', name: 'Team Members', method: 'GET', endpoint: '/employees/team', category: 'Employee'),

      // ATTENDANCE
      ApiTest(id: 'att_today', name: 'Today Attendance', method: 'GET', endpoint: '/attendance/today', category: 'Attendance'),
      ApiTest(id: 'att_summary', name: 'Attendance Summary', method: 'GET', endpoint: '/attendance/summary', category: 'Attendance'),
      ApiTest(id: 'att_my', name: 'My Attendance Records', method: 'GET', endpoint: '/attendance/my-attendance', category: 'Attendance'),
      ApiTest(id: 'att_edit_reqs', name: 'My Edit Requests', method: 'GET', endpoint: '/attendance/edit-requests', category: 'Attendance'),

      // LEAVE
      ApiTest(id: 'leave_balance', name: 'Leave Balance', method: 'GET', endpoint: '/leave/balance', category: 'Leave'),
      ApiTest(id: 'leave_stats', name: 'Leave Statistics', method: 'GET', endpoint: '/leave/statistics', category: 'Leave'),
      ApiTest(id: 'leave_list', name: 'Leave Requests List', method: 'GET', endpoint: '/leave', category: 'Leave'),

      // EXPENSE
      ApiTest(id: 'exp_list', name: 'Expenses List', method: 'GET', endpoint: '/expenses', category: 'Expense'),
      ApiTest(id: 'exp_stats', name: 'Expense Statistics', method: 'GET', endpoint: '/expenses/statistics', category: 'Expense'),

      // TASKS
      ApiTest(id: 'task_list', name: 'Tasks List', method: 'GET', endpoint: '/tasks', category: 'Tasks'),
      ApiTest(id: 'task_stats', name: 'Task Statistics', method: 'GET', endpoint: '/tasks/statistics', category: 'Tasks'),

      // PROFILE
      ApiTest(id: 'profile_get', name: 'Get Profile', method: 'GET', endpoint: '/employees/profile', category: 'Profile'),

      // CHAT
      ApiTest(id: 'chat_rooms', name: 'Chat Rooms', method: 'GET', endpoint: '/chat/rooms', category: 'Chat'),
      ApiTest(id: 'chat_users', name: 'Company Users for Chat', method: 'GET', endpoint: '/chat/users', category: 'Chat'),
      ApiTest(id: 'chat_unread', name: 'Unread Count', method: 'GET', endpoint: '/chat/unread', category: 'Chat'),

      // ANNOUNCEMENTS
      ApiTest(id: 'announce_list', name: 'Announcements', method: 'GET', endpoint: '/announcements', category: 'Chat'),
    ];
  }

  Future<void> _loadToken() async {
    final token = await _tokenStorage.getToken();
    if (mounted) setState(() => _token = token);
  }

  // ── Run single test ───────────────────────────────────────────────────────

  Future<void> _runTest(ApiTest test) async {
    if (_token == null) {
      setState(() {
        test.status = TestStatus.skipped;
        test.errorMessage = 'No token – please log in first';
      });
      return;
    }

    setState(() {
      test.status = TestStatus.running;
      test.responseCode = null;
      test.responseBody = null;
      test.errorMessage = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final result = await _executeTest(test);
      stopwatch.stop();
      setState(() {
        test.status = result.$1 ? TestStatus.passed : TestStatus.failed;
        test.responseCode = result.$2;
        test.responseBody = result.$3;
        test.errorMessage = result.$4;
        test.duration = stopwatch.elapsed;
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        test.status = TestStatus.failed;
        test.errorMessage = e.toString();
        test.duration = stopwatch.elapsed;
      });
    }
  }

  // ── Run all tests ─────────────────────────────────────────────────────────

  Future<void> _runAllTests() async {
    setState(() => _isRunningAll = true);
    final visible = _filteredTests();
    for (final test in visible) {
      if (!mounted) break;
      await _runTest(test);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    setState(() => _isRunningAll = false);
  }

  // ── Execute individual test logic ─────────────────────────────────────────

  Future<(bool, String, String, String?)> _executeTest(ApiTest test) async {
    final headers = <String, String>{
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
    };

    late http.Response response;

    final now = DateTime.now();
    final firstDayOfMonth =
        DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
    final today = now.toIso8601String().split('T')[0];

    switch (test.id) {
      case 'auth_me':
        response = await http
            .get(Uri.parse('$_baseUrl/auth/me'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'auth_login_history':
        final userId = await _tokenStorage.getUserId();
        if (userId == null) throw Exception('User ID not found');
        response = await http
            .get(Uri.parse('$_baseUrl/auth/login-history/$userId'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'emp_dashboard':
        response = await http
            .get(Uri.parse('$_baseUrl/employees/dashboard'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'emp_profile':
      case 'profile_get':
        response = await http
            .get(Uri.parse('$_baseUrl/employees/profile'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'emp_tasks':
        response = await http
            .get(Uri.parse('$_baseUrl/employees/tasks'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'emp_leaves':
        response = await http
            .get(Uri.parse('$_baseUrl/employees/leaves'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'emp_expenses':
        response = await http
            .get(Uri.parse('$_baseUrl/employees/expenses'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'emp_attendance':
        response = await http
            .get(Uri.parse('$_baseUrl/employees/attendance'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'emp_leave_balance':
        response = await http
            .get(Uri.parse('$_baseUrl/employees/leave-balance'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'emp_team':
        response = await http
            .get(Uri.parse('$_baseUrl/employees/team'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'att_today':
        response = await http
            .get(Uri.parse('$_baseUrl/attendance/today'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'att_summary':
        response = await http
            .get(
              Uri.parse(
                  '$_baseUrl/attendance/summary?month=${now.month}&year=${now.year}'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));
        break;

      case 'att_my':
        response = await http
            .get(
              Uri.parse(
                  '$_baseUrl/attendance/my-attendance?startDate=$firstDayOfMonth&endDate=$today'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));
        break;

      case 'att_edit_reqs':
        response = await http
            .get(Uri.parse('$_baseUrl/attendance/edit-requests'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'leave_balance':
        response = await http
            .get(Uri.parse('$_baseUrl/leave/balance'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'leave_stats':
        response = await http
            .get(
              Uri.parse('$_baseUrl/leave/statistics?year=${now.year}'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));
        break;

      case 'leave_list':
        response = await http
            .get(Uri.parse('$_baseUrl/leave'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'exp_list':
        response = await http
            .get(Uri.parse('$_baseUrl/expenses'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'exp_stats':
        response = await http
            .get(
              Uri.parse(
                  '$_baseUrl/expenses/statistics?startDate=$firstDayOfMonth&endDate=$today'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));
        break;

      case 'task_list':
        response = await http
            .get(Uri.parse('$_baseUrl/tasks'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'task_stats':
        response = await http
            .get(Uri.parse('$_baseUrl/tasks/statistics'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'chat_rooms':
        response = await http
            .get(Uri.parse('$_baseUrl/chat/rooms'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'chat_users':
        response = await http
            .get(Uri.parse('$_baseUrl/chat/users'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'chat_unread':
        response = await http
            .get(Uri.parse('$_baseUrl/chat/unread'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      case 'announce_list':
        response = await http
            .get(Uri.parse('$_baseUrl/announcements'), headers: headers)
            .timeout(const Duration(seconds: 15));
        break;

      default:
        throw Exception('Test not implemented: ${test.id}');
    }

    final bodyStr = _prettyJson(response.body);
    final code = response.statusCode.toString();
    final passed = response.statusCode >= 200 && response.statusCode < 300;
    String? err;
    if (!passed) {
      try {
        final decoded = jsonDecode(response.body);
        err = decoded['message'] ?? decoded['error'] ?? 'Status ${response.statusCode}';
      } catch (_) {
        err = 'Status ${response.statusCode}';
      }
    }
    return (passed, code, bodyStr, err);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _prettyJson(String raw) {
    try {
      final obj = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(obj);
    } catch (_) {
      return raw;
    }
  }

  List<ApiTest> _filteredTests() {
    if (_selectedCategory == 'All') return _tests;
    return _tests.where((t) => t.category == _selectedCategory).toList();
  }

  // ── Colours ───────────────────────────────────────────────────────────────

  Color _statusColor(TestStatus s) {
    switch (s) {
      case TestStatus.passed:
        return const Color(0xFF00D084);
      case TestStatus.failed:
        return const Color(0xFFFF6B6B);
      case TestStatus.running:
        return const Color(0xFFFFA500);
      case TestStatus.skipped:
        return Colors.grey;
      case TestStatus.pending:
        return Colors.grey.shade600;
    }
  }

  IconData _statusIcon(TestStatus s) {
    switch (s) {
      case TestStatus.passed:
        return Icons.check_circle;
      case TestStatus.failed:
        return Icons.cancel;
      case TestStatus.running:
        return Icons.hourglass_top;
      case TestStatus.skipped:
        return Icons.skip_next;
      case TestStatus.pending:
        return Icons.radio_button_unchecked;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'API Integration Tests',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _token == null
                ? const Chip(
                    label: Text('No Token', style: TextStyle(color: Colors.white, fontSize: 11)),
                    backgroundColor: Color(0xFFFF6B6B),
                  )
                : const Chip(
                    label: Text('Token OK', style: TextStyle(color: Colors.white, fontSize: 11)),
                    backgroundColor: Color(0xFF00D084),
                  ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF6B6B),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Test Results'),
            Tab(text: 'Response Detail'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTestListTab(),
          _buildDetailTab(),
        ],
      ),
    );
  }

  // ── Tab 1: Test list ──────────────────────────────────────────────────────

  Widget _buildTestListTab() {
    final filtered = _filteredTests();
    return Column(
      children: [
        // Summary bar
        _buildSummaryBar(),
        // Category filter
        _buildCategoryFilter(),
        // Run button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isRunningAll ? null : _runAllTests,
                  icon: _isRunningAll
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isRunningAll
                      ? 'Running ${_filteredTests().where((t) => t.status == TestStatus.running).length} / ${filtered.length}...'
                      : 'Run ${_selectedCategory == 'All' ? 'All' : _selectedCategory} Tests (${filtered.length})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    for (final t in filtered) {
                      t.status = TestStatus.pending;
                      t.responseCode = null;
                      t.responseBody = null;
                      t.errorMessage = null;
                    }
                  });
                },
                icon: const Icon(Icons.refresh, color: Colors.grey),
                tooltip: 'Reset',
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _buildTestTile(filtered[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryChip('Total', _totalCount.toString(), Colors.blue),
          _summaryChip('Passed', _passedCount.toString(), const Color(0xFF00D084)),
          _summaryChip('Failed', _failedCount.toString(), const Color(0xFFFF6B6B)),
          _summaryChip(
            'Pending',
            (_totalCount - _passedCount - _failedCount).toString(),
            Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final selected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFF6B6B) : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey,
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTestTile(ApiTest test) {
    final isSelected = _selectedTest?.id == test.id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTest = test);
        _tabController.animateTo(1);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2D2D2D)
              : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6B6B)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Status icon
            test.status == TestStatus.running
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFFA500),
                    ),
                  )
                : Icon(
                    _statusIcon(test.status),
                    color: _statusColor(test.status),
                    size: 20,
                  ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _methodBadge(test.method),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          test.endpoint,
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (test.errorMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      test.errorMessage!,
                      style: const TextStyle(
                          color: Color(0xFFFF6B6B), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Duration + run button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (test.duration != null)
                  Text(
                    '${test.duration!.inMilliseconds}ms',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                if (test.responseCode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(test.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      test.responseCode!,
                      style: TextStyle(
                          color: _statusColor(test.status),
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: test.status == TestStatus.running
                      ? null
                      : () => _runTest(test),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.play_arrow,
                        size: 16, color: Color(0xFFFFA500)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodBadge(String method) {
    final colors = {
      'GET': Colors.blue,
      'POST': const Color(0xFF00D084),
      'PUT': const Color(0xFFFFA500),
      'DELETE': const Color(0xFFFF6B6B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (colors[method] ?? Colors.grey).withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method,
        style: TextStyle(
            color: colors[method] ?? Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  // ── Tab 2: Detail ─────────────────────────────────────────────────────────

  Widget _buildDetailTab() {
    if (_selectedTest == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, color: Colors.grey, size: 48),
            SizedBox(height: 12),
            Text('Tap any test to see details',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    final test = _selectedTest!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_statusIcon(test.status),
                        color: _statusColor(test.status), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        test.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (test.responseCode != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(test.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _statusColor(test.status), width: 1),
                        ),
                        child: Text(
                          test.responseCode!,
                          style: TextStyle(
                              color: _statusColor(test.status),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _detailRow('Method', test.method),
                _detailRow('Endpoint', '$_baseUrl${test.endpoint}'),
                _detailRow('Category', test.category),
                if (test.duration != null)
                  _detailRow('Duration', '${test.duration!.inMilliseconds} ms'),
                if (test.errorMessage != null)
                  _detailRow('Error', test.errorMessage!,
                      color: const Color(0xFFFF6B6B)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: test.status == TestStatus.running
                      ? null
                      : () => _runTest(test),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run This Test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (test.responseBody != null)
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: test.responseBody!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A2A),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),

          // Response body
          if (test.responseBody != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Response Body',
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                const Spacer(),
                Text(
                  '${test.responseBody!.length} chars',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: SelectableText(
                test.responseBody!,
                style: const TextStyle(
                    color: Color(0xFF00D084),
                    fontSize: 12,
                    fontFamily: 'monospace'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String key, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(key,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  color: color ?? Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
