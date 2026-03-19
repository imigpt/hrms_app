import 'package:flutter/material.dart';
import 'package:hrms_app/shared/services/core/settings_service.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';
import '../hrm_settings/shared.dart';

class AdminCurrenciesScreen extends StatefulWidget {
  final String? token;
  const AdminCurrenciesScreen({super.key, this.token});

  @override
  State<AdminCurrenciesScreen> createState() => _AdminCurrenciesScreenState();
}

class _AdminCurrenciesScreenState extends State<AdminCurrenciesScreen> {
  bool _loading = true;
  bool _saving = false;

  String _currency = 'INR';
  final _symbolCtrl = TextEditingController(text: '₹');
  String _position = 'before';

  static const _currencies = [
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'USD', 'symbol': r'$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'AED', 'symbol': 'د.إ', 'name': 'UAE Dirham'},
    {'code': 'SAR', 'symbol': '﷼', 'name': 'Saudi Riyal'},
    {'code': 'CAD', 'symbol': r'C$', 'name': 'Canadian Dollar'},
    {'code': 'AUD', 'symbol': r'A$', 'name': 'Australian Dollar'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'CNY', 'symbol': '¥', 'name': 'Chinese Yuan'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _symbolCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await SettingsService.getLocalizationSettings(
        widget.token ?? '',
      );
      final d = res['data'];
      if (d != null) {
        setState(() {
          _currency = d['currency'] ?? 'INR';
          _symbolCtrl.text = d['currencySymbol'] ?? '₹';
          _position = d['currencyPosition'] ?? 'before';
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SettingsService.updateLocalizationSettings(widget.token ?? '', {
        'currency': _currency,
        'currencySymbol': _symbolCtrl.text,
        'currencyPosition': _position,
      });
      if (mounted) showAdminSnack(context, 'Currency settings updated');
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
              title: 'Currencies',
              subtitle: 'Configure the currency used across the system',
              icon: Icons.monetization_on_rounded,
              iconColor: const Color(0xFFEAB308),
              trailing: AdminSaveButton(saving: _saving, onTap: _save),
            ),
            Expanded(
              child: _loading
                  ? adminLoader()
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      children: [
                        AdminCard(
                          title: 'Currency Configuration',
                          children: [
                            AdminRow2(
                              left: AdminDropdown(
                                label: 'Currency',
                                value: _currency,
                                items: _currencies
                                    .map(
                                      (c) => DropdownMenuItem<String>(
                                        value: c['code'],
                                        child: Text(
                                          '${c['symbol']}  ${c['name']} (${c['code']})',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  final found = _currencies.firstWhere(
                                    (c) => c['code'] == v,
                                    orElse: () => _currencies.first,
                                  );
                                  setState(() {
                                    _currency = v;
                                    _symbolCtrl.text = found['symbol']!;
                                  });
                                },
                              ),
                              right: AdminDropdown(
                                label: 'Symbol Position',
                                value: _position,
                                items: [
                                  DropdownMenuItem(
                                    value: 'before',
                                    child: Text(
                                      'Before (${_symbolCtrl.text}100)',
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'after',
                                    child: Text(
                                      'After (100${_symbolCtrl.text})',
                                    ),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _position = v!),
                              ),
                            ),
                            const SizedBox(height: 14),
                            AdminTextField(
                              label: 'Currency Symbol',
                              controller: _symbolCtrl,
                              hint: '₹',
                            ),
                          ],
                        ),
                        _PreviewCard(
                          symbolCtrl: _symbolCtrl,
                          position: _position,
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

class _PreviewCard extends StatefulWidget {
  final TextEditingController symbolCtrl;
  final String position;
  const _PreviewCard({required this.symbolCtrl, required this.position});

  @override
  State<_PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<_PreviewCard> {
  @override
  void initState() {
    super.initState();
    widget.symbolCtrl.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    widget.symbolCtrl.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sym = widget.symbolCtrl.text;
    final formatted = widget.position == 'before'
        ? '${sym}1,00,000'
        : '1,00,000$sym';
    return AdminCard(
      title: 'Preview',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEAB308).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEAB308).withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preview',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                formatted,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
