import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';
import 'package:hrms_app/features/admin/presentation/providers/calendar_provider.dart';
import 'package:hrms_app/features/admin/presentation/providers/calendar_notifier.dart';
import 'package:hrms_app/features/admin/presentation/providers/calendar_state.dart';
import 'package:intl/intl.dart';
import 'add_event_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _selectedDate = DateTime.now();
    _tabController = TabController(length: 5, vsync: this);
    
    // Fetch calendar data
    Future.microtask(() {
      final notifier = Provider.of<CalendarNotifier>(context, listen: false);
      print('[CALENDAR API] initState: Starting to fetch calendar data...');
      print('[CALENDAR API] initState: Token: ${widget.token != null}, CompanyId: ${widget.companyId}, UserId: ${widget.userId}');
      
      // Check if we have required parameters
      if (widget.token == null) {
        print('[CALENDAR API] ❌ ERROR: Token is null!');
        return;
      }
      
      bool hasDataSources = false;
      
      // Fetch holidays if we have company ID
      if (widget.companyId != null && widget.companyId!.isNotEmpty) {
        hasDataSources = true;
        print('[CALENDAR API] Fetching holidays for company: ${widget.companyId}, Month: ${_currentDate.month}/${_currentDate.year}');
        notifier.fetchHolidays(
          widget.token!,
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
          widget.token!,
          widget.userId!,
          _currentDate,
          DateTime(_currentDate.year, _currentDate.month + 1, 0),
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

  void _previousMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
      _selectedDate = null;
      print('[CALENDAR] Month changed to: ${_currentDate.month}/${_currentDate.year}');
    });
    
    // Fetch data for new month
    Future.microtask(() {
      final notifier = Provider.of<CalendarNotifier>(context, listen: false);
      if (widget.token != null && widget.companyId != null) {
        print('[CALENDAR API] Fetching holidays for previous month: ${_currentDate.month}/${_currentDate.year}');
        notifier.fetchHolidays(
          widget.token!,
          widget.companyId!,
          _currentDate.year,
          _currentDate.month,
        );
      }
      if (widget.token != null && widget.userId != null) {
        notifier.fetchEvents(
          widget.token!,
          widget.userId!,
          _currentDate,
          DateTime(_currentDate.year, _currentDate.month + 1, 0),
        );
      }
    });
  }

  void _nextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
      _selectedDate = null;
      print('[CALENDAR] Month changed to: ${_currentDate.month}/${_currentDate.year}');
    });
    
    // Fetch data for new month
    Future.microtask(() {
      final notifier = Provider.of<CalendarNotifier>(context, listen: false);
      if (widget.token != null && widget.companyId != null) {
        print('[CALENDAR API] Fetching holidays for next month: ${_currentDate.month}/${_currentDate.year}');
        notifier.fetchHolidays(
          widget.token!,
          widget.companyId!,
          _currentDate.year,
          _currentDate.month,
        );
      }
      if (widget.token != null && widget.userId != null) {
        notifier.fetchEvents(
          widget.token!,
          widget.userId!,
          _currentDate,
          DateTime(_currentDate.year, _currentDate.month + 1, 0),
        );
      }
    });
  }

  void _today() {
    setState(() {
      _currentDate = DateTime.now();
      _selectedDate = DateTime.now();
      print('[CALENDAR] Navigated to today: ${DateTime.now().month}/${DateTime.now().year}');
    });
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
            onPressed: () {
              // TODO: Call API to delete event
              // await notifier.deleteEvent(event.id, widget.token!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Event "${event.title}" deleted'),
                  backgroundColor: Colors.red,
                ),
              );
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
      builder: (context) => Dialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width < 768
                ? MediaQuery.of(context).size.width * 0.9
                : 500,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: AddEventDialog(
            token: widget.token,
            userId: widget.userId,
            initialDate: event.date,
          ),
        ),
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

  // Filter events based on search and type
  List<CalendarEvent> _filterEvents(
    List<CalendarEvent> events,
    List<CalendarEvent> holidays,
  ) {
    List<CalendarEvent> combined = [...events, ...holidays];

    // Apply type filter
    if (_filterType != 'all') {
      combined = combined.where((e) => e.type == _filterType).toList();
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
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey[600],
          isScrollable: true,
          tabs: const [
            Tab(text: 'Month View', icon: Icon(Icons.calendar_view_month)),
            Tab(text: 'Week View', icon: Icon(Icons.calendar_view_week)),
            Tab(text: 'Day View', icon: Icon(Icons.calendar_view_day)),
            Tab(text: 'Events', icon: Icon(Icons.list)),
            Tab(text: 'Search', icon: Icon(Icons.search)),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Month View
            Consumer<CalendarNotifier>(
              builder: (context, calendarNotifier, _) {
                final calendarState = calendarNotifier.state;
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
                              _buildCalendarGrid(isMobile, calendarState),
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
                                  calendarState.events,
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
                return WeekView(
                  currentDate: _currentDate,
                  events: calendarState.events,
                  holidays: calendarState.holidays,
                  onDateSelected: (date) {
                    setState(() => _selectedDate = date);
                  },
                  onPreviousWeek: _previousMonth,
                  onNextWeek: _nextMonth,
                  onToday: _today,
                );
              },
            ),

            // Tab 3: Day View
            Consumer<CalendarNotifier>(
              builder: (context, calendarNotifier, _) {
                final calendarState = calendarNotifier.state;
                final selectedDate = _selectedDate ?? DateTime.now();
                return DayView(
                  selectedDate: selectedDate,
                  events: calendarState.events,
                  holidays: calendarState.holidays,
                  onPreviousDay: _previousMonth,
                  onNextDay: _nextMonth,
                  onToday: _today,
                );
              },
            ),

            // Tab 4: Events List
            Consumer<CalendarNotifier>(
              builder: (context, calendarNotifier, _) {
                final calendarState = calendarNotifier.state;
                final allEvents = [
                  ...calendarState.events,
                  ...calendarState.holidays,
                ];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (allEvents.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_note,
                                  size: 64,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No events scheduled',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: allEvents.length,
                          itemBuilder: (context, index) {
                            final event = allEvents[index];
                            final isHoliday = event.type == 'holiday';

                            return GestureDetector(
                              onTap: () => _showViewEventDialog(event, calendarNotifier),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                color: AppTheme.cardColor,
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _getEventColor(event.type),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      title: Text(
                                        event.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('MMM d, yyyy').format(event.date),
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                          if (event.startTime != null)
                                            Text(
                                              DateFormat('HH:mm').format(event.startTime!),
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined,
                                                size: 18, color: AppTheme.primaryColor),
                                            onPressed: () => _editEvent(event),
                                            tooltip: 'Edit event',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline,
                                                size: 18, color: Colors.red),
                                            onPressed: () => _deleteEvent(event, calendarNotifier),
                                            tooltip: 'Delete event',
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Status and Priority badges
                                    if (event.status != null || event.priority != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Wrap(
                                          spacing: 8,
                                          children: [
                                            if (event.status != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(event.status)
                                                      .withOpacity(0.2),
                                                  border: Border.all(
                                                    color: _getStatusColor(event.status),
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  (event.status ?? '').toUpperCase(),
                                                  style: TextStyle(
                                                    color:
                                                        _getStatusColor(event.status),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            if (event.priority != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getPriorityColor(event.priority)
                                                      .withOpacity(0.2),
                                                  border: Border.all(
                                                    color:
                                                        _getPriorityColor(event.priority),
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  (event.priority ?? '').toUpperCase(),
                                                  style: TextStyle(
                                                    color: _getPriorityColor(
                                                        event.priority),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
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
                        ),
                    ],
                  ),
                );
              },
            ),

            // Tab 5: Search & Filter
            Consumer<CalendarNotifier>(
              builder: (context, calendarNotifier, _) {
                final calendarState = calendarNotifier.state;
                final filteredEvents = _filterEvents(
                  calendarState.events,
                  calendarState.holidays,
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search input
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search events...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.primaryColor),
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceVariant.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Type filter chips
                      Text(
                        'Filter by Type',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['all', 'event', 'meeting', 'holiday', 'leave'].map((type) {
                          final isSelected = _filterType == type;
                          return FilterChip(
                            label: Text(
                              type.toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[400],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _filterType = selected ? type : 'all');
                            },
                            backgroundColor: AppTheme.surfaceVariant.withOpacity(0.5),
                            selectedColor: AppTheme.primaryColor,
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.1),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Source filtering
                      Text(
                        'Filter by Source',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _showEvents,
                        onChanged: (value) {
                          setState(() => _showEvents = value ?? false);
                        },
                        title: const Text('Events', style: TextStyle(color: Colors.white)),
                        secondary: const Icon(Icons.event, color: AppTheme.primaryColor),
                        contentPadding: EdgeInsets.zero,
                        checkColor: Colors.white,
                        activeColor: AppTheme.primaryColor,
                      ),
                      CheckboxListTile(
                        value: _showTasks,
                        onChanged: (value) {
                          setState(() => _showTasks = value ?? false);
                        },
                        title: const Text('Tasks', style: TextStyle(color: Colors.white)),
                        secondary: const Icon(Icons.assignment, color: Colors.blue),
                        contentPadding: EdgeInsets.zero,
                        checkColor: Colors.white,
                        activeColor: Colors.blue,
                      ),
                      CheckboxListTile(
                        value: _showFollowups,
                        onChanged: (value) {
                          setState(() => _showFollowups = value ?? false);
                        },
                        title: const Text('Follow-ups', style: TextStyle(color: Colors.white)),
                        secondary: const Icon(Icons.checklist, color: Colors.orange),
                        contentPadding: EdgeInsets.zero,
                        checkColor: Colors.white,
                        activeColor: Colors.orange,
                      ),
                      const SizedBox(height: 24),

                      // Timezone selector
                      Text(
                        'Timezone',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(8),
                          color: AppTheme.surfaceVariant.withOpacity(0.3),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedTimezone,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() => _selectedTimezone = newValue);
                              print('[CALENDAR] Timezone changed to: $newValue');
                            }
                          },
                          isExpanded: true,
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: AppTheme.cardColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items: TIMEZONE_OPTIONS
                              .map<DropdownMenuItem<String>>((Map<String, String> option) {
                            return DropdownMenuItem<String>(
                              value: option['value']!,
                              child: Row(
                                children: [
                                  const Icon(Icons.public,
                                      size: 18, color: AppTheme.primaryColor),
                                  const SizedBox(width: 12),
                                  Text(
                                    option['label']!,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Results
                      Text(
                        'Results (${filteredEvents.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (filteredEvents.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No events found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredEvents.length,
                          itemBuilder: (context, index) {
                            final event = filteredEvents[index];
                            return GestureDetector(
                              onTap: () => _showViewEventDialog(event, calendarNotifier),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                color: AppTheme.cardColor,
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _getEventColor(event.type),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      title: Text(
                                        event.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateFormat('MMM d, yyyy')
                                                .format(event.date),
                                            style: TextStyle(
                                                color: Colors.grey[400]),
                                          ),
                                          if (event.description.isNotEmpty)
                                            Text(
                                              event.description,
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                      trailing: _buildEventTypeChip(
                                          event.type ?? 'event'),
                                    ),
                                    // Status and Priority badges
                                    if (event.status != null || event.priority != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Wrap(
                                          spacing: 8,
                                          children: [
                                            if (event.status != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                          event.status)
                                                      .withOpacity(0.2),
                                                  border: Border.all(
                                                    color: _getStatusColor(
                                                        event.status),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  (event.status ?? '')
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    color: _getStatusColor(
                                                        event.status),
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            if (event.priority != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getPriorityColor(
                                                          event.priority)
                                                      .withOpacity(0.2),
                                                  border: Border.all(
                                                    color:
                                                        _getPriorityColor(
                                                            event.priority),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  (event.priority ?? '')
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    color: _getPriorityColor(
                                                        event.priority),
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w600,
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
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: AppTheme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width < 768
                      ? MediaQuery.of(context).size.width * 0.9
                      : 500,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: AddEventDialog(
                  token: widget.token,
                  userId: widget.userId,
                  initialDate: _selectedDate ?? DateTime.now(),
                ),
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
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
                  // Show day detail panel
                  final notifier = Provider.of<CalendarNotifier>(context, listen: false);
                  _showDayDetailPanel(day, notifier);
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

    print('[CALENDAR] Getting events for date: ${date.day}/${date.month}/${date.year} - Events: ${eventsOnDate.length}, Holidays: ${holidaysOnDate.length}');

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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
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
        );
      }).toList(),
      // Events
      ...eventsOnDate.map((event) {
        final eventColor = _getEventColor(event.type);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: eventColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: eventColor.withOpacity(0.3)),
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
                              color: eventColor.withOpacity(0.7),
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
      builder: (context) => Dialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with type indicator
              Container(
                decoration: BoxDecoration(
                  color: _getEventColor(event.type).withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: _getEventColor(event.type),
                      width: 3,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getEventIcon(event.type),
                          color: _getEventColor(event.type),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getEventColor(event.type),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            event.type?.toUpperCase() ?? 'EVENT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(event.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (event.status ?? 'scheduled').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (event.priority != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(event.priority),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              event.priority!.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Content section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and time
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: DateFormat('EEEE, MMMM d, yyyy').format(event.date),
                    ),
                    const SizedBox(height: 16),

                    // Time
                    if (event.startTime != null || event.endTime != null)
                      _buildDetailRow(
                        icon: Icons.access_time,
                        label: 'Time',
                        value: _formatTimeRange(event.startTime, event.endTime, event.allDay),
                      ),
                    if (event.startTime != null || event.endTime != null)
                      const SizedBox(height: 16),

                    // Description
                    if (event.description.isNotEmpty) ...[
                      Text(
                        'Description',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.description,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Meeting URL
                    if (event.meetingUrl != null && event.meetingUrl!.isNotEmpty)
                      _buildDetailRow(
                        icon: Icons.link,
                        label: 'Meeting Link',
                        value: event.meetingUrl!,
                        isLink: true,
                      ),

                    if (event.meetingUrl != null && event.meetingUrl!.isNotEmpty)
                      const SizedBox(height: 16),

                    // Participants
                    if (event.participants != null && event.participants!.isNotEmpty) ...[
                      Text(
                        'Participants',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: event.participants!
                            .map((participant) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceVariant.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                participant,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Reminder settings
                    Text(
                      'Reminder',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.surfaceVariant.withOpacity(0.3),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedReminder,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() => _selectedReminder = newValue);
                            print('[CALENDAR] Reminder changed to: $newValue');
                          }
                        },
                        isExpanded: true,
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: AppTheme.cardColor,
                        items: REMINDER_OPTIONS
                            .map<DropdownMenuItem<String>>(
                                (Map<String, String> option) {
                              return DropdownMenuItem<String>(
                                value: option['value']!,
                                child: Row(
                                  children: [
                                    const Icon(Icons.notifications,
                                        size: 16, color: AppTheme.primaryColor),
                                    const SizedBox(width: 12),
                                    Text(option['label']!),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Duration settings (for meetings)
                    if (event.type == 'meeting') ...[
                      Text(
                        'Duration',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(8),
                          color: AppTheme.surfaceVariant.withOpacity(0.3),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedDuration,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() => _selectedDuration = newValue);
                              print('[CALENDAR] Duration changed to: $newValue minutes');
                            }
                          },
                          isExpanded: true,
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: AppTheme.cardColor,
                          items: DURATION_OPTIONS
                              .map<DropdownMenuItem<String>>(
                                  (Map<String, String> option) {
                                return DropdownMenuItem<String>(
                                  value: option['value']!,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.schedule,
                                          size: 16, color: AppTheme.primaryColor),
                                      const SizedBox(width: 12),
                                      Text(option['label']!),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mark complete button (if not completed)
                    if (event.status != 'completed')
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            _markEventComplete(event, notifier);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Mark Complete'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green[600],
                          ),
                        ),
                      ),
                    if (event.status != 'completed') const SizedBox(width: 8),
                    // Edit button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _editEvent(event);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteEvent(event, notifier);
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
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
  }

  // Helper to build detail rows in view dialog
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLink = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: isLink ? AppTheme.primaryColor : Colors.white,
                  fontSize: 14,
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
  void _markEventComplete(CalendarEvent event, CalendarNotifier notifier) {
    // TODO: Call API to update event status to 'completed'
    print('[CALENDAR] Marking event as complete: ${event.id}');
    print('[CALENDAR] Event: ${event.title}, Status: ${event.status} → completed');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ "${event.title}" marked as complete'),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Day Detail Panel - Show BOD/EOD logs and day summary
  // ─────────────────────────────────────────────────────────────────
  void _showDayDetailPanel(DateTime selectedDate, CalendarNotifier notifier) {
    final events = notifier.state.events
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
                            child: GestureDetector(
                              onTap: () => _showViewEventDialog(task, notifier),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.blue.withOpacity(0.3)),
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
                            ),
                          )),
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
                            child: GestureDetector(
                              onTap: () =>
                                  _showViewEventDialog(event, notifier),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getEventColor(event.type)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getEventColor(event.type)
                                        .withOpacity(0.3),
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
                            ),
                          )),
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