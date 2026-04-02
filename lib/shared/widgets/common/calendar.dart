import 'package:flutter/material.dart';

/// A reusable Calendar widget that mimics the React calendar.tsx component
/// Provides date selection with customizable styling and callbacks
class Calendar extends StatefulWidget {
  /// The initially selected date
  final DateTime? selectedDate;

  /// Callback when a date is selected
  final Function(DateTime)? onDateSelected;

  /// Callback when month/year is changed
  final Function(DateTime)? onMonthChanged;

  /// Whether to show dates from other months
  final bool showOutsideDays;

  /// Custom styling options
  final CalendarStyle? style;

  /// Date range start for range selection
  final DateTime? rangeStart;

  /// Date range end for range selection
  final DateTime? rangeEnd;

  /// Whether to allow range selection
  final bool enableRangeSelection;

  /// Disabled dates
  final Set<DateTime>? disabledDates;

  /// Today's date (for highlighting)
  final DateTime? today;

  const Calendar({
    Key? key,
    this.selectedDate,
    this.onDateSelected,
    this.onMonthChanged,
    this.showOutsideDays = true,
    this.style,
    this.rangeStart,
    this.rangeEnd,
    this.enableRangeSelection = false,
    this.disabledDates,
    this.today,
  }) : super(key: key);

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late DateTime _displayedMonth;
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    _today = widget.today ?? DateTime.now();
    _displayedMonth = widget.selectedDate ?? _today;
  }

  @override
  void didUpdateWidget(Calendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != null && widget.selectedDate != oldWidget.selectedDate) {
      _displayedMonth = widget.selectedDate!;
    }
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
    widget.onMonthChanged?.call(_displayedMonth);
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
    widget.onMonthChanged?.call(_displayedMonth);
  }

  bool _isDateDisabled(DateTime date) {
    if (widget.disabledDates == null) return false;
    return widget.disabledDates!.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    return _isSameDay(date, _today);
  }

  bool _isSelected(DateTime date) {
    if (widget.selectedDate == null) return false;
    return _isSameDay(date, widget.selectedDate!);
  }

  bool _isInRange(DateTime date) {
    if (!widget.enableRangeSelection || widget.rangeStart == null || widget.rangeEnd == null) {
      return false;
    }
    return date.isAfter(widget.rangeStart!) && date.isBefore(widget.rangeEnd!);
  }

  bool _isRangeStart(DateTime date) {
    if (widget.rangeStart == null) return false;
    return _isSameDay(date, widget.rangeStart!);
  }

  bool _isRangeEnd(DateTime date) {
    if (widget.rangeEnd == null) return false;
    return _isSameDay(date, widget.rangeEnd!);
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? CalendarStyle();
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: style.containerPadding,
      decoration: style.containerDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month/Year Header with Navigation
          _buildMonthHeader(context, style, scheme),
          const SizedBox(height: 16),
          // Weekday Labels
          _buildWeekdayLabels(context, style, scheme),
          const SizedBox(height: 8),
          // Calendar Grid
          _buildCalendarGrid(context, style, scheme),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context, CalendarStyle style, ColorScheme scheme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          '${_monthName(_displayedMonth.month)} ${_displayedMonth.year}',
          style: style.monthLabelStyle ?? Theme.of(context).textTheme.titleMedium,
        ),
        Positioned(
          left: 0,
          child: _buildNavigationButton(
            onPressed: _previousMonth,
            icon: Icons.chevron_left,
            style: style,
          ),
        ),
        Positioned(
          right: 0,
          child: _buildNavigationButton(
            onPressed: _nextMonth,
            icon: Icons.chevron_right,
            style: style,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButton({
    required VoidCallback onPressed,
    required IconData icon,
    required CalendarStyle style,
  }) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(icon, size: 16),
        onPressed: onPressed,
        style: style.navigationButtonStyle,
      ),
    );
  }

  Widget _buildWeekdayLabels(BuildContext context, CalendarStyle style, ColorScheme scheme) {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: weekdays.map((day) {
        return SizedBox(
          width: 36,
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: style.weekdayLabelStyle ?? Theme.of(context).textTheme.labelSmall,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, CalendarStyle style, ColorScheme scheme) {
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    final firstDayOffset = firstDayOfMonth.weekday % 7;
    final previousMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    final daysInPreviousMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 0).day;

    final days = <DateTime>[];

    // Add days from previous month if showOutsideDays is true
    if (widget.showOutsideDays) {
      for (int i = firstDayOffset - 1; i >= 0; i--) {
        days.add(DateTime(previousMonth.year, previousMonth.month, daysInPreviousMonth - i));
      }
    }

    // Add days of current month
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      days.add(DateTime(_displayedMonth.year, _displayedMonth.month, i));
    }

    // Add days from next month if showOutsideDays is true
    if (widget.showOutsideDays) {
      final remainingDays = 42 - days.length;
      for (int i = 1; i <= remainingDays; i++) {
        days.add(DateTime(_displayedMonth.year, _displayedMonth.month + 1, i));
      }
    }

    return GridView.count(
      crossAxisCount: 7,
      crossAxisSpacing: 4,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: days.map((date) {
        final isCurrentMonth = date.month == _displayedMonth.month;
        final isDisabled = _isDateDisabled(date);
        final isSelected = _isSelected(date);
        final isToday = _isToday(date);
        final isInRange = _isInRange(date);
        final isRangeStart = _isRangeStart(date);
        final isRangeEnd = _isRangeEnd(date);
        final isOutsideMonth = !isCurrentMonth && !widget.showOutsideDays;

        return _buildDateButton(
          date: date,
          isCurrentMonth: isCurrentMonth,
          isDisabled: isDisabled,
          isSelected: isSelected,
          isToday: isToday,
          isInRange: isInRange,
          isRangeStart: isRangeStart,
          isRangeEnd: isRangeEnd,
          isOutsideMonth: isOutsideMonth,
          style: style,
          scheme: scheme,
        );
      }).toList(),
    );
  }

  Widget _buildDateButton({
    required DateTime date,
    required bool isCurrentMonth,
    required bool isDisabled,
    required bool isSelected,
    required bool isToday,
    required bool isInRange,
    required bool isRangeStart,
    required bool isRangeEnd,
    required bool isOutsideMonth,
    required CalendarStyle style,
    required ColorScheme scheme,
  }) {
    Color? backgroundColor;
    Color? textColor;
    TextStyle? textStyle;

    if (isSelected) {
      backgroundColor = scheme.primary;
      textColor = scheme.onPrimary;
    } else if (isRangeStart || isRangeEnd) {
      backgroundColor = scheme.primary;
      textColor = scheme.onPrimary;
    } else if (isInRange) {
      backgroundColor = scheme.primary.withOpacity(0.5);
      textColor = scheme.onPrimaryContainer;
    } else if (isToday) {
      backgroundColor = scheme.secondary.withOpacity(0.5);
      textColor = scheme.onSecondaryContainer;
    } else if (isOutsideMonth) {
      textColor = scheme.onSurfaceVariant.withOpacity(0.5);
    } else if (!isCurrentMonth && !widget.showOutsideDays) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : () {
          setState(() {
            if (!widget.enableRangeSelection) {
              widget.onDateSelected?.call(date);
            }
          });
          if (!widget.enableRangeSelection) {
            widget.onDateSelected?.call(date);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '${date.day}',
            textAlign: TextAlign.center,
            style: (textStyle ?? Theme.of(context).textTheme.labelSmall)?.copyWith(
              color: isDisabled ? scheme.onSurfaceVariant.withOpacity(0.38) : textColor,
              fontWeight: isSelected || isRangeStart || isRangeEnd ? FontWeight.w600 : null,
            ),
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }
}

/// Custom styling configuration for Calendar widget
class CalendarStyle {
  /// Container padding
  final EdgeInsets containerPadding;

  /// Container decoration
  final Decoration? containerDecoration;

  /// Style for month/year label
  final TextStyle? monthLabelStyle;

  /// Style for weekday labels
  final TextStyle? weekdayLabelStyle;

  /// Style for day buttons
  final TextStyle? dayLabelStyle;

  /// Navigation button style
  final ButtonStyle? navigationButtonStyle;

  /// Selected date background color
  final Color? selectedDateBackground;

  /// Selected date text color
  final Color? selectedDateTextColor;

  /// Today highlight color
  final Color? todayHighlightColor;

  /// Disabled date color
  final Color? disabledDateColor;

  const CalendarStyle({
    this.containerPadding = const EdgeInsets.all(12),
    this.containerDecoration,
    this.monthLabelStyle,
    this.weekdayLabelStyle,
    this.dayLabelStyle,
    this.navigationButtonStyle,
    this.selectedDateBackground,
    this.selectedDateTextColor,
    this.todayHighlightColor,
    this.disabledDateColor,
  });
}
