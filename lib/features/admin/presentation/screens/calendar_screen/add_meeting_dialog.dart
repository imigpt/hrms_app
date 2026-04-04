import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';
import 'package:hrms_app/features/admin/presentation/providers/calendar_notifier.dart';
import 'package:hrms_app/features/admin/data/services/admin_employees_service.dart';
import 'package:intl/intl.dart';

const List<Map<String, String>> _meetingReminderOptions = [
  {'value': 'none', 'label': 'No reminder'},
  {'value': '30min', 'label': '30 minutes before'},
  {'value': '1hr', 'label': '1 hour before'},
  {'value': '1day', 'label': '1 day before'},
];

const List<Map<String, String>> _meetingTimezoneOptions = [
  {'value': 'Asia/Kolkata', 'label': 'IST (India)'},
  {'value': 'Europe/London', 'label': 'GMT/BST (UK)'},
  {'value': 'America/New_York', 'label': 'EST/EDT (New York)'},
  {'value': 'America/Los_Angeles', 'label': 'PST/PDT (Los Angeles)'},
  {'value': 'America/Chicago', 'label': 'CST/CDT (Chicago)'},
  {'value': 'Europe/Paris', 'label': 'CET/CEST (Paris)'},
  {'value': 'Asia/Singapore', 'label': 'SGT (Singapore)'},
  {'value': 'Australia/Sydney', 'label': 'AEST/AEDT (Sydney)'},
];

const List<Map<String, String>> _meetingDurationOptions = [
  {'value': '30', 'label': '30 minutes'},
  {'value': '60', 'label': '1 hour'},
  {'value': '90', 'label': '1.5 hours'},
  {'value': '120', 'label': '2 hours'},
  {'value': '180', 'label': '3 hours'},
];

// User model for members
class _User {
  final String id;
  final String name;
  final String email;

  _User({
    required this.id,
    required this.name,
    required this.email,
  });
}

class AddMeetingDialog extends StatefulWidget {
  final String? token;
  final String? userId;
  final DateTime? initialDate;

  const AddMeetingDialog({
    super.key,
    this.token,
    this.userId,
    this.initialDate,
  });

  @override
  State<AddMeetingDialog> createState() => _AddMeetingDialogState();
}

class _AddMeetingDialogState extends State<AddMeetingDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _meetingUrlController = TextEditingController();
  DateTime? _selectedDate;
  DateTime? _startTime;
  DateTime? _endTime;
  String _selectedDuration = '60'; // Duration in minutes
  String _selectedReminder = 'none';
  String _selectedTimezone = 'Asia/Kolkata';
  List<String> _selectedParticipants = [];
  List<_User> _userOptions = [];
  bool _isLoading = false;
  bool _loadingUsers = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = widget.initialDate ?? now;
    _startTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      now.hour,
      now.minute,
    );
    _endTime = _startTime!.add(Duration(minutes: int.parse(_selectedDuration)));
    
    // Fetch users when dialog initializes
    _fetchUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _meetingUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() => _loadingUsers = true);
    try {
      if (widget.token == null || widget.token!.isEmpty) {
        print('[ADD MEETING] No token available for fetching users');
        setState(() => _userOptions = []);
        return;
      }
      
      // Fetch employees using AdminEmployeesService
      final response = await AdminEmployeesService.getAllEmployees(
        widget.token!,
        role: 'admin', // Default to admin role, adjust as needed
      );
      
      final employeeList = response['data'] as List<dynamic>? ?? [];
      
      // Convert to _User objects, excluding current user
      final users = <_User>[];
      for (final emp in employeeList) {
        if (emp is Map<String, dynamic>) {
          final empId = emp['_id']?.toString() ?? '';
          // Skip current user
          if (widget.userId != null && empId != widget.userId) {
            users.add(_User(
              id: empId,
              name: emp['name']?.toString() ?? 'Unknown',
              email: emp['email']?.toString() ?? '',
            ));
          }
        }
      }
      
      if (mounted) {
        setState(() => _userOptions = users);
        print('[ADD MEETING] Loaded ${users.length} team members');
      }
    } catch (e) {
      print('[ADD MEETING] Error fetching users: $e');
      if (mounted) {
        setState(() => _userOptions = []);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingUsers = false);
      }
    }
  }

  void _toggleParticipant(String userId) {
    setState(() {
      if (_selectedParticipants.contains(userId)) {
        _selectedParticipants.remove(userId);
      } else {
        _selectedParticipants.add(userId);
      }
    });
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
        final baseStart = _startTime ?? DateTime.now();
        _startTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          baseStart.hour,
          baseStart.minute,
        );
        _endTime = _startTime!.add(Duration(minutes: int.parse(_selectedDuration)));
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
        _endTime = _startTime!.add(Duration(minutes: int.parse(_selectedDuration)));
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

  Future<void> _saveMeeting() async {
    if (widget.token == null || widget.token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to create meeting: missing token')),
      );
      return;
    }

    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter meeting title')),
      );
      return;
    }

    if (_meetingUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter meeting URL')),
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
      final meetingData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'eventDate': _startTime,
        'endDate': _endTime,
        'eventType': 'meeting',
        'allDay': false,
        'startTime': _startTime,
        'endTime': _endTime,
        'priority': 'medium',
        'reminder': _selectedReminder,
        'timezone': _selectedTimezone,
        'status': 'scheduled',
        'meetingUrl': _meetingUrlController.text,
        'participants': _selectedParticipants,
      };

      final success = await notifier.createEvent(widget.token!, meetingData);
      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notifier.state.error ?? 'Failed to create meeting')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting created successfully')),
      );

      Navigator.of(context).pop(true);
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
                    'Schedule Meeting',
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
                  hintText: 'Meeting Title',
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

              // Duration
              DropdownButtonFormField<String>(
                value: _selectedDuration,
                dropdownColor: AppTheme.cardColor,
                decoration: InputDecoration(
                  labelText: 'Duration',
                  labelStyle: TextStyle(color: Colors.grey[300]),
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
                items: _meetingDurationOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option['value'],
                        child: Text(option['label'] ?? option['value']!),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null || _startTime == null) return;
                  setState(() {
                    _selectedDuration = value;
                    _endTime = _startTime!.add(Duration(minutes: int.parse(value)));
                  });
                },
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

              // Meeting URL
              TextField(
                controller: _meetingUrlController,
                decoration: InputDecoration(
                  hintText: 'Meeting URL (e.g., Zoom, Google Meet)',
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
                  prefixIcon: const Icon(Icons.link, color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.white),
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

              // Time Selection
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

              // Members Section
              Text(
                'Members${_selectedParticipants.isNotEmpty ? ' (${_selectedParticipants.length} selected)' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (_loadingUsers)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                )
              else if (_userOptions.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    'No team members available',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _userOptions.map((user) {
                        final isSelected = _selectedParticipants.contains(user.id);
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _toggleParticipant(user.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (_) => _toggleParticipant(user.id),
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          user.email,
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 11,
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
                      }).toList(),
                    ),
                  ),
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
                  items: _meetingReminderOptions
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
                  items: _meetingTimezoneOptions
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
                        items: _meetingReminderOptions
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
                        items: _meetingTimezoneOptions
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
              const SizedBox(height: 24),

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
                    onPressed: _isLoading ? null : _saveMeeting,
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
                            'Schedule Meeting',
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
