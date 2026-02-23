import 'package:flutter/material.dart';
import 'package:hrms_app/models/apply_leave_model.dart';
import 'package:hrms_app/screen/apply_leave_screen.dart' hide LeaveBalance;
import 'package:hrms_app/services/leave_service.dart';
import 'package:hrms_app/services/token_storage_service.dart';
import 'package:hrms_app/theme/app_theme.dart';

class LeaveStatisticsSection extends StatefulWidget {
  final String? userId;

  const LeaveStatisticsSection({
    super.key,
    this.userId,
  });

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
            token: token, year: DateTime.now().year),
      ]);

      final balanceResponse = results[0] as LeaveBalanceResponse;
      final statsResponse = results[1] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          if (balanceResponse.success && balanceResponse.data != null) {
            _leaveBalance = balanceResponse.data;
          }
          if (statsResponse['success'] == true &&
              statsResponse['data'] != null) {
            _stats = statsResponse['data'] as Map<String, dynamic>;
          }
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LeaveScreen()),
    );
  }

  // ─── data helpers ─────────────────────────────────────────────────────────
  int get _total => (_stats?['total'] ?? 0) as int;
  int get _approved => (_stats?['approved'] ?? 0) as int;
  int get _pending => (_stats?['pending'] ?? 0) as int;
  int get _rejected => (_stats?['rejected'] ?? 0) as int;
  int get _cancelled => (_stats?['cancelled'] ?? 0) as int;
  int get _daysTaken => (_stats?['daysTaken'] ?? 0) as int;
  Map get _byType => (_stats?['byType'] as Map?) ?? {};

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.25),
                        AppTheme.primaryColor.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.beach_access_outlined,
                      color: AppTheme.primaryColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Leave Summary',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3)),
                      Text('Your ${DateTime.now().year} leave overview',
                          style: TextStyle(
                              color: Colors.grey.withOpacity(0.55),
                              fontSize: 12,
                              fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
                if (!_isLoading)
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: AppTheme.primaryColor, size: 22),
                      onPressed: _loadData,
                      tooltip: 'Refresh',
                      padding: const EdgeInsets.all(8),
                      splashRadius: 20,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.08), height: 1, indent: 20, endIndent: 20),

          // ── Content ───────────────────────────────────────────────────────
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  strokeWidth: 2.5,
                ),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildError(),
            )
          else
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Summary highlight row ─────────────────────────────
                  if (_stats != null) ...[
                    Row(
                      children: [
                        _buildHighlight(
                          icon: Icons.summarize_outlined,
                          label: 'Total Requests',
                          value: '$_total',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildHighlight(
                          icon: Icons.calendar_today_outlined,
                          label: 'Days Taken',
                          value: '$_daysTaken',
                          color: AppTheme.primaryColor,
                          suffix: 'd',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── 2. Status breakdown 2×2 ──────────────────────────
                    _buildSectionLabel('Request Status'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatusTile(
                            Icons.check_circle_outline,
                            'Approved',
                            _approved,
                            Colors.green),
                        const SizedBox(width: 10),
                        _buildStatusTile(
                            Icons.hourglass_empty_rounded,
                            'Pending',
                            _pending,
                            Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatusTile(
                            Icons.cancel_outlined,
                            'Rejected',
                            _rejected,
                            Colors.red),
                        const SizedBox(width: 10),
                        _buildStatusTile(
                            Icons.block_outlined,
                            'Cancelled',
                            _cancelled,
                            Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── 3. Days used by leave type ───────────────────────
                    if (_byType.isNotEmpty) ...[
                      _buildSectionLabel('Days Used by Type'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildTypePill('Paid',
                              (_byType['paid'] ?? 0) as int,
                              Colors.purpleAccent),
                          const SizedBox(width: 10),
                          _buildTypePill('Sick',
                              (_byType['sick'] ?? 0) as int,
                              Colors.teal),
                          const SizedBox(width: 10),
                          _buildTypePill('Unpaid',
                              (_byType['unpaid'] ?? 0) as int,
                              Colors.amber),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],

                  // ── 4. Leave balance ─────────────────────────────────────
                  if (_leaveBalance != null) ...[
                    _buildSectionLabel('Leave Balance'),
                    const SizedBox(height: 10),
                    _buildBalanceRow(
                      label: 'Paid Leave',
                      available: _leaveBalance!.paid,
                      used: _leaveBalance!.usedPaid,
                      color: Colors.purpleAccent,
                      icon: Icons.work_history_outlined,
                    ),
                    const SizedBox(height: 10),
                    _buildBalanceRow(
                      label: 'Sick Leave',
                      available: _leaveBalance!.sick,
                      used: _leaveBalance!.usedSick,
                      color: Colors.teal,
                      icon: Icons.medical_services_outlined,
                    ),
                    const SizedBox(height: 10),
                    _buildBalanceRow(
                      label: 'Unpaid Leave',
                      available: _leaveBalance!.unpaid,
                      used: _leaveBalance!.usedUnpaid,
                      color: Colors.amber,
                      icon: Icons.money_off_outlined,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── 5. Apply leave CTA ───────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _goToApplyLeave,
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text(
                        'Apply New Leave',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
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
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13))),
        ]),
      );

  Widget _buildSectionLabel(String text) => Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.withOpacity(0.5),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );

  // Large highlight card (Total / Days Taken)
  Widget _buildHighlight({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String suffix = '',
  }) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    if (suffix.isNotEmpty)
                      TextSpan(
                        text: suffix,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

  // Status tile (Approved / Pending / Rejected / Cancelled)
  Widget _buildStatusTile(
          IconData icon, String label, int count, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.22)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(label,
                        style: TextStyle(
                            color: Colors.grey.withOpacity(0.65),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('$count',
                  style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1)),
            ],
          ),
        ),
      );

  Widget _buildTypePill(String label, int days, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$days',
                  style: TextStyle(
                      color: color,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: Colors.grey.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );

  // Balance row with progress bar (available vs used)
  Widget _buildBalanceRow({
    required String label,
    required int available,
    required int used,
    required Color color,
    required IconData icon,
  }) {
    final total = available + used;
    final usedFraction = total > 0 ? used / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: '$available ',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: '/ ${total} d',
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: usedFraction.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$available available',
                  style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              Text('$used used',
                  style: TextStyle(
                      color: Colors.grey.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
