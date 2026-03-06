import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms_app/services/settings_service.dart';
import 'package:hrms_app/theme/app_theme.dart';
import 'shared.dart';

class AdminUserCredentialsScreen extends StatefulWidget {
  final String? token;
  const AdminUserCredentialsScreen({super.key, this.token});

  @override
  State<AdminUserCredentialsScreen> createState() =>
      _AdminUserCredentialsScreenState();
}

class _AdminUserCredentialsScreenState
    extends State<AdminUserCredentialsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;
  final _searchCtrl = TextEditingController();
  String _roleFilter = 'all';

  // Reset password dialog
  Map<String, dynamic>? _selectedUser;
  final _newPwdCtrl = TextEditingController();
  bool _showPwd = false;
  bool _resetting = false;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    _page = 1;
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await SettingsService.getUserCredentials(
        widget.token ?? '',
        search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
        role: _roleFilter == 'all' ? null : _roleFilter,
        page: _page,
        limit: 10,
      );
      final data = res['data'];
      if (data is List) {
        setState(() {
          _users = data.cast<Map<String, dynamic>>();
          _totalPages = res['totalPages'] ?? 1;
          _total = res['total'] ?? data.length;
        });
      } else if (data is Map) {
        final list = data['users'] ?? data['data'] ?? [];
        setState(() {
          _users = (list as List).cast<Map<String, dynamic>>();
          _totalPages = res['totalPages'] ?? 1;
          _total = res['total'] ?? _users.length;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _generatePassword() async {
    setState(() => _generating = true);
    try {
      final res = await SettingsService.generatePassword(widget.token ?? '');
      final pwd = res['data']?.toString() ?? res['password']?.toString();
      if (pwd != null) setState(() => _newPwdCtrl.text = pwd);
    } catch (_) {}
    if (mounted) setState(() => _generating = false);
  }

  Future<void> _resetPassword() async {
    if (_selectedUser == null || _newPwdCtrl.text.isEmpty) return;
    setState(() => _resetting = true);
    try {
      await SettingsService.adminResetUserPassword(
        widget.token ?? '',
        _selectedUser!['_id'],
        _newPwdCtrl.text,
      );
      if (mounted) {
        Navigator.of(context).pop();
        showAdminSnack(context, 'Password reset successfully');
        _newPwdCtrl.clear();
      }
    } catch (_) {
      if (mounted)
        showAdminSnack(context, 'Failed to reset password', error: true);
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  void _openResetDialog(Map<String, dynamic> user) {
    setState(() {
      _selectedUser = user;
      _newPwdCtrl.clear();
      _showPwd = false;
    });
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reset Password',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user['name']?.toString() ?? user['email'] ?? '',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _newPwdCtrl,
                obscureText: !_showPwd,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter new password',
                  hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                  filled: true,
                  fillColor: AppTheme.background,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _showPwd
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Colors.grey[500],
                          size: 18,
                        ),
                        onPressed: () => setDlg(() => _showPwd = !_showPwd),
                      ),
                      IconButton(
                        icon: _generating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF3B82F6),
                                ),
                              )
                            : const Icon(
                                Icons.refresh_rounded,
                                color: Color(0xFF3B82F6),
                                size: 18,
                              ),
                        onPressed: _generating
                            ? null
                            : () async {
                                await _generatePassword();
                                setDlg(() {});
                              },
                        tooltip: 'Generate password',
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              if (_newPwdCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _newPwdCtrl.text));
                      showAdminSnack(context, 'Copied to clipboard');
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          size: 13,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Copy password',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[500])),
            ),
            GestureDetector(
              onTap: _resetting ? null : _resetPassword,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _resetting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Reset',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    _newPwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            AdminSubScreenHeader(
              title: 'User Credentials',
              subtitle: 'Manage user logins and reset passwords',
              icon: Icons.people_rounded,
              iconColor: const Color(0xFF8B5CF6),
            ),
            // Search + Role filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search users…',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Colors.grey[600],
                            size: 18,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _roleFilter,
                        dropdownColor: AppTheme.cardColor,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All Roles'),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
                          DropdownMenuItem(value: 'hr', child: Text('HR')),
                          DropdownMenuItem(
                            value: 'employee',
                            child: Text('Employee'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _roleFilter = v!;
                            _page = 1;
                          });
                          _load();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? adminLoader()
                  : _users.isEmpty
                  ? Center(
                      child: Text(
                        'No users found.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) => _UserTile(
                        user: _users[i],
                        onReset: () => _openResetDialog(_users[i]),
                      ),
                    ),
            ),
            // Pagination
            if (_totalPages > 1)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                color: AppTheme.background,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_total users total',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _page > 1
                              ? () {
                                  setState(() => _page--);
                                  _load();
                                }
                              : null,
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            color: _page > 1 ? Colors.white : Colors.grey[700],
                          ),
                        ),
                        Text(
                          '$_page / $_totalPages',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        IconButton(
                          onPressed: _page < _totalPages
                              ? () {
                                  setState(() => _page++);
                                  _load();
                                }
                              : null,
                          icon: Icon(
                            Icons.chevron_right_rounded,
                            color: _page < _totalPages
                                ? Colors.white
                                : Colors.grey[700],
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
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onReset;
  const _UserTile({required this.user, required this.onReset});

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFf4879a);
      case 'hr':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF22C55E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = user['name']?.toString() ?? '—';
    final email = user['email']?.toString() ?? '—';
    final role = user['role']?.toString() ?? 'employee';
    final dept = user['department']?.toString();
    final initials = name.isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0]).join().toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _roleColor(role).withOpacity(0.15),
            child: Text(
              initials,
              style: TextStyle(
                color: _roleColor(role),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _RoleBadge(role: role, color: _roleColor(role)),
                    if (dept != null && dept.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        dept,
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onReset,
            icon: Icon(Icons.key_rounded, color: Colors.grey[600], size: 18),
            tooltip: 'Reset password',
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  final Color color;
  const _RoleBadge({required this.role, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role[0].toUpperCase() + role.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
