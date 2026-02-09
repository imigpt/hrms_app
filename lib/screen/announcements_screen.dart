import 'package:flutter/material.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  // 1. Extended Dummy Data with 'type' for filtering
  final List<Map<String, String>> _allAnnouncements = [
    {
      "title": "Server Maintenance",
      "date": "Feb 10, 2026",
      "content": "The HR portal will be down for maintenance from 12:00 AM to 4:00 AM.",
      "type": "Urgent"
    },
    {
      "title": "Welcome to Aselea Network",
      "date": "Feb 6, 2026",
      "content": "We are thrilled to announce the launch of our new HRMS portal. Please update your profile.",
      "type": "Info"
    },
    {
      "title": "Public Holiday Notice",
      "date": "Feb 5, 2026",
      "content": "The office will remain closed on upcoming Tuesday due to public holiday.",
      "type": "Important"
    },
    {
      "title": "New Policy Update",
      "date": "Jan 28, 2026",
      "content": "Please review the updated remote work policy in the documents section.",
      "type": "Important"
    },
  ];

  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    // Colors based on your image
    final kBgColor = const Color(0xFF050505);
    final kCardColor = const Color(0xFF141414);
    final kRedAccent = const Color(0xFFD32F2F);
    final kYellowAccent = const Color(0xFFFBC02D);
    final kPurpleAccent = const Color(0xFF7B1FA2);
    
    // Filter Logic
    List<Map<String, String>> filteredList = _selectedFilter == 'All'
        ? _allAnnouncements
        : _allAnnouncements.where((item) => item['type'] == _selectedFilter).toList();

    // Stats Calculation
    int urgentCount = _allAnnouncements.where((i) => i['type'] == 'Urgent').length;
    int importantCount = _allAnnouncements.where((i) => i['type'] == 'Important').length;
    int totalCount = _allAnnouncements.length;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Announcements",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Stats Row (Urgent, Important, Total)
              Row(
                children: [
                  Expanded(child: _buildStatCard("Urgent", urgentCount, Icons.warning_amber_rounded, kRedAccent)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard("Important", importantCount, Icons.notifications_active_outlined, kYellowAccent)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard("Total", totalCount, Icons.campaign_outlined, kPurpleAccent)),
                ],
              ),

              const SizedBox(height: 32),

              // 2. Header & Filter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Announcements",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Company-wide updates",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  
                  // Custom Filter Dropdown
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: kCardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: kCardColor,
                        value: _selectedFilter,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedFilter = newValue!;
                          });
                        },
                        items: ['All', 'Urgent', 'Important', 'Info'].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 3. The List
              Expanded(
                child: filteredList.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildAnnouncementCard(filteredList[index], kCardColor);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            "$count",
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, String> item, Color cardColor) {
    Color typeColor = Colors.blue;
    if (item['type'] == 'Urgent') typeColor = const Color(0xFFD32F2F);
    if (item['type'] == 'Important') typeColor = const Color(0xFFFBC02D);
    if (item['type'] == 'Info') typeColor = const Color(0xFF7B1FA2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: typeColor.withOpacity(0.3)),
                ),
                child: Text(
                  item['type']!.toUpperCase(),
                  style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Text(
                item["date"] ?? "",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item["title"] ?? "",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            item["content"] ?? "",
            style: TextStyle(fontSize: 13, color: Colors.grey[400], height: 1.4),
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
          Icon(Icons.mark_email_read_outlined, size: 48, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text("No announcements found", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }
}