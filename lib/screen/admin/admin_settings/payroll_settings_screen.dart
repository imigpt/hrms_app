import 'package:flutter/material.dart';
import 'package:hrms_app/services/settings_service.dart';
import 'package:hrms_app/theme/app_theme.dart';
import 'shared.dart';

class AdminPayrollSettingsScreen extends StatefulWidget {
  final String? token;
  const AdminPayrollSettingsScreen({super.key, this.token});

  @override
  State<AdminPayrollSettingsScreen> createState() =>
      _AdminPayrollSettingsScreenState();
}

class _AdminPayrollSettingsScreenState
    extends State<AdminPayrollSettingsScreen> {
  bool _loading = true;
  bool _saving = false;

  String _cycle = 'monthly';
  int _payDay = 1;
  double _overtimeRate = 1.5;
  String _taxCalc = 'auto';
  double _pfPercent = 12.0;
  double _esiPercent = 0.75;
  bool _professionalTax = true;
  bool _autoPayslip = true;
  String _payslipFormat = 'pdf';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res =
          await SettingsService.getPayrollSettings(widget.token ?? '');
      final d = res['data'];
      if (d != null) {
        setState(() {
          _cycle = d['payrollCycle'] ?? 'monthly';
          _payDay = (d['payDay'] ?? 1) as int;
          _overtimeRate =
              (d['overtimeRate'] ?? 1.5).toDouble();
          _taxCalc = d['taxCalculation'] ?? 'auto';
          _pfPercent =
              (d['providentFundPercentage'] ?? 12).toDouble();
          _esiPercent =
              (d['esiPercentage'] ?? 0.75).toDouble();
          _professionalTax = d['professionalTax'] ?? true;
          _autoPayslip = d['autoGeneratePayslip'] ?? true;
          _payslipFormat = d['payslipFormat'] ?? 'pdf';
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SettingsService.updatePayrollSettings(widget.token ?? '', {
        'payrollCycle': _cycle,
        'payDay': _payDay,
        'overtimeRate': _overtimeRate,
        'taxCalculation': _taxCalc,
        'providentFundPercentage': _pfPercent,
        'esiPercentage': _esiPercent,
        'professionalTax': _professionalTax,
        'autoGeneratePayslip': _autoPayslip,
        'payslipFormat': _payslipFormat,
      });
      if (mounted) showAdminSnack(context, 'Payroll settings updated');
    } catch (_) {
      if (mounted) showAdminSnack(context, 'Failed to update', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _numField(String label, num value, ValueChanged<num> onChanged,
      {bool isDouble = false}) {
    final ctrl =
        TextEditingController(text: isDouble ? value.toString() : value.toInt().toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionLabel(label, topPad: false),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) {
            final parsed = isDouble ? double.tryParse(v) : int.tryParse(v);
            if (parsed != null) onChanged(parsed);
          },
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.07)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.07)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            AdminSubScreenHeader(
              title: 'Payroll Settings',
              subtitle: 'Payroll cycle, deductions and tax rules',
              icon: Icons.account_balance_wallet_rounded,
              iconColor: const Color(0xFF3B82F6),
              trailing: AdminSaveButton(saving: _saving, onTap: _save),
            ),
            Expanded(
              child: _loading
                  ? adminLoader()
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      children: [
                        AdminCard(
                          title: 'Payroll Cycle',
                          children: [
                            AdminRow2(
                              left: AdminDropdown(
                                label: 'Payroll Cycle',
                                value: _cycle,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'weekly',
                                      child: Text('Weekly')),
                                  DropdownMenuItem(
                                      value: 'biweekly',
                                      child: Text('Bi-Weekly')),
                                  DropdownMenuItem(
                                      value: 'monthly',
                                      child: Text('Monthly')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _cycle = v!),
                              ),
                              right: _numField(
                                  'Pay Day (1-31)', _payDay,
                                  (v) => setState(
                                      () => _payDay = v.toInt().clamp(1, 31))),
                            ),
                          ],
                        ),
                        AdminCard(
                          title: 'Tax & Deductions',
                          children: [
                            AdminRow2(
                              left: AdminDropdown(
                                label: 'Tax Calculation',
                                value: _taxCalc,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'auto',
                                      child: Text('Automatic')),
                                  DropdownMenuItem(
                                      value: 'manual',
                                      child: Text('Manual')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _taxCalc = v!),
                              ),
                              right: _numField(
                                  'Overtime Rate (x)',
                                  _overtimeRate,
                                  (v) => setState(
                                      () => _overtimeRate = v.toDouble()),
                                  isDouble: true),
                            ),
                            const SizedBox(height: 14),
                            AdminRow2(
                              left: _numField(
                                  'PF Percentage (%)',
                                  _pfPercent,
                                  (v) => setState(
                                      () => _pfPercent = v.toDouble()),
                                  isDouble: true),
                              right: _numField(
                                  'ESI Percentage (%)',
                                  _esiPercent,
                                  (v) => setState(
                                      () => _esiPercent = v.toDouble()),
                                  isDouble: true),
                            ),
                            const SizedBox(height: 14),
                            AdminToggleRow(
                              label: 'Professional Tax',
                              subtitle:
                                  'Automatically calculate professional tax',
                              value: _professionalTax,
                              onChanged: (v) =>
                                  setState(() => _professionalTax = v),
                            ),
                          ],
                        ),
                        AdminCard(
                          title: 'Payslip',
                          children: [
                            AdminRow2(
                              left: AdminToggleRow(
                                label: 'Auto-generate Payslip',
                                value: _autoPayslip,
                                onChanged: (v) =>
                                    setState(() => _autoPayslip = v),
                              ),
                              right: AdminDropdown(
                                label: 'Payslip Format',
                                value: _payslipFormat,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'pdf', child: Text('PDF')),
                                  DropdownMenuItem(
                                      value: 'excel', child: Text('Excel')),
                                  DropdownMenuItem(
                                      value: 'html', child: Text('HTML')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _payslipFormat = v!),
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
