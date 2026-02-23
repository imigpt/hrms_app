import 'dart:async'; // Required for the Timer
import 'package:flutter/material.dart';
import 'package:hrms_app/models/profile_model.dart';
import 'package:hrms_app/models/attendance_checkin_model.dart';
import 'package:hrms_app/models/announcement_model.dart';
import 'package:hrms_app/models/dashboard_stats_model.dart';
import 'package:hrms_app/services/attendance_service.dart';
import 'package:hrms_app/services/announcement_service.dart';
import 'package:hrms_app/services/announcement_websocket_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Import our custom widgets
import '../widgets/sidebar_menu.dart';
import '../widgets/welcome_card.dart';
import '../widgets/status_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/tasks_section.dart';
import '../widgets/announcements_section.dart';
import '../widgets/location_permission_dialog.dart';
import '../widgets/attendance_statistics_section.dart';
import '../widgets/leave_statistics_section.dart';
import '../widgets/dashboard_quick_stats_section.dart';
import '../widgets/profile_card_widget.dart';
import 'announcements_screen.dart';
// import 'employee_api_test_screen.dart';
import 'apply_leave_screen.dart';
import 'attendance_screen.dart';


class DashboardScreen extends StatefulWidget {
  final ProfileUser? user;
  final String? token;

  const DashboardScreen({super.key, this.user, this.token});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- STATE VARIABLES ---
  bool _isCheckedIn = false;
  bool _showPhotoUI = false;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  String? _checkInLocation;
  String? _checkOutLocation;
  Duration _workedDuration = const Duration(hours: 0, minutes: 0);
  Timer? _timer;
  AttendanceData? _todayAttendance;
  bool _isLoadingAttendance = true;
  List<Announcement> _announcements = [];
  bool _isLoadingAnnouncements = true;
  int _unreadAnnouncementsCount = 0;
  
  // Dashboard stats
  DashboardStats? _dashboardStats;
  bool _isLoadingStats = true;

  // Tracks which announcement IDs have been marked read (persisted across sessions)
  Set<String> _readAnnouncementIds = {};
  
  // WebSocket service for real-time announcements
  final AnnouncementWebSocketService _wsService = AnnouncementWebSocketService();
  StreamSubscription<List<Announcement>>? _announcementsSubscription;

  @override
  void initState() {
    super.initState();
    _loadCachedAttendanceState();  // Load cached state first
    _loadPersistedReadIds();           // Load persisted read announcements
    _loadTodayAttendance();
    _loadDashboardStats();  // Load dashboard statistics
    
    // Load unread count from API (fast badge update)
    _loadUnreadCount();

    // Load announcements immediately via REST API for quick display
    _loadAnnouncementsFallback();
    
    // Also connect to WebSocket for real-time updates
    _connectToAnnouncementsWebSocket();
    
    // Start the timer to simulate working hours increasing
    _startTimer();
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
        await prefs.setString('check_out_time', _checkOutTime!.toIso8601String());
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
        print('hasCheckedIn: ${response.data!.hasCheckedIn}, hasCheckedOut: ${response.data!.hasCheckedOut}');
        print('data: ${response.data}');
      }

