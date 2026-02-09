import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Needed for date formatting
import '../screen/camera_screen.dart';

class WelcomeCard extends StatelessWidget {
  // Add these variables to receive data from DashboardScreen
  final bool isCheckedIn;
  final bool showPhotoUI;
  final DateTime? checkInTime;
  final VoidCallback onCheckInToggle;
  final VoidCallback onTakePhoto;

  const WelcomeCard({
    super.key,
    required this.isCheckedIn,
    required this.showPhotoUI,
    required this.checkInTime,
    required this.onCheckInToggle,
    required this.onTakePhoto,
  });

  @override
  Widget build(BuildContext context) {
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
                  
                  // If photo was taken successfully, trigger check in
                  if (result == true) {
                    onTakePhoto();
                  }
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
            
            const SizedBox(height: 16),
            
            // Apply Leave Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to leave application screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening leave application...'),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                label: const Text(
                  'Apply Leave',
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
    
    // If user is checked in, show the welcome message
    if (isCheckedIn) {
      // 1. Get today's date dynamically (e.g., "Friday, February 6, 2026")
      final String todayDate = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

      // 2. Format the check-in time if it exists (e.g., "04:49 AM")
      final String timeString = checkInTime != null 
          ? DateFormat('hh:mm a').format(checkInTime!) 
          : "--:--";

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
                const Text(
                  "Good Morning, Rahul Gupta!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
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
                )
              ],
            ),
            
            // Check Out Button
            ElevatedButton.icon(
              onPressed: onCheckInToggle,
              icon: const Icon(
                Icons.timer_off_outlined, 
                color: Colors.white
              ),
              label: const Text(
                "Check Out", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            )
          ],
        ),
      );
    }

    // If user is NOT checked in and not showing photo UI, show regular welcome card
    // 1. Get today's date dynamically (e.g., "Friday, February 6, 2026")
    final String todayDate = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

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
              const Text(
                "Good Morning, Rahul Gupta!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
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
          )
        ],
      ),
    );
  }
}