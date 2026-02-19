import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Needed for date formatting
import '../screen/camera_screen.dart';
import '../models/profile_model.dart';
import '../models/attendance_checkin_model.dart';

class WelcomeCard extends StatelessWidget {
  // Add these variables to receive data from DashboardScreen
  final bool isCheckedIn;
  final bool showPhotoUI;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? checkInLocation;
  final String? checkOutLocation;
  final double? workHours;
  final VoidCallback onCheckInToggle;
  final Function(dynamic) onCheckInResult;
  final ProfileUser? user;

  const WelcomeCard({
    super.key,
    required this.isCheckedIn,
    required this.showPhotoUI,
    required this.checkInTime,
    this.checkOutTime,
    this.checkInLocation,
    this.checkOutLocation,
    this.workHours,
    required this.onCheckInToggle,
    required this.onCheckInResult,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    // If user has checked out, show Day Complete card
    if (checkOutTime != null && checkInTime != null) {
      // Format check-in and check-out times
      final String checkInTimeStr = DateFormat('hh:mm a').format(checkInTime!.toLocal());
      final String checkOutTimeStr = DateFormat('hh:mm a').format(checkOutTime!.toLocal());
      
      // Calculate work hours in "Xh Ym" format
      String workHoursStr = 'N/A';
      if (workHours != null) {
        final hours = workHours!.floor();
        final minutes = ((workHours! - hours) * 60).round();
        workHoursStr = '${hours}h ${minutes}m';
      }
      
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Green Check Icon Container
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A2E),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 45,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            const Text(
              'Day Complete',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Check in and Check out times
            Text(
              'Check in: $checkInTimeStr • Check out: $checkOutTimeStr',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Locations if available
            if (checkInLocation != null || checkOutLocation != null) ...[
              if (checkInLocation != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withOpacity(0.3), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.login, color: Colors.green, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Check-In Location',
                              style: TextStyle(
                                color: Colors.green[300],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              checkInLocation!,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (checkOutLocation != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.logout, color: Colors.red, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Check-Out Location',
                              style: TextStyle(
                                color: Colors.red[300],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              checkOutLocation!,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            
            // Total work hours
            Text(
              'Total: $workHoursStr',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    
    // If showing photo UI, display the photo attendance card
    if (showPhotoUI) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Clock Icon Container
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
            
            // Title
            const Text(
              'Not Checked In',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              'Take a selfie photo to mark\nattendance',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Take Photo Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Navigate to camera screen
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraScreen(),
                    ),
                  );
                  
                  // Pass the result to the callback (could be AttendanceData, 'refresh' string, or null)
                  onCheckInResult(result);
                },
                icon: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.black,
                  size: 24,
                ),
                label: const Text(
                  'Take Photo to Check In',
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
          ],
        ),
      );
    }
    
    // If user is checked in, show the welcome message
    if (isCheckedIn) {
      // 1. Get today's date dynamically (e.g., "Friday, February 6, 2026")
      final String todayDate = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

      // 2. Format the check-in time if it exists (e.g., "04:49 AM")
      final String timeString = checkInTime != null 
          ? DateFormat('hh:mm a').format(checkInTime!) 
          : "--:--";
      
      // 3. Get user name
      final String userName = user?.name ?? 'User';

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Good Morning, $userName!",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              todayDate, // Dynamic Date
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                const SizedBox(width: 5),
                Text("Checked in at $timeString", style: const TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
            
            // Display location if available
            if (checkInLocation != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, color: Colors.grey, size: 14),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      checkInLocation!,
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Check Out Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: onCheckInToggle,
                icon: const Icon(
                  Icons.timer_off_outlined, 
                  color: Colors.white,
                  size: 24,
                ),
                label: const Text(
                  "Check Out", 
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            
            // Display check-in location below check out button
            if (checkInLocation != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: Colors.green, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Check-In Location',
                            style: TextStyle(
                              color: Colors.green[300],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            checkInLocation!,
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    // If user is NOT checked in and not showing photo UI, show regular welcome card
    // 1. Get today's date dynamically (e.g., "Friday, February 6, 2026")
    final String todayDate = DateFormat('EEEE, MMMM d, y').format(DateTime.now());
    final String userName = user?.name ?? 'User';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 20,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Good Morning, $userName!",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                todayDate,
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 8),
              
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.grey, size: 16),
                  SizedBox(width: 5),
                  Text("Not checked in yet", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              )
            ],
          ),
          
          // Check In Button
          ElevatedButton.icon(
            onPressed: onCheckInToggle,
            icon: const Icon(
              Icons.timer_outlined, 
              color: Colors.black
            ),
            label: const Text(
              "Check In", 
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}