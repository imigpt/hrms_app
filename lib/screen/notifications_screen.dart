import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/announcement_service.dart';
import '../services/api_notification_service.dart';
import '../services/token_storage_service.dart';
import '../services/leave_service.dart';
import '../services/expense_service.dart';
import '../services/attendance_service.dart';
import '../services/task_service.dart';
import '../services/chat_service.dart';
import 'announcement_detail_screen.dart';
import '../theme/app_theme.dart';

//  Notification model
class _AppNotif {
  final String id;
  final bool isBackend;
  final String type;
  final String title;
  final String message;
  final DateTime time;
  bool read;

  _AppNotif({
    required this.id,
    this.isBackend = false,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.read = false,
  });

  factory _AppNotif.fromBackend(NotificationItem item) => _AppNotif(
    id: item.id,
    isBackend: true,
    type: item.type,
    title: item.title,
    message: item.message,
    time: item.createdAt,
    read: item.isRead,
  );
}

//  Type config
class _TypeCfg {
  final String label;
  final IconData icon;
  final Color color;
  const _TypeCfg(this.label, this.icon, this.color);
}

const Map<String, _TypeCfg> _typeConfig = {
  // Backend canonical types
  'announcement': _TypeCfg(
    'Announcement',
    Icons.campaign_outlined,
    AppTheme.primaryColor,
  ),
  'chat': _TypeCfg('Chat', Icons.message_outlined, Color(0xFF60A5FA)),
  'leave': _TypeCfg('Leave', Icons.calendar_today_outlined, Colors.orange),
  'expense': _TypeCfg('Expense', Icons.receipt_outlined, Colors.orange),
  'attendance': _TypeCfg(
    'Attendance',
    Icons.fingerprint_outlined,
    Colors.orange,
  ),
  'payroll': _TypeCfg(
    'Payroll',
    Icons.payments_outlined,
    AppTheme.primaryColor,
  ),
  'task_assigned': _TypeCfg(
    'Task Assigned',
    Icons.assignment_outlined,
    Color(0xFFFB923C),
  ),
  'task_updated': _TypeCfg(
    'Task Updated',
    Icons.update_outlined,
    Color(0xFF60A5FA),
  ),
  'task_comment': _TypeCfg(
    'Task Comment',
    Icons.comment_outlined,
    Color(0xFF60A5FA),
  ),
  'approval': _TypeCfg('Approval', Icons.approval_outlined, Colors.tealAccent),
  'general': _TypeCfg(
    'General',
    Icons.notifications_outlined,
    AppTheme.primaryColor,
  ),
  // Legacy locally-derived types (fallback)
  'leave_approved': _TypeCfg(
    'Leave Approved',
    Icons.check_circle_outline,
    Colors.green,
  ),
  'leave_rejected': _TypeCfg(
    'Leave Rejected',
    Icons.cancel_outlined,
    Colors.red,
  ),
  'leave_pending': _TypeCfg(
    'Leave Pending',
    Icons.calendar_today_outlined,
    Colors.orange,
  ),
  'expense_approved': _TypeCfg(
    'Expense Approved',
    Icons.check_circle_outline,
    Colors.green,
  ),
  'expense_rejected': _TypeCfg(
    'Expense Rejected',
    Icons.cancel_outlined,
    Colors.red,
  ),
  'expense_pending': _TypeCfg(
    'Expense Pending',
    Icons.receipt_outlined,
    Colors.orange,
  ),
  'attendance_edit_approved': _TypeCfg(
    'Att. Approved',
    Icons.check_circle_outline,
    Colors.green,
  ),
  'attendance_edit_rejected': _TypeCfg(
    'Att. Rejected',
    Icons.cancel_outlined,
    Colors.red,
  ),
  'attendance_edit_pending': _TypeCfg(
    'Att. Pending',
    Icons.edit_note_outlined,
    Colors.orange,
  ),
  'task_progress': _TypeCfg(
    'Task Progress',
    Icons.trending_up_rounded,
    Color(0xFF60A5FA),
  ),
  'task_reviewed': _TypeCfg(
    'Task Reviewed',
    Icons.star_outline_rounded,
    Color(0xFFFACC15),
  ),
};

