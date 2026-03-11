import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/token_storage_service.dart';

// ──────────────────────────────────────────────────────────────────────────────
// BOD (Beginning of Day) — Plan Your Tasks
// Shown AFTER a successful check-in. Non-blocking: user can skip.
// ──────────────────────────────────────────────────────────────────────────────

class BODBottomSheet extends StatefulWidget {
  const BODBottomSheet({super.key});

  @override
  State<BODBottomSheet> createState() => _BODBottomSheetState();
}

class _BODBottomSheetState extends State<BODBottomSheet> {
  final List<_TaskRow> _tasks = [_TaskRow()];
  bool _submitting = false;

  void _addTask() {
    if (_tasks.length < 10) {
      setState(() => _tasks.add(_TaskRow()));
    }
  }

  void _removeTask(int index) {
    if (_tasks.length > 1) {
      setState(() => _tasks.removeAt(index));
    }
  }

  Future<void> _submit() async {
    // Validate: at least one task must have title, description, and estimated time
    final tasksWithTitle = _tasks.where((t) => t.titleCtrl.text.trim().isNotEmpty).toList();
    
    if (tasksWithTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one task title'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if any task is missing required fields (description and estimated time)
    final incompleteTasks = tasksWithTitle.where((t) {
      final hasDescription = t.descCtrl.text.trim().isNotEmpty;
      final hasEstimatedTime = t.estimatedType == 'before-lunch' || 
          t.estimatedType == 'evening' || 
          (t.estimatedType == 'custom' && (double.tryParse(t.hoursCtrl.text) ?? 0) > 0);
      return !hasDescription || !hasEstimatedTime;
    }).toList();

    if (incompleteTasks.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Description and Estimated Time are required for each task'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final token = await TokenStorageService().getToken();
      if (token == null) throw Exception('No token');

      final baseUrl = ApiConfig.baseUrl;
      print('[BOD] Base URL: $baseUrl');
      final today = DateTime.now();
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 0);
      final dueDate = endOfDay.toIso8601String();
      final bodDate = today.toIso8601String();

      final futures = _tasks
          .where((t) => t.titleCtrl.text.trim().isNotEmpty)
          .map((t) {
            int estimatedMinutes = 0;
            switch (t.estimatedType) {
              case 'before-lunch':
                estimatedMinutes = 240;
                break;
              case 'evening':
                estimatedMinutes = 480;
                break;
              default:
                final hours = double.tryParse(t.hoursCtrl.text) ?? 0;
                estimatedMinutes = (hours * 60).round();
            }

            final body = {
              'title': t.titleCtrl.text.trim(),
              'description': t.descCtrl.text.trim().isNotEmpty
                  ? t.descCtrl.text.trim()
                  : t.titleCtrl.text.trim(),
              'priority': 'medium',
              'dueDate': dueDate,
              'isBODTask': true,
              'bodDate': bodDate,
              if (estimatedMinutes > 0) 'estimatedTime': estimatedMinutes,
            };

            return http
                .post(
                  Uri.parse('$baseUrl/tasks'),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode(body),
                )
                .timeout(const Duration(seconds: 10));
          });

      await Future.wait(futures, eagerError: false);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Day tasks saved!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      // BOD task creation failed — still proceed with check-in (non-blocking)
      if (mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    for (final t in _tasks) {
      t.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.wb_sunny_rounded,
                      color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Beginning of Day',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Add the tasks you plan to work on today. These will appear as your daily goals.',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),

          Divider(color: Colors.white.withOpacity(0.07), height: 1),

          // Task list
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (int i = 0; i < _tasks.length; i++) ...[
                    _buildTaskRow(i),
                    if (i < _tasks.length - 1) const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                  if (_tasks.length < 10)
                    OutlinedButton.icon(
                      onPressed: _addTask,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Another Task'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                            color: Colors.white.withOpacity(0.2)),
                        minimumSize: const Size.fromHeight(40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Footer buttons
          Divider(color: Colors.white.withOpacity(0.07), height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.checklist_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Start My Day (${_tasks.where((t) => t.titleCtrl.text.trim().isNotEmpty).length} task${_tasks.where((t) => t.titleCtrl.text.trim().isNotEmpty).length != 1 ? 's' : ''})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(int index) {
    final task = _tasks[index];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Task ${index + 1}',
                  style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              if (_tasks.length > 1)
                GestureDetector(
                  onTap: () => _removeTask(index),
                  child: const Icon(Icons.close,
                      color: Colors.redAccent, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Title field
          _buildField(
            controller: task.titleCtrl,
            hint: 'What will you work on?',
            label: 'Task Title *',
          ),
          const SizedBox(height: 8),
          // Description field
          _buildField(
            controller: task.descCtrl,
            hint: 'Brief notes...',
            label: 'Description *',
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          // Estimated time
          Text('Estimated Time *',
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          StatefulBuilder(
            builder: (ctx, setLocal) => Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: task.estimatedType,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF2A2A2A),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                      items: const [
                        DropdownMenuItem(
                            value: 'custom',
                            child: Text('Custom Hours')),
                        DropdownMenuItem(
                            value: 'before-lunch',
                            child: Text('Before Lunch (~4h)')),
                        DropdownMenuItem(
                            value: 'evening',
                            child: Text('Evening of Day (~8h)')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => task.estimatedType = v);
                        }
                      },
                    ),
                  ),
                ),
                if (task.estimatedType == 'custom') ...[
                  const SizedBox(height: 6),
                  _buildField(
                    controller: task.hoursCtrl,
                    hint: 'e.g. 2',
                    label: 'Hours',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: Colors.amber.withOpacity(0.6)),
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskRow {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final hoursCtrl = TextEditingController();
  String estimatedType = 'custom';

  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    hoursCtrl.dispose();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// EOD (End of Day) — Review Before Check-Out
// Shown BEFORE check-out. User must interact (confirm or skip) to proceed.
// ──────────────────────────────────────────────────────────────────────────────

class EODBottomSheet extends StatefulWidget {
  const EODBottomSheet({super.key});

  @override
  State<EODBottomSheet> createState() => _EODBottomSheetState();
}

class _EODBottomSheetState extends State<EODBottomSheet> {
  bool _loading = true;
  bool _submitting = false;
  List<_EODTask> _tasks = [];
  List<_NewEODTask> _newTasks = [];

  static const List<Map<String, dynamic>> _statusOptions = [
    {'value': 'completed', 'label': '✅ Completed'},
    {'value': 'in-progress', 'label': '🔄 In Progress'},
    {'value': 'not-done', 'label': '⭕ Not Done'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTodayBODTasks();
  }

  @override
  void dispose() {
    for (final t in _newTasks) {
      t.dispose();
    }
    super.dispose();
  }

  void _addNewTask() {
    setState(() => _newTasks.add(_NewEODTask()));
  }

  void _removeNewTask(int index) {
    final task = _newTasks.removeAt(index);
    task.dispose();
    setState(() {});
  }

  Future<void> _submitEOD() async {
    setState(() => _submitting = true);

    try {
      final token = await TokenStorageService().getToken();
      if (token == null) throw Exception('No token');

      final baseUrl = ApiConfig.baseUrl;

      // Update task statuses for tasks that changed
      final statusUpdates = _tasks
          .where((t) => t.eodStatus == 'completed' && t.status != 'completed')
          .map((t) async {
        try {
          await http
              .put(
                Uri.parse('$baseUrl/tasks/${t.id}'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({'status': 'completed', 'progress': 100}),
              )
              .timeout(const Duration(seconds: 8));
        } catch (_) {}
      });

      // Add EOD notes as comments where provided
      final noteUpdates = _tasks
          .where((t) => t.notes.trim().isNotEmpty)
          .map((t) async {
        try {
          await http
              .post(
                Uri.parse('$baseUrl/tasks/${t.id}/comments'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({'content': '[EOD Note] ${t.notes.trim()}'}),
              )
              .timeout(const Duration(seconds: 8));
        } catch (_) {}
      });

      // Create new tasks added during EOD
      final today = DateTime.now();
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 0);
      final dueDate = endOfDay.toIso8601String();
      final bodDate = today.toIso8601String();

      final newTaskCreations = _newTasks
          .where((t) => t.titleCtrl.text.trim().isNotEmpty)
          .map((t) async {
        try {
          await http
              .post(
                Uri.parse('$baseUrl/tasks'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({
                  'title': t.titleCtrl.text.trim(),
                  'description': t.descCtrl.text.trim().isNotEmpty
                      ? t.descCtrl.text.trim()
                      : t.titleCtrl.text.trim(),
                  'priority': 'medium',
                  'dueDate': dueDate,
                  'isBODTask': true,
                  'bodDate': bodDate,
                  'status': 'completed',
                  'progress': 100,
                }),
              )
              .timeout(const Duration(seconds: 8));
        } catch (_) {}
      });

      // Wait for all updates (non-blocking - proceed even on failures)
      await Future.wait([
        ...statusUpdates,
        ...noteUpdates,
        ...newTaskCreations,
      ], eagerError: false);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      // Non-blocking — proceed to checkout even if updates fail
      if (mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _loadTodayBODTasks() async {
    try {
      final token = await TokenStorageService().getToken();
      if (token == null) throw Exception('No token');

      final baseUrl = ApiConfig.baseUrl;
      final today = DateTime.now();
      final startOfDay =
          DateTime(today.year, today.month, today.day).toIso8601String();
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59)
          .toIso8601String();

      print('[EOD] Base URL: $baseUrl');
      final uri = Uri.parse('$baseUrl/tasks').replace(queryParameters: {
        'isBODTask': 'true',
        'dueAfter': startOfDay,
        'dueBefore': endOfDay,
        'limit': '20',
      });

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Safe type extraction — guard against unexpected response shapes
        final rawData = decoded is Map ? decoded['data'] : null;
        final data = rawData is List ? rawData as List<dynamic> : <dynamic>[];
        if (mounted) {
          setState(() {
            _tasks = data
                .map((t) {
                  if (t is! Map) return null;
                  return _EODTask(
                    id: t['_id']?.toString() ?? '',
                    title: t['title']?.toString() ?? '',
                    status: t['status']?.toString() ?? 'pending',
                  );
                })
                .whereType<_EODTask>()
                .toList();
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.nightlight_round,
                      color: Colors.blueAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End of Day',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'How did today go?',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),

          Divider(color: Colors.white.withOpacity(0.07), height: 1),

          // Task review list
          Flexible(
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(color: Colors.white54),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Existing BOD tasks
                        if (_tasks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      color: Colors.grey[700], size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No BOD tasks for today',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          for (int i = 0; i < _tasks.length; i++) ...[
                            _buildTaskItem(i),
                            if (i < _tasks.length - 1) const SizedBox(height: 8),
                          ],
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // Add new tasks section
                        for (int i = 0; i < _newTasks.length; i++) ...[
                          _buildNewTaskRow(i),
                          const SizedBox(height: 8),
                        ],
                        
                        // Add task button
                        OutlinedButton.icon(
                          onPressed: _addNewTask,
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add Task Not in BOD'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            minimumSize: const Size.fromHeight(36),
                            textStyle: const TextStyle(fontSize: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        
                        // Summary bar
                        if (_tasks.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildSummaryBar(),
                        ],
                      ],
                    ),
                  ),
          ),

          // Footer buttons
          Divider(color: Colors.white.withOpacity(0.07), height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[400],
                      side: BorderSide(color: Colors.white.withOpacity(0.15)),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submitEOD,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300),
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black87,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.nightlight_round, size: 18),
                              SizedBox(width: 6),
                              Text('End My Day',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(int index) {
    final task = _tasks[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _eodStatusIcon(task.eodStatus),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Status dropdown and notes field in a row on larger screens
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: task.eodStatus,
                            isExpanded: true,
                            isDense: true,
                            dropdownColor: const Color(0xFF2A2A2A),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                            items: _statusOptions
                                .map((o) => DropdownMenuItem(
                                      value: o['value'] as String,
                                      child: Text(o['label'] as String),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _tasks[index].eodStatus = v);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => _tasks[index].notes = v,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11),
                        decoration: InputDecoration(
                          hintText: 'Notes (optional)...',
                          hintStyle: TextStyle(
                              color: Colors.grey[600], fontSize: 11),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                                color: Colors.blueAccent.withOpacity(0.6)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eodStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return const Icon(Icons.check_circle_rounded,
            color: Colors.greenAccent, size: 20);
      case 'in-progress':
        return const Icon(Icons.pending_rounded,
            color: Colors.blueAccent, size: 20);
      default:
        return Icon(Icons.circle_outlined, color: Colors.grey[600], size: 20);
    }
  }

  Widget _buildNewTaskRow(int index) {
    final task = _newTasks[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'New Task ${index + 1}',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _removeNewTask(index),
                child: const Icon(Icons.close, color: Colors.redAccent, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Title field
          Text('Task Title *',
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TextField(
            controller: task.titleCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'What did you work on?',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.6)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Description field
          Text('Description',
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TextField(
            controller: task.descCtrl,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Brief notes...',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    final completed = _tasks.where((t) => t.eodStatus == 'completed').length;
    final inProgress = _tasks.where((t) => t.eodStatus == 'in-progress').length;
    final notDone = _tasks.where((t) => t.eodStatus == 'not-done').length;

    return Row(
      children: [
        Text(
          '✅ $completed done',
          style: const TextStyle(
            color: Colors.greenAccent,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '🔄 $inProgress in progress',
          style: const TextStyle(
            color: Colors.blueAccent,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '⭕ $notDone not done',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _EODTask {
  final String id;
  final String title;
  String status;
  String eodStatus = 'not-done';
  String notes = '';

  _EODTask({
    required this.id,
    required this.title,
    required this.status,
  }) {
    // Set initial eodStatus based on backend status
    if (status == 'completed') {
      eodStatus = 'completed';
    }
  }
}

class _NewEODTask {
  final String id;
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  _NewEODTask() : id = DateTime.now().millisecondsSinceEpoch.toString();

  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
  }
}
