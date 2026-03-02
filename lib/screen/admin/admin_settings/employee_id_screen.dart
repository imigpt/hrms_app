import 'package:flutter/material.dart';
import 'package:hrms_app/services/settings_service.dart';
import 'package:hrms_app/theme/app_theme.dart';
import 'shared.dart';

class AdminEmployeeIDScreen extends StatefulWidget {
  final String? token;
  const AdminEmployeeIDScreen({super.key, this.token});

  @override
  State<AdminEmployeeIDScreen> createState() => _AdminEmployeeIDScreenState();
}

class _AdminEmployeeIDScreenState extends State<AdminEmployeeIDScreen> {
  bool _loading = true;
  bool _saving = false;

  final _prefixCtrl = TextEditingController(text: 'EMP');
  int _padding = 3;
  final _separatorCtrl = TextEditingController();
  bool _includeYear = false;
  String _formatRule = 'auto';
  bool _manualOverride = true;

  @override
  void initState() {
    super.initState();
    _load();
    _prefixCtrl.addListener(() => setState(() {}));
    _separatorCtrl.addListener(() => setState(() {}));
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res =
          await SettingsService.getEmployeeIDConfig(widget.token ?? '');
      final d = res['data'];
      if (d != null) {
        setState(() {
          _prefixCtrl.text = d['prefix'] ?? 'EMP';
          _padding = (d['padding'] ?? 3) as int;
          _separatorCtrl.text = d['separator'] ?? '';
          _includeYear = d['includeYear'] ?? false;
          _formatRule = d['formatRule'] ?? 'auto';
          _manualOverride = d['manualOverrideAllowed'] ?? true;

        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _computePreview() {
    final prefix = _prefixCtrl.text;
    final sep = _separatorCtrl.text;
    final num = '1'.padLeft(_padding, '0');
    final year =
        _includeYear ? '${sep}${DateTime.now().year}' : '';
    return '$prefix$sep$num$year';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SettingsService.updateEmployeeIDConfig(widget.token ?? '', {
        'prefix': _prefixCtrl.text,
        'padding': _padding,
        'separator': _separatorCtrl.text,
        'includeYear': _includeYear,
        'formatRule': _formatRule,
        'manualOverrideAllowed': _manualOverride,
      });
      if (mounted) showAdminSnack(context, 'Employee ID config updated');
    } catch (_) {
      if (mounted) showAdminSnack(context, 'Failed to update', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _prefixCtrl.dispose();
    _separatorCtrl.dispose();
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
              title: 'Employee Custom Fields',
              subtitle: 'Define employee ID format and custom fields',
              icon: Icons.manage_accounts_rounded,
              iconColor: const Color(0xFF10B981),
              trailing: AdminSaveButton(saving: _saving, onTap: _save),
            ),
            Expanded(
              child: _loading
                  ? adminLoader()
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      children: [
                        AdminCard(
                          title: 'ID Format Configuration',
                          children: [
                            AdminRow2(
                              left: AdminTextField(
                                label: 'Prefix',
                                controller: _prefixCtrl,
                                hint: 'EMP',
                              ),
                              right: AdminTextField(
                                label: 'Separator',
                                controller: _separatorCtrl,
                                hint: '- or / or blank',
                              ),
                            ),
                            const SizedBox(height: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AdminSectionLabel('Number Padding (digits)',
                                    topPad: false),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        value: _padding.toDouble(),
                                        min: 1,
                                        max: 8,
                                        divisions: 7,
                                        activeColor: AppTheme.primaryColor,
                                        inactiveColor: AppTheme.cardColor,
                                        onChanged: (v) => setState(
                                            () => _padding = v.toInt()),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 32,
                                      child: Text(
                                        '$_padding',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            AdminRow2(
                              left: AdminDropdown(
                                label: 'Format Rule',
                                value: _formatRule,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'auto', child: Text('Auto')),
                                  DropdownMenuItem(
                                      value: 'manual', child: Text('Manual')),
                                  DropdownMenuItem(
                                      value: 'custom', child: Text('Custom')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _formatRule = v!),
                              ),
                              right: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const AdminSectionLabel('Include Year',
                                      topPad: false),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _SmallBtn('Yes', _includeYear,
                                          () => setState(() {
                                                _includeYear = true;
                                              })),
                                      const SizedBox(width: 8),
                                      _SmallBtn('No', !_includeYear,
                                          () => setState(() {
                                                _includeYear = false;
                                              })),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            AdminToggleRow(
                              label: 'Allow Manual Override',
                              subtitle:
                                  'Admins can manually set employee IDs',
                              value: _manualOverride,
                              onChanged: (v) =>
                                  setState(() => _manualOverride = v),
                            ),
                          ],
                        ),
                        AdminCard(
                          title: 'Preview',
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFF10B981)
                                        .withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.badge_rounded,
                                      color: Color(0xFF10B981), size: 20),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _computePreview(),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 2),
                                      ),
                                      Text(
                                        'Example employee ID',
                                        style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
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

class _SmallBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SmallBtn(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF10B981)
              : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active
                  ? const Color(0xFF10B981)
                  : Colors.white.withOpacity(0.1)),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// end of file
