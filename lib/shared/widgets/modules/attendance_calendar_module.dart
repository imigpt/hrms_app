import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ═══════════════════════ DATA MODELS ═════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════════════

enum AttendanceStatus {
  present,
  absent,
  late,
  holiday,
  weekend,
  future,
  leave,
  halfDay,
  workFromHome,
}

class AttendanceDayData {
  final int date;
  final AttendanceStatus status;
  final String? label;
  final bool isHalfDay;
  final String? session;

  AttendanceDayData({
    required this.date,
    required this.status,
    this.label,
    this.isHalfDay = false,
    this.session,
  });
}

class AttendanceStats {
  final int present;
  final int absent;
  final int late;
  final int leave;
  final int holiday;

  AttendanceStats({
    required this.present,
    required this.absent,
    required this.late,
    required this.leave,
    required this.holiday,
  });

  int get total => present + absent + late + leave + holiday;
}

class LeaveRecord {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final bool isHalfDay;
  final String? session;
  final String status;

  LeaveRecord({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.isHalfDay,
    this.session,
    required this.status,
  });
}

class AttendanceRecord {
  final String id;
  final DateTime date;
  final AttendanceStatus status;
  final String? remarks;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.status,
    this.remarks,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// ═══════════════════════ STATUS COLOR MAP ══════════════════════════════════
// ═══════════════════════════════════════════════════════════════════════════

class AttendanceColorMap {
  static const Map<AttendanceStatus, (Color bg, Color text, Color border)> colors = {
    AttendanceStatus.present: (
      Color(0xFFDCFCE7), // bg-success/20
      Color(0xFF059669), // text-success
      Color(0xFF86EFAC),  // border-success/30
    ),
    AttendanceStatus.absent: (
      Color(0xFFFEE2E2), // bg-destructive/20
      Color(0xFFDC2626), // text-destructive
      Color(0xFFFCA5A5),  // border-destructive/30
    ),
    AttendanceStatus.late: (
      Color(0xFFFEF3C7), // bg-warning/20
      Color(0xFFD97706), // text-warning
      Color(0xFFFCD34D),  // border-warning/30
    ),
    AttendanceStatus.holiday: (
      Color(0xFFDEF7FF), // bg-primary/20
      Color(0xFF0369A1), // text-primary
      Color(0xFF7DD3FC),  // border-primary/30
    ),
    AttendanceStatus.leave: (
      Color(0xFFBFDBFE), // bg-blue-500/20
      Color(0xFF3B82F6), // text-blue-400
      Color(0xFF93C5FD),  // border-blue-400/30
    ),
    AttendanceStatus.halfDay: (
      Color(0xFFFED7AA), // bg-orange-500/20
      Color(0xFFF97316), // text-orange-400
      Color(0xFFFFED4E),  // border-orange-400/30
    ),
    AttendanceStatus.weekend: (
      Color(0xFFF3F4F6), // bg-muted
      Color(0xFF6B7280), // text-muted-foreground
      Color(0xFFE5E7EB),  // border-border
    ),
    AttendanceStatus.future: (
      const Color(0x00000000), // Transparent
      Color(0xFF9CA3AF),
      Color(0xFFE5E7EB),
    ),
    AttendanceStatus.workFromHome: (
      Color(0xFFDCFCE7),
      Color(0xFF059669),
      Color(0xFF86EFAC),
    ),
  };

