import 'package:flutter/material.dart';
import 'package:hrms_app/services/settings_service.dart';
import 'package:hrms_app/theme/app_theme.dart';
import 'shared.dart';

class AdminTranslationsScreen extends StatefulWidget {
  final String? token;
  const AdminTranslationsScreen({super.key, this.token});

  @override
  State<AdminTranslationsScreen> createState() =>
      _AdminTranslationsScreenState();
}

class _AdminTranslationsScreenState extends State<AdminTranslationsScreen> {
  bool _loading = true;
  bool _saving = false;

  String _language = 'en';
  String _dateFormat = 'DD/MM/YYYY';
  String _timeFormat = '12h';
  final _timezoneCtrl = TextEditingController(text: 'Asia/Kolkata');

  final _langs = const [
    DropdownMenuItem(value: 'en', child: Text('English')),
    DropdownMenuItem(value: 'hi', child: Text('Hindi')),
    DropdownMenuItem(value: 'ar', child: Text('Arabic')),
    DropdownMenuItem(value: 'fr', child: Text('French')),
    DropdownMenuItem(value: 'de', child: Text('German')),
    DropdownMenuItem(value: 'es', child: Text('Spanish')),
    DropdownMenuItem(value: 'zh', child: Text('Chinese')),
    DropdownMenuItem(value: 'ja', child: Text('Japanese')),
  ];

  final _dateFormats = const [
    DropdownMenuItem(value: 'DD/MM/YYYY', child: Text('DD/MM/YYYY')),
    DropdownMenuItem(value: 'MM/DD/YYYY', child: Text('MM/DD/YYYY')),
    DropdownMenuItem(value: 'YYYY-MM-DD', child: Text('YYYY-MM-DD')),
    DropdownMenuItem(value: 'DD-MM-YYYY', child: Text('DD-MM-YYYY')),
    DropdownMenuItem(value: 'DD.MM.YYYY', child: Text('DD.MM.YYYY')),
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
          _language = d['defaultLanguage'] ?? 'en';
          _dateFormat = d['dateFormat'] ?? 'DD/MM/YYYY';
          _timeFormat = d['timeFormat'] ?? '12h';
          _timezoneCtrl.text = d['timezone'] ?? 'Asia/Kolkata';
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SettingsService.updateLocalizationSettings(widget.token ?? '', {
        'defaultLanguage': _language,
        'dateFormat': _dateFormat,
        'timeFormat': _timeFormat,
        'timezone': _timezoneCtrl.text,
      });
      if (mounted) showAdminSnack(context, 'Localization settings updated');
    } catch (_) {
      if (mounted) showAdminSnack(context, 'Failed to update', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _timezoneCtrl.dispose();
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
              title: 'Translations',
              subtitle: 'Language, date/time formats and timezone',
              icon: Icons.language_rounded,
              iconColor: const Color(0xFFF59E0B),
              trailing: AdminSaveButton(saving: _saving, onTap: _save),
            ),
            Expanded(
              child: _loading
                  ? adminLoader()
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      children: [
                        AdminCard(
                          title: 'Language & Locale',
                          children: [
                            AdminRow2(
                              left: AdminDropdown(
                                label: 'Default Language',
                                value: _language,
                                items: _langs,
                                onChanged: (v) =>
                                    setState(() => _language = v!),
                              ),
                              right: AdminTextField(
                                label: 'Timezone',
                                controller: _timezoneCtrl,
                                hint: 'e.g. Asia/Kolkata',
                              ),
                            ),
                          ],
                        ),
                        AdminCard(
                          title: 'Date & Time Format',
                          children: [
                            AdminRow2(
                              left: AdminDropdown(
                                label: 'Date Format',
                                value: _dateFormat,
                                items: _dateFormats,
                                onChanged: (v) =>
                                    setState(() => _dateFormat = v!),
                              ),
                              right: AdminDropdown(
                                label: 'Time Format',
                                value: _timeFormat,
                                items: const [
                                  DropdownMenuItem(
                                    value: '12h',
                                    child: Text('12 Hour'),
                                  ),
                                  DropdownMenuItem(
                                    value: '24h',
                                    child: Text('24 Hour'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _timeFormat = v!),
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
