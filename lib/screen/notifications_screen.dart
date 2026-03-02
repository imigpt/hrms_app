import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';
import '../services/token_storage_service.dart';
import '../services/leave_service.dart';
import '../services/expense_service.dart';
import '../services/attendance_service.dart';
import '../services/task_service.dart';
import '../services/chat_service.dart';
import 'announcement_detail_screen.dart';
import '../theme/app_theme.dart';

// ─── Notification model ────────────────────────────────────────────────────
class _AppNotif {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime time;
  bool read;

  _AppNotif({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.read = false,
  });
}

// ─── Type config ───────────────────────────────────────────────────────────
class _TypeCfg {
  final String label;
  final IconData icon;
  final Color color;
  const _TypeCfg(this.label, this.icon, this.color);
}

const Map<String, _TypeCfg> _typeConfig = {
  'announcement':            _TypeCfg('Announcement',              Icons.campaign_outlined,        AppTheme.primaryColor),
  'chat':                    _TypeCfg('Chat',                      Icons.message_outlined,          Color(0xFF60A5FA)),
  'leave_approved':          _TypeCfg('Leave Approved',            Icons.check_circle_outline,      Colors.green),
  'leave_rejected':          _TypeCfg('Leave Rejected',            Icons.cancel_outlined,           Colors.red),
  'leave_pending':           _TypeCfg('Leave Pending',             Icons.calendar_today_outlined,   Colors.orange),
  'expense_approved':        _TypeCfg('Expense Approved',          Icons.check_circle_outline,      Colors.green),
  'expense_rejected':        _TypeCfg('Expense Rejected',          Icons.cancel_outlined,           Colors.red),
  'expense_pending':         _TypeCfg('Expense Pending',           Icons.receipt_outlined,          Colors.orange),
  'attendance_edit_approved':_TypeCfg('Attendance Edit Approved',  Icons.check_circle_outline,      Colors.green),
  'attendance_edit_rejected':_TypeCfg('Attendance Edit Rejected',  Icons.cancel_outlined,           Colors.red),
  'attendance_edit_pending': _TypeCfg('Attendance Edit Pending',   Icons.edit_note_outlined,        Colors.orange),
  'task_assigned':           _TypeCfg('Task Assigned',             Icons.assignment_outlined,       Color(0xFFFB923C)),
  'task_progress':           _TypeCfg('Task Progress',             Icons.trending_up_rounded,       Color(0xFF60A5FA)),
  'task_reviewed':           _TypeCfg('Task Reviewed',             Icons.star_outline_rounded,      Color(0xFFFACC15)),
};

