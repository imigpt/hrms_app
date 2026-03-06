// lib/screen/announcement_api_test_screen.dart
// Announcement API Integration Test Panel
// Automatically tests all 5 announcement endpoints against the live backend.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/announcement_service.dart';
import '../services/token_storage_service.dart';

// ─── Test result model ──────────────────────────────────────────────────────
enum _TestStatus { idle, running, passed, failed }

class _ApiTest {
  final String name;
  final String method;
  final String endpoint;
  final String description;

  // State — mutated during execution
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
class AnnouncementApiTestScreen extends StatefulWidget {
  const AnnouncementApiTestScreen({super.key});

  @override
  State<AnnouncementApiTestScreen> createState() =>
      _AnnouncementApiTestScreenState();
}

class _AnnouncementApiTestScreenState extends State<AnnouncementApiTestScreen> {
  String? _token;
  bool _isInitializing = true;
  bool _isRunningAll = false;

  // Carry forward the first announcement ID fetched in Test 1 for Tests 4 & 5
  String? _firstAnnouncementId;
  String? _firstAnnouncementTitle;

  // ── 5 announcement API tests ───────────────────────────────────────────────
  late final List<_ApiTest> _tests = [
    _ApiTest(
      name: 'Get All Announcements',
      method: 'GET',
      endpoint: '/api/announcements',
      description:
          'Fetches all company announcements for the authenticated user. '
          'Sorted by priority (high → low), then newest first.',
    ),
    _ApiTest(
      name: 'Get All — Filter by Priority',
      method: 'GET',
      endpoint: '/api/announcements?priority=high',
      description:
          'Same endpoint with ?priority=high filter applied. '
          'Returns only URGENT (high-priority) announcements.',
    ),
    _ApiTest(
      name: 'Get Unread Count',
      method: 'GET',
      endpoint: '/api/announcements/unread/count',
      description:
          'Returns the total number of announcements the current user has not yet read.',
    ),
    _ApiTest(
      name: 'Get Announcement by ID',
      method: 'GET',
      endpoint: '/api/announcements/:id',
      description:
          'Fetches full details of a single announcement. '
          'Uses the first ID returned by the "Get All" test above. '
          'Run Test 1 first to populate the ID.',
    ),
    _ApiTest(
      name: 'Mark Announcement as Read',
      method: 'PUT',
      endpoint: '/api/announcements/:id/read',
      description:
          'Marks a specific announcement as read for the current user. '
          'Uses the first ID from Test 1. Run Test 1 first.',
    ),
  ];

  // ── Summary counters ───────────────────────────────────────────────────────
  int get _passedCount =>
      _tests.where((t) => t.status == _TestStatus.passed).length;
  int get _failedCount =>
      _tests.where((t) => t.status == _TestStatus.failed).length;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await TokenStorageService().getToken();
    setState(() {
      _token = token;
      _isInitializing = false;
    });
    if (token != null) _runAllTests();
  }

  // ── Run all tests sequentially (order matters — Test 1 feeds ID to 4 & 5) ──
  Future<void> _runAllTests() async {
    if (_token == null || _isRunningAll) return;
    setState(() => _isRunningAll = true);

    for (final test in _tests) {
      await _runSingleTest(test);
      await Future.delayed(const Duration(milliseconds: 400));
    }

    setState(() => _isRunningAll = false);
  }

