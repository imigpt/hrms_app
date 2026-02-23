import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/task_service.dart';
import '../services/token_storage_service.dart';

class TasksScreen extends StatefulWidget {
  final String? token;
  const TasksScreen({super.key, this.token});

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
  String _searchQuery = '';
  String? _token;
  String? _userId;

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

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _init();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
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
    await _loadData();
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
      return (claims['id'] ?? claims['_id'] ?? claims['userId'])
          ?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadData() async {
    if (_token == null) return;
    try {
      if (!mounted) return;
      setState(() { _isLoading = true; _error = null; });
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
          
          // Parse stats from API or calculate locally
          if (statsRes['success'] == true && statsRes['data'] != null) {
            _stats = {
              'total': (statsRes['data']['total'] ?? 0) as int,
              'todo': (statsRes['data']['todo'] ?? 0) as int,
              'inProgress': (statsRes['data']['inProgress'] ?? 0) as int,
              'completed': (statsRes['data']['completed'] ?? 0) as int,
              'overdue': (statsRes['data']['overdue'] ?? 0) as int,
              'cancelled': (statsRes['data']['cancelled'] ?? 0) as int,
              'highPriority': (statsRes['data']['highPriority'] ?? 0) as int,
              'averageProgress': (statsRes['data']['averageProgress'] ?? 0) as int,
            };
          } else {
            // Fallback: calculate stats locally from tasks
            _stats = {
              'total': _tasks.length,
              'todo': _tasks.where((t) => t['status'] == 'todo').length,
              'inProgress': _tasks.where((t) => t['status'] == 'in-progress').length,
              'completed': _tasks.where((t) => t['status'] == 'completed').length,
              'overdue': _tasks.where((t) => 
                  t['dueDate'] != null && 
                  DateTime.parse(t['dueDate'].toString()).isBefore(DateTime.now()) &&
                  t['status'] != 'completed'
              ).length,
              'cancelled': _tasks.where((t) => t['status'] == 'cancelled').length,
              'highPriority': _tasks.where((t) => t['priority'] == 'high').length,
              'averageProgress': _tasks.isNotEmpty 
                  ? (_tasks.fold<int>(0, (sum, t) => sum + ((t['progress'] ?? 0) as int)) / _tasks.length).round()
                  : 0,
            };
          }
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

  // ── Filtering ──────────────────────────────────────────────────────────────
  List<dynamic> get _filteredTasks {
    var list = _tasks.where((t) {
      final q = _searchQuery.toLowerCase();
      if (q.isEmpty) return true;
      return (t['title'] ?? '').toString().toLowerCase().contains(q) ||
          (t['description'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    switch (_tabController.index) {
      case 1: list = list.where((t) => t['status'] == 'todo').toList(); break;
      case 2: list = list.where((t) => t['status'] == 'in-progress').toList(); break;
      case 3: list = list.where((t) => t['status'] == 'completed').toList(); break;
    }
    return list;
  }

  // ── Priority / status helpers ──────────────────────────────────────────────
  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high': return Colors.redAccent;
      case 'medium': return _accentOrange;
      default: return _accentGreen;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'in-progress': return _accentOrange;
      case 'completed': return _accentGreen;
      case 'cancelled': return Colors.grey;
      default: return Colors.blueAccent;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'in-progress': return 'In Progress';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return 'Todo';
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

    await showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, ss) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (_, scroll) => Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                children: [
                  // ── Header ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
                    child: Row(
                      children: [
                        Container(
                            width: 40, height: 4,
                            decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(2))),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(task['title'] ?? 'Task',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ),
                        // Edit button
                        IconButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showEditTaskDialog(task);
                          },
                          icon: Icon(Icons.edit_outlined,
                              color: _accentPink, size: 20),
                          tooltip: 'Edit task',
                        ),
                        // Delete button (only if allowed)
                        if (canDelete)
                          IconButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _deleteTask(task['_id'].toString());
                            },
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent, size: 20),
                            tooltip: 'Delete task',
                          ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close,
                              color: Colors.white38, size: 20),
                        ),
                      ],
                    ),
                  ),
                  // ── Scrollable body ──────────────────────────────────
                  Expanded(
                    child: ListView(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      children: [
                        // Description
                        if ((task['description'] ?? '').toString().isNotEmpty) ...[
                          Text(task['description'].toString(),
                              style: TextStyle(
                                  color: _textGrey, fontSize: 13, height: 1.5)),
                          const SizedBox(height: 16),
                        ],
                        // Due date + assigned by
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                color: _textGrey, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              task['dueDate'] != null
                                  ? _formatDate(task['dueDate'])
                                  : 'No due date',
                              style:
                                  TextStyle(color: _textGrey, fontSize: 13),
                            ),
                            if (task['assignedBy'] is Map) ...[
                              const SizedBox(width: 16),
                              Icon(Icons.person_outline,
                                  color: _textGrey, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                (task['assignedBy']['name'] ?? 'Manager')
                                    .toString(),
                                style: TextStyle(
                                    color: _textGrey, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 16),

                        // ── Status ─────────────────────────────────────
                        _inputLabel('Status'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['todo', 'in-progress', 'completed',
                                  'cancelled']
                              .map((s) => ChoiceChip(
                                    label: Text(_statusLabel(s)),
                                    selected: selectedStatus == s,
                                    onSelected: (_) =>
                                        ss(() => selectedStatus = s),
                                    selectedColor:
                                        _statusColor(s).withOpacity(0.22),
                                    backgroundColor: _inputDark,
                                    labelStyle: TextStyle(
                                        color: selectedStatus == s
                                            ? _statusColor(s)
                                            : _textGrey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                    side: BorderSide(
                                        color: selectedStatus == s
                                            ? _statusColor(s)
                                            : Colors.transparent),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),

                        // ── Progress ──────────────────────────────────
                        Row(
                          children: [
                            _inputLabel('Progress'),
                            const Spacer(),
                            Text('${progress.toInt()}%',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: progress,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          activeColor: _accentPink,
                          inactiveColor: _inputDark,
                          onChanged: (v) => ss(() => progress = v),
                        ),

                        // ── Sub-tasks ─────────────────────────────────
                        if (subTasks.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 12),
                          _inputLabel('Sub-tasks (${subTasks.where((s) => s['completed'] == true).length}/${subTasks.length})'),
                          const SizedBox(height: 10),
                          ...subTasks.map((sub) {
                            final subId = sub['_id']?.toString() ?? '';
                            final done = sub['completed'] == true;
                            return GestureDetector(
                              onTap: () async {
                                ss(() => sub['completed'] = !done);
                                await _toggleSubTask(
                                    task['_id'].toString(),
                                    subId,
                                    !done);
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _inputDark,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  border: Border.all(
                                      color: done
                                          ? _accentGreen.withOpacity(
                                              0.3)
                                          : Colors.transparent),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      done
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: done
                                          ? _accentGreen
                                          : _textGrey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        sub['title']?.toString() ??
                                            '',
                                        style: TextStyle(
                                          color: done
                                              ? _textGrey
                                              : Colors.white,
                                          fontSize: 13,
                                          decoration: done
                                              ? TextDecoration
                                                  .lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],

                        // ── Notes ─────────────────────────────────────
                        if ((task['notes'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 12),
                          _inputLabel('Notes'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _inputDark,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(task['notes'].toString(),
                                style: TextStyle(
                                    color: _textGrey,
                                    fontSize: 13,
                                    height: 1.5)),
                          ),
                        ],

                        const SizedBox(height: 20),
                        // ── Update button ─────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentPink,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              // Set appropriate progress based on status
                              int finalProgress = progress.toInt();
                              if (selectedStatus == 'completed') {
                                finalProgress = 100;
                              } else if (selectedStatus == 'todo' && finalProgress == 100) {
                                finalProgress = 0;
                              }
                              await _updateProgress(
                                  task['_id'].toString(),
                                  selectedStatus,
                                  finalProgress);
                            },
                            child: const Text('Save Changes',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _updateProgress(String taskId, String status, int progress) async {
    if (_token == null) return;
    try {
      await TaskService.updateTaskProgress(_token!, taskId,
          status: status, completionPercentage: progress);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Task updated!'),
            backgroundColor: _accentGreen,
            duration: const Duration(seconds: 2)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteTask(String taskId) async {
    if (_token == null) return;
    // Confirm before deleting
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardDark,
        title: const Text('Delete Task',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        content: const Text('Are you sure you want to delete this task?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _textGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await TaskService.deleteTask(_token!, taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Task deleted'),
            backgroundColor: _accentGreen,
            duration: const Duration(seconds: 2)));
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _toggleSubTask(
      String taskId, String subTaskId, bool markDone) async {
    if (_token == null) return;
    try {
      await TaskService.updateSubTask(_token!, taskId, subTaskId,
          status: markDone ? 'completed' : 'todo');
      _loadData();
    } catch (_) {}
  }

  // ── Edit task dialog ──────────────────────────────────────────────────────
  Future<void> _showEditTaskDialog(Map<String, dynamic> task) async {
    final titleCtrl =
        TextEditingController(text: task['title']?.toString() ?? '');
    final descCtrl =
        TextEditingController(text: task['description']?.toString() ?? '');
    String selectedPriority =
        (task['priority'] ?? 'medium').toString().toLowerCase();
    DateTime? selectedDueDate;
    if (task['dueDate'] != null) {
      try {
        selectedDueDate = DateTime.parse(task['dueDate'].toString()).toLocal();
      } catch (_) {}
    }
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, ss) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24, right: 24, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Edit Task',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close,
                              color: Colors.white54, size: 20)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _inputLabel('Task Title *'),
                  const SizedBox(height: 8),
                  _inputField(
                      controller: titleCtrl,
                      hint: 'Task title',
                      ctx: ctx),
                  const SizedBox(height: 16),
                  _inputLabel('Description'),
                  const SizedBox(height: 8),
                  _inputField(
                      controller: descCtrl,
                      hint: 'Description...',
                      maxLines: 3,
                      ctx: ctx),
                  const SizedBox(height: 16),
                  _inputLabel('Priority'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: ['low', 'medium', 'high'].map((p) {
                      final color = _priorityColor(p);
                      final sel = selectedPriority == p;
                      return ChoiceChip(
                        label: Text(p[0].toUpperCase() + p.substring(1),
                            style: TextStyle(
                                color: sel ? color : _textGrey,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        selected: sel,
                        onSelected: (_) => ss(() => selectedPriority = p),
                        selectedColor: color.withOpacity(0.18),
                        backgroundColor: _inputDark,
                        side: BorderSide(
                            color: sel ? color : Colors.transparent),
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
                        initialDate: selectedDueDate ??
                            DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 365)),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 365)),
                        builder: (_, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: ColorScheme.dark(
                                primary: _accentPink,
                                surface: _cardDark),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) ss(() => selectedDueDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _inputDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.07)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              color: _textGrey, size: 16),
                          const SizedBox(width: 10),
                          Text(
                            selectedDueDate != null
                                ? DateFormat('MMM d, y')
                                    .format(selectedDueDate!)
                                : 'Select due date',
                            style: TextStyle(
                                color: selectedDueDate != null
                                    ? Colors.white
                                    : _textGrey.withOpacity(0.6),
                                fontSize: 14),
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
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: submitting
                          ? null
                          : () async {
                              if (titleCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Title is required'),
                                        backgroundColor: Colors.red));
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
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Task updated!'),
                                      backgroundColor: _accentGreen,
                                      duration: const Duration(seconds: 2)));
                                  _loadData();
                                }
                              } catch (e) {
                                if (ctx.mounted) ss(() => submitting = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString().replaceAll('Exception: ', '')),
                                      backgroundColor: Colors.red));
                                }
                              }
                            },
                      icon: submitting
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.save_outlined, size: 20),
                      label: Text(
                          submitting ? 'Saving...' : 'Save Changes',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          );
        });
      },
    );

    titleCtrl.dispose();
    descCtrl.dispose();
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
      _token!, taskId,
      title: title,
      description: description.isEmpty ? null : description,
      priority: priority,
      dueDate: dueDate != null
          ? DateFormat('yyyy-MM-dd').format(dueDate)
          : null,
    );
  }

  // ── Create Task ───────────────────────────────────────────────────────────
  Future<void> _showCreateTaskDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedPriority = 'medium';
    DateTime? selectedDueDate;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, ss) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24, right: 24, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Create Task',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close,
                              color: Colors.white54, size: 20)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Title
                  _inputLabel('Task Title *'),
                  const SizedBox(height: 8),
                  _inputField(
                      controller: titleCtrl,
                      hint: 'e.g. Fix login bug',
                      ctx: ctx),
                  const SizedBox(height: 16),

                  // Description
                  _inputLabel('Description'),
                  const SizedBox(height: 8),
                  _inputField(
                      controller: descCtrl,
                      hint: 'Brief description...',
                      maxLines: 3,
                      ctx: ctx),
                  const SizedBox(height: 16),

                  // Priority
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
                                fontWeight: FontWeight.w600)),
                        selected: selected,
                        onSelected: (_) => ss(() => selectedPriority = p),
                        selectedColor: color.withOpacity(0.18),
                        backgroundColor: _inputDark,
                        side: BorderSide(
                            color: selected ? color : Colors.transparent),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Due Date
                  _inputLabel('Due Date'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      // Use the parent screen context to avoid InheritedWidget
                      // dependency assertion when the date picker closes.
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                            const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 365)),
                        builder: (_, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: ColorScheme.dark(
                                primary: _accentPink,
                                surface: _cardDark),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) ss(() => selectedDueDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _inputDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.07)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              color: _textGrey, size: 16),
                          const SizedBox(width: 10),
                          Text(
                            selectedDueDate != null
                                ? DateFormat('MMM d, y').format(selectedDueDate!)
                                : 'Select due date',
                            style: TextStyle(
                                color: selectedDueDate != null
                                    ? Colors.white
                                    : _textGrey.withOpacity(0.6),
                                fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentPink,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: submitting
                          ? null
                          : () async {
                              if (titleCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Title is required'),
                                        backgroundColor: Colors.red));
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
                                // Pop the sheet BEFORE triggering setState/_loadData
                                // to avoid InheritedWidget dispose assertion.
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Task created successfully!'),
                                      backgroundColor: _accentGreen));
                                  _loadData();
                                }
                              } catch (e) {
                                if (ctx.mounted) ss(() => submitting = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString().replaceAll('Exception: ', '')),
                                      backgroundColor: Colors.red));
                                }
                              }
                            },
                      icon: submitting
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.add, size: 20),
                      label: Text(
                          submitting ? 'Creating...' : 'Create Task',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          );
        });
      },
    );

    titleCtrl.dispose();
    descCtrl.dispose();
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
          : DateFormat('yyyy-MM-dd')
              .format(DateTime.now().add(const Duration(days: 7))),
      assignedTo: assignTo,
    );
  }

  // ── Input helpers ──────────────────────────────────────────────────────────
  Widget _inputLabel(String text) => Text(text,
      style: TextStyle(
          color: _textGrey, fontSize: 12, fontWeight: FontWeight.w600));

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required BuildContext ctx,
    int maxLines = 1,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: _inputDark,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            hintText: hint,
            hintStyle:
                TextStyle(color: _textGrey.withOpacity(0.5), fontSize: 14),
          ),
        ),
      );

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return Column(
            children: [
              _buildHeader(context, isMobile),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: _accentPink))
                    : _error != null
                        ? _buildError()
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSearchBar(),
                                const SizedBox(height: 24),
                                isMobile
                                    ? _buildMobileStats()
                                    : _buildDesktopStats(),
                                const SizedBox(height: 28),
                                _buildTabBar(),
                                const SizedBox(height: 24),
                                _buildTaskList(),
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
              ),
            ],
          );
        }),
      ),
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
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textGrey, fontSize: 14)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _accentPink,
                    foregroundColor: Colors.black),
              ),
            ],
          ),
        ),
      );

  Widget _buildHeader(BuildContext context, bool isMobile) => Padding(
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
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Tasks',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Text(DateFormat('MMM dd, y').format(DateTime.now()),
                      style: TextStyle(color: _textGrey, fontSize: 13)),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showCreateTaskDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Task',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentPink,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                elevation: 0,
              ),
            ),
          ],
        ),
      );

  Widget _buildSearchBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _inputDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: TextField(
          style: const TextStyle(color: Colors.white),
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search tasks...',
            hintStyle: TextStyle(color: _textGrey.withOpacity(0.5)),
            icon: Icon(Icons.search, color: _textGrey),
          ),
        ),
      );

  Widget _buildDesktopStats() => Row(
        children: [
          Expanded(child: _buildStatCard('Total',
              '${_stats['total'] ?? _tasks.length}', Icons.folder_open, _accentPurple)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('In Progress',
              '${_stats['inProgress'] ?? 0}', Icons.timer, _accentOrange)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('Completed',
              '${_stats['completed'] ?? 0}', Icons.check_circle, _accentGreen)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('Overdue',
              '${_stats['overdue'] ?? 0}', Icons.warning_amber_rounded, Colors.redAccent)),
        ],
      );

  Widget _buildMobileStats() => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: [
          _buildStatCard('Total',
              '${_stats['total'] ?? _tasks.length}', Icons.folder_open, _accentPurple),
          _buildStatCard('In Progress',
              '${_stats['inProgress'] ?? 0}', Icons.timer, _accentOrange),
          _buildStatCard('Completed',
              '${_stats['completed'] ?? 0}', Icons.check_circle, _accentGreen),
          _buildStatCard('Overdue',
              '${_stats['overdue'] ?? 0}', Icons.warning_amber_rounded, Colors.redAccent),
        ],
      );

  Widget _buildStatCard(String label, String count, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(count,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.2), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            Text(label,
                style: TextStyle(
                    color: _textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _buildTabBar() => Container(
        height: 45,
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white10),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
              color: _accentPink, borderRadius: BorderRadius.circular(25)),
          labelColor: Colors.black,
          unselectedLabelColor: _textGrey,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          padding: const EdgeInsets.all(4),
          tabs: [
            Tab(text: 'All (${_tasks.length})'),
            Tab(text: 'Todo (${_stats['todo'] ?? 0})'),
            Tab(text: 'In Progress (${_stats['inProgress'] ?? 0})'),
            Tab(text: 'Done (${_stats['completed'] ?? 0})'),
          ],
        ),
      );

  Widget _buildTaskList() {
    final list = _filteredTasks;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Column(
            children: [
              Icon(Icons.assignment_outlined, size: 48, color: _textGrey.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text('No tasks found',
                  style: TextStyle(color: _textGrey, fontSize: 14)),
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
      direction: canDelete ? DismissDirection.endToStart : DismissDirection.none,
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
                      title: const Text('Delete Task',
                          style: TextStyle(color: Colors.white, fontSize: 17)),
                      content: const Text(
                          'Are you sure you want to delete this task?',
                          style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel',
                              style: TextStyle(color: _textGrey)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.redAccent)),
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
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 5, color: priorityColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Priority chip + status badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: priorityColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                priority[0].toUpperCase() + priority.substring(1),
                                style: TextStyle(
                                    color: priorityColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.edit_outlined,
                                color: _textGrey.withOpacity(0.5), size: 18),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Title
                        Text(
                          task['title'] ?? '—',
                          style: TextStyle(
                            color: isCompleted
                                ? _textGrey
                                : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if ((task['description'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            task['description'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: _textGrey, fontSize: 12, height: 1.4),
                          ),
                        ],
                        const SizedBox(height: 14),
                        // Progress bar (not shown for completed/cancelled)
                        if (!isCompleted && status != 'cancelled') ...[
                          Row(
                            children: [
                              Text('Progress',
                                  style: TextStyle(
                                      color: _textGrey, fontSize: 11)),
                              const Spacer(),
                              Text('${progress.toInt()}%',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              minHeight: 6,
                              backgroundColor: Colors.black,
                              color: priorityColor,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        // Due date + assigned by
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                color: _textGrey, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              task['dueDate'] != null
                                  ? _formatDate(task['dueDate'])
                                  : 'No due date',
                              style: TextStyle(
                                  color: _textGrey,
                                  fontSize: 12),
                            ),
                            const Spacer(),
                            if (task['assignedBy'] != null &&
                                task['assignedBy'] is Map) ...[
                              Icon(Icons.person_outline,
                                  color: _textGrey, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                (task['assignedBy']['name'] ?? 'Manager')
                                    .toString()
                                    .split(' ')
                                    .first,
                                style: TextStyle(
                                    color: _textGrey, fontSize: 12),
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
    ),  // closes GestureDetector (child of Dismissible)
  );    // closes Dismissible
  }
}

