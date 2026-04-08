import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hrms_app/features/tasks/data/services/task_service.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';
import 'package:hrms_app/features/admin/data/services/admin_employees_service.dart';
import 'package:hrms_app/shared/services/communication/notification_service.dart';
import 'package:hrms_app/features/tasks/data/services/workflow_service.dart';
import 'package:hrms_app/shared/widgets/common/workflow_tab_widget.dart';
import 'package:hrms_app/shared/widgets/common/workflow_template_manager.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';
import 'task_detail_sheet.dart';

class TasksScreen extends StatefulWidget {
  final String? token;
  final String? role;
  final bool showOnlyCurrentUser;
  const TasksScreen({super.key, this.token, this.role, this.showOnlyCurrentUser = false});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  // Ã¢â€â‚¬Ã¢â€â‚¬ Theme Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  final Color _bgDark = const Color(0xFF050505);
  final Color _cardDark = const Color(0xFF141414);
  final Color _inputDark = const Color(0xFF1F1F1F);
  final Color _accentPink = const Color(0xFFFF8FA3);
  final Color _accentGreen = const Color(0xFF00C853);
  final Color _accentOrange = const Color(0xFFFFAB00);
  final Color _accentPurple = const Color(0xFF651FFF);
  final Color _textGrey = const Color(0xFF9E9E9E);

  String? _statusFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _token;
  String? _userId;
  bool _isAdmin = false;

  // Ã¢â€â‚¬Ã¢â€â‚¬ API state Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  bool _isLoading = true;
  String? _error;
  List<dynamic> _tasks = [];
  Map<String, dynamic> _stats = {
    'total': 0,
    'assigned': 0,
    'todo': 0,
    'inProgress': 0,
    'completed': 0,
    'overdue': 0,
    'cancelled': 0,
    'pending': 0,
    'underReview': 0,
  };

  // Ã¢â€â‚¬Ã¢â€â‚¬ Admin state Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  List<dynamic> _employees = [];
  String? _adminStatusFilter;
  String? _adminPriorityFilter;
  String? _adminEmployeeFilter; // employee _id

  // Ã¢â€â‚¬Ã¢â€â‚¬ Tab state Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  int _employeeTab = 0; // 0=list, 1=kanban, 2=time
  int _adminTab = 0; // 0=list, 1=kanban, 2=employees, 3=projects, 4=time, 5=analytics

  // Ã¢â€â‚¬Ã¢â€â‚¬ Employee priority filter Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  String? _employeePriorityFilter;
  // Quick filter: 'overdue' | 'high-priority' | 'in-progress' | 'assigned' | null
  String? _quickFilter;

  // Ã¢â€â‚¬Ã¢â€â‚¬ Projects state Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  List<dynamic> _projects = [];
  Map<String, dynamic>? _selectedProject;
  List<dynamic> _milestones = [];

  // Ã¢â€â‚¬Ã¢â€â‚¬ Time tracking state Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Map<String, dynamic>? _runningTimer;
  int _timerElapsed = 0;
  bool _timerLoading = false;
  List<dynamic> _timeLogs = [];
  Timer? _timerInterval;

  // Ã¢â€â‚¬Ã¢â€â‚¬ Analytics state Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Map<String, dynamic>? _analyticsStats;
  List<dynamic> _analyticsProductivity = [];
  List<dynamic> _analyticsWorkload = [];
  bool _analyticsLoading = false;

  // Ã¢â€â‚¬Ã¢â€â‚¬ Workflow state Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  List<dynamic> _workflows = [];
  Map<String, dynamic>? _selectedWorkflow;
  bool _workflowsLoading = false;

  // â”€â”€ Workflow Editor state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String _editorPanel = 'list'; // 'list' | 'create' | 'edit'
  Map<String, dynamic>? _editingWorkflow;
  final String _workflowFormName = '';
  final String _workflowFormDesc = '';
  final bool _workflowFormShared = false;
  final List<Map<String, dynamic>> _workflowFormSteps = [];
  bool _workflowSaving = false;
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _timerInterval?.cancel();
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
    _isAdmin = (widget.role?.toLowerCase() == 'admin' || widget.role?.toLowerCase() == 'hr');
    await _loadWorkflows();
    
