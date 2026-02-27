import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/hr_accounts_service.dart';
import '../utils/responsive_utils.dart';
import '../theme/app_theme.dart';

class HRAccountsScreen extends StatefulWidget {
  final String? token;

  const HRAccountsScreen({super.key, this.token});

  @override
  State<HRAccountsScreen> createState() => _HRAccountsScreenState();
}

class _HRAccountsScreenState extends State<HRAccountsScreen> {
  // Use App Theme Colors
  static const Color _bg = AppTheme.background;
  static const Color _section = AppTheme.surface;
  static const Color _input = AppTheme.surfaceVariant;
  static const Color _border = AppTheme.outline;
  static const Color _primaryAccent = AppTheme.primaryColor; // Brand Pink
  static const Color _secondaryAccent = AppTheme.secondaryColor; // Green
  static const Color _textGrey = Color(0xFF8E8E93);
  static const Color _textLight = AppTheme.onSurface;
  static const Color _red = AppTheme.errorColor;
  static const Color _orange = AppTheme.warningColor;

  // State
  bool _isLoading = true;
  String? _error;
  List<dynamic> _hrAccounts = [];
  List<dynamic> _filteredAccounts = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? _token;

  @override
  void initState() {
    super.initState();
    _token = widget.token;
    _searchController.addListener(() => _onSearchChanged(_searchController.text));
    _loadHRAccounts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHRAccounts() async {
    if (_token == null || _token!.isEmpty) {
      setState(() {
        _error = 'No authentication token provided';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      final result = await HRAccountsService.getHRAccounts(_token!);
      
      if (mounted) {
        setState(() {
          if (result['success'] == true) {
            _hrAccounts = result['data'] ?? [];
            _filteredAccounts = _hrAccounts;
            _error = null;
          } else {
            _error = result['message'] ?? 'Failed to load HR accounts';
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

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredAccounts = _hrAccounts.where((account) {
        final name = (account['name'] ?? '').toString().toLowerCase();
        final email = (account['email'] ?? '').toString().toLowerCase();
        final employeeId = (account['employeeId'] ?? '').toString().toLowerCase();
        final companyName = (account['company']?['name'] ?? '').toString().toLowerCase();
        
        return name.contains(_searchQuery) ||
            email.contains(_searchQuery) ||
            employeeId.contains(_searchQuery) ||
            companyName.contains(_searchQuery);
      }).toList();
    });
  }

  Future<void> _showDetailsDialog(Map<String, dynamic> account) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: _section,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _primaryAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _primaryAccent.withOpacity(0.3), width: 1),
                        ),
                        child: const Icon(Icons.info_rounded, color: AppTheme.primaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account['name'] ?? 'Manager Details',
                              style: const TextStyle(
                                color: _textLight,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Complete information',
                              style: TextStyle(color: _textGrey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _border.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close_rounded, color: _textGrey, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Divider(color: _border.withOpacity(0.4), height: 1),
                  const SizedBox(height: 18),
                  // Details
                  _buildDetailRow('Name', account['name'] ?? '-'),
                  _buildDetailRow('Employee ID', account['employeeId'] ?? '-'),
                  _buildDetailRow('Email', account['email'] ?? '-'),
                  _buildDetailRow('Phone', account['phone'] ?? '-'),
                  _buildDetailRow('Department', account['department'] ?? '-'),
                  _buildDetailRow('Company', account['company']?['name'] ?? '-'),
                  _buildDetailRow('Status', account['status'] ?? '-'),
                  _buildDetailRow('Join Date', _formatDate(account['joinDate'])),
                  const SizedBox(height: 20),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Close'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textLight,
                            side: BorderSide(color: _border.withOpacity(0.8), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showResetPasswordDialog(account);
                          },
                          icon: const Icon(Icons.vpn_key_rounded, size: 17),
                          label: const Text('Reset Password'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                        ),
                      ),
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

  Future<void> _showResetPasswordDialog(Map<String, dynamic> account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: _section,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border.withOpacity(0.5), width: 1),
          ),
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.vpn_key_rounded, color: _orange, size: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  'Reset Password?',
                  style: const TextStyle(
                    color: _textLight,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'A new temporary password will be sent to ${account['email']}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textGrey, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _border.withOpacity(0.8), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    _resetPassword(account['_id'], account['name']);
  }

  Future<void> _resetPassword(String hrId, String hrName) async {
    if (_token == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await HRAccountsService.resetHRPassword(_token!, hrId);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset sent to $hrName'),
            backgroundColor: _secondaryAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: _red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showEditManagerDialog(Map<String, dynamic> manager) async {
    final _nameController = TextEditingController(text: manager['name'] ?? '');
    final _emailController = TextEditingController(text: manager['email'] ?? '');
    final _phoneController = TextEditingController(text: manager['phone'] ?? '');
    final _departmentController = TextEditingController(text: manager['department'] ?? '');
    var _selectedStatus = manager['status'] ?? 'active';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: StatefulBuilder(
          builder: (context, setState) => Container(
            decoration: BoxDecoration(
              color: _section,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border.withOpacity(0.5), width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
            ),
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _primaryAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _primaryAccent.withOpacity(0.3), width: 1),
                          ),
                          child: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Edit Manager',
                                style: TextStyle(
                                  color: _textLight,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Update manager information',
                                style: TextStyle(color: _textGrey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _border.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.close_rounded, color: _textGrey, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Divider(color: _border.withOpacity(0.4), height: 1),
                    const SizedBox(height: 18),
                    _buildEditField('Full Name', _nameController),
                    const SizedBox(height: 14),
                    _buildEditField('Email', _emailController),
                    const SizedBox(height: 14),
                    _buildEditField('Phone', _phoneController),
                    const SizedBox(height: 14),
                    _buildEditField('Department', _departmentController),
                    const SizedBox(height: 14),
                    _buildStatusSelector(_selectedStatus, (v) => setState(() => _selectedStatus = v)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _textLight,
                              side: BorderSide(color: _border.withOpacity(0.8), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryAccent, _primaryAccent.withOpacity(0.85)],
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  // TODO: Implement update API call
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Manager updated successfully'),
                                      backgroundColor: _secondaryAccent,
                                    ),
                                  );
                                  _loadHRAccounts();
                                },
                                borderRadius: BorderRadius.circular(11),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_rounded, size: 17),
                                      SizedBox(width: 8),
                                      Text(
                                        'Update Manager',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddManagerDialog() async {
    final _nameController = TextEditingController();
    final _employeeIdController = TextEditingController();
    final _passwordController = TextEditingController();
    final _emailController = TextEditingController();
    final _phoneController = TextEditingController();
    final _dobController = TextEditingController();
    final _addressController = TextEditingController();
    final _departmentController = TextEditingController();
    final _positionController = TextEditingController();
    final _jobDateController = TextEditingController();
    var _selectedStatus = 'active';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: StatefulBuilder(
          builder: (context, setState) => Container(
            decoration: BoxDecoration(
              color: _section,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border.withOpacity(0.5), width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
            ),
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryAccent.withOpacity(0.15), _primaryAccent.withOpacity(0.08)],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      border: Border(bottom: BorderSide(color: _border.withOpacity(0.3), width: 1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add New HR Manager',
                              style: TextStyle(
                                color: _textLight,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a new HR manager account with complete details',
                              style: TextStyle(color: _textGrey, fontSize: 12),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _border.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.close_rounded, color: _textLight, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Photo Section
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [_primaryAccent.withOpacity(0.3), _primaryAccent.withOpacity(0.1)],
                                  ),
                                  border: Border.all(color: _primaryAccent.withOpacity(0.4), width: 2),
                                ),
                                child: Center(
                                  child: Icon(Icons.person_add_rounded, color: _primaryAccent, size: 40),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Profile Photo',
                                style: TextStyle(color: _textLight, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Photo upload feature coming soon')),
                                  );
                                },
                                child: Text(
                                  'Click to upload photo\nPNG, JPG up to 5MB',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: _textGrey, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Form Fields
                        _buildEditField('Full Name', _nameController),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildEditField('Employee ID', _employeeIdController, helperText: 'Used for login'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildEditField('Password', _passwordController,
                            obscure: true,
                            helperText: 'Create password for HR manager'),
                        const SizedBox(height: 14),
                        _buildEditField('Email', _emailController),
                        const SizedBox(height: 14),
                        _buildEditField('Phone', _phoneController),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField('Date of Birth', _dobController, context, helperText: 'dd-MM-yyyy'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildEditField('Address', _addressController, maxLines: 3),
                        const SizedBox(height: 14),
                        _buildEditField('Department', _departmentController),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildEditField('Position', _positionController),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField('Job Date', _jobDateController, context, helperText: 'dd-MM-yyyy'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _textLight,
                                  side: BorderSide(color: _border.withOpacity(0.8), width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                                ),
                                child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryAccent, _primaryAccent.withOpacity(0.85)],
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryAccent.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      // TODO: Implement create API call
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Manager created successfully'),
                                          backgroundColor: _secondaryAccent,
                                        ),
                                      );
                                      _loadHRAccounts();
                                    },
                                    borderRadius: BorderRadius.circular(11),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 13),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_rounded, size: 18, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text(
                                            'Create Account',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Future<void> _showDeleteConfirmDialog(Map<String, dynamic> account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: _section,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border.withOpacity(0.5), width: 1),
          ),
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_rounded, color: _red, size: 24),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete Manager?',
                  style: TextStyle(
                    color: _textLight,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(color: _textGrey, fontSize: 13),
                    children: [
                      const TextSpan(text: 'Are you sure you want to delete '),
                      TextSpan(
                        text: account['name'] ?? 'this manager',
                        style: const TextStyle(color: _textLight, fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: '? This action cannot be undone.'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _border.withOpacity(0.8), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    _deleteManager(account['_id'], account['name']);
  }

  Future<void> _deleteManager(String managerId, String managerName) async {
    if (_token == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // TODO: Implement delete API call
      // await HRAccountsService.deleteHRAccount(_token!, managerId);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$managerName deleted successfully'),
            backgroundColor: _secondaryAccent,
          ),
        );
        _loadHRAccounts();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: _red,
          ),
        );
      }
    }
  }

  Widget _buildEditField(String label, TextEditingController controller, {
    String? helperText,
    bool obscure = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textLight,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          maxLines: obscure ? 1 : maxLines,
          minLines: maxLines > 1 ? 3 : 1,
          style: const TextStyle(color: _textLight, fontSize: 14),
          decoration: InputDecoration(
            helperText: helperText,
            helperStyle: TextStyle(color: _textGrey, fontSize: 11),
            hintStyle: TextStyle(color: _textGrey, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            filled: true,
            fillColor: _input,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: _border.withOpacity(0.6), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: _border.withOpacity(0.6), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSelector(String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            color: _textLight,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _input,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _border.withOpacity(0.6), width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: const [
                DropdownMenuItem(
                  value: 'active',
                  child: Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Text('Active', style: TextStyle(color: _textLight, fontSize: 14)),
                  ),
                ),
                DropdownMenuItem(
                  value: 'inactive',
                  child: Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Text('Inactive', style: TextStyle(color: _textLight, fontSize: 14)),
                  ),
                ),
              ],
              onChanged: (v) => onChanged(v ?? 'active'),
              dropdownColor: _section,
              iconEnabledColor: _textGrey,
              style: const TextStyle(color: _textLight, fontSize: 14),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    TextEditingController controller,
    BuildContext context, {
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textLight,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              try {
                DateTime? initialDate;
                if (controller.text.isNotEmpty) {
                  try {
                    initialDate = DateFormat('dd-MM-yyyy').parse(controller.text);
                  } catch (_) {
                    initialDate = DateTime.now();
                  }
                } else {
                  initialDate = DateTime.now();
                }

                final picked = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(1990),
                  lastDate: DateTime.now(),
                  builder: (BuildContext context, Widget? child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: _primaryAccent,
                          onPrimary: Colors.white,
                          surface: _section,
                          onSurface: _textLight,
                          outline: _border,
                        ),
                        textTheme: Theme.of(context).textTheme.copyWith(
                          bodyLarge: const TextStyle(color: _textLight),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (picked != null) {
                  controller.text = DateFormat('dd-MM-yyyy').format(picked);
                }
              } catch (e) {
                debugPrint('Date picker error: $e');
              }
            },
            borderRadius: BorderRadius.circular(11),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                color: _input,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _border.withOpacity(0.6), width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.text.isEmpty ? 'Select date' : controller.text,
                      style: TextStyle(
                        color: controller.text.isEmpty ? _textGrey : _textLight,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(Icons.calendar_today_rounded, color: _primaryAccent, size: 18),
                ],
              ),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: TextStyle(color: _textGrey, fontSize: 11),
          ),
        ],
      ],
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr.toString());
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return '-';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: _textGrey,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: _textLight, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final isMobile = responsive.isMobile;

    final total = _hrAccounts.length;
    final active = _hrAccounts.where((a) => (a['status'] ?? '').toString().toLowerCase() == 'active').length;
    final inactive = total - active;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _section,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textLight),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HR Accounts',
              style: TextStyle(
                color: _textLight,
                fontWeight: FontWeight.bold,
                fontSize: 17,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Manage HR manager accounts',
              style: TextStyle(color: _textGrey, fontSize: 11),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: _showAddManagerDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryAccent, _primaryAccent.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryAccent.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 17),
                    SizedBox(width: 6),
                    Text(
                      'Add HR Manager',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: _border.withOpacity(0.4)),
        ),
      ),

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Section
            if (!_isLoading && _error == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    _buildStatCard('Total HR Managers', '$total',
                        Icons.people_rounded, _primaryAccent),
                    const SizedBox(width: 10),
                    _buildStatCard('Active', '$active',
                        Icons.check_circle_rounded, _secondaryAccent),
                    const SizedBox(width: 10),
                    _buildStatCard('Inactive', '$inactive',
                        Icons.cancel_outlined, _textGrey),
                    const SizedBox(width: 10),
                    _buildStatCard('Employees\nManaged', '-',
                        Icons.manage_accounts_rounded, _orange),
                  ],
                ),
              ),

            // Section header + search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isLoading && _error == null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: _section,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(13),
                          topRight: Radius.circular(13),
                        ),
                        border: Border(
                          top: BorderSide(color: _border.withOpacity(0.5)),
                          left: BorderSide(color: _border.withOpacity(0.5)),
                          right: BorderSide(color: _border.withOpacity(0.5)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _primaryAccent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'All HR Managers',
                            style: TextStyle(
                              color: _textLight,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_filteredAccounts.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _primaryAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_filteredAccounts.length} total',
                                style: TextStyle(
                                  color: _primaryAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: _input,
                      borderRadius: BorderRadius.only(
                        topLeft: (_isLoading || _error != null)
                            ? const Radius.circular(13)
                            : Radius.zero,
                        topRight: (_isLoading || _error != null)
                            ? const Radius.circular(13)
                            : Radius.zero,
                        bottomLeft: const Radius.circular(13),
                        bottomRight: const Radius.circular(13),
                      ),
                      border: Border.all(color: _border.withOpacity(0.5), width: 1),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: _textLight, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by name, email, company...',
                        hintStyle: TextStyle(color: _textGrey, fontSize: 13),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: _searchQuery.isNotEmpty ? _primaryAccent : _textGrey,
                          size: 20,
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 46),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded, color: _textGrey, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _filteredAccounts = _hrAccounts;
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Content
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: _primaryAccent))
                  : _error != null
                      ? _buildErrorWidget()
                      : _filteredAccounts.isEmpty
                          ? _buildEmptyWidget()
                          : _buildAccountsList(isMobile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: _section,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _border.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: _textLight,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: _textGrey, fontSize: 10, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: _red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Managers',
              style: TextStyle(
                color: _textLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textGrey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadHRAccounts,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
              backgroundColor: _primaryAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, color: _textGrey, size: 64),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No HR Managers Found' : 'No Results Found',
              style: const TextStyle(
                color: _textLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'No HR managers are currently registered.'
                  : 'No HR managers match your search criteria.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textGrey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddManagerDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Manager'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsList(bool isMobile) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _filteredAccounts.length,
      itemBuilder: (context, index) {
        final account = _filteredAccounts[index] as Map<String, dynamic>;
        return _buildAccountCard(account, isMobile);
      },
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account, bool isMobile) {
    final status = (account['status'] ?? 'unknown').toString().toLowerCase();
    final statusColor = status == 'active' ? _secondaryAccent : _orange;
    final joinDate = account['joinDate'] != null ? _formatDate(account['joinDate']) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _section,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header row ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryAccent.withOpacity(0.28),
                        _primaryAccent.withOpacity(0.12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: _primaryAccent.withOpacity(0.35), width: 1.2),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(account['name'] ?? 'HR'),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + since date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account['name'] ?? 'Unknown',
                        style: const TextStyle(
                          color: _textLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        joinDate != null ? 'Since $joinDate' : account['email'] ?? '-',
                        style: TextStyle(color: _textGrey, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.35), width: 1),
                  ),
                  child: Text(
                    status == 'active' ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Action buttons
                _buildActionBtn(Icons.remove_red_eye_rounded, _textGrey,
                    () => _showDetailsDialog(account), 'View'),
                const SizedBox(width: 4),
                _buildActionBtn(Icons.edit_rounded, _primaryAccent,
                    () => _showEditManagerDialog(account), 'Edit'),
                const SizedBox(width: 4),
                _buildActionBtn(Icons.delete_rounded, _red,
                    () => _showDeleteConfirmDialog(account), 'Delete'),
              ],
            ),
          ),
          // ── Divider ─────────────────────────────────
          Divider(color: _border.withOpacity(0.4), height: 1),
          // ── Info grid ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoTile(
                        Icons.badge_outlined,
                        'Login ID',
                        account['employeeId'] ?? '-',
                        _primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoTile(
                        Icons.business_outlined,
                        'Company',
                        account['company']?['name'] ?? 'N/A',
                        _textGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoTile(
                        Icons.phone_outlined,
                        'Contact',
                        account['phone'] ?? '-',
                        _textGrey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoTile(
                        Icons.work_outline_rounded,
                        'Position',
                        account['department'] ?? 'HR Manager',
                        _textGrey,
                      ),
                    ),
                  ],
                ),
                if (account['email'] != null) ...[
                  const SizedBox(height: 10),
                  _buildInfoTile(
                    Icons.email_outlined,
                    'Email',
                    account['email'] ?? '-',
                    _textGrey,
                    fullWidth: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(
      IconData icon, Color color, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(child: Icon(icon, color: color, size: 16)),
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value,
    Color iconColor, {
    bool fullWidth = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _input,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: _textGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: _textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }



  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final last = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + last).toUpperCase().isEmpty ? '?' : (first + last).toUpperCase();
  }
}
