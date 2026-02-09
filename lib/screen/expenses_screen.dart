import 'package:flutter/material.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  // -- Theme Colors --
  final Color _bgDark = const Color(0xFF050505);
  final Color _cardDark = const Color(0xFF141414);
  final Color _inputDark = const Color(0xFF1F1F1F);
  final Color _accentPink = const Color(0xFFFF8FA3);
  final Color _accentGreen = const Color(0xFF00C853);
  final Color _accentOrange = const Color(0xFFFFAB00);
  final Color _accentRed = const Color(0xFFFF5252);
  final Color _textWhite = Colors.white;
  final Color _textGrey = const Color(0xFF9E9E9E);

  // -- State --
  String _selectedFilter = "All";
  
  // -- Form Controllers --
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String? _selectedCategory;

  // -- Dummy Data --
  final List<Map<String, dynamic>> _expenses = [
    {
      "id": "EXP-001",
      "category": "Travel",
      "desc": "Uber to Client Meeting",
      "date": "Feb 4, 2026",
      "amount": 24.50,
      "status": "Pending",
    },
    {
      "id": "EXP-002",
      "category": "Equipment",
      "desc": "Monitor Stand",
      "date": "Feb 1, 2026",
      "amount": 45.00,
      "status": "Approved",
    },
    {
      "id": "EXP-003",
      "category": "Meals",
      "desc": "Team Lunch",
      "date": "Jan 28, 2026",
      "amount": 120.00,
      "status": "Rejected",
    },
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // --- Search/Filter Logic ---
  List<Map<String, dynamic>> _getFilteredExpenses() {
    if (_selectedFilter == "All") return _expenses;
    return _expenses.where((e) => e['status'] == _selectedFilter).toList();
  }

  // --- Date Picker Logic ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _accentPink,
              onPrimary: Colors.black,
              surface: _cardDark,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: _cardDark,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
         // Simple formatting
        const List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        _dateController.text = "${months[picked.month - 1]} ${picked.day}, ${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedExpenses = _getFilteredExpenses();
    
    // Calculate Stats
    final totalApproved = _expenses
        .where((e) => e['status'] == 'Approved')
        .fold(0.0, (sum, item) => sum + (item['amount'] as double));
    final pendingCount = _expenses.where((e) => e['status'] == 'Pending').length;
    final approvedCount = _expenses.where((e) => e['status'] == 'Approved').length;
    final rejectedCount = _expenses.where((e) => e['status'] == 'Rejected').length;

    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 600;

            return Column(
              children: [
                // 1. Header
                 _buildTopHeader(context, isMobile),

                // 2. Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Section
                        isMobile 
                          ? _buildMobileStats(pendingCount, approvedCount, rejectedCount, totalApproved) 
                          : _buildDesktopStats(pendingCount, approvedCount, rejectedCount, totalApproved),
                        
                        const SizedBox(height: 30),

                        // Section Header & Filter
                        _buildSectionHeader(isMobile),
                        const SizedBox(height: 20),

                        // List
                        displayedExpenses.isEmpty 
                        ? _buildEmptyState() 
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: displayedExpenses.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildExpenseCard(displayedExpenses[index]);
                            },
                          ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildTopHeader(BuildContext context, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context), // Assuming navigation
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: _cardDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 16),
              const Text("Expense Claims", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          if (!isMobile)
            ElevatedButton.icon(
              onPressed: () => _handleCreateExpense(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Add Expense"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentPink,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("History", style: TextStyle(color: _textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Your recent claims", style: TextStyle(color: _textGrey, fontSize: 13)),
          ],
        ),
        
        // Filter & Add Button (Mobile layout needs care)
        Row(
          children: [
            // Filter Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: 40,
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  dropdownColor: _cardDark,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: ["All", "Pending", "Approved", "Rejected"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _selectedFilter = v!),
                ),
              ),
            ),
            
            if (isMobile) ...[
              const SizedBox(width: 10),
              IconButton(
                onPressed: () => _handleCreateExpense(context),
                style: IconButton.styleFrom(
                  backgroundColor: _accentPink,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 24),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMobileStats(int pending, int approved, int rejected, double total) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5, // Squarer cards for mobile
      children: [
        _buildStatCard("Pending", "$pending", Icons.access_time_filled, _accentOrange),
        _buildStatCard("Approved", "$approved", Icons.check_circle, _accentGreen),
        _buildStatCard("Rejected", "$rejected", Icons.cancel, _accentRed),
        _buildStatCard("Total Approved", "\$${total.toStringAsFixed(0)}", Icons.attach_money, _accentPink),
      ],
    );
  }

  Widget _buildDesktopStats(int pending, int approved, int rejected, double total) {
    return Row(
      children: [
        Expanded(child: _buildStatCard("Pending", "$pending", Icons.access_time_filled, _accentOrange)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard("Approved", "$approved", Icons.check_circle, _accentGreen)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard("Rejected", "$rejected", Icons.cancel, _accentRed)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard("Total Approved", "\$${total.toStringAsFixed(0)}", Icons.attach_money, _accentPink)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: _textGrey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> item) {
    Color statusColor;
    IconData statusIcon;
    switch (item['status']) {
      case "Approved": statusColor = _accentGreen; statusIcon = Icons.check_circle_outline; break;
      case "Rejected": statusColor = _accentRed; statusIcon = Icons.highlight_off; break;
      default: statusColor = _accentOrange; statusIcon = Icons.access_time;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _inputDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt_long, color: _textGrey, size: 24),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['desc'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text("${item['category']} • ${item['date']}", style: TextStyle(color: _textGrey, fontSize: 12)),
              ],
            ),
          ),
          // Amount & Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("\$${item['amount'].toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(item['status'], style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.folder_off_outlined, size: 48, color: _textGrey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text("No claims found", style: TextStyle(color: _textGrey)),
          ],
        ),
      ),
    );
  }

  // --- CREATE EXPENSE MODAL ---

  void _handleCreateExpense(BuildContext context) {
    // Reset Form
    _amountController.clear();
    _descController.clear();
    _dateController.clear();
    _selectedCategory = null;

    if (MediaQuery.of(context).size.width < 600) {
      _showMobileBottomSheet(context);
    } else {
      _showDesktopDialog(context);
    }
  }

  void _showMobileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  const Align(alignment: Alignment.centerLeft, child: Text("Submit Expense", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 4),
                  Align(alignment: Alignment.centerLeft, child: Text("Submit a new expense claim for approval", style: TextStyle(color: _textGrey, fontSize: 13))),
                  const SizedBox(height: 24),
                  _buildForm(context),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDesktopDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: _cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Submit Expense", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("Submit a new expense claim for approval", style: TextStyle(color: _textGrey, fontSize: 13)),
                  const SizedBox(height: 24),
                  _buildForm(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildForm(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Dropdown
            _label("Category"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: _inputDark, borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  hint: Text("Select category", style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                  isExpanded: true,
                  dropdownColor: _cardDark,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  style: const TextStyle(color: Colors.white),
                  items: ["Travel", "Meals", "Equipment", "Training", "Other"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount & Date Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label("Amount (\$)"),
                      _inputField(hint: "0.00", controller: _amountController, isNumber: true),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label("Date"),
                       TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        style: const TextStyle(color: Colors.white),
                        onTap: () => _selectDate(context),
                        decoration: InputDecoration(
                          hintText: "dd-mm-yyyy",
                          hintStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
                          filled: true,
                          fillColor: _inputDark,
                          suffixIcon: Icon(Icons.calendar_month, color: Colors.grey[600], size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // File Picker Stub
            _label("Bill/Receipt Photo (Optional)"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _inputDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(6)),
                    child: const Text("Choose File", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  const Text("No file chosen", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description
            _label("Description"),
            _inputField(hint: "Describe the expense...", controller: _descController, maxLines: 3),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Add logic here
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentPink,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Submit Expense", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)));

  Widget _inputField({required String hint, TextEditingController? controller, int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
        filled: true,
        fillColor: _inputDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}