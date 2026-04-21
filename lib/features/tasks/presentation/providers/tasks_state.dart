import 'package:equatable/equatable.dart';

class TasksState extends Equatable {
  static const Object _unset = Object();

  final List<dynamic> tasks;
  final Map<String, dynamic> statistics;
  final List<dynamic> projects;
  final List<dynamic> employees;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final String? statusFilter;
  final String? priorityFilter;
  final String? employeeFilter;
  final String? projectFilter;
  final String searchQuery;
  final String? quickFilter;
  final dynamic selectedTask;
  final List<dynamic> timeLogs;
  final Map<String, dynamic>? runningTimer;
  final Map<String, dynamic>? analyticsData;
  final int selectedEmployeeTab;
  final int selectedAdminTab;

  const TasksState({
    this.tasks = const [],
    this.statistics = const {
      'total': 0,
      'assigned': 0,
      'todo': 0,
      'inProgress': 0,
      'completed': 0,
      'overdue': 0,
      'cancelled': 0,
      'pending': 0,
      'underReview': 0,
    },
    this.projects = const [],
    this.employees = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.statusFilter,
    this.priorityFilter,
    this.employeeFilter,
    this.projectFilter,
    this.searchQuery = '',
    this.quickFilter,
    this.selectedTask,
    this.timeLogs = const [],
    this.runningTimer,
    this.analyticsData,
    this.selectedEmployeeTab = 0,
    this.selectedAdminTab = 0,
  });

  // ── Computed Getters ─────────────────────────────────────────────────────

  /// Filtered tasks based on current filters
  List<dynamic> get filteredTasks {
    var filtered = List<dynamic>.from(tasks);

    // Apply status filter
    if (statusFilter != null && statusFilter!.isNotEmpty) {
      filtered = filtered
          .where((task) => task['status'] == statusFilter)
          .toList();
    }

    // Apply priority filter
    if (priorityFilter != null && priorityFilter!.isNotEmpty) {
      filtered = filtered
          .where((task) => task['priority'] == priorityFilter)
          .toList();
    }

    // Apply employee filter (admin only)
    if (employeeFilter != null && employeeFilter!.isNotEmpty) {
      filtered = filtered
          .where((task) => task['assignedTo']['_id'] == employeeFilter)
          .toList();
    }

    // Apply project filter
    if (projectFilter != null && projectFilter!.isNotEmpty) {
      filtered = filtered
          .where((task) => task['projectId'] == projectFilter)
          .toList();
    }

    // Apply search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (task) =>
                task['title'].toString().toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                task['description'].toString().toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Apply quick filter
    if (quickFilter != null) {
      switch (quickFilter) {
        case 'overdue':
          filtered = filtered.where((task) {
            final dueDate = DateTime.tryParse(task['dueDate'] ?? '');
            return dueDate != null &&
                dueDate.isBefore(DateTime.now()) &&
                task['status'] != 'completed';
          }).toList();
          break;
        case 'high-priority':
          filtered = filtered
              .where(
                (task) =>
                    task['priority'] == 'high' ||
                    task['priority'] == 'critical',
              )
              .toList();
          break;
        case 'in-progress':
          filtered = filtered
              .where((task) => task['status'] == 'in-progress')
              .toList();
          break;
        case 'assigned':
          filtered = filtered
              .where((task) => task['status'] == 'pending')
              .toList();
          break;
      }
    }

    return filtered;
  }

  /// Get task count by status
  int getTaskCountByStatus(String status) {
    return tasks.where((task) => task['status'] == status).length;
  }

  /// Check if all admin filters are active
  bool get hasActiveFilters =>
      statusFilter != null ||
      priorityFilter != null ||
      employeeFilter != null ||
      projectFilter != null ||
      searchQuery.isNotEmpty ||
      quickFilter != null;

  /// Total tasks waiting for review
  int get tasksUnderReview => statistics['underReview'] ?? 0;

  /// Total overdue tasks
  int get overdueTasks => statistics['overdue'] ?? 0;

  /// In-progress task count
  int get inProgressCount => statistics['inProgress'] ?? 0;

  /// Completed task count
  int get completedCount => statistics['completed'] ?? 0;

  @override
  List<Object?> get props => [
    tasks,
    statistics,
    projects,
    employees,
    isLoading,
    isRefreshing,
    error,
    statusFilter,
    priorityFilter,
    employeeFilter,
    projectFilter,
    searchQuery,
    quickFilter,
    selectedTask,
    timeLogs,
    runningTimer,
    analyticsData,
    selectedEmployeeTab,
    selectedAdminTab,
  ];

  TasksState copyWith({
    List<dynamic>? tasks,
    Map<String, dynamic>? statistics,
    List<dynamic>? projects,
    List<dynamic>? employees,
    bool? isLoading,
    bool? isRefreshing,
    Object? error = _unset,
    Object? statusFilter = _unset,
    Object? priorityFilter = _unset,
    Object? employeeFilter = _unset,
    Object? projectFilter = _unset,
    String? searchQuery,
    Object? quickFilter = _unset,
    Object? selectedTask = _unset,
    List<dynamic>? timeLogs,
    Object? runningTimer = _unset,
    Object? analyticsData = _unset,
    int? selectedEmployeeTab,
    int? selectedAdminTab,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      statistics: statistics ?? this.statistics,
      projects: projects ?? this.projects,
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: identical(error, _unset) ? this.error : error as String?,
      statusFilter: identical(statusFilter, _unset)
          ? this.statusFilter
          : statusFilter as String?,
      priorityFilter: identical(priorityFilter, _unset)
          ? this.priorityFilter
          : priorityFilter as String?,
      employeeFilter: identical(employeeFilter, _unset)
          ? this.employeeFilter
          : employeeFilter as String?,
      projectFilter: identical(projectFilter, _unset)
          ? this.projectFilter
          : projectFilter as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      quickFilter: identical(quickFilter, _unset)
          ? this.quickFilter
          : quickFilter as String?,
      selectedTask: identical(selectedTask, _unset)
          ? this.selectedTask
          : selectedTask,
      timeLogs: timeLogs ?? this.timeLogs,
      runningTimer: identical(runningTimer, _unset)
          ? this.runningTimer
          : runningTimer as Map<String, dynamic>?,
      analyticsData: identical(analyticsData, _unset)
          ? this.analyticsData
          : analyticsData as Map<String, dynamic>?,
      selectedEmployeeTab: selectedEmployeeTab ?? this.selectedEmployeeTab,
      selectedAdminTab: selectedAdminTab ?? this.selectedAdminTab,
    );
  }
}