    // Priority: Check showOnlyCurrentUser first, then check role
    if (widget.showOnlyCurrentUser == true) {
      // "My Tasks" view - load only current user's tasks, ignore admin role
      await Future.wait([_loadMyTasks(), _loadRunningTimer(), _loadTimeLogs()]);
    } else if (_isAdmin) {
      // Admin/HR full interface - load all tasks and employees
      await Future.wait([_loadData(), _loadEmployees(), _loadProjects()]);
    } else {
      // Regular employee view - load their own tasks with timings
      await Future.wait([_loadData(), _loadRunningTimer(), _loadTimeLogs()]);
    }
  }

  Future<void> _loadEmployees() async {
    if (_token == null) return;
    try {
      final res = await AdminEmployeesService.getAllEmployees(
        _token!,
        role: widget.role ?? 'admin', // Pass user's role to use correct endpoint
      );
      if (res['success'] == true && mounted) {
        setState(() {
          _employees = (res['data'] as List<dynamic>? ?? []);
          print('✅ Loaded ${_employees.length} employees');
        });
      } else {
        print('Failed to load employees: ${res['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error loading employees: $e');
    }
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Time Tracking Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  Future<void> _loadRunningTimer() async {
    if (_token == null) return;
    try {
      final res = await TaskService.getRunningTimer(_token!);
      if (mounted) {
        final data = res['data'];
        setState(() {
          _runningTimer = data != null ? Map<String, dynamic>.from(data) : null;
          if (_runningTimer != null) {
            final start = DateTime.tryParse(
              (_runningTimer!['startTime'] ?? '').toString(),
            );
            if (start != null) {
              _timerElapsed = DateTime.now().difference(start).inSeconds;
            }
            _startTimerTick();
          }
        });
      }
    } catch (_) {}
  }

  /// Load only current user's tasks and statistics
  Future<void> _loadMyTasks({bool showLoading = true}) async {
    if (_token == null) return;
    try {
      if (!mounted) return;
      if (showLoading) setState(() => _isLoading = true);

      final tasksRes = await TaskService.getMyTasks(_token!);

      if (mounted) {
        setState(() {
          _tasks = tasksRes is List ? tasksRes : (tasksRes['data'] as List<dynamic>? ?? []);

          // Compute stats from MY tasks only (not from API which includes all employees)
          _stats = {
            'total': _tasks.length,
            'assigned': _tasks.where((t) => 
              (t['status'] as String?)?.toLowerCase() == 'assigned').length,
            'todo': _tasks.where((t) => 
              (t['status'] as String?)?.toLowerCase() == 'todo').length,
            'inProgress': _tasks.where((t) => 
              (t['status'] as String?)?.toLowerCase() == 'in-progress').length,
            'completed': _tasks.where((t) => 
              (t['status'] as String?)?.toLowerCase() == 'completed').length,
            'overdue': _tasks.where((t) {
              final dueDate = t['dueDate'] != null 
                ? DateTime.tryParse(t['dueDate'].toString()) 
                : null;
              return dueDate != null && dueDate.isBefore(DateTime.now()) &&
                  (t['status'] as String?)?.toLowerCase() != 'completed';
            }).length,
            'cancelled': _tasks.where((t) => 
              (t['status'] as String?)?.toLowerCase() == 'cancelled').length,
            'pending': _tasks.where((t) => 
              (t['status'] as String?)?.toLowerCase() == 'pending').length,
            'underReview': _tasks.where((t) => 
              (t['status'] as String?)?.toLowerCase() == 'under-review').length,
          };
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

  Future<void> _loadTimeLogs() async {
    if (_token == null) return;
    try {
      final res = await TaskService.getTimeLogs(_token!, limit: 10);
      if (res['success'] == true && mounted) {
        setState(() {
          _timeLogs = (res['data'] as List<dynamic>? ?? []);
        });
      }
    } catch (_) {}
  }

  void _startTimerTick() {
    _timerInterval?.cancel();
    _timerInterval = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timerElapsed++);
    });
  }

  Future<void> _startTimer(String taskId) async {
    if (_token == null) return;
    setState(() => _timerLoading = true);
    try {
      final res = await TaskService.startTimer(_token!, taskId);
      if (res['success'] == true) {
        await _loadRunningTimer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Timer started'),
              backgroundColor: _accentGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _timerLoading = false);
    }
  }

  Future<void> _stopTimer() async {
    if (_token == null || _runningTimer == null) return;
    setState(() => _timerLoading = true);
    try {
      final logId = _runningTimer!['_id']?.toString() ?? '';
      await TaskService.stopTimer(_token!, logId);
      _timerInterval?.cancel();
      if (mounted) {
        setState(() {
          _runningTimer = null;
          _timerElapsed = 0;
        });
        await _loadTimeLogs();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Timer stopped'),
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
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _timerLoading = false);
    }
  }

  Future<void> _logTime({
    required String taskId,
    required int durationMinutes,
    String? description,
    String? date,
  }) async {
    if (_token == null) return;
    try {
      await TaskService.logTime(
        _token!,
        taskId: taskId,
        durationMinutes: durationMinutes,
        description: description,
        date: date,
      );
      await _loadTimeLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Time logged successfully'),
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
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _formatElapsed(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Projects Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  Future<void> _loadProjects() async {
    if (_token == null) return;
    try {
      final res = await TaskService.getProjects(_token!);
      if (res['success'] == true && mounted) {
        setState(() {
          _projects = (res['data'] as List<dynamic>? ?? []);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadMilestones(String projectId) async {
    if (_token == null) return;
    try {
      final res = await TaskService.getMilestones(_token!, projectId);
      if (mounted) {
        setState(() {
          _milestones = (res['data'] as List<dynamic>? ?? []);
        });
      }
    } catch (_) {}
  }

  Future<void> _createProject({
    required String name,
    String? description,
    String priority = 'medium',
    String color = '#FF8FA3',
  }) async {
    if (_token == null) return;
    try {
      await TaskService.createProject(
        _token!,
        name: name,
        description: description,
        priority: priority,
        color: color,
      );
      await _loadProjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Project created'),
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
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _deleteProject(String projectId) async {
    if (_token == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardDark,
        title: const Text(
          'Delete Project',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: const Text(
          'Delete this project and all its milestones?',
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
      await TaskService.deleteProject(_token!, projectId);
      if (_selectedProject?['_id'] == projectId) {
        setState(() {
          _selectedProject = null;
          _milestones = [];
        });
      }
      await _loadProjects();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _createMilestone({
    required String title,
    required String projectId,
    String? description,
    String? dueDate,
  }) async {
    if (_token == null) return;
    try {
      await TaskService.createMilestone(
        _token!,
        title: title,
        projectId: projectId,
        description: description,
        dueDate: dueDate,
      );
      await _loadMilestones(projectId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Milestone created'),
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
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _deleteMilestone(String milestoneId, String projectId) async {
    if (_token == null) return;
    try {
      await TaskService.deleteMilestone(_token!, milestoneId);
      await _loadMilestones(projectId);
    } catch (_) {}
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Analytics Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  Future<void> _loadAnalytics() async {
    if (_token == null) return;
    setState(() => _analyticsLoading = true);
    try {
      final results = await Future.wait([
        TaskService.getTaskStatistics(_token!),
        TaskService.getProductivityAnalytics(_token!),
        TaskService.getWorkloadDistribution(_token!),
      ]);
      if (mounted) {
        setState(() {
          final statsRes = results[0] as Map<String, dynamic>;
          final prodRes = results[1] as Map<String, dynamic>;
          final workRes = results[2] as Map<String, dynamic>;
          _analyticsStats = statsRes['success'] == true ? statsRes['data'] : null;
          _analyticsProductivity =
              prodRes['success'] == true ? (prodRes['data'] as List<dynamic>? ?? []) : [];
          _analyticsWorkload =
              workRes['success'] == true ? (workRes['data'] as List<dynamic>? ?? []) : [];
          _analyticsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _analyticsLoading = false);
    }
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Workflow Loading (Enhanced) Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  Future<void> _loadWorkflows() async {
    if (_token == null) {
      print('[Workflows] No token available');
      return;
    }
    
    if (mounted) {
      setState(() => _workflowsLoading = true);
    }
    
    try {
      print('[Workflows] Fetching workflow templates...');
      final response = await WorkflowService.getTemplates(_token!);
      
      print('[Workflows] API Response type: ${response.runtimeType}');
      print('[Workflows] API Response: $response');
      
      if (!mounted) return;
      
      setState(() {
        _workflows = [];
        
        // Try multiple response format interpretations
        if (response is Map<String, dynamic>) {
          // Format 1: { success: true, data: [...] }
          if (response['success'] == true && response['data'] != null) {
            _workflows = (response['data'] as List<dynamic>?)?.cast<dynamic>() ?? [];
            print('[Workflows] Parsed success response with ${_workflows.length} templates');
          } 
          // Format 2: { data: [...] } or wrapped response
          else if (response['data'] != null) {
            _workflows = (response['data'] as List<dynamic>?)?.cast<dynamic>() ?? [];
            print('[Workflows] Parsed data field with ${_workflows.length} templates');
          }
          // Format 3: Response is directly the wrapper (check for expected fields)
          else if (response.containsKey('_id') || response.containsKey('name') || response.containsKey('steps')) {
            // Looks like a single workflow object, not a list
            _workflows = [response];
            print('[Workflows] Single workflow object detected');
          }
        } 
        // Format 4: Response is directly a list
        else if (response is List<dynamic>) {
          _workflows = response.cast<dynamic>();
          print('[Workflows] Parsed direct list with ${_workflows.length} templates');
        }
        
        _workflowsLoading = false;
        
        if (_workflows.isEmpty) {
          print('[Workflows] WARNING: No workflows loaded after parsing');
        } else {
          print('[Workflows] Successfully loaded ${_workflows.length} workflows');
          // Debug first workflow structure
          if (_workflows.isNotEmpty) {
            print('[Workflows] First workflow keys: ${(_workflows[0] as Map?)?.keys.toList()}');
          }
        }
      });
    } catch (e) {
      print('[Workflows] ERROR loading workflows: $e');
      if (mounted) {
        setState(() => _workflowsLoading = false);
      }
    }
  }

  /// Display workflow templates dialog (uses new WorkflowTemplateManager widget)
  void _showWorkflowTemplatesDialog() {
    if (_token == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => WorkflowTemplateManager(
        token: _token!,
        onSelectTemplate: (workflow) {
          setState(() => _selectedWorkflow = workflow);
          Navigator.pop(context);
        },
      ),
    );
  }

  /// API: Save workflow (create or update)
  Future<void> _saveWorkflowTemplate() async {
    if (_token == null || _workflowFormName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workflow name is required'),
          backgroundColor: Color(0xFFEF5350),
        ),
      );
      return;
    }

    // Validate at least one step with title
    final validSteps = _workflowFormSteps.where((s) => (s['title'] as String?)?.trim().isNotEmpty == true).toList();
    if (validSteps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one step with a title'),
          backgroundColor: Color(0xFFEF5350),
        ),
      );
      return;
    }

    setState(() => _workflowSaving = true);
    try {
      final steps = validSteps.asMap().entries.map<Map<String, dynamic>>((e) {
        final step = e.value;
        return {
          'order': e.key + 1,
          'title': step['title'] ?? '',
          'description': step['description'] ?? '',
          'responsibleRole': step['responsibleRole'] ?? 'any',
        };
      }).toList();

      if (_editorPanel == 'create') {
        await WorkflowService.createTemplate(
          _token!,
          name: _workflowFormName.trim(),
          description: _workflowFormDesc.isEmpty ? null : _workflowFormDesc,
        );
      } else if (_editorPanel == 'edit' && _editingWorkflow != null) {
        await WorkflowService.updateTemplate(
          _token!,
          _editingWorkflow!['_id'],
          name: _workflowFormName.trim(),
          description: _workflowFormDesc,
          isShared: _workflowFormShared,
          steps: steps,
        );
      }

      await _loadWorkflows();
      if (mounted) {
        setState(() => _editorPanel = 'list');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workflow "${_workflowFormName.trim()}" ${_editingWorkflow == null ? 'created' : 'updated'}'),
            backgroundColor: _accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF5350),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _workflowSaving = false);
    }
  }

  /// API: Delete workflow template
  Future<void> _deleteWorkflowTemplate(String templateId, String templateName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardDark,
        title: const Text(
          'Delete Workflow?',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Delete template "$templateName"? Tasks that already use it will keep their copy.',
          style: TextStyle(color: _textGrey.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: _textGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF5350))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (_token == null) return;
    try {
      await WorkflowService.deleteTemplate(_token!, templateId);
      await _loadWorkflows();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$templateName" deleted'),
            backgroundColor: _accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF5350),
          ),
        );
      }
    }
  }

  /// API: Duplicate workflow template
  Future<void> _duplicateWorkflowTemplate(String templateId, String templateName) async {
    if (_token == null) return;
    try {
      await WorkflowService.duplicateTemplate(_token!, templateId);
      await _loadWorkflows();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copy of "$templateName" created'),
            backgroundColor: _accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF5350),
          ),
        );
      }
    }
  }

  /// Helper: Add a new step
  void _addWorkflowStep() {
    setState(() {
      _workflowFormSteps.add({
        'order': _workflowFormSteps.length + 1,
        'title': '',
        'description': '',
        'responsibleRole': 'any',
      });
    });
  }

  /// Helper: Remove step by index
  void _removeWorkflowStep(int index) {
    setState(() {
      _workflowFormSteps.removeAt(index);
      // Re-order remaining steps
      for (int i = 0; i < _workflowFormSteps.length; i++) {
        _workflowFormSteps[i]['order'] = i + 1;
      }
    });
  }

  /// Helper: Move step up/down
  void _moveWorkflowStep(int index, int direction) {
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _workflowFormSteps.length) return;

    setState(() {
      final temp = _workflowFormSteps[index];
      _workflowFormSteps[index] = _workflowFormSteps[newIndex];
      _workflowFormSteps[newIndex] = temp;
      // Re-order
      for (int i = 0; i < _workflowFormSteps.length; i++) {
        _workflowFormSteps[i]['order'] = i + 1;
      }
    });
  }

  /// Helper: Update step field
  void _updateWorkflowStep(int index, String field, String value) {
    setState(() {
      _workflowFormSteps[index][field] = value;
    });
  }

  /// Get color for role badge
  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFEF5350);
      case 'hr':
        return const Color(0xFF9C27B0);
      case 'employee':
        return _accentGreen;
      default:
        return _textGrey;
    }
  }

  /// Decodes the JWT payload (no signature verification neededÃ¢â‚¬â€server
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

      if (showLoading) {
        setState(() => _isLoading = true);
      }

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
              'assigned': (statsRes['data']['assigned'] as int?) ??
                  _tasks.where((t) => t['status'] == 'assigned').length,
              'todo': (statsRes['data']['todo'] ?? 0) as int,
              'inProgress': (statsRes['data']['inProgress'] ?? 0) as int,
              'completed': (statsRes['data']['completed'] ?? 0) as int,
              'overdue': (statsRes['data']['overdue'] ?? 0) as int,
              'cancelled': (statsRes['data']['cancelled'] ?? 0) as int,
              'pending': (statsRes['data']['pending'] ?? 0) as int,
              'underReview': (statsRes['data']['underReview'] ?? 0) as int,
            };
          } else {
            _stats = {
              'total': _tasks.length,
              'assigned':
                  _tasks.where((t) => t['status'] == 'assigned').length,
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

  // Ã¢â€â‚¬Ã¢â€â‚¬ Filtering Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  List<dynamic> get _filteredTasks {
    var list = _tasks.where((t) {
      final q = _searchQuery.toLowerCase();
      if (q.isEmpty) return true;
      return (t['title'] ?? '').toString().toLowerCase().contains(q) ||
          (t['description'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      list = list.where((t) => t['status'] == _statusFilter).toList();
    }
    if (_employeePriorityFilter != null &&
        _employeePriorityFilter!.isNotEmpty) {
      list = list
          .where(
            (t) =>
                (t['priority'] ?? '').toString().toLowerCase() ==
                _employeePriorityFilter,
          )
          .toList();
    }
    if (_quickFilter == 'overdue') {
      final now = DateTime.now();
      list = list.where((t) {
        final due = t['dueDate'];
        if (due == null) return false;
        try {
          return DateTime.parse(due.toString()).isBefore(now) &&
              t['status'] != 'completed' && t['status'] != 'closed';
        } catch (_) { return false; }
      }).toList();
    } else if (_quickFilter == 'high-priority') {
      list = list.where((t) =>
        ['high', 'critical'].contains((t['priority'] ?? '').toString().toLowerCase())).toList();
    } else if (_quickFilter != null) {
      list = list.where((t) => t['status'] == _quickFilter).toList();
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
            _adminPriorityFilter) {
          return false;
        }
      }
      if (_adminEmployeeFilter != null && _adminEmployeeFilter!.isNotEmpty) {
        final assignedTo = t['assignedTo'];
        if (assignedTo is Map) {
          if ((assignedTo['_id'] ?? '').toString() != _adminEmployeeFilter) {
            return false;
          }
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

  // Ã¢â€â‚¬Ã¢â€â‚¬ Priority / status helpers Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'critical':
        return const Color(0xFFFF1744);
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
      case 'assigned':
        return Colors.amber;
      case 'draft':
        return Colors.grey;
      case 'pending-approval':
        return Colors.blueAccent;
      case 'under-review':
        return Colors.tealAccent;
      case 'closed':
        return Colors.grey;
      case 'rejected':
        return Colors.redAccent;
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
      case 'assigned':
        return 'Assigned';
      case 'draft':
        return 'Draft';
      case 'pending-approval':
        return 'Pending Approval';
      case 'under-review':
        return 'Under Review';
      case 'closed':
        return 'Closed';
      case 'rejected':
        return 'Rejected';
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

  bool _isOverdue(dynamic task) {
    final status = (task['status'] ?? '').toString();
    if (status == 'completed' || status == 'cancelled') return false;
    final due = task['dueDate'];
    if (due == null) return false;
    try {
      return DateTime.parse(due.toString()).toLocal().isBefore(
            DateTime.now().subtract(const Duration(hours: 1)),
          );
    } catch (_) {
      return false;
    }
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Task detail / update sheet Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  void _showTaskDetail(Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskDetailSheet(task: task, token: _token),
    );
  }

  Future<void> _showUpdateDialog(Map<String, dynamic> task) async {
    double progress = ((task['progress'] ?? 0) as num).toDouble();
    final subTasks = (task['subTasks'] as List<dynamic>? ?? []);

    // Mutable local copy of task data (for live updates of comments/attachments)
    Map<String, dynamic> taskData = Map<String, dynamic>.from(task);

    // Comments state
    List<dynamic> comments = List<dynamic>.from(taskData['comments'] ?? []);
    final commentCtrl = TextEditingController();
    bool commentSubmitting = false;

    // Attachments state
    List<dynamic> attachments = List<dynamic>.from(taskData['attachments'] ?? []);
    bool attachmentUploading = false;

    String? sheetAction;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DefaultTabController(
          length: 5,
          child: StatefulBuilder(
            builder: (stateContext, ss) {
              // Ã¢â€â‚¬Ã¢â€â‚¬ helpers scoped to the sheet Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
              void addCommentAction() async {
                final text = commentCtrl.text.trim();
                if (text.isEmpty || _token == null) return;
                ss(() => commentSubmitting = true);
                try {
                  final res = await TaskService.addComment(
                    _token!,
                    taskData['_id'].toString(),
                    content: text,
                  );
                  final updated = res['data'];
                  if (updated != null) {
                    ss(() {
                      comments = List<dynamic>.from(updated['comments'] ?? comments);
                      commentCtrl.clear();
                    });
                  } else {
                    // Optimistic update
                    ss(() {
                      comments = [...comments, {'content': text, 'user': {'name': 'You'}, 'createdAt': DateTime.now().toIso8601String()}];
                      commentCtrl.clear();
                    });
                  }
                  await _loadData(showLoading: false);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ));
                  }
                } finally {
                  ss(() => commentSubmitting = false);
                }
              }

              void deleteCommentAction(String commentId) async {
                if (_token == null) return;
                try {
                  await TaskService.deleteComment(_token!, taskData['_id'].toString(), commentId);
                  ss(() => comments = comments.where((c) => c['_id']?.toString() != commentId).toList());
                  await _loadData(showLoading: false);
                } catch (_) {}
              }

              void pickAndUploadFile() async {
                if (_token == null) return;
                try {
                  final result = await FilePicker.platform.pickFiles();
                  if (result == null || result.files.isEmpty) return;
                  final file = result.files.first;
                  if (file.path == null) return;
                  ss(() => attachmentUploading = true);
                  await TaskService.addAttachment(
                    _token!,
                    taskData['_id'].toString(),
                    filePath: file.path!,
                    fileName: file.name,
                    fileType: file.extension ?? 'document',
                  );
                  // Reload task to get updated attachments
                  await _loadData(showLoading: false);
                  final fresh = _tasks.firstWhere(
                    (t) => t['_id']?.toString() == taskData['_id']?.toString(),
                    orElse: () => taskData,
                  );
                  ss(() => attachments = List<dynamic>.from(fresh['attachments'] ?? attachments));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('File uploaded'),
                      backgroundColor: _accentGreen,
                    ));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ));
                  }
                } finally {
                  ss(() => attachmentUploading = false);
                }
              }

              void deleteAttachmentAction(String attachmentId) async {
                if (_token == null) return;
                try {
                  await TaskService.deleteAttachment(_token!, taskData['_id'].toString(), attachmentId);
                  ss(() => attachments = attachments.where((a) => a['_id']?.toString() != attachmentId).toList());
                  await _loadData(showLoading: false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Attachment deleted'),
                      backgroundColor: _accentGreen,
                    ));
                  }
                } catch (_) {}
              }

              // Ã¢â€â‚¬Ã¢â€â‚¬ Activity timeline builder Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
              List<Map<String, dynamic>> buildTimeline() {
                final items = <Map<String, dynamic>>[];
                for (final e in (taskData['workflowHistory'] ?? [])) {
                  items.add({
                    'type': 'workflow',
                    'icon': Icons.swap_horiz,
                    'iconColor': const Color(0xFF60A5FA),
                    'user': _getUserName(e['performedBy']),
                    'action': '${_statusLabel(e['fromStatus'] ?? '')} Ã¢â€ â€™ ${_statusLabel(e['toStatus'] ?? '')}',
                    'detail': e['comment'],
                    'time': e['timestamp'],
                  });
                }
                for (final e in (taskData['activityLog'] ?? [])) {
                  items.add({
                    'type': 'activity',
                    'icon': Icons.edit_outlined,
                    'iconColor': _textGrey,
                    'user': _getUserName(e['user']),
                    'action': (e['action'] ?? '').toString().replaceAll('_', ' '),
                    'detail': e['details'],
                    'time': e['createdAt'],
                  });
                }
                items.sort((a, b) {
                  final ta = DateTime.tryParse(a['time']?.toString() ?? '') ?? DateTime(0);
                  final tb = DateTime.tryParse(b['time']?.toString() ?? '') ?? DateTime(0);
                  return tb.compareTo(ta);
                });
                return items;
              }

              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.85,
                minChildSize: 0.5,
                maxChildSize: 0.97,
                builder: (_, scroll) => Column(
                  children: [
                    // Ã¢â€â‚¬Ã¢â€â‚¬ Drag handle Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    // Ã¢â€â‚¬Ã¢â€â‚¬ Header Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  taskData['title'] ?? 'Task',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _statusColor(taskData['status'] ?? 'todo').withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: _statusColor(taskData['status'] ?? 'todo').withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        _statusLabel(taskData['status'] ?? 'todo'),
                                        style: TextStyle(color: _statusColor(taskData['status'] ?? 'todo'), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _priorityColor(taskData['priority'] ?? 'medium').withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        (taskData['priority'] ?? 'medium').toString().toUpperCase(),
                                        style: TextStyle(color: _priorityColor(taskData['priority'] ?? 'medium'), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit task',
                            onPressed: () { sheetAction = 'edit'; Navigator.pop(sheetContext); },
                            icon: Icon(Icons.edit_outlined, color: _accentPink, size: 20),
                          ),
                        ],
                      ),
                    ),
                    // Ã¢â€â‚¬Ã¢â€â‚¬ Tab bar Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      decoration: BoxDecoration(
                        color: _inputDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: _accentPink.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _accentPink.withValues(alpha: 0.4)),
                        ),
                        labelColor: _accentPink,
                        unselectedLabelColor: _textGrey,
                        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        padding: const EdgeInsets.all(4),
                        tabs: [
                          const Tab(text: 'Details'),
                          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Text('Comments', style: TextStyle(fontSize: 11)),
                            if (comments.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(color: _accentPink, borderRadius: BorderRadius.circular(8)),
                                child: Text('${comments.length}', style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ])),
                          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Text('Files', style: TextStyle(fontSize: 11)),
                            if (attachments.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(color: _accentOrange, borderRadius: BorderRadius.circular(8)),
                                child: Text('${attachments.length}', style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ])),
                          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Text('Workflow', style: TextStyle(fontSize: 11)),
                            if ((taskData['taskWorkflow']?['steps'] as List?)?.isNotEmpty == true) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(color: _accentPurple, borderRadius: BorderRadius.circular(8)),
                                child: Text('${(taskData['taskWorkflow']?['steps'] as List?)?.length ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ])),
                          const Tab(text: 'Activity'),
                        ],
                      ),
                    ),
                    // Ã¢â€â‚¬Ã¢â€â‚¬ Tab content Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Ã¢â€¢ÂÃ¢â€¢Â TAB 0: DETAILS Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
                          ListView(
                            controller: scroll,
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                            children: [
                              if ((taskData['description'] ?? '').toString().isNotEmpty) ...[
                                Text(
                                  taskData['description'].toString(),
                                  style: TextStyle(color: _textGrey, fontSize: 13, height: 1.5),
                                ),
                                const SizedBox(height: 16),
                              ],
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: [
                                  _metaChip(
                                    label: (taskData['priority'] ?? 'medium').toString().toUpperCase(),
                                    color: _priorityColor((taskData['priority'] ?? 'medium').toString()),
                                    icon: Icons.flag_outlined,
                                  ),
                                  _metaChip(
                                    label: _formatDate(taskData['dueDate']),
                                    color: _textGrey,
                                    icon: Icons.calendar_today_outlined,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Tags
                              if ((taskData['tags'] as List?)?.isNotEmpty == true) ...[
                                Text('Tags', style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6, runSpacing: 6,
                                  children: (taskData['tags'] as List).map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _inputDark,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.label_outline, size: 11, color: _accentPink),
                                      const SizedBox(width: 4),
                                      Text(tag.toString(), style: const TextStyle(color: Colors.white, fontSize: 11)),
                                    ]),
                                  )).toList(),
                                ),
                                const SizedBox(height: 16),
                              ],
                              const Divider(color: Colors.white10),
                              const SizedBox(height: 12),
                              // Progress
                              Row(
                                children: [
                                  Text('Progress', style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(color: _accentPink.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(12)),
                                    child: Text('${progress.toInt()}%', style: TextStyle(color: _accentPink, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SliderTheme(
                                data: SliderTheme.of(stateContext).copyWith(
                                  activeTrackColor: _accentPink,
                                  inactiveTrackColor: Colors.white12,
                                  thumbColor: _accentPink,
                                  overlayColor: _accentPink.withValues(alpha: 0.15),
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                ),
                                child: Slider(
                                  value: progress, min: 0, max: 100, divisions: 20,
                                  onChanged: (v) => ss(() => progress = v),
                                ),
                              ),
                              Text(
                                'Status updates automatically: 100% Ã¢â€ â€™ Completed, <100% Ã¢â€ â€™ In Progress',
                                style: TextStyle(color: _textGrey.withValues(alpha: 0.55), fontSize: 11),
                              ),
                              // Subtasks
                              if (subTasks.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Divider(color: Colors.white10),
                                const SizedBox(height: 12),
                                Text(
                                  'Subtasks (${subTasks.where((s) => s['status'] == 'completed').length}/${subTasks.length})',
                                  style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 10),
                                ...subTasks.map((sub) {
                                  final done = sub['status'] == 'completed';
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: _inputDark,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                    ),
                                    child: CheckboxListTile(
                                      dense: true,
                                      value: done,
                                      activeColor: _accentGreen,
                                      checkColor: Colors.black,
                                      side: BorderSide(color: _textGrey.withValues(alpha: 0.4)),
                                      onChanged: (_) {
                                        Navigator.pop(sheetContext);
                                        _toggleSubTask(taskData['_id'].toString(), sub['_id'].toString(), !done);
                                      },
                                      title: Text(
                                        sub['title'] ?? '',
                                        style: TextStyle(
                                          color: done ? _textGrey : Colors.white,
                                          fontSize: 13,
                                          decoration: done ? TextDecoration.lineThrough : null,
                                          decorationColor: _textGrey,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                              // Review card
                              if (taskData['review'] != null) ...[
                                const SizedBox(height: 16),
                                ..._buildReviewCard(taskData['review'] as Map<String, dynamic>),
                              ],
                              const SizedBox(height: 16),
                              // Save button inline in scroll for details
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accentPink, foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  onPressed: () { sheetAction = 'update'; Navigator.pop(sheetContext); },
                                  icon: const Icon(Icons.check_circle_outline, size: 18),
                                  label: const Text('Save Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                              ),
                            ],
                          ),

                          // Ã¢â€¢ÂÃ¢â€¢Â TAB 1: COMMENTS Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
                          Column(
                            children: [
                              // Add comment input
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: commentCtrl,
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                        maxLines: null,
                                        decoration: InputDecoration(
                                          hintText: 'Add a comment...',
                                          hintStyle: TextStyle(color: _textGrey.withValues(alpha: 0.5), fontSize: 13),
                                          filled: true,
                                          fillColor: _inputDark,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: _accentPink.withValues(alpha: 0.5)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: commentSubmitting ? null : addCommentAction,
                                      child: Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(
                                          color: _accentPink,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: commentSubmitting
                                            ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                            : const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Comments list
                              Expanded(
                                child: comments.isEmpty
                                    ? Center(
                                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                                          Icon(Icons.chat_bubble_outline, size: 40, color: _textGrey.withValues(alpha: 0.3)),
                                          const SizedBox(height: 8),
                                          Text('No comments yet', style: TextStyle(color: _textGrey, fontSize: 13)),
                                        ]),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                        itemCount: comments.length,
                                        reverse: true,
                                        itemBuilder: (_, i) {
                                          final c = comments[comments.length - 1 - i];
                                          final userName = _getUserName(c['user']);
                                          final initials = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
                                          final commentId = c['_id']?.toString();
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 10),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: _inputDark,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: _accentPink.withValues(alpha: 0.2),
                                                  child: Text(initials, style: TextStyle(color: _accentPink, fontSize: 12, fontWeight: FontWeight.bold)),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(userName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                                          const Spacer(),
                                                          Text(_formatDate(c['createdAt']), style: TextStyle(color: _textGrey.withValues(alpha: 0.5), fontSize: 10)),
                                                          if (commentId != null) ...[
                                                            const SizedBox(width: 4),
                                                            GestureDetector(
                                                              onTap: () => deleteCommentAction(commentId),
                                                              child: Icon(Icons.delete_outline, size: 14, color: _textGrey.withValues(alpha: 0.5)),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(c['content']?.toString() ?? '', style: TextStyle(color: _textGrey, fontSize: 13, height: 1.4)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),

                          // Ã¢â€¢ÂÃ¢â€¢Â TAB 2: ATTACHMENTS Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
                          Column(
                            children: [
                              // Upload button
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                child: GestureDetector(
                                  onTap: attachmentUploading ? null : pickAndUploadFile,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _accentPink.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _accentPink.withValues(alpha: 0.3), style: BorderStyle.solid),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (attachmentUploading)
                                          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pinkAccent))
                                        else
                                          Icon(Icons.upload_file_outlined, color: _accentPink, size: 18),
                                        const SizedBox(width: 8),
                                        Text(attachmentUploading ? 'Uploading...' : 'Upload File', style: TextStyle(color: _accentPink, fontSize: 13, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Attachments list
                              Expanded(
                                child: attachments.isEmpty
                                    ? Center(
                                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                                          Icon(Icons.attach_file, size: 40, color: _textGrey.withValues(alpha: 0.3)),
                                          const SizedBox(height: 8),
                                          Text('No files attached', style: TextStyle(color: _textGrey, fontSize: 13)),
                                          const SizedBox(height: 4),
                                          Text('Tap "Upload File" to attach a file', style: TextStyle(color: _textGrey.withValues(alpha: 0.5), fontSize: 11)),
                                        ]),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                        itemCount: attachments.length,
                                        itemBuilder: (_, i) {
                                          final att = attachments[i];
                                          final name = att['name']?.toString() ?? 'File';
                                          final type = att['type']?.toString() ?? 'document';
                                          final attId = att['_id']?.toString();
                                          final uploadedBy = _getUserName(att['uploadedBy']);
                                          IconData typeIcon;
                                          Color typeColor;
                                          switch (type) {
                                            case 'image': typeIcon = Icons.image_outlined; typeColor = const Color(0xFF60A5FA); break;
                                            case 'video': typeIcon = Icons.videocam_outlined; typeColor = const Color(0xFFA78BFA); break;
                                            default: typeIcon = Icons.insert_drive_file_outlined; typeColor = _accentOrange;
                                          }
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 10),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: _inputDark,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 40, height: 40,
                                                  decoration: BoxDecoration(
                                                    color: typeColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Icon(typeIcon, color: typeColor, size: 20),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                      Row(children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                                          child: Text(type.toUpperCase(), style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.bold)),
                                                        ),
                                                        if (uploadedBy.isNotEmpty) ...[
                                                          const SizedBox(width: 6),
                                                          Text('by $uploadedBy', style: TextStyle(color: _textGrey.withValues(alpha: 0.5), fontSize: 10)),
                                                        ],
                                                        const SizedBox(width: 6),
                                                        Text(_formatDate(att['uploadedAt']), style: TextStyle(color: _textGrey.withValues(alpha: 0.4), fontSize: 10)),
                                                      ]),
                                                    ],
                                                  ),
                                                ),
                                                if (attId != null)
                                                  IconButton(
                                                    tooltip: 'Delete',
                                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                                    onPressed: () => deleteAttachmentAction(attId),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),

                          // TAB 3: WORKFLOW
                          WorkflowTabWidget(
                            taskData: taskData,
                            token: _token,
                            statusGreen: _accentGreen,
                            statusPink: _accentPink,
                            statusOrange: _accentOrange,
                            textGrey: _textGrey,
                            inputDark: _inputDark,
                            onStepCompleted: () => setState(() {}),
                            formatDate: _formatDate, workflow: null, onStepComplete: null, onWorkflowAction: null,
                          ),

                          // Ã¢â€¢ÂÃ¢â€¢Â TAB 4: ACTIVITY Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
                          Builder(builder: (_) {
                            final timeline = buildTimeline();
                            if (timeline.isEmpty) {
                              return Center(
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.history, size: 40, color: _textGrey.withValues(alpha: 0.3)),
                                  const SizedBox(height: 8),
                                  Text('No activity recorded', style: TextStyle(color: _textGrey, fontSize: 13)),
                                ]),
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                              itemCount: timeline.length,
                              itemBuilder: (_, i) {
                                final item = timeline[i];
                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Timeline line + dot
                                      SizedBox(
                                        width: 32,
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 28, height: 28,
                                              decoration: BoxDecoration(
                                                color: (item['iconColor'] as Color).withValues(alpha: 0.15),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: (item['iconColor'] as Color).withValues(alpha: 0.3)),
                                              ),
                                              child: Icon(item['icon'] as IconData, size: 13, color: item['iconColor'] as Color),
                                            ),
                                            if (i < timeline.length - 1)
                                              Expanded(child: Container(width: 1, color: Colors.white.withValues(alpha: 0.07))),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Content
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: RichText(
                                                      text: TextSpan(
                                                        children: [
                                                          TextSpan(text: item['user']?.toString() ?? 'System', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                                          const TextSpan(text: '  ', style: TextStyle(fontSize: 12)),
                                                          TextSpan(text: item['action']?.toString() ?? '', style: TextStyle(color: _textGrey, fontSize: 12)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if ((item['detail'] ?? '').toString().isNotEmpty) ...[
                                                const SizedBox(height: 3),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.04),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text('"${item['detail']}"', style: TextStyle(color: _textGrey, fontSize: 11, fontStyle: FontStyle.italic)),
                                                ),
                                              ],
                                              const SizedBox(height: 3),
                                              Text(_formatDate(item['time']), style: TextStyle(color: _textGrey.withValues(alpha: 0.4), fontSize: 10)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (!mounted) return;

    if (sheetAction == 'edit') {
      await Future.delayed(const Duration(milliseconds: 200));
      _showEditTaskDialog(task);
    } else if (sheetAction == 'update') {
      await _updateProgress(task['_id'].toString(), progress.toInt());
    }
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Helper: extract user name from a user field Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  String _getUserName(dynamic user) {
    if (user == null) return '';
    if (user is Map) return user['name']?.toString() ?? user['email']?.toString() ?? '';
    return user.toString();
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

  // Ã¢â€â‚¬Ã¢â€â‚¬ Edit task dialog Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Future<void> _showEditTaskDialog(Map<String, dynamic> task) async {
    final titleCtrl = TextEditingController(
      text: task['title']?.toString() ?? '',
    );
    final descCtrl = TextEditingController(
      text: task['description']?.toString() ?? '',
    );
    final tagCtrl = TextEditingController();
    String selectedPriority = (task['priority'] ?? 'medium')
        .toString()
        .toLowerCase();

    // Parse existing estimated time
    final existingEst = task['estimatedTime'];
    String? estimatedPreset;
    final estimatedCustomCtrl = TextEditingController();
    if (existingEst != null) {
      final estInt = (existingEst as num).toInt();
      if (estInt == 240) {
        estimatedPreset = '240';
      } else if (estInt == 480) {
        estimatedPreset = '480';
      } else {
        estimatedPreset = null;
        estimatedCustomCtrl.text = (estInt / 60).toStringAsFixed(1);
      }
    }

    // Parse start date
    DateTime? selectedStartDate;
    if (task['startDate'] != null) {
      try {
        selectedStartDate = DateTime.parse(task['startDate'].toString()).toLocal();
      } catch (_) {}
    }

    // Parse due date
    DateTime? selectedDueDate;
    if (task['dueDate'] != null) {
      try {
        selectedDueDate = DateTime.parse(task['dueDate'].toString()).toLocal();
      } catch (_) {}
    }

    // Parse tags
    List<String> tags = [];
    if (task['tags'] is List) {
      tags = (task['tags'] as List).map((t) => t.toString()).toList();
    }

    // Workflow: pre-populate if task already has one
    String? selectedEditWorkflow;
    final existingWf = task['workflow'];
    if (existingWf is Map) {
      selectedEditWorkflow = (existingWf['_id'] ?? existingWf['id'])?.toString();
    } else if (existingWf is String && existingWf.isNotEmpty) {
      selectedEditWorkflow = existingWf;
    }

    bool submitting = false;

    Future<DateTime?> pickDateTime(
      BuildContext ctx,
      DateTime? initial,
    ) async {
      final date = await showDatePicker(
        context: ctx,
        initialDate: initial ?? DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (_, c) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme:
                ColorScheme.dark(primary: _accentPink, surface: _cardDark),
          ),
          child: c!,
        ),
      );
      if (date == null) return null;
      final time = await showTimePicker(
        context: ctx,
        initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
        builder: (_, c) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme:
                ColorScheme.dark(primary: _accentPink, surface: _cardDark),
          ),
          child: c!,
        ),
      );
      if (time == null) return date;
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }

    try {
      final result = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: _cardDark,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (_, ss) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ã¢â€â‚¬Ã¢â€â‚¬ Drag handle Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
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

                      // Ã¢â€â‚¬Ã¢â€â‚¬ Title Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                      _inputLabel('Title *'),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: titleCtrl,
                        hint: 'Task title',
                        ctx: sheetContext,
                      ),
                      const SizedBox(height: 16),

                      // Ã¢â€â‚¬Ã¢â€â‚¬ Description Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                      _inputLabel('Description'),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: descCtrl,
                        hint: 'Task description',
                        maxLines: 3,
                        ctx: sheetContext,
                      ),
                      const SizedBox(height: 16),

                      // Ã¢â€â‚¬Ã¢â€â‚¬ Priority + Estimated Time Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _inputLabel('Priority'),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    'low',
                                    'medium',
                                    'high',
                                    'critical',
                                  ].map((p) {
                                    final color = _priorityColor(p);
                                    final sel = selectedPriority == p;
                                    return GestureDetector(
                                      onTap: () =>
                                          ss(() => selectedPriority = p),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: sel
                                              ? color.withOpacity(0.18)
                                              : _inputDark,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: sel
                                                ? color
                                                : Colors.transparent,
                                          ),
                                        ),
                                        child: Text(
                                          p[0].toUpperCase() + p.substring(1),
                                          style: TextStyle(
                                            color: sel ? color : _textGrey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _inputLabel('Estimated Time'),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _EstPreset('Custom Hours', null),
                                    _EstPreset('Before Lunch(4h)', '240'),
                                    _EstPreset('End of the Day(8h)', '480'),
                                  ].map((ep) {
                                    final sel = estimatedPreset == ep.value;
                                    return GestureDetector(
                                      onTap: () =>
                                          ss(() => estimatedPreset = ep.value),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: sel
                                              ? _accentPink.withOpacity(0.18)
                                              : _inputDark,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: sel
                                                ? _accentPink
                                                : Colors.transparent,
                                          ),
                                        ),
                                        child: Text(
                                          ep.label,
                                          style: TextStyle(
                                            color: sel
                                                ? _accentPink
                                                : _textGrey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                if (estimatedPreset == null) ...[
                                  const SizedBox(height: 8),
                                  _inputField(
                                    controller: estimatedCustomCtrl,
                                    hint: 'e.g. 2 (hours)',
                                    ctx: sheetContext,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Ã¢â€â‚¬Ã¢â€â‚¬ Start Date & Due Date Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _inputLabel('Start Date & Time'),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await pickDateTime(
                                      sheetContext,
                                      selectedStartDate,
                                    );
                                    if (picked != null) {
                                      ss(() => selectedStartDate = picked);
                                    }
                                  },
                                  child: _dateTimePickerBox(
                                    selectedStartDate,
                                    'Start date & time',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _inputLabel('Due Date & Time'),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await pickDateTime(
                                      sheetContext,
                                      selectedDueDate,
                                    );
                                    if (picked != null) {
                                      ss(() => selectedDueDate = picked);
                                    }
                                  },
                                  child: _dateTimePickerBox(
                                    selectedDueDate,
                                    'Due date & time',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Ã¢â€â‚¬Ã¢â€â‚¬ Tags Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                      _inputLabel('Tags'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _inputField(
                              controller: tagCtrl,
                              hint: 'Add a tag...',
                              ctx: sheetContext,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              final t = tagCtrl.text.trim();
                              if (t.isNotEmpty && !tags.contains(t)) {
                                ss(() {
                                  tags = [...tags, t];
                                  tagCtrl.clear();
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: _accentPink.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _accentPink.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                'Add',
                                style: TextStyle(
                                  color: _accentPink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _accentPink.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _accentPink.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        tag,
                                        style: TextStyle(
                                          color: _accentPink,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => ss(
                                          () => tags = tags
                                              .where((t) => t != tag)
                                              .toList(),
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 12,
                                          color: _accentPink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // â”€â”€ Workflow Template (optional) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _inputLabel('Workflow Template (optional)'),
                          ),
                          GestureDetector(
                            onTap: () => _showWorkflowTemplatesDialog(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _accentPink.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    size: 14,
                                    color: _accentPink,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Manage',
                                    style: TextStyle(
                                      color: _accentPink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _inputDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.07),
                          ),
                        ),
                        child: _workflowsLoading
                            ? const SizedBox(
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFF8FA3),
                                  ),
                                ),
                              )
                            : _workflows.isEmpty
                                ? Text(
                                    'No workflows available',
                                    style: TextStyle(
                                      color: _textGrey.withOpacity(0.6),
                                      fontSize: 14,
                                    ),
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String?>(
                                            isExpanded: true,
                                            value: selectedEditWorkflow,
                                            hint: Text(
                                              'Select workflow...',
                                              style: TextStyle(
                                                color: _textGrey.withOpacity(0.6),
                                                fontSize: 14,
                                              ),
                                            ),
                                            dropdownColor: _cardDark,
                                            items: [
                                              DropdownMenuItem<String?>(
                                                value: null,
                                                child: Text(
                                                  'â€” No workflow â€”',
                                                  style: TextStyle(
                                                    color: _textGrey,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              ..._workflows.map((wf) {
                                                final workflowId = wf['_id'] ?? '';
                                                final workflowName = wf['name'] ?? 'Unnamed';
                                                final stepCount = (wf['steps'] as List<dynamic>?)?.length ?? 0;
                                                return DropdownMenuItem<String?>(
                                                  value: workflowId,
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          workflowName,
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 13,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: _accentPink.withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          '$stepCount steps',
                                                          style: TextStyle(
                                                            color: _accentPink,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ],
                                            onChanged: (value) =>
                                                ss(() => selectedEditWorkflow = value),
                                          ),
                                        ),
                                      ),
                                      if (selectedEditWorkflow != null) ...[
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () =>
                                              ss(() => selectedEditWorkflow = null),
                                          child: Icon(
                                            Icons.close,
                                            color: _accentPink,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                      ),
                      // â”€â”€ Workflow Preview â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      if (selectedEditWorkflow != null && _workflows.isNotEmpty)
                        Builder(
                          builder: (context) {
                            final selectedWfData = _workflows.firstWhere(
                              (w) => (w['_id'] ?? w['id']) == selectedEditWorkflow,
                              orElse: () => null,
                            );
                            if (selectedWfData == null) return const SizedBox.shrink();
                            final steps = selectedWfData['steps'] as List<dynamic>? ?? [];
                            return Column(
                              children: [
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: _cardDark.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _accentPink.withOpacity(0.2),
                                    ),
                                  ),
                                  child: steps.isEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            'No workflow steps defined',
                                            style: TextStyle(
                                              color: _textGrey.withOpacity(0.6),
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                      : Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Text(
                                                '${steps.length} workflow steps',
                                                style: TextStyle(
                                                  color: _accentPink,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            ...steps.asMap().entries.map((entry) {
                                              final idx = entry.key;
                                              final step = entry.value as Map<String, dynamic>;
                                              final title = step['title'] ?? 'Step ${idx + 1}';
                                              final role = step['responsibleRole'] ?? 'any';
                                              Color roleColor;
                                              switch (role.toString().toLowerCase()) {
                                                case 'admin':
                                                  roleColor = Colors.red;
                                                  break;
                                                case 'hr':
                                                  roleColor = _accentPurple;
                                                  break;
                                                case 'employee':
                                                  roleColor = _accentGreen;
                                                  break;
                                                default:
                                                  roleColor = Colors.blue;
                                              }
                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    top: BorderSide(
                                                      color: _textGrey.withOpacity(0.1),
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 28,
                                                      height: 28,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: _accentPink.withOpacity(0.15),
                                                        border: Border.all(
                                                          color: _accentPink.withOpacity(0.3),
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '${idx + 1}',
                                                          style: TextStyle(
                                                            color: _accentPink,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        title,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: roleColor.withOpacity(0.15),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        role,
                                                        style: TextStyle(
                                                          color: roleColor,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                ),
                              ],
                            );
                          },
                        ),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cardDark,
                            foregroundColor: _accentPink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: _accentPink, width: 1.5),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _showTaskDetail(task);
                          },
                          icon: const Icon(Icons.tune_outlined, size: 20),
                          label: const Text(
                            'Manage',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Ã¢â€â‚¬Ã¢â€â‚¬ Save Button Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
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
                                  int? estMinutes;
                                  if (estimatedPreset == '240') {
                                    estMinutes = 240;
                                  } else if (estimatedPreset == '480') {
                                    estMinutes = 480;
                                  } else {
                                    final h = double.tryParse(
                                      estimatedCustomCtrl.text.trim(),
                                    );
                                    if (h != null && h > 0) {
                                      estMinutes = (h * 60).round();
                                    }
                                  }
                                  try {
                                    await _updateTaskDetails(
                                      taskId: task['_id'].toString(),
                                      title: titleCtrl.text.trim(),
                                      description: descCtrl.text.trim(),
                                      priority: selectedPriority,
                                      dueDate: selectedDueDate,
                                      startDate: selectedStartDate,
                                      estimatedTime: estMinutes,
                                      tags: tags,
                                    );
                                    // Assign workflow if selected
                                    if (selectedEditWorkflow != null && _token != null) {
                                      try {
                                        final workflowTemplate = _workflows.firstWhere(
                                          (w) => (w['_id'] ?? w['id']) == selectedEditWorkflow,
                                          orElse: () => null,
                                        );
                                        if (workflowTemplate != null) {
                                          await WorkflowService.assignToTask(
                                            _token!,
                                            task['_id'].toString(),
                                            templateId: selectedEditWorkflow!,
                                            workflowName: workflowTemplate['name'],
                                          );
                                        }
                                      } catch (e) {
                                        print('Error assigning workflow: $e');
                                      }
                                    }
                                    if (sheetContext.mounted) {
                                      Navigator.pop(sheetContext, true);
                                    }
                                  } catch (e) {
                                    if (sheetContext.mounted) {
                                      ss(() => submitting = false);
                                    }
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

      if (result == true && mounted) {
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
      titleCtrl.dispose();
      descCtrl.dispose();
      tagCtrl.dispose();
      estimatedCustomCtrl.dispose();
    }
  }

  /// Pure API call Ã¢â‚¬â€œ caller handles pop, snackbar, and reload.
  Future<void> _updateTaskDetails({
    required String taskId,
    required String title,
    required String description,
    required String priority,
    DateTime? dueDate,
    DateTime? startDate,
    int? estimatedTime,
    List<String>? tags,
  }) async {
    if (_token == null) throw Exception('Not authenticated');
    await TaskService.updateTask(
      _token!,
      taskId,
      title: title,
      description: description.isEmpty ? null : description,
      priority: priority,
      dueDate: dueDate?.toIso8601String(),
      startDate: startDate?.toIso8601String(),
      estimatedTime: estimatedTime,
      tags: tags,
    );
    await NotificationService().showTaskUpdateNotification(
      taskTitle: title,
      updateType: 'updated',
      details: 'Task details have been updated',
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Create Task Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Future<void> _showCreateTaskDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final tagCtrl = TextEditingController();
    String selectedPriority = 'medium';
    // estimated: null = custom, 240 = 4h, 480 = 8h
    String? estimatedPreset; // '240' | '480' | null(custom)
    final estimatedCustomCtrl = TextEditingController();
    DateTime? selectedStartDate;
    DateTime? selectedDueDate;
    List<String> tags = [];
    String? selectedWorkflow;
    String? selectedAssigneeId; // Optional: defaults to current user if null
    bool submitting = false;

    Future<DateTime?> pickDateTime(
      BuildContext ctx,
      DateTime? initial,
    ) async {
      final date = await showDatePicker(
        context: ctx,
        initialDate: initial ?? DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (_, c) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme:
                ColorScheme.dark(primary: _accentPink, surface: _cardDark),
          ),
          child: c!,
        ),
      );
      if (date == null) return null;
      final time = await showTimePicker(
        context: ctx,
        initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
        builder: (_, c) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme:
                ColorScheme.dark(primary: _accentPink, surface: _cardDark),
          ),
          child: c!,
        ),
      );
      if (time == null) return date;
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }

    try {
      final result = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: _cardDark,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (_, ss) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ã¢â€â‚¬Ã¢â€â‚¬ Drag handle Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
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
                            'Create New Task',
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

                      // Ã¢â€â‚¬Ã¢â€â‚¬ Task Title Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                      _inputLabel('Task Title *'),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: titleCtrl,
                        hint: 'Enter task title',
                        ctx: sheetContext,
                      ),
                      const SizedBox(height: 16),

                      // Ã¢â€â‚¬Ã¢â€â‚¬ Description Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                      _inputLabel('Description'),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: descCtrl,
                        hint: 'Enter task description',
                        maxLines: 3,
                        ctx: sheetContext,
                      ),
                      const SizedBox(height: 16),

                      // Ã¢"â‚¬Ã¢"â‚¬ Assign To (Optional) Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬
                      _inputLabel('Assign To (Optional)'),
                      const SizedBox(height: 10),
                      Builder(
                        builder: (ctx) {
                          final selectedEmployee = selectedAssigneeId == null
                              ? null
                              : _employees.cast<Map<String, dynamic>>().firstWhere(
                                  (e) => e['_id']?.toString() == selectedAssigneeId,
                                  orElse: () => <String, dynamic>{},
                                );
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  final picked = await _pickEmployee(sheetContext);
                                  if (picked != null) {
                                    ss(() => selectedAssigneeId = picked);
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _inputDark,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: selectedAssigneeId == null || (selectedEmployee?.isEmpty ?? true)
                                      ? Row(
                                          children: [
                                            Icon(
                                              Icons.person_add,
                                              color: _textGrey,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'You (default)',
                                              style: TextStyle(
                                                color: _textGrey,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor:
                                                  _accentPink.withValues(alpha: 0.2),
                                              child: Text(
                                                (selectedEmployee?['name'] ?? '?')[0]
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
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    selectedEmployee?['name'] ?? '',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    selectedEmployee?['employeeId'] ??
                                                        '',
                                                    style: TextStyle(
                                                      color: _textGrey,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => ss(
                                                () => selectedAssigneeId = null,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                color: _textGrey,
                                                size: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Ã¢"â‚¬Ã¢"â‚¬ Assign To (Optional) Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬Ã¢"â‚¬
                      _inputLabel('Assign To (Optional)'),
                      const SizedBox(height: 10),
                      Builder(
                        builder: (ctx) {
                          final selectedEmployee = selectedAssigneeId == null
                              ? null
                              : _employees.cast<Map<String, dynamic>>().firstWhere(
                                  (e) => e['_id']?.toString() == selectedAssigneeId,
                                  orElse: () => <String, dynamic>{},
                                );
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  final picked = await _pickEmployee(sheetContext);
                                  if (picked != null) {
                                    ss(() => selectedAssigneeId = picked);
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _inputDark,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: selectedAssigneeId == null || (selectedEmployee?.isEmpty ?? true)
                                      ? Row(
                                          children: [
                                            Icon(
                                              Icons.person_add,
                                              color: _textGrey,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'You (default)',
                                              style: TextStyle(
                                                color: _textGrey,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor:
                                                  _accentPink.withValues(alpha: 0.2),
                                              child: Text(
                                                (selectedEmployee?['name'] ?? '?')[0]
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
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    selectedEmployee?['name'] ?? '',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    selectedEmployee?['employeeId'] ??
                                                        '',
                                                    style: TextStyle(
                                                      color: _textGrey,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => ss(
                                                () => selectedAssigneeId = null,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                color: _textGrey,
                                                size: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Ã¢â€â‚¬Ã¢â€â‚¬ Priority + Estimated Time (2 columns) Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Priority
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _inputLabel('Priority *'),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    'low',
                                    'medium',
                                    'high',
                                    'critical',
                                  ].map((p) {
                                    final color = _priorityColor(p);
                                    final sel = selectedPriority == p;
                                    return GestureDetector(
                                      onTap: () =>
                                          ss(() => selectedPriority = p),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: sel
                                              ? color.withOpacity(0.18)
                                              : _inputDark,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: sel
                                                ? color
                                                : Colors.transparent,
                                          ),
                                        ),
                                        child: Text(
                                          p[0].toUpperCase() + p.substring(1),
                                          style: TextStyle(
                                            color: sel ? color : _textGrey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Estimated Time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _inputLabel('Estimated Time'),
                                const SizedBox(height: 8),
                                // Preset chips
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _EstPreset('Custom Hours', null),
                                    _EstPreset('Before Lunch(4h)', '240'),
                                    _EstPreset('End of the Day(8h)', '480'),
                                  ].map((ep) {
                                    final sel = estimatedPreset == ep.value;
                                    return GestureDetector(
                                      onTap: () =>
                                          ss(() => estimatedPreset = ep.value),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: sel
                                              ? _accentPink.withOpacity(0.18)
                                              : _inputDark,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: sel
                                                ? _accentPink
                                                : Colors.transparent,
                                          ),
                                        ),
                                        child: Text(
                                          ep.label,
                                          style: TextStyle(
                                            color: sel
                                                ? _accentPink
                                                : _textGrey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                if (estimatedPreset == null) ...[
                                  const SizedBox(height: 8),
                                  _inputField(
                                    controller: estimatedCustomCtrl,
                                    hint: 'e.g. 2 (hours)',
                                    ctx: sheetContext,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Ã¢â€â‚¬Ã¢â€â‚¬ Start Date & Time Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _inputLabel('Start Date & Time'),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await pickDateTime(
                                      sheetContext,
                                      selectedStartDate,
                                    );
                                    if (picked != null) {
                                      ss(() => selectedStartDate = picked);
                                    }
                                  },
                                  child: _dateTimePickerBox(
                                    selectedStartDate,
                                    'Start date & time',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Due Date & Time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _inputLabel('Due Date & Time *'),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await pickDateTime(
                                      sheetContext,
                                      selectedDueDate,
                                    );
                                    if (picked != null) {
                                      ss(() => selectedDueDate = picked);
                                    }
                                  },
                                  child: _dateTimePickerBox(
                                    selectedDueDate,
                                    'Due date & time',
                                    required: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Ã¢â€â‚¬Ã¢â€â‚¬ Tags Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                      _inputLabel('Tags'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _inputField(
                              controller: tagCtrl,
                              hint: 'Add a tag...',
                              ctx: sheetContext,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              final t = tagCtrl.text.trim();
                              if (t.isNotEmpty && !tags.contains(t)) {
                                ss(() {
                                  tags = [...tags, t];
                                  tagCtrl.clear();
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: _accentPink.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _accentPink.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                'Add',
                                style: TextStyle(
                                  color: _accentPink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _accentPink.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _accentPink.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        tag,
                                        style: TextStyle(
                                          color: _accentPink,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => ss(
                                          () => tags = tags
                                              .where((t) => t != tag)
                                              .toList(),
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 12,
                                          color: _accentPink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 28),

                      // Ã¢â€â‚¬Ã¢â€â‚¬ Workflow Template (optional) Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _inputLabel('Workflow Template (optional)'),
                          ),
                          GestureDetector(
                            onTap: () => _showWorkflowTemplatesDialog(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _accentPink.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    size: 14,
                                    color: _accentPink,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Manage',
                                    style: TextStyle(
                                      color: _accentPink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _inputDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.07),
                          ),
                        ),
                        child: _workflowsLoading
                            ? const SizedBox(
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFF8FA3),
                                  ),
                                ),
                              )
                            : _workflows.isEmpty
                                ? Text(
                                    'No workflows available',
                                    style: TextStyle(
                                      color: _textGrey.withOpacity(0.6),
                                      fontSize: 14,
                                    ),
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String?>(
                                            isExpanded: true,
                                            value: selectedWorkflow,
                                            hint: Text(
                                              'Select workflow...',
                                              style: TextStyle(
                                                color: _textGrey.withOpacity(0.6),
                                                fontSize: 14,
                                              ),
                                            ),
                                            dropdownColor: _cardDark,
                                            items: [
                                              DropdownMenuItem<String?>(
                                                value: null,
                                                child: Text(
                                                  'No workflow',
                                                  style: TextStyle(
                                                    color: _textGrey,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              ..._workflows.map((wf) {
                                                final workflowId = wf['_id'] ?? '';
                                                final workflowName = wf['name'] ?? 'Unnamed';
                                                final stepCount = (wf['steps'] as List<dynamic>?)?.length ?? 0;
                                                return DropdownMenuItem<String?>(
                                                  value: workflowId,
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          workflowName,
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 13,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: _accentPink.withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          '$stepCount steps',
                                                          style: TextStyle(
                                                            color: _accentPink,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ],
                                            onChanged: (value) =>
                                                ss(() => selectedWorkflow = value),
                                          ),
                                        ),
                                      ),
                                      if (selectedWorkflow != null) ...[
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () =>
                                              ss(() => selectedWorkflow = null),
                                          child: Icon(
                                            Icons.close,
                                            color: _accentPink,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                      ),
                      // Ã¢â€â‚¬Ã¢â€â‚¬ Workflow Preview Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                      if (selectedWorkflow != null &&
                          _workflows.isNotEmpty)
                        Builder(
                          builder: (context) {
                            final selectedWfData = _workflows.firstWhere(
                              (w) => (w['_id'] ?? w['id']) == selectedWorkflow,
                              orElse: () => null,
                            );
                            if (selectedWfData == null) {
                              return const SizedBox.shrink();
                            }
                            final steps = selectedWfData['steps'] as List<dynamic>? ?? [];
                            return Column(
                              children: [
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: _cardDark.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _accentPink.withOpacity(0.2),
                                    ),
                                  ),
                                  child: steps.isEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            'No workflow steps defined',
                                            style: TextStyle(
                                              color: _textGrey.withOpacity(0.6),
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                      : Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Text(
                                                '${steps.length} workflow steps',
                                                style: TextStyle(
                                                  color: _accentPink,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            ...steps.asMap().entries.map((entry) {
                                              final idx = entry.key;
                                              final step = entry.value as Map<String, dynamic>;
                                              final title = step['title'] ?? 'Step ${idx + 1}';
                                              final role = step['responsibleRole'] ?? 'any';
                                              
                                              Color roleColor;
                                              switch (role.toLowerCase()) {
                                                case 'admin':
                                                  roleColor = Colors.red;
                                                  break;
                                                case 'hr':
                                                  roleColor = _accentPurple;
                                                  break;
                                                case 'employee':
                                                  roleColor = _accentGreen;
                                                  break;
                                                default:
                                                  roleColor = Colors.blue;
                                              }
                                              
                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    top: BorderSide(
                                                      color: _textGrey.withOpacity(0.1),
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 28,
                                                      height: 28,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color:
                                                            _accentPink.withOpacity(0.15),
                                                        border: Border.all(
                                                          color: _accentPink.withOpacity(
                                                            0.3,
                                                          ),
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '${idx + 1}',
                                                          style: TextStyle(
                                                            color: _accentPink,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        title,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    if (role != null && role != 'any')
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              roleColor.withOpacity(0.15),
                                                          borderRadius:
                                                              BorderRadius.circular(4),
                                                          border: Border.all(
                                                            color: roleColor.withOpacity(
                                                              0.3,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          role,
                                                          style: TextStyle(
                                                            color: roleColor,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                ),
                              ],
                            );
                          },
                        ),
                      const SizedBox(height: 28),

                      // Ã¢â€â‚¬Ã¢â€â‚¬ Submit Button Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
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
                                  if (selectedDueDate == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Due date is required'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  ss(() => submitting = true);
                                  // compute estimatedTime in minutes
                                  int? estMinutes;
                                  if (estimatedPreset == '240') {
                                    estMinutes = 240;
                                  } else if (estimatedPreset == '480') {
                                    estMinutes = 480;
                                  } else {
                                    final h = double.tryParse(
                                      estimatedCustomCtrl.text.trim(),
                                    );
                                    if (h != null && h > 0) {
                                      estMinutes = (h * 60).round();
                                    }
                                  }
                                  try {
                                    final taskId = await _createTask(
                                      title: titleCtrl.text.trim(),
                                      description: descCtrl.text.trim(),
                                      priority: selectedPriority,
                                      dueDate: selectedDueDate,
                                      startDate: selectedStartDate,
                                      estimatedTime: estMinutes,
                                      tags: tags,
                                      assignedTo: selectedAssigneeId,
                                    );
                                    // Assign workflow if selected
                                    if (selectedWorkflow != null && _token != null && taskId != null) {
                                      try {
                                        final workflowTemplate = _workflows.firstWhere(
                                          (w) => (w['_id'] ?? w['id']) == selectedWorkflow,
                                          orElse: () => null,
                                        );
                                        if (workflowTemplate != null) {
                                          await WorkflowService.assignToTask(
                                            _token!,
                                            taskId,
                                            templateId: selectedWorkflow!,
                                            workflowName: workflowTemplate['name'],
                                          );
                                        }
                                      } catch (e) {
                                        print('Error assigning workflow: $e');
                                        // Workflow assignment failure is non-critical
                                      }
                                    }
                                    if (sheetContext.mounted) {
                                      Navigator.pop(sheetContext, true);
                                    }
                                  } catch (e) {
                                    if (sheetContext.mounted) {
                                      ss(() => submitting = false);
                                    }
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

      if (result == true && mounted) {
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
      titleCtrl.dispose();
      descCtrl.dispose();
      tagCtrl.dispose();
      estimatedCustomCtrl.dispose();
    }
  }

  /// Pure API call Ã¢â‚¬â€œ no UI side-effects.
  Future<String?> _createTask({
    required String title,
    required String description,
    required String priority,
    DateTime? dueDate,
    DateTime? startDate,
    int? estimatedTime,
    List<String>? tags,
    String? assignedTo,
  }) async {
    if (_token == null) throw Exception('Not authenticated');
    final assignTo = assignedTo ?? _userId ?? '';
    if (assignTo.isEmpty) throw Exception('User ID not found');
    final response = await TaskService.createTask(
      _token!,
      title: title,
      description: description.isEmpty ? title : description,
      priority: priority,
      dueDate: dueDate != null
          ? dueDate.toIso8601String()
          : DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      assignedTo: assignTo,
      startDate: startDate?.toIso8601String(),
      estimatedTime: estimatedTime,
      tags: tags?.isNotEmpty == true ? tags : null,
    );
    await NotificationService().showTaskAssignedNotification(
      taskTitle: title,
      assignedTo: 'You',
      priority: priority,
    );
    // Extract task ID from response for workflow assignment
    if (response is Map<String, dynamic>) {
      if (response['success'] == true && response['data'] != null) {
        return response['data']['_id'] ?? response['data']['id'];
      } else if (response['data'] != null && response['data'] is Map) {
        return response['data']['_id'] ?? response['data']['id'];
      }
    }
    return null;
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Input helpers Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
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

  /// Consistent date/time picker button.
  Widget _dateTimePickerBox(
    DateTime? value,
    String placeholder, {
    bool required = false,
  }) {
    final hasValue = value != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: _inputDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (required && !hasValue)
              ? _accentPink.withOpacity(0.5)
              : Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_outlined,
            color: hasValue ? _accentPink : _textGrey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasValue
                  ? DateFormat('MMM d, y  HH:mm').format(value)
                  : placeholder,
              style: TextStyle(
                color:
                    hasValue ? Colors.white : _textGrey.withOpacity(0.6),
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

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

  // Ã¢â€â‚¬Ã¢â€â‚¬ Build Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  @override
  Widget build(BuildContext context) {
    // Show admin interface unless this is "My Tasks" view (showOnlyCurrentUser=true)
    if (_isAdmin && widget.showOnlyCurrentUser != true) return _buildAdminScaffold(context);
    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return Column(
              children: [
                _buildHeader(context, isMobile),
                // Ã¢â€â‚¬Ã¢â€â‚¬ Employee Tab Bar Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                _buildTabBar(
                  [
                    {'label': 'List', 'icon': Icons.list_alt_rounded},
                    {'label': 'Kanban', 'icon': Icons.view_column_outlined},
                    {'label': 'Time', 'icon': Icons.timer_outlined},
                  ],
                  _employeeTab,
                  (i) => setState(() => _employeeTab = i),
                ),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: _accentPink),
                        )
                      : _error != null
                      ? _buildError()
                      : IndexedStack(
                          index: _employeeTab,
                          children: [
                            // Ã¢â€â‚¬Ã¢â€â‚¬ Tab 0: List Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                            RefreshIndicator(
                              color: _accentPink,
                              backgroundColor: _cardDark,
                              onRefresh: () => widget.showOnlyCurrentUser == true
                                ? _loadMyTasks(showLoading: false)
                                : _loadData(showLoading: false),
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
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
                                    _buildEmployeeFilterRow(),
                                    const SizedBox(height: 20),
                                    _buildTaskList(),
                                    const SizedBox(height: 80),
                                  ],
                                ),
                              ),
                            ),
                            // Ã¢â€â‚¬Ã¢â€â‚¬ Tab 1: Kanban Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                            _buildKanbanView(_filteredTasks),
                            // Ã¢â€â‚¬Ã¢â€â‚¬ Tab 2: Time Tracking Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                            SingleChildScrollView(
                              child: _buildTimeTrackingTab(),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _employeeTab == 0
          ? FloatingActionButton(
              onPressed: _showCreateTaskDialog,
              backgroundColor: _accentPink,
              foregroundColor: Colors.black,
              elevation: 4,
              child: const Icon(Icons.add, size: 26),
            )
          : null,
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ ADMIN PANEL Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Widget _buildAdminScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildAdminHeader(context),
            // Ã¢â€â‚¬Ã¢â€â‚¬ Admin Tab Bar Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
            _buildTabBar(
              [
                {'label': 'List', 'icon': Icons.list_alt_rounded},
                {'label': 'Kanban', 'icon': Icons.view_column_outlined},
                {'label': 'Employees', 'icon': Icons.group_outlined},
                {'label': 'Projects', 'icon': Icons.folder_outlined},
                {'label': 'Time', 'icon': Icons.timer_outlined},
                {'label': 'Analytics', 'icon': Icons.bar_chart_rounded},
              ],
              _adminTab,
              (i) {
                setState(() => _adminTab = i);
                if (i == 5 && _analyticsStats == null) _loadAnalytics();
                if (i == 4 && _timeLogs.isEmpty) _loadTimeLogs();
                if (i == 4 && _runningTimer == null) _loadRunningTimer();
              },
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: _accentPink))
                  : _error != null
                  ? _buildError()
                  : IndexedStack(
                      index: _adminTab,
                      children: [
                        // Ã¢â€â‚¬Ã¢â€â‚¬ Tab 0: List Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                        RefreshIndicator(
                          color: _accentPink,
                          backgroundColor: _cardDark,
                          onRefresh: () async {
                            if (widget.showOnlyCurrentUser == true) {
                              await _loadMyTasks(showLoading: false);
                            } else {
                              await Future.wait([_loadData(), _loadEmployees()]);
                            }
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
                        // Ã¢â€â‚¬Ã¢â€â‚¬ Tab 1: Kanban Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                        _buildKanbanView(_adminFilteredTasks),
                        // Ã¢â€â‚¬Ã¢â€â‚¬ Tab 2: By Employee Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                        _buildAdminByEmployeeTab(),
                        // Ã¢â€â‚¬Ã¢â€â‚¬ Tab 3: Projects Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                        _buildProjectsTab(),
                        // Ã¢â€â‚¬Ã¢â€â‚¬ Tab 4: Time Tracking Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                        SingleChildScrollView(
                          child: _buildTimeTrackingTab(),
                        ),
                        // Ã¢â€â‚¬Ã¢â€â‚¬ Tab 5: Analytics Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                        SingleChildScrollView(
                          child: _buildAnalyticsTab(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _adminTab == 0
          ? FloatingActionButton.extended(
              onPressed: _showAdminCreateTaskDialog,
              backgroundColor: _accentPink,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Assign Task',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              elevation: 4,
            )
          : (_adminTab == 3
              ? FloatingActionButton(
                  onPressed: _showCreateProjectDialog,
                  backgroundColor: _accentPink,
                  foregroundColor: Colors.black,
                  elevation: 4,
                  tooltip: 'New Project',
                  child: const Icon(Icons.add, size: 26),
                )
              : null),
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
    final pending = _stats['pending'] ?? 0;
    final underReview = _stats['underReview'] ?? 0;
    final statItems = [
      _StatItem('Total', '$total', Icons.folder_outlined, _accentPurple),
      _StatItem('In Progress', '$inProgress', Icons.pending_actions, _accentOrange),
      _StatItem('Completed', '$completed', Icons.check_circle_outline, _accentGreen),
      _StatItem('Overdue', '$overdue', Icons.warning_amber_outlined, Colors.redAccent),
      _StatItem('Pending', '$pending', Icons.schedule, Colors.orangeAccent),
      _StatItem('Under Review', '$underReview', Icons.visibility, Colors.blueAccent),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 360 ? 2 : 3;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.4,
          children: statItems
              .map((s) => _buildStatCard(s.label, s.count, s.icon, s.color))
              .toList(),
        );
      },
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
    final overdue = _isOverdue(task);
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
          border: Border.all(
            color: overdue
                ? Colors.redAccent.withOpacity(0.4)
                : Colors.white.withValues(alpha: 0.06),
            width: overdue ? 1.5 : 1.0,
          ),
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
                            if (overdue) ...[
                              const SizedBox(width: 6),
                              _miniChip('Overdue', Colors.redAccent),
                            ],
                            const Spacer(),
                            // Edit icon
                            GestureDetector(
                              onTap: () => _showEditTaskDialog(task),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.edit_outlined,
                                  color: _accentPink,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Eye icon to show TaskDetailSheet
                            GestureDetector(
                              onTap: () => _showTaskDetail(task),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.visibility_outlined,
                                  color: _textGrey.withValues(alpha: 0.6),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Title
                        Text(
                          task['title'] ?? 'Ã¢â‚¬â€',
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
                              overdue
                                  ? Icons.warning_amber_outlined
                                  : Icons.calendar_today_outlined,
                              color: overdue ? Colors.redAccent : _textGrey,
                              size: 11,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatDate(task['dueDate']),
                              style: TextStyle(
                                color: overdue ? Colors.redAccent : _textGrey,
                                fontSize: 11,
                                fontWeight: overdue
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
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

  // Ã¢â€â‚¬Ã¢â€â‚¬ Review helpers Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
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
                                  if (sheetCtx.mounted) {
                                    Navigator.pop(sheetCtx, true);
                                  }
                                } catch (e) {
                                  if (sheetCtx.mounted) {
                                    ss(() => submitting = false);
                                  }
                                  if (mounted) {
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
                  // IconButton(
                  //   icon: Icon(
                  //     Icons.edit_outlined,
                  //     color: _accentPink,
                  //     size: 20,
                  //   ),
                  //   tooltip: 'Edit',
                  //   onPressed: () => Navigator.pop(sheetCtx, 'edit'),
                  // ),
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
                  // Ã¢â€â‚¬Ã¢â€â‚¬ Existing review display in detail Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
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
    DateTime? selectedStartDate;
    DateTime? selectedDueDate;
    List<String> selectedEmployeeIds = [];
    String? selectedAdminWorkflow;
    bool submitting = false;

    Future<DateTime?> pickDateTime(
      BuildContext ctx,
      DateTime? initial,
    ) async {
      final date = await showDatePicker(
        context: ctx,
        initialDate: initial ?? DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (_, c) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme:
                ColorScheme.dark(primary: _accentPink, surface: _cardDark),
          ),
          child: c!,
        ),
      );
      if (date == null) return null;
      final time = await showTimePicker(
        context: ctx,
        initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
        builder: (_, c) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme:
                ColorScheme.dark(primary: _accentPink, surface: _cardDark),
          ),
          child: c!,
        ),
      );
      if (time == null) return date;
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }

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
            final selectedEmployees = selectedEmployeeIds.isNotEmpty
                ? _employees.where(
                    (e) => selectedEmployeeIds.contains(e['_id']),
                  ).toList()
                : [];
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
                    // Assign To (Multiple Employees)
                    _inputLabel('Assign To (Multiple) *'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await _pickEmployees(sheetCtx);
                        if (picked != null) {
                          ss(() => selectedEmployeeIds = picked);
                        }
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
                            color: selectedEmployeeIds.isNotEmpty
                                ? _accentPink.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                        child: selectedEmployeeIds.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: selectedEmployees.map((emp) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _accentPink.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _accentPink.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              emp['name'] ?? '?',
                                              style: TextStyle(
                                                color: _accentPink,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                              onTap: () => ss(
                                                () => selectedEmployeeIds
                                                    .remove(emp['_id']),
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                size: 14,
                                                color: _accentPink,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        color: _accentPink,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Tap to change',
                                        style: TextStyle(
                                          color: _accentPink
                                              .withValues(alpha: 0.7),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Icon(
                                    Icons.person_add_outlined,
                                    color: _textGrey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Select Employees',
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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _inputLabel('Start Date & Time'),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await pickDateTime(
                                    sheetCtx,
                                    selectedStartDate,
                                  );
                                  if (picked != null) {
                                    ss(() => selectedStartDate = picked);
                                  }
                                },
                                child: _dateTimePickerBox(
                                  selectedStartDate,
                                  'Start date & time',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _inputLabel('Due Date & Time *'),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await pickDateTime(
                                    sheetCtx,
                                    selectedDueDate,
                                  );
                                  if (picked != null) {
                                    ss(() => selectedDueDate = picked);
                                  }
                                },
                                child: _dateTimePickerBox(
                                  selectedDueDate,
                                  'Due date & time',
                                  required: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _inputLabel('Workflow Template (optional)'),
                        ),
                        GestureDetector(
                          onTap: () => _showWorkflowTemplatesDialog(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _accentPink.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  size: 14,
                                  color: _accentPink,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Manage',
                                  style: TextStyle(
                                    color: _accentPink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _inputDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                      child: _workflowsLoading
                          ? const SizedBox(
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFF8FA3),
                                ),
                              ),
                            )
                          : _workflows.isEmpty
                              ? Text(
                                  'No workflows available',
                                  style: TextStyle(
                                    color: _textGrey.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String?>(
                                          isExpanded: true,
                                          value: selectedAdminWorkflow,
                                          hint: Text(
                                            'Select workflow...',
                                            style: TextStyle(
                                              color: _textGrey.withOpacity(0.6),
                                              fontSize: 14,
                                            ),
                                          ),
                                          dropdownColor: _cardDark,
                                          items: [
                                            DropdownMenuItem<String?>(
                                              value: null,
                                              child: Text(
                                                'No workflow',
                                                style: TextStyle(
                                                  color: _textGrey,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            ..._workflows.map((wf) {
                                              final workflowId = wf['_id'] ?? '';
                                              final workflowName = wf['name'] ?? 'Unnamed';
                                              final stepCount = (wf['steps'] as List<dynamic>?)?.length ?? 0;
                                              return DropdownMenuItem<String?>(
                                                value: workflowId,
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        workflowName,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 13,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            _accentPink.withOpacity(0.2),
                                                        borderRadius:
                                                            BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        '$stepCount steps',
                                                        style: TextStyle(
                                                          color: _accentPink,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ],
                                          onChanged: (value) =>
                                              ss(() => selectedAdminWorkflow = value),
                                        ),
                                      ),
                                    ),
                                    if (selectedAdminWorkflow != null) ...[
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () =>
                                            ss(() => selectedAdminWorkflow = null),
                                        child: Icon(
                                          Icons.close,
                                          color: _accentPink,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                    ),
                    // Ã¢â€â‚¬Ã¢â€â‚¬ Workflow Preview Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                    if (selectedAdminWorkflow != null &&
                        _workflows.isNotEmpty)
                      Builder(
                        builder: (context) {
                          final selectedWfData = _workflows.firstWhere(
                            (w) => (w['_id'] ?? w['id']) == selectedAdminWorkflow,
                            orElse: () => null,
                          );
                          if (selectedWfData == null) {
                            return const SizedBox.shrink();
                          }
                          final steps = selectedWfData['steps'] as List<dynamic>? ?? [];
                          return Column(
                            children: [
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: _cardDark.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _accentPink.withOpacity(0.2),
                                  ),
                                ),
                                child: steps.isEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          'No workflow steps defined',
                                          style: TextStyle(
                                            color: _textGrey.withOpacity(0.6),
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Text(
                                              '${steps.length} workflow steps',
                                              style: TextStyle(
                                                color: _accentPink,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          ...steps.asMap().entries.map((entry) {
                                            final idx = entry.key;
                                            final step = entry.value as Map<String, dynamic>;
                                            final title = step['title'] ?? 'Step ${idx + 1}';
                                            final role = step['responsibleRole'] ?? 'any';
                                            
                                            Color roleColor;
                                            switch (role.toLowerCase()) {
                                              case 'admin':
                                                roleColor = Colors.red;
                                                break;
                                              case 'hr':
                                                roleColor = _accentPurple;
                                                break;
                                              case 'employee':
                                                roleColor = _accentGreen;
                                                break;
                                              default:
                                                roleColor = Colors.blue;
                                            }
                                            
                                            return Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  top: BorderSide(
                                                    color: _textGrey.withOpacity(0.1),
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 28,
                                                    height: 28,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color:
                                                          _accentPink.withOpacity(0.15),
                                                      border: Border.all(
                                                        color: _accentPink.withOpacity(
                                                          0.3,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        '${idx + 1}',
                                                        style: TextStyle(
                                                          color: _accentPink,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      title,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (role != null && role != 'any')
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            roleColor.withOpacity(0.15),
                                                        borderRadius:
                                                            BorderRadius.circular(4),
                                                        border: Border.all(
                                                          color: roleColor.withOpacity(
                                                            0.3,
                                                          ),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        role,
                                                        style: TextStyle(
                                                          color: roleColor,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                              ),
                            ],
                          );
                        },
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
                                if (selectedEmployeeIds.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select at least one employee',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                ss(() => submitting = true);
                                try {
                                  // Validate due date is set
                                  if (selectedDueDate == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Due date & time is required'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    ss(() => submitting = false);
                                    return;
                                  }

                                  // Validate at least one employee is selected
                                  if (selectedEmployeeIds.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please select at least one employee'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    ss(() => submitting = false);
                                    return;
                                  }

                                  // Create task for EACH selected employee
                                  List<String> createdTaskIds = [];
                                  int successCount = 0;
                                  int failureCount = 0;

                                  for (String employeeId in selectedEmployeeIds) {
                                    try {
                                      final taskId = await _createTask(
                                        title: titleCtrl.text.trim(),
                                        description: descCtrl.text.trim().isEmpty
                                            ? titleCtrl.text.trim()
                                            : descCtrl.text.trim(),
                                        priority: selectedPriority,
                                        dueDate: selectedDueDate,
                                        startDate: selectedStartDate,
                                        assignedTo: employeeId,
                                      );

                                      if (taskId != null) {
                                        createdTaskIds.add(taskId);
                                        successCount++;

                                        // Assign workflow if selected (only for first task to avoid duplication)
                                        if (selectedAdminWorkflow != null && _token != null && createdTaskIds.length == 1) {
                                          try {
                                            final workflowTemplate = _workflows.firstWhere(
                                              (w) => (w['_id'] ?? w['id']) == selectedAdminWorkflow,
                                              orElse: () => null,
                                            );
                                            if (workflowTemplate != null) {
                                              await WorkflowService.assignToTask(
                                                _token!,
                                                taskId,
                                                templateId: selectedAdminWorkflow!,
                                                workflowName: workflowTemplate['name'],
                                              );
                                            }
                                          } catch (e) {
                                            print('Error assigning workflow: $e');
                                          }
                                        }
                                      }
                                    } catch (e) {
                                      failureCount++;
                                      print('Failed to create task for employee $employeeId: $e');
                                    }
                                  }

                                  // Show result summary
                                  String resultMessage = 'Task created for $successCount employee${successCount != 1 ? 's' : ''}';
                                  if (failureCount > 0) {
                                    resultMessage += '\n(Failed for $failureCount employee${failureCount != 1 ? 's' : ''})';
                                  }

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(resultMessage),
                                        backgroundColor: failureCount > 0 ? Colors.orange : Colors.green,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }

                                  if (sheetCtx.mounted) {
                                    Navigator.pop(sheetCtx, true);
                                  }
                                } catch (e) {
                                  if (sheetCtx.mounted) {
                                    ss(() => submitting = false);
                                  }
                                  if (mounted) {
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

  /// Pick multiple employees (for task assignment)
  Future<List<String>?> _pickEmployees(BuildContext sheetCtx) async {
    // Ensure employees are loaded before showing picker
    if (_employees.isEmpty) {
      await _loadEmployees();
    }

    return showModalBottomSheet<List<String>>(
      context: sheetCtx,
      backgroundColor: _cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        String search = '';
        List<String> selectedIds = [];
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
              initialChildSize: 0.6,
              maxChildSize: 0.95,
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
                          'Select Employees',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${selectedIds.length} selected',
                          style: TextStyle(
                            color: _textGrey,
                            fontSize: 12,
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
                    child: _employees.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, color: _textGrey, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'No employees found',
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Check your permissions',
                                  style: TextStyle(color: _textGrey, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, color: _textGrey, size: 48),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No matching employees',
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                      controller: sc,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final e = filtered[i];
                        final eId = e['_id']?.toString() ?? '';
                        final isSelected = selectedIds.contains(eId);
                        return ListTile(
                          dense: true,
                          leading: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? _accentPink
                                    : Colors.white30,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? CircleAvatar(
                                    radius: 16,
                                    backgroundColor: _accentPink,
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.black,
                                      size: 14,
                                    ),
                                  )
                                : CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                        _accentPink.withValues(alpha: 0.2),
                                    child: Text(
                                      (e['name'] ?? '?')[0]
                                          .toString()
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: _accentPink,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                            '${e['department'] ?? ''} â€¢ ${e['employeeId'] ?? ''}',
                            style: TextStyle(color: _textGrey, fontSize: 11),
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (_) {
                              ss2(() {
                                if (isSelected) {
                                  selectedIds.remove(eId);
                                } else {
                                  selectedIds.add(eId);
                                }
                              });
                            },
                            fillColor: WidgetStateColor.resolveWith(
                              (states) => isSelected
                                  ? _accentPink
                                  : Colors.transparent,
                            ),
                            checkColor: Colors.black,
                            side: BorderSide(
                              color:
                                  isSelected ? _accentPink : Colors.white30,
                              width: 2,
                            ),
                          ),
                          onTap: () {
                            ss2(() {
                              if (isSelected) {
                                selectedIds.remove(eId);
                              } else {
                                selectedIds.add(eId);
                              }
                            });
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                        );
                      },
                    ),
                  ),
                  if (selectedIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(context, selectedIds),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentPink,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Assign to ${selectedIds.length} Employee${selectedIds.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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
  }

  Future<String?> _pickEmployee(BuildContext sheetCtx) async {
    // Ensure employees are loaded before showing picker
    if (_employees.isEmpty) {
      await _loadEmployees();
    }

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
                    child: _employees.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, color: _textGrey, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'No employees found',
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Check your permissions',
                                  style: TextStyle(color: _textGrey, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, color: _textGrey, size: 48),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No matching employees',
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
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
                            '${e['department'] ?? ''} Ã¢â‚¬Â¢ ${e['employeeId'] ?? ''}',
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    'My Tasks',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_tasks.length} tasks',
                    style: TextStyle(color: _textGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Refresh button
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => _loadData(showLoading: false),
              icon: Icon(Icons.refresh_rounded, color: _accentPink, size: 22),
              style: IconButton.styleFrom(
                backgroundColor: _accentPink.withOpacity(0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
      const SizedBox(width: 12),
      Expanded(
        child: _buildStatCard(
          'Assigned',
          '${_stats['assigned'] ?? 0}',
          Icons.assignment_ind_outlined,
          Colors.amber,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildStatCard(
          'In Progress',
          '${_stats['inProgress'] ?? 0}',
          Icons.timer,
          _accentOrange,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildStatCard(
          'Completed',
          '${_stats['completed'] ?? 0}',
          Icons.check_circle,
          _accentGreen,
        ),
      ),
      const SizedBox(width: 12),
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
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.35,
    children: [
      _buildStatCard(
        'Total',
        '${_stats['total'] ?? _tasks.length}',
        Icons.folder_open,
        _accentPurple,
      ),
      _buildStatCard(
        'Assigned',
        '${_stats['assigned'] ?? 0}',
        Icons.assignment_ind_outlined,
        Colors.amber,
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

  Widget _buildStatusFilterRow() {
    final count = _filteredTasks.length;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _showEmployeeStatusFilterSheet,
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      _statusFilter != null ? _accentPink : Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    color: _statusFilter != null ? _accentPink : _textGrey,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusFilter == null
                        ? 'All Status'
                        : _statusLabel(_statusFilter!),
                    style: TextStyle(
                      color: _statusFilter != null
                          ? _accentPink
                          : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: _textGrey,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _accentPink.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _accentPink.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: _accentPink,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showEmployeeStatusFilterSheet() {
    final options = [
      {'value': null, 'label': 'All Status', 'color': Colors.white},
      {'value': 'draft', 'label': 'Draft', 'color': Colors.grey},
      {
        'value': 'pending-approval',
        'label': 'Pending Approval',
        'color': Colors.blueAccent,
      },
      {'value': 'assigned', 'label': 'Assigned', 'color': Colors.amber},
      {
        'value': 'in-progress',
        'label': 'In Progress',
        'color': _accentOrange,
      },
      {
        'value': 'under-review',
        'label': 'Under Review',
        'color': Colors.tealAccent,
      },
      {'value': 'completed', 'label': 'Completed', 'color': _accentGreen},
      {'value': 'closed', 'label': 'Closed', 'color': Colors.grey},
      {'value': 'rejected', 'label': 'Rejected', 'color': Colors.redAccent},
    ];
    _showFilterSheet('Filter by Status', options, _statusFilter, (v) {
      setState(() => _statusFilter = v as String?);
    });
  }

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
    final overdue = _isOverdue(task);

    final canDelete = task['isDeletableByEmployee'] == true && _isAdmin;

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
        onTap: () => _showTaskDetail(task),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: overdue
                  ? Colors.redAccent.withOpacity(0.4)
                  : Colors.white.withOpacity(0.06),
              width: overdue ? 1.5 : 1.0,
            ),
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
                          // Priority chip + status badge + overdue
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
                              if (overdue) ...[
                                const SizedBox(width: 7),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Overdue',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
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
                            task['title'] ?? 'Ã¢â‚¬â€',
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
                                overdue
                                    ? Icons.warning_amber_outlined
                                    : Icons.calendar_today_outlined,
                                color: overdue ? Colors.redAccent : _textGrey,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  task['dueDate'] != null
                                      ? _formatDate(task['dueDate'])
                                      : 'No due date',
                                  style: TextStyle(
                                    color: overdue
                                        ? Colors.redAccent
                                        : _textGrey,
                                    fontSize: 11,
                                    fontWeight: overdue
                                        ? FontWeight.w600
                                        : FontWeight.normal,
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

  // Ã¢â€â‚¬Ã¢â€â‚¬ Tab Bar Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Widget _buildTabBar(
    List<Map<String, dynamic>> tabs,
    int current,
    ValueChanged<int> onChange,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (i) {
            final active = i == current;
            return GestureDetector(
              onTap: () => onChange(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: active ? _accentPink : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tabs[i]['icon'] as IconData,
                      size: 15,
                      color: active ? Colors.black : _textGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tabs[i]['label'] as String,
                      style: TextStyle(
                        color: active ? Colors.black : _textGrey,
                        fontSize: 12,
                        fontWeight: active ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Employee filter row (status + priority) Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Widget _buildEmployeeFilterRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _showEmployeeStatusFilterSheet,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _statusFilter != null ? _accentPink : Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    color: _statusFilter != null ? _accentPink : _textGrey,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _statusFilter == null ? 'All Status' : _statusLabel(_statusFilter!),
                      style: TextStyle(
                        color: _statusFilter != null ? _accentPink : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, color: _textGrey, size: 16),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () {
              final options = [
                {'value': null, 'label': 'All Priority', 'color': Colors.white},
                {'value': 'low', 'label': 'Low', 'color': _accentGreen},
                {'value': 'medium', 'label': 'Medium', 'color': _accentOrange},
                {'value': 'high', 'label': 'High', 'color': Colors.redAccent},
                {'value': 'critical', 'label': 'Critical', 'color': const Color(0xFFFF1744)},
              ];
              _showFilterSheet('Filter by Priority', options, _employeePriorityFilter, (v) {
                setState(() => _employeePriorityFilter = v as String?);
              });
            },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _employeePriorityFilter != null ? _accentPink : Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    color: _employeePriorityFilter != null ? _accentPink : _textGrey,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _employeePriorityFilter == null
                          ? 'All Priority'
                          : '${_employeePriorityFilter![0].toUpperCase()}${_employeePriorityFilter!.substring(1)}',
                      style: TextStyle(
                        color: _employeePriorityFilter != null ? _accentPink : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, color: _textGrey, size: 16),
                ],
              ),
            ),
          ),
        ),
        if (_statusFilter != null || _employeePriorityFilter != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() {
              _statusFilter = null;
              _employeePriorityFilter = null;
            }),
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: const Icon(Icons.clear, color: Colors.redAccent, size: 16),
            ),
          ),
        ],
      ],
    );
  }

  // Show bottom sheet to change task status from Kanban
  void _showKanbanStatusPicker(BuildContext context, Map<String, dynamic> task) {
    final statuses = [
      {'status': 'draft', 'label': 'Draft', 'color': 0xFF9E9E9E},
      {'status': 'pending-approval', 'label': 'Pending Approval', 'color': 0xFFFFC107},
      {'status': 'assigned', 'label': 'Assigned', 'color': 0xFF2196F3},
      {'status': 'todo', 'label': 'To Do', 'color': 0xFF03A9F4},
      {'status': 'in-progress', 'label': 'In Progress', 'color': 0xFFFFAB00},
      {'status': 'under-review', 'label': 'Under Review', 'color': 0xFF009688},
      {'status': 'completed', 'label': 'Completed', 'color': 0xFF00C853},
      {'status': 'closed', 'label': 'Closed', 'color': 0xFF607D8B},
      {'status': 'rejected', 'label': 'Rejected', 'color': 0xFFEF5350},
    ];
    final current = (task['status'] ?? '').toString();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Move to',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(task['title'] ?? '',
              style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statuses.map((s) {
                final isCurrent = s['status'] == current;
                final col = Color(s['color'] as int);
                return GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    if (isCurrent) return;
                    final token = _token;
                    if (token == null) return;
                    await TaskService.updateTaskStatus(token, task['_id']?.toString() ?? '', s['status'] as String);
                    // _loadTasks();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: col.withOpacity(isCurrent ? 0.25 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: col.withOpacity(isCurrent ? 0.8 : 0.3)),
                    ),
                    child: Text(s['label'] as String,
                      style: TextStyle(color: col, fontSize: 13, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Kanban view Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Widget _buildKanbanView(List<dynamic> tasks) {
    final columns = [
      {'status': 'draft', 'label': 'Draft', 'color': Colors.grey},
      {'status': 'pending-approval', 'label': 'Pending Approval', 'color': Colors.amber},
      {'status': 'assigned', 'label': 'Assigned', 'color': Colors.blueAccent},
      {'status': 'todo', 'label': 'To Do', 'color': Colors.lightBlueAccent},
      {'status': 'in-progress', 'label': 'In Progress', 'color': _accentOrange},
      {'status': 'under-review', 'label': 'Under Review', 'color': Colors.tealAccent},
      {'status': 'completed', 'label': 'Completed', 'color': _accentGreen},
      {'status': 'closed', 'label': 'Closed', 'color': Colors.blueGrey},
      {'status': 'rejected', 'label': 'Rejected', 'color': Colors.redAccent},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns.map((col) {
          final colStatus = col['status'] as String;
          final colLabel = col['label'] as String;
          final colColor = col['color'] as Color;
          final colTasks = tasks.where((t) => t['status'] == colStatus).toList();
          return Container(
            width: 260,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: colColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          colLabel,
                          style: TextStyle(
                            color: colColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${colTasks.length}',
                          style: TextStyle(
                            color: colColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Cards
                ...colTasks.map((task) {
                  final priority = (task['priority'] ?? 'medium').toString();
                  final overdue = _isOverdue(task);
                  return GestureDetector(
                    onTap: () => _showTaskDetail(task as Map<String, dynamic>),
                    onLongPress: () => _showKanbanStatusPicker(context, task as Map<String, dynamic>),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: overdue
                              ? Colors.redAccent.withOpacity(0.4)
                              : Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _miniChip(
                                priority[0].toUpperCase() + priority.substring(1),
                                _priorityColor(priority),
                              ),
                              if (overdue) ...[
                                const SizedBox(width: 4),
                                _miniChip('Overdue', Colors.redAccent),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            task['title'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (task['dueDate'] != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 11, color: _textGrey),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(task['dueDate']),
                                  style: TextStyle(color: _textGrey, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                          if (_isAdmin) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.person_outline, size: 11, color: _textGrey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _assigneeName(task),
                                    style: TextStyle(color: _textGrey, fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Time Tracking Tab Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Widget _buildTimeTrackingTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active timer card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _runningTimer != null
                    ? _accentGreen.withOpacity(0.5)
                    : Colors.white.withOpacity(0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_outlined, color: _runningTimer != null ? _accentGreen : _textGrey, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Active Timer',
                      style: TextStyle(
                        color: _runningTimer != null ? _accentGreen : _textGrey,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_runningTimer != null)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C853),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_runningTimer != null) ...[
                  Text(
                    _formatElapsed(_timerElapsed),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Task: ${(_runningTimer!['task'] is Map ? _runningTimer!['task']['title'] : _runningTimer!['task']) ?? 'Unknown'}',
                    style: TextStyle(color: _textGrey, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _timerLoading ? null : _stopTimer,
                      icon: _timerLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.stop_rounded, size: 18),
                      label: const Text('Stop Timer', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'No active timer',
                    style: TextStyle(color: _textGrey, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap a task to start tracking time',
                    style: TextStyle(color: _textGrey.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Recent logs
          Row(
            children: [
              Text(
                'Recent Time Logs',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${_timeLogs.length} entries',
                style: TextStyle(color: _textGrey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_timeLogs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  children: [
                    Icon(Icons.access_time_outlined, size: 40, color: _textGrey.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text('No time logs yet', style: TextStyle(color: _textGrey, fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            ...(_timeLogs.map((log) {
              final taskInfo = log['task'];
              final taskTitle = taskInfo is Map ? (taskInfo['title'] ?? 'Task') : 'Task';
              final duration = (log['durationMinutes'] ?? 0) as num;
              final desc = (log['description'] ?? '').toString();
              final date = log['date'] ?? log['createdAt'];
              String dateStr = '';
              if (date != null) {
                try {
                  dateStr = DateFormat('MMM d').format(DateTime.parse(date.toString()).toLocal());
                } catch (_) {}
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _accentPink.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.timer_outlined, color: _accentPink, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            taskTitle.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (desc.isNotEmpty)
                            Text(desc, style: TextStyle(color: _textGrey, fontSize: 11), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatDuration(duration.toInt()),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        if (dateStr.isNotEmpty)
                          Text(dateStr, style: TextStyle(color: _textGrey, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              );
            })),
        ],
      ),
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Admin by-employee tab Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Widget _buildAdminByEmployeeTab() {
    if (_employees.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_outlined, size: 48, color: _textGrey.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('No employees found', style: TextStyle(color: _textGrey, fontSize: 14)),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: _accentPink,
      backgroundColor: _cardDark,
      onRefresh: () async { await Future.wait([_loadData(), _loadEmployees()]); },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _employees.length,
        itemBuilder: (_, i) {
          final emp = _employees[i] as Map<String, dynamic>;
          final empId = (emp['_id'] ?? '').toString();
          final empTasks = _tasks.where((t) {
            final assignedTo = t['assignedTo'];
            if (assignedTo is Map) return (assignedTo['_id'] ?? '').toString() == empId;
            if (assignedTo is String) return assignedTo == empId;
            return false;
          }).toList();
          final completed = empTasks.where((t) => t['status'] == 'completed').length;
          final inProgress = empTasks.where((t) => t['status'] == 'in-progress').length;
          final overdue = empTasks.where((t) => _isOverdue(t)).length;
          final name = (emp['name'] ?? 'Employee').toString();
          final dept = (emp['department'] ?? '').toString();
          final empIdNum = (emp['employeeId'] ?? '').toString();

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              shape: const Border(),
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _accentPink.withOpacity(0.2),
                    child: Text(
                      name[0].toUpperCase(),
                      style: TextStyle(color: _accentPink, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text(
                          '${dept.isNotEmpty ? '$dept Ã¢â‚¬Â¢ ' : ''}${empIdNum.isNotEmpty ? empIdNum : ''}',
                          style: TextStyle(color: _textGrey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${empTasks.length} task${empTasks.length != 1 ? 's' : ''}',
                        style: TextStyle(color: _textGrey, fontSize: 12),
                      ),
                      if (overdue > 0)
                        Text(
                          '$overdue overdue',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ],
              ),
              subtitle: empTasks.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6, left: 52),
                      child: Row(
                        children: [
                          _miniChip('$completed Done', _accentGreen),
                          const SizedBox(width: 6),
                          _miniChip('$inProgress Active', _accentOrange),
                        ],
                      ),
                    )
                  : null,
              children: empTasks.isEmpty
                  ? [
                      Text(
                        'No tasks assigned',
                        style: TextStyle(color: _textGrey.withOpacity(0.6), fontSize: 13),
                      ),
                    ]
                  : empTasks.map((task) {
                      final t = task as Map<String, dynamic>;
                      final status = (t['status'] ?? 'todo').toString();
                      final priority = (t['priority'] ?? 'medium').toString();
                      return GestureDetector(
                        onTap: () => _showAdminTaskDetail(t),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _bgDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _priorityColor(priority),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t['title'] ?? '',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (t['dueDate'] != null)
                                      Text(
                                        _formatDate(t['dueDate']),
                                        style: TextStyle(color: _textGrey, fontSize: 11),
                                      ),
                                  ],
                                ),
                              ),
                              _miniChip(_statusLabel(status), _statusColor(status)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
            ),
          );
        },
      ),
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Projects Tab Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Widget _buildProjectsTab() {
    if (_projects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_outlined, size: 56, color: _textGrey.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('No projects yet', style: TextStyle(color: _textGrey, fontSize: 15)),
              const SizedBox(height: 8),
              Text(
                'Tap + to create a project',
                style: TextStyle(color: _textGrey.withOpacity(0.6), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _projects.length,
      itemBuilder: (_, i) {
        final p = _projects[i] as Map<String, dynamic>;
        final projId = (p['_id'] ?? '').toString();
        final name = (p['name'] ?? 'Project').toString();
        final desc = (p['description'] ?? '').toString();
        final priority = (p['priority'] ?? 'medium').toString();
        final colorHex = (p['color'] ?? '#FF8FA3').toString();
        Color projColor = _accentPink;
        try {
          projColor = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
        } catch (_) {}
        final isSelected = _selectedProject?['_id'] == projId;

        return GestureDetector(
          onTap: () async {
            setState(() => _selectedProject = p);
            await _loadMilestones(projId);
            if (!mounted) return;
            showModalBottomSheet(
              context: context,
              backgroundColor: _cardDark,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => StatefulBuilder(
                builder: (ctx, ss) => DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.7,
                  maxChildSize: 0.95,
                  builder: (_, scroll) => Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                        child: Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(color: projColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await _deleteProject(projId);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                      if (desc.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: Text(desc, style: TextStyle(color: _textGrey, fontSize: 13)),
                        ),
                      const Divider(color: Colors.white10, height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                        child: Row(
                          children: [
                            Text('Milestones', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _showCreateMilestoneDialog(projId),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add'),
                              style: TextButton.styleFrom(foregroundColor: _accentPink),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _milestones.isEmpty
                            ? Center(child: Text('No milestones yet', style: TextStyle(color: _textGrey, fontSize: 13)))
                            : ListView.builder(
                                controller: scroll,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _milestones.length,
                                itemBuilder: (_, j) {
                                  final m = _milestones[j] as Map<String, dynamic>;
                                  final mTitle = (m['title'] ?? '').toString();
                                  final mDue = m['dueDate'];
                                  final mDone = m['isCompleted'] == true;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: _bgDark,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          mDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                          color: mDone ? _accentGreen : _textGrey,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                mTitle,
                                                style: TextStyle(
                                                  color: mDone ? _textGrey : Colors.white,
                                                  fontSize: 13,
                                                  decoration: mDone ? TextDecoration.lineThrough : null,
                                                ),
                                              ),
                                              if (mDue != null)
                                                Text(_formatDate(mDue), style: TextStyle(color: _textGrey, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline, color: _textGrey.withOpacity(0.5), size: 16),
                                          onPressed: () async {
                                            await _deleteMilestone((m['_id'] ?? '').toString(), projId);
                                            ss(() {});
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? projColor.withOpacity(0.5) : Colors.white.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: projColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      if (desc.isNotEmpty)
                        Text(desc, style: TextStyle(color: _textGrey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                _miniChip(priority[0].toUpperCase() + priority.substring(1), _priorityColor(priority)),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: _textGrey, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Analytics Tab Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Widget _buildAnalyticsTab() {
    if (_analyticsLoading) {
      return Center(child: CircularProgressIndicator(color: _accentPink));
    }
    final stats = _analyticsStats;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall stats
          const Text(
            'Overview',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (stats != null) ...[
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.2,
              children: [
                _buildStatCard('Total', '${stats['total'] ?? 0}', Icons.folder_outlined, _accentPurple),
                _buildStatCard('Completed', '${stats['completed'] ?? 0}', Icons.check_circle_outline, _accentGreen),
                _buildStatCard('In Progress', '${stats['inProgress'] ?? 0}', Icons.pending_actions, _accentOrange),
                _buildStatCard('Overdue', '${stats['overdue'] ?? 0}', Icons.warning_amber_outlined, Colors.redAccent),
                _buildStatCard('Pending', '${stats['pending'] ?? 0}', Icons.schedule, Colors.orangeAccent),
                _buildStatCard('Under Review', '${stats['underReview'] ?? 0}', Icons.visibility, Colors.blueAccent),
              ],
            ),
            const SizedBox(height: 24),
          ],
          // Workload distribution
          if (_analyticsWorkload.isNotEmpty) ...[
            const Text(
              'Workload Distribution',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._analyticsWorkload.map((w) {
              final emp = w as Map<String, dynamic>;
              final name = (emp['employeeName'] ?? emp['name'] ?? 'Employee').toString();
              final count = (emp['taskCount'] ?? emp['count'] ?? 0) as num;
              final total = _analyticsWorkload.fold<num>(
                0,
                (s, e) => s + ((e as Map)['taskCount'] ?? (e)['count'] ?? 0),
              );
              final pct = total > 0 ? count / total : 0.0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        Text('${count.toInt()} tasks', style: TextStyle(color: _textGrey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.toDouble(),
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        color: _accentPink,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
          // Productivity
          if (_analyticsProductivity.isNotEmpty) ...[
            const Text(
              'Productivity Trends',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._analyticsProductivity.take(10).map((p) {
              final prod = p as Map<String, dynamic>;
              final date = prod['date'] ?? prod['_id']?.toString() ?? '';
              final completed = (prod['completed'] ?? prod['count'] ?? 0) as num;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(date.toString(), style: TextStyle(color: _textGrey, fontSize: 12)),
                    ),
                    _miniChip('${completed.toInt()} completed', _accentGreen),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Create project dialog Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Future<void> _showCreateProjectDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedPriority = 'medium';
    String selectedColor = '#FF8FA3';
    bool submitting = false;

    final colors = ['#FF8FA3', '#651FFF', '#FFB300', '#00C853', '#2196F3', '#FF5722'];
    final priorities = ['low', 'medium', 'high'];

    await showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (_, ss) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'New Project',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text('Name', style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _inputDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.07)),
                  ),
                  child: TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      hintText: 'Project name',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Description (optional)', style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _inputDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.07)),
                  ),
                  child: TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      hintText: 'Short description...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Priority', style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: priorities.map((pr) {
                    final active = pr == selectedPriority;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => ss(() => selectedPriority = pr),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: active ? _priorityColor(pr).withOpacity(0.2) : _inputDark,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: active ? _priorityColor(pr) : Colors.white.withOpacity(0.07),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              pr[0].toUpperCase() + pr.substring(1),
                              style: TextStyle(
                                color: active ? _priorityColor(pr) : _textGrey,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Text('Color', style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: colors.map((c) {
                    Color col = _accentPink;
                    try {
                      col = Color(int.parse(c.replaceAll('#', '0xFF')));
                    } catch (_) {}
                    final active = c == selectedColor;
                    return GestureDetector(
                      onTap: () => ss(() => selectedColor = c),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: active ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: active
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) return;
                            ss(() => submitting = true);
                            await _createProject(
                              name: name,
                              description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                              priority: selectedPriority,
                              color: selectedColor,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentPink,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('Create Project', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    nameCtrl.dispose();
    descCtrl.dispose();
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Create milestone dialog Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  Future<void> _showCreateMilestoneDialog(String projectId) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? dueDate;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (_, ss) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Text('New Milestone', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text('Title', style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _inputDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.07)),
                  ),
                  child: TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      hintText: 'Milestone title',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Due Date (optional)', style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.dark(primary: _accentPink)),
                        child: child!,
                      ),
                    );
                    if (picked != null) ss(() => dueDate = picked);
                  },
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _inputDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: dueDate != null ? _accentPink : Colors.white.withOpacity(0.07),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, color: dueDate != null ? _accentPink : _textGrey, size: 16),
                        const SizedBox(width: 10),
                        Text(
                          dueDate != null ? DateFormat('MMM d, y').format(dueDate!) : 'Select due date',
                          style: TextStyle(color: dueDate != null ? Colors.white : _textGrey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            final title = titleCtrl.text.trim();
                            if (title.isEmpty) return;
                            ss(() => submitting = true);
                            await _createMilestone(
                              title: title,
                              projectId: projectId,
                              dueDate: dueDate?.toIso8601String(),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentPink,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('Create Milestone', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    titleCtrl.dispose();
    descCtrl.dispose();
  }
}

/// Helper class for admin stat grid items.
class _StatItem {
  final String label;
  final String count;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.count, this.icon, this.color);
}

/// Simple data holder for estimated-time preset chips.
class _EstPreset {
  final String label;
  final String? value; // null = custom
  const _EstPreset(this.label, this.value);
}

