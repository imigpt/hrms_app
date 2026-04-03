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

  const WeekView({
    super.key,
    required this.currentDate,
    required this.events,
    required this.holidays,
    required this.onDateSelected,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onToday,
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

    return Column(
      children: [
        // Week Header with Navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: widget.onPreviousWeek,
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                color: AppTheme.primaryColor,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.surfaceVariant.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Week of ${DateFormat('MMM d').format(weekDays.first)} - ${DateFormat('MMM d, yyyy').format(weekDays.last)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onNextWeek,
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                color: AppTheme.primaryColor,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.surfaceVariant.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Week Days
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  7,
                  (index) {
                    final day = weekDays[index];
                    final isToday = day.year == today.year &&
                        day.month == today.month &&
                        day.day == today.day;
                    final dayEvents = _getEventsForDay(day);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onDateSelected(day),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
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
                              // Day header
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('EEE').format(day),
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    day.day.toString(),
                                    style: TextStyle(
                                      color: isToday
                                          ? AppTheme.primaryColor
                                          : Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Events
                              Flexible(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: dayEvents.isEmpty
                                        ? [
                                            Text(
                                              'No events',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ]
                                        : List.generate(
                                            dayEvents.length,
                                            (eventIndex) {
                                              final event = dayEvents[eventIndex];
                                              final eventColor =
                                                  _getEventTextColor(
                                                      event.type);

                                              return Padding(
                                                padding: const EdgeInsets
                                                    .symmetric(vertical: 4),
                                                child: Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: eventColor
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    border: Border.all(
                                                      color: eventColor
                                                          .withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    event.title,
                                                    style: TextStyle(
                                                      color: eventColor,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
