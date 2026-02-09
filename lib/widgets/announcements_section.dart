import 'package:flutter/material.dart';
import '../screen/announcements_screen.dart';

class AnnouncementsSection extends StatelessWidget {
  // Accepts a list of announcements. Defaults to sample data if empty.
  final List<Map<String, String>> announcements;

  const AnnouncementsSection({
    super.key,
    this.announcements = const [
      {
        "title": "Welcome to Aselea Network",
        "date": "Feb 6, 2026",
        "content": "We are thrilled to announce the launch of our new HRMS portal. Please update your profile."
      },
      {
        "title": "Public Holiday Notice",
        "date": "Feb 10, 2026",
        "content": "The office will remain closed on upcoming Tuesday due to public holiday."
      },
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Matching height with TasksSection for symmetry
      height: 260, 
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header with View All ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("📢 Announcements", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AnnouncementsScreen()),
                  );
                },
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                child: Text("View All", style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor)),
              ),
            ],
          ),
          const Text("Latest company updates", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 15),

          // --- Scrollable List ---
          Expanded(
            child: announcements.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: announcements.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildAnnouncementCard(context, announcements[index]);
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(BuildContext context, Map<String, String> item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: Theme.of(context).primaryColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item["title"]!, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                item["date"]!, 
                style: TextStyle(fontSize: 10, color: Colors.grey[400])
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item["content"]!, 
            style: TextStyle(fontSize: 11, color: Colors.grey[300]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign_outlined, size: 40, color: Colors.grey[800]),
          const SizedBox(height: 8),
          Text("No announcements yet", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
}