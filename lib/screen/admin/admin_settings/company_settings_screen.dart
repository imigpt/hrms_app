import 'package:flutter/material.dart';
import 'package:hrms_app/services/settings_service.dart';
import 'package:hrms_app/theme/app_theme.dart';
import 'shared.dart';

class AdminCompanySettingsScreen extends StatefulWidget {
  final String? token;
  const AdminCompanySettingsScreen({super.key, this.token});

  @override
  State<AdminCompanySettingsScreen> createState() =>
      _AdminCompanySettingsScreenState();
}

class _AdminCompanySettingsScreenState
    extends State<AdminCompanySettingsScreen> {
  bool _loading = true;
  bool _saving = false;

  // Company info
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();

  // Additional settings
  final _shortNameCtrl = TextEditingController();
  final _mapsKeyCtrl = TextEditingController();
  final _timezoneCtrl = TextEditingController(text: 'Asia/Kolkata');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res =
          await SettingsService.getCompanySettings(widget.token ?? '');
      final data = res['data'];
      if (data != null) {
        final c = data['company'];
        final s = data['settings'];
        if (c != null) {
          _nameCtrl.text = c['name'] ?? '';
          _emailCtrl.text = c['email'] ?? '';
          _phoneCtrl.text = c['phone'] ?? '';
          _addressCtrl.text = c['address'] ?? '';
          _websiteCtrl.text = c['website'] ?? '';
          _industryCtrl.text = c['industry'] ?? '';
        }
        if (s != null) {
          _shortNameCtrl.text = s['shortName'] ?? '';
          _mapsKeyCtrl.text = s['googleMapsApiKey'] ?? '';
          _timezoneCtrl.text = s['timezone'] ?? 'Asia/Kolkata';
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SettingsService.updateCompanySettings(widget.token ?? '', {
        'companyData': {
          'name': _nameCtrl.text,
          'email': _emailCtrl.text,
          'phone': _phoneCtrl.text,
          'address': _addressCtrl.text,
          'website': _websiteCtrl.text,
          'industry': _industryCtrl.text,
        },
        'settings': {
          'shortName': _shortNameCtrl.text,
          'googleMapsApiKey': _mapsKeyCtrl.text,
          'timezone': _timezoneCtrl.text,
        },
      });
      if (mounted) showAdminSnack(context, 'Company settings updated');
    } catch (_) {
      if (mounted) showAdminSnack(context, 'Failed to update', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _emailCtrl, _phoneCtrl, _addressCtrl,
      _websiteCtrl, _industryCtrl, _shortNameCtrl, _mapsKeyCtrl, _timezoneCtrl,
    ]) {
      c.dispose();
    }
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
              title: 'Company Settings',
              subtitle: 'Configure your company information',
              icon: Icons.business_rounded,
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
                          title: 'Company Information',
                          children: [
                            AdminRow2(
                              left: AdminTextField(
                                  label: 'Company Name',
                                  controller: _nameCtrl),
                              right: AdminTextField(
                                  label: 'Short Name',
                                  controller: _shortNameCtrl,
                                  hint: 'e.g. ACME'),
                            ),
                            const SizedBox(height: 14),
                            AdminRow2(
                              left: AdminTextField(
                                  label: 'Company Email',
                                  controller: _emailCtrl,
                                  keyboardType:
                                      TextInputType.emailAddress),
                              right: AdminTextField(
                                  label: 'Phone Number',
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone),
                            ),
                            const SizedBox(height: 14),
                            AdminTextField(
                              label: 'Address',
                              controller: _addressCtrl,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 14),
                            AdminRow2(
                              left: AdminTextField(
                                  label: 'Website',
                                  controller: _websiteCtrl,
                                  hint: 'https://'),
                              right: AdminTextField(
                                  label: 'Industry',
                                  controller: _industryCtrl,
                                  hint: 'e.g. Technology'),
                            ),
                          ],
                        ),
                        AdminCard(
                          title: 'Advanced Settings',
                          children: [
                            AdminRow2(
                              left: AdminTextField(
                                  label: 'Google Maps API Key',
                                  controller: _mapsKeyCtrl,
                                  hint: 'AIzaSy...'),
                              right: AdminTextField(
                                  label: 'Timezone',
                                  controller: _timezoneCtrl),
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
