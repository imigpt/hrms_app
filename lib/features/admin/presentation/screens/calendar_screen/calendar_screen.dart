import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';
import 'package:hrms_app/features/admin/presentation/providers/calendar_provider.dart';
import 'package:hrms_app/features/tasks/data/services/task_service.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';
import 'package:intl/intl.dart';
import 'add_event_dialog.dart';
import 'add_meeting_dialog.dart';
import 'week_view.dart';
import 'day_view.dart';

// ─────────────────────────────────────────────────────────────────
// Configuration Constants
// ─────────────────────────────────────────────────────────────────
const List<Map<String, String>> TIMEZONE_OPTIONS = [
  {'value': 'Asia/Kolkata', 'label': 'IST (India)'},
  {'value': 'Europe/London', 'label': 'GMT/BST (UK)'},
  {'value': 'America/New_York', 'label': 'EST/EDT (New York)'},
  {'value': 'America/Los_Angeles', 'label': 'PST/PDT (Los Angeles)'},
  {'value': 'America/Chicago', 'label': 'CST/CDT (Chicago)'},
  {'value': 'Europe/Paris', 'label': 'CET/CEST (Paris)'},
  {'value': 'Asia/Singapore', 'label': 'SGT (Singapore)'},
  {'value': 'Australia/Sydney', 'label': 'AEST/AEDT (Sydney)'},
];

const List<Map<String, String>> REMINDER_OPTIONS = [
  {'value': 'none', 'label': 'No reminder'},
  {'value': '30min', 'label': '30 minutes before'},
  {'value': '1hr', 'label': '1 hour before'},
  {'value': '1day', 'label': '1 day before'},
];

const List<Map<String, String>> DURATION_OPTIONS = [
  {'value': '30', 'label': '30 minutes'},
  {'value': '60', 'label': '1 hour'},
  {'value': '90', 'label': '1.5 hours'},
  {'value': '120', 'label': '2 hours'},
  {'value': '180', 'label': '3 hours'},
];

class AdminCalendarScreen extends StatefulWidget {
  final String? token;
  final String? companyId;
  final String? userId;

  const AdminCalendarScreen({
    super.key,
    this.token,
    this.companyId,
    this.userId,
  });

  @override
  State<AdminCalendarScreen> createState() => _AdminCalendarScreenState();
}

