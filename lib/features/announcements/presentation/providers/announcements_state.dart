import 'package:equatable/equatable.dart';
import 'package:hrms_app/features/announcements/data/models/announcement_model.dart';

class AnnouncementsState extends Equatable {
  final List<Announcement> announcements;
  final List<Announcement> filteredAnnouncements;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final String selectedFilter;
  final String? priorityFilter;
  final String? departmentFilter;
  final String searchQuery;
  final Set<String> readAnnouncementIds;
  final Set<String> notifiedAnnouncementIds;
  final int unreadCount;
  final Announcement? selectedAnnouncement;
  final bool isCreating;

  const AnnouncementsState({
    this.announcements = const [],
    this.filteredAnnouncements = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.selectedFilter = 'All',
    this.priorityFilter,
    this.departmentFilter,
    this.searchQuery = '',
    this.readAnnouncementIds = const {},
    this.notifiedAnnouncementIds = const {},
    this.unreadCount = 0,
    this.selectedAnnouncement,
    this.isCreating = false,
  });

  // ── Computed Getters ─────────────────────────────────────────────────────

  /// Total number of announcements
  int get totalCount => announcements.length;

  /// Number of unread announcements
  int get totalUnread {
    return announcements
        .where((a) => !readAnnouncementIds.contains(a.id))
        .length;
  }

  /// Announcements grouped by priority
  List<Announcement> get highPriorityAnnouncements =>
      _filterByPriority('high');

  List<Announcement> get mediumPriorityAnnouncements =>
      _filterByPriority('medium');

  List<Announcement> get lowPriorityAnnouncements =>
      _filterByPriority('low');

  /// Recently added announcements (sorted by creation date)
  List<Announcement> get recentAnnouncements {
    final sorted = List<Announcement>.from(announcements);
    sorted.sort((a, b) {
      final dateA = DateTime.tryParse((a.createdAt ?? '') as String) ?? DateTime.now();
      final dateB = DateTime.tryParse((b.createdAt ?? '') as String) ?? DateTime.now();
      return dateB.compareTo(dateA);
    });
    return sorted;
  }

  /// Unread announcements list
  List<Announcement> get unreadAnnouncements =>
      announcements
          .where((a) => !readAnnouncementIds.contains(a.id))
          .toList();

  /// Check if there are any unread announcements
  bool get hasUnread => totalUnread > 0;

  /// Helper method to filter by priority
  List<Announcement> _filterByPriority(String priority) {
    return filteredAnnouncements
        .where((a) => a.priority?.toLowerCase() == priority.toLowerCase())
        .toList();
  }

  @override
  List<Object?> get props => [
    announcements,
    filteredAnnouncements,
    isLoading,
    isRefreshing,
    error,
    selectedFilter,
    priorityFilter,
    departmentFilter,
    searchQuery,
    readAnnouncementIds,
    notifiedAnnouncementIds,
    unreadCount,
    selectedAnnouncement,
    isCreating,
  ];

  AnnouncementsState copyWith({
    List<Announcement>? announcements,
    List<Announcement>? filteredAnnouncements,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    String? selectedFilter,
    String? priorityFilter,
    String? departmentFilter,
    String? searchQuery,
    Set<String>? readAnnouncementIds,
    Set<String>? notifiedAnnouncementIds,
    int? unreadCount,
    Announcement? selectedAnnouncement,
    bool? isCreating,
  }) {
    return AnnouncementsState(
      announcements: announcements ?? this.announcements,
      filteredAnnouncements: filteredAnnouncements ?? this.filteredAnnouncements,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error ?? this.error,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      priorityFilter: priorityFilter ?? this.priorityFilter,
      departmentFilter: departmentFilter ?? this.departmentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      readAnnouncementIds: readAnnouncementIds ?? this.readAnnouncementIds,
      notifiedAnnouncementIds: notifiedAnnouncementIds ?? this.notifiedAnnouncementIds,
      unreadCount: unreadCount ?? this.unreadCount,
      selectedAnnouncement: selectedAnnouncement ?? this.selectedAnnouncement,
      isCreating: isCreating ?? this.isCreating,
    );
  }
}
