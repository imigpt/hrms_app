import 'package:flutter/material.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';
import 'package:hrms_app/features/admin/presentation/providers/calendar_state.dart';
import 'package:intl/intl.dart';

class WeekView extends StatefulWidget {
  final DateTime currentDate;
  final List<CalendarEvent> events;
  final List<CalendarEvent> holidays;
  final Function(DateTime) onDateSelected;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onToday;
  final void Function(CalendarEvent) onEventTap;

  const WeekView({
    super.key,
    required this.currentDate,
    required this.events,
    required this.holidays,
    required this.onDateSelected,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onToday,
    required this.onEventTap,
  });

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  Color _getEventTextColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'event':
        return Colors.green;
      case 'task':
        return Colors.blue;
      case 'follow-up':
        return Colors.orange;
      case 'meeting':
        return Colors.indigo;
      case 'deadline':
        return Colors.red;
      case 'document-approval':
        return Colors.teal;
      case 'reminder':
        return Colors.amber;
      case 'holiday':
        return Colors.red;
      case 'leave':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  List<DateTime> _getWeekDays(DateTime date) {
    // Get the Monday of the week
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final dayEvents = widget.events
        .where((e) =>
            e.date.year == day.year &&
            e.date.month == day.month &&
            e.date.day == day.day)
        .toList();

    final dayHolidays = widget.holidays
        .where((h) =>
            h.date.year == day.year &&
            h.date.month == day.month &&
            h.date.day == day.day)
        .toList();

    return [...dayEvents, ...dayHolidays];
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _getWeekDays(widget.currentDate);
    final today = DateTime.now();
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width < 1024;

    // Determine how many days to show per row
    int daysPerRow = 7;
    if (isMobile) {
      daysPerRow = 1; // Show 1 day per row on mobile
    } else if (isTablet) {
      daysPerRow = 3; // Show 3 days per row on tablet
    }

    return Column(
      children: [
        // Week Header with Navigation
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 20,
            vertical: isMobile ? 12 : 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: widget.onPreviousWeek,
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                color: AppTheme.primaryColor,
                iconSize: isMobile ? 18 : 20,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.surfaceVariant.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    isMobile
                        ? DateFormat('MMM d').format(widget.currentDate)
                        : 'Week of ${DateFormat('MMM d').format(weekDays.first)} - ${DateFormat('MMM d, yyyy').format(weekDays.last)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 13 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onNextWeek,
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                color: AppTheme.primaryColor,
                iconSize: isMobile ? 18 : 20,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.surfaceVariant.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Week Days Grid
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 20,
              vertical: isMobile ? 8 : 16,
            ),
            child: SingleChildScrollView(
              // Allow horizontal scroll on tablet if needed
              scrollDirection: daysPerRow == 3 ? Axis.horizontal : Axis.vertical,
              child: daysPerRow == 1
                  ? _buildMobileWeekView(weekDays, today, isMobile)
                  : _buildGridWeekView(weekDays, today, daysPerRow, isMobile),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileWeekView(List<DateTime> weekDays, DateTime today, bool isMobile) {
    return Column(
      children: weekDays.map((day) {
        final isToday = day.year == today.year &&
            day.month == today.month &&
            day.day == today.day;
        final dayEvents = _getEventsForDay(day);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => widget.onDateSelected(day),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday
                      ? AppTheme.primaryColor
                      : Colors.white.withOpacity(0.1),
                  width: isToday ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE').format(day),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, yyyy').format(day),
                            style: TextStyle(
                              color: isToday ? AppTheme.primaryColor : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (dayEvents.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${dayEvents.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                    if (dayEvents.isEmpty)
                      Text(
                        'No events',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      SingleChildScrollView(
                        child: Column(
                          children: dayEvents.map((event) {
                            final eventColor = _getEventTextColor(event.type);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: GestureDetector(
                                onTap: () => widget.onEventTap(event),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: eventColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: eventColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.title,
                                        style: TextStyle(
                                          color: eventColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if ((event.description ?? "").isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            event.description ?? "",
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGridWeekView(
    List<DateTime> weekDays,
    DateTime today,
    int daysPerRow,
    bool isMobile,
  ) {
    return Wrap(
      spacing: isMobile ? 4 : 8,
      runSpacing: isMobile ? 8 : 12,
      children: weekDays.map((day) {
        final isToday = day.year == today.year &&
            day.month == today.month &&
            day.day == today.day;
        final dayEvents = _getEventsForDay(day);
        final dayWidth = (MediaQuery.of(context).size.width -
                (isMobile ? 24 : 40) -
                (daysPerRow - 1) * (isMobile ? 4 : 8)) /
            daysPerRow;

        return SizedBox(
          width: dayWidth,
          height: 280,
          child: GestureDetector(
            onTap: () => widget.onDateSelected(day),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday
                      ? AppTheme.primaryColor
                      : Colors.white.withOpacity(0.1),
                  width: isToday ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEE').format(day),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: isToday ? AppTheme.primaryColor : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: dayEvents.isEmpty ? 1 : dayEvents.length,
                      itemBuilder: (context, eventIndex) {
                        if (dayEvents.isEmpty) {
                          return Text(
                            'No events',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          );
                        }

                        final event = dayEvents[eventIndex];
                        final eventColor = _getEventTextColor(event.type);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: GestureDetector(
                            onTap: () => widget.onEventTap(event),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: eventColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: eventColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                event.title,
                                style: TextStyle(
                                  color: eventColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
