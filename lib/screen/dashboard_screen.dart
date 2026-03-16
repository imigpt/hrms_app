import 'dart:async'; // Required for the Timer
import 'package:flutter/material.dart';
import 'package:hrms_app/models/expense_model.dart';
import 'package:hrms_app/models/leave_management_model.dart';
import 'package:hrms_app/models/profile_model.dart';
import 'package:hrms_app/models/announcement_model.dart';
import 'package:hrms_app/models/dashboard_stats_model.dart';
import 'package:hrms_app/services/attendance_service.dart';
import 'package:hrms_app/services/announcement_service.dart';
import 'package:hrms_app/services/announcement_websocket_service.dart';
import 'package:hrms_app/services/api_notification_service.dart';
import 'package:hrms_app/services/notification_socket_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hrms_app/services/expense_service.dart';
import 'package:hrms_app/services/leave_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/profile_service.dart';
import '../models/chat_room_model.dart';

// Import our custom widgets
import '../widgets/sidebar_menu.dart';
import '../widgets/welcome_card.dart';
import '../widgets/status_card.dart';
import '../widgets/tasks_section.dart';
import '../widgets/announcements_section.dart';
import '../widgets/location_permission_dialog.dart';
import '../widgets/attendance_statistics_section.dart';
import '../widgets/leave_statistics_section.dart';
import '../widgets/dashboard_quick_stats_section.dart';
import '../widgets/profile_card_widget.dart';
import 'notifications_screen.dart';
import 'chat_screen.dart';
import 'expenses_screen.dart';
import 'tasks_screen.dart';
import 'leave_management_screen.dart';
// import 'employee_api_test_screen.dart';
import 'apply_leave_screen.dart';
import 'attendance_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/bod_eod_dialogs.dart';

class DashboardScreen extends StatefulWidget {
  final ProfileUser? user;
  final String? token;

  const DashboardScreen({super.key, this.user, this.token});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ── THEME COLORS ────────────────────────────────────────────────────────────
  final Color _bgDark = const Color(0xFF050505);
  final Color _cardDark = const Color(0xFF141414);
  final Color _accentPink = const Color(0xFFFF8FA3);
  final Color _accentGreen = const Color(0xFF00C853);
  final Color _accentBlue = const Color(0xFF1E88E5);
  final Color _accentOrange = const Color(0xFFFF9800);

  // --- STATE VARIABLES ---
  bool _isCheckedIn = false;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  String? _checkInLocation;
  String? _checkOutLocation;
  Duration _workedDuration = const Duration(hours: 0, minutes: 0);
  Timer? _timer;
  Timer? _notificationRefreshTimer;
  List<Announcement> _announcements = [];
  int _unreadNotificationsCount = 0;
  int _unreadChatCount = 0; // Unread chat messages count

  // Dashboard stats
  DashboardStats? _dashboardStats;

  // Consolidated loading state - single loading state for entire screen
  bool _isLoading = true;
  String? _errorMessage;

  // Tracks which announcement IDs have been marked read (persisted across sessions)
  Set<String> _readAnnouncementIds = {};

  // WebSocket service for real-time announcements
  final AnnouncementWebSocketService _wsService =
      AnnouncementWebSocketService();
  StreamSubscription<List<Announcement>>? _announcementsSubscription;

  // Socket service for real-time notifications
  final NotificationSocketService _notificationSocket =
      NotificationSocketService();
  StreamSubscription<NotificationCountEvent>? _notificationCountSubscription;

  // Full profile (fetched fresh on load to get phone/address/dob etc.)
  ProfileUser? _dashboardUser;

  // ── ADMIN DASHBOARD STATE ───────────────────────────────────────────────────
  Map<String, dynamic> _adminDashboard = {};
  Map<String, dynamic> _systemHealth = {}; // Server load, database, storage
  List<dynamic> _recentActivity = [];
  String _userRole = 'employee';

  // ── HR DASHBOARD STATE ──────────────────────────────────────────────────────
  Map<String, dynamic> _hrDashboard = {};
  List<dynamic> _pendingLeaves = [];
  List<dynamic> _pendingExpenses = [];
  Map<String, dynamic> _todayAttendance = {};

  // ── CLIENT DASHBOARD STATE ───────────────────────────────────────────────────
  int _personalChats = 0;
  int _groupChats = 0;
  int _clientUnreadMessages = 0;

  @override
  void initState() {
    super.initState();

    // Determine user role
    final roleStr = widget.user?.role.toLowerCase() ?? '';
    if (roleStr == 'admin') {
      _userRole = 'admin';
    } else if (roleStr == 'hr') {
      _userRole = 'hr';
    } else if (roleStr == 'client') {
      _userRole = 'client';
    } else {
      _userRole = 'employee';
    }

    // Load full profile data (includes phone, address, dob etc.)
    _fetchDashboardProfile();

    // Load unread chat count for both admin and employee
    _loadUnreadChatCount();

    // Start periodic notification badge refresh (every 45 seconds)
    _startNotificationRefreshTimer();

    // Connect to notification socket for real-time updates (if token available)
    _initNotificationSocket();

    if (_userRole == 'admin') {
      // Load admin dashboard data - all at once
      _loadAdminDashboardData();
    } else if (_userRole == 'hr') {
      // Load HR dashboard data - all at once
      _loadHRDashboardData();
    } else if (_userRole == 'client') {
      // Load client dashboard data - all at once
      _loadClientDashboardData();
    } else {
      // Load employee dashboard data - all at once
      _loadEmployeeDashboardData();
    }
  }

  Future<void> _fetchDashboardProfile() async {
    if (widget.token == null || widget.token!.isEmpty) return;
    try {
      final fresh = await ProfileService().fetchProfile(widget.token!);
      if (fresh != null && mounted) {
        setState(() => _dashboardUser = fresh);
      }
    } catch (_) {}
  }

