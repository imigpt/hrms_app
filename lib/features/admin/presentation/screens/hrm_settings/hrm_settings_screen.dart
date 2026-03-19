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

  String _leaveStartMonth = 'January';
  final _clockInCtrl = TextEditingController(text: '09:30');
  final _clockOutCtrl = TextEditingController(text: '18:00');
  late TextEditingController _earlyClockInCtrl;
  late TextEditingController _allowClockOutTillCtrl;
  late TextEditingController _lateMarkAfterCtrl;
  late TextEditingController _halfDayHoursCtrl;
  late TextEditingController _workingDaysPerWeekCtrl;
  int _earlyClockIn = 0;
  int _allowClockOutTill = 0;
  int _lateMarkAfter = 30;
  bool _selfClocking = true;
  bool _captureLocation = false;
  int _halfDayHours = 4;
  int _workingDaysPerWeek = 5;
  List<String> _weeklyOffDays = ['sunday'];
  List<String> _allowedIPs = [];

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  void initState() {
    super.initState();
    _earlyClockInCtrl = TextEditingController(text: '0');
    _allowClockOutTillCtrl = TextEditingController(text: '0');
    _lateMarkAfterCtrl = TextEditingController(text: '30');
    _halfDayHoursCtrl = TextEditingController(text: '4');
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
          _clockInCtrl.text = (d['clockInTime'] ?? '09:30').substring(0, 5);
          _clockOutCtrl.text = (d['clockOutTime'] ?? '18:00').substring(0, 5);
          _earlyClockIn = (d['earlyClockInMinutes'] ?? 0) as int;
          _allowClockOutTill = (d['allowClockOutTillMinutes'] ?? 0) as int;
          _lateMarkAfter = (d['lateMarkAfterMinutes'] ?? 30) as int;
          _earlyClockInCtrl.text = _earlyClockIn.toString();
          _allowClockOutTillCtrl.text = _allowClockOutTill.toString();
          _lateMarkAfterCtrl.text = _lateMarkAfter.toString();
          _selfClocking = d['selfClocking'] ?? true;
          _captureLocation = d['captureLocation'] ?? false;
          _halfDayHours = (d['halfDayHours'] ?? 4) as int;
          _workingDaysPerWeek = (d['workingDaysPerWeek'] ?? 5) as int;
          _halfDayHoursCtrl.text = _halfDayHours.toString();
          _workingDaysPerWeekCtrl.text = _workingDaysPerWeek.toString();
          _weeklyOffDays = List<String>.from(d['weeklyOffDays'] ?? ['sunday']);
          _allowedIPs = List<String>.from(d['allowedIPs'] ?? []);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SettingsService.updateHRMSettings(widget.token ?? '', {
        'leaveStartMonth': _leaveStartMonth,
        'clockInTime': '${_clockInCtrl.text}:00',
        'clockOutTime': '${_clockOutCtrl.text}:00',
        'earlyClockInMinutes': _earlyClockIn,
        'allowClockOutTillMinutes': _allowClockOutTill,
        'lateMarkAfterMinutes': _lateMarkAfter,
        'selfClocking': _selfClocking,
        'captureLocation': _captureLocation,
        'halfDayHours': _halfDayHours,
        'workingDaysPerWeek': _workingDaysPerWeek,
        'weeklyOffDays': _weeklyOffDays,
        'allowedIPs': _allowedIPs,
      });
      if (mounted) showAdminSnack(context, 'HRM settings updated');
    } catch (_) {
      if (mounted) showAdminSnack(context, 'Failed to update', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _clockInCtrl.dispose();
    _clockOutCtrl.dispose();
    _earlyClockInCtrl.dispose();
    _allowClockOutTillCtrl.dispose();
    _lateMarkAfterCtrl.dispose();
    _halfDayHoursCtrl.dispose();
    _workingDaysPerWeekCtrl.dispose();
    super.dispose();
  }

  Widget _numInput(
    String label,
    TextEditingController controller,
    ValueChanged<int> onChanged, {
    String hint = '0',
    String? description,
    int? maxDigits,
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
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            if (maxDigits != null) LengthLimitingTextInputFormatter(maxDigits),
          ],
          onChanged: (v) {
            final parsed = int.tryParse(v);
            if (parsed != null) {
              onChanged(parsed);
            } else if (v.isEmpty) {
              onChanged(0);
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
            suffixText: 'min',
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
          title: 'Leave & Clock Settings',
          children: [
            AdminDropdown(
              label: 'Leave Start Month',
              value: _leaveStartMonth,
              items: _months
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _leaveStartMonth = v!),
            ),
            const SizedBox(height: 14),
            AdminRow2(
              left: AdminTextField(
                label: 'Check In Time',
                controller: _clockInCtrl,
                hint: '09:30',
                keyboardType: TextInputType.datetime,
              ),
              right: AdminTextField(
                label: 'Check Out Time',
                controller: _clockOutCtrl,
                hint: '18:00',
                keyboardType: TextInputType.datetime,
              ),
            ),
            const SizedBox(height: 14),
            AdminRow2(
              left: _numInput(
                'Early Clock In',
                _earlyClockInCtrl,
                (v) => setState(() => _earlyClockIn = v),
                description: 'Allow early check-in before scheduled time',
                maxDigits: 2,
              ),
              right: _numInput(
                'Allow Clock Out Till',
                _allowClockOutTillCtrl,
                (v) => setState(() => _allowClockOutTill = v),
                description: 'Allow check-out after scheduled time',
                maxDigits: 2,
              ),
            ),
            const SizedBox(height: 14),
            _numInput(
              'Late Mark After',
              _lateMarkAfterCtrl,
              (v) => setState(() => _lateMarkAfter = v),
              description: 'Mark attendance as late if check-in is after this time',
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
                'Half Day Hours',
                _halfDayHoursCtrl,
                (v) => setState(() => _halfDayHours = v),
              ),
              right: _numInput(
                'Working Days / Week',
                _workingDaysPerWeekCtrl,
                (v) => setState(() => _workingDaysPerWeek = v.clamp(1, 7)),
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