_TypeCfg _cfgFor(String type) =>
    _typeConfig[type] ?? const _TypeCfg('Notification', Icons.notifications_outlined, AppTheme.primaryColor);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_AppNotif> _all = [];
  bool _isLoading = true;
  String? _error;
  String _selectedTab = 'all';
  String? _token;
  String? _userId;
  String _role = 'employee'; // employee | hr | admin

  // Filter tabs
  static const _tabs = [
    ('all',          'All'),
    ('unread',       'Unread'),
    ('announcement', 'Announcements'),
    ('chat',         'Chat'),
    ('leave',        'Leaves'),
    ('expense',      'Expenses'),
    ('attendance',   'Attendance'),
    ('task',         'Tasks'),
  ];

  // ── Read IDs ───────────────────────────────────────────────────────────────
  String get _storageKey => 'notif_read_ids_${_userId ?? ''}';

  Future<Set<String>> _getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    return Set<String>.from(prefs.getStringList(_storageKey) ?? []);
  }

  Future<void> _saveReadIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, ids.toList());
  }

  // ── Stats ──────────────────────────────────────────────────────────────────
  int get _total      => _all.length;
  int get _unread     => _all.where((n) => !n.read).length;
  int get _approvals  => _all.where((n) => n.type.contains('approved')).length;
  int get _rejections => _all.where((n) => n.type.contains('rejected')).length;
  int get _tasks      => _all.where((n) => n.type.startsWith('task_')).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Main loader (mirrors NotificationContext.buildNotifications) ───────────
  Future<void> _load() async {
    if (mounted) setState(() { _isLoading = true; _error = null; });

    try {
      final storage = TokenStorageService();
      _token = await storage.getToken();
      _userId = await storage.getUserId();
      _role   = (await storage.getUserRole()) ?? 'employee';

      if (_token == null) throw Exception('Not authenticated');

      final readIds = await _getReadIds();
      bool isRead(String id) => readIds.contains(id);

      final List<_AppNotif> result = [];

      // ── 1. Announcements (all roles) ───────────────────────────────────────
      try {
        final res = await AnnouncementService.getAnnouncements(token: _token!);
        for (final a in res.data.take(5)) {
          final id = 'ann_${a.id}';
          result.add(_AppNotif(
            id: id, type: 'announcement',
            title: 'New Announcement',
            message: a.title ?? 'Company announcement',
            time: a.createdAt,
            read: isRead(id),
          ));
        }
      } catch (_) {}

      // ── 2. Chat unread (all roles) ─────────────────────────────────────────
      try {
        final res = await ChatService.getUnreadCount(token: _token!);
        final count = res.count;
        if (count > 0) {
          const id = 'chat_unread_bulk';
          result.add(_AppNotif(
            id: id, type: 'chat',
            title: 'Unread Messages',
            message: 'You have $count unread message${count > 1 ? 's' : ''}',
            time: DateTime.now(),
            read: isRead(id),
          ));
        }
      } catch (_) {}

      // ── 3. Employee / HR: Leave decisions ─────────────────────────────────
      if (_role == 'employee' || _role == 'hr') {
        try {
          final res = await LeaveService.getMyLeaves(token: _token!);
          final leaves = (res['data'] as List<dynamic>? ?? []);
          for (final l in leaves.where((l) => l['status'] == 'approved' || l['status'] == 'rejected').take(5)) {
            final id = 'leave_${l['_id'] ?? l['id']}_${l['status']}';
            final status = l['status'] as String;
            result.add(_AppNotif(
              id: id,
              type: status == 'approved' ? 'leave_approved' : 'leave_rejected',
              title: status == 'approved' ? '\u2705 Leave Approved' : '\u274C Leave Rejected',
              message: 'Your ${l['leaveType'] ?? 'leave'} request (${_fmtDate(l['startDate'])}) was $status',
              time: _parseDate(l['updatedAt'] ?? l['createdAt']),
              read: isRead(id),
            ));
          }
        } catch (_) {}

        // ── 4. Expense decisions ─────────────────────────────────────────────
        try {
          final res = await ExpenseService.getExpenses(token: _token!);
          for (final e in res.data.where((e) => e.status == 'approved' || e.status == 'rejected').take(5)) {
            final id = 'exp_${e.id}_${e.status}';
            result.add(_AppNotif(
              id: id,
              type: e.status == 'approved' ? 'expense_approved' : 'expense_rejected',
              title: e.status == 'approved' ? '\u2705 Expense Approved' : '\u274C Expense Rejected',
              message: 'Your expense "${e.category}" was ${e.status}',
              time: e.updatedAt,
              read: isRead(id),
            ));
          }
        } catch (_) {}

        // ── 5. Attendance edit outcomes ──────────────────────────────────────
        try {
          final res = await AttendanceService.getEditRequests(token: _token!);
          for (final r in res.data.where((r) => r.status == 'approved' || r.status == 'rejected').take(5)) {
            final id = 'attedit_${r.id}_${r.status}';
            result.add(_AppNotif(
              id: id,
              type: r.status == 'approved' ? 'attendance_edit_approved' : 'attendance_edit_rejected',
              title: r.status == 'approved' ? '\u2705 Attendance Edit Approved' : '\u274C Attendance Edit Rejected',
              message: 'Your attendance correction was ${r.status}',
              time: r.updatedAt,
              read: isRead(id),
            ));
          }
        } catch (_) {}
      }

      // ── 6. HR / Admin: pending items ───────────────────────────────────────
      if (_role == 'hr' || _role == 'admin') {
        // Pending leaves
        try {
          final res = await LeaveService.getAdminLeaves(token: _token!, status: 'pending');
          for (final l in res.data.take(3)) {
            final id = 'pending_leave_${l.id}';
            result.add(_AppNotif(
              id: id, type: 'leave_pending',
              title: '\u{1F4CB} Leave Request Pending',
              message: '${l.user?.name ?? 'An employee'} requested ${l.leaveType} — awaiting review',
              time: l.createdAt,
              read: isRead(id),
            ));
          }
        } catch (_) {}

        // Pending attendance edits
        try {
          final res = await AttendanceService.getPendingAdminEditRequests(token: _token!);
          for (final r in res.data.take(3)) {
            final id = 'pending_edit_${r.id}';
            result.add(_AppNotif(
              id: id, type: 'attendance_edit_pending',
              title: '\u{1F4CB} Attendance Edit Request',
              message: '${r.employee?.name ?? 'An employee'} requested attendance correction',
              time: r.createdAt,
              read: isRead(id),
            ));
          }
        } catch (_) {}
      }

      // ── 7. Tasks ────────────────────────────────────────────────────────────
      try {
        final res = await TaskService.getTasks(_token!);
        final tasks = (res['tasks'] ?? res['data']?['tasks'] ?? []) as List<dynamic>;

        if (_role == 'employee') {
          for (final t in tasks.take(5)) {
            final id = 'task_assigned_${t['_id'] ?? t['id']}';
            result.add(_AppNotif(
              id: id, type: 'task_assigned',
              title: '📋 New Task Assigned',
              message: '"${t['title']}" — Priority: ${t['priority'] ?? 'N/A'}, Due: ${_fmtDate(t['dueDate'])}',
              time: _parseDate(t['createdAt'] ?? t['createdDate']),
              read: isRead(id),
            ));
          }
          // Reviews
          for (final t in tasks.where((t) => t['review']?['comment'] != null).take(5)) {
            final id = 'task_reviewed_${t['_id'] ?? t['id']}';
            final rating = t['review']['rating'];
            result.add(_AppNotif(
              id: id, type: 'task_reviewed',
              title: '⭐ Task Reviewed',
              message: 'Your task "${t['title']}" received a review${rating != null ? ' ($rating/5)' : ''}',
              time: _parseDate(t['review']['reviewedAt'] ?? t['updatedAt']),
              read: isRead(id),
            ));
          }
        }

        if (_role == 'hr' || _role == 'admin') {
          for (final t in tasks.where((t) => (t['progress'] ?? 0) > 0 && t['status'] != 'completed').take(5)) {
            final id = 'task_progress_${t['_id'] ?? t['id']}_${t['progress']}';
            result.add(_AppNotif(
              id: id, type: 'task_progress',
              title: '📊 Task Progress Updated',
              message: '"${t['title']}" — ${t['assignedTo']?['name'] ?? 'Employee'} updated progress to ${t['progress']}%',
              time: _parseDate(t['updatedAt']),
              read: isRead(id),
            ));
          }
        }
      } catch (_) {}

      // Sort newest first
      result.sort((a, b) => b.time.compareTo(a.time));

      if (mounted) setState(() { _all = result; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  // ── Filters ────────────────────────────────────────────────────────────────
  List<_AppNotif> get _filtered {
    switch (_selectedTab) {
      case 'unread':      return _all.where((n) => !n.read).toList();
      case 'announcement':return _all.where((n) => n.type == 'announcement').toList();
      case 'chat':        return _all.where((n) => n.type == 'chat').toList();
      case 'leave':       return _all.where((n) => n.type.startsWith('leave_')).toList();
      case 'expense':     return _all.where((n) => n.type.startsWith('expense_')).toList();
      case 'attendance':  return _all.where((n) => n.type.startsWith('attendance_')).toList();
      case 'task':        return _all.where((n) => n.type.startsWith('task_')).toList();
      default:            return _all;
    }
  }

  String get _listHeader => switch (_selectedTab) {
    'unread'       => 'Unread Notifications',
    'announcement' => 'Announcements',
    'chat'         => 'Chat Notifications',
    'leave'        => 'Leave Notifications',
    'expense'      => 'Expense Notifications',
    'attendance'   => 'Attendance Notifications',
    'task'         => 'Task Notifications',
    _              => 'All Notifications',
  };

  // ── Mark read ──────────────────────────────────────────────────────────────
  Future<void> _markRead(_AppNotif n) async {
    if (n.read) return;
    setState(() => n.read = true);
    final ids = await _getReadIds();
    ids.add(n.id);
    await _saveReadIds(ids);

    // Also mark on backend if it's an announcement
    if (n.type == 'announcement' && _token != null) {
      final annId = n.id.replaceFirst('ann_', '');
      try { await AnnouncementService.markAsRead(token: _token!, announcementId: annId); } catch (_) {}
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

    // Backend: mark all announcements as read
    if (_token != null) {
      for (final n in _all.where((n) => n.type == 'announcement')) {
        final annId = n.id.replaceFirst('ann_', '');
        try { await AnnouncementService.markAsRead(token: _token!, announcementId: annId); } catch (_) {}
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _fmtDate(dynamic raw) {
    if (raw == null) return 'N/A';
    try { return DateFormat('MMM d').format(DateTime.parse(raw.toString())); } catch (_) { return raw.toString(); }
  }

  DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    try { return DateTime.parse(raw.toString()); } catch (_) { return DateTime.now(); }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161616),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Notifications',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ]),
            Text(
              _unread > 0 ? '$_unread unread notification${_unread > 1 ? 's' : ''}' : 'All caught up!',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
        actions: [
          if (_unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark All Read',
                  style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2.5))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      // ── Role badge ───────────────────────────────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            _role.toUpperCase(),
                            style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Stat cards ───────────────────────────────────────
                      SizedBox(
                        height: 84,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _statCard(Icons.notifications_outlined, 'Total',      _total,      AppTheme.primaryColor),
                            const SizedBox(width: 10),
                            _statCard(Icons.mark_email_unread_outlined, 'Unread',  _unread,    const Color(0xFF4ADE80)),
                            const SizedBox(width: 10),
                            _statCard(Icons.check_circle_outline, 'Approvals',    _approvals,  Colors.tealAccent),
                            const SizedBox(width: 10),
                            _statCard(Icons.cancel_outlined, 'Rejections',        _rejections, Colors.redAccent),
                            const SizedBox(width: 10),
                            _statCard(Icons.assignment_outlined, 'Tasks',         _tasks,      const Color(0xFFFB923C)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Filter tabs ──────────────────────────────────────
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
                                  color: sel ? AppTheme.primaryColor : Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: sel ? AppTheme.primaryColor : Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  key == 'unread' ? 'Unread ($_unread)' : label,
                                  style: TextStyle(
                                    color: sel ? Colors.white : Colors.grey[400],
                                    fontSize: 12,
                                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── List header ──────────────────────────────────────
                      Text(
                        '$_listHeader (${_filtered.length})',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12,
                            fontWeight: FontWeight.w600, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 12),

                      // ── Items / Empty ────────────────────────────────────
                      if (_filtered.isEmpty) _buildEmpty(),
                      ..._filtered.map(_buildTile),
                    ],
                  ),
                ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────
  Widget _statCard(IconData icon, String label, int count, Color color) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$count', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold, height: 1.1)),
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
          ],
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        Icon(Icons.notifications_off_outlined, color: Colors.grey[700], size: 48),
        const SizedBox(height: 12),
        Text('No notifications', style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text("You're all caught up!", style: TextStyle(color: Colors.grey[700], fontSize: 12)),
      ]),
    );
  }

  Widget _buildTile(_AppNotif n) {
    final cfg = _cfgFor(n.type);

    return GestureDetector(
      onTap: () async {
        await _markRead(n);
        // Navigate to detail if it's an announcement
        if (n.type == 'announcement' && mounted) {
          final annId = n.id.replaceFirst('ann_', '');
          try {
            final res = await AnnouncementService.getAnnouncements(token: _token!);
            final ann = res.data.where((a) => a.id == annId).firstOrNull;
            if (ann != null && mounted) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => AnnouncementDetailScreen(announcement: ann),
              ));
            }
          } catch (_) {}
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.read ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: n.read ? Colors.white.withOpacity(0.05) : cfg.color.withOpacity(0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: cfg.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(cfg.icon, color: cfg.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(n.title,
                        style: TextStyle(
                          color: n.read ? Colors.white70 : Colors.white,
                          fontSize: 13,
                          fontWeight: n.read ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!n.read)
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: cfg.color, shape: BoxShape.circle),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  Text(n.message,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cfg.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cfg.color.withOpacity(0.3)),
                      ),
                      child: Text(cfg.label, style: TextStyle(color: cfg.color, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Text(_timeAgo(n.time), style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[700], size: 18),
          ],
        ),
      ),
    );
  }
}
