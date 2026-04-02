import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ═══════════════════════ DATA MODELS ═══════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════════════

enum ViewMode { month, week, day }

enum EventType {
  event,
  task,
  followUp,
  meeting,
  deadline,
  documentApproval,
  reminder,
}

enum EventPriority { low, medium, high, critical }

enum EventStatus { scheduled, inProgress, completed, cancelled, pending, active, done }

class AggregatedCalendarItem {
  final String id;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime? end;
  final EventType eventType;
  final EventStatus status;
  final EventPriority? priority;
  final String? createdBy;
  final bool allDay;
  final String? meetingUrl;
  final List<String>? participants;
  final String? timezone;
  final String? reminder;

  AggregatedCalendarItem({
    required this.id,
    required this.title,
    this.description,
    required this.start,
    this.end,
    required this.eventType,
    required this.status,
    this.priority,
    this.createdBy,
    this.allDay = false,
    this.meetingUrl,
    this.participants,
    this.timezone,
    this.reminder,
  });

  bool isSameDay(DateTime other) {
    return start.year == other.year && start.month == other.month && start.day == other.day;
  }

  bool isToday() {
    final now = DateTime.now();
    return isSameDay(now);
  }

  bool isOverdue() {
    return start.isBefore(DateTime.now()) && status != EventStatus.completed;
  }
}

class EventTypeStyle {
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final Color dotColor;

  EventTypeStyle({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.dotColor,
  });
}

class CalendarItemStats {
  final int total;
  final int completed;
  final int pending;
  final int overdue;

  CalendarItemStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// ═══════════════════════ STYLING CONSTANTS ═════════════════════════════════
// ═══════════════════════════════════════════════════════════════════════════

class TypeStyleMap {
  static final Map<EventType, EventTypeStyle> styles = {
    EventType.event: EventTypeStyle(
      backgroundColor: Colors.green.withOpacity(0.1),
      textColor: Colors.green[800]!,
      borderColor: Colors.green[300]!,
      dotColor: Colors.green[500]!,
    ),
    EventType.task: EventTypeStyle(
      backgroundColor: Colors.blue.withOpacity(0.1),
      textColor: Colors.blue[800]!,
      borderColor: Colors.blue[300]!,
      dotColor: Colors.blue[500]!,
    ),
    EventType.followUp: EventTypeStyle(
      backgroundColor: Colors.orange.withOpacity(0.1),
      textColor: Colors.orange[800]!,
      borderColor: Colors.orange[300]!,
      dotColor: Colors.orange[500]!,
    ),
    EventType.meeting: EventTypeStyle(
      backgroundColor: Colors.indigo.withOpacity(0.1),
      textColor: Colors.indigo[800]!,
      borderColor: Colors.indigo[300]!,
      dotColor: Colors.indigo[500]!,
    ),
    EventType.deadline: EventTypeStyle(
      backgroundColor: Colors.red.withOpacity(0.1),
      textColor: Colors.red[800]!,
      borderColor: Colors.red[300]!,
      dotColor: Colors.red[500]!,
    ),
    EventType.documentApproval: EventTypeStyle(
      backgroundColor: Colors.emerald.withOpacity(0.1),
      textColor: Colors.emerald[800]!,
      borderColor: Colors.emerald[300]!,
      dotColor: Colors.emerald[500]!,
    ),
    EventType.reminder: EventTypeStyle(
      backgroundColor: Colors.yellow.withOpacity(0.1),
      textColor: Colors.yellow[800]!,
      borderColor: Colors.yellow[300]!,
      dotColor: Colors.yellow[500]!,
    ),
  };

  static EventTypeStyle getStyle(EventType type) {
    return styles[type] ?? styles[EventType.event]!;
  }
}

class PriorityColorMap {
  static const Map<EventPriority, (Color bg, Color text)> colors = {
    EventPriority.low: (Color(0xFFF1F5FE), Color(0xFF1E40AF)),
    EventPriority.medium: (Color(0xFFDEF7FF), Color(0xFF0369A1)),
    EventPriority.high: (Color(0xFFFED7AA), Color(0xFF92400E)),
    EventPriority.critical: (Color(0xFFFEE2E2), Color(0xFFDC2626)),
  };