      if (response != null && response.data != null && mounted) {
        setState(() {
          final attendanceData = response.data!;
          _isCheckedIn = attendanceData.hasCheckedIn && !attendanceData.hasCheckedOut;
          
          try {
            print('Using attendance data from API');
            print('Check-in time string: ${attendanceData.checkIn?.time}');
            
            // Check if attendance is from today
            if (attendanceData.checkIn?.time != null) {
              final checkInDateTime = DateTime.tryParse(attendanceData.checkIn!.time!);
              if (checkInDateTime != null) {
                final today = DateTime.now();
                final isSameDay = checkInDateTime.year == today.year && 
                                  checkInDateTime.month == today.month && 
                                  checkInDateTime.day == today.day;
                
                print('Is same day: $isSameDay');
                
                // Only set check-in/out times if they're from today
                if (isSameDay) {
                  _checkInTime = checkInDateTime;
                  
                  // Set check-in location
                  if (attendanceData.checkIn?.location != null) {
                    final lat = attendanceData.checkIn!.location!['latitude'] ?? 0.0;
                    final lng = attendanceData.checkIn!.location!['longitude'] ?? 0.0;
                    _checkInLocation = '${(lat as num).toDouble().toStringAsFixed(6)}, ${(lng as num).toDouble().toStringAsFixed(6)}';
                  }
                  
                  // Set check-out info if available
                  if (attendanceData.checkOut?.time != null) {
                    final checkOutDateTime = DateTime.tryParse(attendanceData.checkOut!.time!);
                    if (checkOutDateTime != null) {
                      _checkOutTime = checkOutDateTime;
                      if (attendanceData.checkOut!.location != null) {
                        final lat = attendanceData.checkOut!.location!['latitude'] ?? 0.0;
                        final lng = attendanceData.checkOut!.location!['longitude'] ?? 0.0;
                        _checkOutLocation = '${(lat as num).toDouble().toStringAsFixed(6)}, ${(lng as num).toDouble().toStringAsFixed(6)}';
                      }
                    }
                  }
                  
                  // Calculate worked duration
                  if (_isCheckedIn) {
                    _workedDuration = DateTime.now().difference(checkInDateTime);
                  } else if (attendanceData.checkOut?.time != null) {
                    final checkOutDateTime = DateTime.tryParse(attendanceData.checkOut!.time!);
                    if (checkOutDateTime != null) {
                      _workedDuration = checkOutDateTime.difference(checkInDateTime);
                    }
                  }
                  
                  print('State updated - _isCheckedIn: $_isCheckedIn, checkInTime: $_checkInTime, checkOutTime: $_checkOutTime');
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
        print('Response is null - no attendance for today');
        setState(() {
          _isLoadingAttendance = false;
        });
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
      
      // Set a timeout - if no data received in 10 seconds, use REST API fallback
      bool dataReceived = false;
      Timer? timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (!dataReceived && mounted && _isLoadingAnnouncements) {
          print('WebSocket timeout - falling back to REST API');
          _loadAnnouncementsFallback();
        }
      });
      
      // Listen to announcements stream
      _announcementsSubscription = _wsService.announcementsStream.listen(
        (announcements) {
          dataReceived = true;
          timeoutTimer?.cancel();
          if (mounted) {
            final previousCount = _unreadAnnouncementsCount;
            setState(() {
              _announcements = announcements;
              _isLoadingAnnouncements = false;
              _unreadAnnouncementsCount = _calculateUnreadCount(announcements);
            });
            print('Announcements updated via WebSocket: ${announcements.length} items (${_unreadAnnouncementsCount} unread)');
            if (previousCount != _unreadAnnouncementsCount) {
              print('Badge count changed: $previousCount -> $_unreadAnnouncementsCount');
            }
          }
        },
        onError: (error) {
          print('WebSocket stream error: $error');
          timeoutTimer?.cancel();
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
          if (_isLoadingAnnouncements && response.data.announcements.isNotEmpty) {
            _announcements = response.data.announcements
                .map((a) => Announcement(
                      id: a.id,
                      title: a.title,
                      content: a.message,
                      priority: 'normal',
                      readBy: [],
                      isActive: true,
                      attachments: [],
                      createdAt: a.createdAt,
                      updatedAt: a.createdAt,
                    ))
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
    
    print('Calculated unread count: $unreadCount (userId: $userId, total announcements: ${announcements.length})');
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
  /// Navigate to Attendance Screen and trigger check-in or check-out flow.
  void _toggleCheckIn() {
    final action = _isCheckedIn ? 'checkOut' : 'checkIn';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceScreen(initialAction: action),
      ),
    ).then((_) {
      // Refresh dashboard state when returning from Attendance Screen
      _loadTodayAttendance();
      _loadDashboardStats();
    });
  }

  // Check location services before starting check-in
  Future<void> _checkLocationAndStartCheckIn() async {
    try {
      print('=== Check-In: Checking Location Permission ===');
      
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('Location service enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services to mark attendance'),
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
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        // Show custom dialog to explain why we need location
        if (mounted) {
          final shouldRequest = await LocationPermissionDialog.show(
            context, 
            isPermanentlyDenied: permission == LocationPermission.deniedForever
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
            
            if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
              print('Permission denied by user');
              return;
            }
          } else {
            return;
          }
        }
      }

      print('Location permission granted, showing photo UI');
      // Location is enabled and permission granted, show photo UI
      setState(() {
        _showPhotoUI = true;
      });
    } catch (e) {
      print('Error in _checkLocationAndStartCheckIn: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking location: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        // Show custom dialog to explain why we need location
        if (mounted) {
          final shouldRequest = await LocationPermissionDialog.show(
            context, 
            isPermanentlyDenied: permission == LocationPermission.deniedForever
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
            
            if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
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
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('=== Check-Out Process ===');
      print('Attempting check-out with token: ${widget.token!.substring(0, 20)}...');
      print('Location captured: Lat=${position.latitude}, Long=${position.longitude}');

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
          _showPhotoUI = false;
          _todayAttendance = response.data;
          
          // Parse check-in data - time is already a DateTime in the model
          _checkInTime = response.data.checkIn.time;
          if (response.data.checkIn.location != null) {
            _checkInLocation = '${response.data.checkIn.location!.latitude.toStringAsFixed(6)}, ${response.data.checkIn.location!.longitude.toStringAsFixed(6)}';
          }
          
          // Parse check-out data
          if (response.data.checkOut != null) {
            _checkOutTime = response.data.checkOut!.time;
            if (response.data.checkOut!.location != null) {
              _checkOutLocation = '${response.data.checkOut!.location!.latitude.toStringAsFixed(6)}, ${response.data.checkOut!.location!.longitude.toStringAsFixed(6)}';
            }
            
            // Calculate worked duration
            if (_checkInTime != null) {
              _workedDuration = response.data.checkOut!.time.difference(_checkInTime!);
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

  // Called when photo capture returns with result
  void _handleCheckInResult(dynamic result) async {
    if (result != null && result is AttendanceData) {
      setState(() {
        _isCheckedIn = true;
        _showPhotoUI = false;
        _checkInTime = result.checkIn.time;
        _todayAttendance = result;
        if (result.checkIn.location != null) {
          _checkInLocation = '${result.checkIn.location!.latitude.toStringAsFixed(6)}, ${result.checkIn.location!.longitude.toStringAsFixed(6)}';
        }
        _workedDuration = DateTime.now().difference(result.checkIn.time);
      });
      
      // Save the updated state to local storage
      await _saveAttendanceState();
      
      // Reload dashboard stats to update attendance percentage
      _loadDashboardStats();
    } else if (result == 'refresh') {
      // User was already checked in on backend - reload attendance data
      setState(() {
        _showPhotoUI = false;
      });
      await _loadTodayAttendance();
      _loadDashboardStats(); // Reload stats as well
    } else {
      // User cancelled or error occurred
      setState(() {
        _showPhotoUI = false;
      });
    }
  }

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
                    // --- EMPLOYEE API TEST ---
                    // IconButton(
                    //   icon: const Icon(Icons.api_outlined, color: Colors.pinkAccent),
                    //   onPressed: () => Navigator.push(
                    //     context,
                    //     MaterialPageRoute(builder: (_) => const EmployeeApiTestScreen()),
                    //   ),
                    //   tooltip: 'Employee API Tests',
                    // ),
                    // --- NOTIFICATION ICON ---
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AnnouncementsScreen()),
                        );
                      },
                      icon: _unreadAnnouncementsCount > 0
                          ? Badge(
                              label: Text(_unreadAnnouncementsCount.toString()),
                              backgroundColor: Colors.red,
                              child: Icon(Icons.notifications_outlined, size: iconSize),
                            )
                          : Icon(Icons.notifications_outlined, size: iconSize),
                    ),
                    // --- MORE OPTIONS (THREE-DOTS) ICON ---
                    Padding(
                      padding: EdgeInsets.only(right: isMobile ? 4.0 : 8.0),
                      child: IconButton(
                        onPressed: _onApplyLeave,
                        icon: Icon(Icons.more_vert, size: iconSize),
                        tooltip: 'More options',
                      ),
                    ),
                  ],
                ),
          
            drawer: !isDesktopDevice
              ? Drawer(child: SidebarMenu(user: widget.user, token: widget.token))
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
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const AnnouncementsScreen()),
                                    );
                                  },
                                  icon: _unreadAnnouncementsCount > 0
                                      ? Badge(
                                          label: Text(_unreadAnnouncementsCount.toString()),
                                          backgroundColor: Colors.red,
                                          child: Icon(Icons.notifications_outlined, size: iconSize),
                                        )
                                      : Icon(Icons.notifications_outlined, size: iconSize),
                                ),
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
                              showPhotoUI: _showPhotoUI,
                              checkInTime: _checkInTime,
                              checkOutTime: _checkOutTime,
                              checkInLocation: _checkInLocation,
                              checkOutLocation: _checkOutLocation,
                              workHours: workHours,
                              onCheckInToggle: _toggleCheckIn,
                              onCheckInResult: _handleCheckInResult,
                              user: widget.user,
                            ),
                      SizedBox(height: verticalSpacing),

