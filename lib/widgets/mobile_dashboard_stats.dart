import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/dashboard_stats_model.dart';
import '../models/profile_model.dart';
import '../utils/responsive_utils.dart';

class MobileDashboardStats extends StatelessWidget {
  final DashboardStats? stats;
  final ProfileUser? userProfile;
  final bool isLoading;
  final VoidCallback? onRetry;

  const MobileDashboardStats({
    super.key,
    this.stats,
    this.userProfile,
    this.isLoading = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    if (isLoading) {
      return _buildLoadingState();
    }

    if (stats == null) {
      return _buildErrorState(context);
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Card (if provided)
          if (userProfile != null)
            Padding(
              padding: EdgeInsets.all(responsive.spacing),
              child: _buildProfileCard(context, responsive),
            ),

          // Attendance Chart Card
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.spacing,
              vertical: responsive.spacing / 2,
            ),
            child: _buildAttendanceCard(context, responsive),
          ),

          // Leave Summary Card
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.spacing,
              vertical: responsive.spacing / 2,
            ),
            child: _buildLeaveCard(context, responsive),
          ),

          // Quick Stats Grid
          Padding(
            padding: EdgeInsets.all(responsive.spacing),
            child: _buildQuickStatsGrid(context, responsive),
          ),
        ],
      ),
    );
  }

  // ── PROFILE CARD ───────────────────────────────────────────────────────────

  Widget _buildProfileCard(BuildContext context, ResponsiveUtils responsive) {
    final profile = userProfile!;
    final profileSize = responsive.screenWidth * 0.15;
    return Container(
      padding: EdgeInsets.all(responsive.spacing),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(responsive.spacing),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with profile pic and name
          Row(
            children: [
              // Profile Picture
              Container(
                width: profileSize,
                height: profileSize,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: const Color(0xFFFF6B6B), width: 2),
                ),
                child: profile.profilePhotoUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          profile.profilePhotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.grey, size: 32),
              ),
              SizedBox(width: responsive.spacing),
              // Name and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.headingFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      profile.position,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: responsive.bodyFontSize - 2,
                      ),
                    ),
                    SizedBox(height: responsive.spacing / 2),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing / 2,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D084),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: responsive.bodyFontSize - 3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing),
          Divider(color: Colors.grey.shade800),
          SizedBox(height: responsive.spacing / 2),
          // Contact details
          _profileDetail(Icons.phone, profile.phone, responsive),
          SizedBox(height: responsive.spacing / 2),
          _profileDetail(Icons.email, profile.email, responsive),
          SizedBox(height: responsive.spacing / 2),
          _profileDetail(Icons.location_on, profile.address, responsive),
          SizedBox(height: responsive.spacing / 2),
          _profileDetail(
            Icons.calendar_today,
            _formatDate(profile.joinDate),
            responsive,
          ),
        ],
      ),
    );
  }

  Widget _profileDetail(
    IconData icon,
    String text,
    ResponsiveUtils responsive,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFFFF6B6B),
          size: responsive.smallIconSize,
        ),
        SizedBox(width: responsive.spacing / 2),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey,
              fontSize: responsive.bodyFontSize - 2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day} ${_monthName(date.month)}, ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  // ── ATTENDANCE CARD ────────────────────────────────────────────────────────

  Widget _buildAttendanceCard(
    BuildContext context,
    ResponsiveUtils responsive,
  ) {
    final total = stats?.totalAttendance ?? 0;
    final present = stats?.presentDays ?? 0;
    final absent = stats?.absentDays ?? 0;
    final leave = stats?.leaveDays ?? 0;
    final halfDay = stats?.halfDayCount ?? 0;

    final presentPercent = total > 0 ? (present / total) * 100 : 0.0;
    final absentPercent = total > 0 ? (absent / total) * 100 : 0.0;
    final leavePercent = total > 0 ? (leave / total) * 100 : 0.0;
    final halfPercent = total > 0 ? (halfDay / total) * 100 : 0.0;

    return Container(
      padding: EdgeInsets.all(responsive.spacing),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(responsive.spacing),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: const Color(0xFFFF6B6B),
                size: responsive.smallIconSize + 4,
              ),
              SizedBox(width: responsive.spacing / 2),
              Expanded(
                child: Text(
                  'Attendance Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: responsive.headingFontSize,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing),

          // Responsive pie chart + legend
          responsive.isMobile
              ? Column(
                  children: [
                    _buildPieChart(
                      responsive,
                      presentPercent,
                      absentPercent,
                      leavePercent,
                      halfPercent,
                    ),
                    SizedBox(height: responsive.spacing),
                    _buildLegendColumn(
                      present,
                      absent,
                      leave,
                      halfDay,
                      responsive,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _buildPieChart(
                        responsive,
                        presentPercent,
                        absentPercent,
                        leavePercent,
                        halfPercent,
                      ),
                    ),
                    SizedBox(width: responsive.spacing),
                    Expanded(
                      child: _buildLegendColumn(
                        present,
                        absent,
                        leave,
                        halfDay,
                        responsive,
                      ),
                    ),
                  ],
                ),
          SizedBox(height: responsive.spacing),

          // Total Count
          Container(
            padding: EdgeInsets.all(responsive.spacing),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(responsive.spacing / 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Attendance',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: responsive.bodyFontSize,
                  ),
                ),
                Text(
                  '$total days',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: responsive.headingFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(
    ResponsiveUtils responsive,
    double presentPercent,
    double absentPercent,
    double leavePercent,
    double halfPercent,
  ) {
    return SizedBox(
      height: responsive.isMobile
          ? responsive.screenHeight * 0.2
          : responsive.screenHeight * 0.25,
      child: PieChart(
        PieChartData(
          sections: [
            if (presentPercent > 0)
              PieChartSectionData(
                value: presentPercent,
                color: const Color(0xFF00D084),
                title: '',
                radius: responsive.isMobile ? 35 : 50,
              ),
            if (absentPercent > 0)
              PieChartSectionData(
                value: absentPercent,
                color: const Color(0xFFFF6B6B),
                title: '',
                radius: responsive.isMobile ? 35 : 50,
              ),
            if (leavePercent > 0)
              PieChartSectionData(
                value: leavePercent,
                color: const Color(0xFF4ECDC4),
                title: '',
                radius: responsive.isMobile ? 35 : 50,
              ),
            if (halfPercent > 0)
              PieChartSectionData(
                value: halfPercent,
                color: const Color(0xFFFFA500),
                title: '',
                radius: responsive.isMobile ? 35 : 50,
              ),
          ],
          centerSpaceRadius: responsive.isMobile ? 20 : 35,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildLegendColumn(
    int present,
    int absent,
    int leave,
    int halfDay,
    ResponsiveUtils responsive,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegendItem(
          'Present',
          present,
          const Color(0xFF00D084),
          responsive,
        ),
        SizedBox(height: responsive.spacing / 2),
        _buildLegendItem('Absent', absent, const Color(0xFFFF6B6B), responsive),
        SizedBox(height: responsive.spacing / 2),
        _buildLegendItem('Leave', leave, const Color(0xFF4ECDC4), responsive),
        SizedBox(height: responsive.spacing / 2),
        _buildLegendItem(
          'Half Day',
          halfDay,
          const Color(0xFFFFA500),
          responsive,
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    String label,
    int count,
    Color color,
    ResponsiveUtils responsive,
  ) {
    return Row(
      children: [
        Container(
          width: responsive.isMobile ? 10 : 12,
          height: responsive.isMobile ? 10 : 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: responsive.spacing / 2),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: responsive.bodyFontSize - 2,
            ),
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: responsive.bodyFontSize + 1,
          ),
        ),
      ],
    );
  }

  // ── LEAVE CARD ─────────────────────────────────────────────────────────────

  Widget _buildLeaveCard(BuildContext context, ResponsiveUtils responsive) {
    final totalLeaves = stats?.totalLeaves ?? 0;
    final approved = stats?.approvedLeaves ?? 0;
    final rejected = stats?.rejectedLeaves ?? 0;
    final pending = stats?.pendingLeaves ?? 0;

    return Container(
      padding: EdgeInsets.all(responsive.spacing),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(responsive.spacing),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.time_to_leave,
                color: const Color(0xFF4ECDC4),
                size: responsive.smallIconSize + 4,
              ),
              SizedBox(width: responsive.spacing / 2),
              Text(
                'Leave Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: responsive.headingFontSize,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing),

          // Leave Stats Grid (2x2 on mobile, responsive on tablet)
          GridView.count(
            crossAxisCount: responsive.isMobile ? 2 : 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: responsive.spacing / 2,
            mainAxisSpacing: responsive.spacing / 2,
            children: [
              _buildLeaveStatBox(
                'Total Leaves',
                totalLeaves.toString(),
                Colors.blue,
                responsive,
              ),
              _buildLeaveStatBox(
                'Approved',
                approved.toString(),
                const Color(0xFF00D084),
                responsive,
              ),
              _buildLeaveStatBox(
                'Rejected',
                rejected.toString(),
                const Color(0xFFFF6B6B),
                responsive,
              ),
              _buildLeaveStatBox(
                'Pending',
                pending.toString(),
                const Color(0xFFFFA500),
                responsive,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveStatBox(
    String label,
    String value,
    Color color,
    ResponsiveUtils responsive,
  ) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing / 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(responsive.spacing / 2),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: responsive.isMobile
                  ? responsive.headingFontSize + 4
                  : responsive.headingFontSize + 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: responsive.spacing / 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: responsive.bodyFontSize - 3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── QUICK STATS GRID ───────────────────────────────────────────────────────

  Widget _buildQuickStatsGrid(
    BuildContext context,
    ResponsiveUtils responsive,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: responsive.spacing / 2,
      mainAxisSpacing: responsive.spacing / 2,
      children: [
        _buildQuickStatCard(
          'On Time',
          '${stats?.onTimeCount ?? 0}',
          Icons.check_circle,
          const Color(0xFF00D084),
          responsive,
        ),
        _buildQuickStatCard(
          'Late',
          '${stats?.lateCount ?? 0}',
          Icons.schedule,
          const Color(0xFFFFA500),
          responsive,
        ),
        _buildQuickStatCard(
          'Early Checkout',
          '${stats?.earlyCheckout ?? 0}',
          Icons.logout,
          Colors.purple,
          responsive,
        ),
        _buildQuickStatCard(
          'Work Hours',
          '${(stats?.totalWorkHours ?? 0).toStringAsFixed(1)} hrs',
          Icons.timer,
          Colors.blue,
          responsive,
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ResponsiveUtils responsive,
  ) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing / 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(responsive.spacing / 2),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: responsive.isMobile ? 24 : 32),
          SizedBox(height: responsive.spacing / 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: responsive.isMobile ? 16 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: responsive.spacing / 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: responsive.bodyFontSize - 3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── STATES ─────────────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF6B6B), width: 1),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 48),
          const SizedBox(height: 12),
          Text(
            'Unable to load statistics',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
