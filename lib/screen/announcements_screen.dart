import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';
import '../services/token_storage_service.dart';
import '../services/notification_service.dart';
import 'announcement_detail_screen.dart';
// import 'announcement_api_test_screen.dart';
import 'package:intl/intl.dart';

class AnnouncementsScreen extends StatefulWidget {
  final String? role;
  final String? token;
  const AnnouncementsScreen({super.key, this.role, this.token});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  bool get _isAdmin => widget.role?.toLowerCase() == 'admin' || widget.role?.toLowerCase() == 'hr';

  List<Announcement> _allAnnouncements = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All';
  String? _currentUserId;
  String? _authToken;
  // Track which IDs have been read (persisted across sessions)
  Set<String> _readIds = {};
  // Track which announcements have been notified
  Set<String> _notifiedAnnouncementIds = {};

  @override
  void initState() {
    super.initState();
    _initializeUserAndReadIds();
  }

  Future<void> _initializeUserAndReadIds() async {
    // First get the current user ID
    await _getCurrentUserId();
    // Then load the read IDs for this specific user
    await _loadPersistedReadIds();
    // Finally fetch announcements
    await _fetchAnnouncements();
  }

  Future<void> _getCurrentUserId() async {
    try {
      final token = await TokenStorageService().getToken();
      if (token != null) {
        // You might need to decode the JWT token or make an API call to get user ID
        // For now, we'll use a simple approach - you can enhance this based on your token structure
        _currentUserId = token.hashCode.toString(); // Simple approach using token hash
        // TODO: Replace with actual user ID extraction from token or API call
      }
    } catch (e) {
      print('Error getting current user ID: $e');
    }
  }

  Future<void> _loadPersistedReadIds() async {
    try {
      if (_currentUserId == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final userSpecificKey = 'read_announcement_ids_$_currentUserId';
      final ids = prefs.getStringList(userSpecificKey) ?? [];
      if (mounted) {
        setState(() {
          _readIds = Set<String>.from(ids);
        });
      }
    } catch (e) {
      print('Error loading persisted read IDs: $e');
    }
  }

  Future<void> _persistReadId(String announcementId) async {
    try {
      if (_currentUserId == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final userSpecificKey = 'read_announcement_ids_$_currentUserId';
      final ids = prefs.getStringList(userSpecificKey) ?? [];
      if (!ids.contains(announcementId)) {
        ids.add(announcementId);
        await prefs.setStringList(userSpecificKey, ids);
      }
    } catch (e) {
      print('Error persisting read ID: $e');
    }
  }

  Future<void> _fetchAnnouncements() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get token
      final token = widget.token ?? await TokenStorageService().getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }
      _authToken = token;

      // Fetch announcements
      final response = await AnnouncementService.getAnnouncements(token: token);

      if (mounted) {
        setState(() {
          _allAnnouncements = response.data
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _isLoading = false;
        });
        
        // Show notifications for new announcements
        for (final announcement in response.data) {
          if (!_notifiedAnnouncementIds.contains(announcement.id)) {
            await NotificationService().showAnnouncementNotification(
              title: 'New Announcement',
              message: announcement.title ?? 'New announcement from management',
              body: announcement.content ?? announcement.title ?? 'Check the announcements section for details',
              payload: {'id': announcement.id},
            );
            _notifiedAnnouncementIds.add(announcement.id);
          }
        }
      }
    } catch (e) {
      print('Error fetching announcements: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(String announcementId) async {
    if (_readIds.contains(announcementId)) return;
    setState(() => _readIds.add(announcementId));
    // Persist so read state survives app restarts
    _persistReadId(announcementId);
    try {
      final token = await TokenStorageService().getToken();
      if (token != null) {
        await AnnouncementService.markAsRead(
          token: token,
          announcementId: announcementId,
        );
      }
    } catch (e) {
      print('Mark as read error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colors based on your image
    final kBgColor = const Color(0xFF050505);
    final kCardColor = const Color(0xFF141414);
    final kRedAccent = const Color(0xFFD32F2F);
    final kYellowAccent = const Color(0xFFFBC02D);
    final kPurpleAccent = const Color(0xFF7B1FA2);
    
    // Filter Logic - filter by displayType
    List<Announcement> filteredList = _selectedFilter == 'All'
        ? _allAnnouncements
        : _allAnnouncements.where((item) => item.displayType == _selectedFilter).toList();

    // Stats Calculation
    int urgentCount = _allAnnouncements.where((i) => i.displayType == 'Urgent').length;
    int importantCount = _allAnnouncements.where((i) => i.displayType == 'Important').length;
    int infoCount = _allAnnouncements.where((i) => i.displayType == 'Info').length;
    int totalCount = _allAnnouncements.length;

    return Scaffold(
      backgroundColor: kBgColor,
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showCreateAnnouncementDialog,
              backgroundColor: const Color(0xFFFF8FA3),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: const Text('New Announcement', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
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
        // actions: [
        //   Tooltip(
        //     message: 'API Tests',
        //     child: IconButton(
        //       icon: const Icon(Icons.api_outlined, color: Colors.pinkAccent, size: 22),
        //       onPressed: () => Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //             builder: (_) => const AnnouncementApiTestScreen()),
        //       ),
        //     ),
        //   ),
        // ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Stats Row (Urgent, Important, Info, Total) - Scrollable
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    SizedBox(
                      width: 100,
                      child: _buildStatCard("Urgent", urgentCount, Icons.warning_amber_rounded, kRedAccent),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: _buildStatCard("Important", importantCount, Icons.notifications_active_outlined, kYellowAccent),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: _buildStatCard("Info", infoCount, Icons.info_outline_rounded, kPurpleAccent),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: _buildStatCard("Total", totalCount, Icons.campaign_outlined, Colors.blueAccent),
                    ),
                  ],
                ),
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorState()
                        : filteredList.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: _fetchAnnouncements,
                                child: ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  itemCount: filteredList.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    return _buildAnnouncementCard(filteredList[index], kCardColor);
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Builders ---

  // ── Create Announcement Dialog ────────────────────────────────────────────
  Future<void> _showCreateAnnouncementDialog() async {
    final kCardColor = const Color(0xFF141414);
    final kInputColor = const Color(0xFF1F1F1F);
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedPriority = 'medium';
    String? selectedCategory;
    bool submitting = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: kCardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(builder: (_, ss) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  const Icon(Icons.campaign_outlined, color: Color(0xFFFF8FA3), size: 22),
                  const SizedBox(width: 10),
                  const Text('New Announcement', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(sheetCtx), icon: const Icon(Icons.close, color: Colors.white54, size: 20)),
                ]),
                const SizedBox(height: 20),
                // Priority selector
                const Text('Priority', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(children: [
                  for (final p in [
                    ('low', 'Info', const Color(0xFF7B1FA2)),
                    ('medium', 'Important', const Color(0xFFFBC02D)),
                    ('high', 'Urgent', const Color(0xFFD32F2F)),
                  ])
                    Expanded(
                      child: GestureDetector(
                        onTap: () => ss(() => selectedPriority = p.$1),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedPriority == p.$1 ? p.$3.withValues(alpha: 0.2) : kInputColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedPriority == p.$1 ? p.$3 : Colors.white12,
                              width: selectedPriority == p.$1 ? 1.5 : 1,
                            ),
                          ),
                          child: Text(p.$2, textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selectedPriority == p.$1 ? p.$3 : Colors.grey,
                              fontSize: 13, fontWeight: FontWeight.w600,
                            )),
                        ),
                      ),
                    ),
                ]),
                const SizedBox(height: 20),
                // Category
                const Text('Category', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: kInputColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      dropdownColor: kInputColor,
                      hint: Text('Select category', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 20),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      items: ['Policy', 'Event', 'Benefits', 'IT', 'Facility', 'General']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => ss(() => selectedCategory = v),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                const Text('Title *', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Announcement title',
                    hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                    filled: true, fillColor: kInputColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                // Content
                const Text('Content *', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: contentCtrl,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Write the announcement content...',
                    hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                    filled: true, fillColor: kInputColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8FA3),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: submitting ? null : () async {
                      final title = titleCtrl.text.trim();
                      final content = contentCtrl.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a title'), backgroundColor: Colors.red));
                        return;
                      }
                      if (content.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter content'), backgroundColor: Colors.red));
                        return;
                      }
                      final token = _authToken ?? widget.token ?? await TokenStorageService().getToken();
                      if (token == null) return;
                      ss(() => submitting = true);
                      try {
                        await AnnouncementService.createAnnouncement(
                          token: token,
                          title: title,
                          content: content,
                          priority: selectedPriority,
                          category: selectedCategory,
                        );
                        if (sheetCtx.mounted) Navigator.pop(sheetCtx, true);
                      } catch (e) {
                        if (sheetCtx.mounted) ss(() => submitting = false);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
                      }
                    },
                    icon: submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(submitting ? 'Publishing...' : 'Publish Announcement',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      }),
    );

