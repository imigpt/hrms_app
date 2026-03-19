import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/attendance_service.dart';
import '../services/token_storage_service.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';

class AttendanceEditRequestDialog extends StatefulWidget {
  final String date;
  final String checkIn;
  final String checkOut;
  final String attendanceId;
  final VoidCallback? onSuccess;

  const AttendanceEditRequestDialog({
    super.key,
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.attendanceId,
    this.onSuccess,
  });

  @override
  State<AttendanceEditRequestDialog> createState() =>
      _AttendanceEditRequestDialogState();
}

class _AttendanceEditRequestDialogState
    extends State<AttendanceEditRequestDialog> {
  late TextEditingController _checkInController;
  late TextEditingController _checkOutController;
  late TextEditingController _reasonController;
  int _characterCount = 0;
  final int _minCharacters = 10;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checkInController = TextEditingController(
      text: widget.checkIn == '-' ? '' : widget.checkIn,
    );
    _checkOutController = TextEditingController(
      text: widget.checkOut == '-' ? '' : widget.checkOut,
    );
    _reasonController = TextEditingController();
    _reasonController.addListener(() {
      setState(() {
        _characterCount = _reasonController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _checkInController.dispose();
    _checkOutController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  /// Tries multiple time formats and returns a parsed DateTime, or null if all fail
  DateTime? _tryParseTime(String input) {
    final trimmed = input.trim();
    final formats = [
      DateFormat('hh:mm a'), // 09:30 AM
      DateFormat('h:mm a'), // 9:30 AM
      DateFormat('HH:mm'), // 14:30
      DateFormat('H:mm'), // 9:30
      DateFormat('hh:mma'), // 09:30AM
      DateFormat('h:mma'), // 9:30AM
    ];
    for (final fmt in formats) {
      try {
        return fmt.parseStrict(trimmed);
      } catch (_) {}
    }
    return null;
  }

  Future<void> _pickTime(TextEditingController controller) async {
    // Try to pre-fill picker from existing text
    TimeOfDay initial = TimeOfDay.now();
    final parsed = _tryParseTime(controller.text);
    if (parsed != null) {
      initial = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      final dateTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      controller.text = DateFormat('hh:mm a').format(dateTime);
      setState(() {});
    }
  }

  Future<void> _submitRequest() async {
    // Validation: Check reason length
    if (_characterCount < _minCharacters) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please provide at least $_minCharacters characters for the reason',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation: Check times
    if (_checkInController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide check-in time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_checkOutController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide check-out time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get authentication token
      final token = await TokenStorageService().getToken();
      if (token == null) {
        throw Exception('No token found. Please login again.');
      }

      print('📝 [EDIT REQUEST] === Submitting Edit Request ===');
      print('📝 [EDIT REQUEST] Attendance ID: ${widget.attendanceId}');
      print('📝 [EDIT REQUEST] Date: ${widget.date}');
      print('📝 [EDIT REQUEST] Check In: ${_checkInController.text}');
      print('📝 [EDIT REQUEST] Check Out: ${_checkOutController.text}');
      print('📝 [EDIT REQUEST] Reason: ${_reasonController.text}');

      // Parse the date from "MMM d, y" format to ISO format
      final dateFormat = DateFormat('MMM d, y');
      final parsedDate = dateFormat.parse(widget.date);
      final isoDate = DateFormat('yyyy-MM-dd').format(parsedDate);

      // Convert time strings to ISO format (flexible parsing)
      final checkInTime = _tryParseTime(_checkInController.text);
      if (checkInTime == null) {
        throw Exception(
          'Invalid check-in time format. Use format like "09:30 AM"',
        );
      }
      final checkInDateTime = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        checkInTime.hour,
        checkInTime.minute,
      );

      final checkOutTime = _tryParseTime(_checkOutController.text);
      if (checkOutTime == null) {
        throw Exception(
          'Invalid check-out time format. Use format like "05:30 PM"',
        );
      }
      final checkOutDateTime = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        checkOutTime.hour,
        checkOutTime.minute,
      );

      print('📝 [EDIT REQUEST] Formatted Date: $isoDate');
      print(
        '📝 [EDIT REQUEST] Check In DateTime: ${checkInDateTime.toIso8601String()}',
      );
      print(
        '📝 [EDIT REQUEST] Check Out DateTime: ${checkOutDateTime.toIso8601String()}',
      );

      if (widget.attendanceId.isEmpty) {
        throw Exception('Attendance ID is missing. Please try again.');
      }

      // Call API to submit edit request
      final response = await AttendanceService.submitEditRequest(
        token: token,
        attendanceId: widget.attendanceId,
        requestedCheckIn: checkInDateTime.toIso8601String(),
        requestedCheckOut: checkOutDateTime.toIso8601String(),
        reason: _reasonController.text,
      );

      print('✅ [EDIT REQUEST] Response: ${response.message}');

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ [EDIT REQUEST] Error: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        String errorMessage = e.toString();
        if (errorMessage.contains('Exception:')) {
          errorMessage = errorMessage.replaceFirst('Exception:', '').trim();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Request Attendance Edit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Submit a request to edit your check in/out times for ${widget.date}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF1A1A1A)),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Record
                    const Text(
                      'Current Record:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Check In',
                            widget.checkIn == '-'
                                ? 'Not recorded'
                                : widget.checkIn,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            'Check Out',
                            widget.checkOut == '-'
                                ? 'Not recorded'
                                : widget.checkOut,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Corrected Check In Time
                    _buildLabel('Corrected Check In Time', isRequired: true),
                    const SizedBox(height: 8),
                    _buildTimeField(_checkInController),

                    const SizedBox(height: 20),

                    // Corrected Check Out Time
                    _buildLabel('Corrected Check Out Time', isRequired: true),
                    const SizedBox(height: 8),
                    _buildTimeField(_checkOutController),

                    const SizedBox(height: 20),

                    // Reason for Edit Request
                    _buildLabel('Reason for Edit Request', isRequired: true),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _characterCount >= _minCharacters
                              ? Colors.white.withOpacity(0.1)
                              : Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _reasonController,
                        maxLines: 4,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Explain why you need to edit this attendance record (minimum $_minCharacters characters)',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_characterCount/$_minCharacters characters minimum',
                      style: TextStyle(
                        color: _characterCount >= _minCharacters
                            ? Colors.grey[600]
                            : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: Color(0xFF1A1A1A)),

            // Footer Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          (_characterCount >= _minCharacters && !_isSubmitting)
                          ? _submitRequest
                          : null,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, size: 18),
                      label: Text(
                        _isSubmitting ? 'Submitting...' : 'Submit Request',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey[800],
                        disabledForegroundColor: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isRequired)
          const Text(' *', style: TextStyle(color: Colors.red, fontSize: 14)),
      ],
    );
  }

  Widget _buildTimeField(TextEditingController controller) {
    final isValid =
        controller.text.isEmpty || _tryParseTime(controller.text) != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: controller.text.isNotEmpty && !isValid
                  ? Colors.red.withOpacity(0.6)
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
            keyboardType: TextInputType.streetAddress,
            enableSuggestions: false,
            autocorrect: false,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9: AaPpMm]')),
              LengthLimitingTextInputFormatter(8),
            ],
            decoration: InputDecoration(
              hintText: '09:30 AM',
              hintStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.access_time_rounded,
                  color: AppTheme.primaryColor.withOpacity(0.7),
                  size: 22,
                ),
                onPressed: () => _pickTime(controller),
                tooltip: 'Pick from clock',
              ),
            ),
          ),
        ),
        if (controller.text.isNotEmpty && !isValid)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'Invalid format — use 09:30 AM or 14:30',
              style: TextStyle(color: Colors.red[400], fontSize: 11),
            ),
          ),
      ],
    );
  }
}