class _AdminCalendarScreenState extends State<AdminCalendarScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _currentDate;
  DateTime? _selectedDate;
  String? _activeToken;
  late TabController _tabController;
  String _viewMode = 'month'; // 'month', 'week', 'day'
  bool _showAddMenu = false;
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'holiday', 'leave', 'event', 'meeting'
  final TextEditingController _searchController = TextEditingController();
  
  // Source filtering for search
  bool _showEvents = true;
  bool _showTasks = true;
  bool _showFollowups = true;

  // Timezone and Reminder settings
  String _selectedTimezone = 'Asia/Kolkata';
  String _selectedReminder = 'none';
  String _selectedDuration = '60';  // in minutes

  DateTime get _rangeStart => DateTime(_currentDate.year, _currentDate.month, 1);
  DateTime get _rangeEnd => DateTime(_currentDate.year, _currentDate.month + 1, 0);

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _selectedDate = DateTime.now();
    _tabController = TabController(length: 5, vsync: this);
    
    // Fetch calendar data
    Future.microtask(() async {
      _activeToken = widget.token ?? await TokenStorageService().getToken();
      final notifier = context.read<CalendarNotifier>();
      print('[CALENDAR API] initState: Starting to fetch calendar data...');
      print('[CALENDAR API] initState: Token: ${_activeToken != null}, CompanyId: ${widget.companyId}, UserId: ${widget.userId}');
      
      // Check if we have required parameters
      if (_activeToken == null) {
        print('[CALENDAR API] ❌ ERROR: Token is null!');
        return;
      }
      
      bool hasDataSources = false;
      
      // Fetch holidays if we have company ID
      if (widget.companyId != null && widget.companyId!.isNotEmpty) {
        hasDataSources = true;
        print('[CALENDAR API] Fetching holidays for company: ${widget.companyId}, Month: ${_currentDate.month}/${_currentDate.year}');
        notifier.fetchHolidays(
          _activeToken!,
          widget.companyId!,
          _currentDate.year,
          _currentDate.month,
        );
      } else {
        print('[CALENDAR API] ⚠️ WARNING: CompanyId is missing, skipping holidays fetch');
      }
      
      // Fetch events if we have user ID
      if (widget.userId != null && widget.userId!.isNotEmpty) {
        hasDataSources = true;
        print('[CALENDAR API] Fetching events for user: ${widget.userId}, From: ${_currentDate.month}/${_currentDate.year}');
        notifier.fetchEvents(
          _activeToken!,
          widget.userId!,
          _rangeStart,
          _rangeEnd,
        );
      } else {
        print('[CALENDAR API] ⚠️ WARNING: UserId is missing, skipping events fetch');
      }
      
      // If no API calls were made, log the issue
      if (!hasDataSources) {
        print('[CALENDAR API] ❌ ERROR: No data sources available (missing companyId and userId)');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Build search and filter panel
  Widget _buildSearchFilterPanel() {
    return Consumer<CalendarNotifier>(
      builder: (context, calendarNotifier, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 8 : 12,
          ),
          child: isSmallScreen
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Events button
                    FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Events',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ],
                      ),
                      selected: _showEvents,
                      onSelected: (selected) {
                        setState(() => _showEvents = selected);
                      },
                      backgroundColor: AppTheme.surfaceVariant.withOpacity(0.5),
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: _showEvents ? Colors.white : Colors.grey[400],
                      ),
                      side: BorderSide(
                        color: _showEvents
                            ? AppTheme.primaryColor
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    // Tasks button
                    FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.assignment, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Tasks',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ],
                      ),
                      selected: _showTasks,
                      onSelected: (selected) {
                        setState(() => _showTasks = selected);
                      },
                      backgroundColor: AppTheme.surfaceVariant.withOpacity(0.5),
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: _showTasks ? Colors.white : Colors.grey[400],
                      ),
                      side: BorderSide(
                        color: _showTasks
                            ? AppTheme.primaryColor
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    // Follow-ups button
                    FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.checklist, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Follow-ups',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ],
                      ),
                      selected: _showFollowups,
                      onSelected: (selected) {
                        setState(() => _showFollowups = selected);
                      },
                      backgroundColor: AppTheme.surfaceVariant.withOpacity(0.5),
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: _showFollowups ? Colors.white : Colors.grey[400],
                      ),
                      side: BorderSide(
                        color: _showFollowups
                            ? AppTheme.primaryColor
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Events button
                    Expanded(
                      child: FilterChip(
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'Events',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        selected: _showEvents,
                        onSelected: (selected) {
                          setState(() => _showEvents = selected);
                        },
                        backgroundColor: AppTheme.surfaceVariant.withOpacity(0.5),
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: _showEvents ? Colors.white : Colors.grey[400],
                        ),
                        side: BorderSide(
                          color: _showEvents
                              ? AppTheme.primaryColor
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tasks button
                    Expanded(
                      child: FilterChip(
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.assignment, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'Tasks',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        selected: _showTasks,
                        onSelected: (selected) {
                          setState(() => _showTasks = selected);
                        },
                        backgroundColor: AppTheme.surfaceVariant.withOpacity(0.5),
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: _showTasks ? Colors.white : Colors.grey[400],
                        ),
                        side: BorderSide(
                          color: _showTasks
                              ? AppTheme.primaryColor
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Follow-ups button
                    Expanded(
                      child: FilterChip(
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.checklist, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'Follow-ups',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        selected: _showFollowups,
                        onSelected: (selected) {
                          setState(() => _showFollowups = selected);
                        },
                        backgroundColor: AppTheme.surfaceVariant.withOpacity(0.5),
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: _showFollowups ? Colors.white : Colors.grey[400],
                        ),
                        side: BorderSide(
                          color: _showFollowups
                              ? AppTheme.primaryColor
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  List<DateTime> _getDaysInMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    
    List<DateTime> days = [];
    
    // Add empty days at the start for alignment
    for (int i = firstDay.weekday; i > 1; i--) {
      days.add(firstDay.subtract(Duration(days: i - 1)));
    }
    
    // Add all days of the month
    for (int i = 0; i < lastDay.day; i++) {
      days.add(DateTime(date.year, date.month, i + 1));
    }
    
    // Add empty days at the end for alignment
    int remainingDays = (42 - days.length); // 6 weeks * 7 days
    for (int i = 1; i <= remainingDays; i++) {
      days.add(lastDay.add(Duration(days: i)));
    }
    
    return days;
  }

  void _refreshCalendarForCurrentRange() {
    Future.microtask(() {
      final notifier = context.read<CalendarNotifier>();
      if (_activeToken != null && widget.companyId != null) {
        notifier.fetchHolidays(
          _activeToken!,
          widget.companyId!,
          _currentDate.year,
          _currentDate.month,
        );
      }
      if (_activeToken != null && widget.userId != null) {
        notifier.fetchEvents(
          _activeToken!,
          widget.userId!,
          _rangeStart,
          _rangeEnd,
        );
      }
    });
  }

  void _previousMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
      _selectedDate = null;
      print('[CALENDAR] Month changed to: ${_currentDate.month}/${_currentDate.year}');
    });

    _refreshCalendarForCurrentRange();
  }

  void _nextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
      _selectedDate = null;
      print('[CALENDAR] Month changed to: ${_currentDate.month}/${_currentDate.year}');
    });

    _refreshCalendarForCurrentRange();
  }

  void _today() {
    setState(() {
      _currentDate = DateTime.now();
      _selectedDate = DateTime.now();
      print('[CALENDAR] Navigated to today: ${DateTime.now().month}/${DateTime.now().year}');
    });
    _refreshCalendarForCurrentRange();
  }

  void _previousWeek() {
    setState(() {
      _currentDate = _currentDate.subtract(const Duration(days: 7));
      _selectedDate = _selectedDate?.subtract(const Duration(days: 7));
    });
    _refreshCalendarForCurrentRange();
  }

  void _nextWeek() {
    setState(() {
      _currentDate = _currentDate.add(const Duration(days: 7));
      _selectedDate = _selectedDate?.add(const Duration(days: 7));
    });
    _refreshCalendarForCurrentRange();
  }

  void _previousDay() {
    final base = _selectedDate ?? _currentDate;
    final next = base.subtract(const Duration(days: 1));
    setState(() {
      _selectedDate = next;
      _currentDate = next;
    });
    _refreshCalendarForCurrentRange();
  }

  void _nextDay() {
    final base = _selectedDate ?? _currentDate;
    final next = base.add(const Duration(days: 1));
    setState(() {
      _selectedDate = next;
      _currentDate = next;
    });
    _refreshCalendarForCurrentRange();
  }

  String _normalizeDeleteId(String rawId) {
    final id = rawId.trim();
    const prefixes = ['task-', 'followup-', 'meeting-', 'document-', 'deadline-'];
    for (final prefix in prefixes) {
      if (id.startsWith(prefix) && id.length > prefix.length) {
        return id.substring(prefix.length);
      }
    }
    return id;
  }

  String? _extractObjectId(String rawId) {
    final normalized = _normalizeDeleteId(rawId);
    final match = RegExp(r'([a-fA-F0-9]{24})').firstMatch(normalized);
    return match?.group(1);
  }

  bool _isObjectId(String id) {
    return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(id);
  }

  // Delete event functionality
  void _deleteEvent(CalendarEvent event, CalendarNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Delete Event'),
        content: Text(
          'Are you sure you want to delete "${event.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_activeToken == null || _activeToken!.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Session expired. Please login again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Deleting event...')),
              );

              final rawId = event.id;
              final normalizedId = _normalizeDeleteId(rawId);
              final objectId = _extractObjectId(rawId);
              final itemType = (event.type ?? '').toLowerCase().trim();

              bool success = false;

              if (itemType == 'task' || rawId.startsWith('task-')) {
                try {
                  final taskId = objectId ?? normalizedId;
                  if (!_isObjectId(taskId)) {
                    throw Exception('Invalid task id');
                  }
                  await TaskService.deleteTask(_activeToken!, taskId);
                  success = true;
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete task: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }
              } else {
                // Non-calendar aggregated sources should not hit calendar delete endpoint.
                if (rawId.startsWith('followup-') ||
                    rawId.startsWith('document-') ||
                    rawId.startsWith('deadline-')) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This item cannot be deleted from calendar.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }

                final eventId = objectId ?? normalizedId;
                if (!_isObjectId(eventId)) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This item cannot be deleted from calendar.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }
                success = await notifier.deleteEvent(_activeToken!, eventId);
              }

              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Event deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  if (widget.userId != null) {
                    await notifier.fetchEvents(
                      _activeToken!,
                      widget.userId!,
                      _rangeStart,
                      _rangeEnd,
                    );
                  }
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(notifier.state.error ?? 'Failed to delete event'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Edit event functionality
  void _editEvent(CalendarEvent event) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        token: _activeToken,
        userId: widget.userId,
        initialDate: event.date,
        initialType: event.type ?? 'event',
      ),
    );
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully')),
      );
    }
  }

  // Export calendar to CSV
  void _exportCalendar(List<CalendarEvent> events, List<CalendarEvent> holidays) {
    final allEvents = [...events, ...holidays];
    if (allEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No events to export')),
      );
      return;
    }

    // Create CSV content
    StringBuffer csv = StringBuffer();
    csv.writeln('Title,Type,Date,Start Time,End Time,Description,Status,Priority');

    for (var event in allEvents) {
      final startTime = event.startTime != null
          ? DateFormat('HH:mm').format(event.startTime!)
          : 'All Day';
      final endTime = event.endTime != null
          ? DateFormat('HH:mm').format(event.endTime!)
          : '';
      
      csv.writeln(
        '"${event.title}","${event.type}","${DateFormat('yyyy-MM-dd').format(event.date)}",'
        '"$startTime","$endTime","${event.description}","${event.status ?? 'N/A'}",'
        '"${event.priority ?? 'N/A'}"',
      );
    }

    // TODO: Save to file or share
    print('[EXPORT] Calendar export:\n${csv.toString()}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported ${allEvents.length} events')),
    );
  }

  Future<void> _openAddEventDialog({String initialType = 'event'}) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        token: _activeToken,
        userId: widget.userId,
        initialDate: _selectedDate ?? DateTime.now(),
        initialType: initialType,
      ),
    );

    if (result == true && mounted && _activeToken != null && widget.userId != null) {
      final notifier = context.read<CalendarNotifier>();
      notifier.fetchEvents(
        _activeToken!,
        widget.userId!,
        _rangeStart,
        _rangeEnd,
      );
    }
  }

  Future<void> _openAddMeetingDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddMeetingDialog(
        token: _activeToken,
        userId: widget.userId,
        initialDate: _selectedDate ?? DateTime.now(),
      ),
    );

    if (result != null && mounted && _activeToken != null && widget.userId != null) {
      final notifier = context.read<CalendarNotifier>();
      notifier.fetchEvents(
        _activeToken!,
        widget.userId!,
        _rangeStart,
        _rangeEnd,
      );
    }
  }

  List<CalendarEvent> _applySourceFilters(List<CalendarEvent> events) {
    final filtered = events.where((e) {
      final type = (e.type ?? '').toLowerCase().trim();
      if (type == 'task') return _showTasks;
      if (type == 'follow-up' || type == 'follow_up' || type == 'followup') {
        return _showFollowups;
      }
      return _showEvents;
    }).toList();
    
    final tasksBefore = events.where((e) => e.type == 'task').length;
    final tasksAfter = filtered.where((e) => e.type == 'task').length;
    print('[CALENDAR FILTER] Source filters applied - Tasks before: $tasksBefore, after: $tasksAfter (_showTasks: $_showTasks)');
    
    return filtered;
  }

  // Filter events based on search and type
  List<CalendarEvent> _filterEvents(
    List<CalendarEvent> events,
    List<CalendarEvent> holidays,
  ) {
    List<CalendarEvent> combined = [...events, ...holidays];

    // Apply source filters (aligned with web UniversalCalendarModule)
    combined = combined.where((e) {
      final type = (e.type ?? '').toLowerCase().trim();
      if (type == 'task') return _showTasks;
      if (type == 'follow-up' || type == 'follow_up' || type == 'followup') {
        return _showFollowups;
      }
      // Everything else is treated as events source
      return _showEvents;
    }).toList();

    // Apply type filter
    if (_filterType != 'all') {
      combined = combined.where((e) {
        final type = (e.type ?? '').toLowerCase().trim();
        if (_filterType == 'follow-up') {
          return type == 'follow-up' || type == 'follow_up' || type == 'followup';
        }
        return type == _filterType;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      combined = combined.where((e) {
        final query = _searchQuery.toLowerCase();
        return e.title.toLowerCase().contains(query) ||
            e.description.toLowerCase().contains(query);
      }).toList();
    }

    return combined;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isSmallMobile = MediaQuery.of(context).size.width < 480;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calendar',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage events and schedules',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          indicatorPadding: EdgeInsets.zero,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey[600],
          isScrollable: false,
          labelPadding: EdgeInsets.symmetric(horizontal: 12),
          tabs: const [
            Tab(text: 'Month View', icon: Icon(Icons.calendar_view_month)),
            Tab(text: 'Week View', icon: Icon(Icons.calendar_view_week)),
            Tab(text: 'Day View', icon: Icon(Icons.calendar_view_day)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchFilterPanel(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
            // Tab 1: Month View
            Consumer<CalendarNotifier>(
              builder: (context, calendarNotifier, _) {
                final calendarState = calendarNotifier.state;
                final visibleEvents = _applySourceFilters(calendarState.events);
                final isLoading = calendarState.isLoading;

                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallMobile ? 12 : 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Loading indicator
                        if (isLoading)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.primaryColor),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Loading calendar data...',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Error message
                        if (calendarState.error != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.errorColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppTheme.errorColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Error Loading Calendar',
                                        style: TextStyle(
                                          color: AppTheme.errorColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        calendarState.error!,
                                        style: const TextStyle(
                                          color: AppTheme.errorColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    print('[CALENDAR] Error dismissed by user');
                                    calendarNotifier.clearError();
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    color: AppTheme.errorColor,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Main calendar card
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          child: Column(
                            children: [
                              // Month/Year header with navigation
                              _buildMonthHeader(),
                              const SizedBox(height: 24),

                              // Weekday labels
                              _buildWeekdayLabels(isMobile),
                              const SizedBox(height: 12),

                              // Calendar grid
                              _buildCalendarGrid(
                                isMobile,
                                calendarState.copyWith(events: visibleEvents),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Selected date info
                        if (_selectedDate != null)
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.event_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Selected: ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Events on selected date
                                ..._getEventsForDate(
                                  _selectedDate!,
                                  visibleEvents,
                                  calendarState.holidays,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Tab 2: Week View
            Consumer<CalendarNotifier>(
              builder: (context, calendarNotifier, _) {
                final calendarState = calendarNotifier.state;
                final visibleEvents = _applySourceFilters(calendarState.events);
                return WeekView(
                  currentDate: _currentDate,
                  events: visibleEvents,
                  holidays: calendarState.holidays,
                  onDateSelected: (date) {
                    setState(() => _selectedDate = date);
                  },
                  onPreviousWeek: _previousWeek,
                  onNextWeek: _nextWeek,
                  onToday: _today,
                  onEventTap: (event) => _showViewEventDialog(event, calendarNotifier),
                );
              },
            ),

            // Tab 3: Day View
            Consumer<CalendarNotifier>(
              builder: (context, calendarNotifier, _) {
                final calendarState = calendarNotifier.state;
                final visibleEvents = _applySourceFilters(calendarState.events);
                final selectedDate = _selectedDate ?? DateTime.now();
                return DayView(
                  selectedDate: selectedDate,
                  events: visibleEvents,
                  holidays: calendarState.holidays,
                  onPreviousDay: _previousDay,
                  onNextDay: _nextDay,
                  onToday: _today,
                  onEventTap: (event) => _showViewEventDialog(event, calendarNotifier),
                );
              },
            ),
              ],
            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final choice = await showModalBottomSheet<String>(
            context: context,
            backgroundColor: AppTheme.cardColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.event, color: Colors.blue),
                    title: const Text('Add Event', style: TextStyle(color: Colors.white)),
                    onTap: () => Navigator.pop(context, 'event'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.videocam, color: Colors.purple),
                    title: const Text('Add Meeting', style: TextStyle(color: Colors.white)),
                    onTap: () => Navigator.pop(context, 'meeting'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );

          if (choice == 'meeting') {
            await _openAddMeetingDialog();
          } else if (choice == 'event') {
            await _openAddEventDialog(initialType: 'event');
          }
        },
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Add'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildEventTypeChip(String type) {
    final colors = {
      'holiday': (Colors.red, Colors.white),
      'leave': (Colors.orange, Colors.white),
      'event': (Colors.blue, Colors.white),
      'meeting': (Colors.purple, Colors.white),
      'task': (Colors.lightBlue, Colors.white),
      'follow-up': (Colors.amber, Colors.black),
      'deadline': (Colors.redAccent, Colors.white),
      'reminder': (Colors.teal, Colors.white),
      'document-approval': (Colors.cyan, Colors.black),
    };

    final (bgColor, textColor) = colors[type] ?? (Colors.grey, Colors.white);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Previous button
        IconButton(
          onPressed: _previousMonth,
          icon: const Icon(Icons.chevron_left_rounded, size: 20),
          color: AppTheme.primaryColor,
          tooltip: 'Previous month',
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.surfaceVariant.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: EdgeInsets.zero,
          ),
        ),

        // Month/Year text - centered
        Expanded(
          child: Center(
            child: Text(
              DateFormat('MMMM yyyy').format(_currentDate),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),

        // Next button
        IconButton(
          onPressed: _nextMonth,
          icon: const Icon(Icons.chevron_right_rounded, size: 20),
          color: AppTheme.primaryColor,
          tooltip: 'Next month',
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.surfaceVariant.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels(bool isMobile) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.5,
        mainAxisSpacing: 0,
        crossAxisSpacing: 8,
      ),
      itemCount: 7,
      itemBuilder: (context, index) {
        return Center(
          child: Text(
            weekdays[index],
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarGrid(bool isMobile, CalendarState calendarState) {
    final days = _getDaysInMonth(_currentDate);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final isCurrentMonth = day.month == _currentDate.month;
        final isToday = day.year == DateTime.now().year &&
            day.month == DateTime.now().month &&
            day.day == DateTime.now().day;
        final isSelected = _selectedDate != null &&
            day.year == _selectedDate!.year &&
            day.month == _selectedDate!.month &&
            day.day == _selectedDate!.day;

        // Check if there are events/holidays on this day
        final eventsOnDay = calendarState.events
            .where((e) =>
                e.date.year == day.year &&
                e.date.month == day.month &&
                e.date.day == day.day)
            .toList();
        final holidaysOnDay = calendarState.holidays
            .where((h) =>
                h.date.year == day.year &&
                h.date.month == day.month &&
                h.date.day == day.day)
            .toList();

        final totalEvents = eventsOnDay.length + holidaysOnDay.length;
        final hasHoliday = holidaysOnDay.isNotEmpty;

        return GestureDetector(
          onTap: isCurrentMonth
              ? () {
                  setState(() => _selectedDate = day);
                  print('[CALENDAR] Date selected: ${day.day}/${day.month}/${day.year}');
                  if (eventsOnDay.isNotEmpty || holidaysOnDay.isNotEmpty) {
                    print('[CALENDAR] Selected date has ${eventsOnDay.length} events and ${holidaysOnDay.length} holidays');
                  }
                  // Day detail bottom sheet removed per user request.
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor
                  : isToday
                      ? AppTheme.primaryColor.withOpacity(0.12)
                      : isCurrentMonth
                          ? Colors.transparent
                          : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isToday && !isSelected
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Day number
                Center(
                  child: Text(
                    day.day.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isCurrentMonth
                              ? Colors.white
                              : Colors.grey[700],
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: isToday || isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
                // Event/Holiday indicators
                if (totalEvents > 0)
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(
                          (totalEvents > 3 ? 3 : totalEvents),
                          (i) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1.5),
                            child: Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: hasHoliday
                                    ? Colors.red.withOpacity(0.8)
                                    : Colors.blue.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Get all events and holidays for a specific date
  List<Widget> _getEventsForDate(
    DateTime date,
    List<CalendarEvent> events,
    List<CalendarEvent> holidays,
  ) {
    final eventsOnDate = events
        .where((e) =>
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day)
        .toList();

    final holidaysOnDate = holidays
        .where((h) =>
            h.date.year == date.year &&
            h.date.month == date.month &&
            h.date.day == date.day)
        .toList();

    final taskCount = eventsOnDate.where((e) => e.type == 'task').length;
    print('[CALENDAR] Getting events for date: ${date.day}/${date.month}/${date.year} - Events: ${eventsOnDate.length} (Tasks: $taskCount), Holidays: ${holidaysOnDate.length}');

    if (eventsOnDate.isEmpty && holidaysOnDate.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.event_busy,
                color: Colors.grey[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'No events scheduled',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return [
      // Holidays
      ...holidaysOnDate.map((holiday) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () {
              final notifier = context.read<CalendarNotifier>();
              _showViewEventDialog(holiday, notifier);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.celebration_rounded,
                    size: 14,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          holiday.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (holiday.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              holiday.description,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
      // Events
      ...eventsOnDate.map((event) {
        final eventColor = _getEventColor(event.type);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () {
              final notifier = context.read<CalendarNotifier>();
              _showViewEventDialog(event, notifier);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: eventColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: eventColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getEventIcon(event.type),
                    size: 14,
                    color: eventColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (event.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              event.description,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (event.allDay)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'All day',
                              style: TextStyle(
                                color: eventColor.withValues(alpha: 0.7),
                                fontSize: 9,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ];
  }

  /// Get event color based on type
  Color _getEventColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'holiday':
        return Colors.red;
      case 'leave':
        return Colors.orange;
      case 'task':
        return Colors.blue;
      case 'meeting':
      case 'event':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  /// Get event icon based on type
  IconData _getEventIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'holiday':
        return Icons.celebration_rounded;
      case 'leave':
        return Icons.beach_access_rounded;
      case 'task':
        return Icons.assignment_rounded;
      case 'meeting':
        return Icons.videocam_rounded;
      case 'event':
        return Icons.event_note_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // View Event Dialog - Display full event details with actions
  // ─────────────────────────────────────────────────────────────────
  void _showViewEventDialog(CalendarEvent event, CalendarNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final isMobile = screenSize.width < 600;
        final dialogWidth = isMobile 
            ? screenSize.width * 0.9 
            : screenSize.width * 0.6;
        
        // Responsive font sizes
        final titleFontSize = isMobile ? 18.0 : 20.0;
        final labelFontSize = isMobile ? 11.0 : 12.0;
        final valueFontSize = isMobile ? 13.0 : 14.0;
        final badgeFontSize = isMobile ? 10.0 : 11.0;
        
        // Responsive padding
        final headerPadding = isMobile ? 16.0 : 20.0;
        final contentPadding = isMobile ? 16.0 : 20.0;
        final buttonPadding = isMobile ? 12.0 : 16.0;
        
        // Responsive spacing
        final rowSpacing = isMobile ? 8.0 : 12.0;
        final sectionSpacing = isMobile ? 12.0 : 16.0;
        
        return Dialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 40,
            vertical: isMobile ? 24 : 40,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? dialogWidth : double.infinity,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with colored border
                  Container(
                    decoration: BoxDecoration(
                      color: _getEventColor(event.type).withValues(alpha: 0.08),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: _getEventColor(event.type),
                          width: 3,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.all(headerPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with icon
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getEventColor(event.type),
                              ),
                            ),
                            SizedBox(width: isMobile ? 10 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: isMobile ? 3 : 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: isMobile ? 8 : 10),
                                  // Badges
                                  Wrap(
                                    spacing: isMobile ? 6 : 8,
                                    runSpacing: isMobile ? 4 : 6,
                                    children: [
                                      // Type badge
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isMobile ? 8 : 10,
                                          vertical: isMobile ? 3 : 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getEventColor(event.type),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          event.type?.toUpperCase() ?? 'EVENT',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: badgeFontSize,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      // Status badge
                                      if (event.status != null)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isMobile ? 8 : 10,
                                            vertical: isMobile ? 3 : 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(event.status).withValues(alpha: 0.8),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            event.status!.toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: badgeFontSize,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      // Priority badge
                                      if (event.priority != null)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isMobile ? 8 : 10,
                                            vertical: isMobile ? 3 : 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getPriorityColor(event.priority).withValues(alpha: 0.8),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            event.priority!.toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: badgeFontSize,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Content section
                  Padding(
                    padding: EdgeInsets.all(contentPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date and time section
                        _buildDetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date',
                          value: DateFormat('EEEE, MMMM d, yyyy').format(event.date),
                          labelFontSize: labelFontSize,
                          valueFontSize: valueFontSize,
                          spacing: rowSpacing,
                        ),
                        SizedBox(height: rowSpacing),

                        // Time range
                        if (event.startTime != null || event.endTime != null) ...[
                          _buildDetailRow(
                            icon: Icons.access_time_outlined,
                            label: 'Time',
                            value: _formatTimeRange(event.startTime, event.endTime, event.allDay),
                            labelFontSize: labelFontSize,
                            valueFontSize: valueFontSize,
                            spacing: rowSpacing,
                          ),
                          SizedBox(height: rowSpacing),
                        ],

                        // Created By
                        if (event.createdBy != null && event.createdBy!.isNotEmpty) ...[
                          _buildDetailRow(
                            icon: Icons.person_add_outlined,
                            label: 'Created By',
                            value: event.createdBy!,
                            labelFontSize: labelFontSize,
                            valueFontSize: valueFontSize,
                            spacing: rowSpacing,
                          ),
                          SizedBox(height: rowSpacing),
                        ],

                        // Assigned To
                        if (event.assignedTo != null && event.assignedTo!.isNotEmpty) ...[
                          _buildDetailRow(
                            icon: Icons.assignment_ind_outlined,
                            label: 'Assigned To',
                            value: event.assignedTo!,
                            labelFontSize: labelFontSize,
                            valueFontSize: valueFontSize,
                            spacing: rowSpacing,
                          ),
                          SizedBox(height: rowSpacing),
                        ],

                        // Description
                        if (event.description.isNotEmpty) ...[
                          Text(
                            'Description',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: labelFontSize,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: isMobile ? 6 : 8),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isMobile ? 10 : 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[900]?.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[700]!.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              event.description,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: valueFontSize,
                                height: 1.5,
                              ),
                            ),
                          ),
                          SizedBox(height: sectionSpacing),
                        ],

                        // Meeting URL
                        if (event.meetingUrl != null && event.meetingUrl!.isNotEmpty)
                          _buildDetailRow(
                            icon: Icons.video_call_outlined,
                            label: 'Meeting',
                            value: event.meetingUrl!,
                            isLink: true,
                            labelFontSize: labelFontSize,
                            valueFontSize: valueFontSize,
                            spacing: rowSpacing,
                          ),

                        // Participants
                        if (event.participants != null && event.participants!.isNotEmpty) ...[
                          SizedBox(height: sectionSpacing),
                          Text(
                            'Participants (${event.participants!.length})',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: labelFontSize,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: isMobile ? 6 : 8),
                          Wrap(
                            spacing: isMobile ? 4 : 6,
                            runSpacing: isMobile ? 4 : 6,
                            children: event.participants!
                                .map((participant) => Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 8 : 10,
                                    vertical: isMobile ? 4 : 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800]?.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey[700]!.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    participant,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: valueFontSize - 1,
                                    ),
                                  ),
                                ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Action buttons
                  Padding(
                    padding: EdgeInsets.fromLTRB(buttonPadding, isMobile ? 8 : 8, buttonPadding, buttonPadding),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 8,
                            children: [
                              if (event.status != 'completed')
                                FilledButton.icon(
                                  onPressed: () {
                                    _markEventComplete(event, notifier);
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.check_circle, size: 18),
                                  label: const Text('Complete'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                  ),
                                ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _editEvent(event);
                                },
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Edit'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteEvent(event, notifier);
                                },
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                label: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (event.status != 'completed')
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      _markEventComplete(event, notifier);
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(Icons.check_circle, size: 18),
                                    label: const Text('Complete'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                    ),
                                  ),
                                ),
                              if (event.status != 'completed') const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _editEvent(event);
                                  },
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Edit'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteEvent(event, notifier);
                                  },
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper to build detail rows in view dialog
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLink = false,
    double labelFontSize = 12,
    double valueFontSize = 14,
    double spacing = 12,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        SizedBox(width: spacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: isLink ? AppTheme.primaryColor : Colors.white,
                  fontSize: valueFontSize,
                  decoration: isLink ? TextDecoration.underline : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Format time range
  String _formatTimeRange(DateTime? start, DateTime? end, bool allDay) {
    if (allDay) return 'All Day';
    if (start == null && end == null) return 'No specific time';
    
    final startStr = start != null ? DateFormat('HH:mm').format(start) : '';
    final endStr = end != null ? DateFormat('HH:mm').format(end) : '';
    
    if (startStr.isNotEmpty && endStr.isNotEmpty) {
      return '$startStr - $endStr';
    }
    return startStr.isNotEmpty ? startStr : endStr;
  }

  // Get color for status
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'in-progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get color for priority
  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'low':
        return Colors.grey;
      case 'medium':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Mark event as complete
  Future<void> _markEventComplete(CalendarEvent event, CalendarNotifier notifier) async {
    if (_activeToken == null || _activeToken!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final rawId = event.id;
    final normalizedId = _normalizeDeleteId(rawId);
    final objectId = _extractObjectId(rawId);
    final itemType = (event.type ?? '').toLowerCase().trim();

    bool success = false;

    if (itemType == 'task' || rawId.startsWith('task-')) {
      try {
        final taskId = objectId ?? normalizedId;
        if (!_isObjectId(taskId)) {
          throw Exception('Invalid task id');
        }
        await TaskService.updateTaskStatus(_activeToken!, taskId, 'completed');
        success = true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to complete task: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } else {
      if (rawId.startsWith('followup-') ||
          rawId.startsWith('document-') ||
          rawId.startsWith('deadline-')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This item cannot be completed from calendar.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final eventId = objectId ?? normalizedId;
      if (!_isObjectId(eventId)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid item id for complete action.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      success = await notifier.markEventComplete(_activeToken!, eventId);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ "${event.title}" marked as complete'),
          backgroundColor: Colors.green[600],
        ),
      );

      if (widget.userId != null) {
        await notifier.fetchEvents(
          _activeToken!,
          widget.userId!,
          _rangeStart,
          _rangeEnd,
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Day Detail Panel - Show BOD/EOD logs and day summary
  // ─────────────────────────────────────────────────────────────────
  void _showDayDetailPanel(DateTime selectedDate, CalendarNotifier notifier) {
    final events = _applySourceFilters(notifier.state.events)
        .where((e) =>
            e.date.year == selectedDate.year &&
            e.date.month == selectedDate.month &&
            e.date.day == selectedDate.day)
        .toList();

    final holidays = notifier.state.holidays
        .where((h) =>
            h.date.year == selectedDate.year &&
            h.date.month == selectedDate.month &&
            h.date.day == selectedDate.day)
        .toList();

    final meetings =
        events.where((e) => e.type == 'meeting').toList();
    final tasks =
        events.where((e) => e.type == 'task').toList();
    final otherEvents = events
        .where((e) => e.type != 'meeting' && e.type != 'task')
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day title
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Holidays section
                    if (holidays.isNotEmpty) ...[
                      Text(
                        '🎉 Holidays',
                        style: TextStyle(
                          color: Colors.red[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...holidays.map((holiday) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Text(
                                holiday.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],

                    // Meetings section
                    if (meetings.isNotEmpty) ...[
                      Text(
                        '📞 Meetings (${meetings.length})',
                        style: TextStyle(
                          color: Colors.purple[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...meetings.map((meeting) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.purple.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meeting.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (meeting.startTime != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Time: ${DateFormat('HH:mm').format(meeting.startTime!)}',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  if (meeting.meetingUrl != null) ...[
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () {
                                        // TODO: Open meeting URL
                                        print(
                                            '[CALENDAR] Opening meeting URL: ${meeting.meetingUrl}');
                                      },
                                      child: Text(
                                        'Join Meet',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],

                    // Tasks section
                    if (tasks.isNotEmpty) ...[
                      Text(
                        '✓ Tasks (${tasks.length})',
                        style: TextStyle(
                          color: Colors.blue[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...tasks.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                task.status == 'completed'
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: task.status == 'completed'
                                    ? Colors.green
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    decoration: task.status == 'completed'
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                      const SizedBox(height: 16),
                    ],

                    // Other events section
                    if (otherEvents.isNotEmpty) ...[
                      Text(
                        '📅 Other Events (${otherEvents.length})',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...otherEvents.map((event) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getEventColor(event.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getEventColor(event.type).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )).toList(),
                      const SizedBox(height: 16),
                    ],

                    // No events
                    if (events.isEmpty && holidays.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 64,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No events scheduled for this day',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}