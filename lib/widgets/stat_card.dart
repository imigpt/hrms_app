import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isAlert;
  final VoidCallback? onTap; // Added tap interaction

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.isAlert = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Define the color based on alert status
    final Color iconColor = isAlert ? Colors.pinkAccent : Colors.white70;
    final Color iconBgColor = isAlert 
        ? Colors.pinkAccent.withOpacity(0.15) 
        : Colors.white.withOpacity(0.05);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {}, // Handle taps
        borderRadius: BorderRadius.circular(16),
        overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.05)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)), // Subtle border
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Text
                  Expanded(
                    child: Text(
                      title, 
                      style: TextStyle(
                        color: Colors.grey[400], 
                        fontSize: 13, 
                        fontWeight: FontWeight.w500
                      ), 
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Icon Container
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  )
                ],
              ),
              
              // Value Text
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}