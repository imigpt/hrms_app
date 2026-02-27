import 'package:flutter/material.dart';
import 'package:hrms_app/models/profile_model.dart';
import 'package:hrms_app/services/profile_service.dart';
import 'package:hrms_app/services/token_storage_service.dart';
import 'package:hrms_app/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  final ProfileUser? user;
  final String? token;

  const SettingsScreen({super.key, this.user, this.token});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ── All settings items (title, subtitle, icon, section) ──────────────────
  final List<_SettingsItem> _allItems = const [
    _SettingsItem(
      section: 'Account',
      title: 'Profile',
      subtitle: 'Update your name, photo and personal info',
      icon: Icons.person_rounded,
      color: Color(0xFF3B82F6),
      route: 'profile',
    ),
    _SettingsItem(
      section: 'Account',
      title: 'Change Password',
      subtitle: 'Keep your account secure with a strong password',
      icon: Icons.lock_rounded,
      color: Color(0xFFEC4899),
      route: 'password',
    ),
    _SettingsItem(
      section: 'Preferences',
      title: 'Notifications',
      subtitle: 'Manage alerts and push notification settings',
      icon: Icons.notifications_rounded,
      color: Color(0xFFF59E0B),
      route: 'notifications',
    ),
    _SettingsItem(
      section: 'Preferences',
      title: 'Appearance',
      subtitle: 'Theme, font size and display preferences',
      icon: Icons.palette_rounded,
      color: Color(0xFF8B5CF6),
      route: 'appearance',
    ),
    _SettingsItem(
      section: 'Support',
      title: 'Help & Support',
      subtitle: 'FAQs, contact support and documentation',
      icon: Icons.help_rounded,
      color: Color(0xFF10B981),
      route: 'help',
    ),
    _SettingsItem(
      section: 'Support',
      title: 'Privacy Policy',
      subtitle: 'View how we handle your data',
      icon: Icons.policy_rounded,
      color: Color(0xFF06B6D4),
      route: 'privacy',
    ),
    _SettingsItem(
      section: 'About',
      title: 'About App',
      subtitle: 'Version info, changelog and credits',
      icon: Icons.info_rounded,
      color: Color(0xFF64748B),
      route: 'about',
    ),
  ];

  List<_SettingsItem> get _filtered {
    if (_searchQuery.isEmpty) return _allItems;
    final q = _searchQuery.toLowerCase();
    return _allItems
        .where((i) =>
            i.title.toLowerCase().contains(q) ||
            i.subtitle.toLowerCase().contains(q) ||
            i.section.toLowerCase().contains(q))
        .toList();
  }

  Map<String, List<_SettingsItem>> get _grouped {
    final map = <String, List<_SettingsItem>>{};
    for (final item in _filtered) {
      map.putIfAbsent(item.section, () => []).add(item);
    }
    return map;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Navigate to sub-screen ──────────────────────────────────────────────
  void _onItemTap(_SettingsItem item) {
    if (item.route == 'profile') {
      Navigator.of(context).push(_route(
        _ProfileSettingsScreen(user: widget.user, token: widget.token),
      ));
    } else if (item.route == 'password') {
      Navigator.of(context).push(_route(
        _ChangePasswordScreen(token: widget.token),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.title} — coming soon'),
          backgroundColor: AppTheme.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  PageRouteBuilder _route(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween(begin: const Offset(0.04, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      );

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            _Header(user: widget.user),

            const SizedBox(height: 4),

            // ── Search Bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search settings…',
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Colors.grey[600], size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: Colors.grey[600], size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Settings List ─────────────────────────────────────────────
            Expanded(
              child: grouped.isEmpty
                  ? _emptySearch()
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 32),
                      children: grouped.entries
                          .map((e) => _SectionGroup(
                                section: e.key,
                                items: e.value,
                                onTap: _onItemTap,
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptySearch() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, color: Colors.grey[700], size: 52),
            const SizedBox(height: 12),
            Text(
              'No settings found',
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Try different keywords',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Header Widget
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final ProfileUser? user;
  const _Header({this.user});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(user?.name ?? 'U');
    final photo = user?.profilePhotoUrl ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                Text('Manage your account & preferences',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.cardColor,
              border: Border.all(
                  color: Colors.white.withOpacity(0.08), width: 1.5),
              image: photo.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(photo), fit: BoxFit.cover)
                  : null,
            ),
            child: photo.isEmpty
                ? Center(
                    child: Text(initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)))
                : null,
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Group
// ─────────────────────────────────────────────────────────────────────────────
class _SectionGroup extends StatelessWidget {
  final String section;
  final List<_SettingsItem> items;
  final ValueChanged<_SettingsItem> onTap;
  const _SectionGroup(
      {required this.section, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
            child: Text(
              section.toUpperCase(),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withOpacity(0.05), width: 1),
            ),
            child: Column(
              children: items
                  .asMap()
                  .entries
                  .map((e) => _SettingsTile(
                        item: e.value,
                        isFirst: e.key == 0,
                        isLast: e.key == items.length - 1,
                        onTap: onTap,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Tile
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final _SettingsItem item;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<_SettingsItem> onTap;

  const _SettingsTile(
      {required this.item,
      required this.isFirst,
      required this.isLast,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(item),
            borderRadius: BorderRadius.vertical(
              top: isFirst ? const Radius.circular(16) : Radius.zero,
              bottom: isLast ? const Radius.circular(16) : Radius.zero,
            ),
            splashColor: Colors.white.withOpacity(0.04),
            highlightColor: Colors.white.withOpacity(0.02),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.grey[700], size: 20),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: Colors.white.withOpacity(0.05),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model (const-friendly)
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsItem {
  final String section;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _SettingsItem({
    required this.section,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// PROFILE SETTINGS SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class _ProfileSettingsScreen extends StatefulWidget {
  final ProfileUser? user;
  final String? token;
  const _ProfileSettingsScreen({this.user, this.token});

  @override
  State<_ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<_ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  final _tokenService = TokenStorageService();

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _bioCtrl;

  ProfileUser? _user;
  String? _token;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _init();
  }

  Future<void> _init() async {
    _token = widget.token ?? await _tokenService.getToken();
    if (_token != null) {
      final fetched = await _profileService.fetchProfile(_token!);
      if (mounted) {
        setState(() {
          _user = fetched ?? widget.user;
          _applyUser(_user);
          _loading = false;
        });
      }
    } else {
      setState(() {
        _user = widget.user;
        _applyUser(_user);
        _loading = false;
      });
    }
  }

  void _applyUser(ProfileUser? u) {
    if (u == null) return;
    _nameCtrl.text = u.name;
    _emailCtrl.text = u.email;
    _phoneCtrl.text = u.phone;
    _addressCtrl.text = u.address;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_token == null) return;

    setState(() => _saving = true);

    final result = await _profileService.updateProfile(
      token: _token!,
      userId: _user?.id ?? '',
      payload: {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      },
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      if (result['user'] != null) {
        setState(() => _user = result['user'] as ProfileUser);
      }
      _showSnack('Profile updated successfully', isSuccess: true);
    } else {
      _showSnack(result['message'] ?? 'Update failed', isSuccess: false);
    }
  }

  void _showSnack(String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(msg, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: isSuccess ? AppTheme.successColor : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _SubScreenHeader(
              title: 'Profile',
              subtitle: 'Your admin profile information',
              icon: Icons.person_rounded,
              iconColor: AppTheme.primaryColor,
              trailing: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5))
                  : _ActionButton(
                      label: 'Update',
                      icon: Icons.save_rounded,
                      color: AppTheme.primaryColor,
                      onTap: _save,
                    ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Avatar row
                            _AvatarCard(user: _user),
                            const SizedBox(height: 24),

                            // Fields (2-column grid where possible)
                            _buildRow(
                              _FormField(
                                label: 'Full Name',
                                controller: _nameCtrl,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Name is required'
                                    : null,
                              ),
                              _FormField(
                                label: 'Email',
                                controller: _emailCtrl,
                                readOnly: true,
                                hint: 'Email cannot be changed',
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildRow(
                              _FormField(
                                label: 'Phone',
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                              ),
                              _FormField(
                                label: 'Address',
                                controller: _addressCtrl,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _FormField(
                              label: 'Bio',
                              controller: _bioCtrl,
                              hint: 'A short bio...',
                              minLines: 3,
                            ),
                            const SizedBox(height: 24),

                            // Info cards (read-only employment data)
                            if (_user != null) ...[
                              _SectionLabel('Employment Details'),
                              const SizedBox(height: 12),
                              _InfoGrid(user: _user!),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(Widget left, Widget right) {
    return LayoutBuilder(builder: (ctx, c) {
      if (c.maxWidth >= 500) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 14),
            Expanded(child: right),
          ],
        );
      }
      return Column(
        children: [
          left,
          const SizedBox(height: 16),
          right,
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar Card
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarCard extends StatelessWidget {
  final ProfileUser? user;
  const _AvatarCard({this.user});

  @override
  Widget build(BuildContext context) {
    final photo = user?.profilePhotoUrl ?? '';
    final initials = _buildInitials(user?.name ?? 'U');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.cardColor,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1), width: 2),
                  image: photo.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(photo), fit: BoxFit.cover)
                      : null,
                ),
                child: photo.isEmpty
                    ? Center(
                        child: Text(initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 20)))
                    : null,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _titleCase(user?.role ?? 'Employee'),
                  style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                if (user?.department != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _titleCase(user!.department),
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Grid (read-only employment data)
// ─────────────────────────────────────────────────────────────────────────────
class _InfoGrid extends StatelessWidget {
  final ProfileUser user;
  const _InfoGrid({required this.user});

  @override
  Widget build(BuildContext context) {
    final items = <MapEntry<String, String>>[
      MapEntry('Employee ID', user.employeeId),
      MapEntry('Department', _tc(user.department)),
      MapEntry('Position', user.position),
      MapEntry('Role', _tc(user.role)),
      MapEntry('Status', _tc(user.status)),
      if (user.joinDate != null)
        MapEntry('Join Date',
            '${user.joinDate!.day.toString().padLeft(2, '0')} '
            '${_months[user.joinDate!.month - 1]} '
            '${user.joinDate!.year}'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: items
            .asMap()
            .entries
            .map((e) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.value.key,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13)),
                          Text(
                            e.value.value.isEmpty ? '—' : e.value.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (e.key < items.length - 1)
                      Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Colors.white.withOpacity(0.05)),
                  ],
                ))
            .toList(),
      ),
    );
  }

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  String _tc(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CHANGE PASSWORD SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class _ChangePasswordScreen extends StatefulWidget {
  final String? token;
  const _ChangePasswordScreen({this.token});

  @override
  State<_ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<_ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  final _tokenService = TokenStorageService();

  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _resolveToken();
  }

  Future<void> _resolveToken() async {
    _token = widget.token ?? await _tokenService.getToken();
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_token == null) {
      _showSnack('Session expired. Please log in again.', isSuccess: false);
      return;
    }

    setState(() => _loading = true);

    final result = await _profileService.changePassword(
      token: _token!,
      currentPassword: _currentCtrl.text,
      newPassword: _newCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      _showSnack('Password changed successfully', isSuccess: true);
    } else {
      _showSnack(result['message'] ?? 'Failed to change password',
          isSuccess: false);
    }
  }

  void _showSnack(String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(msg, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor:
            isSuccess ? AppTheme.successColor : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _SubScreenHeader(
              title: 'Change Password',
              subtitle:
                  "Update your account password. You'll need your current password to make changes.",
              icon: Icons.lock_rounded,
              iconColor: AppTheme.primaryColor,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Password strength hint card
                      _PasswordHintCard(),
                      const SizedBox(height: 24),

                      // Current Password
                      _SectionLabel('Current Password'),
                      const SizedBox(height: 10),
                      _PasswordField(
                        controller: _currentCtrl,
                        hint: 'Enter current password',
                        show: _showCurrent,
                        onToggle: () =>
                            setState(() => _showCurrent = !_showCurrent),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Current password is required'
                            : null,
                      ),

                      const SizedBox(height: 20),

                      // New Password
                      _SectionLabel('New Password'),
                      const SizedBox(height: 10),
                      _PasswordField(
                        controller: _newCtrl,
                        hint: 'Enter new password (min 6 chars)',
                        show: _showNew,
                        onToggle: () => setState(() => _showNew = !_showNew),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'New password is required';
                          }
                          if (v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      // Strength indicator
                      const SizedBox(height: 8),
                      _StrengthBar(password: _newCtrl.text),

                      const SizedBox(height: 20),

                      // Confirm New Password
                      _SectionLabel('Confirm New Password'),
                      const SizedBox(height: 10),
                      _PasswordField(
                        controller: _confirmCtrl,
                        hint: 'Confirm new password',
                        show: _showConfirm,
                        onToggle: () =>
                            setState(() => _showConfirm = !_showConfirm),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (v != _newCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lock_reset_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Update Password',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Password strength indicator
// ─────────────────────────────────────────────────────────────────────────────
class _StrengthBar extends StatefulWidget {
  final String password;
  const _StrengthBar({required this.password});

  @override
  State<_StrengthBar> createState() => _StrengthBarState();
}

class _StrengthBarState extends State<_StrengthBar> {
  @override
  Widget build(BuildContext context) {
    int score = _score(widget.password);
    final colors = [
      Colors.transparent,
      AppTheme.errorColor,
      Colors.orange,
      Colors.amber,
      AppTheme.successColor,
    ];
    final labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];

    return Row(
      children: [
        ...List.generate(
          4,
          (i) => Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: i < score ? colors[score] : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            score > 0 ? labels[score] : '',
            key: ValueKey(score),
            style: TextStyle(
              color: score > 0 ? colors[score] : Colors.transparent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  int _score(String p) {
    if (p.isEmpty) return 0;
    int s = 0;
    if (p.length >= 6) s++;
    if (p.contains(RegExp(r'[A-Z]')) && p.contains(RegExp(r'[a-z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) s++;
    return s.clamp(0, 4);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Password hint card
// ─────────────────────────────────────────────────────────────────────────────
class _PasswordHintCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tips = [
      'Use at least 8 characters',
      'Mix uppercase & lowercase letters',
      'Include numbers and special characters',
      'Avoid common words or patterns',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded,
                  color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Password Tips',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: Colors.grey[600], size: 14),
                  const SizedBox(width: 8),
                  Text(t,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable sub-screen header
// ─────────────────────────────────────────────────────────────────────────────
class _SubScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget? trailing;

  const _SubScreenHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 12),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Button (Update)
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Password field
// ─────────────────────────────────────────────────────────────────────────────
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool show;
  final VoidCallback onToggle;
  final FormFieldValidator<String>? validator;

  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.show,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.grey[600],
            size: 19,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.errorColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic form field
// ─────────────────────────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool readOnly;
  final int? minLines;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  const _FormField({
    required this.label,
    required this.controller,
    this.hint,
    this.readOnly = false,
    this.minLines,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          minLines: minLines ?? 1,
          maxLines: minLines != null ? minLines! + 2 : 1,
          keyboardType: keyboardType,
          style: TextStyle(
            color: readOnly ? Colors.grey[500] : Colors.white,
            fontSize: 14,
          ),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
            filled: true,
            fillColor: readOnly
                ? AppTheme.background
                : AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.errorColor),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}