  // ── Execute a single test ─────────────────────────────────────────────────
  Future<void> _runSingleTest(_ApiTest test) async {
    if (_token == null) return;
    setState(() {
      test.status = _TestStatus.running;
      test.httpStatusCode = null;
      test.responsePreview = null;
      test.errorMessage = null;
      test.testedAt = null;
    });

    try {
      switch (test.endpoint) {
        // ── 1. Get all announcements ───────────────────────────────────
        case '/api/announcements':
          final result = await AnnouncementService.getAnnouncements(
            token: _token!,
          );
          // Cache first ID for Tests 4 & 5
          if (result.data.isNotEmpty) {
            _firstAnnouncementId = result.data.first.id;
            _firstAnnouncementTitle = result.data.first.title;
          }
          _pass(
            test,
            200,
            'success: ${result.success}\n'
            'count: ${result.count}\n'
            '${result.data.isNotEmpty ? '1st title: "${result.data.first.title}"\n'
                      'priority: ${result.data.first.priority}\n'
                      'id: ${result.data.first.id}' : 'No announcements found.'}',
          );
          break;

        // ── 2. Filter by priority=high ─────────────────────────────────
        case '/api/announcements?priority=high':
          final result = await AnnouncementService.getAnnouncements(
            token: _token!,
            priority: 'high',
          );
          _pass(
            test,
            200,
            'success: ${result.success}\n'
            'high-priority count: ${result.count}\n'
            '${result.data.isNotEmpty ? '1st: "${result.data.first.title}"' : 'None found with priority=high'}',
          );
          break;

        // ── 3. Unread count ────────────────────────────────────────────
        case '/api/announcements/unread/count':
          final count = await AnnouncementService.getUnreadCount(
            token: _token!,
          );
          _pass(test, 200, 'unread count: $count');
          break;

        // ── 4. Get by ID ───────────────────────────────────────────────
        case '/api/announcements/:id':
          if (_firstAnnouncementId == null) {
            throw Exception(
              'No announcement ID available. Run "Get All Announcements" first.',
            );
          }
          final detail = await AnnouncementService.getAnnouncementById(
            token: _token!,
            announcementId: _firstAnnouncementId!,
          );
          _pass(
            test,
            200,
            'id: ${detail.id}\n'
            'title: "${detail.title}"\n'
            'priority: ${detail.priority}\n'
            'created by: ${detail.createdBy?.name ?? "unknown"}\n'
            'read by: ${detail.readBy.length} user(s)\n'
            'isActive: ${detail.isActive}\n'
            '${detail.targetDepartment != null ? 'targetDept: ${detail.targetDepartment}\n' : ''}'
            '${detail.expiryDate != null ? 'expires: ${DateFormat('MMM d, yyyy').format(detail.expiryDate!)}' : ''}',
          );
          break;

        // ── 5. Mark as read ────────────────────────────────────────────
        case '/api/announcements/:id/read':
          if (_firstAnnouncementId == null) {
            throw Exception(
              'No announcement ID available. Run "Get All Announcements" first.',
            );
          }
          final success = await AnnouncementService.markAsRead(
            token: _token!,
            announcementId: _firstAnnouncementId!,
          );
          _pass(
            test,
            200,
            'success: $success\n'
            'marked as read: "${_firstAnnouncementTitle ?? _firstAnnouncementId}"',
          );
          break;

        default:
          break;
      }
    } catch (e) {
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

  void _pass(_ApiTest test, int code, String preview) {
    setState(() {
      test.status = _TestStatus.passed;
      test.httpStatusCode = code;
      test.responsePreview = preview;
      test.testedAt = DateTime.now();
    });
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
          'Announcement API Tests',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Run all tests',
            icon: Icon(
              _isRunningAll ? Icons.hourglass_top : Icons.play_circle_outline,
              color: _isRunningAll ? Colors.amber : Colors.greenAccent,
              size: 26,
            ),
            onPressed: _isRunningAll ? null : _runAllTests,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isInitializing
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            )
          : _token == null
          ? _noToken()
          : _body(),
    );
  }

  // ── No-token placeholder ───────────────────────────────────────────────────
  Widget _noToken() {
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
  Widget _body() {
    return Column(
      children: [
        _summaryBanner(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _runAllTests,
            color: Colors.pinkAccent,
            backgroundColor: const Color(0xFF1A1A1A),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._tests.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _card(e.key + 1, e.value),
                  ),
                ),
                const SizedBox(height: 8),
                _legend(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Summary banner ─────────────────────────────────────────────────────────
  Widget _summaryBanner() {
    final passed = _passedCount;
    final failed = _failedCount;
    final total = _tests.length;
    final pending = total - passed - failed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          _chip('Passed', passed, Colors.greenAccent),
          const SizedBox(width: 12),
          _chip('Failed', failed, Colors.red[400]!),
          const SizedBox(width: 12),
          _chip('Pending', pending, Colors.grey[600]!),
          const Spacer(),
          Text(
            '$passed / $total tests',
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

  Widget _chip(String label, int count, Color color) {
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

  // ── Single test card ───────────────────────────────────────────────────────
  Widget _card(int index, _ApiTest test) {
    final methodColor = test.method == 'GET'
        ? Colors.cyanAccent
        : Colors.orange[300]!;

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
                // Index circle
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
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
                              color: methodColor.withValues(alpha: 0.12),
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
                          // Endpoint (copy on long-press)
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
                _statusWidget(test),
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

          // ── Response / Error sections ──────────────────────────────────
          if (test.status == _TestStatus.passed && test.responsePreview != null)
            _responseSection(test),
          if (test.status == _TestStatus.failed && test.errorMessage != null)
            _errorSection(test),

          // ── Footer row ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
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
                  label: const Text('Re-test', style: TextStyle(fontSize: 12)),
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
        ],
      ),
    );
  }

  // ── Status indicator ───────────────────────────────────────────────────────
  Widget _statusWidget(_ApiTest test) {
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
          mainAxisSize: MainAxisSize.min,
          children: [
            if (test.httpStatusCode != null)
              Text(
                '${test.httpStatusCode}',
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
          mainAxisSize: MainAxisSize.min,
          children: [
            if (test.httpStatusCode != null)
              Text(
                '${test.httpStatusCode}',
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

  // ── Response section ───────────────────────────────────────────────────────
  Widget _responseSection(_ApiTest test) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
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
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.greenAccent.withValues(alpha: 0.15),
              ),
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
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Error section ──────────────────────────────────────────────────────────
  Widget _errorSection(_ApiTest test) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
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
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
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
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Legend ─────────────────────────────────────────────────────────────────
  Widget _legend() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes',
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
            'Passed — API returned 2xx',
          ),
          const SizedBox(height: 6),
          _legendRow(
            Icons.cancel,
            Colors.red,
            'Failed — API error, network issue, or missing data',
          ),
          const SizedBox(height: 6),
          _legendRow(
            Icons.radio_button_unchecked,
            Colors.grey,
            'Idle — not tested yet',
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 8),
          _legendRow(
            Icons.link,
            Colors.blueAccent,
            'Tests 4 & 5 use the first ID returned by Test 1',
          ),
          const SizedBox(height: 6),
          _legendRow(
            Icons.touch_app,
            Colors.purpleAccent,
            'Long-press any endpoint to copy it to clipboard',
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
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ),
      ],
    );
  }

  // ── Border color ───────────────────────────────────────────────────────────
  Color _borderColor(_TestStatus s) {
    switch (s) {
      case _TestStatus.passed:
        return Colors.greenAccent.withValues(alpha: 0.3);
      case _TestStatus.failed:
        return Colors.red.withValues(alpha: 0.3);
      case _TestStatus.running:
        return Colors.amber.withValues(alpha: 0.3);
      case _TestStatus.idle:
        return Colors.white.withValues(alpha: 0.07);
    }
  }
}
