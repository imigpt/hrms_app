import 'dart:async';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'camera_screen.dart';
import 'attendance_history_screen.dart';
import '../services/attendance_service.dart';
import '../services/token_storage_service.dart';
import '../models/attendance_summary_model.dart';
import '../models/today_attendance_model.dart' as today;
import '../models/attendance_checkin_model.dart';
import '../models/attendance_history_model.dart' as history;
import '../models/attendance_records_model.dart' as records;
import '../models/attendance_edit_request_model.dart';
import '../widgets/welcome_card.dart';
import '../widgets/location_permission_dialog.dart';
import '../widgets/attendance_edit_request_dialog.dart';
import 'edit_requests_screen.dart';
// import 'attendance_api_test_screen.dart';

// 1. Define Status Enum
enum AttendanceStatus { present, absent, late, halfDay }

/// [initialAction] can be 'checkIn' or 'checkOut' to immediately trigger
/// the respective flow when the screen opens from the dashboard.
class AttendanceScreen extends StatefulWidget {
  final String? initialAction;

  const AttendanceScreen({super.key, this.initialAction});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // --- Existing State ---
  bool _isCheckedIn = false;
  String _checkInTime = "--:--";
  String _checkOutTime = "--:--";
  bool _showPhotoUI = false;

  // --- DateTime State for Welcome Card ---
  DateTime? _checkInDateTime;
  DateTime? _checkOutDateTime;
  Duration _workedDuration = const Duration(hours: 0, minutes: 0);
  today.AttendanceData? _todayAttendanceData;
  String? _token;

  // --- Location State ---
  bool _isLoadingLocation = false;
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
    
    // Handle initial action from dashboard navigation immediately
    if (widget.initialAction == 'checkIn') {
      // Directly show photo UI for check-in from dashboard
      _showPhotoUI = true;
    }
    
    _fetchTodayAttendance();
    _fetchAttendanceSummary();
    _fetchAttendanceHistory();
    _fetchLatestRecords();
    _fetchEditRequestsPreview();

