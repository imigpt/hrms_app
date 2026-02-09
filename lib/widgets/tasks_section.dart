import 'package:flutter/material.dart';
import '../screen/tasks_screen.dart';

class TasksSection extends StatelessWidget {
  // Accepts a list of tasks. 
  // If nothing is passed, it defaults to these 3 sample tasks for the demo.
  final List<Map<String, String>> tasks;

  const TasksSection({
    super.key,
    this.tasks = const [
      {"title": "Review Q1 Expenses", "due": "Today", "status": "High"},
      {"title": "Update HR Policy", "due": "Feb 8", "status": "Medium"},
      {"title": "Team Meeting Prep", "due": "Feb 9", "status": "Low"},
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Slightly taller to fit the list comfortably
      height: 260, 
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with "View All" button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("📋 My Tasks", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TasksScreen()),
                  );
                },
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                child: Text("View All", style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor)),
              ),
            ],
          ),
          const Text("Your assigned tasks and progress", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),

          // Logic: Show List if tasks exist, otherwise show Empty State
          Expanded(
            child: tasks.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: tasks.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildTaskItem(context, task);
                    },
                  ),
          )
        ],
      ),
    );
  }

  // Helper widget for individual task rows
  Widget _buildTaskItem(BuildContext context, Map<String, String> task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // Circular Checkbox (Visual only for now)
          Icon(Icons.circle_outlined, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          
          // Title & Due Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task["title"]!, 
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "Due: ${task["due"]}", 
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          
          // Priority Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(task["status"]!).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _getStatusColor(task["status"]!).withOpacity(0.3)),
            ),
            child: Text(
              task["status"]!,
              style: TextStyle(fontSize: 10, color: _getStatusColor(task["status"]!)),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for when there are no tasks
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_outlined, size: 40, color: Colors.grey[800]),
          const SizedBox(height: 8),
          Text("No tasks assigned yet", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  // Helper color function
  Color _getStatusColor(String status) {
    switch (status) {
      case 'High': return Colors.orange;
      case 'Medium': return Colors.blue;
      case 'Low': return Colors.green;
      default: return Colors.grey;
    }
  }
}