  static (Color bg, Color text, Color border) getColors(AttendanceStatus status) {
    return colors[status] ?? colors[AttendanceStatus.absent]!;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ═══════════════════════ ATTENDANCE CALENDAR MODULE ═══════════════════════
// ═══════════════════════════════════════════════════════════════════════════

class AttendanceCalendarModule extends StatefulWidget {
  final String userRole;
  final String? userId;
  final String? token;
  final Function(int month, int year)? onFetchAttendance;
  final Function(int month, int year)? onFetchLeaves;
  final List<AttendanceRecord>? initialAttendanceData;
  final List<LeaveRecord>? initialLeaveData;

  const AttendanceCalendarModule({
    Key? key,
    required this.userRole,
    this.userId,
    this.token,
    this.onFetchAttendance,
    this.onFetchLeaves,
    this.initialAttendanceData,
    this.initialLeaveData,
  }) : super(key: key);

  @override
  State<AttendanceCalendarModule> createState() => _AttendanceCalendarModuleState();
}

class _AttendanceCalendarModuleState extends State<AttendanceCalendarModule> {
  late DateTime _currentMonth;
  bool _isLoading = false;
  late List<AttendanceDayData> _calendarData;
  late AttendanceStats _stats;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _calendarData = [];
    _stats = AttendanceStats(present: 0, absent: 0, late: 0, leave: 0, holiday: 0);
    _buildCalendar();
  }

  Future<void> _buildCalendar() async {
    setState(() => _isLoading = true);

    try {
      final year = _currentMonth.year;
      final month = _currentMonth.month;

      print('[CALENDAR] Building calendar for: $month/$year');

      // Fetch attendance records
      await widget.onFetchAttendance?.call(month, year);

      // Fetch leave records
      await widget.onFetchLeaves?.call(month, year);

      // Build attendance map
      final attMap = <String, AttendanceStatus>{};
      for (final rec in (widget.initialAttendanceData ?? [])) {
        if (rec.date.month == month && rec.date.year == year) {
          final key = rec.date.day.toString();
          attMap[key] = rec.status;
        }
      }

      // Build leave dates set
      final leaveDates = <String, (bool isHalfDay, String? session)>{};
      for (final leave in (widget.initialLeaveData ?? [])) {
        if (leave.status != 'approved') continue;

        var current = leave.startDate;
        while (current.isBefore(leave.endDate) || current.isAtSameMomentAs(leave.endDate)) {
          if (current.month == month && current.year == year) {
            final key = current.day.toString();
            leaveDates[key] = (leave.isHalfDay, leave.session);
          }
          current = current.add(const Duration(days: 1));
        }
      }

      // Build calendar data
      final today = DateTime.now();
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final days = <AttendanceDayData>[];

      for (int i = 1; i <= daysInMonth; i++) {
        final date = DateTime(year, month, i);
        final dayOfWeek = date.weekday;
        final isFuture = date.isAfter(today);
        final key = i.toString();

        AttendanceStatus status = AttendanceStatus.absent;
        String? label;

        if (isFuture) {
          status = AttendanceStatus.future;
        } else if (dayOfWeek == 6 || dayOfWeek == 7) {
          // Saturday or Sunday
          status = AttendanceStatus.weekend;
        } else if (leaveDates.containsKey(key)) {
          final (isHalf, session) = leaveDates[key]!;
          if (isHalf) {
            status = AttendanceStatus.halfDay;
            label = session ?? 'AM/PM';
          } else {
            status = AttendanceStatus.leave;
            label = 'On Leave';
          }
        } else if (attMap.containsKey(key)) {
          status = attMap[key]!;
          if (status == AttendanceStatus.workFromHome) {
            label = 'WFH';
          }
        }

        days.add(AttendanceDayData(
          date: i,
          status: status,
          label: label,
        ));
      }

      // Calculate stats
      final present = days.where((d) => d.status == AttendanceStatus.present).length;
      final absent = days.where((d) => d.status == AttendanceStatus.absent).length;
      final late = days.where((d) => d.status == AttendanceStatus.late).length;
      final leave = days.where((d) => d.status == AttendanceStatus.leave || d.status == AttendanceStatus.halfDay).length;
      final holiday = days.where((d) => d.status == AttendanceStatus.holiday).length;

      if (mounted) {
        setState(() {
          _calendarData = days;
          _stats = AttendanceStats(
            present: present,
            absent: absent,
            late: late,
            leave: leave,
            holiday: holiday,
          );
        });
      }
    } catch (e) {
      print('[CALENDAR ERROR] Failed to build calendar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    print('[CALENDAR] Navigated to previous month: ${_currentMonth.month}/${_currentMonth.year}');
    _buildCalendar();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    print('[CALENDAR] Navigated to next month: ${_currentMonth.month}/${_currentMonth.year}');
    _buildCalendar();
  }

  void _today() {
    setState(() {
      _currentMonth = DateTime.now();
    });
    print('[CALENDAR] Navigated to today: ${_currentMonth.month}/${_currentMonth.year}');
    _buildCalendar();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Statistics cards
          _buildStatisticsRow(),
          const SizedBox(height: 24),

          // Calendar card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header with navigation
                  _buildCalendarHeader(),
                  const SizedBox(height: 16),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    )
                  else ...[
                    // Weekday labels
                    _buildWeekdayLabels(),
                    const SizedBox(height: 8),

                    // Calendar grid
                    _buildCalendarGrid(isMobile),
                  ],
                ],
              ),
            ),
          ),

          // Legend
          const SizedBox(height: 24),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow() {
    final stats = [
      ('Present', _stats.present, const Color(0xFF059669)),
      ('Absent', _stats.absent, const Color(0xFFDC2626)),
      ('Late', _stats.late, const Color(0xFFD97706)),
      ('Leave', _stats.leave, const Color(0xFF3B82F6)),
      ('Holiday', _stats.holiday, const Color(0xFF0369A1)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stats.map((stat) {
          final (label, count, color) = stat;
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final monthYear = DateFormat('MMMM yyyy').format(_currentMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _previousMonth,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                monthYear,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _today,
                child: const Text('Today'),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _nextMonth,
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels() {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 0,
      children: weekdays.map((day) {
        return Center(
          child: Text(
            day,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(bool isMobile) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstDayOffset = firstDay.weekday;
    final daysInMonth = lastDay.day;

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        // Empty cells for days before month starts
        for (int i = 0; i < firstDayOffset; i++)
          const SizedBox(),

        // Days of month
        ..._calendarData.map((day) {
          final isCurrentMonth = true;
          final colors = AttendanceColorMap.getColors(day.status);

          return GestureDetector(
            onTap: day.status == AttendanceStatus.future ? null : null,
            child: Container(
              decoration: BoxDecoration(
                color: colors.$1,
                border: Border.all(color: colors.$3, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.date}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCurrentMonth ? colors.$2 : Colors.grey,
                        ),
                      ),
                      if (day.label != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          day.label!,
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.$2,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildLegend() {
    final legendItems = [
      ('Present', AttendanceStatus.present),
      ('Absent', AttendanceStatus.absent),
      ('Late', AttendanceStatus.late),
      ('Leave', AttendanceStatus.leave),
      ('Holiday', AttendanceStatus.holiday),
      ('Weekend', AttendanceStatus.weekend),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 16,
      children: legendItems.map((item) {
        final (label, status) = item;
        final colors = AttendanceColorMap.getColors(status);

        return Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: colors.$1,
                border: Border.all(color: colors.$3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }
}
