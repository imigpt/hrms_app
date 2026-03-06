import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hrms_app/services/attendance_service.dart';
import 'package:hrms_app/services/token_storage_service.dart';
import 'package:hrms_app/models/attendance_summary_model.dart';
import 'package:hrms_app/theme/app_theme.dart';

class AttendanceStatisticsSection extends StatefulWidget {
  final String? userId;

  const AttendanceStatisticsSection({super.key, this.userId});

  @override
  State<AttendanceStatisticsSection> createState() =>
      _AttendanceStatisticsSectionState();
}

class _AttendanceStatisticsSectionState
    extends State<AttendanceStatisticsSection> {
  bool _isLoading = true;
  AttendanceSummaryData? _summaryData;
  String? _error;
  late int _currentMonth;
  late int _currentYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = now.month;
    _currentYear = now.year;
    _loadAttendanceSummary();
  }

  Future<void> _loadAttendanceSummary() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final token = await TokenStorageService().getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await AttendanceService.getAttendanceSummary(
        token: token,
        month: _currentMonth,
        year: _currentYear,
      );

      if (response.success && mounted) {
        setState(() {
          _summaryData = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _changeMonth(int monthDelta) async {
    setState(() {
      _currentMonth += monthDelta;
      if (_currentMonth > 12) {
        _currentMonth = 1;
        _currentYear++;
      } else if (_currentMonth < 1) {
        _currentMonth = 12;
        _currentYear--;
      }
    });
    await _loadAttendanceSummary();
  }

  @override
  Widget build(BuildContext context) {
    final monthYear = DateFormat(
      'MMMM yyyy',
    ).format(DateTime(_currentYear, _currentMonth, 1));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Current month breakdown',
                        style: TextStyle(
                          color: Colors.grey.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (!_isLoading)
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  onPressed: _loadAttendanceSummary,
                  tooltip: 'Refresh',
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Content
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 60),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            )
          else if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                ],
              ),
            )
          else if (_summaryData != null)
            Column(
              children: [
                // Month Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Text(
                      monthYear,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Legend and Chart
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Legend (Left side)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem(
                            'Total Attendance',
                            (_summaryData!.present +
                                    _summaryData!.absent +
                                    _summaryData!.late +
                                    _summaryData!.halfDay)
                                .toString(),
                            const Color(0xFF9C27B0), // Purple
                          ),
                          const SizedBox(height: 12),
                          _buildLegendItem(
                            'Present',
                            _summaryData!.present.toString(),
                            const Color(0xFF4CAF50), // Green
                          ),
                          const SizedBox(height: 12),
                          _buildLegendItem(
                            'Leaves',
                            '0',
                            const Color(0xFFF44336), // Red
                          ),
                          const SizedBox(height: 12),
                          _buildLegendItem(
                            'Half Day',
                            _summaryData!.halfDay.toString(),
                            const Color(0xFF2196F3), // Blue
                          ),
                          const SizedBox(height: 12),
                          _buildLegendItem(
                            'Late Attendance',
                            _summaryData!.late.toString(),
                            const Color(0xFFFF9800), // Orange
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 30),
                    // Chart (Right side - Donut/Pie)
                    Expanded(child: _buildDonutChart()),
                  ],
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: const Text(
                'No attendance data available',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDonutChart() {
    final total =
        _summaryData!.present +
        _summaryData!.absent +
        _summaryData!.late +
        _summaryData!.halfDay;

    if (total == 0) {
      return Center(
        child: Text(
          'No data',
          style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 14),
        ),
      );
    }

    return CustomPaint(
      painter: DonutChartPainter(
        present: _summaryData!.present.toDouble(),
        absent: _summaryData!.absent.toDouble(),
        late: _summaryData!.late.toDouble(),
        halfDay: _summaryData!.halfDay.toDouble(),
        total: total.toDouble(),
      ),
      size: const Size(120, 120),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final double present;
  final double absent;
  final double late;
  final double halfDay;
  final double total;

  DonutChartPainter({
    required this.present,
    required this.absent,
    required this.late,
    required this.halfDay,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.6;

    var startAngle = -90.0 * (3.14159 / 180); // Start from top

    // Colors matching the legend
    const presentColor = Color(0xFF4CAF50); // Green
    const absentColor = Color(0xFFF44336); // Red
    const lateColor = Color(0xFFFF9800); // Orange
    const halfDayColor = Color(0xFF2196F3); // Blue

    // Draw Present segment (Green)
    _drawSegment(
      canvas,
      center,
      radius,
      innerRadius,
      startAngle,
      (present / total) * 360,
      presentColor,
    );
    startAngle += (present / total) * 360 * (3.14159 / 180);

    // Draw Absent segment (Red)
    _drawSegment(
      canvas,
      center,
      radius,
      innerRadius,
      startAngle,
      (absent / total) * 360,
      absentColor,
    );
    startAngle += (absent / total) * 360 * (3.14159 / 180);

    // Draw Late segment (Orange)
    _drawSegment(
      canvas,
      center,
      radius,
      innerRadius,
      startAngle,
      (late / total) * 360,
      lateColor,
    );
    startAngle += (late / total) * 360 * (3.14159 / 180);

    // Draw Half Day segment (Blue)
    _drawSegment(
      canvas,
      center,
      radius,
      innerRadius,
      startAngle,
      (halfDay / total) * 360,
      halfDayColor,
    );
  }

  void _drawSegment(
    Canvas canvas,
    Offset center,
    double radius,
    double innerRadius,
    double startAngle,
    double sweepAngle,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Outer arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    path.arcTo(rect, startAngle, sweepAngle * (3.14159 / 180), true);

    // Line to inner circle
    final endAngle = startAngle + sweepAngle * (3.14159 / 180);
    final endPoint = Offset(
      center.dx + innerRadius * cos(endAngle),
      center.dy + innerRadius * sin(endAngle),
    );
    path.lineTo(endPoint.dx, endPoint.dy);

    // Inner arc (reverse)
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
    path.arcTo(innerRect, endAngle, -sweepAngle * (3.14159 / 180), false);

    path.close();
    canvas.drawPath(path, paint);
  }

  double cos(double angle) => math.cos(angle);
  double sin(double angle) => math.sin(angle);

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return oldDelegate.present != present ||
        oldDelegate.absent != absent ||
        oldDelegate.late != late ||
        oldDelegate.halfDay != halfDay;
  }
}
