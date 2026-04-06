import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:hrms_app/core/config/api_config.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';

class BodEodUser {
  final String id;
  final String name;
  final String email;
  final String employeeId;
  final String department;

  const BodEodUser({
    required this.id,
    required this.name,
    required this.email,
    required this.employeeId,
    required this.department,
  });

  factory BodEodUser.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return BodEodUser(
        id: (json['_id'] ?? '').toString(),
        name: (json['name'] ?? 'Unknown').toString(),
        email: (json['email'] ?? '').toString(),
        employeeId: (json['employeeId'] ?? '').toString(),
        department: (json['department'] ?? '').toString(),
      );
    }

    return const BodEodUser(
      id: '',
      name: 'Unknown',
      email: '',
      employeeId: '',
      department: '',
    );
  }
}

class BodEntry {
  final String id;
  final String bodText;
  final String bodNotes;
  final DateTime? createdAt;

  const BodEntry({
    required this.id,
    required this.bodText,
    required this.bodNotes,
    required this.createdAt,
  });

  factory BodEntry.fromJson(Map<String, dynamic> json) {
    return BodEntry(
      id: (json['_id'] ?? '').toString(),
      bodText: (json['bodText'] ?? '').toString(),
      bodNotes: (json['bodNotes'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

class EodEntry {
  final String id;
  final String eodCompleted;
  final String eodPending;
  final String eodRemarks;
  final DateTime? createdAt;

  const EodEntry({
    required this.id,
    required this.eodCompleted,
    required this.eodPending,
    required this.eodRemarks,
    required this.createdAt,
  });

  factory EodEntry.fromJson(Map<String, dynamic> json) {
    return EodEntry(
      id: (json['_id'] ?? '').toString(),
      eodCompleted: (json['eodCompleted'] ?? '').toString(),
      eodPending: (json['eodPending'] ?? '').toString(),
      eodRemarks: (json['eodRemarks'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

class BodEodLog {
  final String id;
  final BodEodUser user;
  final String date;
  final String bodText;
  final String bodNotes;
  final DateTime? bodSubmittedAt;
  final String eodCompleted;
  final String eodPending;
  final String eodRemarks;
  final DateTime? eodSubmittedAt;
  final List<BodEntry> bodEntries;
  final List<EodEntry> eodEntries;

  const BodEodLog({
    required this.id,
    required this.user,
    required this.date,
    required this.bodText,
    required this.bodNotes,
    required this.bodSubmittedAt,
    required this.eodCompleted,
    required this.eodPending,
    required this.eodRemarks,
    required this.eodSubmittedAt,
    required this.bodEntries,
    required this.eodEntries,
  });

  factory BodEodLog.fromJson(Map<String, dynamic> json) {
    final rawBodEntries = (json['bodEntries'] as List?) ?? const [];
    final rawEodEntries = (json['eodEntries'] as List?) ?? const [];

    return BodEodLog(
      id: (json['_id'] ?? '').toString(),
      user: BodEodUser.fromJson(json['user']),
      date: (json['date'] ?? '').toString(),
      bodText: (json['bodText'] ?? '').toString(),
      bodNotes: (json['bodNotes'] ?? '').toString(),
      bodSubmittedAt:
          DateTime.tryParse((json['bodSubmittedAt'] ?? '').toString()),
      eodCompleted: (json['eodCompleted'] ?? '').toString(),
      eodPending: (json['eodPending'] ?? '').toString(),
      eodRemarks: (json['eodRemarks'] ?? '').toString(),
      eodSubmittedAt:
          DateTime.tryParse((json['eodSubmittedAt'] ?? '').toString()),
      bodEntries: rawBodEntries
          .whereType<Map<String, dynamic>>()
          .map(BodEntry.fromJson)
          .toList(),
      eodEntries: rawEodEntries
          .whereType<Map<String, dynamic>>()
          .map(EodEntry.fromJson)
          .toList(),
    );
  }

  String get bodPreview {
    if (bodEntries.isNotEmpty && bodEntries.first.bodText.trim().isNotEmpty) {
      return bodEntries.first.bodText.trim();
    }
    return bodText.trim();
  }

  String get eodPreview {
    if (eodEntries.isNotEmpty) {
      final top = eodEntries.first;
      if (top.eodCompleted.trim().isNotEmpty) return top.eodCompleted.trim();
      if (top.eodRemarks.trim().isNotEmpty) return top.eodRemarks.trim();
      return top.eodPending.trim();
    }

    if (eodCompleted.trim().isNotEmpty) return eodCompleted.trim();
    if (eodRemarks.trim().isNotEmpty) return eodRemarks.trim();
    return eodPending.trim();
  }
}

class BodEodService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Map<String, String> _headers(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Future<List<BodEodLog>> getMyLogs(
    String token, {
    required String startDate,
    required String endDate,
    int page = 1,
    int limit = 500,
  }) async {
    final uri = Uri.parse('$_baseUrl/bod-eod/me/list').replace(
      queryParameters: {
        'startDate': startDate,
        'endDate': endDate,
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await http
        .get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch logs (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (body['data'] as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(BodEodLog.fromJson)
        .toList();
  }

  static Future<List<BodEodLog>> getAllLogs(
    String token, {
    required String startDate,
    required String endDate,
    int page = 1,
    int limit = 500,
  }) async {
    final uri = Uri.parse('$_baseUrl/bod-eod/all').replace(
      queryParameters: {
        'startDate': startDate,
        'endDate': endDate,
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await http
        .get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch all logs (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (body['data'] as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(BodEodLog.fromJson)
        .toList();
  }
}

class BodEodScreen extends StatefulWidget {
  final String? token;
  final String? role;

  const BodEodScreen({super.key, this.token, this.role});

  @override
  State<BodEodScreen> createState() => _BodEodScreenState();
}

class _BodEodScreenState extends State<BodEodScreen>
    with SingleTickerProviderStateMixin {
  String? _token;
  bool _loading = true;
  String? _error;
  late DateTime _selectedMonth;

  final List<BodEodLog> _myLogs = [];
  final List<BodEodLog> _allLogs = [];
  String? _selectedEmployeeId;

  TabController? _tabController;

  bool get _isManager {
    final role = (widget.role ?? '').toLowerCase();
    return role == 'admin' || role == 'hr';
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    if (_isManager) {
      _tabController = TabController(length: 2, vsync: this);
    }
    _init();
  }

  @override
  void dispose() {
    _tabController?.dispose();
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
    await _loadLogs();
  }

  String _fmtDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  DateTime get _monthStart => DateTime(_selectedMonth.year, _selectedMonth.month, 1);

  DateTime get _monthEnd => DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

  Future<void> _loadLogs() async {
    final token = _token;
    if (token == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final myLogs = await BodEodService.getMyLogs(
        token,
        startDate: _fmtDate(_monthStart),
        endDate: _fmtDate(_monthEnd),
      );

      List<BodEodLog> allLogs = const [];
      if (_isManager) {
        allLogs = await BodEodService.getAllLogs(
          token,
          startDate: _fmtDate(_monthStart),
          endDate: _fmtDate(_monthEnd),
        );
      }

      if (!mounted) return;
      setState(() {
        _myLogs
          ..clear()
          ..addAll(myLogs);
        _allLogs
          ..clear()
          ..addAll(allLogs);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    });
    _loadLogs();
  }

  List<BodEodUser> _employeeOptions() {
    final byId = <String, BodEodUser>{};
    for (final log in _allLogs) {
      final user = log.user;
      if (user.id.isNotEmpty) {
        byId[user.id] = user;
      }
    }

    final users = byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return users;
  }

  List<BodEodLog> _filteredAllLogs() {
    final selectedId = _selectedEmployeeId;
    if (selectedId == null || selectedId.isEmpty) return _allLogs;
    return _allLogs.where((log) => log.user.id == selectedId).toList();
  }

  Widget _buildEmployeeFilter() {
    if (_loading || _error != null) {
      return const SizedBox.shrink();
    }

    final users = _employeeOptions();
    if (users.isEmpty) {
      return const SizedBox.shrink();
    }

    final selected = users.any((u) => u.id == _selectedEmployeeId)
        ? _selectedEmployeeId
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: selected,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          labelText: 'Employee Filter',
          labelStyle: TextStyle(color: Colors.grey[400]),
        ),
        dropdownColor: AppTheme.cardColor,
        iconEnabledColor: Colors.white,
        style: const TextStyle(color: Colors.white),
        hint: const Text(
          'All Employees',
          style: TextStyle(color: Colors.white),
        ),
        items: users
            .map(
              (user) => DropdownMenuItem<String>(
                value: user.id,
                child: Text(
                  user.employeeId.isNotEmpty
                      ? '${user.employeeId} - ${user.name}'
                      : user.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedEmployeeId = value;
          });
        },
      ),
    );
  }

  Widget _buildAllEmployeesTab() {
    return Column(
      children: [
        _buildEmployeeFilter(),
        Expanded(
          child: _buildList(_filteredAllLogs(), showUser: true),
        ),
      ],
    );
  }

  String _statusLabel(BodEodLog log) {
    if (log.eodSubmittedAt != null) return 'BOD + EOD';
    if (log.bodSubmittedAt != null) return 'BOD only';
    return 'Empty';
  }

  Color _statusColor(BodEodLog log) {
    if (log.eodSubmittedAt != null) return Colors.green;
    if (log.bodSubmittedAt != null) return Colors.orange;
    return Colors.grey;
  }

  void _showLogDetails(BodEodLog log) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(
          DateFormat('EEEE, MMM d, yyyy').format(
            DateTime.tryParse('${log.date}T00:00:00') ?? DateTime.now(),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log.user.name.isNotEmpty) ...[
                  Text(
                    log.user.name,
                    style: TextStyle(color: Colors.grey[300], fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildSectionTitle('BOD - Beginning of Day', Colors.orange),
                const SizedBox(height: 8),
                if (log.bodEntries.isNotEmpty)
                  ...log.bodEntries.map((entry) => _buildBodEntry(entry))
                else if (log.bodText.trim().isNotEmpty)
                  _buildTextCard(log.bodText, Colors.orange)
                else
                  _buildMutedText('No BOD submitted'),
                const SizedBox(height: 16),
                _buildSectionTitle('EOD - End of Day', Colors.indigo),
                const SizedBox(height: 8),
                if (log.eodEntries.isNotEmpty)
                  ...log.eodEntries.map((entry) => _buildEodEntry(entry))
                else if (log.eodCompleted.trim().isNotEmpty ||
                    log.eodPending.trim().isNotEmpty ||
                    log.eodRemarks.trim().isNotEmpty)
                  _buildEodText(log)
                else
                  _buildMutedText('No EOD submitted'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text, Color color) {
    return Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
    );
  }

  Widget _buildMutedText(String text) {
    return Text(
      text,
      style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
    );
  }

  Widget _buildTextCard(String text, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }

  Widget _buildBodEntry(BodEntry entry) {
    final subtitle = entry.bodNotes.trim();
    return _buildTextCard(
      subtitle.isNotEmpty ? '${entry.bodText}\n$subtitle' : entry.bodText,
      Colors.orange,
    );
  }

  Widget _buildEodEntry(EodEntry entry) {
    final parts = <String>[];
    if (entry.eodCompleted.trim().isNotEmpty) {
      parts.add('Completed: ${entry.eodCompleted.trim()}');
    }
    if (entry.eodPending.trim().isNotEmpty) {
      parts.add('Pending: ${entry.eodPending.trim()}');
    }
    if (entry.eodRemarks.trim().isNotEmpty) {
      parts.add('Remarks: ${entry.eodRemarks.trim()}');
    }
    return _buildTextCard(parts.join('\n'), Colors.indigo);
  }

  Widget _buildEodText(BodEodLog log) {
    final parts = <String>[];
    if (log.eodCompleted.trim().isNotEmpty) {
      parts.add('Completed: ${log.eodCompleted.trim()}');
    }
    if (log.eodPending.trim().isNotEmpty) {
      parts.add('Pending: ${log.eodPending.trim()}');
    }
    if (log.eodRemarks.trim().isNotEmpty) {
      parts.add('Remarks: ${log.eodRemarks.trim()}');
    }
    return _buildTextCard(parts.join('\n'), Colors.indigo);
  }

  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left),
            color: AppTheme.primaryColor,
          ),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right),
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 6),
          OutlinedButton.icon(
            onPressed: _loadLogs,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogTile(BodEodLog log, {required bool showUser}) {
    final date = DateTime.tryParse('${log.date}T00:00:00');
    final statusColor = _statusColor(log);

    return GestureDetector(
      onTap: () => _showLogDetails(log),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        date != null
                            ? DateFormat('dd MMM yyyy').format(date)
                            : log.date,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          _statusLabel(log),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showUser) ...[
                    const SizedBox(height: 6),
                    Text(
                      log.user.employeeId.isNotEmpty
                          ? '${log.user.employeeId} - ${log.user.name}'
                          : log.user.name,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    log.bodPreview.isNotEmpty
                        ? 'BOD: ${log.bodPreview}'
                        : 'BOD not submitted',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    log.eodPreview.isNotEmpty
                        ? 'EOD: ${log.eodPreview}'
                        : 'EOD not submitted',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<BodEodLog> logs, {required bool showUser}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[300]),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadLogs,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (logs.isEmpty) {
      return Center(
        child: Text(
          'No BOD/EOD logs found for this month',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (_, index) => _buildLogTile(logs[index], showUser: showUser),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text('BOD / EOD', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: _isManager
            ? TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey[500],
                tabs: const [
                  Tab(text: 'My BOD/EOD'),
                  Tab(text: 'All Employees'),
                ],
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildMonthHeader(),
              const SizedBox(height: 12),
              Expanded(
                child: _isManager
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(_myLogs, showUser: false),
                          _buildAllEmployeesTab(),
                        ],
                      )
                    : _buildList(_myLogs, showUser: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
