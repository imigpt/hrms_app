import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    required this.total
  });
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LeaveScreen(),
  ));
}

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  // --- DATA ---
  final List<LeaveBalance> _leaveBalances = [
    LeaveBalance(type: 'Annual', remaining: 21, used: 0, total: 21),
    LeaveBalance(type: 'Sick', remaining: 14, used: 0, total: 14),
    LeaveBalance(type: 'Casual', remaining: 7, used: 0, total: 7),
    LeaveBalance(type: 'Maternity', remaining: 90, used: 0, total: 90),
    LeaveBalance(type: 'Paternity', remaining: 7, used: 0, total: 7),
    LeaveBalance(type: 'Unpaid', remaining: 0, used: 0, total: 0),
  ];

  final List<LeaveRequest> _leaveRequests = [
    LeaveRequest(type: 'Sick Leave', fromDate: DateTime(2026, 2, 5), toDate: DateTime(2026, 2, 6), reason: 'Flu'),
    LeaveRequest(type: 'Casual Leave', fromDate: DateTime(2026, 1, 20), toDate: DateTime(2026, 1, 20), reason: 'Personal', status: 'Approved'),
    LeaveRequest(type: 'Annual Leave', fromDate: DateTime(2025, 12, 25), toDate: DateTime(2026, 1, 1), reason: 'Vacation', status: 'Rejected'),
  ];

  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Pending', 'Approved', 'Rejected'];

  // --- COLORS (Matched to Screenshots) ---
  final Color kBackground = const Color(0xFF000000); // Pitch Black
  final Color kCardColor = const Color(0xFF111111); // Dark Grey Card
  final Color kPinkAccent = const Color(0xFFFF80AB); // The main pink button color
  final Color kTextRed = const Color(0xFFFF5252); // The number color in cards
  final Color kTextWhite = const Color(0xFFFFFFFF);
  final Color kTextGrey = const Color(0xFF9E9E9E);
  final Color kBorderGrey = const Color(0xFF333333);

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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<LeaveRequest> filteredRequests = _leaveRequests.where((request) {
      if (_selectedFilter == 'All') return true;
      return request.status == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        title: Text('My Leaves', style: TextStyle(color: kTextWhite, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Leave Balances Grid (Horizontal Scroll to fit mobile)
            SizedBox(
              height: 110, // Fixed height for cards
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _leaveBalances.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 12),
                itemBuilder: (ctx, index) {
                  return _buildLeaveBalanceCard(_leaveBalances[index]);
                },
              ),
            ),
            
            const SizedBox(height: 30),

            // 2. Section Header + Filter + Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_month_outlined, color: kPinkAccent, size: 20),
                          const SizedBox(width: 8),
                          Text('Leave Requests', style: TextStyle(color: kTextWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Your leave request history', style: TextStyle(color: kTextGrey, fontSize: 12)),
                    ],
                  ),
                ),
                
                // Filter Dropdown
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorderGrey),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: kCardColor,
                      value: _selectedFilter,
                      icon: Icon(Icons.keyboard_arrow_down, color: kTextGrey),
                      style: TextStyle(color: kTextWhite, fontSize: 14),
                      onChanged: (String? newValue) {
                        setState(() { _selectedFilter = newValue!; });
                      },
                      items: _filterOptions.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                const SizedBox(width: 10),

                // Apply Leave Button
                ElevatedButton.icon(
                  onPressed: _openApplyLeaveDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPinkAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    fixedSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Apply Leave", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // 3. Leave Request History List
            filteredRequests.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    child: Text("No requests found.", style: TextStyle(color: kTextGrey)),
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
    );
  }

  // --- WIDGETS ---

  Widget _buildLeaveBalanceCard(LeaveBalance balance) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderGrey.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Line: Type Name
          Text(balance.type, style: TextStyle(color: kTextGrey, fontSize: 13)),
          
          // Middle Line: Big Number + Remaining
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${balance.remaining}',
                style: TextStyle(color: kPinkAccent, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Text('remaining', style: TextStyle(color: kTextGrey, fontSize: 12)),
            ],
          ),

          // Bottom Line: Used Count (Right Aligned)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${balance.used}/${balance.total} used',
              style: TextStyle(color: kTextGrey, fontSize: 11),
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
        statusColor = const Color(0xFF66BB6A); // Green
        statusBg = const Color(0xFF1B5E20).withOpacity(0.3);
        break;
      case 'Rejected':
        statusColor = const Color(0xFFEF5350); // Red
        statusBg = const Color(0xFFB71C1C).withOpacity(0.3);
        break;
      default:
        statusColor = const Color(0xFFFFA726); // Orange
        statusBg = const Color(0xFFE65100).withOpacity(0.3);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderGrey.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Left Icon Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.description_outlined, color: kPinkAccent, size: 24),
          ),
          const SizedBox(width: 16),
          
          // Center Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.type, style: TextStyle(color: kTextWhite, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('MMM dd').format(request.fromDate)} - ${DateFormat('MMM dd, yyyy').format(request.toDate)}',
                  style: TextStyle(color: kTextGrey, fontSize: 13),
                ),
                if(request.reason.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(request.reason, style: TextStyle(color: kTextGrey.withOpacity(0.7), fontSize: 12, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                  )
              ],
            ),
          ),

          // Right Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.5), width: 1),
            ),
            child: Text(
              request.status,
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
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
  String _selectedLeaveType = 'Sick Leave';
  final List<String> _leaveTypes = ['Sick Leave', 'Casual Leave', 'Annual Leave', 'Maternity Leave', 'Paternity Leave', 'Unpaid Leave'];
  DateTime? _fromDate;
  DateTime? _toDate;
  final _reasonController = TextEditingController();

  // Dialog Colors
  final Color kDialogBg = const Color(0xFF1A1A1A);
  final Color kInputBg = const Color(0xFF2C2C2C);
  final Color kPinkAccent = const Color(0xFFFF80AB);

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
              surface: const Color(0xFF222222),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF222222),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) _fromDate = picked;
        else _toDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kDialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  const Text('New Request', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildLabel('Leave Type'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: kInputBg, borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: kInputBg,
                    value: _selectedLeaveType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) => setState(() => _selectedLeaveType = val!),
                    items: _leaveTypes.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                  const SizedBox(width: 12),
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
              const SizedBox(height: 16),

              _buildLabel('Reason'),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Describe reason...',
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  filled: true,
                  fillColor: kInputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _fromDate != null && _toDate != null) {
                      widget.onSubmit(LeaveRequest(
                        type: _selectedLeaveType,
                        fromDate: _fromDate!,
                        toDate: _toDate!,
                        reason: _reasonController.text,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPinkAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Submit Request", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildDateField(BuildContext context, DateTime? date, bool isFrom) {
    return InkWell(
      onTap: () => _selectDate(context, isFrom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(color: kInputBg, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(date == null ? '--/--' : DateFormat('dd MMM').format(date), style: const TextStyle(color: Colors.white)),
            const Icon(Icons.calendar_today, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}