  // ── CONSOLIDATED EMPLOYEE DASHBOARD LOADING ──────────────────────────────────
  /// Load all employee dashboard data at once before showing UI
  Future<void> _loadEmployeeDashboardData() async {
    if (widget.token == null || widget.token!.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication token missing';
        });
      }
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      // Load void methods first (cached data)
      await _loadCachedAttendanceState();
      await _loadPersistedReadIds();

      // Load attendance separately using dedicated method
      await _loadTodayAttendance();

      // Then load dashboard stats data in parallel (NOT attendance, already loaded above)
      final results = await Future.wait([
        AttendanceService.getDashboardStats(token: widget.token!),
        ApiNotificationService.getUnreadCount(authToken: widget.token!, userId: widget.user!.id),
        AnnouncementService.getAnnouncements(token: widget.token!),
      ], eagerError: false);

      if (mounted) {
        // Process results with proper casting
        dynamic dashboardDataResult = results[0];
        dynamic unreadCountResult = results[1];
        dynamic announcementsResult = results[2];

        // Update state with all loaded data at once
        setState(() {
          // Remove attendance processing from here - it's now handled by _loadTodayAttendance()
          print('✅ [DASHBOARD] Dashboard stats loaded');

          // Set dashboard stats from API
          if (dashboardDataResult is! Exception &&
              dashboardDataResult != null) {
            try {
              if (dashboardDataResult.data != null) {
                _dashboardStats = dashboardDataResult.data.stats;
              }
            } catch (e) {
              print('Error processing dashboard stats: $e');
            }
          }

          // Set announcements data from API
          if (announcementsResult is! Exception &&
              announcementsResult != null) {
            try {
              if (announcementsResult.data != null) {
                _announcements = announcementsResult.data;
              }
            } catch (e) {
              print('Error processing announcements: $e');
            }
          }

          if (unreadCountResult is! Exception &&
              unreadCountResult is int) {
            _unreadNotificationsCount = unreadCountResult;
          }

          // Calculate worked duration if checked in
          if (_checkInTime != null) {
            if (_checkOutTime != null) {
              _workedDuration = _checkOutTime!.difference(_checkInTime!);
            } else if (_isCheckedIn) {
              _workedDuration = DateTime.now().difference(_checkInTime!);
            }
          }

          // Mark loading complete
          _isLoading = false;
          print('📊 [DASHBOARD] Load complete - _isCheckedIn: $_isCheckedIn');
        });

        // After UI loads, start the timer and connect WebSocket for real-time updates
        if (_isCheckedIn) {
          _startTimer();
        }
        _connectToAnnouncementsWebSocket();
      }
    } catch (e, stackTrace) {
      print('Error loading employee dashboard: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  // ── CONSOLIDATED ADMIN DASHBOARD LOADING ──────────────────────────────────
  /// Load all admin dashboard data at once before showing UI
  Future<void> _loadAdminDashboardData() async {
    if (widget.token == null || widget.token!.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication token missing';
        });
      }
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      // Load cached data first
      await _loadPersistedReadIds();

      final authService = AuthService();

      // Load all admin API data in parallel
      final results = await Future.wait([
        authService.getAdminDashboardStats(widget.token!),
        authService.getAdminRecentActivity(widget.token!, limit: 8),
        ApiNotificationService.getUnreadCount(authToken: widget.token!, userId: widget.user!.id),
        AnnouncementService.getAnnouncements(token: widget.token!),
      ], eagerError: false);

      if (mounted) {
        // Process results with proper type checks
        dynamic statsResult = results[0];
        dynamic activityResult = results[1];
        dynamic unreadCountResult = results[2];
        dynamic announcementsResult = results[3];

        // Map activity items with icons
        final IconData Function(String) iconForType = (String type) {
          switch (type) {
            case 'leave':
              return Icons.calendar_today;
            case 'task':
              return Icons.assignment;
            case 'expense':
              return Icons.receipt_long;
            case 'attendance':
              return Icons.access_time;
            default:
              return Icons.info_outline;
          }
        };

        // Process activity data
        List<Map<String, dynamic>> mappedActivity = [];
        if (activityResult is! Exception && activityResult is List) {
          mappedActivity = activityResult
              .cast<Map<String, dynamic>>()
              .map((a) {
                return {
                  'type': a['type'] ?? '',
                  'message':
                      '${a['action'] ?? ''} — ${a['user'] ?? ''}',
                  'timestamp': DateTime.tryParse(
                          a['time']?.toString() ?? '') ??
                      DateTime.now(),
                  'icon': iconForType(a['type']?.toString() ?? ''),
                  'status': a['status'] ?? '',
                };
              })
              .toList();
        }

        setState(() {
          // Set admin stats and system health
          if (statsResult is! Exception &&
              statsResult is Map<String, dynamic>) {
            // Extract stats
            final stats = statsResult['stats'] as Map<String, dynamic>? ?? {};
            _adminDashboard = {
              'totalCompanies': stats['totalCompanies'] ?? 0,
              'totalHRAccounts': stats['totalHR'] ?? 0,
              'totalEmployees': stats['totalEmployees'] ?? 0,
              'activeToday': stats['activeToday'] ?? 0,
              'totalLeaves': stats['totalLeaves'] ?? 0,
              'totalTasks': stats['totalTasks'] ?? 0,
            };
            // Extract system health metrics
            final health = statsResult['systemHealth'] as Map<String, dynamic>? ?? {};
            _systemHealth = {
              'serverLoad': (health['serverLoad'] ?? 0).toDouble(),
              'database': (health['database'] ?? 0).toDouble(),
              'storage': (health['storage'] ?? 0).toDouble(),
            };
          }

          _recentActivity = mappedActivity;

          if (unreadCountResult is! Exception &&
              unreadCountResult is int) {
            _unreadNotificationsCount = unreadCountResult;
          }

          // Set announcements data
          if (announcementsResult is! Exception &&
              announcementsResult != null) {
            try {
              if (announcementsResult.data != null) {
                _announcements = announcementsResult.data;
              }
            } catch (e) {
              print('Error processing announcements: $e');
            }
          }

          // Mark loading complete
          _isLoading = false;
        });

        // Connect WebSocket for real-time announcements after UI loads
        _connectToAnnouncementsWebSocket();
      }
    } catch (e, stackTrace) {
      print('Error loading admin dashboard: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  // ── CONSOLIDATED HR DASHBOARD LOADING ──────────────────────────────────────
  /// Load all HR dashboard data at once before showing UI
  Future<void> _loadHRDashboardData() async {
    print('🔵 [HR DASHBOARD] _loadHRDashboardData() STARTED');
    print('   User Role: $_userRole');
    print('   Token Present: ${widget.token != null && widget.token!.isNotEmpty}');
    print('   Token Length: ${widget.token?.length ?? 0}');

    if (widget.token == null || widget.token!.isEmpty) {
      print('❌ [HR DASHBOARD] Token missing or empty!');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication token missing';
        });
      }
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      print('⏳ [HR DASHBOARD] Loading persisted read IDs...');
      // Load cached data first
      await _loadPersistedReadIds();

      print('📡 [HR DASHBOARD] Starting 6 parallel API calls...');
      print('   1. getHRDashboardStats (GET /api/hr/dashboard)');
      print('   2. getHRDepartmentStats (GET /api/hr/departments/stats)');
      print('   3. getAdminLeaves (GET /api/leave?status=pending)');
      print('   4. getExpenses (GET /api/expenses)');
      print('   5. getUnreadCount (GET /api/notifications/unread-count)');
      print('   6. getAnnouncements (GET /api/announcements)');

      // Load all HR API data in parallel
      final results = await Future.wait([
        AuthService().getHRDashboardStats(widget.token!),
        AuthService().getHRDepartmentStats(widget.token!),
        LeaveService.getAdminLeaves(
          token: widget.token!,
          status: 'pending',
        ),
        ExpenseService.getExpenses(token: widget.token!),
        ApiNotificationService.getUnreadCount(authToken: widget.token!, userId: widget.user!.id),
        AnnouncementService.getAnnouncements(token: widget.token!),
      ], eagerError: false);

      print('✅ [HR DASHBOARD] All 6 API calls completed');
      print('   Results types: ${results.map((r) => r.runtimeType).toList()}');

      if (mounted) {
        // Process results with proper type checks
        dynamic statsResult = results[0];
        dynamic deptStatsResult = results[1];
        dynamic leavesResult = results[2];
        dynamic expensesResult = results[3];
        dynamic unreadCountResult = results[4];
        dynamic announcementsResult = results[5];

        print('🔍 [HR DASHBOARD] Processing API Responses:');
        print('   [1] statsResult type: ${statsResult.runtimeType}');
        print('       Is Exception: ${statsResult is Exception}');
        print('       Is Map: ${statsResult is Map<String, dynamic>}');

        print('   [2] deptStatsResult type: ${deptStatsResult.runtimeType}');
        print('       Is Exception: ${deptStatsResult is Exception}');

        print('   [3] leavesResult type: ${leavesResult.runtimeType}');
        print('       Is Exception: ${leavesResult is Exception}');

        print('   [4] expensesResult type: ${expensesResult.runtimeType}');
        print('       Is Exception: ${expensesResult is Exception}');

        print('   [5] unreadCountResult type: ${unreadCountResult.runtimeType}');
        print('       Is Exception: ${unreadCountResult is Exception}');

        print('   [6] announcementsResult type: ${announcementsResult.runtimeType}');
        print('       Is Exception: ${announcementsResult is Exception}');

        setState(() {
          // Set HR dashboard stats from HR-specific endpoint
          if (statsResult is! Exception &&
              statsResult is Map<String, dynamic>) {
            // Handle both response structures: with and without 'stats' wrapper
            final stats = (statsResult['stats'] as Map<String, dynamic>?) ?? statsResult;

            print('✅ [HR DASHBOARD STATS] Successfully processed');
            print('   Raw statsResult: $statsResult');
            print('   Extracted stats: $stats');

            _hrDashboard = {
              'totalEmployees': stats['totalEmployees'] ?? 0,
              'presentToday': stats['presentToday'] ?? 0,
              'pendingLeaves': stats['pendingLeaves'] ?? 0,
              'activeTasks': stats['activeTasks'] ?? 0,
              'totalDepartments': (deptStatsResult is Map<String, dynamic> && deptStatsResult is! Exception)
                  ? deptStatsResult['totalDepartments'] ?? deptStatsResult['departments']?.length ?? 0
                  : 0,
            };

            print('✅ [HR DASHBOARD STATE] Updated:');
            print('   totalEmployees: ${_hrDashboard['totalEmployees']}');
            print('   presentToday: ${_hrDashboard['presentToday']}');
            print('   pendingLeaves: ${_hrDashboard['pendingLeaves']}');
            print('   activeTasks: ${_hrDashboard['activeTasks']}');
            print('   totalDepartments: ${_hrDashboard['totalDepartments']}');
            print('   Full _hrDashboard: ${_hrDashboard}');
          } else {
            print('❌ [HR DASHBOARD STATS] Failed to process');
            print('   statsResult is Exception: ${statsResult is Exception}');
            print('   statsResult type: ${statsResult.runtimeType}');
            print('   statsResult: $statsResult');
            _hrDashboard = {};
          }

          // Process pending leaves
          if (leavesResult is! Exception &&
              leavesResult is AdminLeavesResponse) {
            _pendingLeaves = leavesResult.data;
            print('✅ [PENDING LEAVES] Loaded ${_pendingLeaves.length} pending leaves');
            print('   Leave IDs: ${_pendingLeaves.map((l) => l.id).toList()}');
          } else {
            print('❌ [PENDING LEAVES] Failed to process');
            print('   Is Exception: ${leavesResult is Exception}');
            print('   Type: ${leavesResult.runtimeType}');
            if (leavesResult is Exception) {
              print('   Error: ${leavesResult.toString()}');
            }
            _pendingLeaves = [];
          }

          // Process pending expenses (filter for pending status)
          if (expensesResult is! Exception &&
              expensesResult is ExpenseListResponse) {
            _pendingExpenses = expensesResult.data
                .where((e) => e.status.toLowerCase() == 'pending')
                .toList();
            print('✅ [PENDING EXPENSES] Processed ${_pendingExpenses.length} pending expenses');
            print('   Total expenses in response: ${expensesResult.data.length}');
            print('   Pending expenses: ${_pendingExpenses.length}');
            print('   Expense statuses: ${expensesResult.data.map((e) => e.status).toSet().toList()}');
          } else {
            print('❌ [PENDING EXPENSES] Failed to process');
            print('   Is Exception: ${expensesResult is Exception}');
            print('   Type: ${expensesResult.runtimeType}');
            if (expensesResult is Exception) {
              print('   Error: ${expensesResult.toString()}');
            }
            _pendingExpenses = [];
          }

          if (unreadCountResult is! Exception &&
              unreadCountResult is int) {
            _unreadNotificationsCount = unreadCountResult;
            print('✅ [UNREAD NOTIFICATIONS] Count: $_unreadNotificationsCount');
          } else {
            print('⚠️ [UNREAD NOTIFICATIONS] Failed - Type: ${unreadCountResult.runtimeType}');
            _unreadNotificationsCount = 0;
          }

          // Set announcements data
          if (announcementsResult is! Exception &&
              announcementsResult != null) {
            try {
              if (announcementsResult.data != null) {
                _announcements = announcementsResult.data;
                print('✅ [ANNOUNCEMENTS] Loaded ${_announcements.length} announcements');
              }
            } catch (e) {
              print('❌ [ANNOUNCEMENTS] Error processing: $e');
            }
          } else {
            print('⚠️ [ANNOUNCEMENTS] Failed - Type: ${announcementsResult.runtimeType}');
          }

          // Mark loading complete
          _isLoading = false;
          print('✅ [HR DASHBOARD] Loading complete - setstate() triggered');
          print('   _isLoading: $_isLoading');
          print('   _hrDashboard populated: ${_hrDashboard.isNotEmpty}');
        });

        // Connect WebSocket for real-time announcements after UI loads
        _connectToAnnouncementsWebSocket();
      }
    } catch (e, stackTrace) {
      print('❌ [HR DASHBOARD] ERROR loading: $e');
      print('   Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  // ── CONSOLIDATED CLIENT DASHBOARD LOADING ──────────────────────────────────
  /// Load all client dashboard data at once before showing UI
  Future<void> _loadClientDashboardData() async {
    if (widget.token == null || widget.token!.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication token missing';
        });
      }
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      // Load cached data first
      await _loadPersistedReadIds();

      // Load all client API data in parallel
      final results = await Future.wait([
        ChatService.getChatRooms(token: widget.token!),
        ChatService.getUnreadCount(token: widget.token!),
        ApiNotificationService.getUnreadCount(authToken: widget.token!, userId: widget.user!.id),
        AnnouncementService.getAnnouncements(token: widget.token!),
      ], eagerError: false);

      if (mounted) {
        // Process results with proper type checks
        dynamic chatRoomsResult = results[0];
        dynamic unreadChatResult = results[1];
        dynamic unreadCountResult = results[2];
        dynamic announcementsResult = results[3];

        // Calculate personal and group chats
        int personalChats = 0;
        int groupChats = 0;
        int unreadMessages = 0;

        if (chatRoomsResult is! Exception &&
            chatRoomsResult is ChatRoomsResponse) {
          final rooms = chatRoomsResult.data;
          personalChats = rooms.where((r) => r.type == 'personal').length;
          groupChats = rooms.where((r) => r.type == 'group').length;
        }

        if (unreadChatResult is! Exception &&
            unreadChatResult is UnreadCountResponse) {
          unreadMessages = unreadChatResult.count;
        }

        setState(() {
          _personalChats = personalChats;
          _groupChats = groupChats;
          _clientUnreadMessages = unreadMessages;

          if (unreadCountResult is! Exception &&
              unreadCountResult is int) {
            _unreadNotificationsCount = unreadCountResult;
          }

          // Set announcements data
          if (announcementsResult is! Exception &&
              announcementsResult != null) {
            try {
              if (announcementsResult.data != null) {
                _announcements = announcementsResult.data;
              }
            } catch (e) {
              print('Error processing announcements: $e');
            }
          }

          // Mark loading complete
          _isLoading = false;
        });

        // Connect WebSocket for real-time announcements after UI loads
        _connectToAnnouncementsWebSocket();
      }
    } catch (e, stackTrace) {
      print('Error loading client dashboard: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  // Save attendance state to local storage
  Future<void> _saveAttendanceState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await prefs.setString('attendance_date', today);
      await prefs.setBool('is_checked_in', _isCheckedIn);

      if (_checkInTime != null) {
        await prefs.setString('check_in_time', _checkInTime!.toIso8601String());
      } else {
        await prefs.remove('check_in_time');
      }

      if (_checkOutTime != null) {
        await prefs.setString(
          'check_out_time',
          _checkOutTime!.toIso8601String(),
        );
      } else {
        await prefs.remove('check_out_time');
      }

      if (_checkInLocation != null) {
        await prefs.setString('check_in_location', _checkInLocation!);
      } else {
        await prefs.remove('check_in_location');
      }

      if (_checkOutLocation != null) {
        await prefs.setString('check_out_location', _checkOutLocation!);
      } else {
        await prefs.remove('check_out_location');
      }
    } catch (e) {
      print('Error saving attendance state: $e');
    }
  }

  // Load cached attendance state from local storage
  Future<void> _loadCachedAttendanceState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDate = prefs.getString('attendance_date');
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Only load cached data if it's from today
      if (cachedDate == today) {
        setState(() {
          _isCheckedIn = prefs.getBool('is_checked_in') ?? false;

          final checkInStr = prefs.getString('check_in_time');
          if (checkInStr != null) {
            _checkInTime = DateTime.parse(checkInStr);
          }

          final checkOutStr = prefs.getString('check_out_time');
          if (checkOutStr != null) {
            _checkOutTime = DateTime.parse(checkOutStr);
          }

          _checkInLocation = prefs.getString('check_in_location');
          _checkOutLocation = prefs.getString('check_out_location');

          // Calculate worked duration if we have the times
          if (_checkInTime != null && _checkOutTime != null) {
            _workedDuration = _checkOutTime!.difference(_checkInTime!);
          } else if (_checkInTime != null && _isCheckedIn) {
            _workedDuration = DateTime.now().difference(_checkInTime!);
          }
        });
      } else {
        // Clear old cached data
        await prefs.remove('attendance_date');
        await prefs.remove('is_checked_in');
        await prefs.remove('check_in_time');
        await prefs.remove('check_out_time');
        await prefs.remove('check_in_location');
        await prefs.remove('check_out_location');
      }
    } catch (e) {
      print('Error loading cached attendance state: $e');
    }
  }

  Future<void> _loadTodayAttendance() async {
    if (widget.token == null) {
      return;
    }

    try {
      print('Loading today attendance from API...');
      final response = await AttendanceService.getTodayAttendance(
        token: widget.token!,
      );

      print('🔎 [API RESPONSE DEBUG]');
      print('   response: $response');
      print('   response != null: ${response != null}');
      print('   response.data: ${response?.data}');
      print('   response.data != null: ${response?.data != null}');

      if (response?.data == null) {
        print('   ⚠️ WARNING: response.data is NULL or empty!');
      }

      print('API Response received: ${response != null}');
      if (response != null && response.data != null) {
        print(
          '✅ [ATTENDANCE API] Response received:',
        );
        print(
          '   hasCheckedIn: ${response.data!.hasCheckedIn}, hasCheckedOut: ${response.data!.hasCheckedOut}',
        );
        print('   checkIn.time: ${response.data!.checkIn?.time}');
        print('   checkOut.time: ${response.data!.checkOut?.time}');
      } else {
        print('   ❌ [ATTENDANCE API] Response is NULL or data is empty!');
      }

      if (response != null && response.data != null && mounted) {
        print('🔧 [setState] About to call setState...');
        setState(() {
          print('🔧 [setState] Inside setState callback');
          final attendanceData = response.data!;
          // Derive checked-in state: prefer model flags, fallback to
          // actual checkIn/checkOut time presence.
          final hasCheckedIn =
              attendanceData.hasCheckedIn ||
              (attendanceData.checkIn?.time != null);
          final hasCheckedOut =
              attendanceData.hasCheckedOut ||
              (attendanceData.checkOut?.time != null);
          _isCheckedIn = hasCheckedIn && !hasCheckedOut;

          print('🔍 [STATE DERIVATION]');
          print('   hasCheckedIn flag: ${attendanceData.hasCheckedIn}');
          print('   checkIn?.time exists: ${attendanceData.checkIn?.time != null}');
          print('   → derived hasCheckedIn: $hasCheckedIn');
          print('   hasCheckedOut flag: ${attendanceData.hasCheckedOut}');
          print('   checkOut?.time exists: ${attendanceData.checkOut?.time != null}');
          print('   → derived hasCheckedOut: $hasCheckedOut');
          print('   → FINAL _isCheckedIn: $_isCheckedIn');

          try {
            print('Using attendance data from API');
            print('Check-in time string: ${attendanceData.checkIn?.time}');

            // Check if attendance is from today
            if (attendanceData.checkIn?.time != null) {
              final checkInDateTimeRaw = DateTime.tryParse(
                attendanceData.checkIn!.time!,
              );
              // Always compare in local time to avoid UTC vs local date mismatch
              final checkInDateTime = checkInDateTimeRaw?.toLocal();
              if (checkInDateTime != null) {
                final today = DateTime.now();
                final isSameDay =
                    checkInDateTime.year == today.year &&
                    checkInDateTime.month == today.month &&
                    checkInDateTime.day == today.day;

                print('Is same day: $isSameDay');

                // Only set check-in/out times if they're from today
                if (isSameDay) {
                  _checkInTime = checkInDateTime;

                  // Set check-in location
                  if (attendanceData.checkIn?.location != null) {
                    final lat =
                        (attendanceData.checkIn!.location!['latitude'] as num)
                            .toDouble();
                    final lng =
                        (attendanceData.checkIn!.location!['longitude'] as num)
                            .toDouble();
                    final d = Geolocator.distanceBetween(
                      lat,
                      lng,
                      26.816224,
                      75.845444,
                    );
                    _checkInLocation = d <= 100
                        ? 'Main Building'
                        : 'Outside Building';
                  }

                  // Set check-out info if available
                  if (attendanceData.checkOut?.time != null) {
                    final checkOutDateTime = DateTime.tryParse(
                      attendanceData.checkOut!.time!,
                    );
                    if (checkOutDateTime != null) {
                      _checkOutTime = checkOutDateTime;
                      if (attendanceData.checkOut!.location != null) {
                        final lat =
                            (attendanceData.checkOut!.location!['latitude']
                                    as num)
                                .toDouble();
                        final lng =
                            (attendanceData.checkOut!.location!['longitude']
                                    as num)
                                .toDouble();
                        final d = Geolocator.distanceBetween(
                          lat,
                          lng,
                          26.816224,
                          75.845444,
                        );
                        _checkOutLocation = d <= 100
                            ? 'Main Building'
                            : 'Outside Building';
                      }
                    }
                  } else {
                    // Not checked out yet — explicitly clear any stale value
                    _checkOutTime = null;
                    _checkOutLocation = null;
                  }

                  // Calculate worked duration
                  if (_isCheckedIn) {
                    _workedDuration = DateTime.now().difference(
                      checkInDateTime,
                    );
                  } else if (attendanceData.checkOut?.time != null) {
                    final checkOutDateTime = DateTime.tryParse(
                      attendanceData.checkOut!.time!,
                    );
                    if (checkOutDateTime != null) {
                      _workedDuration = checkOutDateTime.difference(
                        checkInDateTime,
                      );
                    }
                  }

                  print(
                    'State updated - _isCheckedIn: $_isCheckedIn, checkInTime: $_checkInTime, checkOutTime: $_checkOutTime',
                  );
                } else {
                  // Attendance is from a previous day - reset state for new day
                  print('Attendance is from previous day - resetting state');
                  _checkInTime = null;
                  _checkOutTime = null;
                  _checkInLocation = null;
                  _checkOutLocation = null;
                  _workedDuration = const Duration(hours: 0, minutes: 0);
                  _isCheckedIn = false;
                }
              }
            } else {
              // No attendance data - reset state
              print('No attendance data in response');
              _checkInTime = null;
              _checkOutTime = null;
              _checkInLocation = null;
              _checkOutLocation = null;
              _workedDuration = const Duration(hours: 0, minutes: 0);
            }
          } catch (e) {
            print('Error parsing attendance data: $e');
            print('Stack trace: ${StackTrace.current}');
          }
        });

        print('🔧 [setState] Completed - widget rebuild triggered');
        print('🔧 [setState] Current key value: ${ValueKey<bool>(_isCheckedIn)}');

        // Save the loaded state to local storage
        await _saveAttendanceState();
      } else {
        print(
          'Response is null - no attendance for today, clearing stale state',
        );
        print('🔎 [API DEBUG - CRITICAL]');
        print('   response: $response');
        print('   response == null: ${response == null}');
        print('   response?.data == null: ${response?.data == null}');
        print('   ⚠️⚠️⚠️ BACKEND DID NOT RETURN CHECK-IN DATA! ⚠️⚠️⚠️');
        print('   POSSIBLE CAUSES:');
        print('     1. Check-in API didn\'t actually save to database');
        print('     2. Different database/table for today check-in');
        print('     3. User context lost between requests');
        print('     4. Backend returning cached old data');
        print('   CHECK: Look at HRMS-Backend logs when user checks in');
        print('   CHECK: Is /attendance/today returning your check-in?');
        print('🔧 [setState] About to call setState (no attendance)...');
        setState(() {
          print('🔧 [setState] Inside setState callback (no attendance)');
          // No record from server means user hasn't checked in today.
          // Clear any stale SharedPreferences data so "Day Complete" doesn't linger.
          _isCheckedIn = false;
          _checkInTime = null;
          _checkOutTime = null;
          _checkInLocation = null;
          _checkOutLocation = null;
          _workedDuration = const Duration(hours: 0, minutes: 0);
        });
        print('🔧 [setState] Completed (no attendance) - widget rebuild triggered');
        print('🔧 [setState] Current key value: ${ValueKey<bool>(_isCheckedIn)}');
        await _saveAttendanceState();
      }
    } catch (e, stackTrace) {
      print('Error loading today attendance: $e');
      print('Stack trace: $stackTrace');
    }

    // Final state summary for debugging
    print('📊 [_loadTodayAttendance COMPLETE]');
    print('   Final state:');
    print('   _isCheckedIn: $_isCheckedIn');
    print('   _checkInTime: $_checkInTime');
    print('   _checkOutTime: $_checkOutTime');
    print('   _checkInLocation: $_checkInLocation');
    print('   _checkOutLocation: $_checkOutLocation');
  }

  /// Retry wrapper for _loadTodayAttendance()
  /// Retries up to 3 times if no check-in data found
  /// Waits progressively longer between retries
  Future<void> _loadTodayAttendanceWithRetry() async {
    int maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      attempt++;
      print('🔄 [RETRY ATTENDANCE] Attempt $attempt of $maxRetries');

      // Load attendance data
      await _loadTodayAttendance();

      // Check if we got the data
      if (_isCheckedIn) {
        print('✅ [RETRY ATTENDANCE] Success! Check-in data received on attempt $attempt');
        return; // Got data, stop retrying
      }

      // No data yet, check if this was the last attempt
      if (attempt < maxRetries) {
        // Wait longer with each retry: 3s, 4s, 5s
        final waitSeconds = 2 + attempt;
        print('⏳ [RETRY ATTENDANCE] No check-in found, waiting ${waitSeconds}s before retry...');
        await Future.delayed(Duration(seconds: waitSeconds));
      }
    }

    if (!_isCheckedIn) {
      print('❌ [RETRY ATTENDANCE] Failed after $maxRetries attempts - check-in data not found');
      // Show snackbar to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Check-in might not be saved yet. Pull down to refresh or try again.',
            ),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Connect to WebSocket for real-time announcements updates
  // (Initial announcements are loaded via consolidated loading method)
  Future<void> _connectToAnnouncementsWebSocket() async {
    if (widget.token == null) {
      return;
    }

    try {
      print('Connecting to announcements WebSocket for real-time updates...');

      // Listen to announcements stream for real-time updates
      _announcementsSubscription = _wsService.announcementsStream.listen(
        (announcements) {
          if (mounted) {
            final previousCount = _unreadNotificationsCount;
            setState(() {
              _announcements = announcements;
              // Unread count now comes from API, not announcements list
            });
            // Refresh unread notification count from API in parallel
            _refreshUnreadNotificationCount();
            print(
              'Announcements updated via WebSocket: ${announcements.length} items (${_unreadNotificationsCount} unread)',
            );
            if (previousCount != _unreadNotificationsCount) {
              print(
                'Badge count changed: $previousCount -> $_unreadNotificationsCount',
              );
            }
          }
        },
        onError: (error) {
          print('WebSocket stream error: $error');
        },
      );

      // Connect to WebSocket
      await _wsService.connect(widget.token!);
    } catch (e) {
      print('Error connecting to announcements WebSocket: $e');
      // Silently fail - announcements are already loaded via API
    }
  }

  // Fallback method to load announcements via REST API
  // Load persisted read announcement IDs from SharedPreferences
  Future<void> _loadPersistedReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('read_announcement_ids') ?? [];
      if (mounted) {
        setState(() {
          _readAnnouncementIds = Set<String>.from(ids);
        });
      }
    } catch (e) {
      print('Error loading persisted read IDs: $e');
    }
  }

  // Save read announcement IDs to SharedPreferences
  Future<void> _persistReadId(String announcementId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('read_announcement_ids') ?? [];
      if (!ids.contains(announcementId)) {
        ids.add(announcementId);
        await prefs.setStringList('read_announcement_ids', ids);
      }
    } catch (e) {
      print('Error persisting read ID: $e');
    }
  }

  // Fetch authoritative unread count from the dedicated API
  // Load unread chat count
  Future<void> _loadUnreadChatCount() async {
    if (widget.token == null) return;
    try {
      final count = await ChatService.getUnreadCount(token: widget.token!);
      if (mounted) {
        setState(() {
          _unreadChatCount = count.count;
        });
        print('Unread chat count from API: ${count.count}');
      }
    } catch (e) {
      print('Error loading unread chat count: $e');
      // Silently fail - badge will show 0
    }
  }

  // Refresh unread notification count from API
  Future<void> _refreshUnreadNotificationCount() async {
    if (widget.token == null || widget.user == null) return;
    try {
      final count = await ApiNotificationService.getUnreadCount(
        authToken: widget.token!,
        userId: widget.user!.id,
      );
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = count;
        });
      }
    } catch (e) {
      debugPrint('Failed to refresh notification count: $e');
    }
  }

  // Start periodic notification count refresh timer (every 45 seconds)
  void _startNotificationRefreshTimer() {
    _notificationRefreshTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _refreshUnreadNotificationCount(),
    );
  }

  // ── LOAD ADMIN DASHBOARD ────────────────────────────────────────────────────

  // ── Notification icon + popup ────────────────────────────────────────────
  Widget _buildNotificationIconButton(double iconSize) {
    return IconButton(
      onPressed: () {
        if (_userRole == 'admin') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
        } else {
          _showNotificationPopup(context);
        }
      },
      icon: _unreadNotificationsCount > 0
          ? Badge(
              label: Text(_unreadNotificationsCount.toString()),
              backgroundColor: Colors.red,
              child: Icon(Icons.notifications_outlined, size: iconSize),
            )
          : Icon(Icons.notifications_outlined, size: iconSize),
    );
  }

  Widget _buildChatIconButton(double iconSize) {
    return IconButton(
      icon: _unreadChatCount > 0
          ? Badge(
              label: Text(_unreadChatCount.toString()),
              backgroundColor: Colors.red,
              child: Icon(
                Icons.chat_rounded,
                size: iconSize,
                color: Colors.white,
              ),
            )
          : Icon(Icons.chat_rounded, size: iconSize, color: Colors.white),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        );
      },
      tooltip: 'Chat',
    );
  }

  void _showNotificationPopup(BuildContext ctx) {
    final recent = _announcements.take(5).toList();
    final userId = widget.user?.id;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.55,
          ),
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
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _unreadNotificationsCount > 0
                        ? '$_unreadNotificationsCount unread'
                        : 'All caught up!',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.white.withOpacity(0.07), height: 1),
              // Content
              if (recent.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        color: Colors.grey[700],
                        size: 44,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No notifications yet',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: recent.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final a = recent[i];
                      final isRead =
                          userId != null && a.readBy.contains(userId);
                      final diff = DateTime.now().difference(a.createdAt);
                      String time;
                      if (diff.inMinutes < 60) {
                        time = '${diff.inMinutes}m ago';
                      } else if (diff.inHours < 24) {
                        time = '${diff.inHours}h ago';
                      } else {
                        time = '${diff.inDays}d ago';
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isRead
                              ? Colors.white.withOpacity(0.03)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isRead
                                ? Colors.white.withOpacity(0.05)
                                : AppTheme.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color:
                                    (a.priority == 'high'
                                            ? Colors.redAccent
                                            : a.priority == 'medium'
                                            ? Colors.orangeAccent
                                            : Colors.blueAccent)
                                        .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Icon(
                                a.priority == 'high'
                                    ? Icons.warning_amber_rounded
                                    : a.priority == 'medium'
                                    ? Icons.info_outline
                                    : Icons.campaign_outlined,
                                color: a.priority == 'high'
                                    ? Colors.redAccent
                                    : a.priority == 'medium'
                                    ? Colors.orangeAccent
                                    : Colors.blueAccent,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: isRead
                                          ? FontWeight.w400
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    time,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              // View All button
              Divider(color: Colors.white.withOpacity(0.07), height: 1),
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'View All Notifications',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.grey[500],
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Calculate unread announcements count
  int _calculateUnreadCount(List<Announcement> announcements) {
    if (widget.user == null) {
      print('Cannot calculate unread count: user is null');
      return 0;
    }

    final userId = widget.user!.id;
    final unreadCount = announcements.where((announcement) {
      // Check if user ID is NOT in the readBy list
      final isUnread = !announcement.readBy.contains(userId);
      return isUnread;
    }).length;

    print(
      'Calculated unread count: $unreadCount (userId: $userId, total announcements: ${announcements.length})',
    );
    return unreadCount;
  }

  // Mark announcement as read
  void _markAnnouncementAsRead(String announcementId) {
    // Check if already marked read (track by a local set to avoid double-decrement)
    final alreadyRead = _readAnnouncementIds.contains(announcementId);
    if (alreadyRead) return;

    // Optimistically update badge count immediately (decrement by 1)
    setState(() {
      _readAnnouncementIds.add(announcementId);
      // Unread count is now fetched from API, no local decrement
    });

    // Persist to local storage so read state survives app restarts
    _persistReadId(announcementId);

    // Call REST API to mark as read (WebSocket will update announcements)
    _wsService.markAsRead(announcementId);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notificationRefreshTimer?.cancel();
    _announcementsSubscription?.cancel();
    _notificationCountSubscription?.cancel();
    _notificationSocket.dispose();
    _wsService.dispose();
    super.dispose();
  }

  // Timer logic to update UI every minute
  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_isCheckedIn) {
        setState(() {
          _workedDuration += const Duration(minutes: 1);
        });
      }
    });
  }

  // Periodic refresh for notification badge count (every 45 seconds)

  // Initialize real-time notification socket connection
  Future<void> _initNotificationSocket() async {
    if (widget.token == null) return;
    try {
      // Connect to notification socket
      await _notificationSocket.connect(widget.token!);

      // Listen for real-time unread count updates
      _notificationCountSubscription =
          _notificationSocket.onCountUpdated.listen(
        (event) {
          if (mounted) {
            setState(() {
              _unreadNotificationsCount = event.unreadCount;
              print('📊 Notification badge updated via socket: ${event.unreadCount}');
            });
          }
        },
        onError: (error) {
          print('Error in notification count stream: $error');
        },
      );
    } catch (e) {
      print('Failed to initialize notification socket: $e');
      // Not critical - fallback to periodic refresh timer
    }
  }

  // Toggle Check-In / Check-Out
  /// For check-in → navigate to AttendanceScreen.
  /// For check-out → call _handleCheckOut directly (inline GPS + API).
  void _toggleCheckIn() async {
    if (_isCheckedIn) {
      // Show EOD review before allowing check-out
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const EODBottomSheet(),
      );
      if (confirmed == true && mounted) {
        _handleCheckOut();
      }
    } else {
      print('📍 [TOGGLE CHECK IN] Before navigation:');
      print('   _isCheckedIn: $_isCheckedIn');
      print('   _checkInTime: $_checkInTime');
      print('   _checkOutTime: $_checkOutTime');

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const AttendanceScreen(initialAction: 'checkIn'),
        ),
      );

      print('📍 [TOGGLE CHECK IN] Returned from AttendanceScreen');

      if (mounted) {
        print('📍 [TOGGLE CHECK IN] Waiting for backend (2s)...');
        await Future.delayed(const Duration(seconds: 2));
        print('📍 [TOGGLE CHECK IN] Reloading attendance data with retry...');

        // Use retry method that waits for check-in data to be available
        await _loadTodayAttendanceWithRetry();

        print('📍 [TOGGLE CHECK IN] After reload:');
        print('   _isCheckedIn: $_isCheckedIn');
        print('   _checkInTime: $_checkInTime');
        print('   _checkOutTime: $_checkOutTime');

        // Force a complete rebuild of the page
        if (mounted) {
          print('🔄 [FORCE REBUILD] Triggering complete page rebuild...');
          setState(() {
            print('🔄 [FORCE REBUILD] setState called to rebuild entire page');
          });
        }
      }
    }
  }

  Future<void> _handleCheckOut() async {
    print('=== Check-Out: Starting Process ===');

    // Check if user is actually checked in
    if (!_isCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to check in first before checking out.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication error. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('Location service enabled: $serviceEnabled');

      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services to check out'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Check current location permission
      LocationPermission permission = await Geolocator.checkPermission();
      print('Current location permission: $permission');

      // ALWAYS show our custom dialog first (except if already granted)
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Show custom dialog to explain why we need location
        if (mounted) {
          final shouldRequest = await LocationPermissionDialog.show(
            context,
            isPermanentlyDenied: permission == LocationPermission.deniedForever,
          );
          print('Dialog result: $shouldRequest');

          if (shouldRequest == null) {
            print('User cancelled');
            return;
          }

          if (permission == LocationPermission.deniedForever) {
            // User needs to go to settings
            return;
          }

          if (shouldRequest == true) {
            // User clicked "Enable", now request permission from system
            permission = await Geolocator.requestPermission();
            print('Permission after request: $permission');

            if (permission == LocationPermission.denied ||
                permission == LocationPermission.deniedForever) {
              print('Permission denied by user');
              return;
            }
          } else {
            return;
          }
        }
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get location — medium accuracy + 8s timeout + last-known fallback
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 8));
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        if (mounted) {
          try {
            Navigator.of(context, rootNavigator: true).pop();
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not get location. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      print('=== Check-Out Process ===');
      print(
        'Attempting check-out with token: ${widget.token!.substring(0, 20)}...',
      );
      print(
        'Location captured: Lat=${position.latitude}, Long=${position.longitude}',
      );

      // Call check-out API with location data
      final response = await AttendanceService.checkOut(
        token: widget.token!,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      print('Check-out API response received');
      print('Response message: ${response.message}');
      print('Response data: ${response.data}');

      if (mounted) {
        Navigator.pop(context); // Close loading

        setState(() {
          _isCheckedIn = false;

          // Parse check-in data
          _checkInTime = response.data.checkIn.time;
          if (response.data.checkIn.location != null) {
            final d = Geolocator.distanceBetween(
              response.data.checkIn.location!.latitude,
              response.data.checkIn.location!.longitude,
              26.816224,
              75.845444,
            );
            _checkInLocation = d <= 100 ? 'Main Building' : 'Outside Building';
          }

          // Parse check-out data
          if (response.data.checkOut != null) {
            _checkOutTime = response.data.checkOut!.time;
            if (response.data.checkOut!.location != null) {
              final d = Geolocator.distanceBetween(
                response.data.checkOut!.location!.latitude,
                response.data.checkOut!.location!.longitude,
                26.816224,
                75.845444,
              );
              _checkOutLocation = d <= 100
                  ? 'Main Building'
                  : 'Outside Building';
            }
            // Calculate worked duration
            if (_checkInTime != null) {
              _workedDuration = response.data.checkOut!.time.difference(
                _checkInTime!,
              );
            }
          }
        });

        // Save the updated state to local storage
        await _saveAttendanceState();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Check-out error details: $e');
      if (mounted) {
        // Try to close loading dialog if it's open
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}

        // Parse error message to provide better feedback
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception:')) {
          errorMessage = errorMessage.replaceFirst('Exception:', '').trim();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ─── CLIENT DASHBOARD WIDGETS ────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildClientScaffold({
    required BuildContext context,
    required bool isMobile,
    required bool isDesktopDevice,
    required double titleFontSize,
    required double iconSize,
  }) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color cardColor = Theme.of(context).cardColor;

    // Stat cards for client dashboard
    final statCards = [
      {
        'title': 'Direct Chats',
        'value': _personalChats,
        'icon': Icons.message_outlined,
        'description': 'Active conversations with Admin / HR',
        'color': Color(0xFF1E88E5),
        'bg': Color(0xFF1E88E5).withOpacity(0.1),
      },
      {
        'title': 'Group Chats',
        'value': _groupChats,
        'icon': Icons.groups_outlined,
        'description': 'Groups you are a member of',
        'color': Color(0xFF00C853),
        'bg': Color(0xFF00C853).withOpacity(0.1),
      },
      {
        'title': 'Unread Messages',
        'value': _clientUnreadMessages,
        'icon': Icons.notifications_outlined,
        'description': 'Messages waiting for your response',
        'color': Color(0xFFFF9800),
        'bg': Color(0xFFFF9800).withOpacity(0.1),
      },
    ];

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(
                'Client Portal',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: titleFontSize,
                ),
              ),
              backgroundColor: cardColor,
              elevation: 0,
              actions: [
                _buildNotificationIconButton(iconSize),
              ],
            )
          : null,
      drawer: !isDesktopDevice
          ? Drawer(
              child: SidebarMenu(user: widget.user, token: widget.token),
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar (Desktop only)
          if (isDesktopDevice)
            Container(
              width: 250,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey[800]!)),
              ),
              child: SidebarMenu(user: widget.user, token: widget.token),
            ),
          // Main content
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Banner
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.2),
                          primaryColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.2),
                      ),
                    ),
                    padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${widget.user?.name} 👋',
                          style: TextStyle(
                            fontSize: isMobile ? 20.0 : 24.0,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        SizedBox(height: isMobile ? 8.0 : 12.0),
                        Text(
                          'Your client communication portal. Chat with our team anytime.',
                          style: TextStyle(
                            fontSize: isMobile ? 12.0 : 14.0,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: isMobile ? 12.0 : 16.0),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChatScreen(),
                            ),
                          ),
                          icon: Icon(Icons.open_in_new, size: iconSize - 4),
                          label: Text(
                            'Open Chat',
                            style: TextStyle(
                              fontSize: isMobile ? 12.0 : 14.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isMobile ? 24.0 : 32.0),
                  // Stats Grid
                  Text(
                    'Chat Statistics',
                    style: TextStyle(
                      fontSize: isMobile ? 16.0 : 18.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: isMobile ? 12.0 : 16.0),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : 3,
                      childAspectRatio: isMobile ? 1.2 : 1.4,
                      crossAxisSpacing: isMobile ? 12.0 : 16.0,
                      mainAxisSpacing: isMobile ? 12.0 : 16.0,
                    ),
                    itemCount: statCards.length,
                    itemBuilder: (context, index) {
                      final card = statCards[index];
                      return _buildClientStatCard(card);
                    },
                  ),
                  SizedBox(height: isMobile ? 24.0 : 32.0),
                  // Info Card
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.2),
                      ),
                    ),
                    padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
                              child: Icon(
                                Icons.info_outlined,
                                color: primaryColor,
                                size: isMobile ? 18.0 : 22.0,
                              ),
                            ),
                            SizedBox(width: isMobile ? 12.0 : 16.0),
                            Expanded(
                              child: Text(
                                'How to use this portal',
                                style: TextStyle(
                                  fontSize: isMobile ? 14.0 : 16.0,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12.0 : 16.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoBullet(
                              'You can message Admin or HR directly from the Chat section.',
                              isMobile,
                            ),
                            SizedBox(height: 8),
                            _buildInfoBullet(
                              'If you\'ve been added to a group, you can chat with all group members.',
                              isMobile,
                            ),
                            SizedBox(height: 8),
                            _buildInfoBullet(
                              'Contact your Admin or HR if you need assistance.',
                              isMobile,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a stat card for client dashboard
  Widget _buildClientStatCard(Map<String, dynamic> card) {
    final Color accent = card['color'] as Color;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  card['title'] as String,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface.withOpacity(0.9),
                  ),
                ),
              ),
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  card['icon'] as IconData,
                  color: accent,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isLoading ? '...' : (card['value'] as int).toString(),
            style: TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            card['description'] as String,
            style: TextStyle(
              fontSize: 12.0,
              color: AppTheme.onSurface.withOpacity(0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Build info bullet point for client dashboard
  Widget _buildInfoBullet(String text, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: isMobile ? 4.0 : 6.0, right: 8.0),
          child: Icon(
            Icons.check_circle_outline,
            size: isMobile ? 14.0 : 16.0,
            color: Theme.of(context).primaryColor.withOpacity(0.7),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isMobile ? 12.0 : 13.0,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ─── HR DASHBOARD WIDGETS ───────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHRScaffold({
    required BuildContext context,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktopDevice,
    required double sidebarWidth,
    required double horizontalPadding,
    required double verticalSpacing,
    required double titleFontSize,
    required double iconSize,
  }) {
    return Scaffold(
      appBar: isDesktopDevice
          ? null
          : AppBar(
              title: Text(
                "HR Dashboard",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: titleFontSize,
                ),
              ),
              backgroundColor: _cardDark,
              elevation: 0,
              actions: [
                _buildChatIconButton(iconSize),
                _buildNotificationIconButton(iconSize),
              ],
            ),
      drawer: !isDesktopDevice
          ? Drawer(
              child: SidebarMenu(user: widget.user, token: widget.token),
            )
          : null,
      backgroundColor: _bgDark,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktopDevice)
            SizedBox(
              width: sidebarWidth,
              child: SidebarMenu(user: widget.user, token: widget.token),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadHRDashboardData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(horizontalPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Welcome Card (Check-in/Check-out) ──
                          WelcomeCard(
                            key: ValueKey<String>('${_isCheckedIn}_${_checkInTime?.toString() ?? "null"}'),  // Force rebuild on any state change
                            isCheckedIn: _isCheckedIn,
                            checkInTime: _checkInTime,
                            checkOutTime: _checkOutTime,
                            checkInLocation: _checkInLocation,
                            checkOutLocation: _checkOutLocation,
                            workHours: _workedDuration.inSeconds / 3600,
                            onCheckInToggle: _toggleCheckIn,
                            user: widget.user,
                          ),
                          SizedBox(height: verticalSpacing),

                          // ── Row 1: HR Profile | HR Stats | Pending Approvals ──
                          if (isDesktopDevice)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildHRProfileCard(isMobile),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildHRStatsCard(isMobile),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildPendingApprovalsCard(isMobile),
                                ),
                              ],
                            )
                          else ...[
                            _buildHRProfileCard(isMobile),
                            SizedBox(height: verticalSpacing),
                            _buildHRStatsCard(isMobile),
                            SizedBox(height: verticalSpacing),
                            _buildPendingApprovalsCard(isMobile),
                            SizedBox(height: verticalSpacing),
                          ],

                          // ── Row 2: 4 Stat Cards ──
                          _buildSectionHeader(
                            'Quick Stats',
                            Icons.speed,
                            _accentBlue,
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
                            crossAxisSpacing: isMobile ? 10 : 12,
                            mainAxisSpacing: isMobile ? 10 : 12,
                            childAspectRatio: isMobile
                                ? 1.2
                                : (isTablet ? 1.35 : 1.5),
                            children: [
                              _buildHRQuickStatCard(
                                'Employees on Leave',
                                '${_hrDashboard['pendingLeaves'] ?? 0}',
                                Icons.calendar_today,
                                Colors.amber,
                                isMobile: isMobile,
                              ),
                              _buildHRQuickStatCard(
                                'Pending Approvals',
                                '${_pendingLeaves.length + _pendingExpenses.length + ((_hrDashboard['activeTasks'] as num? ?? 0).toInt())}',
                                Icons.assignment,
                                Colors.redAccent,
                                isMobile: isMobile,
                              ),
                              _buildHRQuickStatCard(
                                'Active Tasks',
                                '${_hrDashboard['activeTasks'] ?? 0}',
                                Icons.task_alt,
                                _accentBlue,
                                isMobile: isMobile,
                              ),
                              _buildHRQuickStatCard(
                                'Total Departments',
                                '${_hrDashboard['totalDepartments'] ?? 0}',
                                Icons.domain,
                                _accentGreen,
                                isMobile: isMobile,
                              ),
                            ],
                          ),
                          SizedBox(height: verticalSpacing),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── HR Profile Card ──
  Widget _buildHRProfileCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar and Info
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _accentPink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.person,
                  color: _accentPink,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user?.name ?? 'HR Manager',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'HR Manager',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Contact Info
          Row(
            children: [
              Icon(Icons.phone, color: _accentPink.withOpacity(0.6), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _dashboardUser?.phone ?? '—',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.email, color: _accentPink.withOpacity(0.6), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.user?.email ?? '—',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── HR Stats Card ──
  Widget _buildHRStatsCard(bool isMobile) {
    print('🎨 [UI RENDER] _buildHRStatsCard() called');
    print('   _hrDashboard: $_hrDashboard');
    print('   _hrDashboard empty: ${_hrDashboard.isEmpty}');
    print('   totalEmployees: ${_hrDashboard['totalEmployees'] ?? 'NULL'}');
    print('   presentToday: ${_hrDashboard['presentToday'] ?? 'NULL'}');
    print('   pendingLeaves: ${_hrDashboard['pendingLeaves'] ?? 'NULL'}');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.business, color: _accentBlue, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'HR Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats rows
          _buildHRStatRow(
            'Total Employees',
            '${_hrDashboard['totalEmployees'] ?? 0}',
            _accentGreen,
          ),
          const SizedBox(height: 12),
          _buildHRStatRow(
            'Present Today',
            '${_hrDashboard['presentToday'] ?? 0}',
            _accentGreen,
          ),
          const SizedBox(height: 12),
          _buildHRStatRow(
            'On Leave',
            '${_hrDashboard['pendingLeaves'] ?? 0}',
            Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildHRStatRow(
            'Absent',
            '${((_hrDashboard['totalEmployees'] ?? 0) - (_hrDashboard['presentToday'] ?? 0) - (_hrDashboard['pendingLeaves'] ?? 0))}',
            Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildHRStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[400],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Pending Approvals Card ──
  Widget _buildPendingApprovalsCard(bool isMobile) {
    final leaveCount = _pendingLeaves.length;
    final expenseCount = _pendingExpenses.length;
    final taskCount = (_hrDashboard['activeTasks'] as num? ?? 0).toInt();
    final totalPending = leaveCount + expenseCount + taskCount;

    print('🎨 [UI RENDER] _buildPendingApprovalsCard() called');
    print('   leaveCount: $leaveCount');
    print('   expenseCount: $expenseCount');
    print('   taskCount: $taskCount');
    print('   totalPending: $totalPending');
    print('   _pendingLeaves length: ${_pendingLeaves.length}');
    print('   _pendingExpenses length: ${_pendingExpenses.length}');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pending Approvals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (totalPending > 0)
                      Text(
                        '$totalPending items awaiting action',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pending items - all children shown
          GestureDetector(
            onTap: () => _navigateToPendingLeaves(context),
            child: _buildPendingItem('Leave Requests', leaveCount.toString()),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _navigateToPendingExpenses(context),
            child: _buildPendingItem('Expense Claims', expenseCount.toString()),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _navigateToPendingTasks(context),
            child: _buildPendingItem('Active Tasks', taskCount.toString()),
          ),
          
          // See All Button
          if (totalPending > 0) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToAllPendingApprovals(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentBlue.withOpacity(0.2),
                  foregroundColor: _accentBlue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'See All Pending Approvals',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingItem(String label, String count) {
    final itemCount = int.tryParse(count) ?? 0;
    final hasItems = itemCount > 0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: hasItems ? Border.all(color: _accentPink.withOpacity(0.3)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[400],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: hasItems ? _accentPink.withOpacity(0.25) : _accentGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: hasItems ? _accentPink : _accentGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigation Methods for Pending Items ──

  /// Navigate to pending leaves screen (Employee Leaves - all employees)
  void _navigateToPendingLeaves(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeaveManagementScreen(token: widget.token),
      ),
    );
  }

  /// Navigate to pending expenses screen
  void _navigateToPendingExpenses(BuildContext context) {
    print('📍 [NAVIGATION] _navigateToPendingExpenses() called');
    print('   Current user role: $_userRole');

    // For HR users, pass 'hr' role so they can CREATE expenses
    // The ExpensesScreen treats both 'admin' and 'hr' roles equally for viewing all expenses
    // But the create button only shows for 'employee' and 'hr' roles
    final roleToPass = _userRole;
    print('   Navigating with role: $roleToPass');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpensesScreen(role: roleToPass),
      ),
    );
  }

  /// Navigate to pending tasks screen (Employee Tasks - admin view)
  void _navigateToPendingTasks(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TasksScreen(token: widget.token, role: 'admin'),
      ),
    );
  }

  /// Show all pending approvals in modal
  void _navigateToAllPendingApprovals(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'All Pending Approvals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Pending Leaves Section
                    _buildAllPendingSection(
                      title: 'Leave Requests',
                      count: _pendingLeaves.length,
                      icon: Icons.calendar_today,
                      color: Colors.amber,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToPendingLeaves(context);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Pending Expenses Section
                    _buildAllPendingSection(
                      title: 'Expense Claims',
                      count: _pendingExpenses.length,
                      icon: Icons.receipt_long,
                      color: Colors.deepPurple,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToPendingExpenses(context);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Active Tasks Section
                    _buildAllPendingSection(
                      title: 'Active Tasks',
                      count: (_hrDashboard['activeTasks'] as num? ?? 0).toInt(),
                      icon: Icons.task_alt,
                      color: _accentBlue,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToPendingTasks(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build pending section for all pending approvals modal
  Widget _buildAllPendingSection({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        count > 0 ? '$count pending' : 'All clear',
                        style: TextStyle(
                          fontSize: 12,
                          color: count > 0 ? Colors.grey[500] : _accentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── HR Quick Stat Card ──
  Widget _buildHRQuickStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isMobile = false,
  }) {
    final cardPadding = isMobile ? 12.0 : 16.0;
    final iconSize = isMobile ? 18.0 : 22.0;
    final iconPadding = isMobile ? 8.0 : 10.0;
    final valueFontSize = isMobile ? 18.0 : 22.0;
    final titleFontSize = isMobile ? 11.0 : 12.0;
    final spacerHeight = isMobile ? 8.0 : 12.0;
    final borderRadius = isMobile ? 12.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            padding: EdgeInsets.all(iconPadding),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
              border: Border.all(color: color.withOpacity(0.2), width: 0.5),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          SizedBox(height: spacerHeight),

          // Value and Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? 2 : 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ─── ADMIN DASHBOARD WIDGETS ─────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildAdminScaffold({
    required BuildContext context,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktopDevice,
    required double sidebarWidth,
    required double horizontalPadding,
    required double verticalSpacing,
    required double titleFontSize,
    required double iconSize,
  }) {
    return Scaffold(
      appBar: isDesktopDevice
          ? null
          : AppBar(
              title: Text(
                "Admin Panel",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: titleFontSize,
                ),
              ),
              backgroundColor: _cardDark,
              elevation: 0,
              actions: [
                _buildChatIconButton(iconSize),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.notifications_outlined, size: iconSize),
                  tooltip: 'Notification',
                ),
              ],
            ),
      drawer: !isDesktopDevice
          ? Drawer(
              child: SidebarMenu(user: widget.user, token: widget.token),
            )
          : null,
      backgroundColor: _bgDark,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktopDevice)
            SizedBox(
              width: sidebarWidth,
              child: SidebarMenu(user: widget.user, token: widget.token),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadAdminDashboardData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(horizontalPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Desktop Header ──
                          if (isDesktopDevice) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Admin Panel",
                                      style: TextStyle(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Welcome back, ${widget.user?.name ?? 'Admin'}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: _loadAdminDashboardData,
                                      icon: Icon(
                                        Icons.refresh,
                                        size: iconSize,
                                        color: Colors.grey[400],
                                      ),
                                      tooltip: 'Refresh',
                                    ),
                                    SizedBox(width: isMobile ? 4 : 8),
                                    IconButton(
                                      onPressed: () {},
                                      icon: Icon(
                                        Icons.settings_outlined,
                                        size: iconSize,
                                        color: Colors.grey[400],
                                      ),
                                      tooltip: 'Settings',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: verticalSpacing),
                          ] else ...[
                            // Mobile welcome
                            // Padding(
                              // padding: const EdgeInsets.only(bottom: 4),
                              // child: Text(
                              //   "Welcome back, ${widget.user?.name ?? 'Admin'}",
                              //   style: TextStyle(
                              //     fontSize: 14,
                              //     color: Colors.grey[500],
                              //   ),
                              // ),
                            // ),
                            // SizedBox(height: verticalSpacing),
                          ],

                          // ── System Overview ──
                          _buildSectionHeader(
                            'System Overview',
                            Icons.dashboard,
                            _accentBlue,
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
                            crossAxisSpacing: isMobile ? 10 : 12,
                            mainAxisSpacing: isMobile ? 10 : 12,
                            childAspectRatio: isMobile
                                ? 1.2
                                : (isTablet ? 1.35 : 1.5),
                            children: [
                              _buildAdminStatCard(
                                'Total Companies',
                                '${_adminDashboard['totalCompanies'] ?? 0}',
                                Icons.business,
                                _accentBlue,
                                isMobile: isMobile,
                              ),
                              _buildAdminStatCard(
                                'HR Accounts',
                                '${_adminDashboard['totalHRAccounts'] ?? 0}',
                                Icons.admin_panel_settings,
                                _accentPink,
                                isMobile: isMobile,
                              ),
                              _buildAdminStatCard(
                                'Total Employees',
                                '${_adminDashboard['totalEmployees'] ?? 0}',
                                Icons.people,
                                _accentGreen,
                                isMobile: isMobile,
                              ),
                              _buildAdminStatCard(
                                'Active Today',
                                '${_adminDashboard['activeToday'] ?? 0} / ${_adminDashboard['totalEmployees'] ?? 0}',
                                Icons.access_time,
                                _accentOrange,
                                isMobile: isMobile,
                              ),
                            ],
                          ),
                          SizedBox(height: verticalSpacing),

                          // ── Quick Stats ──
                          _buildSectionHeader(
                            'Quick Stats',
                            Icons.speed,
                            _accentPink,
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
                            crossAxisSpacing: isMobile ? 10 : 12,
                            mainAxisSpacing: isMobile ? 10 : 12,
                            childAspectRatio: isMobile
                                ? 1.2
                                : (isTablet ? 1.35 : 1.5),
                            children: [
                              _buildAdminStatCard(
                                'Pending Leaves',
                                '${_adminDashboard['pendingLeaves'] ?? 0}',
                                Icons.calendar_today,
                                Colors.amber,
                                isMobile: isMobile,
                              ),
                              _buildAdminStatCard(
                                'Active Tasks',
                                '${_adminDashboard['activeTasks'] ?? 0}',
                                Icons.assignment,
                                _accentBlue,
                                isMobile: isMobile,
                              ),
                              _buildAdminStatCard(
                                'Pending Expenses',
                                '${_adminDashboard['pendingExpenses'] ?? 0}',
                                Icons.receipt_long,
                                Colors.redAccent,
                                isMobile: isMobile,
                              ),
                              _buildAdminStatCard(
                                'Total Amount',
                                '₹${_formatAmount(_adminDashboard['totalExpenseAmount'] ?? 0)}',
                                Icons.account_balance_wallet,
                                _accentGreen,
                                isMobile: isMobile,
                              ),
                            ],
                          ),
                          SizedBox(height: verticalSpacing),

                          // ── Recent Activity + System Alerts ──
                          if (isDesktopDevice)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: _buildRecentActivitySection(),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: _buildSystemAlertsSection(),
                                ),
                              ],
                            )
                          else ...[
                            _buildRecentActivitySection(),
                            SizedBox(height: verticalSpacing),
                            _buildSystemAlertsSection(),
                          ],
                          SizedBox(height: verticalSpacing),

                          // ── Quick Actions ──
                          // _buildQuickActionsSection(isMobile),
                          // SizedBox(height: verticalSpacing),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ──
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  // ── Format Amount ──
  String _formatAmount(dynamic amount) {
    if (amount is int) {
      if (amount >= 100000) {
        return '${(amount / 100000).toStringAsFixed(1)}L';
      } else if (amount >= 1000) {
        return '${(amount / 1000).toStringAsFixed(1)}K';
      }
      return amount.toString();
    }
    return amount.toString();
  }

  // ── Admin Stat Card ──
  Widget _buildAdminStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isMobile = false,
  }) {
    final cardPadding = isMobile ? 12.0 : 16.0;
    final iconSize = isMobile ? 18.0 : 22.0;
    final iconPadding = isMobile ? 8.0 : 10.0;
    final valueFontSize = isMobile ? 18.0 : 22.0;
    final titleFontSize = isMobile ? 11.0 : 12.0;
    final spacerHeight = isMobile ? 8.0 : 12.0;
    final borderRadius = isMobile ? 12.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            padding: EdgeInsets.all(iconPadding),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
              border: Border.all(color: color.withOpacity(0.2), width: 0.5),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          SizedBox(height: spacerHeight),

          // Value Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? 2 : 4),

                // Title Text
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Recent Activity Section ──
  Widget _buildRecentActivitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.trending_up, color: _accentBlue, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'Latest actions across the system',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Activity List
          if (_recentActivity.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox, color: Colors.grey[700], size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'No recent activity',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                ..._recentActivity.asMap().entries.map((entry) {
                  final i = entry.key;
                  final activity = entry.value;
                  final timestamp = activity['timestamp'] as DateTime;
                  final diff = DateTime.now().difference(timestamp);
                  String timeStr;
                  if (diff.inMinutes < 1) {
                    timeStr = 'Just now';
                  } else if (diff.inMinutes < 60) {
                    timeStr = '${diff.inMinutes}m ago';
                  } else if (diff.inHours < 24) {
                    timeStr = '${diff.inHours}h ago';
                  } else {
                    timeStr = '${diff.inDays}d ago';
                  }

                  return Column(
                    children: [
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(
                            color: Colors.white.withOpacity(0.04),
                            height: 1,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            // Status indicator
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _accentGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _accentGreen.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  activity['icon'] as IconData,
                                  color: _accentGreen,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Message & User
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity['message'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    activity['user'] ?? 'System',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Time
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  // ── System Alerts Section ──
  Widget _buildSystemAlertsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'System Alerts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Items requiring attention',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),

          // No Alerts Message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _accentGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accentGreen.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: _accentGreen, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No alerts',
                    style: TextStyle(
                      color: _accentGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // System Health Section
          Text(
            'System Health',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Server Load
          _buildHealthMetric(
            label: 'Server Load',
            percentage: (_systemHealth['serverLoad'] as num? ?? 0).toInt(),
            color: _getHealthColor((_systemHealth['serverLoad'] as num? ?? 0).toDouble()),
          ),
          const SizedBox(height: 14),

          // Database
          _buildHealthMetric(
            label: 'Database',
            percentage: (_systemHealth['database'] as num? ?? 0).toInt(),
            color: _getHealthColor((_systemHealth['database'] as num? ?? 0).toDouble()),
          ),
          const SizedBox(height: 14),

          // Storage
          _buildHealthMetric(
            label: 'Storage',
            percentage: (_systemHealth['storage'] as num? ?? 0).toInt(),
            color: _getHealthColor((_systemHealth['storage'] as num? ?? 0).toDouble()),
          ),
        ],
      ),
    );
  }

  // ── Health Metric Widget ──
  Widget _buildHealthMetric({
    required String label,
    required int percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  /// Get color based on health percentage (green < 50, yellow < 80, red >= 80)
  Color _getHealthColor(double percentage) {
    if (percentage < 50) return _accentGreen;
    if (percentage < 80) return _accentOrange;
    return Colors.redAccent;
  }

  // ── Quick Actions Section ──
  // Navigate to apply leave screen
  void _onApplyLeave() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LeaveScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions and orientation using MediaQuery
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    // Responsive breakpoints
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isLargeDesktop = screenWidth >= 1200;

    // Combined desktop check
    final isDesktopDevice = screenWidth > 800;

    // Responsive dimensions
    final sidebarWidth = isLargeDesktop ? 280.0 : 250.0;
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);
    final verticalSpacing = isMobile ? 16.0 : 20.0;

    // Responsive font sizes
    final titleFontSize = isMobile ? 20.0 : (isTablet ? 22.0 : 24.0);
    final iconSize = isMobile ? 24.0 : 28.0;

    // Grid configuration
    final gridCrossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);
    final gridChildAspectRatio = isMobile ? 1.3 : (isTablet ? 1.4 : 1.6);
    final gridSpacing = isMobile ? 12.0 : 15.0;

    // Calculate progress (Assuming 8 hour workday target)
    double progress = _workedDuration.inMinutes / (8 * 60);
    // Calculate work hours as double for welcome card
    double workHours = _workedDuration.inMinutes / 60.0;

    // ── ADMIN PANEL ── Route to admin scaffold if user is admin
    if (_userRole == 'admin') {
      return _buildAdminScaffold(
        context: context,
        isMobile: isMobile,
        isTablet: isTablet,
        isDesktopDevice: isDesktopDevice,
        sidebarWidth: sidebarWidth,
        horizontalPadding: horizontalPadding,
        verticalSpacing: verticalSpacing,
        titleFontSize: titleFontSize,
        iconSize: iconSize,
      );
    }

    // ── HR PANEL ── Route to HR scaffold if user is HR
    if (_userRole == 'hr') {
      return _buildHRScaffold(
        context: context,
        isMobile: isMobile,
        isTablet: isTablet,
        isDesktopDevice: isDesktopDevice,
        sidebarWidth: sidebarWidth,
        horizontalPadding: horizontalPadding,
        verticalSpacing: verticalSpacing,
        titleFontSize: titleFontSize,
        iconSize: iconSize,
      );
    }

    // ── CLIENT PANEL ── Route to client scaffold if user is client
    if (_userRole == 'client') {
      return _buildClientScaffold(
        context: context,
        isMobile: isMobile,
        isDesktopDevice: isDesktopDevice,
        titleFontSize: titleFontSize,
        iconSize: iconSize,
      );
    }

    // ── EMPLOYEE PANEL ──
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          // --- APP BAR (Mobile Only) ---
          appBar: isDesktopDevice
              ? null
              : AppBar(
                  title: Text(
                    "Employee Dashboard",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: titleFontSize,
                    ),
                  ),
                  backgroundColor: Theme.of(context).cardColor,
                  elevation: 0,
                  actions: [
                    _buildChatIconButton(iconSize),
                    _buildNotificationIconButton(iconSize),
                  ],
                ),

          drawer: !isDesktopDevice
              ? Drawer(
                  child: SidebarMenu(user: widget.user, token: widget.token),
                )
              : null,

          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. SIDEBAR (Desktop Only)
              if (isDesktopDevice)
                SizedBox(
                  width: sidebarWidth,
                  child: SidebarMenu(user: widget.user, token: widget.token),
                ),

              // 2. MAIN CONTENT AREA
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Loading Dashboard...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Desktop Header
                            if (isDesktopDevice) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Employee Dashboard",
                                    style: TextStyle(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  // Desktop Notification and More Icons
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildNotificationIconButton(iconSize),
                                      SizedBox(width: isMobile ? 4 : 8),
                                      IconButton(
                                        onPressed: _onApplyLeave,
                                        icon:
                                            Icon(Icons.more_vert, size: iconSize),
                                        tooltip: 'More options',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: verticalSpacing),
                            ],

                            // Welcome Card (always visible after loading completes)
                            WelcomeCard(
                              key: ValueKey<String>('${_isCheckedIn}_${_checkInTime?.toString() ?? "null"}'),  // Force rebuild on any state change
                              isCheckedIn: _isCheckedIn,
                              checkInTime: _checkInTime,
                              checkOutTime: _checkOutTime,
                              checkInLocation: _checkInLocation,
                              checkOutLocation: _checkOutLocation,
                              workHours: workHours,
                              onCheckInToggle: _toggleCheckIn,
                              user: widget.user,
                            ),
                            SizedBox(height: verticalSpacing),

                            // Profile Card
                            ProfileCardWidget(
                              name: (_dashboardUser ?? widget.user)?.name,
                              role: (_dashboardUser ?? widget.user)?.role,
                              department: (_dashboardUser ?? widget.user)?.department,
                              phone: (_dashboardUser ?? widget.user)?.phone,
                              email: (_dashboardUser ?? widget.user)?.email,
                              address: (_dashboardUser ?? widget.user)?.address,
                              dateOfBirth: (_dashboardUser ?? widget.user)
                                  ?.dateOfBirth
                                  ?.toIso8601String(),
                              isActive: ((_dashboardUser ?? widget.user)?.status ?? '')
                                      .toLowerCase() ==
                                  'active',
                            ),
                            SizedBox(height: verticalSpacing),

                            // Status Card (Updates based on timer)
                            StatusCard(
                              workedDuration: _workedDuration,
                              progress: progress,
                              checkInTime: _checkInTime,
                            ),
                            SizedBox(height: verticalSpacing),

                            // Stats Grid (now visible after loading completes)
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: gridCrossAxisCount,
                              crossAxisSpacing: gridSpacing,
                              mainAxisSpacing: gridSpacing,
                              childAspectRatio: gridChildAspectRatio,
                              children: [
                                // StatCard(
                                //   title: "Casual Leave",
                                //   value: "${_dashboardStats?.leaveBalance.casual ?? 0} days",
                                //   icon: Icons.calendar_today,
                                //   isAlert: (_dashboardStats?.leaveBalance.casual ?? 0) < 2,
                                // ),
                                // StatCard(
                                //   title: "Active Tasks",
                                //   value: "${_dashboardStats?.activeTasks ?? 0}",
                                //   icon: Icons.assignment,
                                //   isAlert: (_dashboardStats?.activeTasks ?? 0) > 5,
                                // ),
                                // StatCard(
                                //   title: "Pending Expenses",
                                //   value: "₹${_dashboardStats?.pendingExpenses.toStringAsFixed(0) ?? '0'}",
                                //   icon: Icons.receipt_long,
                                //   isAlert: (_dashboardStats?.pendingExpenses ?? 0) > 0,
                                // ),
                                // StatCard(
                                //   title: "Month Attendance",
                                //   value: "${_dashboardStats?.attendancePercentage.toStringAsFixed(0) ?? '0'}%",
                                //   icon: Icons.access_time,
                                //   isAlert: (_dashboardStats?.attendancePercentage ?? 0) < 80,
                                // ),
                              ],
                            ),
                            SizedBox(height: verticalSpacing),

                            // Quick Stats: Appreciations, Warnings, Expenses, Complaints
                            DashboardQuickStatsSection(userId: widget.user?.id),
                            SizedBox(height: verticalSpacing),

                            // Attendance Statistics + Leave Statistics
                            if (isDesktopDevice)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: AttendanceStatisticsSection(
                                      userId: widget.user?.id,
                                    ),
                                  ),
                                  SizedBox(width: verticalSpacing),
                                  Expanded(
                                    child: LeaveStatisticsSection(
                                      userId: widget.user?.id,
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              AttendanceStatisticsSection(userId: widget.user?.id),
                              SizedBox(height: verticalSpacing),
                              LeaveStatisticsSection(userId: widget.user?.id),
                            ],
                            SizedBox(height: verticalSpacing),

                            // Tasks + Announcements Section
                            if (isDesktopDevice)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: TasksSection(token: widget.token)),
                                  SizedBox(width: verticalSpacing),
                                  Expanded(
                                    child: AnnouncementsSection(
                                      announcements: _announcements,
                                      isLoading: false,
                                      userId: widget.user?.id,
                                      onAnnouncementTap: _markAnnouncementAsRead,
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              TasksSection(token: widget.token),
                              SizedBox(height: verticalSpacing),
                              AnnouncementsSection(
                                announcements: _announcements,
                                isLoading: false,
                                userId: widget.user?.id,
                                onAnnouncementTap: _markAnnouncementAsRead,
                              ),
                            ],
                            SizedBox(height: verticalSpacing),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
