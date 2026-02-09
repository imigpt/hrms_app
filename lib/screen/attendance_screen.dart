import 'dart:async';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'apply_leave_screen.dart';
import 'camera_screen.dart';

// 1. Define Status Enum
enum AttendanceStatus { present, absent, late }

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // --- Existing State ---
  bool _isCheckedIn = false;
  String _checkInTime = "--:--";
  String _checkOutTime = "--:--";
  bool _showPhotoUI = false;

  // --- Calendar State ---
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Dummy Attendance Data for the Calendar
  final Map<DateTime, AttendanceStatus> _attendanceData = {
    DateTime(2026, 2, 6): AttendanceStatus.present,
    DateTime(2026, 2, 7): AttendanceStatus.present,
    DateTime(2026, 2, 5): AttendanceStatus.late,
    DateTime(2026, 2, 8): AttendanceStatus.absent,
    DateTime(2026, 2, 4): AttendanceStatus.present,
  };

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

    if (result == true) {
      setState(() {
        _isCheckedIn = true;
        _checkInTime = _formatTime(DateTime.now());
        _checkOutTime = "--:--";
        _showPhotoUI = false;
      });
    } else {
      setState(() {
        _showPhotoUI = false;
      });
    }
  }

  void _handleCheckOut() {
    setState(() {
      _isCheckedIn = false;
      _checkOutTime = _formatTime(DateTime.now());
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Checked Out Successfully!"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onApplyLeave() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LeaveScreen()),
    );
  }

  String _formatTime(DateTime t) {
    return "${t.hour > 12 ? t.hour - 12 : t.hour}:${t.minute.toString().padLeft(2, '0')} ${t.hour >= 12 ? 'PM' : 'AM'}";
  }

  // Helper to find status for a specific day
  AttendanceStatus? _getStatus(DateTime day) {
    for (var entry in _attendanceData.entries) {
      if (isSameDay(entry.key, day)) return entry.value;
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
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

              // 4. Recent History List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Recent History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  TextButton(onPressed: () {}, child: const Text("View All", style: TextStyle(color: Colors.grey))),
                ],
              ),
              const SizedBox(height: 10),
              _buildHistoryItem("Feb 06", "10:19 AM", "Present", Colors.green),
              _buildHistoryItem("Feb 05", "10:21 AM", "Present", Colors.green),
              _buildHistoryItem("Feb 04", "06:52 PM", "Late", Colors.orange),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeroStatusCard() {
    if (_showPhotoUI) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFF101010),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2020),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B6B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: Colors.white,
                    size: 45,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Not Checked In",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Take a selfie photo to mark\nattendance",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _startPhotoCheckIn,
                icon: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.black,
                  size: 24,
                ),
                label: const Text(
                  "Take Photo to Check In",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB4B4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _onApplyLeave,
                icon: const Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                label: const Text(
                  "Apply Leave",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final String todayDate = DateFormat('EEEE, MMMM d, y').format(DateTime.now());
    final String timeString = _isCheckedIn
        ? _checkInTime
        : DateFormat('hh:mm a').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 16,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isCheckedIn ? const Color(0xFF15301F) : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isCheckedIn ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  color: _isCheckedIn ? const Color(0xFF38D26C) : Colors.grey[400],
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isCheckedIn ? "Checked In" : "Not Checked In",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${_isCheckedIn ? 'Check in' : 'Today'}: $timeString · $todayDate",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _isCheckedIn ? _handleCheckOut : _startPhotoCheckIn,
                icon: Icon(
                  _isCheckedIn ? Icons.timer_off_outlined : Icons.timer_outlined,
                  color: _isCheckedIn ? Colors.white : Colors.black,
                  size: 18,
                ),
                label: Text(
                  _isCheckedIn ? "Check Out" : "Check In",
                  style: TextStyle(
                    color: _isCheckedIn ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCheckedIn ? Colors.redAccent : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _onApplyLeave,
                icon: const Icon(Icons.description_outlined, color: Colors.white, size: 18),
                label: const Text(
                  "Apply Leave",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard("Present", "04", Icons.check_circle, Colors.greenAccent)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard("Late", "01", Icons.access_time, Colors.orangeAccent)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard("Absent", "01", Icons.cancel, Colors.redAccent)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard("Leave", "00", Icons.beach_access, Colors.purpleAccent)),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414), // Matches your other cards
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TableCalendar(
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
            // If it's the selected day, let selectedBuilder handle it (optional)
            if (isSameDay(day, _selectedDay)) return null;

            AttendanceStatus? status = _getStatus(day);
            if (status == AttendanceStatus.present) {
              return _buildCalendarCell(day, kGreenBg, kGreenText, Icons.check);
            } else if (status == AttendanceStatus.absent) {
              return _buildCalendarCell(day, kRedBg, kRedText, Icons.close);
            } else if (status == AttendanceStatus.late) {
              return _buildCalendarCell(day, kOrangeBg, kOrangeText, Icons.access_time);
            }
            return null;
          },

          // 2. Default Day (Empty)
          defaultBuilder: (context, day, focusedDay) {
             return Center(child: Text('${day.day}', style: const TextStyle(color: Colors.white70)));
          },

          // 3. Today (Highlighted)
          todayBuilder: (context, day, focusedDay) {
            return Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text('${day.day}', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
            );
          },
          
          // 4. Selected Day
          selectedBuilder: (context, day, focusedDay) {
            return Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.pinkAccent),
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
          _focusedDay = focusedDay;
        },
      ),
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

  Widget _buildHistoryItem(String date, String checkIn, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.calendar_today, size: 18, color: Colors.white70),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                Text("In: $checkIn", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3))
            ),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

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