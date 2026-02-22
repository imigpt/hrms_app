import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hrms_app/services/attendance_service.dart';
import 'package:hrms_app/services/token_storage_service.dart';
import 'package:hrms_app/models/attendance_edit_request_model.dart';

class AttendanceEditRequestsCard extends StatefulWidget {
  final String? userId;

  const AttendanceEditRequestsCard({
    super.key,
    this.userId,
  });

  @override
  State<AttendanceEditRequestsCard> createState() =>
      _AttendanceEditRequestsCardState();
}

class _AttendanceEditRequestsCardState
    extends State<AttendanceEditRequestsCard> {
  bool _isLoading = true;
  List<AttendanceEditRequestData> _editRequests = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEditRequests();
  }

  Future<void> _loadEditRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final token = await TokenStorageService().getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await AttendanceService.getEditRequests(token: token);

      if (response.success && mounted) {
        setState(() {
          _editRequests = response.data.take(3).toList();
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.edit_note_outlined,
                    color: Colors.pinkAccent,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Requests',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (!_isLoading)
                IconButton(
                  icon: const Icon(Icons.refresh,
                      color: Colors.pinkAccent, size: 20),
                  onPressed: _loadEditRequests,
                  tooltip: 'Refresh',
                )
            ],
          ),
          const SizedBox(height: 16),

          // Content
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
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
          else if (_editRequests.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: Colors.green.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No pending requests',
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _editRequests.asMap().entries.map((entry) {
                final request = entry.value;
                final isLast = entry.key == _editRequests.length - 1;

                return Column(
                  children: [
                    _buildRequestItem(request),
                    if (!isLast) ...[
                      const SizedBox(height: 12),
                      const Divider(
                        color: Colors.white24,
                        height: 1,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(AttendanceEditRequestData request) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMMM dd, yyyy').format(request.date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getStatusColor(request.status).withOpacity(0.4),
                  ),
                ),
                child: Text(
                  request.status[0].toUpperCase() + request.status.substring(1),
                  style: TextStyle(
                    color: _getStatusColor(request.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Time info
          Row(
            children: [
              Icon(Icons.access_time_outlined,
                  color: Colors.grey.withOpacity(0.6), size: 16),
              const SizedBox(width: 6),
              Text(
                '${DateFormat('HH:mm').format(request.requestedCheckIn)} - ${DateFormat('HH:mm').format(request.requestedCheckOut)}',
                style: TextStyle(
                  color: Colors.grey.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (request.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note_outlined,
                    color: Colors.grey.withOpacity(0.6), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    request.reason,
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.6),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
