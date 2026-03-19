// lib/screen/user_api_integration_screen.dart
// User API Integration Verification Dashboard
// Tests all user-facing APIs (non-admin) from Flutter frontend
// Features: Real-time API testing, response validation, error handling

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hrms_app/shared/services/core/token_storage_service.dart';
import 'package:hrms_app/core/config/api_config.dart';

enum ApiCategory {
  auth('🔐 Auth'),
  attendance('📍 Attendance'),
  leave('🏖️ Leave'),
  expense('💰 Expense'),
  profile('👤 Profile'),
  employee('👥 Employee'),
  announcements('📢 Announcements'),
  tasks('✅ Tasks');

  final String label;
  const ApiCategory(this.label);
}

enum ApiTestStatus { idle, running, success, failed, skipped }

class ApiEndpoint {
  final String id;
  final String name;
  final String method;
  final String endpoint;
  final ApiCategory category;
  final String description;
  final bool requiresAuthentication;

  ApiTestStatus status = ApiTestStatus.idle;
  int? responseCode;
  String? responsePreview;
  String? errorMessage;
  Duration? duration;
  DateTime? testedAt;

  ApiEndpoint({
    required this.id,
    required this.name,
    required this.method,
    required this.endpoint,
    required this.category,
    required this.description,
    this.requiresAuthentication = true,
  });
}

class UserApiIntegrationScreen extends StatefulWidget {
  const UserApiIntegrationScreen({super.key});

  @override
  State<UserApiIntegrationScreen> createState() =>
      _UserApiIntegrationScreenState();
}

