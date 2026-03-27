import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';
import 'package:hrms_app/features/admin/presentation/providers/calendar_provider.dart';
import 'package:hrms_app/features/admin/presentation/providers/calendar_notifier.dart';
import 'package:hrms_app/features/admin/presentation/providers/calendar_state.dart';
import 'package:intl/intl.dart';

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

class _AdminCalendarScreenState extends State<AdminCalendarScreen> {
  late DateTime _currentDate;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _selectedDate = DateTime.now();
    
    // Fetch calendar data
    Future.microtask(() {
      final notifier = Provider.of<CalendarNotifier>(context, listen: false);
      if (widget.token != null && widget.companyId != null) {
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

  /// Get all days in the current month
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
    });
  }

  void _nextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
    });
  }

  void _today() {
    setState(() {
      _currentDate = DateTime.now();
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Consumer<CalendarNotifier>(
      builder: (context, calendarNotifier, _) {
        final calendarState = calendarNotifier.state;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              child: Text(
                                calendarState.error!,
                                style: const TextStyle(
                                  color: AppTheme.errorColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => calendarNotifier.clearError(),
                              child: const Icon(
                                Icons.close,
                                color: AppTheme.errorColor,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Success message
                    if (calendarState.successMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.successColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: AppTheme.successColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                calendarState.successMessage!,
                                style: const TextStyle(
                                  color: AppTheme.successColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => calendarNotifier.clearSuccess(),
                              child: const Icon(
                                Icons.close,
                                color: AppTheme.successColor,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Calendar',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
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
                        ),
                        // Today button
                        ElevatedButton.icon(
                          onPressed: _today,
                          icon: const Icon(Icons.today_rounded, size: 16),
                          label: const Text('Today'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Calendar container
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
            ),
          ),
        );
      },
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
          icon: const Icon(Icons.chevron_left_rounded),
          color: AppTheme.primaryColor,
          tooltip: 'Previous month',
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
        ),

        // Month/Year text
        Expanded(
          child: Center(
            child: Text(
              DateFormat('MMMM yyyy').format(_currentDate),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Next button
        IconButton(
          onPressed: _nextMonth,
          icon: const Icon(Icons.chevron_right_rounded),
          color: AppTheme.primaryColor,
          tooltip: 'Next month',
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Colors.white.withOpacity(0.06),
              ),
            ),
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
        childAspectRatio: 1.2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: 7,
      itemBuilder: (context, index) {
        return Center(
          child: Text(
            weekdays[index],
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w500,
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
        childAspectRatio: 1.1,
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

        return GestureDetector(
          onTap: isCurrentMonth
              ? () => setState(() => _selectedDate = day)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor
                  : isToday
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isToday && !isSelected
                    ? AppTheme.primaryColor.withOpacity(0.5)
                    : Colors.transparent,
                width: 1.5,
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
                              : Colors.grey[600],
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: isToday || isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
                // Event indicators
                if (totalEvents > 0)
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            shape: BoxShape.circle,
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

    if (eventsOnDate.isEmpty && holidaysOnDate.isEmpty) {
      return [
        Text(
          'No events scheduled',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ];
    }

    return [
      // Holidays
      ...holidaysOnDate.map((holiday) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.holiday_village,
                  size: 14,
                  color: Colors.red,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    holiday.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      // Events
      ...eventsOnDate.map((event) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_note,
                  size: 14,
                  color: Colors.blue,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ];
  }
}

