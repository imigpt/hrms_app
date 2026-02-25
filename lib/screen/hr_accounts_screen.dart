import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/hr_accounts_service.dart';
import '../utils/responsive_utils.dart';

class HRAccountsScreen extends StatefulWidget {
  final String? token;

  const HRAccountsScreen({super.key, this.token});

  @override
  State<HRAccountsScreen> createState() => _HRAccountsScreenState();
}

class _HRAccountsScreenState extends State<HRAccountsScreen> {
  // Theme colors
  final Color _bgDark = const Color(0xFF050505);
  final Color _cardDark = const Color(0xFF141414);
  final Color _inputDark = const Color(0xFF1F1F1F);
  final Color _accentBlue = const Color(0xFF1E88E5);
  final Color _accentGreen = const Color(0xFF00C853);
  final Color _accentPink = const Color(0xFFFF8FA3);
  final Color _textGrey = const Color(0xFF9E9E9E);

  // State
  bool _isLoading = true;
  String? _error;
  List<dynamic> _hrAccounts = [];
  List<dynamic> _filteredAccounts = [];
  String _searchQuery = '';
  String? _token;

  @override
  void initState() {
    super.initState();
    _token = widget.token;
    _loadHRAccounts();
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
      builder: (context) => AlertDialog(
        backgroundColor: _cardDark,
        title: Text(
          account['name'] ?? 'HR Account',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Employee ID', account['employeeId'] ?? '-'),
              _buildDetailRow('Email', account['email'] ?? '-'),
              _buildDetailRow('Phone', account['phone'] ?? '-'),
              _buildDetailRow('Department', account['department'] ?? '-'),
              _buildDetailRow('Company', account['company']?['name'] ?? '-'),
              _buildDetailRow('Status', account['status'] ?? '-'),
              _buildDetailRow('Join Date', _formatDate(account['joinDate'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showResetPasswordDialog(account);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _accentPink),
            child: const Text('Reset Password', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetPasswordDialog(Map<String, dynamic> account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardDark,
        title: const Text('Reset Password?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Reset password for ${account['name']}? A new temporary password will be sent to their email.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
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
            backgroundColor: _accentGreen,
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
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: _textGrey, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
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

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _cardDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('HR Accounts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _inputDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or company...',
                    hintStyle: TextStyle(color: _textGrey.withOpacity(0.6)),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search_rounded, color: _textGrey, size: 20),
                    prefixIconConstraints: const BoxConstraints(minWidth: 40),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: _accentBlue),
                    )
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

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            Text(
              'Error Loading Accounts',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: _accentBlue),
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
            Icon(Icons.people_outline, color: _textGrey, size: 64),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No HR Accounts Found' : 'No Results Found',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'No HR accounts are currently registered.'
                  : 'No HR accounts match your search criteria.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textGrey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsList(bool isMobile) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredAccounts.length,
      itemBuilder: (context, index) {
        final account = _filteredAccounts[index] as Map<String, dynamic>;
        return _buildAccountCard(account, isMobile);
      },
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account, bool isMobile) {
    final status = (account['status'] ?? 'unknown').toString().toLowerCase();
    final statusColor = status == 'active' ? _accentGreen : Colors.orange;

    return GestureDetector(
      onTap: () => _showDetailsDialog(account),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name and Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _accentBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(account['name'] ?? 'HR'),
                      style: TextStyle(
                        color: _accentBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name and Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account['name'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Quick Action Button
                IconButton(
                  onPressed: () => _showResetPasswordDialog(account),
                  icon: const Icon(Icons.vpn_key_rounded, color: Colors.orange, size: 20),
                  tooltip: 'Reset Password',
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Details Grid
            isMobile ? _buildMobileDetails(account) : _buildDesktopDetails(account),
            const SizedBox(height: 12),
            // Footer: View Details Link
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Tap to view details →',
                style: TextStyle(color: _accentBlue, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDetails(Map<String, dynamic> account) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem('📧', account['email'] ?? '-', isMobile: true),
        const SizedBox(height: 8),
        _buildDetailItem('🏢', account['company']?['name'] ?? '-', isMobile: true),
        const SizedBox(height: 8),
        _buildDetailItem('👔', account['department'] ?? '-', isMobile: true),
        const SizedBox(height: 8),
        _buildDetailItem('🆔', account['employeeId'] ?? '-', isMobile: true),
      ],
    );
  }

  Widget _buildDesktopDetails(Map<String, dynamic> account) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('📧', account['email'] ?? '-'),
              const SizedBox(height: 6),
              _buildDetailItem('🏢', account['company']?['name'] ?? '-'),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('👔', account['department'] ?? '-'),
              const SizedBox(height: 6),
              _buildDetailItem('🆔', account['employeeId'] ?? '-'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String icon, String value, {bool isMobile = false}) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: _textGrey,
              fontSize: isMobile ? 12 : 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
