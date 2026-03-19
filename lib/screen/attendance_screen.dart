import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'camera_screen.dart';
import 'attendance_history_screen.dart';
import 'package:hrms_app/shared/widgets/common/bod_eod_dialogs.dart';
import 'package:hrms_app/features/attendance/data/services/attendance_service.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';
import 'package:hrms_app/features/profile/data/services/profile_service.dart';
import 'package:hrms_app/features/profile/data/models/profile_model.dart';
import 'package:hrms_app/features/attendance/data/models/attendance_summary_model.dart';
import 'package:hrms_app/features/attendance/data/models/attendance_records_model.dart' as records;
import 'package:hrms_app/features/attendance/data/models/attendance_edit_request_model.dart';
import 'package:hrms_app/shared/widgets/common/welcome_card.dart';
import 'package:hrms_app/shared/widgets/common/location_permission_dialog.dart';
import 'package:hrms_app/shared/widgets/common/attendance_edit_request_dialog.dart';
import 'edit_requests_screen.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';
// import 'attendance_api_test_screen.dart';

// 1. Define Status Enum
enum AttendanceStatus { present, absent, late, halfDay, leave }

/// [initialAction] can be 'checkIn' or 'checkOut' to immediately trigger
/// the respective flow when the screen opens from the dashboard.
class AttendanceScreen extends StatefulWidget {
  final String? initialAction;

  const AttendanceScreen({super.key, this.initialAction, String? token});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // --- Existing State ---
  bool _isCheckedIn = false;

  // --- Test Mode (for QA: allows unlimited check-in/check-out) ---
  // Static so it persists when navigating away and back
  static bool _testModeEnabled = false;

  // --- DateTime State for Welcome Card ---
  DateTime? _checkInDateTime;
  DateTime? _checkOutDateTime;
  Duration _workedDuration = const Duration(hours: 0, minutes: 0);
  String? _token;
  ProfileUser? _user;

  // --- Location State ---
  String? _checkInLocation;
  String? _checkOutLocation;

  // --- Attendance Summary State ---
  AttendanceSummaryData? _summaryData;
  bool _isLoadingSummary = true;

  // --- Calendar State ---
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Attendance History Data for the Calendar
  Map<DateTime, AttendanceStatus> _attendanceData = {};
  bool _isLoadingHistory = false;

  // Latest Attendance Records (max 5)
  List<records.AttendanceRecord> _latestRecords = [];
  bool _isLoadingRecords = false;

  // Edit Requests preview (max 3)
  List<AttendanceEditRequestData> _editRequests = [];
  bool _isLoadingEditRequests = false;

