import 'dart:async'; // Required for the Timer
import 'package:flutter/material.dart';

// Import our custom widgets
import '../widgets/sidebar_menu.dart';
import '../widgets/welcome_card.dart';
import '../widgets/status_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/tasks_section.dart';
import '../widgets/announcements_section.dart';
import 'announcements_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- STATE VARIABLES ---
  bool _isCheckedIn = false;
  bool _showPhotoUI = false;
  DateTime? _checkInTime;
  Duration _workedDuration = const Duration(hours: 2, minutes: 34);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start the timer to simulate working hours increasing
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
  void _toggleCheckIn() {
    if (_isCheckedIn) {
      // User is checking out
      setState(() {
        _isCheckedIn = false;
        _showPhotoUI = false;
        _checkInTime = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Checked Out!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // User clicked Check In - show photo UI
      setState(() {
        _showPhotoUI = true;
      });
    }
  }

  // Called when Take Photo button is clicked
  void _takePhoto() {
    setState(() {
      _isCheckedIn = true;
      _showPhotoUI = false;
      _checkInTime = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Checked In Successfully!"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress (Assuming 8 hour workday target)
    double progress = _workedDuration.inMinutes / (8 * 60);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint for Desktop vs Mobile
        bool isDesktop = constraints.maxWidth > 800;

        return Scaffold(
          // --- APP BAR (Mobile Only) ---
          appBar: isDesktop
              ? null
              : AppBar(
                  title: const Text("Employee Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Theme.of(context).cardColor,
                  elevation: 0,
                  actions: [
                    // --- ANNOUNCEMENT ICON ---
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AnnouncementsScreen()),
                          );
                        },
                        icon: Badge(
                          label: const Text('3'), // Modern badge showing count
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(Icons.announcement_outlined, size: 28),
                        ),
                      ),
                    ),
                  ],
                ),
          
          drawer: !isDesktop ? const Drawer(child: SidebarMenu()) : null,
          
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. SIDEBAR (Desktop Only)
              if (isDesktop)
                const SizedBox(
                  width: 250,
                  child: SidebarMenu(),
                ),

              // 2. MAIN CONTENT AREA
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Desktop Header
                      if (isDesktop) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Employee Dashboard",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            // Desktop Notification Icon
                            IconButton(
                              onPressed: () {},
                              icon: Badge(
                                label: const Text('3'),
                                backgroundColor: Theme.of(context).primaryColor,
                                child: const Icon(Icons.notifications_outlined, size: 28),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // --- DYNAMIC WIDGETS ---
                      
                      // Welcome Card (Passes functions to handle button click)
                      WelcomeCard(
                        isCheckedIn: _isCheckedIn,
                        showPhotoUI: _showPhotoUI,
                        checkInTime: _checkInTime,
                        onCheckInToggle: _toggleCheckIn,
                        onTakePhoto: _takePhoto,
                      ),
                      const SizedBox(height: 20),

                      // Status Card (Updates based on timer)
                      StatusCard(
                        workedDuration: _workedDuration,
                        progress: progress,
                      ),
                      const SizedBox(height: 20),

                      // Responsive Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isDesktop ? 4 : 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: isDesktop ? 1.6 : 1.3,
                        children: const [
                          StatCard(title: "Leave Balance", value: "12 days", icon: Icons.calendar_today, isAlert: false),
                          StatCard(title: "Active Tasks", value: "3", icon: Icons.assignment),
                          StatCard(title: "Pending Expenses", value: "₹4500", icon: Icons.receipt_long, isAlert: true),
                          StatCard(title: "Month Attendance", value: "92%", icon: Icons.access_time),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Responsive Bottom Section
                      if (isDesktop)
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: TasksSection()),
                            SizedBox(width: 20),
                            Expanded(child: AnnouncementsSection()),
                          ],
                        )
                      else ...[
                        const TasksSection(),
                        const SizedBox(height: 20),
                        const AnnouncementsSection(),
                      ],
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