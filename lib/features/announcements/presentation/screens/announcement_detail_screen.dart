import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hrms_app/features/announcements/data/models/announcement_model.dart';
import 'package:hrms_app/features/announcements/data/services/announcement_service.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  /// Pass the basic announcement from the list (for immediate display).
  /// Full detail is fetched from the API in the background.
  final Announcement announcement;
  final bool isAlreadyRead;
  final void Function(String id)? onRead;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcement,
    this.isAlreadyRead = false,
    this.onRead,
  });

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  // Colors
  static const _kBg = Color(0xFF050505);
  static const _kCard = Color(0xFF141414);
  static const _kDivider = Color(0xFF1E1E1E);

  Announcement? _detail;
  bool _isLoading = true;
  bool _markedRead = false;

  @override
  void initState() {
    super.initState();
    _markedRead = widget.isAlreadyRead;
    _fetchDetail();
    if (!widget.isAlreadyRead) {
      _markAsRead();
    }
  }

  Future<void> _fetchDetail() async {
    try {
      final token = await TokenStorageService().getToken();
      if (token == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final detail = await AnnouncementService.getAnnouncementById(
        token: token,
        announcementId: widget.announcement.id,
      );
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching detail: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead() async {
    try {
      final token = await TokenStorageService().getToken();
      if (token == null) return;
      final success = await AnnouncementService.markAsRead(
        token: token,
        announcementId: widget.announcement.id,
      );
      if (success) {
        if (mounted) setState(() => _markedRead = true);
        widget.onRead?.call(widget.announcement.id);
      }
    } catch (e) {
      print('Mark as read error: $e');
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return const Color(0xFFD32F2F);
      case 'medium':
      case 'important':
        return const Color(0xFFFBC02D);
      default:
        return const Color(0xFF42A5F5);
    }
  }

  IconData _priorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return Icons.notifications_active;
      case 'medium':
      case 'important':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _detail ?? widget.announcement;
    final priorityColor = _priorityColor(data.priority);
    final createdAt = DateFormat(
      'MMMM d, yyyy • hh:mm a',
    ).format(data.createdAt);
    final updatedAt = DateFormat(
      'MMM d, yyyy • hh:mm a',
    ).format(data.updatedAt);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Announcement',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_markedRead)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.done_all, size: 13, color: Colors.green[400]),
                  const SizedBox(width: 4),
                  Text(
                    'Read',
                    style: TextStyle(fontSize: 11, color: Colors.green[400]),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white24),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: priorityColor.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _priorityIcon(data.priority),
                              size: 13,
                              color: priorityColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              data.priority.toUpperCase(),
                              style: TextStyle(
                                color: priorityColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        createdAt,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Container(height: 1, color: _kDivider),
                  const SizedBox(height: 20),

                  // Content
                  Text(
                    data.content,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Meta info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Column(
                      children: [
                        // Created By
                        if (data.createdBy != null) ...[
                          _metaRow(
                            icon: Icons.person_outline,
                            label: 'Posted by',
                            value: data.createdBy!.name,
                            subtitle: data.createdBy!.position.isNotEmpty
                                ? data.createdBy!.position
                                : data.createdBy!.email,
                          ),
                          _divider(),
                        ],

                        // Posted on
                        _metaRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Posted on',
                          value: createdAt,
                        ),

                        // Last updated
                        if (data.updatedAt != data.createdAt) ...[
                          _divider(),
                          _metaRow(
                            icon: Icons.update_outlined,
                            label: 'Last updated',
                            value: updatedAt,
                          ),
                        ],

                        // Read by count
                        _divider(),
                        _metaRow(
                          icon: Icons.visibility_outlined,
                          label: 'Read by',
                          value:
                              '${data.readBy.length} member${data.readBy.length == 1 ? '' : 's'}',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _divider() => Container(
    margin: const EdgeInsets.symmetric(vertical: 12),
    height: 1,
    color: _kDivider,
  );

  Widget _metaRow({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.grey[400]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
