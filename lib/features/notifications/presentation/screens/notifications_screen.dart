import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/features/announcements/presentation/screens/announcement_detail_screen.dart';
import 'package:hrms_app/features/notifications/data/services/api_notification_service.dart';
import 'package:hrms_app/features/notifications/presentation/providers/notifications_notifier.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';

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
  String? _token;
  String? _userId;
  String _role = 'employee';

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

  // Tabs shown for client users (limited)
  static const _clientTabs = [
    ('all', 'All'),
    ('unread', 'Unread'),
    ('chat', 'Chat'),
  ];


  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }
  Future<void> _initAndLoad({bool force = false}) async {
    if (force || _token == null || _userId == null) {
      final storage = TokenStorageService();
      _token = await storage.getToken();
      _userId = await storage.getUserId();
      _role = (await storage.getUserRole()) ?? 'employee';
    }

    if (!mounted) return;

    if (_token == null || _userId == null) {
      context.read<NotificationsNotifier>().setError('Not authenticated');
      return;
    }

    await context.read<NotificationsNotifier>().loadNotifications(
      _token!,
      userId: _userId!,
      role: _role,
    );
  }

  Future<void> _loadMore() async {
    if (_token == null || _userId == null) return;
    await context
        .read<NotificationsNotifier>()
        .loadMore(_token!, _userId!);
  }

  int _total(List<NotificationItem> all) => all.length;
  int _unread(List<NotificationItem> all) => all.where((n) => !n.isRead).length;
  int _approvals(List<NotificationItem> all) => all
      .where((n) => n.type.contains('approved') || n.type == 'approval')
      .length;
  int _rejections(List<NotificationItem> all) =>
      all.where((n) => n.type.contains('rejected')).length;
  int _tasks(List<NotificationItem> all) => all
      .where((n) => n.type.startsWith('task_') || n.type == 'task_assigned')
      .length;

  List<NotificationItem> _filtered(
    List<NotificationItem> all,
    String selectedTab,
  ) {
    final baseline = _role == 'client'
        ? all.where((n) => n.type == 'chat').toList()
        : all;

    switch (selectedTab) {
      case 'unread':
        return baseline.where((n) => !n.isRead).toList();
      case 'announcement':
        return baseline.where((n) => n.type == 'announcement').toList();
      case 'chat':
        return baseline.where((n) => n.type == 'chat').toList();
      case 'leave':
        return baseline
            .where((n) => n.type == 'leave' || n.type.startsWith('leave_'))
            .toList();
      case 'expense':
        return baseline
            .where((n) => n.type == 'expense' || n.type.startsWith('expense_'))
            .toList();
      case 'attendance':
        return baseline
            .where(
              (n) => n.type == 'attendance' || n.type.startsWith('attendance_'),
            )
            .toList();
      case 'task':
        return baseline
            .where(
              (n) => n.type.startsWith('task_') || n.type == 'task_assigned',
            )
            .toList();
      case 'payroll':
        return baseline.where((n) => n.type == 'payroll').toList();
      default:
        return baseline;
    }
  }

  String _listHeader(String selectedTab) => switch (selectedTab) {
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

  bool _isBackend(NotificationItem n) {
    return (n.metadata?['source'] as String?) != 'local';
  }

  Future<void> _markRead(
    NotificationsNotifier notifier,
    NotificationItem n,
  ) async {
    if (n.isRead || _token == null) return;
    await notifier.markAsRead(_token!, n.id, userId: _userId);
  }

  Future<void> _markAllRead(NotificationsNotifier notifier) async {
    if (_token == null) return;
    await notifier.markAllAsRead(_token!, userId: _userId);
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
    final notifier = context.watch<NotificationsNotifier>();
    final state = notifier.state;
    final selectedTab = state.selectedTab;
    final all = state.notifications;
    final unread = _unread(all);
    final filtered = _filtered(all, selectedTab);
    // Role-aware tabs list (compute once at build-time)
    final tabs = _role == 'client' ? _clientTabs : _tabs;
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
              state.isLoading
                  ? 'Loading...'
                  : unread > 0
                  ? '$unread unread notification${unread > 1 ? 's' : ''}'
                  : 'All caught up!',
              style: TextStyle(
                color: AppTheme.onSurface.withValues(alpha: 0.6),
                fontSize: _subtitleFontSize,
              ),
            ),
          ],
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => _markAllRead(notifier),
              child: const Text(
                'Mark All Read',
                style: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => _initAndLoad(force: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 2.5,
              ),
            )
          : state.errorMessage != null
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
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.errorColor),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _initAndLoad(force: true),
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
              onRefresh: () => _initAndLoad(force: true),
              color: AppTheme.primaryColor,
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: _horizontalPadding,
                  vertical: 12,
                ),
                children: <Widget>[
                  // Role + source badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (state.usingBackend)
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
                                    _total(all),
                                    AppTheme.primaryColor,
                                  ),
                                  _statCard(
                                    Icons.mark_email_unread_outlined,
                                    'Unread',
                                    unread,
                                    const Color(0xFF4ADE80),
                                  ),
                                  if (_role != 'client') ...[
                                    _statCard(
                                      Icons.check_circle_outline,
                                      'Approvals',
                                      _approvals(all),
                                      Colors.tealAccent,
                                    ),
                                    _statCard(
                                      Icons.cancel_outlined,
                                      'Rejections',
                                      _rejections(all),
                                      Colors.redAccent,
                                    ),
                                    _statCard(
                                      Icons.assignment_outlined,
                                      'Tasks',
                                      _tasks(all),
                                      const Color(0xFFFB923C),
                                    ),
                                  ],
                                ],
                              ),
                            ]
                          : [
                              _statCard(
                                Icons.notifications_outlined,
                                'Total',
                                _total(all),
                                AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 10),
                              _statCard(
                                Icons.mark_email_unread_outlined,
                                'Unread',
                                unread,
                                const Color(0xFF4ADE80),
                              ),
                              if (_role != 'client') ...[
                                const SizedBox(width: 10),
                                _statCard(
                                  Icons.check_circle_outline,
                                  'Approvals',
                                  _approvals(all),
                                  Colors.tealAccent,
                                ),
                                const SizedBox(width: 10),
                                _statCard(
                                  Icons.cancel_outlined,
                                  'Rejections',
                                  _rejections(all),
                                  Colors.redAccent,
                                ),
                                const SizedBox(width: 10),
                                _statCard(
                                  Icons.assignment_outlined,
                                  'Tasks',
                                  _tasks(all),
                                  const Color(0xFFFB923C),
                                ),
                              ],
                            ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Filter tabs
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: tabs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final (key, label) = tabs[i];
                        final sel = key == selectedTab;
                        return GestureDetector(
                          onTap: () => notifier.selectTab(key),
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
                              key == 'unread' ? 'Unread ($unread)' : label,
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
                    '${_listHeader(selectedTab)} (${filtered.length})',
                    style: TextStyle(
                      color: AppTheme.onSurface.withValues(alpha: 0.6),
                      fontSize: _bodyFontSize,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (filtered.isEmpty) _buildEmpty(),
                  ...filtered.map(_buildTile),

                  // Load more
                  if (state.hasMore && state.usingBackend && selectedTab == 'all')
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: state.isLoadingMore
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

  Widget _buildTile(NotificationItem n) {
    final cfg = _cfgFor(n.type);
    return GestureDetector(
      onTap: () async {
        await _markRead(context.read<NotificationsNotifier>(), n);
        if (n.type == 'announcement' && mounted && _token != null) {
          final annId = _isBackend(n) ? n.id : n.id.replaceFirst('ann_', '');
          try {
            final ann = await context.read<NotificationsNotifier>().getAnnouncementById(
              _token!,
              annId,
            );
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
          color: n.isRead
              ? AppTheme.surfaceVariant.withValues(alpha: 0.5)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: n.isRead
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
                            color: n.isRead
                                ? AppTheme.onSurface.withValues(alpha: 0.7)
                                : AppTheme.onSurface,
                            fontSize: _isTablet ? 14 : 13,
                            fontWeight: n.isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!n.isRead)
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
                        _timeAgo(n.createdAt),
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
