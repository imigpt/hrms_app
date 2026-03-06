import 'package:flutter/material.dart';
import 'package:hrms_app/services/settings_service.dart';
import 'package:hrms_app/theme/app_theme.dart';
import 'shared.dart';

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
  String _symbol = '₹';
  String _position = 'before';

  static const _currencies = [
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'AED', 'symbol': 'AED', 'name': 'UAE Dirham'},
    {'code': 'SAR', 'symbol': 'SAR', 'name': 'Saudi Riyal'},
    {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'CNY', 'symbol': '¥', 'name': 'Chinese Yuan'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
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
          _symbol = d['currencySymbol'] ?? '₹';
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
        'currencySymbol': _symbol,
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
                            AdminDropdown(
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
                                  _symbol = found['symbol']!;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            AdminRow2(
                              left: _SymbolPreview(
                                currency: _currency,
                                symbol: _symbol,
                              ),
                              right: AdminDropdown(
                                label: 'Symbol Position',
                                value: _position,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'before',
                                    child: Text('Before Amount'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'after',
                                    child: Text('After Amount'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _position = v!),
                              ),
                            ),
                          ],
                        ),
                        _PreviewCard(symbol: _symbol, position: _position),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SymbolPreview extends StatelessWidget {
  final String currency;
  final String symbol;
  const _SymbolPreview({required this.currency, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionLabel('Symbol', topPad: false),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Row(
            children: [
              Text(
                symbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currency,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String symbol;
  final String position;
  const _PreviewCard({required this.symbol, required this.position});

  @override
  Widget build(BuildContext context) {
    final formatted = position == 'before'
        ? '$symbol 1,234.56'
        : '1,234.56 $symbol';
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
          child: Row(
            children: [
              const Icon(
                Icons.visibility_rounded,
                color: Color(0xFFEAB308),
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'Sample: $formatted',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