    titleCtrl.dispose();
    contentCtrl.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Announcement published!'),
        backgroundColor: Color(0xFF00C853),
      ));
      _fetchAnnouncements();
    }
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const Spacer(),
          Text(
            "$count",
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement item, Color cardColor) {
    Color typeColor = Colors.blue;
    if (item.displayType == 'Urgent') typeColor = const Color(0xFFD32F2F);
    if (item.displayType == 'Important') typeColor = const Color(0xFFFBC02D);
    if (item.displayType == 'Info') typeColor = const Color(0xFF7B1FA2);

    // Format date
    String formattedDate = DateFormat('MMM d, yyyy').format(item.createdAt);

    final bool isRead = _readIds.contains(item.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnnouncementDetailScreen(
              announcement: item,
              isAlreadyRead: isRead,
              onRead: (id) => _markAsRead(id),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isRead
              ? null
              : Border.all(color: Colors.white.withOpacity(0.08)),
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
                    item.displayType.toUpperCase(),
                    style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                if (isRead)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.done_all, size: 12, color: Colors.green[400]),
                        const SizedBox(width: 4),
                        Text('Read', style: TextStyle(fontSize: 10, color: Colors.green[400])),
                      ],
                    ),
                  )
                else
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isRead ? Colors.grey[400] : Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.content,
              style: TextStyle(fontSize: 13, color: Colors.grey[400], height: 1.4),
            ),
            if (item.createdBy != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'By ${item.createdBy!.name}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(
            "Failed to load announcements",
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          if (_error != null && _error!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!.replaceFirst('Exception: ', ''),
                style: TextStyle(color: Colors.red[400], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _fetchAnnouncements,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF141414),
              foregroundColor: Colors.white,
            ),
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