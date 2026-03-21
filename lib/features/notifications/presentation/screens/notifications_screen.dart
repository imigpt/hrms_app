import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/features/notifications/data/services/api_notification_service.dart';
import 'package:hrms_app/features/notifications/presentation/providers/notifications_notifier.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';

// Type configuration for notification types
class _TypeCfg {
  final String label;
  final IconData icon;
  final Color color;
  const _TypeCfg(this.label, this.icon, this.color);
}

const Map<String, _TypeCfg> _typeConfig = {
  'announcement': _TypeCfg('Announcement', Icons.campaign_outlined, AppTheme.primaryColor),
  'chat': _TypeCfg('Chat', Icons.message_outlined, Color(0xFF60A5FA)),
  'leave': _TypeCfg('Leave', Icons.calendar_today_outlined, Colors.orange),
  'expense': _TypeCfg('Expense', Icons.receipt_outlined, Colors.orange),
  'attendance': _TypeCfg('Attendance', Icons.fingerprint_outlined, Colors.orange),
  'payroll': _TypeCfg('Payroll', Icons.payments_outlined, AppTheme.primaryColor),
  'task_assigned': _TypeCfg('Task Assigned', Icons.assignment_outlined, Color(0xFFFB923C)),
  'task_updated': _TypeCfg('Task Updated', Icons.update_outlined, Color(0xFF60A5FA)),
  'task_comment': _TypeCfg('Task Comment', Icons.comment_outlined, Color(0xFF60A5FA)),
  'approval': _TypeCfg('Approval', Icons.approval_outlined, Colors.tealAccent),
  'general': _TypeCfg('General', Icons.notifications_outlined, AppTheme.primaryColor),
  'leave_approved': _TypeCfg('Leave Approved', Icons.check_circle_outline, Colors.green),
  'leave_rejected': _TypeCfg('Leave Rejected', Icons.cancel_outlined, Colors.red),
  'leave_pending': _TypeCfg('Leave Pending', Icons.calendar_today_outlined, Colors.orange),
  'expense_approved': _TypeCfg('Expense Approved', Icons.check_circle_outline, Colors.green),
  'expense_rejected': _TypeCfg('Expense Rejected', Icons.cancel_outlined, Colors.red),
  'expense_pending': _TypeCfg('Expense Pending', Icons.receipt_outlined, Colors.orange),
  'attendance_edit_approved': _TypeCfg('Att. Approved', Icons.check_circle_outline, Colors.green),
  'attendance_edit_rejected': _TypeCfg('Att. Rejected', Icons.cancel_outlined, Colors.red),
  'attendance_edit_pending': _TypeCfg('Att. Pending', Icons.edit_note_outlined, Colors.orange),
  'task_progress': _TypeCfg('Task Progress', Icons.trending_up_rounded, Color(0xFF60A5FA)),
  'task_reviewed': _TypeCfg('Task Reviewed', Icons.star_outline_rounded, Color(0xFFFACC15)),
};

