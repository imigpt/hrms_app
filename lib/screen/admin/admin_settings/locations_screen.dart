import 'package:flutter/material.dart';
import 'package:hrms_app/services/settings_service.dart';
import 'package:hrms_app/theme/app_theme.dart';
import 'shared.dart';

class AdminLocationsScreen extends StatefulWidget {
  final String? token;
  const AdminLocationsScreen({super.key, this.token});

  @override
  State<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends State<AdminLocationsScreen> {
  bool _loading = true;
  bool _saving = false;
  List<Map<String, String>> _locations = [];

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

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
      final locs = res['data']?['locations'];
      if (locs is List) {
        setState(() => _locations = locs
            .map<Map<String, String>>((l) => {
                  'name': l['name']?.toString() ?? '',
                  'address': l['address']?.toString() ?? '',
                  'city': l['city']?.toString() ?? '',
                  'state': l['state']?.toString() ?? '',
                  'country': l['country']?.toString() ?? '',
                })
            .toList());
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _addLocation() {
    if (_nameCtrl.text.isEmpty || _cityCtrl.text.isEmpty) {
      showAdminSnack(context, 'Name and City are required', error: true);
      return;
    }
    setState(() {
      _locations.add({
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
      });
    });
    _nameCtrl.clear();
    _addressCtrl.clear();
    _cityCtrl.clear();
    _stateCtrl.clear();
    _countryCtrl.clear();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SettingsService.updateCompanySettings(
          widget.token ?? '', {'locations': _locations});
      if (mounted) showAdminSnack(context, 'Locations updated');
    } catch (_) {
      if (mounted) showAdminSnack(context, 'Failed to update', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _addressCtrl, _cityCtrl, _stateCtrl, _countryCtrl,
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
              title: 'Locations',
              subtitle: 'Define office locations for your organisation',
              icon: Icons.location_on_rounded,
              iconColor: const Color(0xFFEF4444),
              trailing: AdminSaveButton(saving: _saving, onTap: _save),
            ),
            Expanded(
              child: _loading
                  ? adminLoader()
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      children: [
                        AdminCard(
                          title: 'Add New Location',
                          children: [
                            AdminRow2(
                              left: AdminTextField(
                                  label: 'Location Name *',
                                  controller: _nameCtrl,
                                  hint: 'e.g. Mumbai HQ'),
                              right: AdminTextField(
                                  label: 'Address',
                                  controller: _addressCtrl),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: AdminTextField(
                                      label: 'City *',
                                      controller: _cityCtrl),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AdminTextField(
                                      label: 'State',
                                      controller: _stateCtrl),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AdminTextField(
                                      label: 'Country',
                                      controller: _countryCtrl),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: GestureDetector(
                                onTap: _addLocation,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_location_alt_rounded,
                                          color: AppTheme.primaryColor,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Text('Add Location',
                                          style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        AdminCard(
                          title: 'Locations (${_locations.length})',
                          children: [
                            if (_locations.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 24),
                                child: Center(
                                  child: Text(
                                    'No locations added yet.',
                                    style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13),
                                  ),
                                ),
                              )
                            else
                              ...List.generate(_locations.length, (i) {
                                final l = _locations[i];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.06)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444)
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                            Icons.location_on_rounded,
                                            color: Color(0xFFEF4444),
                                            size: 16),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(l['name'] ?? '',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            if ((l['city'] ?? '').isNotEmpty)
                                              Text(
                                                [
                                                  l['city'],
                                                  l['state'],
                                                  l['country'],
                                                ]
                                                    .where((s) =>
                                                        s != null &&
                                                        s.isNotEmpty)
                                                    .join(', '),
                                                style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 11),
                                              ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => setState(
                                            () => _locations.removeAt(i)),
                                        child: Icon(Icons.delete_outline_rounded,
                                            color: Colors.grey[600], size: 18),
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
