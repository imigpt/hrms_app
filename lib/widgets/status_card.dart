import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  // 1. Accept dynamic data from the parent screen
  final Duration workedDuration;
  final double progress; // Value between 0.0 and 1.0

  const StatusCard({
    super.key,
    required this.workedDuration,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    // 2. Format duration into readable text (e.g., "2h 34m")
    String hours = workedDuration.inHours.toString();
    String minutes = (workedDuration.inMinutes.remainder(60)).toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Status", style: TextStyle(fontWeight: FontWeight.bold)),
              // 3. Display the dynamic time string
              Text(
                "${hours}h ${minutes}m", 
                style: const TextStyle(fontWeight: FontWeight.bold)
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text("Working Hours", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          
          // 4. Update the Progress Bar dynamically
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0), // Prevents crash if progress > 100%
            backgroundColor: Colors.grey[800],
            color: Theme.of(context).primaryColor,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("0h", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("8h target", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}