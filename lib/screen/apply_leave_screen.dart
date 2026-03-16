import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/leave_service.dart';
import '../services/token_storage_service.dart';
import '../services/notification_service.dart';
import '../utils/responsive_utils.dart';
import '../theme/app_theme.dart';
// import 'leave_api_test_screen.dart';

// --- MODELS ---
class LeaveRequest {
  final String type;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final String status; // 'Pending', 'Approved', 'Rejected'

  LeaveRequest({
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    this.status = 'Pending',
  });
}

class LeaveBalance {
  final String type;
  final int remaining;
  final int used;
  final int total;

  LeaveBalance({
    required this.type,
    required this.remaining,
    required this.used,
    required this.total,
  });
}

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: LeaveScreen()),
  );
}

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key, String? token});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  // --- DATA ---
  List<LeaveBalance> _leaveBalances = [];
  bool _isLoadingBalance = false;

  final List<LeaveRequest> _leaveRequests = [];
  bool _isLoadingRequests = false;

  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
  ];

  // Track which leave IDs have been notified for status changes
  final Set<String> _notifiedLeaveIds = {};

  // --- COLORS ---
  Color get kBackground => AppTheme.background;
  Color get kCardColor => AppTheme.cardColor;
  Color get kPinkAccent => AppTheme.primaryColor;
  Color get kTextRed => AppTheme.errorColor;
  Color get kTextWhite => Colors.white;
  Color get kTextGrey => Colors.grey;
  Color get kBorderGrey => AppTheme.outline;

  @override
  void initState() {
    super.initState();
    _loadLeaveBalance();
    _loadLeaveRequests();
  }

  Future<void> _loadLeaveBalance() async {
    setState(() => _isLoadingBalance = true);
    try {
      final storage = TokenStorageService();
      final token = await storage.getToken();
      if (token == null) {
        throw Exception('Authentication data not found');
      }

      final response = await LeaveService.getLeaveBalance(token: token);

      if (response.success && response.data != null) {
        final d = response.data!;
        setState(() {
          _leaveBalances = [
            LeaveBalance(
              type: 'Paid',
              remaining: d.paid,
              used: d.usedPaid,
              total: d.paid + d.usedPaid,
            ),
            LeaveBalance(
              type: 'Sick',
              remaining: d.sick,
              used: d.usedSick,
              total: d.sick + d.usedSick,
            ),
            LeaveBalance(
              type: 'Unpaid',
              remaining: d.unpaid,
              used: d.usedUnpaid,
              total: d.unpaid + d.usedUnpaid,
            ),
          ];
        });
      }
    } catch (e) {
      print('Error loading leave balance: $e');
    } finally {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _loadLeaveRequests() async {
    setState(() {
      _isLoadingRequests = true;
    });

    try {
      final token = await TokenStorageService().getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await LeaveService.getMyLeaves(token: token);

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> leavesData = response['data'];

        setState(() {
          _leaveRequests.clear();
          for (var leave in leavesData) {
            String leaveType = leave['leaveType'] ?? 'unknown';
            // Capitalize first letter
            leaveType = leaveType[0].toUpperCase() + leaveType.substring(1);

            final leaveId = '${leave['id'] ?? leave['_id']}';
            final status = _capitalizeStatus(leave['status'] ?? 'Pending');

            _leaveRequests.add(
              LeaveRequest(
                type: '$leaveType Leave',
                fromDate: DateTime.parse(leave['startDate']),
                toDate: DateTime.parse(leave['endDate']),
                reason: leave['reason'] ?? '',
                status: status,
              ),
            );
          }
        });

        // Show notifications outside of setState
        for (var leave in leavesData) {
          final leaveId = '${leave['id'] ?? leave['_id']}';
          final status = _capitalizeStatus(leave['status'] ?? 'Pending');
          String leaveType = leave['leaveType'] ?? 'unknown';
          leaveType = leaveType[0].toUpperCase() + leaveType.substring(1);

          if (!_notifiedLeaveIds.contains(leaveId)) {
            if (status == 'Approved') {
              await NotificationService().showLeaveApprovedNotification(
                employeeName: 'Your',
                leaveType: leaveType,
                startDate: DateFormat(
                  'MMM dd',
                ).format(DateTime.parse(leave['startDate'])),
                endDate: DateFormat(
                  'MMM dd',
                ).format(DateTime.parse(leave['endDate'])),
              );
              _notifiedLeaveIds.add(leaveId);
            } else if (status == 'Rejected') {
              await NotificationService().showLeaveRejectedNotification(
                employeeName: 'Your',
                leaveType: leaveType,
                reason: leave['reviewNote'] ?? 'No reason provided',
              );
              _notifiedLeaveIds.add(leaveId);
            }
          }
        }
      }
    } catch (e) {
      print('Error loading leave requests: $e');
    } finally {
      setState(() {
        _isLoadingRequests = false;
      });
    }
  }

  String _capitalizeStatus(String status) {
    if (status.isEmpty) return 'Pending';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  // --- DIALOG ---
  void _openApplyLeaveDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ApplyLeaveDialog(
          onSubmit: (LeaveRequest newRequest) {
            setState(() {
              _leaveRequests.insert(0, newRequest);
            });
            // Optionally reload from server to get updated data
            _loadLeaveRequests();
          },
        );
      },
    );
  }

  void _openApplyHalfDayDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ApplyHalfDayDialog(
          onSubmit: (LeaveRequest newRequest) {
            setState(() {
              _leaveRequests.insert(0, newRequest);
            });
            // Optionally reload from server to get updated data
            _loadLeaveRequests();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    List<LeaveRequest> filteredRequests = _leaveRequests.where((request) {
      if (_selectedFilter == 'All') return true;
      return request.status == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: kTextWhite,
            size: responsive.iconSize,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Leaves',
          style: TextStyle(
            color: kTextWhite,
            fontWeight: FontWeight.bold,
            fontSize: responsive.titleFontSize,
          ),
        ),
        centerTitle: false,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.api_outlined, color: Colors.pinkAccent),
        //     onPressed: () => Navigator.push(
        //       context,
        //       MaterialPageRoute(builder: (_) => const LeaveApiTestScreen()),
        //     ),
        //     tooltip: 'Leave API Tests',
        //   ),
        // ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_loadLeaveBalance(), _loadLeaveRequests()]);
        },
        color: kPinkAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(responsive.horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Leave Balances Grid (Responsive layout)
              if (_isLoadingBalance)
                Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kPinkAccent),
                  ),
                )
              else if (_leaveBalances.isEmpty)
                Container(
                  height: 80,
                  alignment: Alignment.center,
                  child: Text(
                    'Balance not available',
                    style: TextStyle(color: kTextGrey, fontSize: 14),
                  ),
                )
              else if (responsive.isDesktopDevice)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: responsive.spacing,
                    mainAxisSpacing: responsive.spacing,
                  ),
                  itemCount: _leaveBalances.length,
                  itemBuilder: (ctx, index) {
                    return _buildLeaveBalanceCard(
                      _leaveBalances[index],
                      responsive,
                    );
                  },
                )
              else
                SizedBox(
                  height: responsive.scaledSize(120),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _leaveBalances.length,
                    separatorBuilder: (ctx, i) =>
                        SizedBox(width: responsive.spacing),
                    itemBuilder: (ctx, index) {
                      return _buildLeaveBalanceCard(
                        _leaveBalances[index],
                        responsive,
                      );
                    },
                  ),
                ),

              SizedBox(height: responsive.spacing * 1.5),

              // 2. Section Header
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: kPinkAccent,
                    size: responsive.iconSize,
                  ),
                  SizedBox(width: responsive.smallSpacing),
                  Text(
                    'Leave Requests',
                    style: TextStyle(
                      color: kTextWhite,
                      fontSize: responsive.headingFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.smallSpacing / 2),
              Text(
                'Your leave request history',
                style: TextStyle(
                  color: kTextGrey,
                  fontSize: responsive.captionFontSize,
                ),
              ),

              SizedBox(height: responsive.spacing),

              // Filter and Apply Button Row (Responsive)
              responsive.isDesktopDevice
                  ? Row(
                      children: [
                        SizedBox(
                          width: 200,
                          child: _buildFilterDropdown(responsive),
                        ),
                        SizedBox(width: responsive.spacing),
                        SizedBox(
                          width: 140,
                          child: _buildApplyButton(responsive),
                        ),
                        SizedBox(width: responsive.smallSpacing),
                        SizedBox(
                          width: 160,
                          child: _buildApplyHalfDayButton(responsive),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        // Filter Dropdown
                        _buildFilterDropdown(responsive),

                        SizedBox(height: responsive.smallSpacing),

                        // Apply Buttons Row
                        Row(
                          children: [
                            Expanded(child: _buildApplyButton(responsive)),
                            SizedBox(width: responsive.smallSpacing),
                            Expanded(
                              child: _buildApplyHalfDayButton(responsive),
                            ),
                          ],
                        ),
                      ],
                    ),

              SizedBox(height: responsive.spacing * 1.5),

              // 3. Leave Request History List
              _isLoadingRequests
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(kPinkAccent),
                      ),
                    )
                  : filteredRequests.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 60,
                        horizontal: 24,
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: kTextGrey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No requests found",
                            style: TextStyle(
                              color: kTextGrey,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Your leave requests will appear here",
                            style: TextStyle(
                              color: kTextGrey.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredRequests.length,
                      itemBuilder: (context, index) {
                        return _buildLeaveRequestRow(filteredRequests[index]);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
  // --- WIDGETS ---

  Widget _buildFilterDropdown(ResponsiveUtils responsive) {
    return Container(
      height: responsive.buttonHeight,
      padding: EdgeInsets.symmetric(horizontal: responsive.spacing),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(responsive.cardBorderRadius),
        border: Border.all(color: kBorderGrey),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: kCardColor,
          value: _selectedFilter,
          icon: Icon(Icons.keyboard_arrow_down, color: kTextGrey),
          style: TextStyle(
            color: kTextWhite,
            fontSize: responsive.bodyFontSize,
          ),
          isExpanded: true,
          onChanged: (String? newValue) {
            setState(() {
              _selectedFilter = newValue!;
            });
          },
          items: _filterOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildApplyButton(ResponsiveUtils responsive) {
    return ElevatedButton.icon(
      onPressed: _openApplyLeaveDialog,
      style: ElevatedButton.styleFrom(
        backgroundColor: kPinkAccent,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(vertical: responsive.spacing * 0.875),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.cardBorderRadius),
        ),
        elevation: 0,
        minimumSize: Size(0, responsive.buttonHeight),
      ),
      icon: Icon(Icons.add, size: responsive.smallIconSize),
      label: Text(
        "Apply Leave",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: responsive.bodyFontSize,
        ),
      ),
    );
  }

  Widget _buildApplyHalfDayButton(ResponsiveUtils responsive) {
    return ElevatedButton.icon(
      onPressed: _openApplyHalfDayDialog,
      style: ElevatedButton.styleFrom(
        backgroundColor: kPinkAccent,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(vertical: responsive.spacing * 0.875),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.cardBorderRadius),
        ),
        elevation: 0,
        minimumSize: Size(0, responsive.buttonHeight),
      ),
      icon: Icon(Icons.schedule, size: responsive.smallIconSize),
      label: Text(
        "Half Day",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: responsive.bodyFontSize,
        ),
      ),
    );
  }

  Widget _buildLeaveBalanceCard(
    LeaveBalance balance,
    ResponsiveUtils responsive,
  ) {
    return Container(
      width: responsive.isMobile ? responsive.scaledSize(170) : null,
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing,
        vertical: responsive.spacing * 0.6,
      ),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(responsive.cardBorderRadius),
        border: Border.all(color: kBorderGrey.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Line: Type Name
          Text(
            balance.type,
            style: TextStyle(
              color: kTextGrey,
              fontSize: responsive.bodyFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: responsive.smallSpacing * 0.3),

          // Middle Line: Big Number + Remaining
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${balance.remaining}',
                style: TextStyle(
                  color: kPinkAccent,
                  fontSize: responsive.scaledFontSize(36),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: responsive.smallSpacing / 2),
              Text(
                'left',
                style: TextStyle(
                  color: kTextGrey,
                  fontSize: responsive.captionFontSize,
                ),
              ),
            ],
          ),

          SizedBox(height: responsive.smallSpacing * 0.3),

          // Bottom Line: Used Count (Right Aligned)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${balance.used}/${balance.total} used',
              style: TextStyle(
                color: kTextGrey,
                fontSize: responsive.captionFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveRequestRow(LeaveRequest request) {
    Color statusColor;
    Color statusBg;

    switch (request.status) {
      case 'Approved':
        statusColor = AppTheme.successColor;
        statusBg = AppTheme.successColor.withOpacity(0.15);
        break;
      case 'Rejected':
        statusColor = AppTheme.errorColor;
        statusBg = AppTheme.errorColor.withOpacity(0.15);
        break;
      default:
        statusColor = AppTheme.warningColor;
        statusBg = AppTheme.warningColor.withOpacity(0.15);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderGrey.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon and Status
          Row(
            children: [
              // Left Icon Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: kPinkAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Type Name
              Expanded(
                child: Text(
                  request.type,
                  style: TextStyle(
                    color: kTextWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  request.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Date Range
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: kTextGrey, size: 16),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('MMM dd').format(request.fromDate)} - ${DateFormat('MMM dd, yyyy').format(request.toDate)}',
                style: TextStyle(color: kTextGrey, fontSize: 14),
              ),
            ],
          ),

          // Reason (if exists)
          if (request.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes_outlined, color: kTextGrey, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.reason,
                    style: TextStyle(
                      color: kTextGrey.withOpacity(0.8),
                      fontSize: 13,
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

// --- APPLY LEAVE DIALOG ---
class ApplyLeaveDialog extends StatefulWidget {
  final Function(LeaveRequest) onSubmit;

  const ApplyLeaveDialog({super.key, required this.onSubmit});

  @override
  State<ApplyLeaveDialog> createState() => _ApplyLeaveDialogState();
}

class _ApplyLeaveDialogState extends State<ApplyLeaveDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedLeaveType = 'Paid Leave';
  final List<String> _leaveTypes = ['Paid Leave', 'Sick Leave', 'Unpaid Leave'];
  DateTime? _fromDate;
  DateTime? _toDate;
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  // Dialog Colors
  Color get kDialogBg => AppTheme.surface;
  Color get kInputBg => AppTheme.surfaceVariant;
  Color get kPinkAccent => AppTheme.primaryColor;

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: kPinkAccent,
              onPrimary: Colors.black,
              surface: AppTheme.surface,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppTheme.surface,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      print('📅 [DatePicker] Picked date: $picked (isFromDate=$isFromDate)');
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          print('📅 [DatePicker] _fromDate set to: $_fromDate');
        } else {
          _toDate = picked;
          print('📅 [DatePicker] _toDate set to: $_toDate');
        }
      });
    } else {
      print('📅 [DatePicker] No date picked (user cancelled)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.85; // Max 85% of screen height

    return Dialog(
      backgroundColor: kDialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'New Request',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildLabel('Leave Type'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: kInputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: kInputBg,
                      value: _selectedLeaveType,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      onChanged: (val) =>
                          setState(() => _selectedLeaveType = val!),
                      items: _leaveTypes
                          .map(
                            (val) =>
                                DropdownMenuItem(value: val, child: Text(val)),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('From'),
                          _buildDateField(context, _fromDate, true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('To'),
                          _buildDateField(context, _toDate, false),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildLabel('Reason'),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Describe your reason for leave...',
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                    filled: true,
                    fillColor: kInputBg,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: kPinkAccent.withOpacity(0.5),
                      ),
                    ),
                  ),
                  validator: (val) =>
                      val!.isEmpty ? 'Reason is required' : null,
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitLeaveRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPinkAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                        : const Text(
                            "Submit Request",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context, DateTime? date, bool isFrom) {
    return InkWell(
      onTap: () => _selectDate(context, isFrom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: kInputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                date == null
                    ? 'Select date'
                    : DateFormat('dd MMM yyyy').format(date),
                style: TextStyle(
                  color: date == null ? Colors.grey : Colors.white,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.calendar_today, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLeaveRequest() async {
    print('🔴 [Dialog] _submitLeaveRequest called');
    print('🔴 [Dialog] _fromDate: $_fromDate');
    print('🔴 [Dialog] _toDate: $_toDate');
    print('🔴 [Dialog] _reasonController.text: ${_reasonController.text}');

    // Validate form and dates
    if (!_formKey.currentState!.validate()) {
      print('❌ [Dialog] Form validation failed');
      return;
    }

    if (_fromDate == null || _toDate == null) {
      print(
        '❌ [Dialog] Dates are null - _fromDate=$_fromDate, _toDate=$_toDate',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select both dates')));
      return;
    }

    // Check date logic
    if (_toDate!.isBefore(_fromDate!)) {
      print('❌ [Dialog] End date is before start date');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    print('✅ [Dialog] All validation passed, submitting...');

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get token
      final token = await TokenStorageService().getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Call API
      final response = await LeaveService.applyLeave(
        token: token,
        leaveType: _selectedLeaveType,
        startDate: _fromDate!,
        endDate: _toDate!,
        reason: _reasonController.text,
      );

      if (!mounted) return;

      // Capitalize status for consistency (API returns lowercase)
      String capitalizedStatus = response.data.status.isEmpty
          ? 'Pending'
          : response.data.status[0].toUpperCase() +
                response.data.status.substring(1).toLowerCase();

      // Success - add to local list and close dialog
      widget.onSubmit(
        LeaveRequest(
          type: _selectedLeaveType,
          fromDate: _fromDate!,
          toDate: _toDate!,
          reason: _reasonController.text,
          status: capitalizedStatus,
        ),
      );

      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      print('❌ [Dialog] Submit error: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

// --- APPLY HALF DAY DIALOG ---
class ApplyHalfDayDialog extends StatefulWidget {
  final Function(LeaveRequest) onSubmit;

  const ApplyHalfDayDialog({super.key, required this.onSubmit});

  @override
  State<ApplyHalfDayDialog> createState() => _ApplyHalfDayDialogState();
}

class _ApplyHalfDayDialogState extends State<ApplyHalfDayDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String _selectedSession = 'morning'; // 'morning' or 'afternoon'
  String _leaveType = 'paid'; // 'paid' or 'unpaid'
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(() {
      setState(() {}); // Rebuild to update character counter
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppTheme.surface,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600;
    final maxHeight = mediaQuery.size.height * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: isMobile ? double.infinity : 500,
        ),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.schedule,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Apply Half Day',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Request a half-day off (0.5 days)',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Date Selection
                  _buildSectionLabel('📅 Select Date'),
                  const SizedBox(height: 10),
                  _buildDateField(context, isMobile),
                  const SizedBox(height: 20),

                  // Session Selection
                  _buildSectionLabel('⏰ Select Session'),
                  const SizedBox(height: 10),
                  _buildSessionSelection(isMobile),
                  const SizedBox(height: 20),

                  // Leave Type
                  _buildSectionLabel('💼 Leave Type'),
                  const SizedBox(height: 10),
                  _buildLeaveTypeSelection(isMobile),
                  const SizedBox(height: 20),

                  // Reason
                  _buildSectionLabel('📝 Reason'),
                  const SizedBox(height: 10),
                  _buildReasonField(isMobile),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(isMobile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildDateField(BuildContext context, bool isMobile) {
    final hasDate = _selectedDate != null;
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isMobile ? 14 : 16,
        ),
        decoration: BoxDecoration(
          color: hasDate
              ? AppTheme.primaryColor.withOpacity(0.1)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDate
                ? AppTheme.primaryColor
                : Colors.white.withOpacity(0.1),
            width: hasDate ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedDate == null ? 'Select a date' : 'Date Selected',
                    style: TextStyle(
                      color: _selectedDate == null
                          ? Colors.grey[600]
                          : AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedDate == null
                        ? 'Tap to choose a date'
                        : DateFormat('EEE, MMM d, yyyy').format(_selectedDate!),
                    style: TextStyle(
                      color: _selectedDate == null
                          ? Colors.grey[500]
                          : Colors.white,
                      fontSize: isMobile ? 14 : 15,
                      fontWeight: _selectedDate == null
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.calendar_today,
              color: hasDate ? AppTheme.primaryColor : Colors.white54,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionSelection(bool isMobile) {
    return Row(
      children: [
        Expanded(child: _buildSessionButton('morning', '🌅 Morning', isMobile)),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSessionButton('afternoon', '🌤️ Afternoon', isMobile),
        ),
      ],
    );
  }

  Widget _buildSessionButton(String value, String label, bool isMobile) {
    final isSelected = _selectedSession == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedSession = value),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isMobile ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.2)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryColor : Colors.grey[500],
              fontSize: isMobile ? 13 : 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveTypeSelection(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: _buildLeaveTypeButton('paid', '💰 Paid Leave', isMobile),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildLeaveTypeButton('unpaid', '📋 Unpaid Leave', isMobile),
        ),
      ],
    );
  }

  Widget _buildLeaveTypeButton(String value, String label, bool isMobile) {
    final isSelected = _leaveType == value;
    return GestureDetector(
      onTap: () => setState(() => _leaveType = value),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isMobile ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.2)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryColor : Colors.grey[500],
              fontSize: isMobile ? 13 : 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildReasonField(bool isMobile) {
    return TextFormField(
      controller: _reasonController,
      maxLines: isMobile ? 3 : 4,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Explain why you need a half day...',
        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Reason is required';
        if (val.length < 5) return 'Reason must be at least 5 characters';
        return null;
      },
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    return isMobile
        ? Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitHalfDayRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[700],
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.send, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Submit Request',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitHalfDayRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[700],
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.send, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Submit Request',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          );
  }

  Future<void> _submitHalfDayRequest() async {
    // Validate form and date
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please fill all required fields'),
          backgroundColor: AppTheme.errorColor,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please select a date for the half-day leave'),
          backgroundColor: AppTheme.errorColor,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get token
      final token = await TokenStorageService().getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Convert date to UTC before sending to API
      final utcDate = DateTime.utc(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      // Call the new half-day API
      final response = await LeaveService.applyHalfDayLeave(
        token: token,
        date: utcDate,
        session: _selectedSession,
        reason: _reasonController.text.trim(),
        leaveType: _leaveType,
      );

      if (!mounted) return;

      // Capitalize status for consistency
      String capitalizedStatus = response.data.status.isEmpty
          ? 'Pending'
          : response.data.status[0].toUpperCase() +
                response.data.status.substring(1).toLowerCase();

      // Success - add to local list and close dialog
      widget.onSubmit(
        LeaveRequest(
          type: 'Half Day',
          fromDate: _selectedDate!,
          toDate: _selectedDate!,
          reason: _reasonController.text,
          status: capitalizedStatus,
        ),
      );

      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Half-day request submitted successfully'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ' + e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
