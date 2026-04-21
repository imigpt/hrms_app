import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:hrms_app/features/announcements/data/models/announcement_model.dart';
import 'package:hrms_app/features/announcements/data/services/announcement_service.dart';
import 'package:hrms_app/features/attendance/data/services/attendance_service.dart';
import 'package:hrms_app/features/chat/data/services/chat_service.dart';
import 'package:hrms_app/features/expenses/data/services/expense_service.dart';
import 'package:hrms_app/features/leave/data/services/leave_service.dart';
import 'package:hrms_app/features/notifications/data/services/api_notification_service.dart';
import 'package:hrms_app/features/tasks/data/services/task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Notification State (Equatable for immutability)
// ═══════════════════════════════════════════════════════════════════════════

class NotificationState extends Equatable {
  static const Object _unset = Object();

  final List<NotificationItem> notifications;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSaving;
  final String selectedTab; // 'all', 'unread', 'announcement', etc.
  final int currentPage;
  final bool hasMore;
  final String? errorMessage;
  final int unreadCount;
  final bool usingBackend;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSaving = false,
    this.selectedTab = 'all',
    this.currentPage = 1,
    this.hasMore = false,
    this.errorMessage,
    this.unreadCount = 0,
    this.usingBackend = true,
  });

  /// Immutable state copy with optional property updates
  NotificationState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSaving,
    String? selectedTab,
    int? currentPage,
    bool? hasMore,
    Object? errorMessage = _unset,
    int? unreadCount,
    bool? usingBackend,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSaving: isSaving ?? this.isSaving,
      selectedTab: selectedTab ?? this.selectedTab,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      unreadCount: unreadCount ?? this.unreadCount,
      usingBackend: usingBackend ?? this.usingBackend,
    );
  }

  @override
  List<Object?> get props => [
    notifications,
    isLoading,
    isLoadingMore,
    isSaving,
    selectedTab,
    currentPage,
    hasMore,
    errorMessage,
    unreadCount,
    usingBackend,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// Notifications Notifier (ChangeNotifier for Provider)
// ═══════════════════════════════════════════════════════════════════════════

class NotificationsNotifier extends ChangeNotifier {
  static const String _readNotificationsKeyPrefix = 'notif_read_ids_';

  final Future<List<NotificationItem>> Function(
    String token,
    String userId,
    String role,
  )? _fallbackProvider;
  NotificationState _state = const NotificationState();

  NotificationsNotifier({
    Future<List<NotificationItem>> Function(
      String token,
      String userId,
      String role,
    )?
        fallbackProvider,
  }) : _fallbackProvider = fallbackProvider;

  NotificationState get state => _state;

  String _storageKey(String userId) => '$_readNotificationsKeyPrefix$userId';

  NotificationItem _withSource(NotificationItem item, String source) {
    final metadata = <String, dynamic>{...(item.metadata ?? {})};
    metadata['source'] = source;
    return NotificationItem(
      id: item.id,
      userId: item.userId,
      title: item.title,
      message: item.message,
      type: item.type,
      referenceId: item.referenceId,
      isRead: item.isRead,
      readAt: item.readAt,
      metadata: metadata,
      pushSent: item.pushSent,
      createdAt: item.createdAt,
    );
  }

  void _setState(NotificationState newState) {
    _state = newState;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Load Notifications
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadNotifications(
    String token, {
    required String userId,
    required String role,
    bool preferFallback = false,
  }) async {
    debugPrint('📧 NotificationsNotifier: Loading notifications...');
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      if (preferFallback) {
        await _loadFromServices(token, userId, role);
        return;
      }
      final readIds = await getLocalReadIds(userId);

      // Try backend API first
      final response = await ApiNotificationService.getNotifications(
        authToken: token,
        userId: userId,
        page: 1,
        limit: 20,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Notification service timeout');
        },
      );

      debugPrint('✅ Backend notifications loaded: ${response.items.length}');

      final items = response.items.map((item) {
        final updated = _withSource(item, 'backend');
        if (readIds.contains(updated.id)) {
          updated.isRead = true;
        }
        return updated;
      }).toList();

      _setState(_state.copyWith(
        notifications: items,
        currentPage: 1,
        hasMore: response.pagination.hasMore,
        isLoading: false,
        usingBackend: true,
        unreadCount: _countUnread(items),
      ));

      // Fetch unread count
      await _getUnreadCount(token, userId);
    } catch (e) {
      debugPrint('⚠️ Backend failed, using fallback aggregation: $e');
      // Fall back to aggregating from various services
      await _loadFromServices(token, userId, role);
    }
  }

  /// Load more notifications (pagination)
  Future<void> loadMore(String token, String userId) async {
    if (_state.isLoadingMore || !_state.hasMore) return;

    debugPrint('📧 NotificationsNotifier: Loading more notifications...');
    _setState(_state.copyWith(isLoadingMore: true));

    try {
      final nextPage = _state.currentPage + 1;
      final response = await ApiNotificationService.getNotifications(
        authToken: token,
        userId: userId,
        page: nextPage,
        limit: 20,
      );

      final readIds = await getLocalReadIds(userId);
      final newItems = response.items.map((item) {
        final updated = _withSource(item, 'backend');
        if (readIds.contains(updated.id)) {
          updated.isRead = true;
        }
        return updated;
      }).toList();

      final updatedNotifications = [..._state.notifications, ...newItems];

      _setState(_state.copyWith(
        notifications: updatedNotifications,
        currentPage: nextPage,
        hasMore: response.pagination.hasMore,
        isLoadingMore: false,
        unreadCount: _countUnread(updatedNotifications),
      ));

      debugPrint('✅ More notifications loaded: ${newItems.length}');
    } catch (e) {
      debugPrint('❌ Error loading more: $e');
      _setState(_state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Failed to load more',
      ));
    }
  }

  /// Fallback: Show error when backend is unavailable
  Future<void> _loadFromServices(
    String token,
    String userId,
    String role,
  ) async {
    debugPrint('⚠️ Backend notification API unavailable, aggregating data');
    if (_fallbackProvider != null) {
      final items = await _fallbackProvider(token, userId, role);
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _setState(_state.copyWith(
        isLoading: false,
        usingBackend: false,
        notifications: items,
        currentPage: 1,
        hasMore: false,
        unreadCount: _countUnread(items),
        errorMessage: null,
      ));
      return;
    }
    final readIds = await getLocalReadIds(userId);
    bool isRead(String id) => readIds.contains(id);
    final List<NotificationItem> result = [];

    try {
      final res = await AnnouncementService.getAnnouncements(token: token);
      for (final a in res.data.take(5)) {
        final id = 'ann_${a.id}';
        result.add(
          NotificationItem(
            id: id,
            userId: userId,
            title: 'New Announcement',
            message: a.title,
            type: 'announcement',
            isRead: isRead(id),
            createdAt: a.createdAt,
            metadata: const {'source': 'local'},
          ),
        );
      }
    } catch (_) {}

    try {
      final res = await ChatService.getUnreadCount(token: token);
      if (res.count > 0) {
        const id = 'chat_unread_bulk';
        result.add(
          NotificationItem(
            id: id,
            userId: userId,
            title: 'Unread Messages',
            message:
                'You have ${res.count} unread message${res.count > 1 ? 's' : ''}',
            type: 'chat',
            isRead: isRead(id),
            createdAt: DateTime.now(),
            metadata: const {'source': 'local'},
          ),
        );
      }
    } catch (_) {}

    if (role == 'employee' || role == 'hr' || role == 'admin') {
      try {
        final res = await LeaveService.getMyLeaves(token: token);
        final allLeaves = (res['data'] as List<dynamic>? ?? []);
        final filtered = allLeaves.where(
          (l) => l['status'] == 'approved' || l['status'] == 'rejected',
        );
        for (final l in filtered.take(5)) {
          final status = l['status'] as String? ?? 'approved';
          final id = 'leave_${l['_id'] ?? l['id']}_$status';
          result.add(
            NotificationItem(
              id: id,
              userId: userId,
              title: status == 'approved' ? 'Leave Approved' : 'Leave Rejected',
              message:
                  'Your ${l['leaveType'] ?? 'leave'} (${_fmtDate(l['startDate'])}) was $status',
              type: status == 'approved' ? 'leave_approved' : 'leave_rejected',
              isRead: isRead(id),
              createdAt: _parseDate(l['updatedAt'] ?? l['createdAt']),
              metadata: const {'source': 'local'},
            ),
          );
        }
      } catch (_) {}

      try {
        final res = await ExpenseService.getExpenses(token: token);
        for (final e in res.data
            .where((e) => e.status == 'approved' || e.status == 'rejected')
            .take(5)) {
          final id = 'exp_${e.id}_${e.status}';
          result.add(
            NotificationItem(
              id: id,
              userId: userId,
              title: e.status == 'approved'
                  ? 'Expense Approved'
                  : 'Expense Rejected',
              message: 'Your expense "${e.category}" was ${e.status}',
              type: e.status == 'approved'
                  ? 'expense_approved'
                  : 'expense_rejected',
              isRead: isRead(id),
              createdAt: e.updatedAt,
              metadata: const {'source': 'local'},
            ),
          );
        }
      } catch (_) {}

      try {
        final res = await AttendanceService.getEditRequests(token: token);
        for (final r in res.data
            .where((r) => r.status == 'approved' || r.status == 'rejected')
            .take(5)) {
          final id = 'attedit_${r.id}_${r.status}';
          result.add(
            NotificationItem(
              id: id,
              userId: userId,
              title: r.status == 'approved'
                  ? 'Attendance Approved'
                  : 'Attendance Rejected',
              message: 'Your attendance correction was ${r.status}',
              type: r.status == 'approved'
                  ? 'attendance_edit_approved'
                  : 'attendance_edit_rejected',
              isRead: isRead(id),
              createdAt: r.updatedAt,
              metadata: const {'source': 'local'},
            ),
          );
        }
      } catch (_) {}
    }

    if (role == 'hr' || role == 'admin') {
      try {
        final res = await LeaveService.getAdminLeaves(
          token: token,
          status: 'pending',
        );
        for (final l in res.data.take(3)) {
          final id = 'pending_leave_${l.id}';
          result.add(
            NotificationItem(
              id: id,
              userId: userId,
              title: 'Leave Request Pending',
              message:
                  '${l.user?.name ?? 'An employee'} requested ${l.leaveType} — awaiting review',
              type: 'leave_pending',
              isRead: isRead(id),
              createdAt: l.createdAt,
              metadata: const {'source': 'local'},
            ),
          );
        }
      } catch (_) {}

      try {
        final res = await AttendanceService.getPendingAdminEditRequests(
          token: token,
        );
        for (final r in res.data.take(3)) {
          final id = 'pending_edit_${r.id}';
          result.add(
            NotificationItem(
              id: id,
              userId: userId,
              title: 'Attendance Edit Request',
              message:
                  '${r.employee?.name ?? 'An employee'} requested attendance correction',
              type: 'attendance_edit_pending',
              isRead: isRead(id),
              createdAt: r.createdAt,
              metadata: const {'source': 'local'},
            ),
          );
        }
      } catch (_) {}
    }

    try {
      final res = await TaskService.getTasks(token);
      final tasks =
          (res['tasks'] ?? res['data']?['tasks'] ?? []) as List<dynamic>;
      for (final t in tasks.take(5)) {
        final id = 'task_assigned_${t['_id'] ?? t['id']}';
        result.add(
          NotificationItem(
            id: id,
            userId: userId,
            title: 'New Task Assigned',
            message:
                '"${t['title']}" — Priority: ${t['priority'] ?? 'N/A'}, Due: ${_fmtDate(t['dueDate'])}',
            type: 'task_assigned',
            isRead: isRead(id),
            createdAt: _parseDate(t['createdAt'] ?? t['createdDate']),
            metadata: const {'source': 'local'},
          ),
        );
      }

      if (role == 'employee') {
        for (final t in tasks
            .where((t) => t['review']?['comment'] != null)
            .take(5)) {
          final id = 'task_reviewed_${t['_id'] ?? t['id']}';
          result.add(
            NotificationItem(
              id: id,
              userId: userId,
              title: 'Task Reviewed',
              message:
                  'Your task "${t['title']}" received a review${t['review']['rating'] != null ? ' (${t['review']['rating']}/5)' : ''}',
              type: 'task_reviewed',
              isRead: isRead(id),
              createdAt: _parseDate(t['review']['reviewedAt'] ?? t['updatedAt']),
              metadata: const {'source': 'local'},
            ),
          );
        }
      }

      for (final t in tasks
          .where(
            (t) => (t['progress'] ?? 0) > 0 && t['status'] != 'completed',
          )
          .take(5)) {
        final id = 'task_progress_${t['_id'] ?? t['id']}_${t['progress']}';
        result.add(
          NotificationItem(
            id: id,
            userId: userId,
            title: 'Task Progress Updated',
            message:
                '"${t['title']}" — ${t['assignedTo']?['name'] ?? 'Employee'} updated progress to ${t['progress']}%',
            type: 'task_progress',
            isRead: isRead(id),
            createdAt: _parseDate(t['updatedAt']),
            metadata: const {'source': 'local'},
          ),
        );
      }
    } catch (_) {}

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _setState(_state.copyWith(
      isLoading: false,
      usingBackend: false,
      notifications: result,
      currentPage: 1,
      hasMore: false,
      unreadCount: _countUnread(result),
      errorMessage: null,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mark as Read
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> markAsRead(
    String token,
    String id, {
    String? userId,
  }) async {
    debugPrint('✓ Marking notification $id as read');
    _setState(_state.copyWith(isSaving: true));

    NotificationItem? item;
    for (final n in _state.notifications) {
      if (n.id == id) {
        item = n;
        break;
      }
    }

    if (item == null) {
      _setState(_state.copyWith(isSaving: false));
      return;
    }

    try {
      final source = (item.metadata?['source'] as String?) ??
          (_state.usingBackend ? 'backend' : 'local');
      if (source == 'backend') {
        await ApiNotificationService.markAsRead(
          authToken: token,
          notificationId: id,
        );
      } else if (item.type == 'announcement') {
        final annId = id.replaceFirst('ann_', '');
        await AnnouncementService.markAsRead(
          token: token,
          announcementId: annId,
        );
      }

      // Update local list
      final updated = _state.notifications.map((n) {
        if (n.id == id) {
          return n..isRead = true;
        }
        return n;
      }).toList();

      _setState(_state.copyWith(
        notifications: updated,
        unreadCount: _countUnread(updated),
        isSaving: false,
      ));

      // Persist locally
      if (userId != null && userId.isNotEmpty) {
        await _persistReadId(userId, id);
      }
    } catch (e) {
      debugPrint('❌ Mark as read error: $e');
      _setState(_state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to mark as read',
      ));
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String token, {String? userId}) async {
    debugPrint('✓ Marking all as read');
    _setState(_state.copyWith(isSaving: true));

    try {
      if (userId != null) {
        if (_state.usingBackend) {
          await ApiNotificationService.markAllAsRead(
            authToken: token,
            userId: userId,
          );
        } else {
          for (final n in _state.notifications
              .where((n) => n.type == 'announcement')) {
            final annId = n.id.replaceFirst('ann_', '');
            await AnnouncementService.markAsRead(
              token: token,
              announcementId: annId,
            );
          }
        }
      }

      // Update local list
      final updated = _state.notifications.map((n) {
        final notif = n;
        notif.isRead = true;
        return notif;
      }).toList();

      _setState(_state.copyWith(
        notifications: updated,
        unreadCount: 0,
        isSaving: false,
      ));

      debugPrint('✅ All marked as read');
    } catch (e) {
      debugPrint('❌ Mark all as read error: $e');
      _setState(_state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to mark all as read',
      ));
    }
  }

  void setError(String message) {
    _setState(_state.copyWith(isLoading: false, errorMessage: message));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Unread Count
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _getUnreadCount(String token, String userId) async {
    try {
      final count = await ApiNotificationService.getUnreadCount(
        authToken: token,
        userId: userId,
      );
      _setState(_state.copyWith(unreadCount: count));
      debugPrint('📊 Unread count: $count');
    } catch (e) {
      debugPrint('⚠️ Failed to fetch unread count: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab Selection
  // ─────────────────────────────────────────────────────────────────────────

  void selectTab(String tabName) {
    debugPrint('📑 Selecting tab: $tabName');
    _setState(_state.copyWith(selectedTab: tabName));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Error Handling
  // ─────────────────────────────────────────────────────────────────────────

  void clearError() {
    _setState(_state.copyWith(errorMessage: null));
  }

  Future<Announcement?> getAnnouncementById(String token, String id) async {
    try {
      return await AnnouncementService.getAnnouncementById(
        token: token,
        announcementId: id,
      );
    } catch (e) {
      debugPrint('❌ Announcement detail fetch error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Local Persistence (SharedPreferences)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _persistReadId(String userId, String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList(_storageKey(userId)) ?? [];
      if (!readIds.contains(notificationId)) {
        readIds.add(notificationId);
        await prefs.setStringList(_storageKey(userId), readIds);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to persist read notification: $e');
    }
  }

  Future<Set<String>> getLocalReadIds(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList(_storageKey(userId)) ?? [];
      return readIds.toSet();
    } catch (e) {
      debugPrint('⚠️ Failed to load read notifications: $e');
      return {};
    }
  }

  int _countUnread(List<NotificationItem> items) {
    return items.where((n) => !n.isRead).length;
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
}
