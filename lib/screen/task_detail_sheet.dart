import 'package:flutter/material.dart';
import '../services/admin_employees_service.dart';
import '../services/workflow_service.dart';
import '../widgets/workflow_template_manager.dart';
import '../widgets/task_workflow_canvas.dart';

/// Reusable Task Detail Sheet Widget
/// Can be used across multiple screens to display task details in a bottom sheet
class TaskDetailSheet extends StatefulWidget {
  final Map<String, dynamic> task;
  final String? token;
  final VoidCallback? onEditTask;
  final String userRole;

  const TaskDetailSheet({
    required this.task,
    this.token,
    this.onEditTask,
    this.userRole = 'employee',
    Key? key,
  }) : super(key: key);

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late double _progress;
  late TextEditingController _progressController;
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _newCommentController = TextEditingController();
  int _selectedRating = 0;

  // Comments state
  bool _loadingComments = false;
  List<dynamic> _comments = [];
  String? _commentsError;

  // History state
  bool _loadingHistory = false;
  List<dynamic> _history = [];
  String? _historyError;

  // Subtask form state
  bool _showSubtaskForm = false;
  bool _subtaskSubmitting = false;
  final TextEditingController _subtaskTitleController = TextEditingController();
  final TextEditingController _subtaskDescController = TextEditingController();
  String _subtaskPriority = 'medium';

  // Workflow state
  bool _completingStep = false;
  bool _assigningWorkflow = false;
  final TextEditingController _transitionCommentController = TextEditingController();

  static const _bg = Color(0xFF0D0D0D);
  static const _card = Color(0xFF181818);
  static const _border = Color(0xFF2A2A2A);
  static const _textGrey = Color(0xFF9E9E9E);
  static const _pink = Color(0xFFFF8FA3);
  static const _green = Color(0xFF69F0AE);