    // Handle location permission check in background after UI is rendered
    if (widget.initialAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (widget.initialAction == 'checkIn') {
          await _checkLocationAndStartCheckIn();
        } else if (widget.initialAction == 'checkOut') {
          await _handleCheckOut();
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
          _isCheckedIn = data.hasCheckedIn && !data.hasCheckedOut;
          
          // Parse check-in and check-out times from AttendanceCheckPoint objects
          try {
            if (data.checkIn != null && data.checkIn!.time != null) {
              final checkInTime = DateTime.tryParse(data.checkIn!.time!) ?? DateTime.now();
              _checkInDateTime = checkInTime;
              _checkInTime = _formatTime(checkInTime);
            }
            
            if (data.checkOut != null && data.checkOut!.time != null) {
              final checkOutTime = DateTime.tryParse(data.checkOut!.time!) ?? DateTime.now();
              _checkOutDateTime = checkOutTime;
              _checkOutTime = _formatTime(checkOutTime);
            }
            
            // Set location addresses if available
            if (data.checkIn?.location != null) {
              final lat = data.checkIn!.location!['latitude'] ?? 0.0;
              final lng = data.checkIn!.location!['longitude'] ?? 0.0;
              _checkInLocation = '${(lat as num).toDouble().toStringAsFixed(6)}, ${(lng as num).toDouble().toStringAsFixed(6)}';
            }
            if (data.checkOut?.location != null) {
              final lat = data.checkOut!.location!['latitude'] ?? 0.0;
              final lng = data.checkOut!.location!['longitude'] ?? 0.0;
              _checkOutLocation = '${(lat as num).toDouble().toStringAsFixed(6)}, ${(lng as num).toDouble().toStringAsFixed(6)}';
            }
            
            // Calculate worked duration
            if (_isCheckedIn && _checkInDateTime != null) {
              _workedDuration = DateTime.now().difference(_checkInDateTime!);
            } else if (_checkOutDateTime != null && _checkInDateTime != null) {
              _workedDuration = _checkOutDateTime!.difference(_checkInDateTime!);
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

      print('📅 Attendance history response: success=${history.success}, count=${history.data.length}');
      
      if (mounted) {
        final Map<DateTime, AttendanceStatus> attendanceMap = {};
        
        if (history.success && history.data.isNotEmpty) {
          for (var record in history.data) {
            // Normalize the date to UTC midnight to avoid timezone issues
            final recordDate = record.date;
            final normalizedDate = DateTime.utc(recordDate.year, recordDate.month, recordDate.day);
            
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
                status = AttendanceStatus.halfDay;
                break;
              default:
                print('⚠️ Unknown status: ${record.status}');
                status = AttendanceStatus.absent;
            }
            
            attendanceMap[normalizedDate] = status;
          }
          print('📅 Total attendance data loaded: ${attendanceMap.length} entries');
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
          final sortedRecords = List<records.AttendanceRecord>.from(recordsResponse.data)
            ..sort((a, b) => b.date.compareTo(a.date));
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

  // --- Face Scan Logic (Unchanged) ---
  Future<void> _triggerFaceScan(bool isCheckingIn) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FaceScanScreen()),
    );

    if (result == true) {
      setState(() {
        if (isCheckingIn) {
          _isCheckedIn = true;
          _checkInTime = _formatTime(DateTime.now());
          _checkOutTime = "--:--";
        } else {
          _isCheckedIn = false;
          _checkOutTime = _formatTime(DateTime.now());
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCheckingIn ? "Checked In Successfully!" : "Checked Out Successfully!"),
            backgroundColor: isCheckingIn ? Colors.green : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _startPhotoCheckIn() async {
    setState(() {
      _showPhotoUI = true;
    });

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );

    if (!mounted) return;

    if (result != null) {
      _handleCheckInResult(result);
    } else {
      setState(() {
        _showPhotoUI = false;
      });
    }
  }

  // Handle check-in result from camera
  void _handleCheckInResult(dynamic result) async {
    String? checkInAddress;
    
    // Extract address if result is a Map with both data and address
    if (result is Map<String, dynamic> && result.containsKey('checkInAddress')) {
      checkInAddress = result['checkInAddress'];
      result = result['attendanceData'];
    }
    
    if (result != null && result is AttendanceData) {
      setState(() {
        _isCheckedIn = true;
        _todayAttendanceData = result;
        _checkInDateTime = result.checkIn.time;
        _checkInTime = _formatTime(result.checkIn.time);
        _checkOutTime = "--:--";
        _checkOutDateTime = null;
        _showPhotoUI = false;
        
        // Use human-readable address if provided, otherwise fall back to coordinates
        if (checkInAddress != null && checkInAddress.isNotEmpty) {
          _checkInLocation = checkInAddress;
        } else if (result.checkIn.location != null) {
          _checkInLocation = '${result.checkIn.location!.latitude.toStringAsFixed(6)}, ${result.checkIn.location!.longitude.toStringAsFixed(6)}';
        }
        
        _workedDuration = DateTime.now().difference(result.checkIn.time);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Checked In Successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (result == 'refresh') {
      // User was already checked in on backend - reload attendance data
      setState(() {
        _showPhotoUI = false;
      });
      await _fetchTodayAttendance();
    } else {
      setState(() {
        _showPhotoUI = false;
      });
    }
  }

  // Toggle check-in/check-out
  void _toggleCheckIn() async {
    if (_isCheckedIn) {
      _handleCheckOut();
    } else {
      // Check location before starting check-in
      await _checkLocationAndStartCheckIn();
    }
  }

  // Check location services before starting check-in
  Future<void> _checkLocationAndStartCheckIn() async {
    try {
      print('\n🔍 [CHECK-IN DEBUG] === Starting Check-In Permission Check ===');
      
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📍 [CHECK-IN] Location service enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _showPhotoUI = false; // Hide photo UI if location services disabled
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services in device settings to mark attendance'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Check current location permission
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 [CHECK-IN] Initial permission: $permission');
      
      // Handle permission states
      if (permission == LocationPermission.denied) {
        // Show custom dialog to explain why we need location
        if (mounted) {
          final shouldRequest = await LocationPermissionDialog.show(context, isPermanentlyDenied: false);
          print('📍 [CHECK-IN] Dialog result: $shouldRequest');
          
          if (shouldRequest != true) {
            print('📍 [CHECK-IN] User cancelled or declined');
            if (mounted) {
              setState(() {
                _showPhotoUI = false; // Hide photo UI if user declines
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location permission is required to mark attendance'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return;
          }
          
          // Request permission from system
          permission = await Geolocator.requestPermission();
          print('📍 [CHECK-IN] Permission after request: $permission');
        }
      } else if (permission == LocationPermission.deniedForever) {
        // Show dialog for permanently denied permission
        if (mounted) {
          setState(() {
            _showPhotoUI = false; // Hide photo UI for permanently denied permission
          });
          await LocationPermissionDialog.show(context, isPermanentlyDenied: true);
        }
        return;
      }

      // Check final permission state
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          // Hide photo UI if permission denied
          setState(() {
            _showPhotoUI = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied. Please enable it in settings to mark attendance.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        print('✅ [CHECK-IN] Location permission granted, photo UI already shown');
        // Photo UI is already shown from initState, just ensure it stays visible
        if (mounted && !_showPhotoUI) {
          setState(() {
            _showPhotoUI = true;
          });
        }
      } else {
        print('❌ [CHECK-IN] Unexpected permission state: $permission');
        if (mounted) {
          setState(() {
            _showPhotoUI = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get location permission. Please try again.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [CHECK-IN] Error in location check: $e');
      if (mounted) {
        setState(() {
          _showPhotoUI = false; // Hide photo UI on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to access location. Please check your device settings and try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleCheckOut() async {
    print('\n🔍 [CHECK-OUT DEBUG] === Starting Check-Out Process ===');
    
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
      print('📡 [CHECK-OUT] Requesting GPS location (HIGH accuracy)...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('✅ [CHECK-OUT] Location captured successfully!');
      print('📍 [CHECK-OUT] Latitude: ${position.latitude}');
      print('📍 [CHECK-OUT] Longitude: ${position.longitude}');
      print('📍 [CHECK-OUT] Accuracy: ${position.accuracy}m');
      print('📍 [CHECK-OUT] Altitude: ${position.altitude}m');
      print('📡 [CHECK-OUT] Calling check-out API with location...');

      // Get human-readable address from coordinates
      String checkOutAddress = 'Address not found';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          
          // Build address string from placemark
          List<String> addressParts = [];
          if (placemark.name != null && placemark.name!.isNotEmpty) {
            addressParts.add(placemark.name!);
          }
          if (placemark.street != null && placemark.street!.isNotEmpty && 
              placemark.street != placemark.name) {
            addressParts.add(placemark.street!);
          }
          if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
            addressParts.add(placemark.subLocality!);
          }
          if (placemark.locality != null && placemark.locality!.isNotEmpty) {
            addressParts.add(placemark.locality!);
          }
          if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
            addressParts.add(placemark.administrativeArea!);
          }
          
          checkOutAddress = addressParts.take(3).join(', '); // Take first 3 parts to keep it concise
          if (checkOutAddress.isEmpty) {
            checkOutAddress = '${placemark.locality ?? 'Unknown'}, ${placemark.administrativeArea ?? 'Unknown'}';
          }
        }
        print('📍 [CHECK-OUT] Address resolved: $checkOutAddress');
      } catch (e) {
        print('⚠️ [CHECK-OUT] Error getting address: $e');
        // Keep default "Address not found" if reverse geocoding fails
      }

      // Call check-out API
      final response = await AttendanceService.checkOut(
        token: _token!,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      print('✅ [CHECK-OUT] Check-out API response received');;
      print('📨 [CHECK-OUT] Response message: ${response.message}');
      print('📍 [CHECK-OUT] Response status: ${response.data.status}');
      if (response.data.checkOut?.location != null) {
        print('📍 [CHECK-OUT] Server stored location: Lat=${response.data.checkOut!.location!.latitude}, Long=${response.data.checkOut!.location!.longitude}');
      } else {
        print('⚠️ [CHECK-OUT] WARNING: Server did not store location!');
      }

      if (mounted) {
        Navigator.pop(context); // Close loading

        setState(() {
          _isCheckedIn = false;
          _checkOutDateTime = response.data.checkOut!.time;
          _checkOutTime = _formatTime(response.data.checkOut!.time);
          
          if (response.data.checkOut!.location != null) {
            // Use human-readable address instead of coordinates
            _checkOutLocation = checkOutAddress;
          }
          
          _workedDuration = response.data.checkOut!.time.difference(response.data.checkIn.time);
        });

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

  // --- Location Permission and Fetching ---
  Future<void> _fetchLocation({required bool isCheckIn}) async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Request location permission
      final status = await Permission.location.request();

      if (status.isGranted) {
        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location services are disabled. Please enable them.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }

        // Fetch current position
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Reverse geocode to get address
        String locationString;
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            // Format address: Street, Locality, State
            List<String> addressParts = [];
            if (place.street != null && place.street!.isNotEmpty) {
              addressParts.add(place.street!);
            }
            if (place.locality != null && place.locality!.isNotEmpty) {
              addressParts.add(place.locality!);
            }
            if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
              addressParts.add(place.administrativeArea!);
            }
            
            locationString = addressParts.isNotEmpty 
                ? addressParts.join(', ') 
                : '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          } else {
            locationString = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          }
        } catch (e) {
          print('Error reverse geocoding: $e');
          // Fallback to coordinates if geocoding fails
          locationString = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        }

        setState(() {
          if (isCheckIn) {
            _checkInLocation = locationString;
          } else {
            _checkOutLocation = locationString;
          }
          _isLoadingLocation = false;
        });
      } else if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  String _formatTime(DateTime t) {
    return DateFormat('hh:mm a').format(t.toLocal());
  }

  // Helper to find status for a specific day
  AttendanceStatus? _getStatus(DateTime day) {
    // Normalize the day to UTC midnight for consistent comparison
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    
    // Debug print
    if (_attendanceData.isNotEmpty) {
      print('🔍 Looking for $normalizedDay in ${_attendanceData.keys.toList()}');
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Attendance",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Status Card
              _buildHeroStatusCard(),

              const SizedBox(height: 32),

              // 2. Stats Grid
              const Text("Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              _buildStatsGrid(),

              const SizedBox(height: 32),

              // 3. NEW CALENDAR SECTION
              const Text("Monthly Report", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              _buildCalendarCard(), // <--- NEW WIDGET ADDED HERE

              const SizedBox(height: 32),

              // 4. Daily Attendance Records
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Daily Attendance Records", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AttendanceHistoryScreen(),
                        ),
                      );
                    }, 
                    child: Text("View All", style: TextStyle(color: Theme.of(context).primaryColor)),
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
                  const Text('My Edit Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditRequestsScreen()),
                    ),
                    child: Text('View All', style: TextStyle(color: Theme.of(context).primaryColor)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildEditRequestsPreview(),
            ],
          ),
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
      showPhotoUI: _showPhotoUI,
      checkInTime: _checkInDateTime,
      checkOutTime: _checkOutDateTime,
      checkInLocation: _checkInLocation,
      checkOutLocation: _checkOutLocation,
      workHours: workHours,
      onCheckInToggle: _toggleCheckIn,
      onCheckInResult: _handleCheckInResult,
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
    final wfh = _summaryData?.wfh.toString() ?? '0';
    final totalWorkHours = _summaryData?.totalWorkHours ?? 0.0;
    final averageWorkHours = _summaryData?.averageWorkHours ?? '0h 0m';
    
    // Format total work hours
    final hours = totalWorkHours.floor();
    final minutes = ((totalWorkHours - hours) * 60).round();
    final totalWorkHoursStr = '${hours}h ${minutes}m';

    return Column(
      children: [
        // First Row: Present, Late
        Row(
          children: [
            Expanded(child: _buildStatCard("Present", present, Icons.check_circle, Colors.greenAccent)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard("Late", late, Icons.access_time, Colors.orangeAccent)),
          ],
        ),
        const SizedBox(height: 16),
        // Second Row: Absent, Half Day
        Row(
          children: [
            Expanded(child: _buildStatCard("Absent", absent, Icons.cancel, Colors.redAccent)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard("Half Day", halfDay, Icons.timelapse, Colors.amberAccent)),
          ],
        ),
        const SizedBox(height: 16),
        // Third Row: WFH, Total Days
        Row(
          children: [
            Expanded(child: _buildStatCard("WFH", wfh, Icons.home, Colors.purpleAccent)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard("Total Days", _summaryData?.totalDays.toString() ?? '0', Icons.calendar_today, Colors.blueAccent)),
          ],
        ),
        const SizedBox(height: 16),
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: Container(
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
                      children: [
                        Icon(Icons.access_time_filled, color: Colors.cyanAccent, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Total Work Hours',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totalWorkHoursStr,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
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
                      children: [
                        Icon(Icons.trending_up, color: Colors.greenAccent, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Avg. Work Hours',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      averageWorkHours,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white70, size: 20),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white70, size: 20),
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
              }
              
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected 
                      ? Border.all(color: Colors.pinkAccent, width: 2)
                      : (isToday ? Border.all(color: Colors.blueAccent, width: 2) : null),
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
             return Center(child: Text('${day.day}', style: const TextStyle(color: Colors.white70)));
          },

          // 3. Today (Highlighted) - Only for days without attendance status
          todayBuilder: (context, day, focusedDay) {
            return Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent, width: 2),
              ),
              child: Center(child: Text('${day.day}', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
            );
          },
          
          // 4. Selected Day - Only for days without attendance status
          selectedBuilder: (context, day, focusedDay) {
            return Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.pinkAccent, width: 2),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text('${day.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(Icons.check, const Color(0xFF4CAF50), 'Present'),
              _buildLegendItem(Icons.access_time, Colors.orangeAccent, 'Late'),
              _buildLegendItem(Icons.close, const Color(0xFFE57373), 'Absent'),
            ],
          ),
        ],
      ),
    );
  }

  // Legend item widget
  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
      ],
    );
  }

  // Helper widget for specific calendar status cells
  Widget _buildCalendarCell(DateTime day, Color bg, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${day.day}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 2),
          Icon(icon, size: 10, color: color),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
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
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
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

  Widget _buildAttendanceRecordCard(records.AttendanceRecord record) {
    final status = record.status.substring(0, 1).toUpperCase() + record.status.substring(1);
    
    // Format times
    final checkInTime = DateFormat('hh:mm a').format(record.checkIn.time.toLocal());
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
        statusColor = Colors.green;
        statusBgColor = Colors.green.withOpacity(0.15);
        break;
      case 'absent':
        statusColor = Colors.red;
        statusBgColor = Colors.red.withOpacity(0.15);
        break;
      case 'late':
        statusColor = Colors.orange;
        statusBgColor = Colors.orange.withOpacity(0.15);
        break;
      case 'leave':
        statusColor = Colors.purple;
        statusBgColor = Colors.purple.withOpacity(0.15);
        break;
      case 'halfday':
      case 'half_day':
        statusColor = Colors.amber;
        statusBgColor = Colors.amber.withOpacity(0.15);
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Edit Icon
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Colors.grey[600], size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showEditRequestDialog(dateStr, checkInTime, checkOutTime, record.id),
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
                child: _buildTimeInfo('Check In', checkInTime, Icons.login, Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeInfo('Check Out', checkOutTime, Icons.logout, Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeInfo('Duration', duration, Icons.access_time, Colors.blue),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                      ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

  Widget _buildTimeInfo(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
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
  void _showEditRequestDialog(String date, String checkIn, String checkOut, String attendanceId) {
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
          child: CircularProgressIndicator(color: Colors.pinkAccent, strokeWidth: 2),
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
        final checkInStr = DateFormat('hh:mm a').format(req.requestedCheckIn.toLocal());
        final checkOutStr = DateFormat('hh:mm a').format(req.requestedCheckOut.toLocal());
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
                child: Icon(Icons.edit_calendar_outlined, color: statusColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
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
      case 'approved': return Colors.greenAccent;
      case 'rejected': return Colors.redAccent;
      default:         return Colors.orangeAccent;
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
    final googleMapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    
    try {
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      print('Google Maps URL failed: $e');
    }
    
    // Method 3: Try direct Google Maps app link
    final mapsAppUri = Uri.parse('https://maps.google.com/?q=$latitude,$longitude');
    
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
          content: Text('Could not open Google Maps. Please install Google Maps app.'),
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
                          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
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

class _FaceScanScreenState extends State<FaceScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    Future.delayed(const Duration(seconds: 3), () {
      if(mounted) Navigator.pop(context, true);
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
                  const Text("Scanning...", style: TextStyle(color: Colors.white, fontSize: 20)),
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