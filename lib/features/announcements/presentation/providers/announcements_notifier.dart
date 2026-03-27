import 'package:flutter/foundation.dart';
import 'package:hrms_app/features/announcements/data/models/announcement_model.dart';
import 'package:hrms_app/features/announcements/data/services/announcement_service.dart';
import 'announcements_state.dart';

class AnnouncementsNotifier extends ChangeNotifier {
  final AnnouncementService _announcementService;
  AnnouncementsState _state = const AnnouncementsState();

  AnnouncementsNotifier({required AnnouncementService announcementService})
      : _announcementService = announcementService;

  AnnouncementsState get state => _state;

  // ── Private Helper ──────────────────────────────────────────────────────

  void _setState(AnnouncementsState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Apply current filters and search to announcements
  void _applyFilters() {
    var filtered = List<Announcement>.from(_state.announcements);

    // Apply priority filter
    if (_state.priorityFilter != null && _state.priorityFilter!.isNotEmpty) {
      filtered = filtered
          .where((a) =>
              a.priority?.toLowerCase() ==
              _state.priorityFilter!.toLowerCase())
          .toList();
    }

    // Apply department filter
    if (_state.departmentFilter != null &&
        _state.departmentFilter!.isNotEmpty) {
      filtered = filtered
          .where((a) =>
              a.targetDepartment?.toLowerCase() ==
              _state.departmentFilter!.toLowerCase())
          .toList();
    }

    // Apply search query
    if (_state.searchQuery.isNotEmpty) {
      filtered = filtered
          .where((a) =>
              (a.title ?? '')
                  .toLowerCase()
                  .contains(_state.searchQuery.toLowerCase()) ||
              (a.content ?? '')
                  .toLowerCase()
                  .contains(_state.searchQuery.toLowerCase()))
          .toList();
    }

    // Apply selected filter
    if (_state.selectedFilter == 'Unread') {
      filtered = filtered
          .where((a) => !_state.readAnnouncementIds.contains(a.id))
          .toList();
    }

    _setState(_state.copyWith(filteredAnnouncements: filtered));
  }

  // ── Load Data Methods ───────────────────────────────────────────────────

  /// Load all announcements
  Future<void> loadAnnouncements(
    String token, {
    String? priority,
    String? department,
  }) async {
    try {
      _setState(_state.copyWith(isLoading: true, error: null));

      final response = await _announcementService.getAnnouncements(
        token: token,
        priority: priority,
        department: department,
      );

      final announcements = response.data ?? [];

      _setState(_state.copyWith(
        announcements: announcements,
        isLoading: false,
      ));

      // Apply filters after loading
      _applyFilters();

      // Update unread count
      await _loadUnreadCount(token);
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
        isLoading: false,
      ));
    }
  }

  /// Load unread count
  Future<void> _loadUnreadCount(String token) async {
    try {
      final count = await _announcementService.getUnreadCount(token: token);
      _setState(_state.copyWith(unreadCount: count));
    } catch (e) {
      // Non-blocking error for unread count
      print('Error loading unread count: $e');
    }
  }

  /// Load specific announcement by ID
  Future<void> loadAnnouncementById(String token, String announcementId) async {
    try {
      _setState(_state.copyWith(error: null));

      final announcement = await _announcementService.getAnnouncementById(
        token: token,
        announcementId: announcementId,
      );

      _setState(_state.copyWith(selectedAnnouncement: announcement));
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
      rethrow;
    }
  }

  /// Refresh announcements
  Future<void> refresh(String token) async {
    try {
      _setState(_state.copyWith(isRefreshing: true, error: null));

      final response = await _announcementService.getAnnouncements(
        token: token,
        priority: _state.priorityFilter,
        department: _state.departmentFilter,
      );

      final announcements = response.data ?? [];

      _setState(_state.copyWith(
        announcements: announcements,
        isRefreshing: false,
      ));

      // Apply filters after refresh
      _applyFilters();

      // Update unread count
      await _loadUnreadCount(token);
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
        isRefreshing: false,
      ));
    }
  }

  // ── Filtering Methods ───────────────────────────────────────────────────

  /// Filter by priority
  void filterByPriority(String? priority) {
    _setState(_state.copyWith(priorityFilter: priority));
    _applyFilters();
  }

  /// Filter by department
  void filterByDepartment(String? department) {
    _setState(_state.copyWith(departmentFilter: department));
    _applyFilters();
  }

  /// Apply selected filter ('All', 'Unread', etc.)
  void setSelectedFilter(String filter) {
    _setState(_state.copyWith(selectedFilter: filter));
    _applyFilters();
  }

  /// Search announcements by title or content
  void searchAnnouncements(String query) {
    _setState(_state.copyWith(searchQuery: query));
    _applyFilters();
  }

  /// Clear all filters and search
  void clearFilters() {
    _setState(_state.copyWith(
      priorityFilter: null,
      departmentFilter: null,
      searchQuery: '',
      selectedFilter: 'All',
    ));
    _applyFilters();
  }

  // ── Announcement Management ─────────────────────────────────────────────

  /// Mark single announcement as read
  Future<void> markAsRead(String token, String announcementId) async {
    try {
      _setState(_state.copyWith(error: null));

      final success = await _announcementService.markAsRead(
        token: token,
        announcementId: announcementId,
      );

      if (success) {
        final updatedReadIds = Set<String>.from(_state.readAnnouncementIds);
        updatedReadIds.add(announcementId);

        _setState(_state.copyWith(readAnnouncementIds: updatedReadIds));

        // Reapply filters to update unread list
        _applyFilters();

        // Update unread count
        await _loadUnreadCount(token);
      }
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  /// Mark all announcements as read
  Future<void> markAllAsRead(String token) async {
    try {
      _setState(_state.copyWith(error: null));

      // Mark all unread announcements as read
      final unreadIds =
          _state.announcements
              .where((a) => !_state.readAnnouncementIds.contains(a.id))
              .map((a) => a.id)
              .toList();

      for (final id in unreadIds) {
        await _announcementService.markAsRead(
          token: token,
          announcementId: id,
        );
      }

      // Update read IDs
      final updatedReadIds = Set<String>.from(_state.readAnnouncementIds);
      updatedReadIds.addAll(unreadIds);

      _setState(_state.copyWith(readAnnouncementIds: updatedReadIds));

      // Reapply filters
      _applyFilters();

      // Update unread count
      await _loadUnreadCount(token);
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  /// Create new announcement (admin only)
  Future<void> createAnnouncement(
    String token, {
    required String title,
    required String content,
    required String priority,
    String? category,
    String? targetDepartment,
    DateTime? expiryDate,
  }) async {
    try {
      _setState(_state.copyWith(isCreating: true, error: null));

      await _announcementService.createAnnouncement(
        token: token,
        title: title,
        content: content,
        priority: priority,
        category: category,
        targetDepartment: targetDepartment,
        expiryDate: expiryDate,
      );

      _setState(_state.copyWith(isCreating: false));

      // Reload announcements to show the new one
      await loadAnnouncements(token);
    } catch (e) {
      _setState(_state.copyWith(
        isCreating: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
      rethrow;
    }
  }

  // ── Notification & Read Tracking ────────────────────────────────────────

  /// Mark announcement as notified (already shown in notification)
  void markAsNotified(String announcementId) {
    final updatedNotified = Set<String>.from(_state.notifiedAnnouncementIds);
    updatedNotified.add(announcementId);
    _setState(_state.copyWith(notifiedAnnouncementIds: updatedNotified));
  }

  /// Check if announcement was already notified
  bool isNotified(String announcementId) {
    return _state.notifiedAnnouncementIds.contains(announcementId);
  }

  /// Update read IDs from shared preferences (during initialization)
  void setReadIds(Set<String> readIds) {
    _setState(_state.copyWith(readAnnouncementIds: readIds));
    _applyFilters();
  }

  /// Batch update read announcements from persistence
  void syncReadIds(Set<String> persistedReadIds) {
    _setState(_state.copyWith(readAnnouncementIds: persistedReadIds));
    _applyFilters();
  }

  // ── Selection & View Management ─────────────────────────────────────────

  /// Select announcement for detail view
  void selectAnnouncement(Announcement announcement) {
    _setState(_state.copyWith(selectedAnnouncement: announcement));
  }

  /// Deselect current announcement
  void deselectAnnouncement() {
    _setState(_state.copyWith(selectedAnnouncement: null));
  }

  // ── Statistics & Analytics ──────────────────────────────────────────────

  /// Get announcement count by priority
  Map<String, int> getPriorityStats() {
    return {
      'high': _state.announcements
          .where((a) => a.priority?.toLowerCase() == 'high')
          .length,
      'medium': _state.announcements
          .where((a) => a.priority?.toLowerCase() == 'medium')
          .length,
      'low': _state.announcements
          .where((a) => a.priority?.toLowerCase() == 'low')
          .length,
    };
  }

  /// Get announcement count by department
  Map<String, int> getDepartmentStats() {
    final stats = <String, int>{};
    for (final announcement in _state.announcements) {
      final dept = announcement.targetDepartment ?? 'General';
      stats[dept] = (stats[dept] ?? 0) + 1;
    }
    return stats;
  }

  /// Calculate read percentage
  double getReadPercentage() {
    if (_state.totalCount == 0) return 100.0;
    return (_state.readAnnouncementIds.length / _state.totalCount) * 100;
  }

  // ── Error & State Management ────────────────────────────────────────────

  /// Clear error message
  void clearError() {
    _setState(_state.copyWith(error: null));
  }

  /// Reset all state
  void reset() {
    _setState(const AnnouncementsState());
  }
}
