import 'package:flutter/material.dart';
import 'package:hrms_app/models/apply_leave_model.dart';
import 'package:hrms_app/services/leave_service.dart';
import 'package:hrms_app/services/token_storage_service.dart';

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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeaveBalance();
  }

  Future<void> _loadLeaveBalance() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final storage = TokenStorageService();
      final token = await storage.getToken();
      final userId = widget.userId ?? await storage.getUserId();
      if (token == null || userId == null) {
        throw Exception('Authentication data not found');
      }

      final response = await LeaveService.getLeaveBalance(
        token: token,
        userId: userId,
      );

      if (response.success && response.data != null) {
        setState(() {
          _leaveBalance = response.data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
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
                    Icons.beach_access_outlined,
                    color: Colors.pinkAccent,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Leave Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Your leave summary',
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
                  icon: const Icon(Icons.refresh, color: Colors.pinkAccent, size: 20),
                  onPressed: _loadLeaveBalance,
                  tooltip: 'Refresh',
                )
            ],
          ),
          const SizedBox(height: 20),

          // Content
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
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
          else if (_leaveBalance != null)
            Column(
              children: [
                // Statistics Grid (2 columns x 3 rows)
                GridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      'Paid Balance',
                      _leaveBalance!.paid.toString(),
                      Colors.purpleAccent,
                    ),
                    _buildStatCard(
                      'Sick Balance',
                      _leaveBalance!.sick.toString(),
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Unpaid Balance',
                      _leaveBalance!.unpaid.toString(),
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'Used Paid',
                      _leaveBalance!.usedPaid.toString(),
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Used Sick',
                      _leaveBalance!.usedSick.toString(),
                      Colors.red,
                    ),
                    _buildStatCard(
                      'Used Unpaid',
                      _leaveBalance!.usedUnpaid.toString(),
                      Colors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Apply New Leave Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      // Navigate to apply leave screen
                      Navigator.of(context).pushNamed('/apply-leave');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Apply New Leave',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: const Text(
                'No leave balance data',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
