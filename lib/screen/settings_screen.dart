import 'package:flutter/material.dart';
import 'package:hrms_app/models/profile_model.dart';
import 'package:hrms_app/services/admin_service.dart';
import 'package:hrms_app/services/profile_service.dart';
import 'package:hrms_app/services/settings_service.dart';
import 'package:hrms_app/services/token_storage_service.dart';
import 'package:hrms_app/theme/app_theme.dart';
import 'admin/admin_settings/company_settings_screen.dart';
import 'admin/admin_settings/currencies_screen.dart';
import 'admin/admin_settings/email_settings_screen.dart';
import 'admin/admin_settings/employee_id_screen.dart';
import 'admin/admin_settings/hrm_settings_screen.dart';
import 'admin/admin_settings/locations_screen.dart';
import 'admin/admin_settings/payroll_settings_screen.dart';
import 'admin/admin_settings/pdf_fonts_screen.dart';
import 'admin/admin_settings/roles_permissions_screen.dart';
import 'admin/admin_settings/storage_settings_screen.dart';
import 'admin/admin_settings/translations_screen.dart';
import 'admin/admin_settings/user_credentials_screen.dart';
import 'admin/admin_settings/work_status_screen.dart';
import 'hr_accounts_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  final ProfileUser? user;
  final String? token;

  const SettingsScreen({super.key, this.user, this.token});

  bool get isAdmin => (user?.role.toLowerCase() == 'admin');

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ── All settings items (title, subtitle, icon, section) ──────────────────
  static const List<_SettingsItem> _baseItems = [
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
    // _SettingsItem(
    //   section: 'Preferences',
    //   title: 'Notifications',
    //   subtitle: 'Manage alerts and push notification settings',
    //   icon: Icons.notifications_rounded,
    //   color: Color(0xFFF59E0B),
    //   route: 'notifications',
    // ),
    // _SettingsItem(
    //   section: 'Preferences',
    //   title: 'Appearance',
    //   subtitle: 'Theme, font size and display preferences',
    //   icon: Icons.palette_rounded,
    //   color: Color(0xFF8B5CF6),
    //   route: 'appearance',
    // ),
    // _SettingsItem(
    //   section: 'Support',
    //   title: 'Help & Support',
    //   subtitle: 'FAQs, contact support and documentation',
    //   icon: Icons.help_rounded,
    //   color: Color(0xFF10B981),
    //   route: 'help',
    // ),
    // _SettingsItem(
    //   section: 'Support',
    //   title: 'Privacy Policy',
    //   subtitle: 'View how we handle your data',
    //   icon: Icons.policy_rounded,
    //   color: Color(0xFF06B6D4),
    //   route: 'privacy',
    // ),
    // _SettingsItem(
    //   section: 'About',
    //   title: 'About App',
    //   subtitle: 'Version info, changelog and credits',
    //   icon: Icons.info_rounded,
    //   color: Color(0xFF64748B),
    //   route: 'about',
    // ),
  ];

  static const List<_SettingsItem> _adminItems = [
    _SettingsItem(
      section: 'System Settings',
      title: 'Company Settings',
      subtitle: 'Company info, timezone, integrations',
      icon: Icons.business_rounded,
      color: Color(0xFF3B82F6),
      route: 'settings_company',
    ),
    _SettingsItem(
      section: 'System Settings',
      title: 'User Credentials',
      subtitle: 'Manage user logins and reset passwords',
      icon: Icons.people_rounded,
      color: Color(0xFF8B5CF6),
      route: 'settings_user_credentials',
    ),
    _SettingsItem(
      section: 'System Settings',
      title: 'Translations',
      subtitle: 'Language, timezone and date format',
      icon: Icons.language_rounded,
      color: Color(0xFFF59E0B),
      route: 'settings_translations',
    ),
    _SettingsItem(
      section: 'System Settings',
      title: 'Role & Permissions',
      subtitle: 'Define roles and access control',
      icon: Icons.shield_rounded,
      color: Color(0xFF06B6D4),
      route: 'settings_roles',
    ),
    _SettingsItem(
      section: 'System Settings',
      title: 'Employee Work Status',
      subtitle: 'Configure available work status options',
      icon: Icons.verified_user_rounded,
      color: Color(0xFF22C55E),
      route: 'settings_work_status',
    ),
    _SettingsItem(
      section: 'System Settings',
      title: 'Currencies',
      subtitle: 'Set up supported currencies',
      icon: Icons.monetization_on_rounded,
      color: Color(0xFFEAB308),
      route: 'settings_currencies',
    ),
    _SettingsItem(
      section: 'System Settings',
      title: 'Locations',
      subtitle: 'Manage office and remote locations',
      icon: Icons.location_on_rounded,
      color: Color(0xFFEF4444),
      route: 'settings_locations',
    ),
    _SettingsItem(
      section: 'System Settings',
      title: 'PDF Fonts',
      subtitle: 'Configure fonts for PDF exports',
      icon: Icons.text_fields_rounded,
      color: Color(0xFF64748B),
      route: 'settings_pdf_fonts',
    ),
    _SettingsItem(
      section: 'System Settings',
      title: 'HRM Settings',
      subtitle: 'Attendance, clock-in rules and IP restrictions',
      icon: Icons.settings_rounded,
      color: Color(0xFFf4879a),
      route: 'settings_hrm',
    ),
    _SettingsItem(
      section: 'System Settings',
      title: 'Payroll Settings',
      subtitle: 'Payroll cycle, deductions and tax rules',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF3B82F6),
      route: 'settings_payroll',
    ),
    _SettingsItem(
      section: 'System Settings',
      title: 'Employee Custom Fields',
      subtitle: 'Define employee ID format and custom fields',
      icon: Icons.manage_accounts_rounded,
      color: Color(0xFF10B981),
      route: 'settings_employee_id',
    ),
    _SettingsItem(
      section: 'System Settings',
      title: 'Email Settings',
      subtitle: 'SMTP configuration and email triggers',
      icon: Icons.email_rounded,
      color: Color(0xFF8B5CF6),
      route: 'settings_email',
    ),
    _SettingsItem(
      section: 'System Settings',
      title: 'Storage Settings',
      subtitle: 'File storage provider and upload limits',
      icon: Icons.storage_rounded,
      color: Color(0xFFF59E0B),
      route: 'settings_storage',
    ),
  ];

  List<_SettingsItem> get _allItems => [
    if (widget.isAdmin) ..._adminItems,
    ..._baseItems,
  ];

  List<_SettingsItem> get _filtered {
    if (_searchQuery.isEmpty) return _allItems;
    final q = _searchQuery.toLowerCase();
    return _allItems
        .where(
          (i) =>
              i.title.toLowerCase().contains(q) ||
              i.subtitle.toLowerCase().contains(q) ||
              i.section.toLowerCase().contains(q),
        )
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
    switch (item.route) {
      case 'profile':
        Navigator.of(context).push(
          _route(
            _ProfileSettingsScreen(user: widget.user, token: widget.token),
          ),
        );
        break;
      case 'password':
        Navigator.of(
          context,
        ).push(_route(_ChangePasswordScreen(token: widget.token)));
        break;
      // ── System Settings routes ────────────────────────────────────────
      case 'settings_company':
        Navigator.of(
          context,
        ).push(_route(AdminCompanySettingsScreen(token: widget.token)));
        break;
      case 'settings_user_credentials':
        Navigator.of(
          context,
        ).push(_route(AdminUserCredentialsScreen(token: widget.token)));
        break;
      case 'settings_translations':
        Navigator.of(
          context,
        ).push(_route(AdminTranslationsScreen(token: widget.token)));
        break;
      case 'settings_roles':
        Navigator.of(
          context,
        ).push(_route(AdminRolesPermissionsScreen(token: widget.token)));
        break;
      case 'settings_work_status':
        Navigator.of(
          context,
        ).push(_route(AdminWorkStatusScreen(token: widget.token)));
        break;
      case 'settings_currencies':
        Navigator.of(
          context,
        ).push(_route(AdminCurrenciesScreen(token: widget.token)));
        break;
      case 'settings_locations':
        Navigator.of(
          context,
        ).push(_route(AdminLocationsScreen(token: widget.token)));
        break;
      case 'settings_pdf_fonts':
        Navigator.of(
          context,
        ).push(_route(AdminPdfFontsScreen(token: widget.token)));
        break;
      case 'settings_hrm':
        Navigator.of(
          context,
        ).push(_route(AdminHRMSettingsScreen(token: widget.token)));
        break;
      case 'settings_payroll':
        Navigator.of(
          context,
        ).push(_route(AdminPayrollSettingsScreen(token: widget.token)));
        break;
      case 'settings_employee_id':
        Navigator.of(
          context,
        ).push(_route(AdminEmployeeIDScreen(token: widget.token)));
        break;
      case 'settings_email':
        Navigator.of(
          context,
        ).push(_route(AdminEmailSettingsScreen(token: widget.token)));
        break;
      case 'settings_storage':
        Navigator.of(
          context,
        ).push(_route(AdminStorageSettingsScreen(token: widget.token)));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.title} — coming soon'),
            backgroundColor: AppTheme.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
    }
  }

  PageRouteBuilder _route(Widget page) => PageRouteBuilder(
    pageBuilder: (_, a, __) => page,
    transitionsBuilder: (_, a, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
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
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: Colors.grey[600],
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
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
                          .map(
                            (e) => _SectionGroup(
                              section: e.key,
                              items: e.value,
                              onTap: _onItemTap,
                            ),
                          )
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
            fontWeight: FontWeight.w600,
          ),
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
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Manage your account & preferences',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
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
                color: Colors.white.withOpacity(0.08),
                width: 1.5,
              ),
              image: photo.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(photo),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photo.isEmpty
                ? Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  )
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
  const _SectionGroup({
    required this.section,
    required this.items,
    required this.onTap,
  });

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
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Column(
              children: items
                  .asMap()
                  .entries
                  .map(
                    (e) => _SettingsTile(
                      item: e.value,
                      isFirst: e.key == 0,
                      isLast: e.key == items.length - 1,
                      onTap: onTap,
                    ),
                  )
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

  const _SettingsTile({
    required this.item,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

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
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey[700],
                    size: 20,
                  ),
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
              child: Text(msg, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isSuccess
            ? AppTheme.successColor
            : AppTheme.errorColor,
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
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
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
    return LayoutBuilder(
      builder: (ctx, c) {
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
        return Column(children: [left, const SizedBox(height: 16), right]);
      },
    );
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
                    color: Colors.white.withOpacity(0.1),
                    width: 2,
                  ),
                  image: photo.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(photo),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: photo.isEmpty
                    ? Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      )
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (user?.department != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
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
        .map(
          (w) => w.isEmpty
              ? ''
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
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
        MapEntry(
          'Join Date',
          '${user.joinDate!.day.toString().padLeft(2, '0')} '
              '${_months[user.joinDate!.month - 1]} '
              '${user.joinDate!.year}',
        ),
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
            .map(
              (e) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          e.value.key,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
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
                      color: Colors.white.withOpacity(0.05),
                    ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  static const _months = [
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
      _showSnack(
        result['message'] ?? 'Failed to change password',
        isSuccess: false,
      );
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
              child: Text(msg, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isSuccess
            ? AppTheme.successColor
            : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      // _PasswordHintCard(),
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
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lock_reset_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Update Password',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
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
// class _PasswordHintCard extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final tips = [
//       'Use at least 8 characters',
//       'Mix uppercase & lowercase letters',
//       'Include numbers and special characters',
//       'Avoid common words or patterns',
//     ];

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppTheme.primaryColor.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: AppTheme.primaryColor.withOpacity(0.2),
//           width: 1,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.shield_rounded,
//                 color: AppTheme.primaryColor,
//                 size: 18,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 'Password Tips',
//                 style: TextStyle(
//                   color: AppTheme.primaryColor,
//                   fontWeight: FontWeight.w700,
//                   fontSize: 13,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           ...tips.map(
//             (t) => Padding(
//               padding: const EdgeInsets.only(bottom: 5),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.check_circle_outline_rounded,
//                     color: Colors.grey[600],
//                     size: 14,
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     t,
//                     style: TextStyle(color: Colors.grey[500], fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

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
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
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
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
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

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

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
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
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
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
            fillColor: readOnly ? AppTheme.background : AppTheme.surfaceVariant,
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
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.errorColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ADMIN DASHBOARD SCREEN
// Shows aggregated stats, system health, and recent activity feed.
// ═════════════════════════════════════════════════════════════════════════════
class _AdminDashboardScreen extends StatefulWidget {
  final String? token;
  const _AdminDashboardScreen({this.token});

  @override
  State<_AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<_AdminDashboardScreen> {
  bool _loadingStats = true;
  bool _loadingActivity = true;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _health = {};
  List<dynamic> _activity = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.token == null) {
      setState(() {
        _error = 'No authentication token';
        _loadingStats = false;
        _loadingActivity = false;
      });
      return;
    }
    setState(() {
      _loadingStats = true;
      _loadingActivity = true;
      _error = null;
    });

    final results = await Future.wait([
      AdminService.getDashboardStats(widget.token!),
      AdminService.getRecentActivity(widget.token!, limit: 20),
    ]);

    if (!mounted) return;

    final dash = results[0];
    final act = results[1];

    setState(() {
      _loadingStats = false;
      _loadingActivity = false;
      if (dash['success'] == true) {
        _stats = (dash['data']?['stats'] ?? {}) as Map<String, dynamic>;
        _health = (dash['data']?['systemHealth'] ?? {}) as Map<String, dynamic>;
      } else {
        _error = dash['message'] ?? 'Failed to load dashboard';
      }
      if (act['success'] == true) {
        _activity = (act['data'] ?? []) as List<dynamic>;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _SubScreenHeader(
              title: 'Dashboard Stats',
              subtitle: 'Live metrics across all companies',
              icon: Icons.dashboard_rounded,
              iconColor: AppTheme.primaryColor,
              trailing: IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _load,
              ),
            ),
            Expanded(
              child: _loadingStats
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _AdminErrorWidget(message: _error!, onRetry: _load)
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primaryColor,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          // ── Stats grid ───────────────────────────────
                          _SectionLabel('Overview'),
                          const SizedBox(height: 12),
                          _AdminStatsGrid(stats: _stats),
                          const SizedBox(height: 24),

                          // ── System Health ────────────────────────────
                          _SectionLabel('System Health'),
                          const SizedBox(height: 12),
                          _SystemHealthCard(health: _health),
                          const SizedBox(height: 24),

                          // ── Activity feed ────────────────────────────
                          Row(
                            children: [
                              const Expanded(
                                child: _SectionLabel('Recent Activity'),
                              ),
                              if (_loadingActivity)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_activity.isEmpty && !_loadingActivity)
                            _AdminEmptyState(
                              icon: Icons.history_rounded,
                              message: 'No recent activity',
                            )
                          else
                            ..._activity
                                .map((a) => _ActivityTile(item: a))
                                .toList(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Grid ──────────────────────────────────────────────────────────────
class _AdminStatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _AdminStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatTileData(
        'Companies',
        '${stats['totalCompanies'] ?? 0}',
        Icons.business_rounded,
        const Color(0xFF3B82F6),
      ),
      _StatTileData(
        'HR Staff',
        '${stats['totalHR'] ?? 0}',
        Icons.manage_accounts_rounded,
        const Color(0xFF10B981),
      ),
      _StatTileData(
        'Employees',
        '${stats['totalEmployees'] ?? 0}',
        Icons.people_alt_rounded,
        const Color(0xFF8B5CF6),
      ),
      _StatTileData(
        'Active Today',
        '${stats['activeToday'] ?? 0}',
        Icons.check_circle_rounded,
        AppTheme.successColor,
      ),
      _StatTileData(
        'Pending Leaves',
        '${stats['pendingLeaves'] ?? 0}',
        Icons.event_busy_rounded,
        const Color(0xFFF59E0B),
      ),
      _StatTileData(
        'Active Tasks',
        '${stats['activeTasks'] ?? 0}',
        Icons.task_alt_rounded,
        const Color(0xFF06B6D4),
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.65,
      children: items.map((d) => _StatTile(data: d)).toList(),
    );
  }
}

class _StatTileData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatTileData(this.label, this.value, this.icon, this.color);
}

class _StatTile extends StatelessWidget {
  final _StatTileData data;
  const _StatTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: data.color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                data.label,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── System Health Card ───────────────────────────────────────────────────────
class _SystemHealthCard extends StatelessWidget {
  final Map<String, dynamic> health;
  const _SystemHealthCard({required this.health});

  @override
  Widget build(BuildContext context) {
    final serverLoad = (health['serverLoad'] ?? 0) as num;
    final storage = (health['storage'] ?? 0) as num;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          _HealthRow(
            label: 'Server Load',
            value: serverLoad.toDouble(),
            icon: Icons.memory_rounded,
            color: _barColor(serverLoad.toDouble()),
          ),
          const SizedBox(height: 14),
          _HealthRow(
            label: 'Storage (Cloudinary)',
            value: storage.toDouble(),
            icon: Icons.cloud_rounded,
            color: _barColor(storage.toDouble()),
          ),
        ],
      ),
    );
  }

  Color _barColor(double v) {
    if (v < 50) return AppTheme.successColor;
    if (v < 80) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  const _HealthRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            backgroundColor: AppTheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ─── Activity Tile ────────────────────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final dynamic item;
  const _ActivityTile({required this.item});

  IconData _icon(String type) {
    switch (type) {
      case 'leave':
        return Icons.event_busy_rounded;
      case 'task':
        return Icons.task_alt_rounded;
      case 'expense':
        return Icons.receipt_rounded;
      case 'attendance':
        return Icons.fingerprint_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'leave':
        return const Color(0xFFF59E0B);
      case 'task':
        return const Color(0xFF06B6D4);
      case 'expense':
        return const Color(0xFF8B5CF6);
      case 'attendance':
        return AppTheme.successColor;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = (item['type'] ?? '') as String;
    final action = (item['action'] ?? '') as String;
    final user = (item['user'] ?? 'Unknown') as String;
    final status = (item['status'] ?? '') as String;
    final color = _color(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon(type), color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(status: status),
              const SizedBox(height: 4),
              Text(
                _formatTime(item['time']),
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Status Badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color _color() {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'present':
      case 'completed':
        return AppTheme.successColor;
      case 'pending':
      case 'todo':
        return const Color(0xFFF59E0B);
      case 'rejected':
      case 'cancelled':
        return AppTheme.errorColor;
      case 'in-progress':
        return const Color(0xFF06B6D4);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status.isEmpty) return const SizedBox.shrink();
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ADMIN COMPANIES SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class _AdminCompaniesScreen extends StatefulWidget {
  final String? token;
  const _AdminCompaniesScreen({this.token});

  @override
  State<_AdminCompaniesScreen> createState() => _AdminCompaniesScreenState();
}

class _AdminCompaniesScreenState extends State<_AdminCompaniesScreen> {
  bool _loading = true;
  List<dynamic> _companies = [];
  String? _error;
  final _search = TextEditingController();
  String _q = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.token == null) {
      setState(() {
        _error = 'No auth token';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await AdminService.getAllCompanies(widget.token!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        _companies = (res['data'] ?? []) as List<dynamic>;
      } else {
        _error = res['message'] ?? 'Failed to load companies';
      }
    });
  }

  List<dynamic> get _filtered {
    if (_q.isEmpty) return _companies;
    final q = _q.toLowerCase();
    return _companies.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final industry = (c['industry'] ?? '').toString().toLowerCase();
      final city = (c['city'] ?? '').toString().toLowerCase();
      return name.contains(q) || industry.contains(q) || city.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _SubScreenHeader(
              title: 'Companies',
              subtitle: 'All registered companies (${_companies.length})',
              icon: Icons.business_rounded,
              iconColor: const Color(0xFF3B82F6),
              trailing: IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _load,
              ),
            ),
            if (!_loading && _error == null && _companies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: _AdminSearchBar(
                  controller: _search,
                  hint: 'Search companies…',
                  onChanged: (v) => setState(() => _q = v.trim()),
                  onClear: () => setState(() {
                    _search.clear();
                    _q = '';
                  }),
                  query: _q,
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _AdminErrorWidget(message: _error!, onRetry: _load)
                  : _filtered.isEmpty
                  ? _AdminEmptyState(
                      icon: Icons.business_rounded,
                      message: 'No companies found',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) =>
                            _CompanyCard(company: _filtered[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final dynamic company;
  const _CompanyCard({required this.company});

  @override
  Widget build(BuildContext context) {
    final name = company['name'] ?? 'Unknown';
    final industry = company['industry'] ?? '';
    final city = company['city'] ?? '';
    final country = company['country'] ?? '';
    final empCount = company['employeeCount'] ?? 0;
    final hrCount = company['hrCount'] ?? 0;
    final hr = company['hrManager'];
    final logo = company['logo'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo / initials
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppTheme.cardColor,
                  image: (logo as String).isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(logo),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: logo.isEmpty
                    ? Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      )
                    : null,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        industry,
                        city,
                        country,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 12),
          Row(
            children: [
              _CompanyStatChip(
                icon: Icons.people_alt_rounded,
                label: '$empCount Employees',
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 10),
              _CompanyStatChip(
                icon: Icons.manage_accounts_rounded,
                label: '$hrCount HR',
                color: const Color(0xFF10B981),
              ),
              if (hr != null) ...[
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_pin_rounded,
                      color: Colors.grey[600],
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hr['name'] ?? '',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CompanyStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _CompanyStatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ADMIN EMPLOYEES SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class _AdminEmployeesScreen extends StatefulWidget {
  final String? token;
  const _AdminEmployeesScreen({this.token});

  @override
  State<_AdminEmployeesScreen> createState() => _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends State<_AdminEmployeesScreen> {
  bool _loading = true;
  List<dynamic> _employees = [];
  String? _error;
  final _search = TextEditingController();
  String _q = '';
  String _statusFilter = '';

  static const _statusOptions = ['', 'active', 'inactive'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.token == null) {
      setState(() {
        _error = 'No auth token';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await AdminService.getAllEmployees(
      widget.token!,
      status: _statusFilter.isEmpty ? null : _statusFilter,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        _employees = (res['data'] ?? []) as List<dynamic>;
      } else {
        _error = res['message'] ?? 'Failed to load employees';
      }
    });
  }

  List<dynamic> get _filtered {
    if (_q.isEmpty) return _employees;
    final q = _q.toLowerCase();
    return _employees.where((e) {
      final name = (e['name'] ?? '').toString().toLowerCase();
      final email = (e['email'] ?? '').toString().toLowerCase();
      final dept = (e['department'] ?? '').toString().toLowerCase();
      final empId = (e['employeeId'] ?? '').toString().toLowerCase();
      return name.contains(q) ||
          email.contains(q) ||
          dept.contains(q) ||
          empId.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _SubScreenHeader(
              title: 'All Employees',
              subtitle: 'Cross-company directory (${_employees.length})',
              icon: Icons.people_alt_rounded,
              iconColor: const Color(0xFF8B5CF6),
              trailing: IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _load,
              ),
            ),
            if (!_loading && _error == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    _AdminSearchBar(
                      controller: _search,
                      hint: 'Search by name, ID, department…',
                      onChanged: (v) => setState(() => _q = v.trim()),
                      onClear: () => setState(() {
                        _search.clear();
                        _q = '';
                      }),
                      query: _q,
                    ),
                    const SizedBox(height: 10),
                    // Status filter chips
                    Row(
                      children: _statusOptions.map((s) {
                        final label = s.isEmpty ? 'All' : _tc(s);
                        final selected = _statusFilter == s;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _statusFilter = s);
                              _load();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF8B5CF6)
                                    : AppTheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF8B5CF6)
                                      : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Colors.grey[400],
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _AdminErrorWidget(message: _error!, onRetry: _load)
                  : _filtered.isEmpty
                  ? _AdminEmptyState(
                      icon: Icons.people_alt_rounded,
                      message: 'No employees found',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) =>
                            _EmployeeListTile(employee: _filtered[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _tc(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

class _EmployeeListTile extends StatelessWidget {
  final dynamic employee;
  const _EmployeeListTile({required this.employee});

  @override
  Widget build(BuildContext context) {
    final name = (employee['name'] ?? 'Unknown') as String;
    final email = (employee['email'] ?? '') as String;
    final dept = (employee['department'] ?? '') as String;
    final empId = (employee['employeeId'] ?? '') as String;
    final status = (employee['status'] ?? '') as String;
    final company = (employee['company']?['name'] ?? '') as String;
    final photo = employee['profileImage'] ?? employee['profilePhoto'] ?? '';
    final photoUrl = photo is Map ? (photo['url'] ?? '') : photo.toString();
    final initials = name
        .split(' ')
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.cardColor,
              image: (photoUrl as String).isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (photoUrl).isEmpty
                ? Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : null,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [dept, company].where((s) => s.isNotEmpty).join(' · '),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(status: status),
              const SizedBox(height: 4),
              Text(
                empId,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ADMIN LEAVES SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class _AdminLeavesScreen extends StatefulWidget {
  final String? token;
  const _AdminLeavesScreen({this.token});

  @override
  State<_AdminLeavesScreen> createState() => _AdminLeavesScreenState();
}

class _AdminLeavesScreenState extends State<_AdminLeavesScreen> {
  bool _loading = true;
  List<dynamic> _leaves = [];
  String? _error;
  final _search = TextEditingController();
  String _q = '';
  String _statusFilter = '';

  static const _statusOptions = [
    '',
    'pending',
    'approved',
    'rejected',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.token == null) {
      setState(() {
        _error = 'No auth token';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await AdminService.getAllLeaves(
      widget.token!,
      status: _statusFilter.isEmpty ? null : _statusFilter,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        _leaves = (res['data'] ?? []) as List<dynamic>;
      } else {
        _error = res['message'] ?? 'Failed to load leaves';
      }
    });
  }

  List<dynamic> get _filtered {
    if (_q.isEmpty) return _leaves;
    final q = _q.toLowerCase();
    return _leaves.where((l) {
      final name = (l['user']?['name'] ?? '').toString().toLowerCase();
      final type = (l['leaveType'] ?? '').toString().toLowerCase();
      return name.contains(q) || type.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _SubScreenHeader(
              title: 'Leave Overview',
              subtitle: 'All leave requests (${_leaves.length})',
              icon: Icons.event_busy_rounded,
              iconColor: const Color(0xFFF59E0B),
              trailing: IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _load,
              ),
            ),
            if (!_loading && _error == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    _AdminSearchBar(
                      controller: _search,
                      hint: 'Search by employee name or type…',
                      onChanged: (v) => setState(() => _q = v.trim()),
                      onClear: () => setState(() {
                        _search.clear();
                        _q = '';
                      }),
                      query: _q,
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _statusOptions.map((s) {
                          final label = s.isEmpty ? 'All' : _tc(s);
                          final selected = _statusFilter == s;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _statusFilter = s);
                                _load();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFF59E0B)
                                      : AppTheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFFF59E0B)
                                        : Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.grey[400],
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _AdminErrorWidget(message: _error!, onRetry: _load)
                  : _filtered.isEmpty
                  ? _AdminEmptyState(
                      icon: Icons.event_busy_rounded,
                      message: 'No leave requests found',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _LeaveCard(leave: _filtered[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _tc(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

class _LeaveCard extends StatelessWidget {
  final dynamic leave;
  const _LeaveCard({required this.leave});

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
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
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = leave['user'];
    final name = (user?['name'] ?? 'Unknown') as String;
    final empId = (user?['employeeId'] ?? '') as String;
    final company = (leave['company']?['name'] ?? '') as String;
    final type = (leave['leaveType'] ?? '') as String;
    final days = leave['days'] ?? 0;
    final status = (leave['status'] ?? '') as String;
    final start = _formatDate(leave['startDate']);
    final end = _formatDate(leave['endDate']);
    final reason = (leave['reason'] ?? '') as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [empId, company].where((s) => s.isNotEmpty).join(' · '),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.event_rounded,
                color: const Color(0xFFF59E0B),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '$start → $end',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$days day${days == 1 ? '' : 's'} · ${_tc(type)}',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reason,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _tc(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

// ═════════════════════════════════════════════════════════════════════════════
// ADMIN TASKS SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class _AdminTasksScreen extends StatefulWidget {
  final String? token;
  const _AdminTasksScreen({this.token});

  @override
  State<_AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends State<_AdminTasksScreen> {
  bool _loading = true;
  List<dynamic> _tasks = [];
  String? _error;
  final _search = TextEditingController();
  String _q = '';
  String _statusFilter = '';

  static const _statusOptions = [
    '',
    'todo',
    'in-progress',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.token == null) {
      setState(() {
        _error = 'No auth token';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await AdminService.getAllTasks(
      widget.token!,
      status: _statusFilter.isEmpty ? null : _statusFilter,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        _tasks = (res['data'] ?? []) as List<dynamic>;
      } else {
        _error = res['message'] ?? 'Failed to load tasks';
      }
    });
  }

  List<dynamic> get _filtered {
    if (_q.isEmpty) return _tasks;
    final q = _q.toLowerCase();
    return _tasks.where((t) {
      final title = (t['title'] ?? '').toString().toLowerCase();
      final desc = (t['description'] ?? '').toString().toLowerCase();
      final assignee = (t['assignedTo']?['name'] ?? '')
          .toString()
          .toLowerCase();
      return title.contains(q) || desc.contains(q) || assignee.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _SubScreenHeader(
              title: 'Task Overview',
              subtitle: 'All tasks across companies (${_tasks.length})',
              icon: Icons.task_alt_rounded,
              iconColor: const Color(0xFF06B6D4),
              trailing: IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _load,
              ),
            ),
            if (!_loading && _error == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    _AdminSearchBar(
                      controller: _search,
                      hint: 'Search by title or assignee…',
                      onChanged: (v) => setState(() => _q = v.trim()),
                      onClear: () => setState(() {
                        _search.clear();
                        _q = '';
                      }),
                      query: _q,
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _statusOptions.map((s) {
                          final label = s.isEmpty ? 'All' : _tc(s);
                          final selected = _statusFilter == s;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _statusFilter = s);
                                _load();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF06B6D4)
                                      : AppTheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF06B6D4)
                                        : Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.grey[400],
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _AdminErrorWidget(message: _error!, onRetry: _load)
                  : _filtered.isEmpty
                  ? _AdminEmptyState(
                      icon: Icons.task_alt_rounded,
                      message: 'No tasks found',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _TaskCard(task: _filtered[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _tc(String s) {
    if (s.isEmpty) return s;
    return s
        .split('-')
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

class _TaskCard extends StatelessWidget {
  final dynamic task;
  const _TaskCard({required this.task});

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppTheme.errorColor;
      case 'medium':
        return AppTheme.warningColor;
      case 'low':
        return AppTheme.successColor;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
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
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (task['title'] ?? 'Untitled') as String;
    final desc = (task['description'] ?? '') as String;
    final status = (task['status'] ?? '') as String;
    final priority = (task['priority'] ?? '') as String;
    final assignee = (task['assignedTo']?['name'] ?? '') as String;
    final company = (task['company']?['name'] ?? '') as String;
    final dueDate = _formatDate(task['dueDate']);
    final progress = ((task['progress'] ?? 0) as num).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: status),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          // Progress bar
          if (progress > 0) ...[
            Row(
              children: [
                Text(
                  '$progress%',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: AppTheme.surfaceVariant,
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF06B6D4),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              if (priority.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _priorityColor(priority).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _tc(priority),
                    style: TextStyle(
                      color: _priorityColor(priority),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (assignee.isNotEmpty) ...[
                Icon(Icons.person_outlined, color: Colors.grey[600], size: 13),
                const SizedBox(width: 4),
                Text(
                  assignee,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              if (company.isNotEmpty)
                Text(
                  company,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              if (dueDate != '—') ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.grey[600],
                  size: 12,
                ),
                const SizedBox(width: 3),
                Text(
                  dueDate,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _tc(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED ADMIN UTILITY WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

/// Reusable search bar for admin list screens
class _AdminSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String query;

  const _AdminSearchBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey[600],
            size: 18,
          ),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

/// Error state widget with retry button
class _AdminErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _AdminErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: AppTheme.errorColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Try Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state widget
class _AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _AdminEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey[700], size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
