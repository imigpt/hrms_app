import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:hrms_app/features/notifications/data/services/api_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Notification State (Equatable for immutability)
// ═══════════════════════════════════════════════════════════════════════════

class NotificationState extends Equatable {
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
    String? errorMessage,
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
      errorMessage: errorMessage ?? this.errorMessage,
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
  static const String _readNotificationsKey = 'read_notifications';

  final ApiNotificationService _service;
  NotificationState _state = const NotificationState();

  NotificationsNotifier(this._service);

  NotificationState get state => _state;

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
  }) async {
    debugPrint('📧 NotificationsNotifier: Loading notifications...');
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
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
      
      _setState(_state.copyWith(
        notifications: response.items,
        currentPage: 1,
        hasMore: response.pagination.hasMore,
        isLoading: false,
        usingBackend: true,
      ));

      // Fetch unread count
      await _getUnreadCount(token, userId);
    } catch (e) {
      debugPrint('⚠️ Backend failed, using fallback aggregation: $e');
      // Fall back to aggregating from various services
      await _loadFromServices(userId, role);
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

      final updatedNotifications = [..._state.notifications, ...response.items];

      _setState(_state.copyWith(
        notifications: updatedNotifications,
        currentPage: nextPage,
        hasMore: response.pagination.hasMore,
        isLoadingMore: false,
      ));

      debugPrint('✅ More notifications loaded: ${response.items.length}');
    } catch (e) {
      debugPrint('❌ Error loading more: $e');
      _setState(_state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Failed to load more',
      ));
    }
  }

  /// Fallback: Show error when backend is unavailable
  Future<void> _loadFromServices(String userId, String role) async {
    debugPrint('⚠️ Backend notification API unavailable, showing empty state');
    _setState(_state.copyWith(
      isLoading: false,
      usingBackend: false,
      notifications: [],
      errorMessage: 'Unable to load notifications. Please try again.',
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mark as Read
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> markAsRead(String token, String id) async {
    debugPrint('✓ Marking notification $id as read');
    _setState(_state.copyWith(isSaving: true));

    try {
      await ApiNotificationService.markAsRead(
        authToken: token,
        notificationId: id,
      );

      // Update local list
      final updated = _state.notifications.map((n) {
        if (n.id == id) {
          return n..isRead = true;
        }
        return n;
      }).toList();

      _setState(_state.copyWith(
        notifications: updated,
        isSaving: false,
      ));

      // Persist locally
      await _persistReadId(id);
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
        await ApiNotificationService.markAllAsRead(
          authToken: token,
          userId: userId,
        );
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

  // ─────────────────────────────────────────────────────────────────────────
  // Local Persistence (SharedPreferences)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _persistReadId(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList(_readNotificationsKey) ?? [];
      if (!readIds.contains(notificationId)) {
        readIds.add(notificationId);
        await prefs.setStringList(_readNotificationsKey, readIds);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to persist read notification: $e');
    }
  }

  Future<Set<String>> getLocalReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList(_readNotificationsKey) ?? [];
      return readIds.toSet();
    } catch (e) {
      debugPrint('⚠️ Failed to load read notifications: $e');
      return {};
    }
  }
}
