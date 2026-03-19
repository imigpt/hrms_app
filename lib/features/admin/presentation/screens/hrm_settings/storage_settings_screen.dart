import 'package:flutter/material.dart';
import 'package:hrms_app/shared/services/core/settings_service.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';
import 'shared.dart';

class AdminStorageSettingsScreen extends StatefulWidget {
  final String? token;
  const AdminStorageSettingsScreen({super.key, this.token});

  @override
  State<AdminStorageSettingsScreen> createState() =>
      _AdminStorageSettingsScreenState();
}

class _AdminStorageSettingsScreenState
    extends State<AdminStorageSettingsScreen> {
  bool _loading = true;
  bool _saving = false;

  String _driver = 'cloudinary';
  final _cloudNameCtrl = TextEditingController();
  final _cloudKeyCtrl = TextEditingController();
  final _cloudSecretCtrl = TextEditingController();
  final _awsBucketCtrl = TextEditingController();
  final _awsRegionCtrl = TextEditingController();
  final _awsAccessKeyCtrl = TextEditingController();
  final _awsSecretKeyCtrl = TextEditingController();
  int _maxUpload = 10;
  final _extensionsCtrl = TextEditingController(
    text: 'jpg,jpeg,png,gif,pdf,doc,docx,xls,xlsx,ppt,pptx,csv,txt',
  );

  bool _showCloudSecret = false;
  bool _showAwsSecret = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await SettingsService.getStorageSettings(widget.token ?? '');
      final d = res['data'];
      if (d != null) {
        setState(() => _driver = d['storageDriver'] ?? d['provider'] ?? 'cloudinary');
        _cloudNameCtrl.text = d['cloudinaryCloudName'] ?? '';
        _cloudKeyCtrl.text = d['cloudinaryApiKey'] ?? '';
        _cloudSecretCtrl.text = d['cloudinaryApiSecret'] ?? '';
        _awsBucketCtrl.text = d['awsBucket'] ?? '';
        _awsRegionCtrl.text = d['awsRegion'] ?? '';
        _awsAccessKeyCtrl.text = d['awsAccessKey'] ?? '';
        _awsSecretKeyCtrl.text = d['awsSecretKey'] ?? '';
        setState(() {
          _maxUpload = (d['maxUploadSize'] ?? 10) as int;
          _extensionsCtrl.text =
              d['allowedExtensions'] ??
              'jpg,jpeg,png,gif,pdf,doc,docx,xls,xlsx,ppt,pptx,csv,txt';
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SettingsService.updateStorageSettings(widget.token ?? '', {
        'storageDriver': _driver,
        'cloudinaryCloudName': _cloudNameCtrl.text,
        'cloudinaryApiKey': _cloudKeyCtrl.text,
        'cloudinaryApiSecret': _cloudSecretCtrl.text,
        'awsBucket': _awsBucketCtrl.text,
        'awsRegion': _awsRegionCtrl.text,
        'awsAccessKey': _awsAccessKeyCtrl.text,
        'awsSecretKey': _awsSecretKeyCtrl.text,
        'maxUploadSize': _maxUpload,
        'allowedExtensions': _extensionsCtrl.text,
      });
      if (mounted) showAdminSnack(context, 'Storage settings updated');
    } catch (_) {
      if (mounted) showAdminSnack(context, 'Failed to update', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _cloudNameCtrl,
      _cloudKeyCtrl,
      _cloudSecretCtrl,
      _awsBucketCtrl,
      _awsRegionCtrl,
      _awsAccessKeyCtrl,
      _awsSecretKeyCtrl,
      _extensionsCtrl,
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
              title: 'Storage Settings',
              subtitle: 'File storage provider and upload limits',
              icon: Icons.storage_rounded,
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
                          title: 'Storage Driver',
                          children: [
                            AdminRow2(
                              left: AdminDropdown(
                                label: 'Driver',
                                value: _driver,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'cloudinary',
                                    child: Text('Cloudinary'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'aws-s3',
                                    child: Text('AWS S3'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'local',
                                    child: Text('Local Storage'),
                                  ),
                                ],
                                onChanged: (v) => setState(() => _driver = v!),
                              ),
                              right: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const AdminSectionLabel(
                                    'Max Upload Size',
                                    topPad: false,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Slider(
                                          value: _maxUpload.toDouble(),
                                          min: 1,
                                          max: 100,
                                          divisions: 99,
                                          activeColor: AppTheme.primaryColor,
                                          inactiveColor: AppTheme.cardColor,
                                          onChanged: (v) => setState(
                                            () => _maxUpload = v.toInt(),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 46,
                                        child: Text(
                                          '$_maxUpload MB',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            AdminTextField(
                              label: 'Allowed Extensions',
                              controller: _extensionsCtrl,
                              hint: 'jpg,png,pdf...',
                            ),
                          ],
                        ),
                        if (_driver == 'cloudinary')
                          AdminCard(
                            title: 'Cloudinary Configuration',
                            children: [
                              AdminTextField(
                                label: 'Cloud Name',
                                controller: _cloudNameCtrl,
                                hint: 'my-cloud',
                              ),
                              const SizedBox(height: 12),
                              AdminRow2(
                                left: AdminTextField(
                                  label: 'API Key',
                                  controller: _cloudKeyCtrl,
                                ),
                                right: AdminTextField(
                                  label: 'API Secret',
                                  controller: _cloudSecretCtrl,
                                  obscure: !_showCloudSecret,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _showCloudSecret
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: Colors.grey[500],
                                      size: 18,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _showCloudSecret = !_showCloudSecret,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (_driver == 'aws-s3')
                          AdminCard(
                            title: 'AWS S3 Configuration',
                            children: [
                              AdminRow2(
                                left: AdminTextField(
                                  label: 'Bucket Name',
                                  controller: _awsBucketCtrl,
                                ),
                                right: AdminTextField(
                                  label: 'Region',
                                  controller: _awsRegionCtrl,
                                  hint: 'us-east-1',
                                ),
                              ),
                              const SizedBox(height: 12),
                              AdminRow2(
                                left: AdminTextField(
                                  label: 'Access Key',
                                  controller: _awsAccessKeyCtrl,
                                ),
                                right: AdminTextField(
                                  label: 'Secret Key',
                                  controller: _awsSecretKeyCtrl,
                                  obscure: !_showAwsSecret,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _showAwsSecret
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: Colors.grey[500],
                                      size: 18,
                                    ),
                                    onPressed: () => setState(
                                      () => _showAwsSecret = !_showAwsSecret,
                                    ),
                                  ),
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
