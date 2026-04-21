import 'package:flutter/foundation.dart';
import 'package:hrms_app/features/tasks/data/services/task_service.dart';
import 'tasks_state.dart';

class TasksNotifier extends ChangeNotifier {
  TasksState _state = const TasksState();

  TasksNotifier();

  TasksState get state => _state;

  // ── Private Helper ──────────────────────────────────────────────────────

  void _setState(TasksState newState) {
    _state = newState;
    notifyListeners();
  }

  // ── Load Data Methods ───────────────────────────────────────────────────

  /// Load current user's tasks
  Future<void> loadMyTasks(String token) async {
    try {
      _setState(_state.copyWith(isLoading: true, error: null));

      final response = await TaskService.getMyTasks(token);
      // Extract data field if API returns {success: true, data: [...]}
      final tasks = (response is Map && response['data'] != null)
          ? (response['data'] as List)
          : (response is List ? response : []);

      _setState(_state.copyWith(tasks: tasks, isLoading: false));
    } catch (e) {
      _setState(
        _state.copyWith(
          error: e.toString().replaceFirst('Exception: ', ''),
          isLoading: false,
        ),
      );
    }
  }

  /// Load all tasks (Admin only)
  Future<void> loadAllTasks(
    String token, {
    String? status,
    String? assignedTo,
    String? sortBy,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _setState(_state.copyWith(isLoading: true, error: null));

      final response = await TaskService.getTasks(
        token,
        status: status,
        assignedTo: assignedTo,
        sortBy: sortBy,
        page: page,
        limit: limit,
      );
      // Extract data field if API returns {success: true, data: [...]}
      final tasks = (response is Map && response['data'] != null)
          ? (response['data'] as List)
          : (response is List ? response : []);

      _setState(_state.copyWith(tasks: tasks, isLoading: false));
    } catch (e) {
      _setState(
        _state.copyWith(
          error: e.toString().replaceFirst('Exception: ', ''),
          isLoading: false,
        ),
      );
    }
  }

