import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';
import '../services/token_storage_service.dart';
import 'announcement_detail_screen.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Announcement> _all = [];
  bool _isLoading = true;
  String? _error;
  String _selectedTab = 'All';
  String? _token;
  String? _userId;

  final List<String> _tabs = [
    'All',
    'Unread',
    'Announcements',
    'Chat',
    'Leave',
    'Expenses',
    'Attendance',
  ];

  // ── stats ────────────────────────────────────────────────────────────────
  int get _total => _all.length;
  int get _unread =>
      _all.where((a) => _userId != null && !a.readBy.contains(_userId)).length;
  int get _approvals => 0; // placeholder – no approval notifications yet
  int get _rejections => 0; // placeholder

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final storage = TokenStorageService();
      _token = await storage.getToken();
      _userId = await storage.getUserId();
      if (_token == null) throw Exception('Not authenticated');

      final res =
          await AnnouncementService.getAnnouncements(token: _token!);
      if (mounted) {
        setState(() {
          _all = res.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  List<Announcement> get _filtered {
    switch (_selectedTab) {
      case 'Unread':
        return _all
            .where(
                (a) => _userId != null && !a.readBy.contains(_userId))
            .toList();
      case 'Announcements':
        return _all; // all are announcements for now
      default:
        return _all;
    }
  }

  Future<void> _markRead(Announcement a) async {
    if (_token == null) return;
    await AnnouncementService.markAsRead(
        token: _token!, announcementId: a.id);
    setState(() {
      if (_userId != null && !a.readBy.contains(_userId)) {
        a.readBy.add(_userId);
      }
    });
  }

  // ─────────────────────────── BUILD ───────────────────────────────────────
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
        title: Row(
          children: [
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
          ],
        ),
        actions: [
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
                  color: AppTheme.primaryColor, strokeWidth: 2.5))
          : _error != null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor),
                          child: const Text('Retry')),
                    ],
                  ),
                ))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primaryColor,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    children: [
                      // ── Stat cards ──────────────────────────────────────
                      Row(
                        children: [
                          _statCard(Icons.notifications_outlined, 'Total',
                              _total, AppTheme.primaryColor),
                          const SizedBox(width: 10),
                          _statCard(Icons.mark_email_unread_outlined,
                              'Unread', _unread, Colors.greenAccent),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _statCard(Icons.check_circle_outline,
                              'Approvals', _approvals, Colors.tealAccent),
                          const SizedBox(width: 10),
                          _statCard(Icons.cancel_outlined, 'Rejections',
                              _rejections, Colors.redAccent),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Tab chips ───────────────────────────────────────
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _tabs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final t = _tabs[i];
                            final sel = t == _selectedTab;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedTab = t),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppTheme.primaryColor
                                      : Colors.white.withOpacity(0.06),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                    color: sel
                                        ? AppTheme.primaryColor
                                        : Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  t == 'Unread'
                                      ? 'Unread ($_unread)'
                                      : t,
                                  style: TextStyle(
                                    color: sel
                                        ? Colors.white
                                        : Colors.grey[400],
                                    fontSize: 12,
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

                      // ── List header ─────────────────────────────────────
                      Text(
                        'All Notifications (${_filtered.length})',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Items / Empty ───────────────────────────────────
                      if (_filtered.isEmpty) _buildEmpty(),
                      ..._filtered.map(_buildNotificationTile),
                    ],
                  ),
                ),
    );
  }

  // ─────────────────────────── Widgets ─────────────────────────────────────

  Widget _statCard(IconData icon, String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count',
                    style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.1)),
                Text(label,
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.notifications_off_outlined,
              color: Colors.grey[700], size: 48),
          const SizedBox(height: 12),
          Text('No notifications',
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(Announcement a) {
    final isRead =
        _userId != null && a.readBy.contains(_userId);
    final timeAgo = _formatTimeAgo(a.createdAt);
    final priorityColor = _priorityColor(a.priority);

    return GestureDetector(
      onTap: () {
        _markRead(a);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnnouncementDetailScreen(announcement: a),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white.withOpacity(0.03)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? Colors.white.withOpacity(0.05)
                : priorityColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority indicator dot
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _priorityIcon(a.priority),
                color: priorityColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          a.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight:
                                isRead ? FontWeight.w400 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
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
                    a.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          a.displayType,
                          style: TextStyle(
                              color: priorityColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time,
                          size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(timeAgo,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      default:
        return Colors.blueAccent;
    }
  }

  IconData _priorityIcon(String p) {
    switch (p.toLowerCase()) {
      case 'high':
        return Icons.warning_amber_rounded;
      case 'medium':
        return Icons.info_outline;
      default:
        return Icons.campaign_outlined;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}