_TypeCfg _cfgFor(String type) =>
    _typeConfig[type] ??
    const _TypeCfg('Notification', Icons.notifications_outlined, AppTheme.primaryColor);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _token;
  String? _userId;
  String _userRole = 'employee';
  String _selectedTab = 'all';

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

  static const _clientTabs = [
    ('all', 'All'),
    ('unread', 'Unread'),
    ('chat', 'Chat'),
  ];

  // Responsive helpers
  bool get _isTablet => MediaQuery.of(context).size.width >= 600;
  double get _horizontalPadding => _isTablet ? 24 : 16;
  double get _statCardWidth => _isTablet ? 140 : 120;
  double get _statCardHeight => _isTablet ? 96 : 84;
  double get _titleFontSize => _isTablet ? 20 : 18;
  double get _subtitleFontSize => _isTablet ? 13 : 11;
  double get _bodyFontSize => _isTablet ? 14 : 12;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    try {
      final storage = TokenStorageService();
      _token = await storage.getToken();
      _userId = await storage.getUserId();
      _userRole = (await storage.getUserRole()) ?? 'employee';

      if (mounted && _token != null && _userId != null) {
        debugPrint('📧 NotificationsScreen: Loading notifications...');
        final notifier = context.read<NotificationsNotifier>();
        await notifier.loadNotifications(
          _token!,
          userId: _userId!,
          role: _userRole,
        );
      }
    } catch (e) {
      debugPrint('❌ Initialization error: $e');
    }
  }

  List<NotificationItem> _getFilteredNotifications(
    List<NotificationItem> notifications,
  ) {
    final baseline = _userRole == 'client'
        ? notifications.where((n) => n.type == 'chat').toList()
        : notifications;

    switch (_selectedTab) {
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
            .where((n) => n.type == 'attendance' || n.type.startsWith('attendance_'))
            .toList();
      case 'task':
        return baseline
            .where((n) => n.type.startsWith('task_') || n.type == 'task_assigned')
            .toList();
      case 'payroll':
        return baseline.where((n) => n.type == 'payroll').toList();
      default:
        return baseline;
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _userRole == 'client' ? _clientTabs : _tabs;

    return Consumer<NotificationsNotifier>(
      builder: (context, notifier, _) {
        final state = notifier.state;
        final filteredNotifications =
            _getFilteredNotifications(state.notifications);

        // Calculate stats
        final total = state.notifications.length;
        final unread = state.notifications.where((n) => !n.isRead).length;
        final approvals = state.notifications
            .where((n) => n.type.contains('approved') || n.type == 'approval')
            .length;
        final rejections =
            state.notifications.where((n) => n.type.contains('rejected')).length;
        final taskNotifs = state.notifications
            .where((n) =>
                n.type.startsWith('task_') || n.type == 'task_assigned')
            .length;

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
              if (unread > 0 && _token != null)
                TextButton(
                  onPressed: () => notifier.markAllAsRead(_token!, userId: _userId),
                  child: const Text(
                    'Mark All Read',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: () {
                  if (_token != null && _userId != null) {
                    notifier.loadNotifications(
                      _token!,
                      userId: _userId!,
                      role: _userRole,
                    );
                  }
                },
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
                              style:
                                  const TextStyle(color: AppTheme.errorColor),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (_token != null && _userId != null) {
                                  notifier.loadNotifications(
                                    _token!,
                                    userId: _userId!,
                                    role: _userRole,
                                  );
                                }
                              },
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
                      onRefresh: () async {
                        if (_token != null && _userId != null) {
                          await notifier.loadNotifications(
                            _token!,
                            userId: _userId!,
                            role: _userRole,
                          );
                        }
                      },
                      color: AppTheme.primaryColor,
                      child: filteredNotifications.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.all(32),
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.notifications_none_outlined,
                                        size: 64,
                                        color: AppTheme.onSurface
                                            .withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No notifications',
                                        style: TextStyle(
                                          fontSize: _bodyFontSize,
                                          color: AppTheme.onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: _horizontalPadding,
                                vertical: 12,
                              ),
                              itemCount: filteredNotifications.length + 2,
                              itemBuilder: (context, index) {
                                // Stats section at top
                                if (index == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _buildStatCard(
                                            'Total',
                                            total.toString(),
                                            Icons.notifications_active_outlined,
                                            AppTheme.primaryColor,
                                          ),
                                          const SizedBox(width: 12),
                                          _buildStatCard(
                                            'Unread',
                                            unread.toString(),
                                            Icons.mark_email_unread_outlined,
                                            Colors.blue,
                                          ),
                                          const SizedBox(width: 12),
                                          _buildStatCard(
                                            'Approved',
                                            approvals.toString(),
                                            Icons.check_circle_outline,
                                            Colors.green,
                                          ),
                                          const SizedBox(width: 12),
                                          _buildStatCard(
                                            'Rejected',
                                            rejections.toString(),
                                            Icons.cancel_outlined,
                                            Colors.red,
                                          ),
                                          const SizedBox(width: 12),
                                          _buildStatCard(
                                            'Tasks',
                                            taskNotifs.toString(),
                                            Icons.assignment_outlined,
                                            Color(0xFFFB923C),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                // Tab filter buttons
                                if (index == 1) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: tabs
                                            .map((tab) => Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 4),
                                                  child: FilterChip(
                                                    label: Text(tab.$2),
                                                    selected:
                                                        _selectedTab ==
                                                            tab.$1,
                                                    onSelected: (_) {
                                                      setState(() =>
                                                          _selectedTab =
                                                              tab.$1);
                                                    },
                                                    backgroundColor:
                                                        AppTheme.surface,
                                                    selectedColor: AppTheme
                                                        .primaryColor
                                                        .withValues(
                                                          alpha: 0.2,
                                                        ),
                                                    labelStyle: TextStyle(
                                                      color: _selectedTab ==
                                                              tab.$1
                                                          ? AppTheme
                                                              .primaryColor
                                                          : AppTheme
                                                              .onSurface,
                                                      fontSize: _bodyFontSize,
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  );
                                }

                                // Notifications list
                                final notifIndex = index - 2;
                                if (notifIndex >=
                                    filteredNotifications.length) {
                                  return const SizedBox.shrink();
                                }

                                final notif =
                                    filteredNotifications[notifIndex];
                                return _buildNotificationTile(
                                  notif,
                                  notifier,
                                );
                              },
                            ),
                    ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: _statCardWidth,
      height: _statCardHeight,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(
          color: AppTheme.onSurface.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: _titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: _subtitleFontSize,
              color: AppTheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    NotificationItem notification,
    NotificationsNotifier notifier,
  ) {
    final cfg = _cfgFor(notification.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead && _token != null) {
            notifier.markAsRead(_token!, notification.id);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: notification.isRead
                ? AppTheme.surface
                : AppTheme.primaryColor.withValues(alpha: 0.08),
            border: Border.all(
              color: notification.isRead
                  ? AppTheme.onSurface.withValues(alpha: 0.1)
                  : AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cfg.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    cfg.icon,
                    color: cfg.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: _bodyFontSize,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: _bodyFontSize - 2,
                          color: AppTheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _timeAgo(notification.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
