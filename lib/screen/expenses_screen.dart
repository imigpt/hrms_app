import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../services/token_storage_service.dart';
// import 'expense_api_test_screen.dart';

class ExpensesScreen extends StatefulWidget {
  final String? role;
  const ExpensesScreen({super.key, this.role});

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
  bool get _isAdmin =>
      widget.role?.toLowerCase() == 'admin' ||
      widget.role?.toLowerCase() == 'hr';
  String _selectedFilter = "All";
  bool _isLoading = true;
  List<Expense> _expenses = [];
  String? _token;

  // -- Form Controllers --
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String? _selectedCategory;
  String _selectedCurrency = "INR";
  File? _selectedReceiptFile;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // --- API Integration ---
  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _token = await TokenStorageService().getToken();
      if (_token == null) {
        throw Exception('No authentication token found');
      }

      final response = await ExpenseService.getExpenses(token: _token!);
      setState(() {
        _expenses = response.data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading expenses: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load expenses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Search/Filter Logic ---
  List<Expense> _getFilteredExpenses() {
    if (_selectedFilter == "All") return _expenses;
    final filterStatus = _selectedFilter.toLowerCase();
    return _expenses
        .where((e) => e.status.toLowerCase() == filterStatus)
        .toList();
  }

  // --- Date Picker Logic ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
        _selectedDate = picked;
        _dateController.text = DateFormat('MMM d, y').format(picked);
      });
    }
  }

  // --- File Picker Logic ---
  Future<void> _pickReceiptFile() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedReceiptFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedExpenses = _getFilteredExpenses();

    // Calculate Stats
    final totalApproved = _expenses
        .where((e) => e.status.toLowerCase() == 'approved')
        .fold(0.0, (sum, item) => sum + item.amount);
    final pendingCount = _expenses
        .where((e) => e.status.toLowerCase() == 'pending')
        .length;
    final approvedCount = _expenses
        .where((e) => e.status.toLowerCase() == 'approved')
        .length;
    final rejectedCount = _expenses
        .where((e) => e.status.toLowerCase() == 'rejected')
        .length;

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Section
                        isMobile
                            ? _buildMobileStats(
                                pendingCount,
                                approvedCount,
                                rejectedCount,
                                totalApproved,
                              )
                            : _buildDesktopStats(
                                pendingCount,
                                approvedCount,
                                rejectedCount,
                                totalApproved,
                              ),

                        const SizedBox(height: 30),

                        // Section Header & Filter
                        _buildSectionHeader(isMobile),
                        const SizedBox(height: 20),

                        // Loading or List
                        _isLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : displayedExpenses.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayedExpenses.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  return _buildExpenseCard(
                                    displayedExpenses[index],
                                  );
                                },
                              ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                "Expense Claims",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Tooltip(
              //   message: 'API Tests',
              //   child: IconButton(
              //     icon: const Icon(Icons.api_outlined, color: Colors.pinkAccent, size: 22),
              //     onPressed: () => Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //           builder: (_) => const ExpenseApiTestScreen()),
              //     ),
              //   ),
              // ),
              if (!isMobile && widget.role?.toLowerCase() != 'admin')
                ElevatedButton.icon(
                  onPressed: () => _handleCreateExpense(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add Expense"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentPink,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
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
            Text(
              "History",
              style: TextStyle(
                color: _textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Your recent claims",
              style: TextStyle(color: _textGrey, fontSize: 13),
            ),
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
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey,
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: ["All", "Pending", "Approved", "Rejected"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedFilter = v!),
                ),
              ),
            ),

            if (isMobile && widget.role?.toLowerCase() != 'admin') ...[
              const SizedBox(width: 10),
              IconButton(
                onPressed: () => _handleCreateExpense(context),
                style: IconButton.styleFrom(
                  backgroundColor: _accentPink,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add, size: 24),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMobileStats(
    int pending,
    int approved,
    int rejected,
    double total,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1, // Compact cards to prevent overflow
      children: [
        _buildStatCard(
          "Pending",
          "$pending",
          Icons.access_time_filled,
          _accentOrange,
        ),
        _buildStatCard(
          "Approved",
          "$approved",
          Icons.check_circle,
          _accentGreen,
        ),
        _buildStatCard("Rejected", "$rejected", Icons.cancel, _accentRed),
        _buildStatCard(
          "Total Approved",
          "\₹${total.toStringAsFixed(0)}",
          Icons.currency_rupee,
          _accentPink,
        ),
      ],
    );
  }

  Widget _buildDesktopStats(
    int pending,
    int approved,
    int rejected,
    double total,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Pending",
            "$pending",
            Icons.access_time_filled,
            _accentOrange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            "Approved",
            "$approved",
            Icons.check_circle,
            _accentGreen,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            "Rejected",
            "$rejected",
            Icons.cancel,
            _accentRed,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            "Total Approved",
            "\$${total.toStringAsFixed(0)}",
            Icons.attach_money,
            _accentPink,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: _textGrey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense item) {
    Color statusColor;
    IconData statusIcon;
    final status = item.status.toLowerCase();
    switch (status) {
      case "approved":
        statusColor = _accentGreen;
        statusIcon = Icons.check_circle_outline;
        break;
      case "rejected":
        statusColor = _accentRed;
        statusIcon = Icons.highlight_off;
        break;
      default:
        statusColor = _accentOrange;
        statusIcon = Icons.access_time;
    }

    // Format category for display
    final categoryDisplay =
        item.category[0].toUpperCase() + item.category.substring(1);

    // Format date
    final dateDisplay = DateFormat('MMM d, y').format(item.date);

    return GestureDetector(
      onTap: () => _handleViewExpense(context, item),
      child: Container(
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
              width: 48,
              height: 48,
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
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$categoryDisplay • $dateDisplay",
                    style: TextStyle(color: _textGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Amount & Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${item.currency} ${item.amount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(
              Icons.folder_off_outlined,
              size: 48,
              color: _textGrey.withOpacity(0.3),
            ),
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
    _selectedCurrency = "INR";
    _selectedReceiptFile = null;
    _selectedDate = null;

    if (MediaQuery.of(context).size.width < 600) {
      _showMobileBottomSheet(context);
    } else {
      _showDesktopDialog(context);
    }
  }

  // --- Submit Expense to API ---
  Future<void> _submitExpense(BuildContext context) async {
    // Validation
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Parse amount
    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Submitting expense...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      if (_token == null) {
        throw Exception('No authentication token found');
      }

      await ExpenseService.submitExpense(
        token: _token!,
        category: _selectedCategory!,
        amount: amount,
        currency: _selectedCurrency,
        date: _selectedDate!,
        description: _descController.text,
        receiptFile: _selectedReceiptFile,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Close form dialog/bottom sheet
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload expenses
      await _loadExpenses();
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      print('Error submitting expense: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMobileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Submit Expense",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Submit a new expense claim for approval",
                      style: TextStyle(color: _textGrey, fontSize: 13),
                    ),
                  ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                      const Text(
                        "Submit Expense",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Submit a new expense claim for approval",
                    style: TextStyle(color: _textGrey, fontSize: 13),
                  ),
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
      builder: (context, setDialogState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Dropdown
            _label("Category"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _inputDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  hint: Text(
                    "Select category",
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  isExpanded: true,
                  dropdownColor: _cardDark,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: "travel", child: Text("Travel")),
                    DropdownMenuItem(value: "food", child: Text("Food & Meals")),
                    DropdownMenuItem(value: "office-supplies", child: Text("Office Supplies")),
                    DropdownMenuItem(value: "software", child: Text("Software")),
                    DropdownMenuItem(value: "training", child: Text("Training")),
                    DropdownMenuItem(value: "other", child: Text("Other")),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedCategory = val);
                    setDialogState(() => _selectedCategory = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount, Currency & Date Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label("Amount"),
                      _inputField(
                        hint: "0.00",
                        controller: _amountController,
                        isNumber: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label("Currency"),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _inputDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCurrency,
                            isExpanded: true,
                            dropdownColor: _cardDark,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey,
                              size: 18,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            items: ["INR", "USD", "EUR", "GBP"]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() => _selectedCurrency = val!);
                              setDialogState(() => _selectedCurrency = val!);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
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
                          hintText: "Select date",
                          hintStyle: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: _inputDark,
                          suffixIcon: Icon(
                            Icons.calendar_month,
                            color: Colors.grey[600],
                            size: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // File Picker
            _label("Bill/Receipt Photo (Optional)"),
            InkWell(
              onTap: () async {
                await _pickReceiptFile();
                setDialogState(() {}); // Update dialog state
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _inputDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "Choose File",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedReceiptFile != null
                            ? _selectedReceiptFile!.path.split('/').last
                            : "No file chosen",
                        style: TextStyle(
                          color: _selectedReceiptFile != null
                              ? Colors.white
                              : Colors.grey,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_selectedReceiptFile != null)
                      IconButton(
                        onPressed: () {
                          setState(() => _selectedReceiptFile = null);
                          setDialogState(() => _selectedReceiptFile = null);
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            _label("Description"),
            _inputField(
              hint: "Describe the expense...",
              controller: _descController,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submitExpense(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentPink,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Submit Expense",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _inputField({
    required String hint,
    TextEditingController? controller,
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
        filled: true,
        fillColor: _inputDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // --- VIEW/EDIT EXPENSE ---

  void _handleViewExpense(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Expense Details",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildDetailRow("Category", expense.category.toUpperCase()),
                  _buildDetailRow(
                    "Amount",
                    "${expense.currency} ${expense.amount.toStringAsFixed(2)}",
                  ),
                  _buildDetailRow(
                    "Date",
                    DateFormat('MMM d, y').format(expense.date),
                  ),
                  _buildDetailRow("Description", expense.description),
                  _buildDetailRow("Status", expense.status.toUpperCase()),

                  if (expense.receipt != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      "Receipt",
                      style: TextStyle(color: _textGrey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        expense.receipt!.url,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: _inputDark,
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (expense.status.toLowerCase() == 'pending') ...[
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _handleEditExpense(context, expense);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: _accentPink,
                          ),
                          child: const Text("Edit"),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () =>
                              _handleDeleteExpense(context, expense),
                          style: TextButton.styleFrom(
                            foregroundColor: _accentRed,
                          ),
                          child: const Text("Delete"),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: _textGrey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }

  void _handleEditExpense(BuildContext context, Expense expense) {
    // Pre-fill form with expense data
    _amountController.text = expense.amount.toString();
    _descController.text = expense.description;
    _dateController.text = DateFormat('MMM d, y').format(expense.date);
    _selectedCategory = expense.category; // Use category as-is from backend
    _selectedCurrency = expense.currency;
    _selectedDate = expense.date;
    _selectedReceiptFile = null; // Cannot pre-fill file

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Edit Expense",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Update your expense details",
                    style: TextStyle(color: _textGrey, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  _buildForm(context),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _updateExpense(context, expense.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentPink,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Update Expense",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateExpense(BuildContext context, String expenseId) async {
    // Validation (same as submit)
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Updating expense...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      if (_token == null) {
        throw Exception('No authentication token found');
      }

      await ExpenseService.updateExpense(
        token: _token!,
        expenseId: expenseId,
        category: _selectedCategory!,
        amount: amount,
        currency: _selectedCurrency,
        date: _selectedDate!,
        description: _descController.text,
        receiptFile: _selectedReceiptFile,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Close edit dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload expenses
      await _loadExpenses();
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      print('Error updating expense: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteExpense(
    BuildContext context,
    Expense expense,
  ) async {
    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Expense',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this expense?',
          style: TextStyle(color: _textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _textGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _accentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Deleting expense...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      if (_token == null) {
        throw Exception('No authentication token found');
      }

      await ExpenseService.deleteExpense(token: _token!, expenseId: expense.id);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Close details dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload expenses
      await _loadExpenses();
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      print('Error deleting expense: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
