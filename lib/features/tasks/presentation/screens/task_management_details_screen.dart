import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hrms_app/features/tasks/data/services/task_management_service.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';

class TaskManagementDetailsScreen extends StatefulWidget {
  final String entryId;
  final String token;

  const TaskManagementDetailsScreen({
    super.key,
    required this.entryId,
    required this.token,
  });

  @override
  State<TaskManagementDetailsScreen> createState() =>
      _TaskManagementDetailsScreenState();
}

class _TaskManagementDetailsScreenState
    extends State<TaskManagementDetailsScreen> {
  // ─── Theme Colors ───────────────────────────────────────────────────────────
  static const Color _bg = AppTheme.background;
  static const Color _card = AppTheme.surface;
  static const Color _input = AppTheme.surfaceVariant;
  static const Color _border = AppTheme.outline;
  static const Color _primary = AppTheme.primaryColor;
  static const Color _green = AppTheme.secondaryColor;
  static const Color _textLight = AppTheme.onBackground;
  static const Color _textGrey = Color(0xFF8E8E93);

  TaskManagementEntry? _entry;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  late List<TaskManagementTaskItem> _tasks;
  late List<String> _sections;
  late List<String> _statuses;

  int? _editingTaskIndex;
  TextEditingController? _editTitleController;
  TextEditingController? _editDescController;
  TextEditingController? _editTimeController;
  String? _editingStatus;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  @override
  void dispose() {
    _editTitleController?.dispose();
    _editDescController?.dispose();
    _editTimeController?.dispose();
    super.dispose();
  }

  Future<void> _loadEntry() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final entry = await TaskManagementService.getEntryById(
        widget.token,
        widget.entryId,
      );

      if (!mounted) return;

      setState(() {
        _entry = entry;
        _tasks = entry.tasks
            .map(
              (task) => TaskManagementTaskItem(
                id: task.id,
                title: task.title,
                description: task.description,
                estimatedTime: task.estimatedTime,
                status: _normalizeStatus(task.status),
                section: task.section,
              ),
            )
            .toList();
        _sections = entry.sections.isNotEmpty
            ? List.from(entry.sections)
            : ['General'];
        _statuses = ['Doing', 'In Review', 'Completed'];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _startEditTask(int index) {
    setState(() {
      _editingTaskIndex = index;
      _editTitleController = TextEditingController(text: _tasks[index].title);
      _editDescController = TextEditingController(
        text: _tasks[index].description,
      );
      _editTimeController = TextEditingController(
        text: _tasks[index].estimatedTime ?? '',
      );
      _editingStatus = _normalizeStatus(_tasks[index].status);
    });
  }

  String _normalizeStatus(String rawStatus) {
    final normalized = rawStatus.trim().toLowerCase();

    if (normalized == 'completed' ||
        normalized == 'completed task' ||
        normalized == 'done') {
      return 'Completed';
    }

    if (normalized == 'in review' || normalized == 'review') {
      return 'In Review';
    }

    if (normalized == 'doing' ||
        normalized == 'in progress' ||
        normalized == 'in-progress' ||
        normalized == 'pending') {
      return 'Doing';
    }

    return 'Doing';
  }

  void _cancelEditTask() {
    setState(() {
      _editingTaskIndex = null;
      _editTitleController?.dispose();
      _editDescController?.dispose();
      _editTimeController?.dispose();
      _editTitleController = null;
      _editDescController = null;
      _editTimeController = null;
      _editingStatus = null;
    });
  }

  Future<void> _saveEditTask(int index) async {
    setState(() {
      _tasks[index] = TaskManagementTaskItem(
        id: _tasks[index].id,
        title: _editTitleController?.text ?? '',
        description: _editDescController?.text ?? '',
        estimatedTime: _editTimeController?.text ?? '',
        status: _editingStatus ?? 'Doing',
        section: _tasks[index].section,
      );
      _editingTaskIndex = null;
    });
    _editTitleController?.dispose();
    _editDescController?.dispose();
    _editTimeController?.dispose();
    _editTitleController = null;
    _editDescController = null;
    _editTimeController = null;
    _editingStatus = null;
  }

  void _addTask(String section) {
    setState(() {
      _tasks.add(
        TaskManagementTaskItem(
          id: '',
          title: '',
          description: '',
          estimatedTime: '',
          status: 'Doing',
          section: section,
        ),
      );
    });
  }

  Future<void> _removeTask(int index) async {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  bool _hasValidationErrors() {
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].title.trim().isEmpty) {
        return true;
      }
    }
    return false;
  }

  Future<void> _saveAllChanges() async {
    if (_entry == null) return;

    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].title.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task ${i + 1}: Title is required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      setState(() => _saving = true);

      final success = await TaskManagementService.updateEntry(
        widget.token,
        _entry!.id,
        tasks: _tasks,
        sections: _sections,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully')),
        );
        _loadEntry();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _entry?.employeeName ?? 'Task Details',
          style: const TextStyle(
            color: _textLight,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_loading && _entry != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Tooltip(
                message: _hasValidationErrors()
                    ? 'All tasks must have a title'
                    : 'Save all changes',
                child: ElevatedButton.icon(
                  onPressed: _saving || _hasValidationErrors()
                      ? null
                      : _saveAllChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('Save'),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
          ? _buildError()
          : _entry == null
          ? const Center(child: Text('Entry not found'))
          : RefreshIndicator(
              onRefresh: _loadEntry,
              color: _primary,
              child: ListView(
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                children: [
                  // Entry Header Card
                  Container(
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _border.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    padding: EdgeInsets.all(isMobile ? 14 : 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _entry!.employeeName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _textLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: _textGrey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _entry!.date,
                                    style: const TextStyle(
                                      color: _textGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _entry!.type,
                            style: TextStyle(
                              color: _primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tasks Card
                  Container(
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _border.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: EdgeInsets.all(isMobile ? 14 : 20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.assignment_rounded,
                                  color: _primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tasks',
                                    style: TextStyle(
                                      color: _textLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${_tasks.length} task${_tasks.length != 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      color: _textGrey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Tasks list
                        if (_tasks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'No tasks added',
                                style: TextStyle(
                                  color: _textGrey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _tasks.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: _border,
                              indent: 20,
                              endIndent: 20,
                            ),
                            itemBuilder: (context, index) {
                              final task = _tasks[index];
                              final isEditing = _editingTaskIndex == index;

                              return Padding(
                                padding: EdgeInsets.all(isMobile ? 12 : 16),
                                child: isEditing
                                    ? _buildTaskEditForm(index)
                                    : _buildTaskViewMode(task, index),
                              );
                            },
                          ),

                        // Add task button
                        Padding(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _addTask('General');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _card,
                              foregroundColor: _primary,
                              elevation: 0,
                              side: BorderSide(
                                color: _primary.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Task'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: _textGrey),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textGrey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskViewMode(TaskManagementTaskItem task, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: _textLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      task.description,
                      style: const TextStyle(color: _textGrey, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    task.status,
                    style: TextStyle(
                      color: _primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (task.estimatedTime.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: _textGrey),
                  const SizedBox(width: 6),
                  Text(
                    '${task.estimatedTime}h',
                    style: const TextStyle(color: _textGrey, fontSize: 11),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: () => _startEditTask(index),
                  style: TextButton.styleFrom(
                    foregroundColor: _primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _removeTask(index),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.delete_rounded, size: 16),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskEditForm(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        TextFormField(
          controller: _editTitleController,
          style: const TextStyle(color: _textLight),
          decoration: InputDecoration(
            labelText: 'Task Title *',
            labelStyle: TextStyle(color: _textGrey, fontSize: 12),
            filled: true,
            fillColor: _input,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _border.withOpacity(0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Description
        TextFormField(
          controller: _editDescController,
          style: const TextStyle(color: _textLight),
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Description',
            labelStyle: TextStyle(color: _textGrey, fontSize: 12),
            filled: true,
            fillColor: _input,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _border.withOpacity(0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Estimated Time and Status
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _editTimeController,
                style: const TextStyle(color: _textLight),
                decoration: InputDecoration(
                  labelText: 'Est. Time (hours)',
                  labelStyle: TextStyle(color: _textGrey, fontSize: 12),
                  filled: true,
                  fillColor: _input,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _border.withOpacity(0.6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildStatusPicker()),
          ],
        ),
        const SizedBox(height: 12),
        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 8,
          children: [
            TextButton(
              onPressed: _cancelEditTask,
              style: TextButton.styleFrom(foregroundColor: _textGrey),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveEditTask(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusPicker() {
    final selectedStatus = _statuses.contains(_editingStatus)
        ? _editingStatus
        : 'Doing';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _input,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border.withOpacity(0.6)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedStatus,
          dropdownColor: _card,
          style: const TextStyle(color: _textLight, fontSize: 13),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _textGrey,
            size: 18,
          ),
          items: [
            // Existing statuses
            ..._statuses.map(
              (status) => DropdownMenuItem(value: status, child: Text(status)),
            ),
            // Divider
            const DropdownMenuItem<String>(
              enabled: false,
              child: Divider(height: 8, thickness: 0.5),
            ),
            // Add more option
            DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.add_rounded, color: _primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Add more',
                    style: TextStyle(color: _primary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (v) {
            if (v == null) {
              _showAddStatusDialog();
            } else {
              setState(() => _editingStatus = v);
            }
          },
        ),
      ),
    );
  }

  void _showAddStatusDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Custom Status',
            style: TextStyle(color: _textLight, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter a new status name',
                style: TextStyle(color: _textGrey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: const TextStyle(color: _textLight),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g., Testing, On Hold',
                  hintStyle: const TextStyle(color: _textGrey),
                  filled: true,
                  fillColor: _input,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _border.withOpacity(0.6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(foregroundColor: _textGrey),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final status = controller.text.trim();
                if (status.isNotEmpty && !_statuses.contains(status)) {
                  setState(() {
                    _statuses.add(status);
                    _editingStatus = status;
                  });
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