                      // Status Card (Updates based on timer)
                      StatusCard(
                        workedDuration: _workedDuration,
                        progress: progress,
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
                            ? List.generate(4, (index) => Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ))
                            : [
                                StatCard(
                                  title: "Casual Leave",
                                  value: "${_dashboardStats?.leaveBalance.casual ?? 0} days",
                                  icon: Icons.calendar_today,
                                  isAlert: (_dashboardStats?.leaveBalance.casual ?? 0) < 2,
                                ),
                                StatCard(
                                  title: "Active Tasks",
                                  value: "${_dashboardStats?.activeTasks ?? 0}",
                                  icon: Icons.assignment,
                                  isAlert: (_dashboardStats?.activeTasks ?? 0) > 5,
                                ),
                                StatCard(
                                  title: "Pending Expenses",
                                  value: "₹${_dashboardStats?.pendingExpenses.toStringAsFixed(0) ?? '0'}",
                                  icon: Icons.receipt_long,
                                  isAlert: (_dashboardStats?.pendingExpenses ?? 0) > 0,
                                ),
                                StatCard(
                                  title: "Month Attendance",
                                  value: "${_dashboardStats?.attendancePercentage.toStringAsFixed(0) ?? '0'}%",
                                  icon: Icons.access_time,
                                  isAlert: (_dashboardStats?.attendancePercentage ?? 0) < 80,
                                ),
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
                            const Expanded(child: TasksSection()),
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
                        const TasksSection(),
                        SizedBox(height: verticalSpacing),
                        AnnouncementsSection(
                          announcements: _announcements,
                          isLoading: _isLoadingAnnouncements,
                          userId: widget.user?.id,
                          onAnnouncementTap: _markAnnouncementAsRead,
                        ),
                      ],
                      SizedBox(height: verticalSpacing),

                      // Profile Card
                      ProfileCardWidget(
                        name: widget.user?.name,
                        role: widget.user?.role,
                        department: widget.user?.department,
                        phone: widget.user?.phone,
                        email: widget.user?.email,
                        address: widget.user?.address,
                        dateOfBirth: widget.user?.dateOfBirth?.toIso8601String(),
                        isActive: (widget.user?.status ?? '').toLowerCase() == 'active',
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
}