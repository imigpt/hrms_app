import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/task_service.dart';
import '../services/token_storage_service.dart';
import '../services/admin_employees_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class TasksScreen extends StatefulWidget {
  final String? token;
  final String? role;
  const TasksScreen({super.key, this.token, this.role});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  // ── Theme ──────────────────────────────────────────────────────────────────
  final Color _bgDark = const Color(0xFF050505);
  final Color _cardDark = const Color(0xFF141414);
  final Color _inputDark = const Color(0xFF1F1F1F);
  final Color _accentPink = const Color(0xFFFF8FA3);
  final Color _accentGreen = const Color(0xFF00C853);
  final Color _accentOrange = const Color(0xFFFFAB00);
  final Color _accentPurple = const Color(0xFF651FFF);
  final Color _textGrey = const Color(0xFF9E9E9E);

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _token;
  String? _userId;
  bool _isAdmin = false;

  // ── API state ──────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;
  List<dynamic> _tasks = [];
  Map<String, dynamic> _stats = {
    'total': 0,
    'todo': 0,
    'inProgress': 0,
    'completed': 0,
    'overdue': 0,
    'cancelled': 0,
    'highPriority': 0,
    'averageProgress': 0,
  };

  // ── Admin state ────────────────────────────────────────────────────────────
  List<dynamic> _employees = [];
  String? _adminStatusFilter;
  String? _adminPriorityFilter;
  String? _adminEmployeeFilter; // employee _id

  void _onTabChanged() {
    // Tab changed - no action needed
    if (mounted) {
      setState(() {}); // Rebuild if needed
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _init();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final svc = TokenStorageService();
    _token = widget.token ?? await svc.getToken();
    _userId = await svc.getUserId();
    // Fallback: decode JWT to get id claim in case SharedPreferences
    // was stored before user_id key was added.
    if ((_userId == null || _userId!.isEmpty) && _token != null) {
      _userId = _decodeUserIdFromJwt(_token!);
    }
    _isAdmin = (widget.role?.toLowerCase() == 'admin');
    if (_isAdmin) {
      await Future.wait([_loadData(), _loadEmployees()]);
    } else {
      await _loadData();
    }
  }

  Future<void> _loadEmployees() async {
    if (_token == null) return;
    try {
      final res = await AdminEmployeesService.getAllEmployees(_token!);
      if (res['success'] == true && mounted) {
        setState(() {
          _employees = (res['data'] as List<dynamic>? ?? []);
        });
      }
    } catch (_) {}
  }

  /// Decodes the JWT payload (no signature verification needed—server
  /// already validated it) to extract the `id` field.
  String? _decodeUserIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      var payload = parts[1];
      // Pad base64url to a multiple of 4
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;
      return (claims['id'] ?? claims['_id'] ?? claims['userId'])?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (_token == null) return;
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final results = await Future.wait([
        TaskService.getTasks(_token!),
        TaskService.getTaskStatistics(_token!),
      ]);
      if (mounted) {
        setState(() {
          final tasksRes = results[0] as Map<String, dynamic>;
          final statsRes = results[1] as Map<String, dynamic>;
          _tasks = tasksRes['success'] == true
              ? (tasksRes['data'] as List<dynamic>? ?? [])
              : [];

          if (statsRes['success'] == true && statsRes['data'] != null) {
            _stats = {
              'total': (statsRes['data']['total'] ?? 0) as int,
              'todo': (statsRes['data']['todo'] ?? 0) as int,
              'inProgress': (statsRes['data']['inProgress'] ?? 0) as int,
              'completed': (statsRes['data']['completed'] ?? 0) as int,
              'overdue': (statsRes['data']['overdue'] ?? 0) as int,
              'cancelled': (statsRes['data']['cancelled'] ?? 0) as int,
              'highPriority': (statsRes['data']['highPriority'] ?? 0) as int,
              'averageProgress':
                  (statsRes['data']['averageProgress'] ?? 0) as int,
            };
          } else {
            _stats = {
              'total': _tasks.length,
              'todo': _tasks.where((t) => t['status'] == 'todo').length,
              'inProgress': _tasks
                  .where((t) => t['status'] == 'in-progress')
                  .length,
              'completed': _tasks
                  .where((t) => t['status'] == 'completed')
                  .length,
            };
          }
          _isLoading = false; // Hamesha false set karein aakhir mein
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

  // ── Filtering ──────────────────────────────────────────────────────────────
  List<dynamic> get _filteredTasks {
    var list = _tasks.where((t) {
      final q = _searchQuery.toLowerCase();
      if (q.isEmpty) return true;
      return (t['title'] ?? '').toString().toLowerCase().contains(q) ||
          (t['description'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    switch (_tabController.index) {
      case 1:
        list = list.where((t) => t['status'] == 'todo').toList();
        break;
      case 2:
        list = list.where((t) => t['status'] == 'in-progress').toList();
        break;
      case 3:
        list = list.where((t) => t['status'] == 'completed').toList();
        break;
    }
    return list;
  }

  // Admin filtered tasks (search + status + priority + employee filters)
  List<dynamic> get _adminFilteredTasks {
    return _tasks.where((t) {
      final q = _searchQuery.toLowerCase();
      if (q.isNotEmpty &&
          !((t['title'] ?? '').toString().toLowerCase().contains(q)) &&
          !((t['description'] ?? '').toString().toLowerCase().contains(q)) &&
          !((_assigneeName(t)).toLowerCase().contains(q))) {
        return false;
      }
      if (_adminStatusFilter != null && _adminStatusFilter!.isNotEmpty) {
        if (t['status'] != _adminStatusFilter) return false;
      }
      if (_adminPriorityFilter != null && _adminPriorityFilter!.isNotEmpty) {
        if ((t['priority'] ?? '').toString().toLowerCase() !=
            _adminPriorityFilter)
          return false;
      }
      if (_adminEmployeeFilter != null && _adminEmployeeFilter!.isNotEmpty) {
        final assignedTo = t['assignedTo'];
        if (assignedTo is Map) {
          if ((assignedTo['_id'] ?? '').toString() != _adminEmployeeFilter)
            return false;
        } else if (assignedTo is String) {
          if (assignedTo != _adminEmployeeFilter) return false;
        } else {
          return false;
        }
      }
      return true;
    }).toList();
  }

  String _assigneeName(dynamic task) {
    final a = task['assignedTo'];
    if (a is Map) return (a['name'] ?? '').toString();
    return '';
  }

  // ── Priority / status helpers ──────────────────────────────────────────────
  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return _accentOrange;
      default:
        return _accentGreen;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'in-progress':
        return _accentOrange;
      case 'completed':
        return _accentGreen;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blueAccent;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'in-progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Todo';
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return 'No date';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return DateFormat('MMM d, y').format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  // ── Task detail / update sheet ────────────────────────────────────────────
  Future<void> _showUpdateDialog(Map<String, dynamic> task) async {
    String selectedStatus = task['status'] ?? 'todo';
    double progress = ((task['progress'] ?? 0) as num).toDouble();
    final subTasks = (task['subTasks'] as List<dynamic>? ?? []);
    final canDelete = task['isDeletableByEmployee'] == true;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (stateContext, ss) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (_, scroll) => Column(
                children: [
                  // ── Drag handle ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // ── Header row ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task['title'] ?? 'Task',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit task',
                          onPressed: () => Navigator.pop(sheetContext, 'edit'),
                          icon: Icon(
                            Icons.edit_outlined,
                            color: _accentPink,
                            size: 20,
                          ),
                        ),
                        if (canDelete)
                          IconButton(
                            tooltip: 'Delete task',
                            onPressed: () =>
                                Navigator.pop(sheetContext, 'delete'),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                          ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white38,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Scrollable body ──────────────────────────────────────
                  Expanded(
                    child: ListView(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      children: [
                        // Description
                        if ((task['description'] ?? '')
                            .toString()
                            .isNotEmpty) ...[
                          Text(
                            task['description'].toString(),
                            style: TextStyle(
                              color: _textGrey,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Meta chips row
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Priority chip
                            _metaChip(
                              label: (task['priority'] ?? 'medium')
                                  .toString()
                                  .toUpperCase(),
                              color: _priorityColor(
                                (task['priority'] ?? 'medium').toString(),
                              ),
                              icon: Icons.flag_outlined,
                            ),
                            // Due date chip
                            _metaChip(
                              label: _formatDate(task['dueDate']),
                              color: _textGrey,
                              icon: Icons.calendar_today_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 16),

                        // ── Current status (read-only badge) ────────────
                        Row(
                          children: [
                            Text(
                              'Current Status',
                              style: TextStyle(
                                color: _textGrey,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  selectedStatus,
                                ).withOpacity(0.13),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _statusColor(
                                    selectedStatus,
                                  ).withOpacity(0.35),
                                ),
                              ),
                              child: Text(
                                _statusLabel(selectedStatus),
                                style: TextStyle(
                                  color: _statusColor(selectedStatus),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status updates automatically: 100% → Completed, <100% → In Progress',
                          style: TextStyle(
                            color: _textGrey.withOpacity(0.55),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Progress slider ──────────────────────────────
                        Row(
                          children: [
                            Text(
                              'Progress',
                              style: TextStyle(
                                color: _textGrey,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _accentPink.withOpacity(0.13),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${progress.toInt()}%',
                                style: TextStyle(
                                  color: _accentPink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SliderTheme(
                          data: SliderTheme.of(stateContext).copyWith(
                            activeTrackColor: _accentPink,
                            inactiveTrackColor: Colors.white12,
                            thumbColor: _accentPink,
                            overlayColor: _accentPink.withOpacity(0.15),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                          ),
                          child: Slider(
                            value: progress,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            onChanged: (v) => ss(() => progress = v),
                          ),
                        ),

                        // ── Sub-tasks ────────────────────────────────────
                        if (subTasks.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 12),
                          Text(
                            'Subtasks (${subTasks.where((s) => s['status'] == 'completed').length}/${subTasks.length})',
                            style: TextStyle(
                              color: _textGrey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...subTasks.map((sub) {
                            final done = sub['status'] == 'completed';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: _inputDark,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                              child: CheckboxListTile(
                                dense: true,
                                value: done,
                                activeColor: _accentGreen,
                                checkColor: Colors.black,
                                side: BorderSide(
                                  color: _textGrey.withOpacity(0.4),
                                ),
                                onChanged: (_) {
                                  Navigator.pop(sheetContext); // close sheet
                                  _toggleSubTask(
                                    task['_id'].toString(),
                                    sub['_id'].toString(),
                                    !done,
                                  );
                                },
                                title: Text(
                                  sub['title'] ?? '',
                                  style: TextStyle(
                                    color: done ? _textGrey : Colors.white,
                                    fontSize: 13,
                                    decoration: done
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: _textGrey,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],

                        const SizedBox(height: 24),
                        // ── Manager Review Section (read-only for employee) ──
                        if (task['review'] != null)
                          ..._buildReviewCard(
                            task['review'] as Map<String, dynamic>,
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // ── Save button (pinned at bottom) ────────────────────
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      20 + MediaQuery.of(sheetContext).viewInsets.bottom,
                    ),
                    decoration: BoxDecoration(
                      color: _cardDark,
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.06)),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentPink,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(sheetContext, 'update'),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || action == null) return;

    // Pop animation ko thoda waqt dein poori tarah khatam hone ke liye
    if (action == 'edit') {
      await Future.delayed(const Duration(milliseconds: 200));
      _showEditTaskDialog(task);
    } else if (action == 'delete') {
      await Future.delayed(const Duration(milliseconds: 200));
      _deleteTask(task['_id'].toString());
    } else if (action == 'update') {
      await _updateProgress(task['_id'].toString(), progress.toInt());
    }
  }

  Future<void> _updateProgress(String taskId, int progress) async {
    if (_token == null) return;
    try {
      await TaskService.updateTaskProgress(
        _token!,
        taskId,
        completionPercentage: progress,
      );
      await _loadData(showLoading: false); // SILENT UPDATE

      // Show notification for progress update
      if (progress == 100) {
        await NotificationService().showTaskUpdateNotification(
          taskTitle: 'Task Completed',
          updateType: 'completed',
          details: 'A task has been marked as 100% complete',
        );
      } else {
        await NotificationService().showTaskUpdateNotification(
          taskTitle: 'Progress Update',
          updateType: 'progress_updated',
          details: 'Task progress updated to $progress%',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Progress updated to $progress%'),
            backgroundColor: _accentGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTask(String taskId) async {
    if (_token == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardDark,
        title: const Text(
          'Delete Task',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: const Text(
          'Are you sure you want to delete this task?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _textGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await TaskService.deleteTask(_token!, taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task deleted'),
            backgroundColor: _accentGreen,
          ),
        );
      }
      await _loadData(showLoading: false); // SILENT UPDATE
    } catch (e) {}
  }

  Future<void> _toggleSubTask(
    String taskId,
    String subTaskId,
    bool markDone,
  ) async {
    if (_token == null) return;
    try {
      await TaskService.updateSubTask(
        _token!,
        taskId,
        subTaskId,
        status: markDone ? 'completed' : 'todo',
      );
      await _loadData(showLoading: false); // SILENT UPDATE
    } catch (_) {}
  }

  // ── Edit task dialog ──────────────────────────────────────────────────────
  // ── Edit task dialog ──────────────────────────────────────────────────────
  Future<void> _showEditTaskDialog(Map<String, dynamic> task) async {
    final titleCtrl = TextEditingController(
      text: task['title']?.toString() ?? '',
    );
    final descCtrl = TextEditingController(
      text: task['description']?.toString() ?? '',
    );
    String selectedPriority = (task['priority'] ?? 'medium')
        .toString()
        .toLowerCase();
    DateTime? selectedDueDate;
    if (task['dueDate'] != null) {
      try {
        selectedDueDate = DateTime.parse(task['dueDate'].toString()).toLocal();
      } catch (_) {}
    }
    bool submitting = false;

    try {
      // 1. Await karein aur type <bool> set karein
      final result = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: _cardDark,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (stateContext, ss) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                  left: 24,
                  right: 24,
                  top: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Edit Task',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _inputLabel('Task Title *'),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: titleCtrl,
                        hint: 'Task title',
                        ctx: sheetContext,
                      ),
                      const SizedBox(height: 16),
                      _inputLabel('Description'),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: descCtrl,
                        hint: 'Description...',
                        maxLines: 3,
                        ctx: sheetContext,
                      ),
                      const SizedBox(height: 16),
                      _inputLabel('Priority'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: ['low', 'medium', 'high'].map((p) {
                          final color = _priorityColor(p);
                          final sel = selectedPriority == p;
                          return ChoiceChip(
                            label: Text(
                              p[0].toUpperCase() + p.substring(1),
                              style: TextStyle(
                                color: sel ? color : _textGrey,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            selected: sel,
                            onSelected: (_) => ss(() => selectedPriority = p),
                            selectedColor: color.withOpacity(0.18),
                            backgroundColor: _inputDark,
                            side: BorderSide(
                              color: sel ? color : Colors.transparent,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      _inputLabel('Due Date'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                selectedDueDate ??
                                DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            builder: (_, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: ColorScheme.dark(
                                  primary: _accentPink,
                                  surface: _cardDark,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null)
                            ss(() => selectedDueDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _inputDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.07),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: _textGrey,
                                size: 16,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                selectedDueDate != null
                                    ? DateFormat(
                                        'MMM d, y',
                                      ).format(selectedDueDate!)
                                    : 'Select due date',
                                style: TextStyle(
                                  color: selectedDueDate != null
                                      ? Colors.white
                                      : _textGrey.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentPink,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: submitting
                              ? null
                              : () async {
                                  if (titleCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Title is required'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  ss(() => submitting = true);
                                  try {
                                    await _updateTaskDetails(
                                      taskId: task['_id'].toString(),
                                      title: titleCtrl.text.trim(),
                                      description: descCtrl.text.trim(),
                                      priority: selectedPriority,
                                      dueDate: selectedDueDate,
                                    );

                                    // 2. CHANGE: Yahan se _loadData() hata dein.
                                    // Sirf pop karein aur true pass karein.
                                    if (sheetContext.mounted)
                                      Navigator.pop(sheetContext, true);
                                  } catch (e) {
                                    if (sheetContext.mounted)
                                      ss(() => submitting = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e.toString().replaceAll(
                                              'Exception: ',
                                              '',
                                            ),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.save_outlined, size: 20),
                          label: Text(
                            submitting ? 'Saving...' : 'Save Changes',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      // 3. CHANGE: Sheet poori tarah close hone ke baad _loadData aur SnackBar show karein
      if (result == true && mounted) {
        // Adding delay to ensure bottom sheet is completely closed and widget tree is stable
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Task updated!'),
              backgroundColor: _accentGreen,
              duration: const Duration(seconds: 2),
            ),
          );
          _loadData();
        }
      }
    } finally {
      // Always dispose controllers to prevent memory leaks and "used after dispose" errors
      titleCtrl.dispose();
      descCtrl.dispose();
    }
  }

  /// Pure API call – caller handles pop, snackbar, and reload.
  Future<void> _updateTaskDetails({
    required String taskId,
    required String title,
    required String description,
    required String priority,
    DateTime? dueDate,
  }) async {
    if (_token == null) throw Exception('Not authenticated');
    await TaskService.updateTask(
      _token!,
      taskId,
      title: title,
      description: description.isEmpty ? null : description,
      priority: priority,
      dueDate: dueDate != null
          ? DateFormat('yyyy-MM-dd').format(dueDate)
          : null,
    );

    // Show notification for task update
    await NotificationService().showTaskUpdateNotification(
      taskTitle: title,
      updateType: 'updated',
      details: 'Task details have been updated',
    );
  }

  // ── Create Task ───────────────────────────────────────────────────────────
  // ── Create Task ───────────────────────────────────────────────────────────
  Future<void> _showCreateTaskDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedPriority = 'medium';
    DateTime? selectedDueDate;
    bool submitting = false;

    try {
      // 1. showModalBottomSheet ka type <bool> set karein aur result ko await karein
      final result = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: _cardDark,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (stateContext, ss) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                  left: 24,
                  right: 24,
                  top: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Create Task',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _inputLabel('Task Title *'),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: titleCtrl,
                        hint: 'e.g. Fix login bug',
                        ctx: sheetContext,
                      ),
                      const SizedBox(height: 16),
                      _inputLabel('Description'),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: descCtrl,
                        hint: 'Brief description...',
                        maxLines: 3,
                        ctx: sheetContext,
                      ),
                      const SizedBox(height: 16),
                      _inputLabel('Priority'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: ['low', 'medium', 'high'].map((p) {
                          final color = _priorityColor(p);
                          final selected = selectedPriority == p;
                          return ChoiceChip(
                            label: Text(
                              p[0].toUpperCase() + p.substring(1),
                              style: TextStyle(
                                color: selected ? color : _textGrey,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            selected: selected,
                            onSelected: (_) => ss(() => selectedPriority = p),
                            selectedColor: color.withOpacity(0.18),
                            backgroundColor: _inputDark,
                            side: BorderSide(
                              color: selected ? color : Colors.transparent,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      _inputLabel('Due Date'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            builder: (_, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: ColorScheme.dark(
                                  primary: _accentPink,
                                  surface: _cardDark,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null)
                            ss(() => selectedDueDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _inputDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.07),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: _textGrey,
                                size: 16,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                selectedDueDate != null
                                    ? DateFormat(
                                        'MMM d, y',
                                      ).format(selectedDueDate!)
                                    : 'Select due date',
                                style: TextStyle(
                                  color: selectedDueDate != null
                                      ? Colors.white
                                      : _textGrey.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentPink,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: submitting
                              ? null
                              : () async {
                                  if (titleCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Title is required'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  ss(() => submitting = true);
                                  try {
                                    await _createTask(
                                      title: titleCtrl.text.trim(),
                                      description: descCtrl.text.trim(),
                                      priority: selectedPriority,
                                      dueDate: selectedDueDate,
                                    );

                                    // 2. YAHAN CHANGE HAI: Yahan se _loadData() aur SnackBar nikal diya gaya hai.
                                    // Sirf bottom sheet ko band karein aur sath mein "true" pass karein.
                                    if (sheetContext.mounted)
                                      Navigator.pop(sheetContext, true);
                                  } catch (e) {
                                    if (sheetContext.mounted)
                                      ss(() => submitting = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e.toString().replaceAll(
                                              'Exception: ',
                                              '',
                                            ),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.add, size: 20),
                          label: Text(
                            submitting ? 'Creating...' : 'Create Task',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      // 3. YAHAN CHANGE HAI: Jab Bottom sheet poori tarah close ho jaye, tab data reload karein.
      if (result == true && mounted) {
        // Adding delay to ensure bottom sheet is completely closed and widget tree is stable
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Task created successfully!'),
              backgroundColor: _accentGreen,
            ),
          );
          _loadData();
        }
      }
    } finally {
      // Always dispose controllers to prevent memory leaks and "used after dispose" errors
      titleCtrl.dispose();
      descCtrl.dispose();
    }
  }

  /// Pure API call – no UI side-effects so it is safe to call while a
  /// bottom-sheet is still open.  The caller is responsible for popping
  /// the sheet first, then showing feedback and reloading data.
  Future<void> _createTask({
    required String title,
    required String description,
    required String priority,
    DateTime? dueDate,
  }) async {
    if (_token == null) throw Exception('Not authenticated');
    final assignTo = _userId ?? '';
    if (assignTo.isEmpty) throw Exception('User ID not found');
    await TaskService.createTask(
      _token!,
      title: title,
      description: description.isEmpty ? title : description,
      priority: priority,
      dueDate: dueDate != null
          ? DateFormat('yyyy-MM-dd').format(dueDate)
          : DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime.now().add(const Duration(days: 7))),
      assignedTo: assignTo,
    );

    // Show notification for task creation
    await NotificationService().showTaskAssignedNotification(
      taskTitle: title,
      assignedTo: 'You',
      priority: priority,
    );
  }

  // ── Input helpers ──────────────────────────────────────────────────────────
  Widget _metaChip({
    required String label,
    required Color color,
    required IconData icon,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _inputLabel(String text) => Text(
    text,
    style: TextStyle(
      color: _textGrey,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required BuildContext ctx,
    int maxLines = 1,
  }) => Container(
    decoration: BoxDecoration(
      color: _inputDark,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintText: hint,
        hintStyle: TextStyle(color: _textGrey.withOpacity(0.5), fontSize: 14),
      ),
    ),
  );

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isAdmin) return _buildAdminScaffold(context);
    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return Column(
              children: [
                _buildHeader(context, isMobile),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: _accentPink),
                        )
                      : _error != null
                      ? _buildError()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSearchBar(),
                              const SizedBox(height: 20),
                              isMobile
                                  ? _buildMobileStats()
                                  : _buildDesktopStats(),
                              const SizedBox(height: 24),
                              _buildTabBar(),
                              const SizedBox(height: 20),
                              _buildTaskList(),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── ADMIN PANEL ─────────────────────────────────────────────────────────────
  Widget _buildAdminScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildAdminHeader(context),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: _accentPink))
                  : _error != null
                  ? _buildError()
                  : RefreshIndicator(
                      color: _accentPink,
                      backgroundColor: _cardDark,
                      onRefresh: () async {
                        await Future.wait([_loadData(), _loadEmployees()]);
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAdminStats(),
                            const SizedBox(height: 20),
                            _buildAdminSearchAndFilters(),
                            const SizedBox(height: 16),
                            _buildAdminTaskList(),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAdminCreateTaskDialog,
        backgroundColor: _accentPink,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Assign Task',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildAdminHeader(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: _cardDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            minimumSize: const Size(44, 44),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Task Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_adminFilteredTasks.length} of ${_tasks.length} tasks',
                style: TextStyle(color: _textGrey, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: () async => Future.wait([_loadData(), _loadEmployees()]),
          icon: Icon(Icons.refresh_rounded, color: _accentPink, size: 22),
          style: IconButton.styleFrom(
            backgroundColor: _accentPink.withValues(alpha: 0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildAdminStats() {
    final total = _stats['total'] ?? _tasks.length;
    final inProgress = _stats['inProgress'] ?? 0;
    final completed = _stats['completed'] ?? 0;
    final overdue = _stats['overdue'] ?? 0;
    final highPriority = _stats['highPriority'] ?? 0;
    final avgProgress = _stats['averageProgress'] ?? 0;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                '$total',
                Icons.folder_outlined,
                _accentPurple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'In Progress',
                '$inProgress',
                Icons.pending_actions,
                _accentOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Completed',
                '$completed',
                Icons.check_circle_outline,
                _accentGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Overdue',
                '$overdue',
                Icons.warning_amber_outlined,
                Colors.redAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'High Priority',
                '$highPriority',
                Icons.flag_outlined,
                _accentPink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Avg Progress',
                '$avgProgress%',
                Icons.insights,
                Colors.blueAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminSearchAndFilters() => Column(
    children: [
      // Search bar
      Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _searchQuery.isNotEmpty
                ? AppTheme.primaryColor.withOpacity(0.5)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            hintText: 'Search tasks, employees...',
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: _searchQuery.isNotEmpty
                  ? AppTheme.primaryColor
                  : Colors.grey[600],
              size: 20,
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 46),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
        ),
      ),
      const SizedBox(height: 12),
      // Filter chips row
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Status filter
            _adminFilterChip(
              label: _adminStatusFilter == null
                  ? 'All Status'
                  : _statusLabel(_adminStatusFilter!),
              icon: Icons.tune,
              active: _adminStatusFilter != null,
              onTap: _showStatusFilterSheet,
            ),
            const SizedBox(width: 8),
            // Priority filter
            _adminFilterChip(
              label: _adminPriorityFilter == null
                  ? 'All Priority'
                  : '${_adminPriorityFilter![0].toUpperCase()}${_adminPriorityFilter!.substring(1)} Priority',
              icon: Icons.flag_outlined,
              active: _adminPriorityFilter != null,
              onTap: _showPriorityFilterSheet,
            ),
            const SizedBox(width: 8),
            // Employee filter
            _adminFilterChip(
              label: _adminEmployeeFilter == null
                  ? 'All Employees'
                  : (_employees.firstWhere(
                              (e) => e['_id'] == _adminEmployeeFilter,
                              orElse: () => {'name': 'Employee'},
                            )['name'] ??
                            'Employee')
                        .toString()
                        .split(' ')
                        .first,
              icon: Icons.person_outline,
              active: _adminEmployeeFilter != null,
              onTap: _showEmployeeFilterSheet,
            ),
            if (_adminStatusFilter != null ||
                _adminPriorityFilter != null ||
                _adminEmployeeFilter != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() {
                  _adminStatusFilter = null;
                  _adminPriorityFilter = null;
                  _adminEmployeeFilter = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.clear, color: Colors.redAccent, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );

  Widget _adminFilterChip({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? _accentPink.withValues(alpha: 0.15) : _cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? _accentPink : Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? _accentPink : _textGrey, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: active ? _accentPink : _textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            Icons.keyboard_arrow_down,
            color: active ? _accentPink : _textGrey,
            size: 14,
          ),
        ],
      ),
    ),
  );

  void _showStatusFilterSheet() {
    final options = [
      {'value': null, 'label': 'All Status', 'color': Colors.white},
      {'value': 'todo', 'label': 'To Do', 'color': Colors.blueAccent},
      {'value': 'in-progress', 'label': 'In Progress', 'color': _accentOrange},
      {'value': 'completed', 'label': 'Completed', 'color': _accentGreen},
      {'value': 'cancelled', 'label': 'Cancelled', 'color': Colors.grey},
    ];
    _showFilterSheet('Filter by Status', options, _adminStatusFilter, (v) {
      setState(() => _adminStatusFilter = v as String?);
    });
  }

  void _showPriorityFilterSheet() {
    final options = [
      {'value': null, 'label': 'All Priority', 'color': Colors.white},
      {'value': 'low', 'label': 'Low', 'color': _accentGreen},
      {'value': 'medium', 'label': 'Medium', 'color': _accentOrange},
      {'value': 'high', 'label': 'High', 'color': Colors.redAccent},
    ];
    _showFilterSheet('Filter by Priority', options, _adminPriorityFilter, (v) {
      setState(() => _adminPriorityFilter = v as String?);
    });
  }

  void _showEmployeeFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          builder: (_, sc) => Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Filter by Employee',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  children: [
                    _filterOption(
                      label: 'All Employees',
                      color: Colors.white,
                      selected: _adminEmployeeFilter == null,
                      onTap: () {
                        setState(() => _adminEmployeeFilter = null);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(color: Colors.white10, height: 8),
                    ..._employees.map((e) {
                      final id = e['_id']?.toString() ?? '';
                      final name = e['name']?.toString() ?? 'Employee';
                      return _filterOption(
                        label: name,
                        subtitle: e['employeeId']?.toString(),
                        color: _accentPink,
                        selected: _adminEmployeeFilter == id,
                        onTap: () {
                          setState(() => _adminEmployeeFilter = id);
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showFilterSheet(
    String title,
    List<Map<String, dynamic>> options,
    dynamic currentValue,
    ValueChanged<dynamic> onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map(
              (opt) => _filterOption(
                label: opt['label'] as String,
                color: opt['color'] as Color,
                selected: currentValue == opt['value'],
                onTap: () {
                  onSelect(opt['value']);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterOption({
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
    String? subtitle,
  }) => ListTile(
    dense: true,
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    leading: Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
    title: Text(
      label,
      style: TextStyle(
        color: selected ? _accentPink : Colors.white,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 14,
      ),
    ),
    subtitle: subtitle != null
        ? Text(subtitle, style: TextStyle(color: _textGrey, fontSize: 11))
        : null,
    trailing: selected ? Icon(Icons.check, color: _accentPink, size: 18) : null,
  );

  Widget _buildAdminTaskList() {
    final list = _adminFilteredTasks;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Column(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 56,
                color: _textGrey.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No tasks found',
                style: TextStyle(
                  color: _textGrey,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try clearing filters or assign a new task',
                style: TextStyle(
                  color: _textGrey.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (_, i) =>
          _buildAdminTaskCard(list[i] as Map<String, dynamic>),
    );
  }

  Widget _buildAdminTaskCard(Map<String, dynamic> task) {
    final priority = (task['priority'] ?? 'medium').toString();
    final status = (task['status'] ?? 'todo').toString();
    final progress = ((task['progress'] ?? 0) as num).toDouble();
    final priorityColor = _priorityColor(priority);
    final statusColor = _statusColor(status);
    final assignee = task['assignedTo'];
    final assigneeName = assignee is Map
        ? (assignee['name'] ?? 'Unassigned').toString()
        : 'Unassigned';
    final assigneeId = assignee is Map
        ? (assignee['employeeId'] ?? '').toString()
        : '';
    final dept = assignee is Map
        ? (assignee['department'] ?? '').toString()
        : '';

    return GestureDetector(
      onTap: () => _showAdminTaskDetail(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 5, color: priorityColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chips row
                        Row(
                          children: [
                            _miniChip(
                              priority[0].toUpperCase() + priority.substring(1),
                              priorityColor,
                            ),
                            const SizedBox(width: 6),
                            _miniChip(_statusLabel(status), statusColor),
                            const Spacer(),
                            // Review star: filled (gold) if reviewed, outline if not
                            GestureDetector(
                              onTap: () => _showAdminReviewDialog(task),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  task['review'] != null
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: task['review'] != null
                                      ? Colors.amber
                                      : _textGrey.withValues(alpha: 0.5),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Title
                        Text(
                          task['title'] ?? '—',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((task['description'] ?? '')
                            .toString()
                            .isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task['description'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _textGrey,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        // Progress
                        if (status != 'completed' && status != 'cancelled') ...[
                          Row(
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  color: _textGrey,
                                  fontSize: 10,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${progress.toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              minHeight: 5,
                              backgroundColor: Colors.black,
                              color: priorityColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        // Footer: assignee + due date
                        Row(
                          children: [
                            // Assignee avatar
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: _accentPink.withValues(
                                alpha: 0.2,
                              ),
                              child: Text(
                                assigneeName.isNotEmpty
                                    ? assigneeName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: _accentPink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    assigneeName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (dept.isNotEmpty || assigneeId.isNotEmpty)
                                    Text(
                                      dept.isNotEmpty ? dept : assigneeId,
                                      style: TextStyle(
                                        color: _textGrey,
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.calendar_today_outlined,
                              color: _textGrey,
                              size: 11,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatDate(task['dueDate']),
                              style: TextStyle(color: _textGrey, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
    ),
  );

  // ── Review helpers ─────────────────────────────────────────────────────────
  List<Widget> _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] ?? 0) as num;
    final comment = (review['comment'] ?? '').toString();
    final reviewedBy = review['reviewedBy'];
    final reviewerName = reviewedBy is Map
        ? (reviewedBy['name'] ?? 'Manager').toString()
        : 'Manager';
    final reviewedAt = review['reviewedAt'];
    String dateStr = '';
    if (reviewedAt != null) {
      try {
        dateStr = DateFormat(
          'MMM d, y',
        ).format(DateTime.parse(reviewedAt.toString()).toLocal());
      } catch (_) {}
    }
    return [
      const SizedBox(height: 16),
      const Divider(color: Colors.white10),
      const SizedBox(height: 12),
      Row(
        children: [
          Icon(Icons.star_rounded, color: Colors.amber, size: 16),
          const SizedBox(width: 6),
          Text(
            'Manager Review',
            style: TextStyle(
              color: _textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Star row
            Row(
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < rating.toInt()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 18,
                  ),
                ),
                const Spacer(),
                Text(dateStr, style: TextStyle(color: _textGrey, fontSize: 11)),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                comment,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, color: _textGrey, size: 13),
                const SizedBox(width: 4),
                Text(
                  reviewerName,
                  style: TextStyle(color: _textGrey, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Future<void> _showAdminReviewDialog(Map<String, dynamic> task) async {
    final existing = task['review'] as Map<String, dynamic>?;
    final commentCtrl = TextEditingController(
      text: existing?['comment']?.toString() ?? '',
    );
    int selectedRating = existing != null
        ? (existing['rating'] as num).toInt()
        : 0;
    bool submitting = false;

    try {
      final result = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: _cardDark,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetCtx) => StatefulBuilder(
          builder: (_, ss) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          existing != null ? 'Update Review' : 'Add Review',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white54,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task['title'] ?? '',
                      style: TextStyle(color: _textGrey, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    // Star rating
                    _inputLabel('Rating *'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final filled = i < selectedRating;
                        return GestureDetector(
                          onTap: () => ss(() => selectedRating = i + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              filled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: filled
                                  ? Colors.amber
                                  : _textGrey.withValues(alpha: 0.5),
                              size: 40,
                            ),
                          ),
                        );
                      }),
                    ),
                    if (selectedRating > 0) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          [
                            '',
                            'Poor',
                            'Fair',
                            'Good',
                            'Very Good',
                            'Excellent',
                          ][selectedRating],
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Comment
                    _inputLabel('Comment'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _inputDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                      child: TextField(
                        controller: commentCtrl,
                        maxLines: 4,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          hintText: 'Add a comment about this task...',
                          hintStyle: TextStyle(
                            color: _textGrey.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: submitting
                            ? null
                            : () async {
                                if (selectedRating == 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a rating'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                ss(() => submitting = true);
                                try {
                                  await TaskService.addReview(
                                    _token!,
                                    task['_id'].toString(),
                                    comment: commentCtrl.text.trim(),
                                    rating: selectedRating,
                                  );
                                  if (sheetCtx.mounted)
                                    Navigator.pop(sheetCtx, true);
                                } catch (e) {
                                  if (sheetCtx.mounted)
                                    ss(() => submitting = false);
                                  if (mounted)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceAll(
                                            'Exception: ',
                                            '',
                                          ),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                }
                              },
                        icon: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.star_rounded, size: 20),
                        label: Text(
                          submitting
                              ? 'Submitting...'
                              : (existing != null
                                    ? 'Update Review'
                                    : 'Submit Review'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            );
          },
        ),
      );

      if (result == true && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                existing != null ? 'Review updated!' : 'Review submitted!',
              ),
              backgroundColor: Colors.amber.shade700,
            ),
          );
          _loadData();
        }
      }
    } finally {
      commentCtrl.dispose();
    }
  }

  Future<void> _showAdminTaskDetail(Map<String, dynamic> task) async {
    final assignee = task['assignedTo'];
    final assigneeName = assignee is Map
        ? (assignee['name'] ?? 'Unassigned').toString()
        : 'Unassigned';
    final dept = assignee is Map
        ? (assignee['department'] ?? '').toString()
        : '';
    final employeeId = assignee is Map
        ? (assignee['employeeId'] ?? '').toString()
        : '';

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        builder: (_, sc) => Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      task['title'] ?? 'Task',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: _accentPink,
                      size: 20,
                    ),
                    tooltip: 'Edit',
                    onPressed: () => Navigator.pop(sheetCtx, 'edit'),
                  ),
                  IconButton(
                    icon: Icon(
                      task['review'] != null
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: task['review'] != null ? Colors.amber : _textGrey,
                      size: 20,
                    ),
                    tooltip: task['review'] != null
                        ? 'Update Review'
                        : 'Add Review',
                    onPressed: () => Navigator.pop(sheetCtx, 'review'),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    tooltip: 'Delete',
                    onPressed: () => Navigator.pop(sheetCtx, 'delete'),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white38,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // Assignee card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _inputDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: _accentPink.withValues(alpha: 0.2),
                          child: Text(
                            assigneeName.isNotEmpty
                                ? assigneeName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: _accentPink,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assigneeName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (dept.isNotEmpty)
                              Text(
                                dept,
                                style: TextStyle(
                                  color: _textGrey,
                                  fontSize: 12,
                                ),
                              ),
                            if (employeeId.isNotEmpty)
                              Text(
                                'ID: $employeeId',
                                style: TextStyle(
                                  color: _textGrey,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        _miniChip(
                          _statusLabel(task['status'] ?? 'todo'),
                          _statusColor(task['status'] ?? 'todo'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Description
                  if ((task['description'] ?? '').toString().isNotEmpty) ...[
                    Text(
                      task['description'].toString(),
                      style: TextStyle(
                        color: _textGrey,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  // Meta
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _metaChip(
                        label: (task['priority'] ?? 'medium')
                            .toString()
                            .toUpperCase(),
                        color: _priorityColor(task['priority'] ?? 'medium'),
                        icon: Icons.flag_outlined,
                      ),
                      _metaChip(
                        label: _formatDate(task['dueDate']),
                        color: _textGrey,
                        icon: Icons.calendar_today_outlined,
                      ),
                    ],
                  ),
                  // Progress
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          color: _textGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _accentPink.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${((task['progress'] ?? 0) as num).toInt()}%',
                          style: TextStyle(
                            color: _accentPink,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ((task['progress'] ?? 0) as num).toDouble() / 100,
                      minHeight: 8,
                      backgroundColor: Colors.white10,
                      color: _accentPink,
                    ),
                  ),
                  // ── Existing review display in detail ────────────────
                  if (task['review'] != null)
                    ..._buildReviewCard(task['review'] as Map<String, dynamic>),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;
    if (action == 'edit') {
      await Future.delayed(const Duration(milliseconds: 200));
      _showEditTaskDialog(task);
    } else if (action == 'delete') {
      await Future.delayed(const Duration(milliseconds: 200));
      _deleteTask(task['_id'].toString());
    } else if (action == 'review') {
      await Future.delayed(const Duration(milliseconds: 200));
      _showAdminReviewDialog(task);
    }
  }

  Future<void> _showAdminCreateTaskDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedPriority = 'medium';
    DateTime? selectedDueDate;
    String? selectedEmployeeId;
    bool submitting = false;

    try {
      final result = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: _cardDark,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetCtx) => StatefulBuilder(
          builder: (_, ss) {
            final selectedEmployee = selectedEmployeeId != null
                ? _employees.firstWhere(
                    (e) => e['_id'] == selectedEmployeeId,
                    orElse: () => null,
                  )
                : null;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Assign Task',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white54,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Assign To
                    _inputLabel('Assign To *'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await _pickEmployee(sheetCtx);
                        if (picked != null)
                          ss(() => selectedEmployeeId = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _inputDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedEmployee != null
                                ? _accentPink.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (selectedEmployee != null) ...[
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: _accentPink.withValues(
                                  alpha: 0.2,
                                ),
                                child: Text(
                                  (selectedEmployee['name'] ?? '?')[0]
                                      .toString()
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: _accentPink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      selectedEmployee['name'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (selectedEmployee['department'] != null)
                                      Text(
                                        selectedEmployee['department']
                                            .toString(),
                                        style: TextStyle(
                                          color: _textGrey,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(Icons.edit, color: _accentPink, size: 16),
                            ] else ...[
                              Icon(
                                Icons.person_add_outlined,
                                color: _textGrey,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Select Employee',
                                style: TextStyle(
                                  color: _textGrey.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: _textGrey,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _inputLabel('Task Title *'),
                    const SizedBox(height: 8),
                    _inputField(
                      controller: titleCtrl,
                      hint: 'e.g. Fix login bug',
                      ctx: sheetCtx,
                    ),
                    const SizedBox(height: 16),
                    _inputLabel('Description'),
                    const SizedBox(height: 8),
                    _inputField(
                      controller: descCtrl,
                      hint: 'Brief description...',
                      maxLines: 3,
                      ctx: sheetCtx,
                    ),
                    const SizedBox(height: 16),
                    _inputLabel('Priority'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: ['low', 'medium', 'high'].map((p) {
                        final c = _priorityColor(p);
                        final sel = selectedPriority == p;
                        return ChoiceChip(
                          label: Text(
                            p[0].toUpperCase() + p.substring(1),
                            style: TextStyle(
                              color: sel ? c : _textGrey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: sel,
                          onSelected: (_) => ss(() => selectedPriority = p),
                          selectedColor: c.withValues(alpha: 0.18),
                          backgroundColor: _inputDark,
                          side: BorderSide(color: sel ? c : Colors.transparent),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _inputLabel('Due Date'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 1),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          builder: (_, c) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: _accentPink,
                                surface: _cardDark,
                              ),
                            ),
                            child: c!,
                          ),
                        );
                        if (picked != null) ss(() => selectedDueDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _inputDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: _textGrey,
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              selectedDueDate != null
                                  ? DateFormat(
                                      'MMM d, y',
                                    ).format(selectedDueDate!)
                                  : 'Select due date',
                              style: TextStyle(
                                color: selectedDueDate != null
                                    ? Colors.white
                                    : _textGrey.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentPink,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: submitting
                            ? null
                            : () async {
                                if (titleCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Title is required'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                if (selectedEmployeeId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select an employee',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                ss(() => submitting = true);
                                try {
                                  await TaskService.createTask(
                                    _token!,
                                    title: titleCtrl.text.trim(),
                                    description: descCtrl.text.trim().isEmpty
                                        ? titleCtrl.text.trim()
                                        : descCtrl.text.trim(),
                                    priority: selectedPriority,
                                    dueDate: selectedDueDate != null
                                        ? DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(selectedDueDate!)
                                        : DateFormat('yyyy-MM-dd').format(
                                            DateTime.now().add(
                                              const Duration(days: 7),
                                            ),
                                          ),
                                    assignedTo: selectedEmployeeId!,
                                  );
                                  if (sheetCtx.mounted)
                                    Navigator.pop(sheetCtx, true);
                                } catch (e) {
                                  if (sheetCtx.mounted)
                                    ss(() => submitting = false);
                                  if (mounted)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceAll(
                                            'Exception: ',
                                            '',
                                          ),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                }
                              },
                        icon: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.send_outlined, size: 20),
                        label: Text(
                          submitting ? 'Assigning...' : 'Assign Task',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            );
          },
        ),
      );
      if (result == true && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Task assigned successfully!'),
              backgroundColor: _accentGreen,
            ),
          );
          _loadData();
        }
      }
    } finally {
      titleCtrl.dispose();
      descCtrl.dispose();
    }
  }

  Future<String?> _pickEmployee(BuildContext sheetCtx) async {
    return showModalBottomSheet<String>(
      context: sheetCtx,
      backgroundColor: _cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        String search = '';
        return StatefulBuilder(
          builder: (_, ss2) {
            final filtered = _employees.where((e) {
              if (search.isEmpty) return true;
              return (e['name'] ?? '').toString().toLowerCase().contains(
                    search.toLowerCase(),
                  ) ||
                  (e['employeeId'] ?? '').toString().toLowerCase().contains(
                    search.toLowerCase(),
                  ) ||
                  (e['department'] ?? '').toString().toLowerCase().contains(
                    search.toLowerCase(),
                  );
            }).toList();
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.55,
              maxChildSize: 0.9,
              builder: (_, sc) => Column(
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Employee',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _inputDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: TextField(
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            onChanged: (v) => ss2(() => search = v),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search employees...',
                              hintStyle: TextStyle(
                                color: _textGrey,
                                fontSize: 13,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: _textGrey,
                                size: 18,
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 36,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: sc,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final e = filtered[i];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: _accentPink.withValues(alpha: 0.2),
                            child: Text(
                              (e['name'] ?? '?')[0].toString().toUpperCase(),
                              style: TextStyle(
                                color: _accentPink,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            e['name'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${e['department'] ?? ''} • ${e['employeeId'] ?? ''}',
                            style: TextStyle(color: _textGrey, fontSize: 11),
                          ),
                          onTap: () =>
                              Navigator.pop(context, e['_id']?.toString()),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: _textGrey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentPink,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildHeader(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: _cardDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(10),
                    minimumSize: const Size(44, 44),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Tasks',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd').format(DateTime.now()),
                        style: TextStyle(color: _textGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showCreateTaskDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Create Task',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentPink,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: _cardDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Tasks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, y').format(DateTime.now()),
                  style: TextStyle(color: _textGrey, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showCreateTaskDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'Create Task',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentPink,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _searchQuery.isNotEmpty
              ? AppTheme.primaryColor.withOpacity(0.5)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          hintText: 'Search tasks...',
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _searchQuery.isNotEmpty
                ? AppTheme.primaryColor
                : Colors.grey[600],
            size: 20,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 46),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.grey[600],
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDesktopStats() => Row(
    children: [
      Expanded(
        child: _buildStatCard(
          'Total',
          '${_stats['total'] ?? _tasks.length}',
          Icons.folder_open,
          _accentPurple,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _buildStatCard(
          'In Progress',
          '${_stats['inProgress'] ?? 0}',
          Icons.timer,
          _accentOrange,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _buildStatCard(
          'Completed',
          '${_stats['completed'] ?? 0}',
          Icons.check_circle,
          _accentGreen,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _buildStatCard(
          'Overdue',
          '${_stats['overdue'] ?? 0}',
          Icons.warning_amber_rounded,
          Colors.redAccent,
        ),
      ),
    ],
  );

  Widget _buildMobileStats() => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    crossAxisSpacing: 14,
    mainAxisSpacing: 14,
    childAspectRatio: 1.35,
    children: [
      _buildStatCard(
        'Total',
        '${_stats['total'] ?? _tasks.length}',
        Icons.folder_open,
        _accentPurple,
      ),
      _buildStatCard(
        'In Progress',
        '${_stats['inProgress'] ?? 0}',
        Icons.timer,
        _accentOrange,
      ),
      _buildStatCard(
        'Completed',
        '${_stats['completed'] ?? 0}',
        Icons.check_circle,
        _accentGreen,
      ),
      _buildStatCard(
        'Overdue',
        '${_stats['overdue'] ?? 0}',
        Icons.warning_amber_rounded,
        Colors.redAccent,
      ),
    ],
  );

  Widget _buildStatCard(
    String label,
    String count,
    IconData icon,
    Color color,
  ) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _cardDark,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 15),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: _textGrey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );

  Widget _buildTabBar() => LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: _accentPink,
            borderRadius: BorderRadius.circular(12),
          ),
          labelColor: Colors.black,
          unselectedLabelColor: _textGrey,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          padding: const EdgeInsets.all(5),
          tabs: isMobile
              ? [
                  Tab(text: 'All'),
                  Tab(text: 'Todo'),
                  Tab(text: 'Progress'),
                  Tab(text: 'Done'),
                ]
              : [
                  Tab(text: 'All (${_tasks.length})'),
                  Tab(text: 'Todo (${_stats['todo'] ?? 0})'),
                  Tab(text: 'In Progress (${_stats['inProgress'] ?? 0})'),
                  Tab(text: 'Done (${_stats['completed'] ?? 0})'),
                ],
        ),
      );
    },
  );

  Widget _buildTaskList() {
    final list = _filteredTasks;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 56,
                color: _textGrey.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No tasks found',
                style: TextStyle(
                  color: _textGrey,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new task to get started',
                style: TextStyle(
                  color: _textGrey.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildTaskCard(list[i] as Map<String, dynamic>),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final priority = (task['priority'] ?? 'medium').toString();
    final status = (task['status'] ?? 'todo').toString();
    final progress = ((task['progress'] ?? 0) as num).toDouble();
    final priorityColor = _priorityColor(priority);
    final statusColor = _statusColor(status);
    final isCompleted = status == 'completed';

    final canDelete = task['isDeletableByEmployee'] == true;

    return Dismissible(
      key: Key(task['_id']?.toString() ?? UniqueKey().toString()),
      direction: canDelete
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      confirmDismiss: canDelete
          ? (_) async {
              return await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: _cardDark,
                      title: const Text(
                        'Delete Task',
                        style: TextStyle(color: Colors.white, fontSize: 17),
                      ),
                      content: const Text(
                        'Are you sure you want to delete this task?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: _textGrey),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ) ??
                  false;
            }
          : null,
      onDismissed: (_) => _deleteTask(task['_id'].toString()),
      child: GestureDetector(
        onTap: () => _showUpdateDialog(task),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(width: 5, color: priorityColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Priority chip + status badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: priorityColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  priority[0].toUpperCase() +
                                      priority.substring(1),
                                  style: TextStyle(
                                    color: priorityColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _statusLabel(status),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.edit_outlined,
                                color: _textGrey.withOpacity(0.4),
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Title
                          Text(
                            task['title'] ?? '—',
                            style: TextStyle(
                              color: isCompleted ? _textGrey : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((task['description'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              task['description'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _textGrey,
                                fontSize: 11,
                                height: 1.35,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          // Progress bar (not shown for completed/cancelled)
                          if (!isCompleted && status != 'cancelled') ...[
                            Row(
                              children: [
                                Text(
                                  'Progress',
                                  style: TextStyle(
                                    color: _textGrey,
                                    fontSize: 10,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${progress.toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: progress / 100,
                                minHeight: 5,
                                backgroundColor: Colors.black,
                                color: priorityColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          // Due date + assigned by
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: _textGrey,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  task['dueDate'] != null
                                      ? _formatDate(task['dueDate'])
                                      : 'No due date',
                                  style: TextStyle(
                                    color: _textGrey,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (task['assignedBy'] != null &&
                                  task['assignedBy'] is Map) ...[
                                Icon(
                                  Icons.person_outline,
                                  color: _textGrey,
                                  size: 12,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    (task['assignedBy']['name'] ?? 'Manager')
                                        .toString()
                                        .split(' ')
                                        .first,
                                    style: TextStyle(
                                      color: _textGrey,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ), // closes GestureDetector (child of Dismissible)
    ); // closes Dismissible
  }
}
