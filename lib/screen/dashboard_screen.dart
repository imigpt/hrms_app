import 'dart:async'; // Required for the Timer
import 'package:flutter/material.dart';
import 'package:hrms_app/models/profile_model.dart';
import 'package:hrms_app/models/announcement_model.dart';
import 'package:hrms_app/models/dashboard_stats_model.dart';
import 'package:hrms_app/services/attendance_service.dart';
import 'package:hrms_app/services/announcement_service.dart';
import 'package:hrms_app/services/announcement_websocket_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/profile_service.dart';

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
  bool _isLoadingAttendance = true;
  List<Announcement> _announcements = [];
  bool _isLoadingAnnouncements = true;
  int _unreadAnnouncementsCount = 0;
  int _unreadChatCount = 0; // Unread chat messages count

  // Dashboard stats
  DashboardStats? _dashboardStats;
  bool _isLoadingStats = true;

  // Tracks which announcement IDs have been marked read (persisted across sessions)
  Set<String> _readAnnouncementIds = {};

  // WebSocket service for real-time announcements
  final AnnouncementWebSocketService _wsService =
      AnnouncementWebSocketService();
  StreamSubscription<List<Announcement>>? _announcementsSubscription;

  // Full profile (fetched fresh on load to get phone/address/dob etc.)
  ProfileUser? _dashboardUser;

  // ── ADMIN DASHBOARD STATE ───────────────────────────────────────────────────
  Map<String, dynamic> _adminDashboard = {};
  List<dynamic> _recentActivity = [];
  bool _isLoadingAdminData = true;
  String _userRole = 'employee';

  @override
  void initState() {
    super.initState();

    // Determine user role
    _userRole = (widget.user?.role.toLowerCase() == 'admin')
        ? 'admin'
        : 'employee';

    // Fetch full profile data (includes phone, address, dob etc.)
    _fetchDashboardProfile();

    // Load unread chat count for both admin and employee
    _loadUnreadChatCount();

    if (_userRole == 'admin') {
      // Load admin dashboard data
      _loadAdminDashboard();
      // Also load announcements and unread count for notification badge
      _loadPersistedReadIds();
      _loadUnreadCount();
      _loadAnnouncementsFallback();
    } else {
      // Load employee dashboard data
      _loadCachedAttendanceState(); // Load cached state first
      _loadPersistedReadIds(); // Load persisted read announcements
      _loadTodayAttendance();
      _loadDashboardStats(); // Load dashboard statistics

      // Load unread count from API (fast badge update)
      _loadUnreadCount();

      // Load announcements immediately via REST API for quick display
      _loadAnnouncementsFallback();

      // Also connect to WebSocket for real-time updates
      _connectToAnnouncementsWebSocket();

      // Start the timer to simulate working hours increasing
      _startTimer();
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
      setState(() {
        _isLoadingAttendance = false;
      });
      return;
    }

    try {
      print('Loading today attendance from API...');
      final response = await AttendanceService.getTodayAttendance(
        token: widget.token!,
      );

      print('API Response received: ${response != null}');
      if (response != null && response.data != null) {
        print(
          'hasCheckedIn: ${response.data!.hasCheckedIn}, hasCheckedOut: ${response.data!.hasCheckedOut}',
        );
        print('data: ${response.data}');
      }

      if (response != null && response.data != null && mounted) {
        setState(() {
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

          _isLoadingAttendance = false;
        });

        // Save the loaded state to local storage
        await _saveAttendanceState();
      } else {
        print(
          'Response is null - no attendance for today, clearing stale state',
        );
        setState(() {
          _isLoadingAttendance = false;
          // No record from server means user hasn't checked in today.
          // Clear any stale SharedPreferences data so "Day Complete" doesn't linger.
          _isCheckedIn = false;
          _checkInTime = null;
          _checkOutTime = null;
          _checkInLocation = null;
          _checkOutLocation = null;
          _workedDuration = const Duration(hours: 0, minutes: 0);
        });
        await _saveAttendanceState();
      }
    } catch (e, stackTrace) {
      print('Error loading today attendance: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoadingAttendance = false;
        });
      }
    }
  }

  // Connect to WebSocket for real-time announcements
  Future<void> _connectToAnnouncementsWebSocket() async {
    if (widget.token == null) {
      setState(() {
        _isLoadingAnnouncements = false;
      });
      return;
    }

    try {
      print('Connecting to announcements WebSocket...');

      // Set a timeout - if no data received in 4 seconds, use REST API fallback
      bool dataReceived = false;
      Timer? timeoutTimer = Timer(const Duration(seconds: 4), () {
        if (!dataReceived && mounted && _isLoadingAnnouncements) {
          print('WebSocket timeout - falling back to REST API');
          _loadAnnouncementsFallback();
        }
      });

      // Listen to announcements stream
      _announcementsSubscription = _wsService.announcementsStream.listen(
        (announcements) {
          dataReceived = true;
          timeoutTimer.cancel();
          if (mounted) {
            final previousCount = _unreadAnnouncementsCount;
            setState(() {
              _announcements = announcements;
              _isLoadingAnnouncements = false;
              _unreadAnnouncementsCount = _calculateUnreadCount(announcements);
            });
            print(
              'Announcements updated via WebSocket: ${announcements.length} items (${_unreadAnnouncementsCount} unread)',
            );
            if (previousCount != _unreadAnnouncementsCount) {
              print(
                'Badge count changed: $previousCount -> $_unreadAnnouncementsCount',
              );
            }
          }
        },
        onError: (error) {
          print('WebSocket stream error: $error');
          timeoutTimer.cancel();
          if (mounted && _isLoadingAnnouncements) {
            _loadAnnouncementsFallback();
          }
        },
      );

      // Connect to WebSocket
      await _wsService.connect(widget.token!);
    } catch (e) {
      print('Error connecting to announcements WebSocket: $e');
      if (mounted) {
        setState(() {
          _isLoadingAnnouncements = false;
        });
      }

      // Fallback to REST API if WebSocket fails
      _loadAnnouncementsFallback();
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
  Future<void> _loadUnreadCount() async {
    if (widget.token == null) return;
    try {
      final count = await AnnouncementService.getUnreadCount(
        token: widget.token!,
      );
      if (mounted) {
        setState(() {
          _unreadAnnouncementsCount = count;
        });
        print('Unread announcements count from API: $count');
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

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

  Future<void> _loadAnnouncementsFallback() async {
    if (widget.token == null) return;

    try {
      print('Loading announcements from REST API (fallback)...');
      final response = await AnnouncementService.getAnnouncements(
        token: widget.token!,
      );

      print('Announcements loaded: ${response.data.length} items');

      if (mounted) {
        setState(() {
          _announcements = response.data;
          _isLoadingAnnouncements = false;
          _unreadAnnouncementsCount = _calculateUnreadCount(response.data);
        });
      }
    } catch (e) {
      print('Error loading announcements: $e');
      if (mounted) {
        setState(() {
          _isLoadingAnnouncements = false;
        });
      }
    }
  }

  // Load Dashboard Stats
  Future<void> _loadDashboardStats() async {
    if (widget.token == null) {
      setState(() {
        _isLoadingStats = false;
      });
      return;
    }

    try {
      print('Loading dashboard stats from /employees/dashboard ...');
      final response = await AttendanceService.getDashboardStats(
        token: widget.token!,
      );

      print('Dashboard stats response received: ${response != null}');

      if (response != null && mounted) {
        setState(() {
          _dashboardStats = response.data.stats;
          _isLoadingStats = false;

          // Populate announcements from dashboard response if WebSocket hasn't loaded them yet
          if (_isLoadingAnnouncements &&
              response.data.announcements.isNotEmpty) {
            _announcements = response.data.announcements
                .map(
                  (a) => Announcement(
                    id: a.id,
                    title: a.title,
                    content: a.message,
                    priority: 'normal',
                    readBy: [],
                    isActive: true,
                    attachments: [],
                    createdAt: a.createdAt,
                    updatedAt: a.createdAt,
                  ),
                )
                .toList();
            _isLoadingAnnouncements = false;
            _unreadAnnouncementsCount = _calculateUnreadCount(_announcements);
          }
        });
        print('Dashboard stats loaded successfully');
        print('Casual Leave Balance: ${_dashboardStats?.leaveBalance.casual}');
        print('Active Tasks: ${_dashboardStats?.activeTasks}');
        print('Pending Expenses: ${_dashboardStats?.pendingExpenses}');
        print('Attendance %: ${_dashboardStats?.attendancePercentage}');
      } else {
        if (mounted) {
          setState(() {
            _isLoadingStats = false;
          });
        }
      }
    } catch (e) {
      print('Error loading dashboard stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  // ── LOAD ADMIN DASHBOARD ────────────────────────────────────────────────────
  Future<void> _loadAdminDashboard() async {
    if (widget.token == null) {
      setState(() {
        _isLoadingAdminData = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingAdminData = true;
      });
    }

    try {
      final authService = AuthService();

      // Fetch stats and activity in parallel
      final results = await Future.wait([
        authService.getAdminDashboardStats(widget.token!),
        authService.getAdminRecentActivity(widget.token!, limit: 8),
      ]);

      final stats = results[0] as Map<String, dynamic>;
      final activity = results[1] as List<Map<String, dynamic>>;

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

      final mappedActivity = activity.map((a) {
        return {
          'type': a['type'] ?? '',
          'message': '${a['action'] ?? ''} — ${a['user'] ?? ''}',
          'timestamp':
              DateTime.tryParse(a['time']?.toString() ?? '') ?? DateTime.now(),
          'icon': iconForType(a['type']?.toString() ?? ''),
          'status': a['status'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _adminDashboard = {
            'totalCompanies': stats['totalCompanies'] ?? 0,
            'totalHRAccounts': stats['totalHR'] ?? 0,
            'totalEmployees': stats['totalEmployees'] ?? 0,
            'activeToday': stats['activeToday'] ?? 0,
            'pendingLeaves': stats['pendingLeaves'] ?? 0,
            'activeTasks': stats['activeTasks'] ?? 0,
            'pendingExpenses': stats['pendingExpensesCount'] ?? 0,
            'totalExpenseAmount': stats['pendingExpenses'] ?? 0,
          };
          _recentActivity = mappedActivity;
          _isLoadingAdminData = false;
        });
      }
    } catch (e) {
      print('Error loading admin dashboard: $e');
      if (mounted) {
        setState(() {
          _isLoadingAdminData = false;
        });
      }
    }
  }

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
      icon: _unreadAnnouncementsCount > 0
          ? Badge(
              label: Text(_unreadAnnouncementsCount.toString()),
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
                    _unreadAnnouncementsCount > 0
                        ? '$_unreadAnnouncementsCount unread'
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
      if (_unreadAnnouncementsCount > 0) {
        _unreadAnnouncementsCount--;
      }
    });

    // Persist to local storage so read state survives app restarts
    _persistReadId(announcementId);

    // Call REST API + WebSocket, then sync authoritative count from server
    _wsService.markAsRead(announcementId).then((_) {
      _loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _announcementsSubscription?.cancel();
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
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const AttendanceScreen(initialAction: 'checkIn'),
        ),
      );
      
      if (mounted) {
        await _loadTodayAttendance();
        await _loadDashboardStats();
        
        // Show BOD dialog after successful check-in (non-blocking)
        if (result != null && result != 'cancel') {
          // Delay slightly so the navigation animation completes
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const BODBottomSheet(),
              );
            }
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

        // Reload dashboard stats to update attendance percentage
        _loadDashboardStats();

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
            child: _isLoadingAdminData
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadAdminDashboard,
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
                                      onPressed: _loadAdminDashboard,
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
                                '${_adminDashboard['activeToday'] ?? 0}',
                                Icons.trending_up,
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
            percentage: 88,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 14),

          // Database
          _buildHealthMetric(
            label: 'Database',
            percentage: 0,
            color: _accentGreen,
          ),
          const SizedBox(height: 14),

          // Storage
          _buildHealthMetric(
            label: 'Storage',
            percentage: 1,
            color: _accentGreen,
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
                child: SingleChildScrollView(
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
                                  icon: Icon(Icons.more_vert, size: iconSize),
                                  tooltip: 'More options',
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: verticalSpacing),
                      ],

                      _isLoadingAttendance
                          ? Container(
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : WelcomeCard(
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
                        dateOfBirth: (_dashboardUser ?? widget.user)?.dateOfBirth?.toIso8601String(),
                        isActive:
                            ((_dashboardUser ?? widget.user)?.status ?? '').toLowerCase() ==
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

                      // Responsive Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: gridCrossAxisCount,
                        crossAxisSpacing: gridSpacing,
                        mainAxisSpacing: gridSpacing,
                        childAspectRatio: gridChildAspectRatio,
                        children: _isLoadingStats
                            ? List.generate(
                                4,
                                (index) => Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              )
                            : [
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

                      // Responsive Bottom Section
                      if (isDesktopDevice)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: TasksSection(token: widget.token)),
                            SizedBox(width: verticalSpacing),
                            Expanded(
                              child: AnnouncementsSection(
                                announcements: _announcements,
                                isLoading: _isLoadingAnnouncements,
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
                          isLoading: _isLoadingAnnouncements,
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