  // Responsive helpers
  double _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getResponsiveFontSize(BuildContext context, {double small = 12, double medium = 14, double large = 18}) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return small;
    if (width < 600) return medium;
    return large;
  }

  double _getTabViewHeight(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    if (height < 700) return 250;
    if (height < 900) return 300;
    return 350;
  }

  bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  bool _isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1024;
  bool _isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1024;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _progress = ((widget.task['progress'] as num?)?.toDouble() ?? 0).clamp(0, 100);
    _progressController = TextEditingController(text: _progress.toInt().toString());
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final index = _tabController.index;
    if (index == 2 && _comments.isEmpty && !_loadingComments) {
      _loadComments();
    } else if (index == 4 && _history.isEmpty && !_loadingHistory) {
      _loadHistory();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _progressController.dispose();
    _reviewController.dispose();
    _commentController.dispose();
    _newCommentController.dispose();
    _subtaskTitleController.dispose();
    _subtaskDescController.dispose();
    _transitionCommentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    if (!mounted) return;
    setState(() => _loadingComments = true);
    try {
      final taskId = widget.task['_id']?.toString() ?? '';
      final comments = await AdminEmployeesService.getTaskComments(
        widget.token ?? '',
        taskId,
      );
      if (mounted) {
        setState(() {
          _comments = comments;
          _loadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _commentsError = e.toString();
          _loadingComments = false;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _loadingHistory = true);
    try {
      final taskId = widget.task['_id']?.toString() ?? '';
      final history = await AdminEmployeesService.getTaskHistory(
        widget.token ?? '',
        taskId,
      );
      if (mounted) {
        setState(() {
          _history = history.isNotEmpty
              ? history
              : [
                  {
                    'action': 'Task Created',
                    'by': 'System',
                    'date': widget.task['createdAt'],
                    'details': 'Task was created'
                  },
                ];
          _loadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = e.toString();
          _loadingHistory = false;
        });
      }
    }
  }

  Future<void> _addComment(String text) async {
    if (text.trim().isEmpty) return;
    try {
      final taskId = widget.task['_id']?.toString() ?? '';
      final result = await AdminEmployeesService.addTaskComment(
        widget.token ?? '',
        taskId,
        text,
      );
      if (mounted) {
        setState(() {
          _comments.add({
            'author': 'Current User',
            'text': text,
            'createdAt': DateTime.now().toIso8601String(),
            ...result,
          });
          _newCommentController.clear();
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment added successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _updateProgress(double progress) async {
    try {
      final taskId = widget.task['_id']?.toString() ?? '';
      await AdminEmployeesService.updateTask(
        widget.token ?? '',
        taskId,
        progress: progress,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress updated successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF69F0AE),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitWorkflow() async {
    try {
      final taskId = widget.task['_id']?.toString() ?? '';
      await AdminEmployeesService.updateTaskStatus(
        widget.token ?? '',
        taskId,
        'in-progress',
        comment: _commentController.text.isNotEmpty ? _commentController.text : null,
      );
      if (mounted) {
        _commentController.clear();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task submitted for approval'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF69F0AE),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitReview() async {    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a review'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final taskId = widget.task['_id']?.toString() ?? '';
      // Add review as a comment with rating
      final reviewText = '[Rating: $_selectedRating/5]\n${_reviewController.text}';
      await AdminEmployeesService.addTaskComment(
        widget.token ?? '',
        taskId,
        reviewText,
      );
      if (mounted) {
        _reviewController.clear();
        setState(() => _selectedRating = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF69F0AE),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createSubtask() async {
    final title = _subtaskTitleController.text.trim();
    if (title.isEmpty) return;
    setState(() => _subtaskSubmitting = true);
    try {
      final taskId = widget.task['_id']?.toString() ?? '';
      final assignedTo = widget.task['assignedTo'] is Map
          ? widget.task['assignedTo']['_id']?.toString()
          : widget.task['assignedTo']?.toString();
      await AdminEmployeesService.addTaskComment(
        widget.token ?? '',
        taskId,
        '[SUBTASK] ${_subtaskTitleController.text.trim()}',
      );
      if (mounted) {
        _subtaskTitleController.clear();
        _subtaskDescController.clear();
        setState(() {
          _showSubtaskForm = false;
          _subtaskSubmitting = false;
          _subtaskPriority = 'medium';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subtask created successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF69F0AE),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _subtaskSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  bool _isOverdue() {
    final dueRaw = widget.task['dueDate'];
    final status = widget.task['status']?.toString() ?? '';
    if (dueRaw == null || status == 'completed') return false;
    try {
      final due = DateTime.parse(dueRaw.toString()).toLocal();
      return DateTime.now().isAfter(due);
    } catch (_) {
      return false;
    }
  }

  Color _activityIconColor(String? action) {
    if (action == null) return _textGrey;
    if (action.contains('created')) return const Color(0xFF69F0AE);
    if (action.contains('status') || action.contains('workflow') || action.contains('transition')) return const Color(0xFF448AFF);
    if (action.contains('assign') || action.contains('reassign')) return const Color(0xFFAA80FF);
    if (action.contains('comment')) return const Color(0xFF00BCD4);
    if (action.contains('attachment') || action.contains('file')) return const Color(0xFFFF9800);
    if (action.contains('progress')) return _pink;
    if (action.contains('review')) return const Color(0xFFFFD740);
    if (action.contains('priority')) return const Color(0xFFFFAB00);
    if (action.contains('completed')) return const Color(0xFF69F0AE);
    if (action.contains('time')) return const Color(0xFF26A69A);
    return _textGrey;
  }

  IconData _activityIconData(String? action) {
    if (action == null) return Icons.edit_rounded;
    if (action.contains('created')) return Icons.add_circle_outline_rounded;
    if (action.contains('status') || action.contains('transition')) return Icons.swap_horiz_rounded;
    if (action.contains('workflow')) return Icons.account_tree_rounded;
    if (action.contains('assign') || action.contains('reassign')) return Icons.person_add_rounded;
    if (action.contains('comment')) return Icons.message_rounded;
    if (action.contains('attachment') || action.contains('file')) return Icons.attach_file_rounded;
    if (action.contains('progress')) return Icons.trending_up_rounded;
    if (action.contains('review')) return Icons.star_rounded;
    if (action.contains('priority')) return Icons.flag_rounded;
    if (action.contains('completed')) return Icons.check_circle_rounded;
    if (action.contains('time')) return Icons.timer_rounded;
    return Icons.edit_rounded;
  }

  String _formatDate(dynamic raw) {    if (raw == null) return '—';
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high': return const Color(0xFFFF5252);
      case 'low': return const Color(0xFF69F0AE);
      default: return const Color(0xFFFFD740);
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'completed': return const Color(0xFF69F0AE);
      case 'in-progress': return const Color(0xFFFF9500);
      case 'overdue': return const Color(0xFFFF5252);
      default: return const Color(0xFF448AFF);
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'completed': return 'Completed';
      case 'in-progress': return 'In Progress';
      case 'overdue': return 'Overdue';
      case 'todo': return 'To Do';
      default: return s;
    }
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  Widget _statBox(String value, String label, Color color) => Container(
    padding: EdgeInsets.symmetric(vertical: _getResponsivePadding(context) * 0.7),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(color: color, fontSize: _getResponsiveFontSize(context, small: 14, medium: 16, large: 18), fontWeight: FontWeight.bold)),
        SizedBox(height: _getResponsivePadding(context) * 0.2),
        Text(label, style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 8, medium: 10, large: 10)), textAlign: TextAlign.center),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final title = task['title']?.toString() ?? 'Untitled';
    final description = task['description']?.toString() ?? '';
    final status = task['status']?.toString() ?? 'todo';
    final priority = task['priority']?.toString() ?? 'medium';
    final dueDate = _formatDate(task['dueDate']);
    final startDate = _formatDate(task['startDate'] ?? task['createdAt']);
    final subtasks = (task['subtasks'] as List?) ?? [];
    final subtaskCount = subtasks.length;
    final commentCount = (task['comments'] as List?)?.length ?? 0;
    final attachments = (task['attachments'] as List?) ?? (task['files'] as List?) ?? [];
    final fileCount = attachments.length;
    final overdue = _isOverdue();

    // Dynamic progress: avg from subtasks if populated with progress
    final subtaskProgress = subtaskCount > 0 && subtasks.any((s) => (s as Map?)?['progress'] != null)
        ? subtasks.map((s) => ((s as Map)['progress'] as num?)?.toDouble() ?? 0).reduce((a, b) => a + b) / subtaskCount
        : null;
    final displayProgress = subtaskProgress ?? _progress;
    final completedSubtaskCount = subtasks.where((s) => (s as Map?)?['status'] == 'completed').length;

    final responsivePadding = _getResponsivePadding(context);
    final isMobile = _isMobile(context);

    return DraggableScrollableSheet(
      initialChildSize: isMobile ? 0.93 : 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // drag handle
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 10, bottom: 6),
                width: 40, height: 4,
                decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.symmetric(horizontal: responsivePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (overdue) ...[
                                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 16),
                                    const SizedBox(width: 6),
                                  ],
                                  Expanded(
                                    child: Text(title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: _getResponsiveFontSize(context, small: 16, medium: 18, large: 20),
                                        fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(description,
                                  style: TextStyle(
                                    color: _textGrey, 
                                    fontSize: _getResponsiveFontSize(context, small: 11, medium: 12, large: 13)),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                              SizedBox(height: responsivePadding * 0.5),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _badge(_statusLabel(status), _statusColor(status)),
                                    _badge(
                                      '${priority[0].toUpperCase()}${priority.substring(1)} Priority',
                                      _priorityColor(priority)),
                                    if (overdue)
                                      _badge('Overdue', const Color(0xFFFF5252)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: _textGrey),
                          onPressed: () => Navigator.pop(context),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    SizedBox(height: responsivePadding),

                    // ── Workflow Action ──────────────────────────────────────
                    Container(
                      padding: EdgeInsets.all(responsivePadding),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Workflow Actions',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: _getResponsiveFontSize(context, small: 12, medium: 14, large: 14))),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _commentController,
                            maxLines: 2,
                            style: TextStyle(color: Colors.white, fontSize: _getResponsiveFontSize(context, small: 11, medium: 13, large: 13)),
                            decoration: InputDecoration(
                              hintText: 'Optional comment for transition...',
                              hintStyle: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 11, medium: 13, large: 13)),
                              filled: true,
                              fillColor: const Color(0xFF111111),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: _border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: _border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: _pink.withOpacity(0.6)),
                              ),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: const Text('Submit for Approval'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _pink,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: responsivePadding * 0.8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _submitWorkflow,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: responsivePadding * 0.9),

                    // ── Stat Boxes ───────────────────────────────────────────
                    isMobile
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.6,
                                child: _statBox('${displayProgress.toInt()}%', 'Progress', _pink),
                              ),
                              SizedBox(width: responsivePadding * 0.4),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.5,
                                child: _statBox('$subtaskCount', 'Subtasks', const Color(0xFF448AFF)),
                              ),
                              SizedBox(width: responsivePadding * 0.4),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.5,
                                child: _statBox('$commentCount', 'Comments', const Color(0xFFFF9500)),
                              ),
                              SizedBox(width: responsivePadding * 0.4),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.5,
                                child: _statBox('$fileCount', 'Files', const Color(0xFF69F0AE)),
                              ),
                              SizedBox(width: responsivePadding * 0.4),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.5,
                                child: _statBox('0m', 'Time Logged', const Color(0xFFAA80FF)),
                              ),
                            ],
                          ),
                        )
                      : Wrap(
                          spacing: responsivePadding * 0.4,
                          runSpacing: responsivePadding * 0.4,
                          children: [
                            SizedBox(
                              width: (MediaQuery.of(context).size.width - responsivePadding * 2) / 3 - responsivePadding * 0.3,
                              child: _statBox('${displayProgress.toInt()}%', 'Progress', _pink),
                            ),
                            SizedBox(
                              width: (MediaQuery.of(context).size.width - responsivePadding * 2) / 3 - responsivePadding * 0.3,
                              child: _statBox('$subtaskCount', 'Subtasks', const Color(0xFF448AFF)),
                            ),
                            SizedBox(
                              width: (MediaQuery.of(context).size.width - responsivePadding * 2) / 3 - responsivePadding * 0.3,
                              child: _statBox('$commentCount', 'Comments', const Color(0xFFFF9500)),
                            ),
                            SizedBox(
                              width: (MediaQuery.of(context).size.width - responsivePadding * 2) / 3 - responsivePadding * 0.3,
                              child: _statBox('$fileCount', 'Files', const Color(0xFF69F0AE)),
                            ),
                            SizedBox(
                              width: (MediaQuery.of(context).size.width - responsivePadding * 2) / 3 - responsivePadding * 0.3,
                              child: _statBox('0m', 'Time Logged', const Color(0xFFAA80FF)),
                            ),
                          ],
                        ),
                    SizedBox(height: responsivePadding * 0.9),

                    // ── Overall Progress ─────────────────────────────────────
                    Container(
                      padding: EdgeInsets.all(responsivePadding),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Overall Progress',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: _getResponsiveFontSize(context, small: 12, medium: 14, large: 14))),
                              const Spacer(),
                              Text('${displayProgress.toInt()}%',
                                style: TextStyle(
                                  color: displayProgress >= 100 ? _green : _pink,
                                  fontWeight: FontWeight.bold,
                                  fontSize: _getResponsiveFontSize(context, small: 14, medium: 16, large: 16))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: displayProgress / 100,
                              minHeight: 6,
                              backgroundColor: _border,
                              valueColor: AlwaysStoppedAnimation<Color>(displayProgress >= 100 ? _green : _pink),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (subtaskProgress != null)
                            Text(
                              'Auto-calculated from $completedSubtaskCount/$subtaskCount completed subtasks',
                              style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 9, medium: 10, large: 10)),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: _pink,
                                      inactiveTrackColor: _border,
                                      thumbColor: _pink,
                                      overlayColor: _pink.withOpacity(0.15),
                                      trackHeight: 4,
                                    ),
                                    child: Slider(
                                      value: _progress,
                                      min: 0, max: 100,
                                      divisions: 20,
                                      onChanged: (v) => setState(() {
                                        _progress = v;
                                        _progressController.text = v.toInt().toString();
                                      }),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: isMobile ? 44 : 54,
                                  child: TextField(
                                    controller: _progressController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: Colors.white, fontSize: _getResponsiveFontSize(context, small: 11, medium: 13, large: 13)),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      filled: true,
                                      fillColor: const Color(0xFF111111),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(color: _border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(color: _border),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(color: _pink.withOpacity(0.6)),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                    ),
                                    onSubmitted: (v) {
                                      final parsed = double.tryParse(v);
                                      if (parsed != null) setState(() => _progress = parsed.clamp(0, 100));
                                    },
                                  ),
                                ),
                                SizedBox(width: responsivePadding * 0.4),
                                ElevatedButton(
                                  onPressed: () => _updateProgress(_progress),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _pink,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: responsivePadding * 0.7, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: _getResponsiveFontSize(context, small: 10, medium: 12, large: 12)),
                                  ),
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: responsivePadding * 0.9),

                    // ── Tab Bar ──────────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            labelColor: _pink,
                            unselectedLabelColor: _textGrey,
                            indicatorColor: _pink,
                            dividerColor: _border,
                            labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: _getResponsiveFontSize(context, small: 10, medium: 12, large: 12)),
                            tabs: [
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.visibility_rounded, size: 14),
                                    SizedBox(width: 6),
                                    Text('Details'),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.call_split, size: 14),
                                    SizedBox(width: 6),
                                    Text('Subtasks'),
                                    if (subtaskCount > 0) ...[
                                      SizedBox(width: 4),
                                      Text('($subtaskCount)', style: TextStyle(fontSize: 10)),
                                    ],
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.message_rounded, size: 14),
                                    SizedBox(width: 6),
                                    Text('Comments'),
                                    if (commentCount > 0) ...[
                                      SizedBox(width: 4),
                                      Text('($commentCount)', style: TextStyle(fontSize: 10)),
                                    ],
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.attachment_rounded, size: 14),
                                    SizedBox(width: 6),
                                    Text('Files'),
                                    if (fileCount > 0) ...[
                                      SizedBox(width: 4),
                                      Text('($fileCount)', style: TextStyle(fontSize: 10)),
                                    ],
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.history_rounded, size: 14),
                                    SizedBox(width: 6),
                                    Text('History'),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.account_tree_rounded, size: 14),
                                    SizedBox(width: 6),
                                    Text('Workflow'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: _getTabViewHeight(context),
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // ── Details ──────────────────────────
                                _buildDetailsTab(context, priority, dueDate, startDate, overdue),
                                // ── Subtasks ──────────────────────────
                                _buildSubtasksTab(context, subtaskCount),
                                // ── Comments ──────────────────────────
                                _buildCommentsTab(context),
                                // ── Files ──────────────────────────
                                _buildFilesTab(context, attachments),
                                // ── History ───────────────────────────
                                _buildHistoryTab(context),
                                // ── Workflow ───────────────────────────
                                _buildWorkflowTab(context),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: responsivePadding * 0.9),

                    // ── Add Review ───────────────────────────────────────────
                    Container(
                      padding: EdgeInsets.all(responsivePadding),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add Review',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: _getResponsiveFontSize(context, small: 12, medium: 14, large: 14))),
                          SizedBox(height: responsivePadding * 0.7),
                          // Star rating
                          Row(
                            children: List.generate(5, (i) => GestureDetector(
                              onTap: () => setState(() => _selectedRating = i + 1),
                              child: Padding(
                                padding: EdgeInsets.only(right: responsivePadding * 0.4),
                                child: Icon(
                                  i < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: i < _selectedRating ? const Color(0xFFFFD740) : _textGrey,
                                  size: isMobile ? 24 : 28,
                                ),
                              ),
                            )),
                          ),
                          SizedBox(height: responsivePadding * 0.7),
                          TextField(
                            controller: _reviewController,
                            maxLines: isMobile ? 3 : 4,
                            style: TextStyle(color: Colors.white, fontSize: _getResponsiveFontSize(context, small: 11, medium: 13, large: 13)),
                            decoration: InputDecoration(
                              hintText: 'Write your review...',
                              hintStyle: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 11, medium: 13, large: 13)),
                              filled: true,
                              fillColor: const Color(0xFF111111),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: _border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: _border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: _pink.withOpacity(0.6)),
                              ),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                          ),
                          SizedBox(height: responsivePadding * 0.7),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitReview,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _pink,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: responsivePadding * 0.8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text('Submit Review',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: _getResponsiveFontSize(context, small: 11, medium: 13, large: 13))),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: responsivePadding * 1.5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, Widget valueWidget) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Icon(icon, color: _textGrey, size: 16),
      const SizedBox(width: 8),
      SizedBox(
        width: _isMobile(context) ? 60 : 80,
        child: Text(label,
          style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 11, medium: 12, large: 13))),
      ),
      Expanded(child: valueWidget),
    ],
  );

  // ── Details Tab ──────────────────────────────────────────────────────────
  Widget _buildDetailsTab(BuildContext context, String priority, String dueDate, String startDate, bool overdue) {
    final responsivePadding = _getResponsivePadding(context);
    final task = widget.task;

    // Extract fields
    final assignedTo = task['assignedTo'];
    final assigneeName = assignedTo is Map
        ? (assignedTo['name']?.toString() ?? assignedTo['email']?.toString() ?? 'Unknown')
        : assignedTo?.toString() ?? '';
    final project = task['project'];
    final projectName = project is Map ? project['name']?.toString() : project?.toString();
    final milestone = task['milestone'];
    final milestoneName = milestone is Map ? milestone['title']?.toString() : milestone?.toString();
    final tags = (task['tags'] as List?)?.cast<String>() ?? [];
    final review = task['review'] as Map?;

    return Padding(
      padding: EdgeInsets.all(responsivePadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assignee
            if (assigneeName.isNotEmpty)
              _detailRow(Icons.person_rounded, 'Assigned',
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: _pink.withOpacity(0.2),
                      child: Text(
                        assigneeName.isNotEmpty ? assigneeName[0].toUpperCase() : '?',
                        style: TextStyle(color: _pink, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(assigneeName,
                        style: TextStyle(color: Colors.white, fontSize: _getResponsiveFontSize(context, small: 11, medium: 12, large: 13)),
                        overflow: TextOverflow.ellipsis),
                    ),
                  ],
                )),
            if (assigneeName.isNotEmpty) SizedBox(height: responsivePadding * 0.7),

            // Priority
            _detailRow(Icons.flag_rounded, 'Priority',
              _badge(
                '${priority[0].toUpperCase()}${priority.substring(1)}',
                _priorityColor(priority))),
            SizedBox(height: responsivePadding * 0.7),

            // Due Date
            _detailRow(Icons.calendar_today_rounded, 'Due Date',
              Row(
                children: [
                  Text(dueDate,
                    style: TextStyle(
                      color: overdue ? const Color(0xFFFF5252) : Colors.white,
                      fontWeight: overdue ? FontWeight.bold : FontWeight.normal,
                      fontSize: _getResponsiveFontSize(context, small: 11, medium: 13, large: 13))),
                  if (overdue) ...[
                    const SizedBox(width: 4),
                    const Text('(Overdue)', style: TextStyle(color: Color(0xFFFF5252), fontSize: 11)),
                  ],
                ],
              )),
            SizedBox(height: responsivePadding * 0.7),

            // Start Date
            _detailRow(Icons.play_circle_outline_rounded, 'Start Date',
              Text(startDate,
                style: TextStyle(color: Colors.white, fontSize: _getResponsiveFontSize(context, small: 11, medium: 13, large: 13)))),

            // Project
            if (projectName != null && projectName.isNotEmpty) ...[
              SizedBox(height: responsivePadding * 0.7),
              _detailRow(Icons.folder_rounded, 'Project',
                Text(projectName,
                  style: TextStyle(color: Colors.white, fontSize: _getResponsiveFontSize(context, small: 11, medium: 13, large: 13)),
                  overflow: TextOverflow.ellipsis)),
            ],

            // Milestone
            if (milestoneName != null && milestoneName.isNotEmpty) ...[
              SizedBox(height: responsivePadding * 0.7),
              _detailRow(Icons.emoji_events_rounded, 'Milestone',
                Text(milestoneName,
                  style: TextStyle(color: Colors.white, fontSize: _getResponsiveFontSize(context, small: 11, medium: 13, large: 13)),
                  overflow: TextOverflow.ellipsis)),
            ],

            // Tags
            if (tags.isNotEmpty) ...[
              SizedBox(height: responsivePadding * 0.9),
              Text('Tags', style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 10, medium: 11, large: 11))),
              SizedBox(height: responsivePadding * 0.4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF448AFF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF448AFF).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tag, size: 10, color: Color(0xFF448AFF)),
                      const SizedBox(width: 3),
                      Text(tag, style: const TextStyle(color: Color(0xFF448AFF), fontSize: 11)),
                    ],
                  ),
                )).toList(),
              ),
            ],

            // Existing Review
            if (review != null && review['comment'] != null) ...[
              SizedBox(height: responsivePadding * 0.9),
              Text('Review', style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 10, medium: 11, large: 11))),
              SizedBox(height: responsivePadding * 0.4),
              Container(
                padding: EdgeInsets.all(responsivePadding * 0.7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD740).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD740).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (review['rating'] != null)
                      Row(
                        children: [
                          ...List.generate(5, (i) => Icon(
                            i < (review['rating'] as num).toInt()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: i < (review['rating'] as num).toInt()
                                ? const Color(0xFFFFD740) : _textGrey,
                            size: 14,
                          )),
                          const SizedBox(width: 4),
                          Text('${review['rating']}/5',
                            style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 10, medium: 11, large: 11))),
                        ],
                      ),
                    SizedBox(height: responsivePadding * 0.4),
                    Text(review['comment']?.toString() ?? '',
                      style: TextStyle(color: Colors.white, fontSize: _getResponsiveFontSize(context, small: 11, medium: 12, large: 12))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Files Tab ─────────────────────────────────────────────────────────────
  Widget _buildFilesTab(BuildContext context, List<dynamic> attachments) {
    final responsivePadding = _getResponsivePadding(context);

    if (attachments.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(responsivePadding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.attach_file_rounded, size: 36, color: _textGrey.withOpacity(0.3)),
              SizedBox(height: responsivePadding * 0.7),
              Text('No attachments', style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 11, medium: 13, large: 13))),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(responsivePadding * 0.7),
      itemCount: attachments.length,
      itemBuilder: (context, index) {
        final att = attachments[index] as Map?;
        if (att == null) return const SizedBox.shrink();
        final name = att['name']?.toString() ?? att['fileName']?.toString() ?? 'File';
        final type = att['type']?.toString() ?? '';
        final uploadedAt = _formatDate(att['uploadedAt'] ?? att['createdAt']);
        final url = att['url']?.toString();
        final sizeKb = att['size'] != null ? ((att['size'] as num) / 1024).toStringAsFixed(1) : null;

        IconData fileIcon;
        Color fileColor;
        switch (type.toLowerCase()) {
          case 'image': fileIcon = Icons.image_rounded; fileColor = const Color(0xFF69F0AE); break;
          case 'video': fileIcon = Icons.videocam_rounded; fileColor = const Color(0xFF448AFF); break;
          case 'document': fileIcon = Icons.description_rounded; fileColor = const Color(0xFFFFD740); break;
          default: fileIcon = Icons.insert_drive_file_rounded; fileColor = _pink;
        }

        return Container(
          margin: EdgeInsets.only(bottom: responsivePadding * 0.6),
          padding: EdgeInsets.all(responsivePadding * 0.7),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: fileColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(fileIcon, color: fileColor, size: 20),
              ),
              SizedBox(width: responsivePadding * 0.7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                      style: TextStyle(color: Colors.white, fontSize: _getResponsiveFontSize(context, small: 11, medium: 12, large: 12), fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        if (type.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              border: Border.all(color: _border),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(type.toUpperCase(), style: TextStyle(color: _textGrey, fontSize: 9)),
                          ),
                        if (type.isNotEmpty) const SizedBox(width: 6),
                        Text(uploadedAt, style: TextStyle(color: _textGrey, fontSize: 9)),
                        if (sizeKb != null) ...[
                          const SizedBox(width: 6),
                          Text('${sizeKb}KB', style: TextStyle(color: _textGrey, fontSize: 9)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (url != null) ...[
                IconButton(
                  icon: Icon(Icons.open_in_new_rounded, color: _textGrey, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening: $url'), duration: const Duration(seconds: 2))),
                ),
                IconButton(
                  icon: Icon(Icons.download_rounded, color: _textGrey, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Downloading: $name'), duration: const Duration(seconds: 2))),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Workflow Tab ──────────────────────────────────────────────────────────
  // ── Workflow helpers ──────────────────────────────────────────────────────

  List<Map<String, dynamic>> _getAvailableTransitions(String? status) {
    switch (status) {
      case 'todo':
        return [
          {'label': 'Start Work', 'nextStatus': 'in_progress', 'color': 0xFF448AFF, 'icon': Icons.play_arrow},
        ];
      case 'in_progress':
        return [
          {'label': 'Send for Review', 'nextStatus': 'review',    'color': 0xFFFF8FA3, 'icon': Icons.rate_review},
          {'label': 'Mark Done',       'nextStatus': 'done',      'color': 0xFF69F0AE, 'icon': Icons.check_circle},
        ];
      case 'review':
        return [
          {'label': 'Approve',   'nextStatus': 'done',        'color': 0xFF69F0AE, 'icon': Icons.thumb_up},
          {'label': 'Send Back', 'nextStatus': 'in_progress', 'color': 0xFFFFA726, 'icon': Icons.undo},
        ];
      case 'done':
        return [
          {'label': 'Reopen', 'nextStatus': 'in_progress', 'color': 0xFF9E9E9E, 'icon': Icons.refresh},
        ];
      default:
        return [];
    }
  }

  Future<void> _completeWorkflowStep(int stepIndex, String comment) async {
    if (!mounted) return;
    setState(() => _completingStep = true);
    try {
      final taskId = widget.task['_id']?.toString() ?? '';
      await WorkflowService.completeStep(
        widget.token ?? '',
        taskId,
        stepIndex: stepIndex,
        comment: comment.isNotEmpty ? comment : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Step completed!'), backgroundColor: Color(0xFF69F0AE)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF5350)),
        );
      }
    } finally {
      if (mounted) setState(() => _completingStep = false);
    }
  }

  void _openWorkflowManager(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xFF141414),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.8,
        child: WorkflowTemplateManager(
          token: widget.token ?? '',
          onSelectTemplate: (template) async {
            Navigator.pop(ctx);
            setState(() => _assigningWorkflow = true);
            try {
              await WorkflowService.assignToTask(
                widget.token ?? '',
                widget.task['_id']?.toString() ?? '',
                templateId: template['_id']?.toString() ?? '',
                workflowName: template['name']?.toString(),
              );
              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Workflow assigned!'),
                    backgroundColor: Color(0xFF69F0AE),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF5350)),
                );
              }
            } finally {
              if (mounted) setState(() => _assigningWorkflow = false);
            }
          },
        ),
      ),
    );
  }

  Widget _buildWorkflowTab(BuildContext context) {
    final responsivePadding = _getResponsivePadding(context);
    final taskWorkflow     = widget.task['taskWorkflow'] as Map<String, dynamic>?;
    final steps            = taskWorkflow != null ? ((taskWorkflow['steps'] as List?) ?? []) : [];
    final currentStepIdx   = (taskWorkflow?['currentStepIndex'] as num?)?.toInt() ?? 0;
    final workflowName     = taskWorkflow?['workflowName']?.toString()
        ?? taskWorkflow?['name']?.toString()
        ?? 'Workflow';
    final transitions  = _getAvailableTransitions(widget.task['status']?.toString());
    final isAdminOrHr  = widget.userRole == 'admin' || widget.userRole == 'hr';

    return Padding(
      padding: EdgeInsets.all(responsivePadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Edit Task ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Edit Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF448AFF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: responsivePadding * 0.7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: TextStyle(
                    fontSize: _getResponsiveFontSize(context, small: 10, medium: 12, large: 12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(this.context);
                  widget.onEditTask?.call();
                },
              ),
            ),
            SizedBox(height: responsivePadding * 0.9),

            // ── Workflow Canvas (when steps exist) ─────────────────────────
            if (steps.isNotEmpty) ...[
              TaskWorkflowCanvas(
                workflowName:     workflowName,
                steps:            List<dynamic>.from(steps),
                currentStepIndex: currentStepIdx,
                completing:       _completingStep,
                onCompleteStep:   (idx, comment) => _completeWorkflowStep(idx, comment),
              ),
              SizedBox(height: responsivePadding * 0.9),
            ],

            // ── Assign / Change Workflow (admin & hr only) ─────────────────
            if (isAdminOrHr) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: _assigningWorkflow
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF8FA3)))
                      : Icon(taskWorkflow != null ? Icons.swap_horiz : Icons.add_task, size: 15),
                  label: Text(_assigningWorkflow
                      ? 'Assigning…'
                      : (taskWorkflow != null ? 'Change Workflow' : 'Assign Workflow')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _pink,
                    side: const BorderSide(color: _pink),
                    padding: EdgeInsets.symmetric(vertical: responsivePadding * 0.7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: TextStyle(
                      fontSize: _getResponsiveFontSize(context, small: 10, medium: 12, large: 12),
                    ),
                  ),
                  onPressed: _assigningWorkflow ? null : () => _openWorkflowManager(context),
                ),
              ),
              SizedBox(height: responsivePadding * 0.9),
            ],

            // ── Available Status Transitions ───────────────────────────────
            if (transitions.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(responsivePadding * 0.7),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Transitions',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: _getResponsiveFontSize(context, small: 11, medium: 12, large: 12),
                      ),
                    ),
                    SizedBox(height: responsivePadding * 0.5),
                    TextField(
                      controller: _transitionCommentController,
                      maxLines: 2,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _getResponsiveFontSize(context, small: 10, medium: 12, large: 12),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add a comment for this transition…',
                        hintStyle: TextStyle(
                          color: _textGrey,
                          fontSize: _getResponsiveFontSize(context, small: 10, medium: 12, large: 12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0D0D0D),
                        contentPadding: EdgeInsets.all(responsivePadding * 0.6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: _pink.withOpacity(0.6)),
                        ),
                      ),
                    ),
                    SizedBox(height: responsivePadding * 0.6),
                    Wrap(
                      spacing: responsivePadding * 0.5,
                      runSpacing: responsivePadding * 0.5,
                      children: transitions.map((t) {
                        final color = Color(t['color'] as int);
                        return ElevatedButton.icon(
                          icon: Icon(t['icon'] as IconData, size: 14),
                          label: Text(t['label'] as String),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: responsivePadding * 0.7,
                              vertical:   responsivePadding * 0.5,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            textStyle: TextStyle(
                              fontSize: _getResponsiveFontSize(context, small: 10, medium: 11, large: 11),
                            ),
                          ),
                          onPressed: () async {
                            final taskId    = widget.task['_id']?.toString() ?? '';
                            final next      = t['nextStatus'] as String;
                            final comment   = _transitionCommentController.text.trim();
                            try {
                              await AdminEmployeesService.updateTaskStatus(
                                widget.token ?? '',
                                taskId,
                                next,
                                comment: comment.isNotEmpty ? comment : null,
                              );
                              _transitionCommentController.clear();
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('Status → ${t['label']}'),
                                    backgroundColor: color,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: const Color(0xFFEF5350),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsivePadding * 0.9),
            ],

            // ── Submit Workflow ────────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(responsivePadding * 0.7),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submit Workflow',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: _getResponsiveFontSize(context, small: 11, medium: 12, large: 12),
                    ),
                  ),
                  SizedBox(height: responsivePadding * 0.6),
                  TextField(
                    controller: _commentController,
                    maxLines: 2,
                    style: TextStyle(color: Colors.white, fontSize: _getResponsiveFontSize(context, small: 10, medium: 12, large: 12)),
                    decoration: InputDecoration(
                      hintText: 'Add workflow transition comment...',
                      hintStyle: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 10, medium: 12, large: 12)),
                      filled: true,
                      fillColor: const Color(0xFF0D0D0D),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: _border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: _pink.withOpacity(0.6)),
                      ),
                      contentPadding: EdgeInsets.all(responsivePadding * 0.6),
                    ),
                  ),
                  SizedBox(height: responsivePadding * 0.6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward, size: 14),
                      label: const Text('Submit for Approval'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pink,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: responsivePadding * 0.6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        textStyle: TextStyle(fontSize: _getResponsiveFontSize(context, small: 10, medium: 12, large: 12)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Workflow submitted'), duration: Duration(seconds: 2)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsivePadding * 0.9),

            // ── Current Status ─────────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(responsivePadding * 0.7),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Status',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: _getResponsiveFontSize(context, small: 11, medium: 12, large: 12),
                    ),
                  ),
                  SizedBox(height: responsivePadding * 0.6),
                  Row(
                    children: [
                      _badge(
                        _statusLabel(widget.task['status']?.toString() ?? 'todo'),
                        _statusColor(widget.task['status']?.toString() ?? 'todo'),
                      ),
                      SizedBox(width: responsivePadding * 0.6),
                      Expanded(
                        child: Text(
                          'Updated: ${_formatDate(widget.task['updatedAt'])}',
                          style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 10, medium: 11, large: 11)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: responsivePadding * 0.9),

            // ── Status History ─────────────────────────────────────────────
            Builder(builder: (context) {
              final workflowHistory = (widget.task['workflowHistory'] as List?) ?? [];
              return Container(
                padding: EdgeInsets.all(responsivePadding * 0.7),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history, color: _textGrey, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Status History',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: _getResponsiveFontSize(context, small: 11, medium: 12, large: 12),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${workflowHistory.length} events',
                            style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 9, medium: 10, large: 10)),
                          ),
                        ),
                      ],
                    ),
                    if (workflowHistory.isEmpty) ...[
                      SizedBox(height: responsivePadding * 0.8),
                      Center(
                        child: Text(
                          'No workflow history',
                          style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 10, medium: 11, large: 11)),
                        ),
                      ),
                    ] else ...[
                      SizedBox(height: responsivePadding * 0.6),
                      ...workflowHistory.reversed.toList().asMap().entries.map((entry) {
                        final idx        = entry.key;
                        final item       = entry.value as Map;
                        final isFirst    = idx == 0;
                        final fromStatus = item['fromStatus']?.toString();
                        final toStatus   = item['toStatus']?.toString();
                        final action     = item['action']?.toString();
                        final performedBy    = item['performedBy'];
                        final performerName  = _extractName(performedBy is Map ? performedBy['name'] : performedBy);
                        final performerRole  = performedBy is Map ? (performedBy['role']?.toString() ?? '') : '';
                        final comment    = item['comment']?.toString() ?? '';
                        final timestamp  = _formatDate(item['timestamp'] ?? item['createdAt']);
                        return Container(
                          margin: EdgeInsets.only(bottom: responsivePadding * 0.5),
                          padding: EdgeInsets.all(responsivePadding * 0.6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0D0D),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isFirst ? _pink.withOpacity(0.3) : _border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isFirst)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _pink.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: _pink.withOpacity(0.4)),
                                      ),
                                      child: Text('Current',
                                          style: TextStyle(
                                            color: _pink,
                                            fontSize: _getResponsiveFontSize(context, small: 8, medium: 9, large: 9),
                                            fontWeight: FontWeight.w600,
                                          )),
                                    ),
                                  Expanded(
                                    child: Text(
                                      _workflowActionLabel(action ?? ''),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: _getResponsiveFontSize(context, small: 10, medium: 11, large: 11),
                                      ),
                                    ),
                                  ),
                                  Text(timestamp,
                                      style: TextStyle(
                                        color: _textGrey,
                                        fontSize: _getResponsiveFontSize(context, small: 8, medium: 9, large: 9),
                                      )),
                                ],
                              ),
                              if (fromStatus != null || toStatus != null) ...[
                                SizedBox(height: responsivePadding * 0.4),
                                Row(
                                  children: [
                                    if (fromStatus != null)
                                      _badge(_statusLabel(fromStatus), _statusColor(fromStatus)),
                                    if (fromStatus != null && toStatus != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Icon(Icons.arrow_forward, size: 12, color: _textGrey),
                                      ),
                                    if (toStatus != null)
                                      _badge(_statusLabel(toStatus), _statusColor(toStatus)),
                                  ],
                                ),
                              ],
                              SizedBox(height: responsivePadding * 0.4),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 12, color: _textGrey),
                                  const SizedBox(width: 4),
                                  Text(
                                    performerName.isNotEmpty ? performerName : 'Unknown',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: _getResponsiveFontSize(context, small: 9, medium: 10, large: 10),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (performerRole.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Text(performerRole,
                                        style: TextStyle(
                                          color: _textGrey,
                                          fontSize: _getResponsiveFontSize(context, small: 8, medium: 9, large: 9),
                                        )),
                                  ],
                                ],
                              ),
                              if (comment.isNotEmpty) ...[
                                SizedBox(height: responsivePadding * 0.3),
                                Text('"$comment"',
                                    style: TextStyle(
                                      color: _textGrey,
                                      fontSize: _getResponsiveFontSize(context, small: 9, medium: 10, large: 10),
                                      fontStyle: FontStyle.italic,
                                    )),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Comments Tab ──────────────────────────────────────────────────────────
  Widget _buildCommentsTab(BuildContext context) {
    final responsivePadding = _getResponsivePadding(context);
    
    if (_loadingComments) {
      return const Center(
        child: CircularProgressIndicator(color: _pink),
      );
    }

    if (_commentsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: _pink, size: 32),
            SizedBox(height: responsivePadding * 0.6),
            Text(
              'Error: $_commentsError',
              style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 10, medium: 12, large: 12)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _comments.isEmpty
              ? Center(
                  child: Text(
                    'No comments yet',
                    style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 11, medium: 13, large: 13)),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(responsivePadding * 0.7),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: responsivePadding * 0.6),
                      padding: EdgeInsets.all(responsivePadding * 0.7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  comment['author']?.toString() ?? 'Unknown',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: _getResponsiveFontSize(context, small: 10, medium: 12, large: 12),
                                  ),
                                ),
                              ),
                              Text(
                                _formatDate(comment['createdAt']),
                                style: TextStyle(
                                  color: _textGrey,
                                  fontSize: _getResponsiveFontSize(context, small: 9, medium: 10, large: 10),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: responsivePadding * 0.4),
                          Text(
                            comment['text']?.toString() ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _getResponsiveFontSize(context, small: 10, medium: 12, large: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: EdgeInsets.all(responsivePadding * 0.7),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newCommentController,
                  maxLines: 1,
                  style: TextStyle(color: Colors.white, fontSize: _getResponsiveFontSize(context, small: 10, medium: 12, large: 12)),
                  decoration: InputDecoration(
                    hintText: 'Add comment...',
                    hintStyle: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 10, medium: 12, large: 12)),
                    filled: true,
                    fillColor: const Color(0xFF111111),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: _pink.withOpacity(0.6)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: responsivePadding * 0.7,
                      vertical: responsivePadding * 0.6,
                    ),
                  ),
                ),
              ),
              SizedBox(width: responsivePadding * 0.6),
              SizedBox(
                width: 36,
                child: ElevatedButton(
                  onPressed: () {
                    _addComment(_newCommentController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pink,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Icon(Icons.send, size: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Subtasks Tab ──────────────────────────────────────────────────────────
  Widget _buildSubtasksTab(BuildContext context, int subtaskCount) {
    final responsivePadding = _getResponsivePadding(context);
    final rawSubtasks = (widget.task['subtasks'] as List?) ?? [];
    final subtasks = rawSubtasks.whereType<Map>().map((s) => Map<String, dynamic>.from(s)).toList();
    final completedCount = subtasks.where((s) => s['status'] == 'completed').length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(responsivePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.call_split, size: 16, color: _pink),
                      const SizedBox(width: 8),
                      Text(
                        'Subtasks ($subtaskCount)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: _getResponsiveFontSize(context, small: 12, medium: 13, large: 14),
                        ),
                      ),
                    ],
                  ),
                  if (subtaskCount > 0)
                    Padding(
                      padding: EdgeInsets.only(top: responsivePadding * 0.3),
                      child: Text(
                        '$completedCount completed',
                        style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 10, medium: 11, large: 11)),
                      ),
                    ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _showSubtaskForm = !_showSubtaskForm),
                icon: Icon(_showSubtaskForm ? Icons.close : Icons.add, size: 14),
                label: Text(_showSubtaskForm ? 'Cancel' : 'Add Subtask'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _pink,
                  side: BorderSide(color: _pink.withOpacity(0.5)),
                  padding: EdgeInsets.symmetric(horizontal: responsivePadding * 0.8, vertical: responsivePadding * 0.5),
                  textStyle: TextStyle(fontSize: _getResponsiveFontSize(context, small: 10, medium: 11, large: 11)),
                ),
              ),
            ],
          ),
          SizedBox(height: responsivePadding * 0.8),

          // Subtask Creation Form
          if (_showSubtaskForm) ...[
            Container(
              padding: EdgeInsets.all(responsivePadding),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _pink.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Subtask', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: _getResponsiveFontSize(context, small: 11, medium: 12, large: 12))),
                  SizedBox(height: responsivePadding * 0.6),
                  // Title
                  TextField(
                    controller: _subtaskTitleController,
                    style: TextStyle(color: Colors.white, fontSize: _getResponsiveFontSize(context, small: 11, medium: 12, large: 12)),
                    decoration: InputDecoration(
                      labelText: 'Title *',
                      labelStyle: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 10, medium: 11, large: 11)),
                      filled: true,
                      fillColor: _bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: _border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: _border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: _pink.withOpacity(0.6))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                  SizedBox(height: responsivePadding * 0.6),
                  // Description
                  TextField(
                    controller: _subtaskDescController,
                    maxLines: 2,
                    style: TextStyle(color: Colors.white, fontSize: _getResponsiveFontSize(context, small: 11, medium: 12, large: 12)),
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 10, medium: 11, large: 11)),
                      filled: true,
                      fillColor: _bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: _border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: _border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: _pink.withOpacity(0.6))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                  SizedBox(height: responsivePadding * 0.6),
                  // Priority
                  Row(
                    children: [
                      Text('Priority: ', style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 10, medium: 11, large: 11))),
                      ...['low', 'medium', 'high'].map((p) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _subtaskPriority = p),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _subtaskPriority == p ? _priorityColor(p).withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _subtaskPriority == p ? _priorityColor(p) : _border),
                            ),
                            child: Text(
                              '${p[0].toUpperCase()}${p.substring(1)}',
                              style: TextStyle(color: _subtaskPriority == p ? _priorityColor(p) : _textGrey, fontSize: 10),
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                  SizedBox(height: responsivePadding * 0.8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() {
                          _showSubtaskForm = false;
                          _subtaskTitleController.clear();
                          _subtaskDescController.clear();
                        }),
                        child: Text('Cancel', style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 10, medium: 11, large: 11))),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _subtaskSubmitting ? null : _createSubtask,
                        icon: _subtaskSubmitting
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.add, size: 14),
                        label: const Text('Create'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pink,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: responsivePadding * 0.8, vertical: 8),
                          textStyle: TextStyle(fontSize: _getResponsiveFontSize(context, small: 10, medium: 11, large: 11)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: responsivePadding * 0.8),
          ],

          // Subtask List
          if (subtasks.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: responsivePadding * 1.5),
                child: Column(
                  children: [
                    Icon(Icons.call_split, size: 36, color: _textGrey.withOpacity(0.3)),
                    SizedBox(height: responsivePadding * 0.7),
                    Text('No subtasks yet', style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 11, medium: 12, large: 12))),
                    SizedBox(height: responsivePadding * 0.5),
                    Text('Break this task into smaller pieces for better tracking',
                      style: TextStyle(color: _textGrey.withOpacity(0.7), fontSize: _getResponsiveFontSize(context, small: 10, medium: 11, large: 11)),
                      textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subtasks.length,
              itemBuilder: (context, index) {
                final subtask = subtasks[index];
                final isCompleted = subtask['status'] == 'completed';
                final subPriority = subtask['priority']?.toString() ?? 'medium';
                final subStatus = subtask['status']?.toString() ?? 'todo';
                final subAssignee = subtask['assignedTo'] is Map
                    ? subtask['assignedTo']['name']?.toString()
                    : null;
                final subDueDate = subtask['dueDate'] != null ? _formatDate(subtask['dueDate']) : null;
                final subProgress = (subtask['progress'] as num?)?.toInt() ?? 0;

                return Container(
                  margin: EdgeInsets.only(bottom: responsivePadding * 0.6),
                  padding: EdgeInsets.all(responsivePadding * 0.7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isCompleted ? _green : _textGrey,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: responsivePadding * 0.6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    subtask['title']?.toString() ?? 'Untitled',
                                    style: TextStyle(
                                      color: isCompleted ? _textGrey : Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: _getResponsiveFontSize(context, small: 11, medium: 12, large: 12),
                                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _priorityColor(subPriority).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(subPriority, style: TextStyle(color: _priorityColor(subPriority), fontSize: 9)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _badge(_statusLabel(subStatus), _statusColor(subStatus)),
                                if (subAssignee != null) ...[
                                  const SizedBox(width: 6),
                                  Icon(Icons.person_rounded, size: 10, color: _textGrey),
                                  const SizedBox(width: 2),
                                  Text(subAssignee, style: TextStyle(color: _textGrey, fontSize: 9), overflow: TextOverflow.ellipsis),
                                ],
                                if (subDueDate != null) ...[
                                  const SizedBox(width: 6),
                                  Icon(Icons.calendar_today_rounded, size: 10, color: _textGrey),
                                  const SizedBox(width: 2),
                                  Text(subDueDate, style: TextStyle(color: _textGrey, fontSize: 9)),
                                ],
                              ],
                            ),
                            if (subProgress > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: subProgress / 100,
                                        minHeight: 3,
                                        backgroundColor: _border,
                                        valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? _green : _pink),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('$subProgress%', style: TextStyle(color: _textGrey, fontSize: 9, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ── History Tab ───────────────────────────────────────────────────────────
  Widget _buildHistoryTab(BuildContext context) {
    final responsivePadding = _getResponsivePadding(context);

    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator(color: _pink));
    }

    if (_historyError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: _pink, size: 32),
            SizedBox(height: responsivePadding * 0.6),
            Text('Error: $_historyError',
              style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 10, medium: 12, large: 12)),
              textAlign: TextAlign.center),
          ],
        ),
      );
    }

    // Build unified timeline from multiple sources
    final List<Map<String, dynamic>> timeline = [];

    // From workflow history
    for (final entry in (widget.task['workflowHistory'] as List? ?? [])) {
      final e = entry as Map?;
      if (e == null) continue;
      final action = e['action']?.toString() ?? '';
      timeline.add({
        'action': _workflowActionLabel(action),
        'user': _extractName(e['performedBy']),
        'time': e['timestamp'] ?? e['createdAt'],
        'detail': e['comment'],
        'fromStatus': e['fromStatus'],
        'toStatus': e['toStatus'],
        'type': 'workflow',
      });
    }

    // From activity log
    for (final entry in (widget.task['activityLog'] as List? ?? [])) {
      final e = entry as Map?;
      if (e == null) continue;
      timeline.add({
        'action': e['action']?.toString() ?? 'Updated',
        'user': _extractName(e['performedBy'] ?? e['user']),
        'time': e['timestamp'] ?? e['createdAt'],
        'detail': e['comment'] ?? e['details'],
        'oldValue': e['oldValue'],
        'newValue': e['newValue'],
        'type': 'activity',
      });
    }

    // From history API data
    for (final item in _history) {
      final e = item as Map?;
      if (e == null) continue;
      // Avoid duplicates with workflow history
      if (e['action']?.toString()?.contains('workflow') == true) continue;
      timeline.add({
        'action': e['action']?.toString() ?? 'Updated',
        'user': e['by']?.toString() ?? 'System',
        'time': e['date'] ?? e['timestamp'],
        'detail': e['details'],
        'oldValue': e['oldValue'],
        'newValue': e['newValue'],
        'type': 'history',
      });
    }

    // Sort descending by time
    timeline.sort((a, b) {
      final ta = a['time'] != null ? DateTime.tryParse(a['time'].toString()) ?? DateTime(0) : DateTime(0);
      final tb = b['time'] != null ? DateTime.tryParse(b['time'].toString()) ?? DateTime(0) : DateTime(0);
      return tb.compareTo(ta);
    });

    if (timeline.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(responsivePadding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_rounded, size: 36, color: _textGrey.withOpacity(0.3)),
              SizedBox(height: responsivePadding * 0.7),
              Text('No activity recorded', style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 11, medium: 13, large: 13))),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(responsivePadding * 0.7),
      itemCount: timeline.length,
      itemBuilder: (context, index) {
        final item = timeline[index];
        final isLast = index == timeline.length - 1;
        final actionStr = item['action']?.toString() ?? '';
        final iconColor = _activityIconColor(actionStr.toLowerCase());
        final iconData = _activityIconData(actionStr.toLowerCase());

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline column
            Column(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor.withOpacity(0.4)),
                  ),
                  child: Icon(iconData, size: 14, color: iconColor),
                ),
                if (!isLast)
                  Container(width: 1, height: 32, color: _border),
              ],
            ),
            SizedBox(width: responsivePadding * 0.7),
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: responsivePadding * 0.8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${item['user'] ?? 'System'} ',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: _getResponsiveFontSize(context, small: 10, medium: 11, large: 11)),
                                ),
                                TextSpan(
                                  text: actionStr,
                                  style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 10, medium: 11, large: 11)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(item['time']),
                          style: TextStyle(color: _textGrey.withOpacity(0.7), fontSize: 9),
                        ),
                      ],
                    ),
                    // Status transition
                    if (item['fromStatus'] != null && item['toStatus'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _badge(_statusLabel(item['fromStatus'].toString()), _statusColor(item['fromStatus'].toString())),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.arrow_forward, size: 10, color: _textGrey),
                          ),
                          _badge(_statusLabel(item['toStatus'].toString()), _statusColor(item['toStatus'].toString())),
                        ],
                      ),
                    ] else if (item['oldValue'] != null && item['newValue'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _badge(item['oldValue'].toString(), _textGrey),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.arrow_forward, size: 10, color: _textGrey),
                          ),
                          _badge(item['newValue'].toString(), _green),
                        ],
                      ),
                    ],
                    // Detail/comment
                    if (item['detail'] != null && (item['detail'] as String).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '"${item['detail']}"',
                        style: TextStyle(color: _textGrey, fontSize: _getResponsiveFontSize(context, small: 9, medium: 10, large: 10), fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _extractName(dynamic value) {
    if (value == null) return 'System';
    if (value is Map) return value['name']?.toString() ?? value['email']?.toString() ?? 'Unknown';
    return value.toString();
  }

  String _workflowActionLabel(String action) {
    const labels = {
      'created': 'Task Created',
      'submit': 'Submitted for Approval',
      'approve': 'Approved & Assigned',
      'start': 'Work Started',
      'submit-review': 'Submitted for Review',
      'approve-review': 'Review Approved — Completed',
      'reject': 'Rejected',
      'close': 'Closed',
      'reopen': 'Reopened',
      'send-back': 'Sent Back to In Progress',
      'override': 'Status Override',
    };
    return labels[action] ?? action.replaceAll('-', ' ');
  }

}
