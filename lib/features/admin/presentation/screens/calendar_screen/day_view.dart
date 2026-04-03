import 'package:flutter/material.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';
import 'package:hrms_app/features/admin/presentation/providers/calendar_state.dart';
import 'package:intl/intl.dart';

class DayView extends StatefulWidget {
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final List<CalendarEvent> holidays;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onToday;

  const DayView({
    super.key,
    required this.selectedDate,
    required this.events,
    required this.holidays,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onToday,
  });

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  final ScrollController _scrollController = ScrollController();

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

  Color _getEventBackgroundColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'event':
        return const Color(0xDCF5E8);
      case 'task':
        return const Color(0xDCEAF9);
      case 'follow-up':
        return const Color(0xFFEBD1);
      case 'meeting':
        return const Color(0xE6E6F5);
      case 'deadline':
        return const Color(0xFDD8DC);
      case 'document-approval':
        return const Color(0xD1F5E3);
      case 'reminder':
        return const Color(0xFFF4D4);
      case 'holiday':
        return const Color(0xFDD8DC);
      case 'leave':
        return const Color(0xFFEBD1);
      default:
        return const Color(0xDCEAF9);
    }
  }

  IconData _getEventIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'event':
        return Icons.event_rounded;
      case 'task':
        return Icons.assignment_rounded;
      case 'follow-up':
        return Icons.phone_callback_rounded;
      case 'meeting':
        return Icons.videocam_rounded;
      case 'deadline':
        return Icons.schedule_rounded;
      case 'document-approval':
        return Icons.description_rounded;
      case 'reminder':
        return Icons.notifications_rounded;
      case 'holiday':
        return Icons.celebration_rounded;
      case 'leave':
        return Icons.beach_access_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  List<CalendarEvent> _getEventsForDay() {
    final dayEvents = widget.events
        .where((e) =>
            e.date.year == widget.selectedDate.year &&
            e.date.month == widget.selectedDate.month &&
            e.date.day == widget.selectedDate.day)
        .toList();

    final dayHolidays = widget.holidays
        .where((h) =>
            h.date.year == widget.selectedDate.year &&
            h.date.month == widget.selectedDate.month &&
            h.date.day == widget.selectedDate.day)
        .toList();

    final allEvents = [...dayEvents, ...dayHolidays];
    // Sort by start time
    allEvents.sort((a, b) {
      if (a.startTime == null || b.startTime == null) return 0;
      return a.startTime!.compareTo(b.startTime!);
    });

    return allEvents;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayEvents = _getEventsForDay();
    final isToday = widget.selectedDate.year == DateTime.now().year &&
        widget.selectedDate.month == DateTime.now().month &&
        widget.selectedDate.day == DateTime.now().day;

    return Column(
      children: [
        // Day Header with Navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: widget.onPreviousDay,
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
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEEE').format(widget.selectedDate),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMMM d, yyyy').format(widget.selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onNextDay,
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

        if (isToday)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Today',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Events List
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: dayEvents.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_note,
                            size: 48,
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
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      dayEvents.length,
                      (index) {
                        final event = dayEvents[index];
                        final bgColor = _getEventBackgroundColor(event.type);
                        final textColor = _getEventTextColor(event.type);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: textColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with icon and type
                                Row(
                                  children: [
                                    Icon(
                                      _getEventIcon(event.type),
                                      size: 20,
                                      color: textColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            event.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  textColor.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              event.type ?? 'event',
                                              style: TextStyle(
                                                color: textColor,
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
                                const SizedBox(height: 12),

                                // Time
                                if (!event.allDay && event.startTime != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 16,
                                          color: textColor.withOpacity(0.7),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat('h:mm a')
                                              .format(event.startTime!),
                                          style: TextStyle(
                                            color: textColor.withOpacity(0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (event.endTime != null) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            '-',
                                            style: TextStyle(
                                              color:
                                                  textColor.withOpacity(0.5),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('h:mm a')
                                                .format(event.endTime!),
                                            style: TextStyle(
                                              color: textColor.withOpacity(0.8),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                // Description
                                if (event.description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      event.description,
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 13,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                // All Day Badge
                                if (event.allDay)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: textColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'All Day',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