  static (Color bg, Color text) getColors(EventPriority priority) {
    return colors[priority] ?? colors[EventPriority.low]!;
  }
}

class StatusColorMap {
  static const Map<EventStatus, (Color bg, Color text)> colors = {
    EventStatus.scheduled: (Color(0xFFDEF7FF), Color(0xFF0369A1)),
    EventStatus.inProgress: (Color(0xFFFEF3C7), Color(0xFFB45309)),
    EventStatus.completed: (Color(0xFFDCFCE7), Color(0xFF15803D)),
    EventStatus.cancelled: (Color(0xFFFEE2E2), Color(0xFFDC2626)),
    EventStatus.pending: (Color(0xFFF1F5FE), Color(0xFF1E40AF)),
    EventStatus.active: (Color(0xFFDEF7FF), Color(0xFF0369A1)),
    EventStatus.done: (Color(0xFFDCFCE7), Color(0xFF15803D)),
  };

  static (Color bg, Color text) getColors(EventStatus status) {
    return colors[status] ?? colors[EventStatus.pending]!;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ═══════════════════════ VIEW EVENT DIALOG ═════════════════════════════════
// ═══════════════════════════════════════════════════════════════════════════

class ViewEventDialog extends StatefulWidget {
  final AggregatedCalendarItem item;
  final VoidCallback? onClose;
  final Function(String id)? onMarkComplete;
  final Function(String id)? onDelete;
  final String userRole;
  final String? currentUserId;

  const ViewEventDialog({
    Key? key,
    required this.item,
    this.onClose,
    this.onMarkComplete,
    this.onDelete,
    required this.userRole,
    this.currentUserId,
  }) : super(key: key);

  @override
  State<ViewEventDialog> createState() => _ViewEventDialogState();
}

class _ViewEventDialogState extends State<ViewEventDialog> {
  late bool _isLoading = false;

  Future<void> _handleMarkComplete() async {
    setState(() => _isLoading = true);
    try {
      await widget.onMarkComplete?.call(widget.item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event marked as complete')),
        );
        widget.onClose?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      setState(() => _isLoading = true);
      try {
        await widget.onDelete?.call(widget.item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted')),
          );
          widget.onClose?.call();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = TypeStyleMap.getStyle(widget.item.eventType);
    final statusColors = StatusColorMap.getColors(widget.item.status);
    final isCompleted = widget.item.status == EventStatus.completed;
    final isOwn = widget.item.eventType == EventType.event &&
        (widget.userRole == 'admin' || widget.item.createdBy == widget.currentUserId);

    return Dialog(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: style.borderColor, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with type indicator
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: style.dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.item.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColors.$1,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.item.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: statusColors.$2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              if (widget.item.description?.isNotEmpty ?? false) ...[
                Text(
                  widget.item.description!,
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 16),
              ],

              // Details grid
              Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  _buildDetailItem('Start', _formatDateTime(widget.item.start)),
                  if (widget.item.end != null)
                    _buildDetailItem('End', _formatDateTime(widget.item.end!)),
                  if (widget.item.priority != null)
                    _buildDetailItem('Priority', _getPriorityLabel(widget.item.priority!)),
                  if (widget.item.meetingUrl?.isNotEmpty ?? false)
                    _buildDetailItem('Meeting', 'Join', isClickable: true),
                  if (widget.item.timezone?.isNotEmpty ?? false)
                    _buildDetailItem('Timezone', widget.item.timezone!),
                ],
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isCompleted && isOwn)
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleMarkComplete,
                      icon: const Icon(Icons.check),
                      label: const Text('Mark Complete'),
                    ),
                  const SizedBox(width: 12),
                  if (isOwn)
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleDelete,
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isClickable = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isClickable ? Colors.blue : Colors.black,
            decoration: isClickable ? TextDecoration.underline : null,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('MMM dd, yyyy h:mm a').format(dt);
  }

  String _getPriorityLabel(EventPriority priority) {
    return priority.toString().split('.').last;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ═══════════════════════ MAIN MODULE ═════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════════════

class UniversalCalendarModule extends StatefulWidget {
  final String userRole;
  final String? userId;
  final List<AggregatedCalendarItem>? initialItems;
  final Function(AggregatedCalendarItem)? onCreateEvent;
  final Function(AggregatedCalendarItem)? onMarkComplete;
  final Function(String id)? onDeleteEvent;

  const UniversalCalendarModule({
    Key? key,
    required this.userRole,
    this.userId,
    this.initialItems,
    this.onCreateEvent,
    this.onMarkComplete,
    this.onDeleteEvent,
  }) : super(key: key);

  @override
  State<UniversalCalendarModule> createState() => _UniversalCalendarModuleState();
}

class _UniversalCalendarModuleState extends State<UniversalCalendarModule> {
  late DateTime _currentDate;
  ViewMode _viewMode = ViewMode.month;
  AggregatedCalendarItem? _selectedEvent;
  DateTime? _selectedDate;
  List<AggregatedCalendarItem> _items = [];

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _items = widget.initialItems ?? [];
  }

  List<AggregatedCalendarItem> _getItemsForDate(DateTime date) {
    return _items.where((item) => item.isSameDay(date)).toList();
  }

  CalendarItemStats _getStatistics() {
    final completed = _items.where((i) => i.status == EventStatus.completed).length;
    final pending = _items.where((i) => i.status == EventStatus.pending || i.status == EventStatus.scheduled).length;
    final overdue = _items.where((i) => i.isOverdue()).length;

    return CalendarItemStats(
      total: _items.length,
      completed: completed,
      pending: pending,
      overdue: overdue,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getStatistics();

    return Column(
      children: [
        // Statistics bar
        _buildStatisticsBar(stats),
        const SizedBox(height: 24),

        // View mode selector
        _buildViewModeSelector(),
        const SizedBox(height: 16),

        // Main calendar view
        Expanded(
          child: _buildCalendarView(),
        ),

        // Event dialog
        if (_selectedEvent != null)
          ViewEventDialog(
            item: _selectedEvent!,
            onClose: () => setState(() => _selectedEvent = null),
            onMarkComplete: (id) async => await widget.onMarkComplete?.call(_selectedEvent!),
            onDelete: widget.onDeleteEvent,
            userRole: widget.userRole,
            currentUserId: widget.userId,
          ),
      ],
    );
  }

  Widget _buildStatisticsBar(CalendarItemStats stats) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard('Total', stats.total, Colors.blue),
          _buildStatCard('Completed', stats.completed, Colors.green),
          _buildStatCard('Pending', stats.pending, Colors.orange),
          _buildStatCard('Overdue', stats.overdue, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
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
  }

  Widget _buildViewModeSelector() {
    return Row(
      children: [
        for (final mode in ViewMode.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(mode.toString().split('.').last.toUpperCase()),
              selected: _viewMode == mode,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _viewMode = mode);
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarView() {
    switch (_viewMode) {
      case ViewMode.month:
        return _buildMonthView();
      case ViewMode.week:
        return _buildWeekView();
      case ViewMode.day:
        return _buildDayView();
    }
  }

  Widget _buildMonthView() {
    final firstDay = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDay = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    final days = <DateTime>[];
    for (int i = 1 - firstWeekday; i <= daysInMonth; i++) {
      days.add(DateTime(_currentDate.year, _currentDate.month, i));
    }

    return Column(
      children: [
        // Month header
        _buildMonthHeader(),
        const SizedBox(height: 16),

        // Weekday labels
        _buildWeekdayLabels(),
        const SizedBox(height: 8),

        // Calendar grid
        Expanded(
          child: GridView.count(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: days.map((date) {
              final isCurrentMonth = date.month == _currentDate.month;
              final items = _getItemsForDate(date);
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              return _buildDateCell(date, isCurrentMonth, isToday, items);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthHeader() {
    final monthYear = DateFormat('MMMM yyyy').format(_currentDate);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
            });
          },
        ),
        Text(
          monthYear,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            setState(() {
              _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
            });
          },
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels() {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateCell(DateTime date, bool isCurrentMonth, bool isToday, List<AggregatedCalendarItem> items) {
    return GestureDetector(
      onTap: isCurrentMonth ? () => setState(() => _selectedDate = date) : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isToday ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isToday ? Colors.blue : Colors.grey.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCurrentMonth ? Colors.black : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.take(2).map((item) {
                    final style = TypeStyleMap.getStyle(item.eventType);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: style.backgroundColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedEvent = item),
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: style.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (items.length > 2)
              Text(
                '+${items.length - 2} more',
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekView() {
    return Center(
      child: Text('Week View - Coming Soon'),
    );
  }

  Widget _buildDayView() {
    if (_selectedDate == null) {
      return const Center(child: Text('Select a date to view details'));
    }

    final items = _getItemsForDate(_selectedDate!);

    return Column(
      children: [
        Text(
          DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate!),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No events for this day'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final style = TypeStyleMap.getStyle(item.eventType);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: style.dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(item.title),
                        subtitle: Text(
                          '${item.eventType.toString().split('.').last} • ${DateFormat('h:mm a').format(item.start)}',
                        ),
                        onTap: () => setState(() => _selectedEvent = item),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