  /// Load task statistics
  Future<void> loadTaskStatistics(String token) async {
    try {
      final response = await TaskService.getTaskStatistics(token);
      // Extract data field if API returns {success: true, data: {...}}
      final stats = (response is Map && response['data'] != null)
          ? (response['data'] as Map<String, dynamic>)
          : (response is Map
              ? (response as Map<String, dynamic>)
              : <String, dynamic>{});

      _setState(_state.copyWith(statistics: stats));
    } catch (e) {
      // Non-blocking error for statistics
      _setState(
        _state.copyWith(
          error: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  /// Refresh tasks and statistics
  Future<void> refreshTasks(String token, {bool isAdmin = false}) async {
    try {
      _setState(_state.copyWith(isRefreshing: true, error: null));

      if (isAdmin) {
        await loadAllTasks(token);
      } else {
        await loadMyTasks(token);
      }

      await loadTaskStatistics(token);

      _setState(_state.copyWith(isRefreshing: false));
    } catch (e) {
      _setState(
        _state.copyWith(
          error: e.toString().replaceFirst('Exception: ', ''),
          isRefreshing: false,
        ),
      );
    }
  }

  // ── Task CRUD Operations ────────────────────────────────────────────────

  /// Create a new task
  Future<String?> createTask(
    String token, {
    required String title,
    required String description,
    required String priority,
    required String dueDate,
    required String assignedTo,
    String? startDate,
    int? estimatedTime,
    String? projectId,
    List<String>? tags,
  }) async {
    try {
      _setState(_state.copyWith(error: null));

      final response = await TaskService.createTask(
        token,
        title: title,
        description: description,
        priority: priority,
        dueDate: dueDate,
        assignedTo: assignedTo,
        startDate: startDate,
        estimatedTime: estimatedTime,
        projectId: projectId,
        tags: tags,
      );

      // Extract data field if API returns {success: true, data: {...}}
      final newTask = (response is Map && response['data'] != null)
          ? (response['data'] as Map<String, dynamic>)
          : (response is Map ? (response as Map<String, dynamic>) : {});
      final updatedTasks = [..._state.tasks, newTask];
      final taskId = (newTask['_id'] ?? newTask['id'])?.toString();

      _setState(_state.copyWith(tasks: updatedTasks));
      return taskId;
    } catch (e) {
      _setState(
        _state.copyWith(error: e.toString().replaceFirst('Exception: ', '')),
      );
      rethrow;
    }
  }

  /// Update task details
  Future<void> updateTask(
    String token,
    String taskId, {
    String? title,
    String? description,
    String? priority,
    String? dueDate,
    String? startDate,
    int? estimatedTime,
    List<String>? tags,
    String? status,
  }) async {
    try {
      _setState(_state.copyWith(error: null));

      await TaskService.updateTask(
        token,
        taskId,
        title: title,
        description: description,
        priority: priority,
        dueDate: dueDate,
        startDate: startDate,
        estimatedTime: estimatedTime,
        tags: tags,
        status: status,
      );

      // Reload tasks to reflect changes
      await loadMyTasks(token);
    } catch (e) {
      _setState(
        _state.copyWith(error: e.toString().replaceFirst('Exception: ', '')),
      );
      rethrow;
    }
  }

  /// Update task progress/status
  Future<void> updateTaskProgress(
    String token,
    String taskId, {
    String? status,
    int? completionPercentage,
    String? notes,
  }) async {
    try {
      _setState(_state.copyWith(error: null));

      await TaskService.updateTaskProgress(
        token,
        taskId,
        status: status,
        completionPercentage: completionPercentage,
        notes: notes,
      );

      // Reload tasks to reflect changes
      await loadMyTasks(token);
    } catch (e) {
      _setState(
        _state.copyWith(error: e.toString().replaceFirst('Exception: ', '')),
      );
      rethrow;
    }
  }

  /// Delete task
  Future<void> deleteTask(String token, String taskId) async {
    try {
      _setState(_state.copyWith(error: null));

      await TaskService.deleteTask(token, taskId);

      final updatedTasks = _state.tasks
          .whereType<Map<String, dynamic>>()
          .where((task) => task['_id'] != taskId)
          .toList();

      _setState(_state.copyWith(tasks: updatedTasks));
    } catch (e) {
      _setState(
        _state.copyWith(error: e.toString().replaceFirst('Exception: ', '')),
      );
      rethrow;
    }
  }

  // ── Filtering Methods ───────────────────────────────────────────────────

  /// Filter tasks by status
  void filterByStatus(String? status) {
    _setState(_state.copyWith(statusFilter: status));
  }

  /// Filter tasks by priority
  void filterByPriority(String? priority) {
    _setState(_state.copyWith(priorityFilter: priority));
  }

  /// Filter tasks by assigned employee (admin only)
  void filterByEmployee(String? employeeId) {
    _setState(_state.copyWith(employeeFilter: employeeId));
  }

  /// Filter tasks by project
  void filterByProject(String? projectId) {
    _setState(_state.copyWith(projectFilter: projectId));
  }

  /// Apply quick filter
  void applyQuickFilter(String? quickFilter) {
    _setState(_state.copyWith(quickFilter: quickFilter));
  }

  /// Search tasks by title or description
  void searchTasks(String query) {
    _setState(_state.copyWith(searchQuery: query));
  }

  /// Clear all filters
  void clearFilters() {
    _setState(
      _state.copyWith(
        statusFilter: null,
        priorityFilter: null,
        employeeFilter: null,
        projectFilter: null,
        quickFilter: null,
        searchQuery: '',
      ),
    );
  }

  // ── Tab Management ──────────────────────────────────────────────────────

  /// Switch employee tab (0=list, 1=kanban, 2=time)
  void switchEmployeeTab(int tab) {
    _setState(_state.copyWith(selectedEmployeeTab: tab));
  }

  /// Switch admin tab (0=list, 1=kanban, 2=employees, 3=projects, 4=time, 5=analytics)
  void switchAdminTab(int tab) {
    _setState(_state.copyWith(selectedAdminTab: tab));
  }

  // ── Time Tracking Methods ───────────────────────────────────────────────

  /// Start timer for a task
  Future<void> startTimer(String token, String taskId) async {
    try {
      _setState(_state.copyWith(error: null));

      // Simulated timer start - in real implementation would call API
      final runningTimer = {
        'taskId': taskId,
        'startTime': DateTime.now().toIso8601String(),
        'elapsed': 0,
      };

      _setState(_state.copyWith(runningTimer: runningTimer));
    } catch (e) {
      _setState(
        _state.copyWith(error: e.toString().replaceFirst('Exception: ', '')),
      );
    }
  }

  /// Stop timer and save time log
  Future<void> stopTimer(String token) async {
    try {
      _setState(_state.copyWith(error: null));

      if (_state.runningTimer == null) return;

      final startTime = DateTime.parse(_state.runningTimer!['startTime']);
      final elapsed = DateTime.now().difference(startTime).inSeconds;

      final timeLogs = [..._state.timeLogs];
      timeLogs.add({
        'taskId': _state.runningTimer!['taskId'],
        'elapsed': elapsed,
        'loggedAt': DateTime.now().toIso8601String(),
      });

      _setState(_state.copyWith(runningTimer: null, timeLogs: timeLogs));
    } catch (e) {
      _setState(
        _state.copyWith(error: e.toString().replaceFirst('Exception: ', '')),
      );
    }
  }

  /// Load time logs for display
  Future<void> loadTimeLogs(String token) async {
    try {
      // In real implementation would fetch from API
      _setState(_state.copyWith(error: null));
    } catch (e) {
      _setState(
        _state.copyWith(error: e.toString().replaceFirst('Exception: ', '')),
      );
    }
  }

  // ── Analytics Methods ───────────────────────────────────────────────────

  /// Load analytics data for dashboard
  Future<void> loadAnalytics(String token) async {
    try {
      _setState(_state.copyWith(error: null));

      // Build analytics from task data
      final analytics = {
        'totalTasks': _state.tasks.length,
        'completedTasks': _state.statistics['completed'] ?? 0,
        'inProgressTasks': _state.statistics['inProgress'] ?? 0,
        'overdueTasks': _state.statistics['overdue'] ?? 0,
        'completionRate': _state.tasks.isEmpty
            ? 0
            : ((_state.statistics['completed'] ?? 0) /
                      _state.tasks.length *
                      100)
                  .toStringAsFixed(2),
        'productivityByStatus': {
          'pending': _state.statistics['pending'] ?? 0,
          'inProgress': _state.statistics['inProgress'] ?? 0,
          'completed': _state.statistics['completed'] ?? 0,
        },
        'workloadByPriority': {
          'low': _state.tasks
              .whereType<Map<String, dynamic>>()
              .where((t) => t['priority'] == 'low')
              .length,
          'medium': _state.tasks
              .whereType<Map<String, dynamic>>()
              .where((t) => t['priority'] == 'medium')
              .length,
          'high': _state.tasks
              .whereType<Map<String, dynamic>>()
              .where((t) => t['priority'] == 'high')
              .length,
          'critical': _state.tasks
              .whereType<Map<String, dynamic>>()
              .where((t) => t['priority'] == 'critical')
              .length,
        },
      };

      _setState(_state.copyWith(analyticsData: analytics));
    } catch (e) {
      _setState(
        _state.copyWith(error: e.toString().replaceFirst('Exception: ', '')),
      );
    }
  }

  // ── File Management ─────────────────────────────────────────────────────

  /// Add attachment to task
  Future<void> addAttachment(
    String token,
    String taskId, {
    required String filePath,
    required String fileName,
    required String fileType,
  }) async {
    try {
      _setState(_state.copyWith(error: null));

      await TaskService.addAttachment(
        token,
        taskId,
        filePath: filePath,
        fileName: fileName,
        fileType: fileType,
      );
    } catch (e) {
      _setState(
        _state.copyWith(error: e.toString().replaceFirst('Exception: ', '')),
      );
      rethrow;
    }
  }

  /// Delete attachment from task
  Future<void> deleteAttachment(
    String token,
    String taskId,
    String attachmentId,
  ) async {
    try {
      _setState(_state.copyWith(error: null));

      await TaskService.deleteAttachment(token, taskId, attachmentId);
    } catch (e) {
      _setState(
        _state.copyWith(error: e.toString().replaceFirst('Exception: ', '')),
      );
      rethrow;
    }
  }

  // ── Task Selection ──────────────────────────────────────────────────────

  /// Select a task for detail view
  void selectTask(dynamic task) {
    _setState(_state.copyWith(selectedTask: task));
  }

  /// Deselect current task
  void deselectTask() {
    _setState(_state.copyWith(selectedTask: null));
  }

  // ── Admin Operations ────────────────────────────────────────────────────

  /// Set employee list (admin only)
  void setEmployees(List<dynamic> employees) {
    _setState(_state.copyWith(employees: employees));
  }

  /// Set projects list (admin only)
  void setProjects(List<dynamic> projects) {
    _setState(_state.copyWith(projects: projects));
  }

  // ── Error & State Management ────────────────────────────────────────────

  /// Clear error message
  void clearError() {
    _setState(_state.copyWith(error: null));
  }

  /// Reset all state
  void reset() {
    _setState(const TasksState());
  }
}
