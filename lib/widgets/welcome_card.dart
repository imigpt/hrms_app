import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Needed for date formatting
import '../models/profile_model.dart';
import '../theme/app_theme.dart'; // Import AppTheme

class WelcomeCard extends StatelessWidget {
  final bool isCheckedIn;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? checkInLocation;
  final String? checkOutLocation;
  final double? workHours;
  final VoidCallback onCheckInToggle;
  final ProfileUser? user;

  const WelcomeCard({
    super.key,
    required this.isCheckedIn,
    required this.checkInTime,
    this.checkOutTime,
    this.checkInLocation,
    this.checkOutLocation,
    this.workHours,
    required this.onCheckInToggle,
    this.user,
  });

  // Helper to get responsive values
  Map<String, double> _getResponsiveValues(double width) {
    return {
      'cardPad': width < 380 ? 16.0 : 24.0,
      'titleSize': width < 380 ? 20.0 : 24.0,
      'subtitleSize': width < 380 ? 13.0 : 14.0,
      'bodyTextSize': width < 380 ? 13.0 : 14.0,
      'iconOuter': width < 380 ? 90.0 : 120.0,
      'iconInner': width < 380 ? 52.0 : 70.0,
      'iconCheckSize': width < 380 ? 28.0 : 40.0,
      'buttonHeight': width < 380 ? 48.0 : 56.0,
      'spacing': width < 380 ? 16.0 : 24.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    // If user has checked out, show Day Complete card
    if (checkOutTime != null && checkInTime != null) {
      final String checkInTimeStr = DateFormat('hh:mm a').format(checkInTime!.toLocal());
      final String checkOutTimeStr = DateFormat('hh:mm a').format(checkOutTime!.toLocal());

      String workHoursStr = 'N/A';
      if (workHours != null) {
        final hours = workHours!.floor();
        final minutes = ((workHours! - hours) * 60).round();
        workHoursStr = '${hours}h ${minutes}m';
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final values = _getResponsiveValues(constraints.maxWidth);
          final w = values['cardPad']!;

          return SingleChildScrollView(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              padding: EdgeInsets.all(w),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Check Icon
                  Container(
                    width: values['iconOuter'],
                    height: values['iconOuter'],
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(values['iconOuter']! / 2),
                      border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
                    ),
                    child: Center(
                      child: Container(
                        width: values['iconInner'],
                        height: values['iconInner'],
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: values['iconCheckSize'],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: values['spacing']),

                  // Title
                  Text(
                    'Day Complete',
                    style: TextStyle(
                      fontSize: values['titleSize'],
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Check in and Check out times
                  Text(
                    'Check in: $checkInTimeStr • Check out: $checkOutTimeStr',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: values['bodyTextSize'],
                      color: Colors.grey[400],
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: values['spacing']),

                  // Locations if available
                  if (checkInLocation != null || checkOutLocation != null) ...[
                    if (checkInLocation != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.25), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.login, color: Colors.green, size: 18),
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
                                      fontSize: values['bodyTextSize']! - 2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    checkInLocation!,
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: values['bodyTextSize'],
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.25), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.logout, color: Colors.red, size: 18),
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
                                      fontSize: values['bodyTextSize']! - 2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    checkOutLocation!,
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: values['bodyTextSize'],
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
                      fontSize: values['bodyTextSize'],
                      color: Colors.grey[300],
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    // Checked In State
    if (isCheckedIn) {
      final String todayDate = DateFormat('EEEE, MMMM d, y').format(DateTime.now());
      final String timeString = checkInTime != null
          ? DateFormat('hh:mm a').format(checkInTime!)
          : "--:--";
      final String userName = user?.name ?? 'User';
      final locColor = checkInLocation == 'Main Building' ? Colors.green : Colors.orange;

      return LayoutBuilder(
        builder: (context, constraints) {
          final values = _getResponsiveValues(constraints.maxWidth);
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Green top banner
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: values['cardPad']!,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.green.withOpacity(0.15)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Currently Working',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              'Checked in at $timeString',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Live',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                Padding(
                  padding: EdgeInsets.all(values['cardPad']!),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $userName!',
                        style: TextStyle(
                          fontSize: values['titleSize'],
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        todayDate,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: values['subtitleSize'],
                        ),
                      ),

                      if (checkInLocation != null) ...[
                        SizedBox(height: values['spacing']),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: locColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: locColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: locColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  checkInLocation == 'Main Building'
                                      ? Icons.business_rounded
                                      : Icons.place_rounded,
                                  color: locColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Check-In Location',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: values['bodyTextSize']! - 2,
                                    ),
                                  ),
                                  Text(
                                    checkInLocation!,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: values['bodyTextSize'],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: values['spacing']),

                      // Check Out Button
                      SizedBox(
                        width: double.infinity,
                        height: values['buttonHeight'],
                        child: ElevatedButton.icon(
                          onPressed: onCheckInToggle,
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: Text(
                            'Check Out',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: values['bodyTextSize'],
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFE85D75),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Not Checked In State
    final String todayDate = DateFormat('EEEE, MMMM d, y').format(DateTime.now());
    final String userName = user?.name ?? 'User';

    return LayoutBuilder(
      builder: (context, constraints) {
        final values = _getResponsiveValues(constraints.maxWidth);
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top banner: Not Checked In
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: values['cardPad']!,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.07)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.schedule_rounded,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Not Checked In',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Take a selfie to mark attendance',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: EdgeInsets.all(values['cardPad']!),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Morning, $userName!',
                      style: TextStyle(
                        fontSize: values['titleSize'],
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      todayDate,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: values['subtitleSize'],
                      ),
                    ),
                    SizedBox(height: values['spacing']),

                    // Take Selfie / Check In Button
                    SizedBox(
                      width: double.infinity,
                      height: values['buttonHeight'],
                      child: ElevatedButton.icon(
                        onPressed: onCheckInToggle,
                        icon: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                        label: Text(
                          'Take Selfie to Check In',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: values['bodyTextSize'],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE85D75),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
