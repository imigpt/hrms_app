import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';
import 'package:hrms_app/features/admin/presentation/providers/calendar_notifier.dart';
import 'package:intl/intl.dart';

const List<Map<String, String>> _reminderOptions = [
  {'value': 'none', 'label': 'No reminder'},
  {'value': '30min', 'label': '30 minutes before'},
  {'value': '1hr', 'label': '1 hour before'},
  {'value': '1day', 'label': '1 day before'},
];

const List<Map<String, String>> _timezoneOptions = [
  {'value': 'Asia/Kolkata', 'label': 'IST (India)'},
  {'value': 'Europe/London', 'label': 'GMT/BST (UK)'},
  {'value': 'America/New_York', 'label': 'EST/EDT (New York)'},
  {'value': 'America/Los_Angeles', 'label': 'PST/PDT (Los Angeles)'},
  {'value': 'America/Chicago', 'label': 'CST/CDT (Chicago)'},
  {'value': 'Europe/Paris', 'label': 'CET/CEST (Paris)'},
  {'value': 'Asia/Singapore', 'label': 'SGT (Singapore)'},
  {'value': 'Australia/Sydney', 'label': 'AEST/AEDT (Sydney)'},
];

class AddEventDialog extends StatefulWidget {
  final String? token;
  final String? userId;
  final DateTime? initialDate;
  final String initialType;

  const AddEventDialog({
    super.key,
    this.token,
    this.userId,
    this.initialDate,
    this.initialType = 'event',
  });

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  DateTime? _startTime;
  DateTime? _endTime;
  String _selectedType = 'event';
  String _selectedPriority = 'medium';
  String _selectedReminder = 'none';
  String _selectedTimezone = 'Asia/Kolkata';
  bool _isAllDay = false;
  bool _isLoading = false;

  final List<String> _eventTypes = [
    'event',
    'meeting',
    'reminder',
  ];

  final List<String> _priorities = ['low', 'medium', 'high', 'critical'];

