import 'package:flutter/material.dart';
import 'package:hrms_app/services/settings_service.dart';
import 'package:hrms_app/theme/app_theme.dart';
import 'shared.dart';

class AdminRolesPermissionsScreen extends StatefulWidget {
  final String? token;
  const AdminRolesPermissionsScreen({super.key, this.token});

  @override
  State<AdminRolesPermissionsScreen> createState() =>
      _AdminRolesPermissionsScreenState();
}

class _AdminRolesPermissionsScreenState
    extends State<AdminRolesPermissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  bool _loadingRoles = true;
  bool _loadingPerms = false;
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _modules = [];
  Map<String, dynamic>? _selectedRole;
  // permissions map: moduleId → {view, create, edit, delete}
  Map<String, Map<String, bool>> _permissions = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadRoles();
    _loadModules();
  }

  Future<void> _loadRoles() async {
    setState(() => _loadingRoles = true);
    try {
      final res = await SettingsService.getRoles(widget.token ?? '');
      final list = res['data'] ?? res['roles'] ?? res;
      if (list is List) {
        setState(() => _roles = list.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingRoles = false);
  }

  Future<void> _loadModules() async {
    try {
      final res = await SettingsService.getPermissionModules(
        widget.token ?? '',
      );
      final list = res['data'] ?? res['modules'] ?? res;
      if (list is List) {
        setState(() => _modules = list.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  Future<void> _selectRole(Map<String, dynamic> role) async {
    setState(() {
      _selectedRole = role;
      _loadingPerms = true;
      _permissions = {};
    });
    _tabCtrl.animateTo(1);
    try {
      final res = await SettingsService.getRolePermissions(
        widget.token ?? '',
        role['_id'],
      );
      final list = res['data'] ?? res['permissions'] ?? [];
      final Map<String, Map<String, bool>> map = {};
      for (final p in (list as List)) {
        final moduleId = (p['module'] is Map ? p['module']['_id'] : p['module'])
            ?.toString();
        if (moduleId != null) {
          map[moduleId] = {
            'view': p['view'] ?? p['read'] ?? false,
            'create': p['create'] ?? false,
            'edit': p['edit'] ?? p['update'] ?? false,
            'delete': p['delete'] ?? false,
          };
        }
      }
      // fill missing modules
      for (final m in _modules) {
        final id = m['_id'].toString();
        map.putIfAbsent(
          id,
          () => {
            'view': false,
            'create': false,
            'edit': false,
            'delete': false,
          },
        );
      }
      if (mounted) setState(() => _permissions = map);
    } catch (_) {}
    if (mounted) setState(() => _loadingPerms = false);
  }

  Future<void> _savePermissions() async {
    if (_selectedRole == null) return;
    final list = _permissions.entries
        .map(
          (e) => {
            'module': e.key,
            'view': e.value['view'] ?? false,
            'create': e.value['create'] ?? false,
            'edit': e.value['edit'] ?? false,
            'delete': e.value['delete'] ?? false,
          },
        )
        .toList();
    try {
      await SettingsService.assignPermissions(
        widget.token ?? '',
        _selectedRole!['_id'],
        list,
      );
      if (mounted)
        showAdminSnack(
          context,
          'Permissions saved for ${_selectedRole!['name']}',
        );
    } catch (_) {
      if (mounted)
        showAdminSnack(context, 'Failed to save permissions', error: true);
    }
  }

  void _openCreateRoleDialog({Map<String, dynamic>? editing}) {
    final nameCtrl = TextEditingController(text: editing?['name'] ?? '');
    final descCtrl = TextEditingController(text: editing?['description'] ?? '');
    bool saving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            editing == null ? 'Create Role' : 'Edit Role',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DlgField(
                label: 'Role Name',
                ctrl: nameCtrl,
                hint: 'e.g. Manager',
              ),
              const SizedBox(height: 12),
              _DlgField(
                label: 'Description',
                ctrl: descCtrl,
                hint: 'Optional description',
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[500])),
            ),
            GestureDetector(
              onTap: saving
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      setDlg(() => saving = true);
                      try {
                        final data = {
                          'name': nameCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                        };
                        if (editing != null) {
                          await SettingsService.updateRole(
                            widget.token ?? '',
                            editing['_id'],
                            data,
                          );
                        } else {
                          await SettingsService.createRole(
                            widget.token ?? '',
                            data,
                          );
                        }
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        await _loadRoles();
                        if (mounted)
                          showAdminSnack(
                            context,
                            editing == null ? 'Role created' : 'Role updated',
                          );
                      } catch (_) {
                        if (mounted)
                          showAdminSnack(
                            context,
                            'Operation failed',
                            error: true,
                          );
                      } finally {
                        if (ctx.mounted) setDlg(() => saving = false);
                      }
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        editing == null ? 'Create' : 'Save',
                        style: const TextStyle(
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

  void _confirmDeleteRole(Map<String, dynamic> role) {
    final confirmCtrl = TextEditingController();
    bool deleting = false;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Role',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Type "${role['name']}" to confirm deletion.',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 10),
              _DlgField(
                label: 'Role name',
                ctrl: confirmCtrl,
                hint: role['name'] ?? '',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[500])),
            ),
            GestureDetector(
              onTap: deleting
                  ? null
                  : () async {
                      if (confirmCtrl.text.trim() != role['name']) return;
                      setDlg(() => deleting = true);
                      try {
                        await SettingsService.deleteRole(
                          widget.token ?? '',
                          role['_id'],
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        await _loadRoles();
                        if (mounted) showAdminSnack(context, 'Role deleted');
                        if (_selectedRole?['_id'] == role['_id']) {
                          setState(() {
                            _selectedRole = null;
                            _permissions = {};
                          });
                        }
                      } catch (_) {
                        if (mounted)
                          showAdminSnack(context, 'Delete failed', error: true);
                      } finally {
                        if (ctx.mounted) setDlg(() => deleting = false);
                      }
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFef4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  deleting ? '…' : 'Delete',
                  style: const TextStyle(
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
    _tabCtrl.dispose();
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
              title: 'Roles & Permissions',
              subtitle: 'Manage roles and module access',
              icon: Icons.shield_rounded,
              iconColor: const Color(0xFFF59E0B),
              trailing: _selectedRole != null && _tabCtrl.index == 1
                  ? AdminSaveButton(saving: false, onTap: _savePermissions)
                  : null,
            ),
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabCtrl,
                onTap: (i) => setState(() {}),
                indicator: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Roles'),
                  Tab(text: 'Permissions'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [_rolesTab(), _permissionsTab()],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabCtrl.index == 0
          ? FloatingActionButton.small(
              backgroundColor: AppTheme.primaryColor,
              onPressed: _openCreateRoleDialog,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _rolesTab() {
    if (_loadingRoles) return adminLoader();
    if (_roles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, color: Colors.grey[700], size: 40),
            const SizedBox(height: 12),
            Text(
              'No roles yet.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _openCreateRoleDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Create Role',
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
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _roles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final role = _roles[i];
        final isSelected = _selectedRole?['_id'] == role['_id'];
        return GestureDetector(
          onTap: () => _selectRole(role),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFF59E0B).withOpacity(0.1)
                  : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFF59E0B).withOpacity(0.4)
                    : Colors.white.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Color(0xFFF59E0B),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role['name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if ((role['description'] ?? '').toString().isNotEmpty)
                        Text(
                          role['description'],
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IconBtn(
                      icon: Icons.edit_rounded,
                      color: const Color(0xFF3B82F6),
                      onTap: () => _openCreateRoleDialog(editing: role),
                    ),
                    const SizedBox(width: 6),
                    _IconBtn(
                      icon: Icons.delete_rounded,
                      color: const Color(0xFFef4444),
                      onTap: () => _confirmDeleteRole(role),
                    ),
                    const SizedBox(width: 6),
                    _IconBtn(
                      icon: Icons.chevron_right_rounded,
                      color: const Color(0xFFF59E0B),
                      onTap: () => _selectRole(role),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _permissionsTab() {
    if (_selectedRole == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded, color: Colors.grey[700], size: 40),
            const SizedBox(height: 12),
            Text(
              'Select a role to manage its permissions',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    if (_loadingPerms) return adminLoader();
    if (_modules.isEmpty) {
      return Center(
        child: Text(
          'No modules found.',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      );
    }

    const actions = ['view', 'create', 'edit', 'delete'];
    const actionColors = {
      'view': Color(0xFF22C55E),
      'create': Color(0xFF3B82F6),
      'edit': Color(0xFFF59E0B),
      'delete': Color(0xFFef4444),
    };

    return Column(
      children: [
        // Header banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_rounded,
                color: Color(0xFFF59E0B),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedRole!['name'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '${_modules.length} modules',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
        ),
        // Action header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Module',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...actions.map(
                (a) => SizedBox(
                  width: 56,
                  child: Text(
                    a[0].toUpperCase() + a.substring(1),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: actionColors[a],
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            itemCount: _modules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (_, i) {
              final module = _modules[i];
              final mid = module['_id'].toString();
              final perms =
                  _permissions[mid] ??
                  {
                    'view': false,
                    'create': false,
                    'edit': false,
                    'delete': false,
                  };
              return Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        module['name']?.toString() ?? mid,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...actions.map(
                      (a) => SizedBox(
                        width: 56,
                        child: Center(
                          child: Transform.scale(
                            scale: 0.85,
                            child: Checkbox(
                              value: perms[a] ?? false,
                              activeColor: actionColors[a],
                              checkColor: Colors.white,
                              side: BorderSide(
                                color: actionColors[a]!.withOpacity(0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (v) {
                                setState(() {
                                  _permissions[mid] = {...perms, a: v ?? false};
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Save button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: AdminSaveButton(saving: false, onTap: _savePermissions),
          ),
        ),
      ],
    );
  }
}

class _DlgField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  const _DlgField({
    required this.label,
    required this.ctrl,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
            filled: true,
            fillColor: AppTheme.background,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
