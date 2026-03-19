import 'package:flutter/material.dart';
import 'package:hrms_app/shared/services/core/settings_service.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';
import 'shared.dart';

class AdminWorkStatusScreen extends StatefulWidget {
  final String? token;
  const AdminWorkStatusScreen({super.key, this.token});

  @override
  State<AdminWorkStatusScreen> createState() => _AdminWorkStatusScreenState();
}

class _AdminWorkStatusScreenState extends State<AdminWorkStatusScreen> {
  bool _loading = true;
  bool _saving = false;
  List<String> _statuses = [
    'active',
    'on-leave',
    'inactive',
    'probation',
    'notice-period',
    'terminated',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await SettingsService.getWorkStatusSettings(
        widget.token ?? '',
      );
      final data = res['data'];
      if (data is List) {
        setState(() => _statuses = List<String>.from(data));
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SettingsService.updateWorkStatusSettings(
        widget.token ?? '',
        _statuses,
      );
      if (mounted) showAdminSnack(context, 'Work statuses updated');
    } catch (_) {
      if (mounted) showAdminSnack(context, 'Failed to update', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            AdminSubScreenHeader(
              title: 'Employee Work Status',
              subtitle: 'Configure available work statuses for employees',
              icon: Icons.verified_user_rounded,
              iconColor: const Color(0xFF22C55E),
              trailing: AdminSaveButton(saving: _saving, onTap: _save),
            ),
            Expanded(
              child: _loading
                  ? adminLoader()
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      children: [
                        AdminCard(
                          title: 'Work Statuses',
                          children: [
                            AdminChipInput(
                              label: 'Add New Status',
                              hint: 'e.g. remote, on-site...',
                              chips: _statuses,
                              onChanged: (v) => setState(() => _statuses = v),
                            ),
                          ],
                        ),
                        AdminCard(
                          title: 'Current Statuses (${_statuses.length})',
                          children: [
                            if (_statuses.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Center(
                                  child: Text(
                                    'No statuses configured.\nUse the input above to add.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...List.generate(_statuses.length, (i) {
                                final s = _statuses[i];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.06),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF22C55E),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          s[0].toUpperCase() + s.substring(1),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _statuses.removeAt(i),
                                        ),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.grey[600],
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
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