  @override
  void initState() {
    super.initState();
    _selectedType = _eventTypes.contains(widget.initialType)
        ? widget.initialType
        : 'event';
    _selectedDate = widget.initialDate ?? DateTime.now();
    _startTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      9,
      0,
    );
    _endTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      10,
      0,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color _getEventTypeColor(String type) {
    switch (type.toLowerCase()) {
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
      default:
        return Colors.blue;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: AppTheme.cardColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // Update times to match new date
        _startTime = DateTime(picked.year, picked.month, picked.day, 9, 0);
        _endTime = DateTime(picked.year, picked.month, picked.day, 10, 0);
      });
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime ?? DateTime.now()),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: AppTheme.cardColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && _selectedDate != null) {
      setState(() {
        _startTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime ?? DateTime.now()),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: AppTheme.cardColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && _selectedDate != null) {
      setState(() {
        _endTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _saveEvent() async {
    if (widget.token == null || widget.token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to create event: missing token')),
      );
      return;
    }

    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter event title')),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (!mounted) return;
      
      final notifier = Provider.of<CalendarNotifier>(context, listen: false);
      
      // Create event via API
      final startTime = _startTime ?? DateTime.now();
      final endTime = _endTime ?? DateTime.now().add(const Duration(hours: 1));
      final selectedDate = _selectedDate ?? DateTime.now();
      
      final eventData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'eventDate': _isAllDay ? selectedDate.toIso8601String() : startTime.toIso8601String(),
        'endDate': _isAllDay ? selectedDate.toIso8601String() : endTime.toIso8601String(),
        'eventType': _selectedType == 'event' ? 'manual' : _selectedType,
        'allDay': _isAllDay,
        'startTime': _isAllDay ? null : startTime.toIso8601String(),
        'endTime': _isAllDay ? null : endTime.toIso8601String(),
        'priority': _selectedPriority,
        'reminder': _selectedReminder,
        'timezone': _selectedTimezone,
        'status': 'scheduled',
      };
      
      final success = await notifier.createEvent(widget.token!, eventData);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notifier.state.error ?? 'Failed to create event')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: AppTheme.cardColor,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 40,
        vertical: isMobile ? 16 : 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create New Event',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title Field
              const Text(
                'Title *',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Event Title',
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),

              // Description Field
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Description (optional)',
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Event Type
              Text(
                'Event Type',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _eventTypes
                    .map((type) => FilterChip(
                          selected: _selectedType == type,
                          onSelected: (selected) {
                            setState(() => _selectedType = type);
                          },
                          backgroundColor: Colors.transparent,
                          selectedColor: _getEventTypeColor(type).withOpacity(0.3),
                          side: BorderSide(
                            color: _selectedType == type
                                ? _getEventTypeColor(type)
                                : Colors.white.withOpacity(0.2),
                          ),
                          label: Text(
                            type,
                            style: TextStyle(
                              color: _getEventTypeColor(type),
                              fontSize: 12,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Priority
              Text(
                'Priority',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _priorities
                    .map((priority) => FilterChip(
                          selected: _selectedPriority == priority,
                          onSelected: (selected) {
                            setState(() => _selectedPriority = priority);
                          },
                          backgroundColor: Colors.transparent,
                          selectedColor: _getPriorityColor(priority).withOpacity(0.3),
                          side: BorderSide(
                            color: _selectedPriority == priority
                                ? _getPriorityColor(priority)
                                : Colors.white.withOpacity(0.2),
                          ),
                          label: Text(
                            priority,
                            style: TextStyle(
                              color: _getPriorityColor(priority),
                              fontSize: 12,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Reminder and Timezone
              if (isMobile) ...[
                DropdownButtonFormField<String>(
                  value: _selectedReminder,
                  dropdownColor: AppTheme.cardColor,
                  decoration: InputDecoration(
                    labelText: 'Reminder',
                    labelStyle: TextStyle(color: Colors.grey[300]),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: _reminderOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option['value'],
                          child: Text(option['label'] ?? option['value']!),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedReminder = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedTimezone,
                  dropdownColor: AppTheme.cardColor,
                  decoration: InputDecoration(
                    labelText: 'Timezone',
                    labelStyle: TextStyle(color: Colors.grey[300]),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: _timezoneOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option['value'],
                          child: Text(option['label'] ?? option['value']!),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedTimezone = value);
                  },
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedReminder,
                        dropdownColor: AppTheme.cardColor,
                        decoration: InputDecoration(
                          labelText: 'Reminder',
                          labelStyle: TextStyle(color: Colors.grey[300]),
                          filled: true,
                          fillColor: AppTheme.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        items: _reminderOptions
                            .map(
                              (option) => DropdownMenuItem<String>(
                                value: option['value'],
                                child: Text(option['label'] ?? option['value']!),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedReminder = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTimezone,
                        dropdownColor: AppTheme.cardColor,
                        decoration: InputDecoration(
                          labelText: 'Timezone',
                          labelStyle: TextStyle(color: Colors.grey[300]),
                          filled: true,
                          fillColor: AppTheme.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        items: _timezoneOptions
                            .map(
                              (option) => DropdownMenuItem<String>(
                                value: option['value'],
                                child: Text(option['label'] ?? option['value']!),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedTimezone = value);
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Date Selection
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('MMM d, yyyy').format(_selectedDate!)
                              : 'Select Date',
                          style: TextStyle(
                            color: _selectedDate != null ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // All Day Toggle
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'All Day Event',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isAllDay,
                    onChanged: (value) => setState(() => _isAllDay = value),
                    activeColor: AppTheme.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Time Selection (Hidden if All Day)
              if (!_isAllDay) ...[
                isMobile
                    ? Column(
                        children: [
                          GestureDetector(
                            onTap: _selectStartTime,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      color: Colors.grey, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _startTime != null
                                          ? DateFormat('h:mm a').format(_startTime!)
                                          : 'Start Time',
                                      style: TextStyle(
                                        color: _startTime != null
                                            ? Colors.white
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _selectEndTime,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      color: Colors.grey, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _endTime != null
                                          ? DateFormat('h:mm a').format(_endTime!)
                                          : 'End Time',
                                      style: TextStyle(
                                        color: _endTime != null
                                            ? Colors.white
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                      child: GestureDetector(
                        onTap: _selectStartTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time,
                                  color: Colors.grey, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _startTime != null
                                      ? DateFormat('h:mm a').format(_startTime!)
                                      : 'Start Time',
                                  style: TextStyle(
                                    color: _startTime != null
                                        ? Colors.white
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                          const SizedBox(width: 12),
                          Expanded(
                      child: GestureDetector(
                        onTap: _selectEndTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time,
                                  color: Colors.grey, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _endTime != null
                                      ? DateFormat('h:mm a').format(_endTime!)
                                      : 'End Time',
                                  style: TextStyle(
                                    color: _endTime != null
                                        ? Colors.white
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                        ],
                      ),
                const SizedBox(height: 16),
              ],

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Create Event',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
