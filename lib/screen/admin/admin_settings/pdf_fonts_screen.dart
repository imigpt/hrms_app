import 'package:flutter/material.dart';
import 'package:hrms_app/services/settings_service.dart';
import 'package:hrms_app/theme/app_theme.dart';
import 'shared.dart';

class AdminPdfFontsScreen extends StatefulWidget {
  final String? token;
  const AdminPdfFontsScreen({super.key, this.token});

  @override
  State<AdminPdfFontsScreen> createState() => _AdminPdfFontsScreenState();
}

class _AdminPdfFontsScreenState extends State<AdminPdfFontsScreen> {
  bool _loading = true;
  bool _saving = false;

  String _font = 'Helvetica';
  String _fontSize = '12';
  String _orientation = 'portrait';
  final _headerColorCtrl = TextEditingController(text: '#3b82f6');

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
          _font = d['pdfFont'] ?? 'Helvetica';
          _fontSize = d['pdfFontSize']?.toString() ?? '12';
          _orientation = d['pdfOrientation'] ?? 'portrait';
          _headerColorCtrl.text = d['pdfHeaderColor'] ?? '#3b82f6';
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SettingsService.updateLocalizationSettings(widget.token ?? '', {
        'pdfFont': _font,
        'pdfFontSize': _fontSize,
        'pdfOrientation': _orientation,
        'pdfHeaderColor': _headerColorCtrl.text,
      });
      if (mounted) showAdminSnack(context, 'PDF settings updated');
    } catch (_) {
      if (mounted) showAdminSnack(context, 'Failed to update', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _headerColorCtrl.dispose();
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
              title: 'PDF Fonts',
              subtitle: 'Configure font and layout settings for PDF exports',
              icon: Icons.picture_as_pdf_rounded,
              iconColor: const Color(0xFF64748B),
              trailing: AdminSaveButton(saving: _saving, onTap: _save),
            ),
            Expanded(
              child: _loading
                  ? adminLoader()
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      children: [
                        AdminCard(
                          title: 'Font Settings',
                          children: [
                            AdminRow2(
                              left: AdminDropdown(
                                label: 'Font Family',
                                value: _font,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Helvetica',
                                    child: Text('Helvetica'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Times-Roman',
                                    child: Text('Times Roman'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Courier',
                                    child: Text('Courier'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Roboto',
                                    child: Text('Roboto'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Open Sans',
                                    child: Text('Open Sans'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Lato',
                                    child: Text('Lato'),
                                  ),
                                ],
                                onChanged: (v) => setState(() => _font = v!),
                              ),
                              right: AdminDropdown(
                                label: 'Font Size',
                                value: _fontSize,
                                items: ['10', '11', '12', '13', '14']
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text('${s}pt'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _fontSize = v!),
                              ),
                            ),
                          ],
                        ),
                        AdminCard(
                          title: 'Layout Settings',
                          children: [
                            AdminRow2(
                              left: AdminDropdown(
                                label: 'PDF Orientation',
                                value: _orientation,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'portrait',
                                    child: Text('Portrait'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'landscape',
                                    child: Text('Landscape'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _orientation = v!),
                              ),
                              right: AdminTextField(
                                label: 'Header Colour (hex)',
                                controller: _headerColorCtrl,
                                hint: '#3b82f6',
                              ),
                            ),
                          ],
                        ),
                        AdminCard(
                          title: 'Preview',
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF64748B,
                                ).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF64748B,
                                  ).withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$_font · ${_fontSize}pt · ${_orientation[0].toUpperCase()}${_orientation.substring(1)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Header: ${_headerColorCtrl.text}',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11,
                                        ),
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
