import 'package:flutter/material.dart';
import '../screen/tasks_screen.dart';
import '../services/task_service.dart';
import '../services/token_storage_service.dart';

class TasksSection extends StatefulWidget {
  final String? token;
  const TasksSection({super.key, this.token});

  @override
  State<TasksSection> createState() => _TasksSectionState();
}

class _TasksSectionState extends State<TasksSection> {
  //  Theme
  final Color _bgCard = const Color(0xFF141414);
  final Color _accentPink = const Color(0xFFFF8FA3);
  final Color _accentGreen = const Color(0xFF00C853);
  final Color _accentOrange = const Color(0xFFFFAB00);
  final Color _textGrey = const Color(0xFF9E9E9E);

  //  State
  bool _isLoading = true;
  String? _error;
  List<dynamic> _tasks = [];
  String? _token;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _token = widget.token ?? await TokenStorageService().getToken();
    await _loadTasks();
  }

  Future<void> _loadTasks() async {
    if (_token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Not authenticated';
      });
      return;
    }
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final result = await TaskService.getTasks(_token!);
      if (!mounted) return;
      final data = result['data'];
      setState(() {
        _tasks = (data is List) ? data : [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

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
    switch (s.toLowerCase()) {
      case 'completed':
        return _accentGreen;
      case 'in-progress':
        return _accentOrange;
      case 'cancelled':
        return Colors.grey;
      default:
        return _accentPink;
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'in-progress':
        return 'In Progress';
      case 'completed':
        return 'Done';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Todo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _tasks.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //  Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                ' My Tasks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TasksScreen(token: _token)),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 28),
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    color: _accentPink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Your assigned tasks & progress',
            style: TextStyle(fontSize: 12, color: _textGrey),
          ),
          const SizedBox(height: 14),

          //  Body
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_error != null)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Icon(Icons.wifi_off_rounded, color: _textGrey, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Could not load tasks',
                    style: TextStyle(color: _textGrey, fontSize: 12),
                  ),
                  TextButton(
                    onPressed: _loadTasks,
                    child: Text(
                      'Retry',
                      style: TextStyle(color: _accentPink, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else if (preview.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Icon(Icons.assignment_outlined, size: 40, color: _textGrey),
                  const SizedBox(height: 8),
                  Text(
                    'No tasks assigned yet',
                    style: TextStyle(color: _textGrey, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ...preview.map((task) => _buildTaskItem(task)).toList(),
        ],
      ),
    );
  }

  Widget _buildTaskItem(dynamic task) {
    final priority = (task['priority'] ?? 'medium').toString();
    final status = (task['status'] ?? 'todo').toString();
    final progress = ((task['progress'] ?? 0) as num).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Priority dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _priorityColor(priority),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          // Title + progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'] ?? '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 4,
                    backgroundColor: Colors.white10,
                    color: _priorityColor(priority),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _statusLabel(status),
              style: TextStyle(
                color: _statusColor(status),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
