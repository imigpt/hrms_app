import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms_app/shared/services/core/settings_service.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';
import 'shared.dart';

class AdminHRMSettingsScreen extends StatefulWidget {
  final String? token;
  const AdminHRMSettingsScreen({super.key, this.token});

  @override
  State<AdminHRMSettingsScreen> createState() => _AdminHRMSettingsScreenState();
}

class _AdminHRMSettingsScreenState extends State<AdminHRMSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  int _tab = 0;

  // Settings
  String _leaveStartMonth = 'January';
  late TextEditingController _autoCheckoutTimeCtrl;
  late TextEditingController _totalWorkingHoursCtrl;
  late TextEditingController _halfDayHoursCtrl;
  late TextEditingController _workingDaysPerWeekCtrl;
  
  bool _selfClocking = true;
  bool _captureLocation = false;
  bool _overtimeEnabled = false;
  
  double _totalWorkingHours = 9.0;
  double _halfDayHours = 4.5;
  int _workingDaysPerWeek = 5;
  
  List<String> _weeklyOffDays = ['sunday'];
  List<String> _allowedIPs = [];
  String _newIP = '';

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const _days = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
  ];

  @override
  void initState() {
    super.initState();
    _autoCheckoutTimeCtrl = TextEditingController(text: '23:59');
    _totalWorkingHoursCtrl = TextEditingController(text: '9');
    _halfDayHoursCtrl = TextEditingController(text: '4.5');
    _workingDaysPerWeekCtrl = TextEditingController(text: '5');
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await SettingsService.getHRMSettings(widget.token ?? '');
      final d = res['data'];
      if (d != null) {
        setState(() {
          _leaveStartMonth = d['leaveStartMonth'] ?? 'January';
          _autoCheckoutTimeCtrl.text = (d['autoCheckoutTime'] ?? '23:59').substring(0, 5);
          _totalWorkingHours = (d['totalWorkingHours'] ?? 9) as double;
          _totalWorkingHoursCtrl.text = _totalWorkingHours.toString();
          _halfDayHours = (d['halfDayHours'] ?? 4.5) as double;
          _halfDayHoursCtrl.text = _halfDayHours.toString();
          _workingDaysPerWeek = (d['workingDaysPerWeek'] ?? 5) as int;
          _workingDaysPerWeekCtrl.text = _workingDaysPerWeek.toString();
          _selfClocking = d['selfClocking'] ?? true;
          _captureLocation = d['captureLocation'] ?? false;
          _overtimeEnabled = d['overtimeEnabled'] ?? false;
          _weeklyOffDays = List<String>.from(d['weeklyOffDays'] ?? ['sunday']);
          _allowedIPs = List<String>.from(d['allowedIPs'] ?? []);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    // Validation
    if (_totalWorkingHours <= 0) {
      showAdminSnack(context, 'Total working hours must be greater than 0', error: true);
      return;
    }
    if (_halfDayHours <= 0 || _halfDayHours >= _totalWorkingHours) {
      showAdminSnack(context, 'Half day hours must be > 0 and < total working hours', error: true);
      return;
    }
    if (!RegExp(r'^([01]\d|2[0-3]):([0-5]\d)').hasMatch(_autoCheckoutTimeCtrl.text)) {
      showAdminSnack(context, 'Auto checkout time must be in HH:mm format', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await SettingsService.updateHRMSettings(widget.token ?? '', {
        'leaveStartMonth': _leaveStartMonth,
        'autoCheckoutTime': '${_autoCheckoutTimeCtrl.text}:00',
        'totalWorkingHours': _totalWorkingHours,
        'halfDayHours': _halfDayHours,
        'workingDaysPerWeek': _workingDaysPerWeek,
        'selfClocking': _selfClocking,
        'captureLocation': _captureLocation,
        'overtimeEnabled': _overtimeEnabled,
        'weeklyOffDays': _weeklyOffDays,
        'allowedIPs': _allowedIPs,
      });
      if (mounted) showAdminSnack(context, 'HRM settings updated');
    } catch (e) {
      if (mounted) showAdminSnack(context, 'Failed to update', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addIP() {
    if (_newIP.isNotEmpty && !_allowedIPs.contains(_newIP)) {
      setState(() {
        _allowedIPs.add(_newIP);
        _newIP = '';
      });
    }
  }

  void _removeIP(String ip) {
    setState(() => _allowedIPs.remove(ip));
  }

  @override
  void dispose() {
    _autoCheckoutTimeCtrl.dispose();
    _totalWorkingHoursCtrl.dispose();
    _halfDayHoursCtrl.dispose();
    _workingDaysPerWeekCtrl.dispose();
    super.dispose();
  }

  Widget _numInput(
    String label,
    TextEditingController controller,
    Function(dynamic) onChanged, {
    String hint = '0',
    String? description,
    int? maxDigits,
    bool isDecimal = false,
    String suffix = 'min',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionLabel(label, topPad: false),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ],
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isDecimal 
              ? TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          inputFormatters: [
            if (isDecimal)
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            else
              FilteringTextInputFormatter.digitsOnly,
            if (maxDigits != null) LengthLimitingTextInputFormatter(maxDigits),
          ],
          onChanged: (v) {
            if (isDecimal) {
              final parsed = double.tryParse(v);
              if (parsed != null) {
                onChanged(parsed);
              } else if (v.isEmpty) {
                onChanged(0.0);
              }
            } else {
              final parsed = int.tryParse(v);
              if (parsed != null) {
                onChanged(parsed);
              } else if (v.isEmpty) {
                onChanged(0);
              }
            }
          },
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
            suffixText: suffix,
            suffixStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
              title: 'HRM Settings',
              subtitle: 'Attendance, clock-in rules and IP restrictions',
              icon: Icons.settings_rounded,
              iconColor: const Color(0xFFf4879a),
              trailing: AdminSaveButton(saving: _saving, onTap: _save),
            ),
            // Tab bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: ['Attendance', 'Work Rules', 'IP Restrictions']
                    .asMap()
                    .entries
                    .map(
                      (e) => Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _tab = e.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: EdgeInsets.only(right: e.key < 2 ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _tab == e.key
                                  ? AppTheme.primaryColor
                                  : AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _tab == e.key
                                    ? AppTheme.primaryColor
                                    : Colors.white.withOpacity(0.07),
                              ),
                            ),
                            child: Text(
                              e.value,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _tab == e.key
                                    ? Colors.white
                                    : Colors.grey[500],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(
              child: _loading
                  ? adminLoader()
                  : _tab == 0
                  ? _buildAttendance()
                  : _tab == 1
                  ? _buildWorkRules()
                  : _buildIPTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendance() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        AdminCard(
          title: 'Attendance Settings',
          children: [
            AdminDropdown(
              label: 'Leave Start Month *',
              value: _leaveStartMonth,
              items: _months
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _leaveStartMonth = v!),
            ),
            const SizedBox(height: 14),
            AdminRow2(
              left: AdminYesNoToggle(
                label: 'Self Clocking',
                value: _selfClocking,
                onChanged: (v) => setState(() => _selfClocking = v),
              ),
              right: AdminYesNoToggle(
                label: 'Capture Location',
                value: _captureLocation,
                onChanged: (v) => setState(() => _captureLocation = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkRules() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        AdminCard(
          title: 'Work Rules',
          children: [
            AdminRow2(
              left: _numInput(
                'Total Working Hours *',
                _totalWorkingHoursCtrl,
                (v) => setState(() => _totalWorkingHours = v),
                isDecimal: true,
                description: 'Total hours per working day',
                suffix: 'hrs',
              ),
              right: _numInput(
                'Half Day Hours *',
                _halfDayHoursCtrl,
                (v) => setState(() => _halfDayHours = v),
                isDecimal: true,
                description: 'Duration for half-day leave',
                suffix: 'hrs',
              ),
            ),
            const SizedBox(height: 14),
            AdminTextField(
              label: 'Auto Checkout Time',
              controller: _autoCheckoutTimeCtrl,
              hint: '23:59',
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 14),
            AdminRow2(
              left: _numInput(
                'Working Days / Week',
                _workingDaysPerWeekCtrl,
                (v) => setState(() => _workingDaysPerWeek = v.clamp(1, 7)),
                description: 'Number of working days',
              ),
              right: AdminYesNoToggle(
                label: 'Overtime Enabled',
                value: _overtimeEnabled,
                onChanged: (v) => setState(() => _overtimeEnabled = v),
              ),
            ),
            const SizedBox(height: 14),
            AdminMultiChipSelect(
              label: 'Weekly Off Days',
              options: _days,
              selected: _weeklyOffDays,
              onChanged: (v) => setState(() => _weeklyOffDays = v),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIPTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        AdminCard(
          title: 'IP Restrictions',
          children: [
            AdminChipInput(
              label: 'Allowed IP Addresses',
              hint: 'e.g. 192.168.1.1',
              chips: _allowedIPs,
              onChanged: (v) => setState(() => _allowedIPs = v),
            ),
            if (_allowedIPs.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'No IP restrictions configured. All IPs are allowed.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
