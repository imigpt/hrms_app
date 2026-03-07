import 'package:flutter/material.dart';
import 'package:hrms_app/models/apply_leave_model.dart';
import 'package:hrms_app/screen/apply_leave_screen.dart' hide LeaveBalance;
import 'package:hrms_app/services/leave_service.dart';
import 'package:hrms_app/services/token_storage_service.dart';
import 'package:hrms_app/theme/app_theme.dart';

class LeaveStatisticsSection extends StatefulWidget {
  final String? userId;

  const LeaveStatisticsSection({super.key, this.userId});

  @override
  State<LeaveStatisticsSection> createState() => _LeaveStatisticsSectionState();
}

class _LeaveStatisticsSectionState extends State<LeaveStatisticsSection> {
  bool _isLoading = true;
  LeaveBalance? _leaveBalance;
  Map<String, dynamic>? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final storage = TokenStorageService();
      final token = await storage.getToken();
      if (token == null) {
        throw Exception('Authentication data not found');
      }

      final results = await Future.wait([
        LeaveService.getLeaveBalance(token: token),
        LeaveService.getLeaveStatistics(
          token: token,
          year: DateTime.now().year,
        ),
      ]);

      final balanceResponse = results[0] as LeaveBalanceResponse;
      final statsResponse = results[1];

      if (mounted) {
        setState(() {
          // Parse balance response
          if (balanceResponse.success && balanceResponse.data != null) {
            _leaveBalance = balanceResponse.data;
          }

          // Parse stats response safely
          if (statsResponse is Map<String, dynamic>) {
            if (statsResponse['success'] == true &&
                statsResponse['data'] != null) {
              final data = statsResponse['data'];
              if (data is Map<String, dynamic>) {
                _stats = _sanitizeStats(data);
              }
            }
          }

          // Initialize empty stats if none loaded
          _stats ??= _emptyStats();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _goToApplyLeave() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LeaveScreen()));
  }

  // ─── data helpers ─────────────────────────────────────────────────────────
  /// Safely convert double/num to int
  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Sanitize stats to ensure all values are proper types
  Map<String, dynamic> _sanitizeStats(Map<String, dynamic> raw) {
    // Safely convert byType map values
    final byTypeMap = <String, int>{};
    if (raw['byType'] is Map) {
      (raw['byType'] as Map).forEach((key, value) {
        byTypeMap[key.toString()] = _toInt(value);
      });
    }

    return {
      'total': _toInt(raw['total']),
      'approved': _toInt(raw['approved']),
      'pending': _toInt(raw['pending']),
      'rejected': _toInt(raw['rejected']),
      'cancelled': _toInt(raw['cancelled']),
      'daysTaken': _toInt(raw['daysTaken']),
      'byType': byTypeMap,
    };
  }

  /// Return empty stats structure
  Map<String, dynamic> _emptyStats() => {
    'total': 0,
    'approved': 0,
    'pending': 0,
    'rejected': 0,
    'cancelled': 0,
    'daysTaken': 0,
    'byType': {},
  };

  int get _total => _toInt(_stats?['total'] ?? 0);
  int get _approved => _toInt(_stats?['approved'] ?? 0);
  int get _pending => _toInt(_stats?['pending'] ?? 0);
  int get _rejected => _toInt(_stats?['rejected'] ?? 0);
  int get _cancelled => _toInt(_stats?['cancelled'] ?? 0);
  int get _daysTaken => _toInt(_stats?['daysTaken'] ?? 0);

  Map<String, int> get _byType {
    final data = _stats?['byType'];
    if (data is Map<String, int>) return data;
    if (data is Map) {
      final result = <String, int>{};
      data.forEach((key, value) {
        result[key.toString()] = _toInt(value);
      });
      return result;
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Leave Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your ${DateTime.now().year} leave overview',
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.7),
                      fontSize: 12,
                    ),
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
                  onPressed: _loadData,
                  tooltip: 'Refresh',
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                  strokeWidth: 2.5,
                ),
              ),
            )
          else if (_error != null)
            _buildError()
          else if (_stats != null && (_stats?.isNotEmpty ?? false))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Status breakdown
                Text(
                  'Request Status',
                  style: TextStyle(
                    color: Colors.grey.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatusTile(
                      Icons.check_circle_outline,
                      'Approved',
                      _approved,
                      Colors.green,
                    ),
                    const SizedBox(width: 10),
                    _buildStatusTile(
                      Icons.hourglass_empty_rounded,
                      'Pending',
                      _pending,
                      Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStatusTile(
                      Icons.cancel_outlined,
                      'Rejected',
                      _rejected,
                      Colors.red,
                    ),
                    const SizedBox(width: 10),
                    // _buildStatusTile(
                    //   Icons.block_outlined,
                    //   'Cancelled',
                    //   _cancelled,
                    //   Colors.grey,
                    // ),
                    _buildHighlight(
                      icon: Icons.summarize_outlined,
                      label: 'Total Leaves',
                      value: '$_total',
                      color: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Apply leave button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _goToApplyLeave,
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text(
                      'Apply New Leave',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─────────────────────────── Widget builders ─────────────────────────────

  Widget _buildError() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ),
      ],
    ),
  );

  // Highlight card (Total / Days Taken)
  Widget _buildHighlight({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String suffix = '',
  }) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (suffix.isNotEmpty)
                  TextSpan(
                    text: suffix,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  // Status tile (Approved / Pending / Rejected / Cancelled)
  Widget _buildStatusTile(
    IconData icon,
    String label,
    int count,
    Color color,
  ) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.withOpacity(0.65),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ],
      ),
    ),
  );
}