  @override
  void initState() {
    super.initState();

    _fetchTodayAttendance();
    _fetchAttendanceSummary();
    _fetchAttendanceHistory();
    _fetchLatestRecords();
    _fetchEditRequestsPreview();
    _fetchUserProfile();

    // Handle location permission check in background after UI is rendered
    if (widget.initialAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (widget.initialAction == 'checkIn') {
          await _checkLocationAndStartCheckIn();
        } else if (widget.initialAction == 'checkOut') {
          final confirmed = await _showEODBottomSheet();
          if (confirmed && mounted) {
            await _handleCheckOut();
          }
        }
      });
    }
  }

  // Fetch Today's Attendance
  Future<void> _fetchTodayAttendance() async {
    try {
      final token = await TokenStorageService().getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      setState(() {
        _token = token;
      });

      final todayAttendance = await AttendanceService.getTodayAttendance(
        token: token,
      );

      if (mounted && todayAttendance != null && todayAttendance.data != null) {
        setState(() {
          final data = todayAttendance.data!;
          // Derive checked-in state: prefer model flags, fallback to actual data presence
          final hasCheckedIn =
              data.hasCheckedIn || (data.checkIn?.time != null);
          final hasCheckedOut =
              data.hasCheckedOut || (data.checkOut?.time != null);
          _isCheckedIn = hasCheckedIn && !hasCheckedOut;

          // Parse check-in and check-out times from AttendanceCheckPoint objects
          try {
            if (data.checkIn != null && data.checkIn!.time != null) {
              final checkInTime =
                  (DateTime.tryParse(data.checkIn!.time!) ?? DateTime.now())
                      .toLocal();
              _checkInDateTime = checkInTime;
            }

            if (data.checkOut != null && data.checkOut!.time != null) {
              final checkOutTime =
                  (DateTime.tryParse(data.checkOut!.time!) ?? DateTime.now())
                      .toLocal();
              _checkOutDateTime = checkOutTime;
            }

            // Set location labels based on distance from office
            if (data.checkIn?.location != null) {
              final lat = (data.checkIn!.location!['latitude'] as num)
                  .toDouble();
              final lng = (data.checkIn!.location!['longitude'] as num)
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
            if (data.checkOut?.location != null) {
              final lat = (data.checkOut!.location!['latitude'] as num)
                  .toDouble();
              final lng = (data.checkOut!.location!['longitude'] as num)
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

            // Calculate worked duration
            if (_isCheckedIn && _checkInDateTime != null) {
              _workedDuration = DateTime.now().difference(_checkInDateTime!);
            } else if (_checkOutDateTime != null && _checkInDateTime != null) {
              _workedDuration = _checkOutDateTime!.difference(
                _checkInDateTime!,
              );
            }
          } catch (e) {
            print('Error parsing attendance data: $e');
          }
        });
      }
    } catch (e) {
      print('Error fetching today attendance: $e');
      // Don't show error to user, just use default values
    }
  }

  // Fetch User Profile
  Future<void> _fetchUserProfile() async {
    try {
      if (_token == null) {
        final token = await TokenStorageService().getToken();
        if (token != null) {
          setState(() => _token = token);
        }
      }
      
      if (_token != null) {
        final profileService = ProfileService();
        final userProfile = await profileService.fetchProfile(_token!);
        if (userProfile != null && mounted) {
          setState(() => _user = userProfile);
        }
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      // Silently continue - user object is optional for display
    }
  }

  // Fetch Attendance Summary
  Future<void> _fetchAttendanceSummary() async {
    setState(() {
      _isLoadingSummary = true;
    });

    try {
      final token = await TokenStorageService().getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final summary = await AttendanceService.getAttendanceSummary(
        token: token,
        month: _focusedDay.month,
        year: _focusedDay.year,
      );

      if (mounted) {
        setState(() {
          _summaryData = summary.data;
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      print('Error fetching attendance summary: $e');
      if (mounted) {
        setState(() {
          _isLoadingSummary = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load attendance summary: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fetch Attendance History for Calendar
  Future<void> _fetchAttendanceHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final token = await TokenStorageService().getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final history = await AttendanceService.getAttendanceHistory(
        token: token,
        month: _focusedDay.month,
        year: _focusedDay.year,
      );

      print(
        '📅 Attendance history response: success=${history.success}, count=${history.data.length}',
      );

      if (mounted) {
        final Map<DateTime, AttendanceStatus> attendanceMap = {};

        if (history.success && history.data.isNotEmpty) {
          for (var record in history.data) {
            // Normalize the date to UTC midnight to avoid timezone issues
            final recordDate = record.date;
            final normalizedDate = DateTime.utc(
              recordDate.year,
              recordDate.month,
              recordDate.day,
            );

            print('📅 Record: date=$normalizedDate, status=${record.status}');

            // Map backend status to enum
            AttendanceStatus status;
            switch (record.status.toLowerCase().trim()) {
              case 'present':
                status = AttendanceStatus.present;
                break;
              case 'late':
                status = AttendanceStatus.late;
                break;
              case 'absent':
                status = AttendanceStatus.absent;
                break;
              case 'halfday':
              case 'half_day':
              case 'half day':
              case 'half-day':
                status = AttendanceStatus.halfDay;
                break;
              case 'leave':
              case 'on leave':
                status = AttendanceStatus.leave;
                break;
              default:
                print('⚠️ Unknown status: ${record.status}');
                status = AttendanceStatus.absent;
            }

            attendanceMap[normalizedDate] = status;
          }
          print(
            '📅 Total attendance data loaded: ${attendanceMap.length} entries',
          );
        } else if (!history.success) {
          print('⚠️ API returned success=false');
        } else {
          print('⚠️ API returned empty data');
        }

        setState(() {
          _attendanceData = attendanceMap;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching attendance history: $e');
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  // Fetch latest 5 attendance records
  Future<void> _fetchLatestRecords() async {
    setState(() {
      _isLoadingRecords = true;
    });

    try {
      final token = await TokenStorageService().getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      // Calculate start and end dates for the current month
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      final recordsResponse = await AttendanceService.getAttendanceRecords(
        token: token,
        startDate: startDateStr,
        endDate: endDateStr,
        month: now.month,
        year: now.year,
        status: null,
      );

      if (mounted) {
        setState(() {
          // Sort by date descending and take first 5
          final sortedRecords = List<records.AttendanceRecord>.from(
            recordsResponse.data,
          )..sort((a, b) => b.date.compareTo(a.date));
          _latestRecords = sortedRecords.take(5).toList();
          _isLoadingRecords = false;
        });
      }
    } catch (e) {
      print('Error fetching latest records: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecords = false;
        });
      }
    }
  }

  // Handle check-in result from camera (photo + location, face already verified)
  Future<void> _handleCheckInResult(dynamic result) async {
    if (result is! Map<String, dynamic>) return;

    final File? photoFile = result['photoFile'] as File?;
    final double lat = (result['latitude'] as num?)?.toDouble() ?? 26.816224;
    final double lng = (result['longitude'] as num?)?.toDouble() ?? 75.845444;
    final String address = result['address'] as String? ?? 'Main Building';

    if (photoFile == null) return;

    // Step 2: Show BOD (Beginning of Day) — mandatory, matches website flow
    final bodSubmitted = await _showBODBottomSheet();
    if (bodSubmitted != true) {
      // User dismissed BOD — cancel check-in
      return;
    }
    if (!mounted) return;

    // Step 3: Call check-in API with photo + location
    try {
      final token = _token ?? await TokenStorageService().getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication error. Please login again.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      final response = await AttendanceService.checkIn(
        token: token,
        photoFile: photoFile,
        latitude: lat,
        longitude: lng,
      );

      final data = response.data;
      final faceVerification = response.faceVerification;

      if (mounted) {
        setState(() {
          _isCheckedIn = true;
          _checkInDateTime = data.checkIn.time;
          _checkOutDateTime = null;
          _checkInLocation = address;
          _workedDuration = DateTime.now().difference(data.checkIn.time);
        });

        final scoreLabel = faceVerification != null
            ? ' · Face match ${faceVerification.similarityScore}%'
            : '';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Checked In Successfully!$scoreLabel',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        // Pop back to dashboard if pushed there, otherwise refresh in-place
        if (widget.initialAction != null) {
          if (mounted) Navigator.pop(context, 'checkedIn');
        } else {
          // Opened directly via nav — stay on screen, refresh all data
          await _fetchTodayAttendance();
          await _fetchAttendanceSummary();
          await _fetchAttendanceHistory();
          await _fetchLatestRecords();
        }
      }
    } on CheckInNotAllowedException catch (e) {
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.event_busy, color: Colors.orangeAccent, size: 48),
            title: const Text('Check-In Not Allowed',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            content: Text(e.message,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: Colors.orangeAccent)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errMsg = e.toString().replaceAll('Exception:', '').trim();
        if (errMsg.toLowerCase().contains('already checked in')) {
          await _fetchTodayAttendance();
          if (mounted) Navigator.pop(context, 'checkedIn');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Check-in failed: $errMsg'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  // Show BOD (Beginning of Day) task planning sheet — returns true if user submitted tasks
  Future<bool?> _showBODBottomSheet() async {
    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const BODBottomSheet(),
    );
  }

  // Show EOD (End of Day) review sheet — returns true if user confirms checkout
  Future<bool> _showEODBottomSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EODBottomSheet(),
    );
    return result == true;
  }

  // Toggle check-in/check-out
  void _toggleCheckIn() async {
    if (_isCheckedIn) {
      final confirmed = await _showEODBottomSheet();
      if (confirmed && mounted) {
        _handleCheckOut();
      }
    } else {
      // Check location before starting check-in
      await _checkLocationAndStartCheckIn();
    }
  }

  // Check location services before starting check-in (FAST)
  Future<void> _checkLocationAndStartCheckIn() async {
    try {
      print('\n🔍 [CHECK-IN DEBUG] === Quick Location Check ===');

      // Quick location service check
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Quick permission check
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        if (mounted) {
          final shouldRequest = await LocationPermissionDialog.show(
            context,
            isPermanentlyDenied: false,
          );

          if (shouldRequest != true) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location permission required'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            return;
          }

          permission = await Geolocator.requestPermission();
        }
      } else if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          await LocationPermissionDialog.show(
            context,
            isPermanentlyDenied: true,
          );
        }
        return;
      }

      // Allow check-in if permission granted — navigate to CameraScreen (face verification)
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        if (!mounted) return;

        // Camera: capture selfie + verify face (no API call yet)
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CameraScreen()),
        );
        if (!mounted) return;
        if (result != null) {
          // After face verified: show BOD then call check-in API (see _handleCheckInResult)
          await _handleCheckInResult(result);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [CHECK-IN] Location error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to access location'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleCheckOut() async {
    print('\n🔍 [CHECK-OUT DEBUG] === Starting Quick Check-Out Process ===');

    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication error. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

    try {
      // Quick location service check
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
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

      // Quick permission check
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          final shouldRequest = await LocationPermissionDialog.show(
            context,
            isPermanentlyDenied: permission == LocationPermission.deniedForever,
          );

          if (shouldRequest == null || shouldRequest == false) return;

          if (permission == LocationPermission.deniedForever) return;

          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever)
            return;
        }
      }

      // ✅ SHOW SUCCESS IMMEDIATELY - Don't wait for location
      if (mounted) {
        setState(() {
          _isCheckedIn = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-out successful!'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Get location with TIMEOUT (don't wait forever)
      print('📡 [CHECK-OUT] Fetching location (FAST)...');
      final locationFuture = Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 5),
      );

      Position? position;
      try {
        position = await locationFuture;
        print('✅ [CHECK-OUT] Location captured!');
      } catch (e) {
        print('⚠️ [CHECK-OUT] Location timeout/error (using fallback): $e');
        position = null;
      }

      // Call check-out API in background (don't wait)
      _doCheckOutRequest(position);
    } catch (e) {
      print('Check-out error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception:', '').trim()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Background check-out API call (doesn't block UI)
  Future<void> _doCheckOutRequest(Position? position) async {
    try {
      double lat = position?.latitude ?? 26.816224;
      double lng = position?.longitude ?? 75.845444;

      final response = await AttendanceService.checkOut(
        token: _token!,
        latitude: lat,
        longitude: lng,
      );

      print('✅ [CHECK-OUT] API completed');

      if (mounted) {
        setState(() {
          _checkOutDateTime = response.data.checkOut!.time;

          if (response.data.checkOut!.location != null) {
            final double distMeters = Geolocator.distanceBetween(
              response.data.checkOut!.location!.latitude,
              response.data.checkOut!.location!.longitude,
              26.816224,
              75.845444,
            );
            _checkOutLocation = distMeters <= 100
                ? 'Main Building'
                : 'Outside Building';
          }

          _workedDuration = response.data.checkOut!.time.difference(
            response.data.checkIn.time,
          );
        });

        // Test mode: reset to fresh state after 2 s so user can check-in again
        if (_testModeEnabled) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _checkInDateTime = null;
                _checkOutDateTime = null;
                _checkInLocation = null;
                _checkOutLocation = null;
                _workedDuration = Duration.zero;
              });
            }
          });
        }
      }
    } catch (e) {
      print('❌ [CHECK-OUT] Background API error: $e');
    }
  }

  // Helper to find status for a specific day
  AttendanceStatus? _getStatus(DateTime day) {
    // Normalize the day to UTC midnight for consistent comparison
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);

    // Debug print
    if (_attendanceData.isNotEmpty) {
      print(
        '🔍 Looking for $normalizedDay in ${_attendanceData.keys.toList()}',
      );
    }

    for (var entry in _attendanceData.entries) {
      if (isSameDay(entry.key, normalizedDay)) {
        print('✅ Found status: ${entry.value} for $normalizedDay');
        return entry.value;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Attendance",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        // 
        // actions: [
        //   Tooltip(
        //     message: 'API Tests',
        //     child: IconButton(
        //       icon: const Icon(
        //         Icons.api_outlined,
        //         color: Colors.pinkAccent,
        //         size: 22,
        //       ),
        //       onPressed: () {
        //         Navigator.push(
        //           context,
        //           MaterialPageRoute(
        //             builder: (_) => const AttendanceApiTestScreen(),
        //           ),
        //         );
        //       },
        //     ),
        //   ),
        // ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hPad = constraints.maxWidth < 360 ? 14.0 : 20.0;
            return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Status Card
              _buildHeroStatusCard(),

              const SizedBox(height: 32),

              // 2. Stats Grid
              const Text(
                "Overview",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatsGrid(),

              const SizedBox(height: 32),

              // 3. NEW CALENDAR SECTION
              const Text(
                "Monthly Report",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildCalendarCard(), // <--- NEW WIDGET ADDED HERE

              const SizedBox(height: 32),

              // 4. Daily Attendance Records
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Daily Attendance Records",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AttendanceHistoryScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "View All",
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAttendanceRecordsTable(),

              const SizedBox(height: 32),

              // 5. My Edit Requests
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Edit Requests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditRequestsScreen(),
                      ),
                    ),
                    child: Text(
                      'View All',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildEditRequestsPreview(),
            ],
          ),
        );
          },
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeroStatusCard() {
    // Calculate work hours as double
    double workHours = _workedDuration.inMinutes / 60.0;

    return WelcomeCard(
      isCheckedIn: _isCheckedIn,
      checkInTime: _checkInDateTime,
      checkOutTime: _checkOutDateTime,
      checkInLocation: _checkInLocation,
      checkOutLocation: _checkOutLocation,
      workHours: workHours,
      onCheckInToggle: _toggleCheckIn,
      user: _user,
    );
  }

  // Old custom card builders removed - now using WelcomeCard widget for consistency with dashboard

  Widget _buildStatsGrid() {
    if (_isLoadingSummary) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final present = _summaryData?.present.toString() ?? '0';
    final late = _summaryData?.late.toString() ?? '0';
    final absent = _summaryData?.absent.toString() ?? '0';
    final halfDay = _summaryData?.halfDay.toString() ?? '0';
    // final wfh = _summaryData?.wfh.toString() ?? '0';
    final leaves = _summaryData?.leaves.toString() ?? '0';
    // final totalWorkHours = _summaryData?.totalWorkHours ?? 0.0;
    // final averageWorkHours = _summaryData?.averageWorkHours ?? '0h 0m';

    // Format total work hours
    // final hours = totalWorkHours.floor();
    // final minutes = ((totalWorkHours - hours) * 60).round();
    // final totalWorkHoursStr = '${hours}h ${minutes}m';

    return Column(
      children: [
        // First Row: Present, Late
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Present",
                present,
                Icons.check_circle,
                Colors.greenAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                "Late",
                late,
                Icons.access_time,
                Colors.orangeAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Second Row: Absent, Half Day
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Absent",
                absent,
                Icons.cancel,
                Colors.redAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                "Half Day",
                halfDay,
                Icons.timelapse,
                Colors.amberAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Leaves",
                leaves,
                Icons.event_busy_outlined,
                Colors.purpleAccent,
              ),
            ),
        //     const SizedBox(width: 12),
        //     Expanded(
        //       child: _buildStatCard(
        //         "Total Days",
        //         _summaryData?.totalDays.toString() ?? '0',
        //         Icons.calendar_today,
        //         Colors.blueAccent,
        //       ),
            // ),
          ],
        ),
        // const SizedBox(height: 16),
        // Summary Cards
      //   Row(
      //     children: [
      //       Expanded(
      //         child: Container(
      //           padding: const EdgeInsets.all(16),
      //           decoration: BoxDecoration(
      //             color: const Color(0xFF141414),
      //             borderRadius: BorderRadius.circular(16),
      //             border: Border.all(color: Colors.white.withOpacity(0.05)),
      //           ),
      //           child: Column(
      //             crossAxisAlignment: CrossAxisAlignment.start,
      //             children: [
      //               Row(
      //                 children: [
      //                   Icon(
      //                     Icons.access_time_filled,
      //                     color: Colors.cyanAccent,
      //                     size: 20,
      //                   ),
      //                   const SizedBox(width: 8),
      //                   Flexible(
      //                     child: Text(
      //                       'Total Work Hours',
      //                       style: TextStyle(
      //                         color: Colors.grey[500],
      //                         fontSize: 12,
      //                       ),
      //                       overflow: TextOverflow.ellipsis,
      //                     ),
      //                   ),
      //                 ],
      //               ),
      //               const SizedBox(height: 8),
      //               Text(
      //                 totalWorkHoursStr,
      //                 style: const TextStyle(
      //                   fontSize: 20,
      //                   fontWeight: FontWeight.bold,
      //                   color: Colors.white,
      //                 ),
      //               ),
      //             ],
      //           ),
      //         ),
      //       ),
      //       const SizedBox(width: 12),
      //       Expanded(
      //         child: Container(
      //           padding: const EdgeInsets.all(16),
      //           decoration: BoxDecoration(
      //             color: const Color(0xFF141414),
      //             borderRadius: BorderRadius.circular(16),
      //             border: Border.all(color: Colors.white.withOpacity(0.05)),
      //           ),
      //           child: Column(
      //             crossAxisAlignment: CrossAxisAlignment.start,
      //             children: [
      //               Row(
      //                 children: [
      //                   Icon(
      //                     Icons.trending_up,
      //                     color: Colors.greenAccent,
      //                     size: 20,
      //                   ),
      //                   const SizedBox(width: 8),
      //                   Flexible(
      //                     child: Text(
      //                       'Avg. Work Hours',
      //                       style: TextStyle(
      //                         color: Colors.grey[500],
      //                         fontSize: 12,
      //                       ),
      //                       overflow: TextOverflow.ellipsis,
      //                     ),
      //                   ),
      //                 ],
      //               ),
      //               const SizedBox(height: 8),
      //               Text(
      //                 averageWorkHours,
      //                 style: const TextStyle(
      //                   fontSize: 20,
      //                   fontWeight: FontWeight.bold,
      //                   color: Colors.white,
      //                 ),
      //               ),
      //             ],
      //           ),
      //         ),
      //       ),
      //     ],
      //   ),
      ],
    );
  }

  // --- NEW: CALENDAR WIDGET ---
  Widget _buildCalendarCard() {
    // Style constants for the calendar
    final kGreenBg = const Color(0xFF1B3A24);
    final kGreenText = const Color(0xFF4CAF50);
    final kRedBg = const Color(0xFF3A1B1B);
    final kRedText = const Color(0xFFE57373);
    final kOrangeBg = const Color(0xFF3E2723);
    final kOrangeText = Colors.orangeAccent;
    final kAmberBg = const Color(0xFF3E3520);
    final kAmberText = Colors.amberAccent;
    final kPurpleBg = const Color(0xFF2A1A3E);
    final kPurpleText = const Color(0xFFCE93D8);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Calendar
          _isLoadingHistory
              ? const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : TableCalendar(
                  firstDay: DateTime.utc(2020, 10, 16),
                  lastDay: DateTime.utc(2030, 3, 14),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

                  // Minimal Header Styling
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: Colors.white70,
                      size: 20,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),

                  // Grid Styling
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.grey, fontSize: 12),
                    weekendStyle: TextStyle(color: Colors.grey, fontSize: 12),
                  ),

                  // Custom Cell Builders
                  calendarBuilders: CalendarBuilders(
                    // 1. Prioritized Builder: Checks for status first
                    prioritizedBuilder: (context, day, focusedDay) {
                      AttendanceStatus? status = _getStatus(day);
                      bool isSelected = isSameDay(day, _selectedDay);
                      bool isToday = isSameDay(day, DateTime.now());

                      // Handle days with attendance status
                      if (status != null) {
                        Color bgColor;
                        Color textColor;
                        IconData icon;

                        switch (status) {
                          case AttendanceStatus.present:
                            bgColor = kGreenBg;
                            textColor = kGreenText;
                            icon = Icons.check;
                            break;
                          case AttendanceStatus.absent:
                            bgColor = kRedBg;
                            textColor = kRedText;
                            icon = Icons.close;
                            break;
                          case AttendanceStatus.late:
                            bgColor = kOrangeBg;
                            textColor = kOrangeText;
                            icon = Icons.access_time;
                            break;
                          case AttendanceStatus.halfDay:
                            bgColor = kAmberBg;
                            textColor = kAmberText;
                            icon = Icons.timelapse;
                            break;
                          case AttendanceStatus.leave:
                            bgColor = kPurpleBg;
                            textColor = kPurpleText;
                            icon = Icons.event_busy_outlined;
                            break;
                        }

                        return Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  )
                                : (isToday
                                      ? Border.all(
                                          color: Colors.blueAccent,
                                          width: 2,
                                        )
                                      : null),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Icon(icon, size: 12, color: textColor),
                            ],
                          ),
                        );
                      }

                      // If no status, let other builders handle it
                      return null;
                    },

                    // 2. Default Day (Empty)
                    defaultBuilder: (context, day, focusedDay) {
                      return Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    },

                    // 3. Today (Highlighted) - Only for days without attendance status
                    todayBuilder: (context, day, focusedDay) {
                      return Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blueAccent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },

                    // 4. Selected Day - Only for days without attendance status
                    selectedBuilder: (context, day, focusedDay) {
                      return Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                    // Fetch attendance history for the new month
                    _fetchAttendanceHistory();
                    // Also update the summary
                    _fetchAttendanceSummary();
                  },
                ),

          // Legend
          // const SizedBox(height: 16),
          // const Divider(color: Colors.white10, height: 1),
          // const SizedBox(height: 12),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceAround,
          //   children: [
          //     _buildLegendItem(
          //       Icons.check_circle_outline,
          //       const Color.fromARGB(255, 233, 241, 233),
          //       'Present',
          //     ),
          //     _buildLegendItem(Icons.close, const Color(0xFFE57373), 'Absent'),
          //     _buildLegendItem(Icons.access_time, Colors.orangeAccent, 'Late'),
          //   ],
          // ),
          // const SizedBox(height: 8),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceAround,
          //   children: [
          //     _buildLegendItem(Icons.timelapse, Colors.amberAccent, 'Half Day'),
          //     _buildLegendItem(
          //       Icons.event_busy_outlined,
          //       const Color(0xFFCE93D8),
          //       'Leave',
          //     ),
          //     const SizedBox(width: 60), // spacer for alignment
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecordsTable() {
    if (_isLoadingRecords) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_latestRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 12),
              Text(
                'No attendance records yet',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Return individual cards with spacing
    return Column(
      children: _latestRecords.map<Widget>((record) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildAttendanceRecordCard(record),
        );
      }).toList(),
    );
  }

  String _statusLabel(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      case 'late':
        return 'Late';
      case 'leave':
      case 'on leave':
        return 'Leave';
      case 'halfday':
      case 'half_day':
      case 'half day':
      case 'half-day':
        return 'Half Day';
      default:
        return raw.isNotEmpty ? raw[0].toUpperCase() + raw.substring(1) : raw;
    }
  }

  IconData _statusIcon(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'present':
        return Icons.check_circle_outline;
      case 'absent':
        return Icons.cancel_outlined;
      case 'late':
        return Icons.access_time;
      case 'leave':
      case 'on leave':
        return Icons.event_busy_outlined;
      case 'halfday':
      case 'half_day':
      case 'half day':
      case 'half-day':
        return Icons.timelapse;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildAttendanceRecordCard(records.AttendanceRecord record) {
    final status = _statusLabel(record.status);

    // Format times
    final checkInTime = DateFormat(
      'hh:mm a',
    ).format(record.checkIn.time.toLocal());
    final checkOutTime = record.checkOut != null
        ? DateFormat('hh:mm a').format(record.checkOut!.time.toLocal())
        : '-';

    // Calculate duration
    String duration = '-';
    if (record.checkOut != null) {
      final hours = record.workHours.floor();
      final minutes = ((record.workHours - hours) * 60).round();
      duration = '${hours}h ${minutes}m';
    }

    // Check if has photo
    final hasPhoto = record.checkIn.photo.url.isNotEmpty;

    // Get location coordinates
    final hasLocation = record.checkIn.location != null;
    final latitude = hasLocation ? record.checkIn.location!.latitude : 0.0;
    final longitude = hasLocation ? record.checkIn.location!.longitude : 0.0;

    // Format date
    final dateStr = DateFormat('MMM d, y').format(record.date);

    Color statusColor;
    Color statusBgColor;

    switch (status.toLowerCase()) {
      case 'present':
        statusColor = const Color(0xFF4CAF50);
        statusBgColor = const Color(0xFF1B3A24);
        break;
      case 'absent':
        statusColor = const Color(0xFFE57373);
        statusBgColor = const Color(0xFF3A1B1B);
        break;
      case 'late':
        statusColor = Colors.orangeAccent;
        statusBgColor = const Color(0xFF3E2723);
        break;
      case 'leave':
        statusColor = const Color(0xFFCE93D8);
        statusBgColor = const Color(0xFF2A1A3E);
        break;
      case 'half day':
        statusColor = Colors.amberAccent;
        statusBgColor = const Color(0xFF3E3520);
        break;
      default:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.withOpacity(0.15);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  // Status Badge
                  if (status != '-')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _statusIcon(record.status),
                            color: statusColor,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Edit Icon
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showEditRequestDialog(
                      dateStr,
                      checkInTime,
                      checkOutTime,
                      record.id,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFF1A1A1A), height: 1),
          const SizedBox(height: 12),

          // Time Details
          Row(
            children: [
              Expanded(
                child: _buildTimeInfo(
                  'Check In',
                  checkInTime,
                  Icons.login,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeInfo(
                  'Check Out',
                  checkOutTime,
                  Icons.logout,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeInfo(
                  'Duration',
                  duration,
                  Icons.access_time,
                  Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1A1A1A), height: 1),
          const SizedBox(height: 12),

          // Location and Photo View Buttons
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: hasLocation
                      ? () => _openGoogleMaps(latitude, longitude)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.blue.shade300,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'View',
                          style: TextStyle(
                            color: Colors.blue.shade300,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: hasPhoto
                      ? () => _showPhotoDialog(record.checkIn.photo.url)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: hasPhoto
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasPhoto
                            ? Colors.green.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasPhoto ? Icons.image : Icons.image_not_supported,
                          size: 16,
                          color: hasPhoto ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasPhoto ? 'View' : 'No Photo',
                          style: TextStyle(
                            color: hasPhoto ? Colors.green : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Show edit request dialog
  void _showEditRequestDialog(
    String date,
    String checkIn,
    String checkOut,
    String attendanceId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AttendanceEditRequestDialog(
        date: date,
        checkIn: checkIn,
        checkOut: checkOut,
        attendanceId: attendanceId,
        onSuccess: () {
          _fetchAttendanceHistory();
          _fetchAttendanceSummary();
          _fetchLatestRecords();
          _fetchEditRequestsPreview();
        },
      ),
    );
  }

  // Fetch edit requests preview (max 3)
  Future<void> _fetchEditRequestsPreview() async {
    setState(() => _isLoadingEditRequests = true);
    try {
      final token = await TokenStorageService().getToken();
      if (token == null) throw Exception('No token');
      final result = await AttendanceService.getEditRequests(token: token);
      if (mounted) {
        setState(() {
          _editRequests = result.data.take(3).toList();
          _isLoadingEditRequests = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingEditRequests = false);
    }
  }

  // Build edit requests preview widget
  Widget _buildEditRequestsPreview() {
    if (_isLoadingEditRequests) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_editRequests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Center(
          child: Text(
            'No edit requests submitted yet',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: _editRequests.map((req) {
        final dateStr = DateFormat('MMM d, yyyy').format(req.date.toLocal());
        final checkInStr = DateFormat(
          'hh:mm a',
        ).format(req.requestedCheckIn.toLocal());
        final checkOutStr = DateFormat(
          'hh:mm a',
        ).format(req.requestedCheckOut.toLocal());
        final statusColor = _editRequestStatusColor(req.status);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_calendar_outlined,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$checkInStr  →  $checkOutStr',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  req.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _editRequestStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  // Open Google Maps with coordinates
  Future<void> _openGoogleMaps(double latitude, double longitude) async {
    // Try multiple methods to open maps

    // Method 1: Use geo: scheme (native Android maps)
    final geoUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');

    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      print('Geo URI failed: $e');
    }

    // Method 2: Use Google Maps URL
    final googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    try {
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      print('Google Maps URL failed: $e');
    }

    // Method 3: Try direct Google Maps app link
    final mapsAppUri = Uri.parse(
      'https://maps.google.com/?q=$latitude,$longitude',
    );

    try {
      if (await canLaunchUrl(mapsAppUri)) {
        await launchUrl(mapsAppUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      print('Maps app URL failed: $e');
    }

    // If all methods fail, show error
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open Google Maps. Please install Google Maps app.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Show photo in full screen dialog
  void _showPhotoDialog(String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.grey[300]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------

// --- OLD DIALOG REMOVED - Now using separate widget from attendance_edit_request_dialog.dart ---

// ------------------------------------------
// FACE SCAN SCREEN (Unchanged)
// ------------------------------------------
class FaceScanScreen extends StatefulWidget {
  const FaceScanScreen({super.key});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.pop(context, true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            color: Colors.grey[900], // Placeholder for camera
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Scanning...",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: Colors.greenAccent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