class _UserApiIntegrationScreenState extends State<UserApiIntegrationScreen>
    with SingleTickerProviderStateMixin {
  static String get baseUrl => ApiConfig.baseUrl;

  String? _token;
  bool _isLoading = true;
  bool _isRunningAll = false;
  String _selectedCategory = 'All';
  ApiEndpoint? _selectedEndpoint;
  late TabController _tabController;

  late List<ApiEndpoint> _endpoints;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeEndpoints();
    _loadToken();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeEndpoints() {
    _endpoints = [
      // ─── AUTH ─────────────────────────────────────────────────────────────
      ApiEndpoint(
        id: 'auth_me',
        name: 'Get Current User',
        method: 'GET',
        endpoint: '/auth/me',
        category: ApiCategory.auth,
        description: 'Fetch current authenticated user details',
      ),
      ApiEndpoint(
        id: 'auth_logout',
        name: 'Logout',
        method: 'POST',
        endpoint: '/auth/logout',
        category: ApiCategory.auth,
        description: 'Logout from the system',
      ),

      // ─── ATTENDANCE ────────────────────────────────────────────────────────
      ApiEndpoint(
        id: 'att_today',
        name: 'Today Attendance',
        method: 'GET',
        endpoint: '/attendance/today',
        category: ApiCategory.attendance,
        description: 'Get today\'s check-in/out status',
      ),
      ApiEndpoint(
        id: 'att_summary',
        name: 'Attendance Summary',
        method: 'GET',
        endpoint: '/attendance/summary?month=2&year=2026',
        category: ApiCategory.attendance,
        description:
            'Get monthly attendance summary (present, absent, late, etc.)',
      ),
      ApiEndpoint(
        id: 'att_my',
        name: 'My Attendance Records',
        method: 'GET',
        endpoint: '/attendance/my-attendance',
        category: ApiCategory.attendance,
        description:
            'Get paginated attendance records with date range filtering',
      ),
      ApiEndpoint(
        id: 'att_edit_requests',
        name: 'Edit Requests',
        method: 'GET',
        endpoint: '/attendance/edit-requests',
        category: ApiCategory.attendance,
        description: 'Get pending attendance edit requests',
      ),

      // ─── LEAVE ────────────────────────────────────────────────────────────
      ApiEndpoint(
        id: 'leave_balance',
        name: 'Leave Balance',
        method: 'GET',
        endpoint: '/leave/balance',
        category: ApiCategory.leave,
        description: 'Get remaining leave balance by type',
      ),
      ApiEndpoint(
        id: 'leave_stats',
        name: 'Leave Statistics',
        method: 'GET',
        endpoint: '/leave/statistics?year=2026',
        category: ApiCategory.leave,
        description: 'Get leave usage statistics (applied, approved, rejected)',
      ),
      ApiEndpoint(
        id: 'leave_list',
        name: 'Leave Requests',
        method: 'GET',
        endpoint: '/leave',
        category: ApiCategory.leave,
        description: 'Get all leave requests with filtering',
      ),

      // ─── EXPENSE ───────────────────────────────────────────────────────────
      ApiEndpoint(
        id: 'exp_list',
        name: 'Expenses List',
        method: 'GET',
        endpoint: '/expenses',
        category: ApiCategory.expense,
        description: 'Get all expenses with status filtering',
      ),
      ApiEndpoint(
        id: 'exp_stats',
        name: 'Expense Statistics',
        method: 'GET',
        endpoint: '/expenses/statistics',
        category: ApiCategory.expense,
        description: 'Get expense totals by category and status',
      ),

      // ─── PROFILE ───────────────────────────────────────────────────────────
      ApiEndpoint(
        id: 'profile_get',
        name: 'Get Profile',
        method: 'GET',
        endpoint: '/employees/profile',
        category: ApiCategory.profile,
        description: 'Get my complete profile information',
      ),

      // ─── EMPLOYEE ──────────────────────────────────────────────────────────
      ApiEndpoint(
        id: 'emp_dashboard',
        name: 'Dashboard Stats',
        method: 'GET',
        endpoint: '/employees/dashboard',
        category: ApiCategory.employee,
        description: 'Get dashboard statistics (attendance, leaves, expenses)',
      ),
      ApiEndpoint(
        id: 'emp_team',
        name: 'Team Members',
        method: 'GET',
        endpoint: '/employees/team',
        category: ApiCategory.employee,
        description: 'Get team members list for current company',
      ),
      ApiEndpoint(
        id: 'emp_tasks',
        name: 'My Tasks',
        method: 'GET',
        endpoint: '/employees/tasks',
        category: ApiCategory.employee,
        description: 'Get assigned tasks with status',
      ),

      // ─── TASKS ────────────────────────────────────────────────────────────
      ApiEndpoint(
        id: 'task_list',
        name: 'Tasks List',
        method: 'GET',
        endpoint: '/tasks',
        category: ApiCategory.tasks,
        description: 'Get all tasks with filtering by status',
      ),
      ApiEndpoint(
        id: 'task_stats',
        name: 'Task Statistics',
        method: 'GET',
        endpoint: '/tasks/statistics',
        category: ApiCategory.tasks,
        description:
            'Get task count by status (pending, in-progress, completed)',
      ),

      // ─── ANNOUNCEMENTS ────────────────────────────────────────────────────
      ApiEndpoint(
        id: 'announce_list',
        name: 'Announcements',
        method: 'GET',
        endpoint: '/announcements',
        category: ApiCategory.announcements,
        description: 'Get all company announcements',
      ),
      ApiEndpoint(
        id: 'announce_unread',
        name: 'Unread Count',
        method: 'GET',
        endpoint: '/chat/unread',
        category: ApiCategory.announcements,
        description: 'Get count of unread messages',
      ),
    ];
  }

  Future<void> _loadToken() async {
    try {
      final token = await TokenStorageService().getToken();
      setState(() {
        _token = token;
        _isLoading = false;
      });
      if (token == null) {
        _showSnackBar(
          'No authentication token found. Please log in first.',
          true,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading token: $e', true);
    }
  }

  Future<void> _runTest(ApiEndpoint endpoint) async {
    if (_token == null) {
      setState(() {
        endpoint.status = ApiTestStatus.skipped;
        endpoint.errorMessage = 'No token available';
      });
      return;
    }

    setState(() {
      endpoint.status = ApiTestStatus.running;
      endpoint.responseCode = null;
      endpoint.responsePreview = null;
      endpoint.errorMessage = null;
    });

    final stopwatch = Stopwatch()..start();

    try {
      final url = '$baseUrl${endpoint.endpoint}';
      final headers = <String, String>{
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      stopwatch.stop();

      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      final preview = _prettyJsonPreview(response.body, 500);

      setState(() {
        endpoint.status = isSuccess
            ? ApiTestStatus.success
            : ApiTestStatus.failed;
        endpoint.responseCode = response.statusCode;
        endpoint.responsePreview = preview;
        endpoint.duration = stopwatch.elapsed;
        endpoint.testedAt = DateTime.now();
        if (!isSuccess) {
          endpoint.errorMessage = 'HTTP ${response.statusCode}';
        }
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        endpoint.status = ApiTestStatus.failed;
        endpoint.errorMessage = e.toString();
        endpoint.duration = stopwatch.elapsed;
      });
    }
  }

  Future<void> _runAllTests() async {
    if (_token == null) {
      _showSnackBar('Authentication required', true);
      return;
    }

    setState(() => _isRunningAll = true);
    final visible = _getFilteredEndpoints();

    for (final endpoint in visible) {
      if (!mounted) break;
      await _runTest(endpoint);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() => _isRunningAll = false);
    _showSnackBar('All tests completed', false);
  }

  List<ApiEndpoint> _getFilteredEndpoints() {
    if (_selectedCategory == 'All') return _endpoints;
    return _endpoints
        .where((e) => e.category.label.contains(_selectedCategory))
        .toList();
  }

  String _prettyJsonPreview(String raw, int maxChars) {
    try {
      final obj = jsonDecode(raw);
      final pretty = const JsonEncoder.withIndent('  ').convert(obj);
      return pretty.length > maxChars
          ? '${pretty.substring(0, maxChars)}...'
          : pretty;
    } catch (_) {
      return raw.length > maxChars ? '${raw.substring(0, maxChars)}...' : raw;
    }
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _statusColor(ApiTestStatus status) {
    switch (status) {
      case ApiTestStatus.success:
        return const Color(0xFF00D084);
      case ApiTestStatus.failed:
        return const Color(0xFFFF6B6B);
      case ApiTestStatus.running:
        return const Color(0xFFFFA500);
      case ApiTestStatus.skipped:
        return Colors.grey;
      case ApiTestStatus.idle:
        return Colors.grey.shade600;
    }
  }

  IconData _statusIcon(ApiTestStatus status) {
    switch (status) {
      case ApiTestStatus.success:
        return Icons.check_circle;
      case ApiTestStatus.failed:
        return Icons.cancel;
      case ApiTestStatus.running:
        return Icons.hourglass_top;
      case ApiTestStatus.skipped:
        return Icons.skip_next;
      case ApiTestStatus.idle:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'User API Integration',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF6B6B),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Test Suite'),
            Tab(text: 'Response'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _token == null
          ? _buildNoTokenState()
          : TabBarView(
              controller: _tabController,
              children: [_buildTestListTab(), _buildResponseTab()],
            ),
    );
  }

  Widget _buildNoTokenState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Authentication Required',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Please log in to test APIs',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestListTab() {
    return Column(
      children: [
        // Summary
        _buildSummary(),
        // Category filter
        _buildCategoryFilter(),
        // Run all button
        _buildRunAllButton(),
        // Test list
        Expanded(child: _buildTestList()),
      ],
    );
  }

  Widget _buildSummary() {
    final total = _getFilteredEndpoints().length;
    final passed = _endpoints
        .where((e) => e.status == ApiTestStatus.success)
        .length;
    final failed = _endpoints
        .where((e) => e.status == ApiTestStatus.failed)
        .length;

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
          _summaryChip('Total', total.toString(), Colors.blue),
          _summaryChip('Passed', passed.toString(), const Color(0xFF00D084)),
          _summaryChip('Failed', failed.toString(), const Color(0xFFFF6B6B)),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', ...ApiCategory.values.map((c) => c.label)];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final selected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFF6B6B)
                    : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRunAllButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isRunningAll ? null : _runAllTests,
          icon: _isRunningAll
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: Text(
            _isRunningAll
                ? 'Running Tests...'
                : 'Run All Tests (${_getFilteredEndpoints().length})',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B6B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildTestList() {
    final filtered = _getFilteredEndpoints();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) => _buildTestCard(filtered[i]),
    );
  }

  Widget _buildTestCard(ApiEndpoint endpoint) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedEndpoint = endpoint);
        _tabController.animateTo(1);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _selectedEndpoint?.id == endpoint.id
                ? const Color(0xFFFF6B6B)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Status icon
            endpoint.status == ApiTestStatus.running
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _statusIcon(endpoint.status),
                    color: _statusColor(endpoint.status),
                    size: 20,
                  ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    endpoint.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _methodColor(endpoint.method),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          endpoint.method,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          endpoint.endpoint,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (endpoint.duration != null)
                  Text(
                    '${endpoint.duration!.inMilliseconds}ms',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                if (endpoint.responseCode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(endpoint.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      endpoint.responseCode.toString(),
                      style: TextStyle(
                        color: _statusColor(endpoint.status),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: endpoint.status == ApiTestStatus.running
                      ? null
                      : () => _runTest(endpoint),
                  child: Icon(
                    Icons.refresh,
                    size: 16,
                    color: _statusColor(endpoint.status),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _methodColor(String method) {
    return const {
          'GET': Colors.blue,
          'POST': Color(0xFF00D084),
          'PUT': Color(0xFFFFA500),
          'DELETE': Color(0xFFFF6B6B),
        }[method] ??
        Colors.grey;
  }

  Widget _buildResponseTab() {
    if (_selectedEndpoint == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, color: Colors.grey, size: 48),
            SizedBox(height: 12),
            Text(
              'Tap any test to see response',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final endpoint = _selectedEndpoint!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                    Icon(
                      _statusIcon(endpoint.status),
                      color: _statusColor(endpoint.status),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        endpoint.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (endpoint.responseCode != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(endpoint.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          endpoint.responseCode.toString(),
                          style: TextStyle(
                            color: _statusColor(endpoint.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${endpoint.method} ${endpoint.endpoint}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  endpoint.description,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (endpoint.duration != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Duration: ${endpoint.duration!.inMilliseconds}ms',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Run button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: endpoint.status == ApiTestStatus.running
                  ? null
                  : () => _runTest(endpoint),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Response
          if (endpoint.responsePreview != null) ...[
            const Text(
              'Response:',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
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
                endpoint.responsePreview!,
                style: const TextStyle(
                  color: Color(0xFF00D084),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],

          // Error
          if (endpoint.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF6B6B)),
              ),
              child: Text(
                'Error: ${endpoint.errorMessage}',
                style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