_TypeCfg _cfgFor(String type) =>
    _typeConfig[type] ??
    const _TypeCfg(
      'Notification',
      Icons.notifications_outlined,
      AppTheme.primaryColor,
    );

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_AppNotif> _all = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  String _selectedTab = 'all';
  String? _token;
  String? _userId;
  String _role = 'employee';

  int _currentPage = 1;
  bool _hasMore = false;
  bool _usingBackend = false;

  static const _tabs = [
    ('all', 'All'),
    ('unread', 'Unread'),
    ('announcement', 'Announcements'),
    ('chat', 'Chat'),
    ('leave', 'Leaves'),
    ('expense', 'Expenses'),
    ('attendance', 'Attendance'),
    ('task', 'Tasks'),
    ('payroll', 'Payroll'),
  ];

  String get _storageKey => 'notif_read_ids_${_userId ?? ''}';

  Future<Set<String>> _getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    return Set<String>.from(prefs.getStringList(_storageKey) ?? []);
  }

  Future<void> _saveReadIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, ids.toList());
  }

  int get _total => _all.length;
  int get _unread => _all.where((n) => !n.read).length;
  int get _approvals => _all
      .where((n) => n.type.contains('approved') || n.type == 'approval')
      .length;
  int get _rejections => _all.where((n) => n.type.contains('rejected')).length;
  int get _tasks => _all
      .where((n) => n.type.startsWith('task_') || n.type == 'task_assigned')
      .length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
        _hasMore = false;
        _usingBackend = false;
      });
    try {
      final storage = TokenStorageService();
      _token = await storage.getToken();
      _userId = await storage.getUserId();
      _role = (await storage.getUserRole()) ?? 'employee';
      if (_token == null || _userId == null)
        throw Exception('Not authenticated');
      final readIds = await _getReadIds();

      // Try backend API first
      try {
        final page = await ApiNotificationService.getNotifications(
          authToken: _token!,
          userId: _userId!,
          page: 1,
          limit: 30,
        );
        if (page.items.isNotEmpty) {
          final items = page.items.map((item) {
            final n = _AppNotif.fromBackend(item);
            if (readIds.contains(item.id)) n.read = true;
            return n;
          }).toList();
          _usingBackend = true;
          _hasMore = page.pagination.hasMore;
          if (mounted)
            setState(() {
              _all = items;
              _isLoading = false;
            });
          return;
        }
      } catch (e) {
        debugPrint('Backend notification API: $e');
      }

      // Fallback: aggregate from services
      await _loadFromServices(readIds);
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || !_usingBackend) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final page = await ApiNotificationService.getNotifications(
        authToken: _token!,
        userId: _userId!,
        page: nextPage,
        limit: 30,
      );
      final readIds = await _getReadIds();
      final newItems = page.items.map((item) {
        final n = _AppNotif.fromBackend(item);
        if (readIds.contains(item.id)) n.read = true;
        return n;
      }).toList();
      setState(() {
        _all.addAll(newItems);
        _currentPage = nextPage;
        _hasMore = page.pagination.hasMore;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadFromServices(Set<String> readIds) async {
    bool isRead(String id) => readIds.contains(id);
    final List<_AppNotif> result = [];

    try {
      final res = await AnnouncementService.getAnnouncements(token: _token!);
      for (final a in res.data.take(5)) {
        final id = 'ann_${a.id}';
        result.add(
          _AppNotif(
            id: id,
            type: 'announcement',
            title: 'New Announcement',
            message: a.title ?? 'Company announcement',
            time: a.createdAt,
            read: isRead(id),
          ),
        );
      }
    } catch (_) {}

    try {
      final res = await ChatService.getUnreadCount(token: _token!);
      if (res.count > 0) {
        const id = 'chat_unread_bulk';
        result.add(
          _AppNotif(
            id: id,
            type: 'chat',
            title: 'Unread Messages',
            message:
                'You have ${res.count} unread message${res.count > 1 ? 's' : ''}',
            time: DateTime.now(),
            read: isRead(id),
          ),
        );
      }
    } catch (_) {}

    if (_role == 'employee' || _role == 'hr' || _role == 'admin') {
      try {
        final res = await LeaveService.getMyLeaves(token: _token!);
        final allLeaves = ((res['data'] as List<dynamic>?) ?? []);
        print('DEBUG: All leaves from API: ${allLeaves.length} items');
        for (var i = 0; i < allLeaves.length; i++) {
          print('  Leave $i: status=${allLeaves[i]['status']}, startDate=${allLeaves[i]['startDate']}, updatedAt=${allLeaves[i]['updatedAt']}, createdAt=${allLeaves[i]['createdAt']}');
        }
        final filtered = allLeaves.where(
          (l) => l['status'] == 'approved' || l['status'] == 'rejected',
        ).toList();
        print('DEBUG: Filtered leaves (approved+rejected): ${filtered.length} items');
        for (final l in filtered.take(5)) {
          final id = 'leave_${l['_id'] ?? l['id']}_${l['status']}';
          final s = l['status'] as String;
          result.add(
            _AppNotif(
              id: id,
              type: s == 'approved' ? 'leave_approved' : 'leave_rejected',
              title: s == 'approved' ? ' Leave Approved' : ' Leave Rejected',
              message:
                  'Your ${l['leaveType'] ?? 'leave'} (${_fmtDate(l['startDate'])}) was $s',
              time: _parseDate(l['updatedAt'] ?? l['createdAt']),
              read: isRead(id),
            ),
          );
        }
      } catch (_) {}

      try {
        final res = await ExpenseService.getExpenses(token: _token!);
        for (final e
            in res.data
                .where((e) => e.status == 'approved' || e.status == 'rejected')
                .take(5)) {
          final id = 'exp_${e.id}_${e.status}';
          result.add(
            _AppNotif(
              id: id,
              type: e.status == 'approved'
                  ? 'expense_approved'
                  : 'expense_rejected',
              title: e.status == 'approved'
                  ? ' Expense Approved'
                  : ' Expense Rejected',
              message: 'Your expense "${e.category}" was ${e.status}',
              time: e.updatedAt,
              read: isRead(id),
            ),
          );
        }
      } catch (_) {}

      try {
        final res = await AttendanceService.getEditRequests(token: _token!);
        for (final r
            in res.data
                .where((r) => r.status == 'approved' || r.status == 'rejected')
                .take(5)) {
          final id = 'attedit_${r.id}_${r.status}';
          result.add(
            _AppNotif(
              id: id,
              type: r.status == 'approved'
                  ? 'attendance_edit_approved'
                  : 'attendance_edit_rejected',
              title: r.status == 'approved'
                  ? ' Attendance Approved'
                  : ' Attendance Rejected',
              message: 'Your attendance correction was ${r.status}',
              time: r.updatedAt,
              read: isRead(id),
            ),
          );
        }
      } catch (_) {}
    }

    if (_role == 'hr' || _role == 'admin') {
      try {
        final res = await LeaveService.getAdminLeaves(
          token: _token!,
          status: 'pending',
        );
        for (final l in res.data.take(3)) {
          final id = 'pending_leave_${l.id}';
          result.add(
            _AppNotif(
              id: id,
              type: 'leave_pending',
              title: ' Leave Request Pending',
              message:
                  '${l.user?.name ?? 'An employee'} requested ${l.leaveType} — awaiting review',
              time: l.createdAt,
              read: isRead(id),
            ),
          );
        }
      } catch (_) {}

      try {
        final res = await AttendanceService.getPendingAdminEditRequests(
          token: _token!,
        );
        for (final r in res.data.take(3)) {
          final id = 'pending_edit_${r.id}';
          result.add(
            _AppNotif(
              id: id,
              type: 'attendance_edit_pending',
              title: ' Attendance Edit Request',
              message:
                  '${r.employee?.name ?? 'An employee'} requested attendance correction',
              time: r.createdAt,
              read: isRead(id),
            ),
          );
        }
      } catch (_) {}
    }

    try {
      final res = await TaskService.getTasks(_token!);
      final tasks =
          (res['tasks'] ?? res['data']?['tasks'] ?? []) as List<dynamic>;
      // Show assigned tasks for all roles
      for (final t in tasks.take(5)) {
        final id = 'task_assigned_${t['_id'] ?? t['id']}';
        result.add(
          _AppNotif(
            id: id,
            type: 'task_assigned',
            title: ' New Task Assigned',
            message:
                '"${t['title']}" — Priority: ${t['priority'] ?? 'N/A'}, Due: ${_fmtDate(t['dueDate'])}',
            time: _parseDate(t['createdAt'] ?? t['createdDate']),
            read: isRead(id),
          ),
        );
      }
      // Show task reviews for employees
      if (_role == 'employee') {
        for (final t
            in tasks.where((t) => t['review']?['comment'] != null).take(5)) {
          final id = 'task_reviewed_${t['_id'] ?? t['id']}';
          result.add(
            _AppNotif(
              id: id,
              type: 'task_reviewed',
              title: ' Task Reviewed',
              message:
                  'Your task "${t['title']}" received a review${t['review']['rating'] != null ? ' (${t['review']['rating']}/5)' : ''}',
              time: _parseDate(t['review']['reviewedAt'] ?? t['updatedAt']),
              read: isRead(id),
            ),
          );
        }
      }
      // Show task progress for admins/hr and employees with progressing tasks
      for (final t
          in tasks
              .where(
                (t) => (t['progress'] ?? 0) > 0 && t['status'] != 'completed',
              )
              .take(5)) {
        final id = 'task_progress_${t['_id'] ?? t['id']}_${t['progress']}';
        result.add(
          _AppNotif(
            id: id,
            type: 'task_progress',
            title: ' Task Progress Updated',
            message:
                '"${t['title']}" — ${t['assignedTo']?['name'] ?? 'Employee'} updated progress to ${t['progress']}%',
            time: _parseDate(t['updatedAt']),
            read: isRead(id),
          ),
        );
      }
    } catch (_) {}

    result.sort((a, b) => b.time.compareTo(a.time));
    if (mounted)
      setState(() {
        _all = result;
        _isLoading = false;
      });
  }

  List<_AppNotif> get _filtered {
    switch (_selectedTab) {
      case 'unread':
        return _all.where((n) => !n.read).toList();
      case 'announcement':
        return _all.where((n) => n.type == 'announcement').toList();
      case 'chat':
        return _all.where((n) => n.type == 'chat').toList();
      case 'leave':
        final leaveNotifs = _all
            .where((n) => n.type == 'leave' || n.type.startsWith('leave_'))
            .toList();
        print('DEBUG [Filter Leave]: Total _all: ${_all.length}, Filtered leave notifs: ${leaveNotifs.length}');
        for (final n in leaveNotifs) {
          print('  - Leave notif: type=${n.type}, title=${n.title}, read=${n.read}');
        }
        return leaveNotifs;
      case 'expense':
        return _all
            .where((n) => n.type == 'expense' || n.type.startsWith('expense_'))
            .toList();
      case 'attendance':
        return _all
            .where(
              (n) => n.type == 'attendance' || n.type.startsWith('attendance_'),
            )
            .toList();
      case 'task':
        return _all
            .where(
              (n) => n.type.startsWith('task_') || n.type == 'task_assigned',
            )
            .toList();
      case 'payroll':
        return _all.where((n) => n.type == 'payroll').toList();
      default:
        return _all;
    }
  }

  String get _listHeader => switch (_selectedTab) {
    'unread' => 'Unread Notifications',
    'announcement' => 'Announcements',
    'chat' => 'Chat Notifications',
    'leave' => 'Leave Notifications',
    'expense' => 'Expense Notifications',
    'attendance' => 'Attendance Notifications',
    'task' => 'Task Notifications',
    'payroll' => 'Payroll Notifications',
    _ => 'All Notifications',
  };

  Future<void> _markRead(_AppNotif n) async {
    if (n.read) return;
    setState(() => n.read = true);
    final ids = await _getReadIds();
    ids.add(n.id);
    await _saveReadIds(ids);

    if (n.isBackend && _token != null) {
      try {
        await ApiNotificationService.markAsRead(
          authToken: _token!,
          notificationId: n.id,
        );
      } catch (_) {}
    } else if (n.type == 'announcement' && _token != null) {
      final annId = n.id.replaceFirst('ann_', '');
      try {
        await AnnouncementService.markAsRead(
          token: _token!,
          announcementId: annId,
        );
      } catch (_) {}
    }
  }

  Future<void> _markAllRead() async {
    final ids = await _getReadIds();
    for (final n in _all) {
      n.read = true;
      ids.add(n.id);
    }
    await _saveReadIds(ids);
    if (mounted) setState(() {});

    if (_usingBackend && _token != null && _userId != null) {
      try {
        await ApiNotificationService.markAllAsRead(
          authToken: _token!,
          userId: _userId!,
        );
      } catch (_) {}
    } else if (_token != null) {
      for (final n in _all.where((n) => n.type == 'announcement')) {
        try {
          await AnnouncementService.markAsRead(
            token: _token!,
            announcementId: n.id.replaceFirst('ann_', ''),
          );
        } catch (_) {}
      }
    }
  }

  String _fmtDate(dynamic raw) {
    if (raw == null) return 'N/A';
    try {
      return DateFormat('MMM d').format(DateTime.parse(raw.toString()));
    } catch (_) {
      return raw.toString();
    }
  }

  DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  // Responsive helpers
  bool get _isTablet => MediaQuery.of(context).size.width >= 600;
  double get _horizontalPadding => _isTablet ? 24 : 16;
  double get _statCardWidth => _isTablet ? 140 : 120;
  double get _statCardHeight => _isTablet ? 96 : 84;
  double get _titleFontSize => _isTablet ? 20 : 18;
  double get _subtitleFontSize => _isTablet ? 13 : 11;
  double get _bodyFontSize => _isTablet ? 14 : 12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: _titleFontSize,
                  ),
                ),
              ],
            ),
            Text(
              _isLoading
                  ? 'Loading...'
                  : _unread > 0
                  ? '$_unread unread notification${_unread > 1 ? 's' : ''}'
                  : 'All caught up!',
              style: TextStyle(
                color: AppTheme.onSurface.withValues(alpha: 0.6),
                fontSize: _subtitleFontSize,
              ),
            ),
          ],
        ),
        actions: [
          if (_unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark All Read',
                style: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 2.5,
              ),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.errorColor),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _load,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primaryColor,
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: _horizontalPadding,
                  vertical: 12,
                ),
                children: [
                  // Role + source badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_usingBackend)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.secondaryColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: AppTheme.secondaryColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _role.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stat cards
                  SizedBox(
                    height: _statCardHeight,
                    child: ListView(
                      scrollDirection: _isTablet
                          ? Axis.vertical
                          : Axis.horizontal,
                      children: _isTablet
                          ? [
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _statCard(
                                    Icons.notifications_outlined,
                                    'Total',
                                    _total,
                                    AppTheme.primaryColor,
                                  ),
                                  _statCard(
                                    Icons.mark_email_unread_outlined,
                                    'Unread',
                                    _unread,
                                    const Color(0xFF4ADE80),
                                  ),
                                  _statCard(
                                    Icons.check_circle_outline,
                                    'Approvals',
                                    _approvals,
                                    Colors.tealAccent,
                                  ),
                                  _statCard(
                                    Icons.cancel_outlined,
                                    'Rejections',
                                    _rejections,
                                    Colors.redAccent,
                                  ),
                                  _statCard(
                                    Icons.assignment_outlined,
                                    'Tasks',
                                    _tasks,
                                    const Color(0xFFFB923C),
                                  ),
                                ],
                              ),
                            ]
                          : [
                              _statCard(
                                Icons.notifications_outlined,
                                'Total',
                                _total,
                                AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 10),
                              _statCard(
                                Icons.mark_email_unread_outlined,
                                'Unread',
                                _unread,
                                const Color(0xFF4ADE80),
                              ),
                              const SizedBox(width: 10),
                              _statCard(
                                Icons.check_circle_outline,
                                'Approvals',
                                _approvals,
                                Colors.tealAccent,
                              ),
                              const SizedBox(width: 10),
                              _statCard(
                                Icons.cancel_outlined,
                                'Rejections',
                                _rejections,
                                Colors.redAccent,
                              ),
                              const SizedBox(width: 10),
                              _statCard(
                                Icons.assignment_outlined,
                                'Tasks',
                                _tasks,
                                const Color(0xFFFB923C),
                              ),
                            ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Filter tabs
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _tabs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final (key, label) = _tabs[i];
                        final sel = key == _selectedTab;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTab = key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppTheme.primaryColor
                                  : AppTheme.outline.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel
                                    ? AppTheme.primaryColor
                                    : AppTheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              key == 'unread' ? 'Unread ($_unread)' : label,
                              style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : AppTheme.onSurface.withValues(alpha: 0.6),
                                fontSize: _bodyFontSize,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // List header
                  Text(
                    '$_listHeader (${_filtered.length})',
                    style: TextStyle(
                      color: AppTheme.onSurface.withValues(alpha: 0.6),
                      fontSize: _bodyFontSize,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_filtered.isEmpty) _buildEmpty(),
                  ..._filtered.map(_buildTile),

                  // Load more
                  if (_hasMore && _usingBackend && _selectedTab == 'all')
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: _isLoadingMore
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryColor,
                                  strokeWidth: 2,
                                ),
                              )
                            : TextButton.icon(
                                onPressed: _loadMore,
                                icon: Icon(
                                  Icons.expand_more_rounded,
                                  color: AppTheme.primaryColor,
                                  size: _isTablet ? 20 : 18,
                                ),
                                label: const Text(
                                  'Load More',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor
                                      .withValues(alpha: 0.08),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: _isTablet ? 24 : 20,
                                    vertical: _isTablet ? 12 : 10,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _statCard(IconData icon, String label, int count, Color color) {
    return Container(
      width: _statCardWidth,
      padding: EdgeInsets.symmetric(
        vertical: _isTablet ? 16 : 14,
        horizontal: _isTablet ? 16 : 14,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(_isTablet ? 10 : 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: _isTablet ? 22 : 20,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.onSurface.withValues(alpha: 0.6),
                  fontSize: _isTablet ? 11 : 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _isTablet ? 64 : 48),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            color: AppTheme.outline,
            size: _isTablet ? 56 : 48,
          ),
          SizedBox(height: _isTablet ? 16 : 12),
          Text(
            'No notifications',
            style: TextStyle(
              color: AppTheme.onSurface.withValues(alpha: 0.6),
              fontSize: _isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: _isTablet ? 8 : 4),
          Text(
            "You're all caught up!",
            style: TextStyle(
              color: AppTheme.onSurface.withValues(alpha: 0.5),
              fontSize: _isTablet ? 13 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(_AppNotif n) {
    final cfg = _cfgFor(n.type);
    return GestureDetector(
      onTap: () async {
        await _markRead(n);
        if (n.type == 'announcement' && mounted) {
          final annId = n.isBackend ? n.id : n.id.replaceFirst('ann_', '');
          try {
            final res = await AnnouncementService.getAnnouncements(
              token: _token!,
            );
            final ann = res.data.where((a) => a.id == annId).firstOrNull;
            if (ann != null && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnnouncementDetailScreen(announcement: ann),
                ),
              );
            }
          } catch (_) {}
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.read
              ? AppTheme.surfaceVariant.withValues(alpha: 0.5)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: n.read
                ? AppTheme.outline.withValues(alpha: 0.2)
                : cfg.color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cfg.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                cfg.icon,
                color: cfg.color,
                size: _isTablet ? 20 : 18,
              ),
            ),
            SizedBox(width: _isTablet ? 14 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            color: n.read
                                ? AppTheme.onSurface.withValues(alpha: 0.7)
                                : AppTheme.onSurface,
                            fontSize: _isTablet ? 14 : 13,
                            fontWeight: n.read
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!n.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: cfg.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: _isTablet ? 6 : 4),
                  Text(
                    n.message,
                    style: TextStyle(
                      color: AppTheme.onSurface.withValues(alpha: 0.7),
                      fontSize: _isTablet ? 13 : 12,
                    ),
                    maxLines: _isTablet ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: _isTablet ? 8 : 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cfg.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: cfg.color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          cfg.label,
                          style: TextStyle(
                            color: cfg.color,
                            fontSize: _isTablet ? 11 : 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: _isTablet ? 10 : 8),
                      Text(
                        _timeAgo(n.time),
                        style: TextStyle(
                          color: AppTheme.onSurface.withValues(alpha: 0.5),
                          fontSize: _isTablet ? 11 : 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.outline,
              size: _isTablet ? 20 : 18,
            ),
          ],
        ),
      ),
    );
  }
}
