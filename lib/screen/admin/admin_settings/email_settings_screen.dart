import 'package:flutter/material.dart';
import 'package:hrms_app/services/settings_service.dart';
import 'package:hrms_app/theme/app_theme.dart';
import 'shared.dart';

class AdminEmailSettingsScreen extends StatefulWidget {
  final String? token;
  const AdminEmailSettingsScreen({super.key, this.token});

  @override
  State<AdminEmailSettingsScreen> createState() =>
      _AdminEmailSettingsScreenState();
}

class _AdminEmailSettingsScreenState
    extends State<AdminEmailSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _testSending = false;
  int _tab = 0;

  // SMTP
  String _driver = 'smtp';
  final _smtpHostCtrl = TextEditingController(text: 'smtp.gmail.com');
  int _smtpPort = 587;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;
  String _encryption = 'tls';
  final _fromNameCtrl = TextEditingController(text: 'HRMS');
  final _fromEmailCtrl =
      TextEditingController(text: 'noreply@hrms.com');

  // Triggers
  bool _leaveApplication = true;
  bool _leaveApproval = true;
  bool _leaveRejection = true;
  bool _attendanceLate = true;
  bool _taskAssignment = true;
  bool _expenseSubmission = true;
  bool _expenseApproval = true;
  bool _resignation = true;
  bool _passwordReset = true;
  bool _welcomeEmail = true;
  bool _payslipGenerated = true;
  bool _announcement = true;

  // Logs
  List<Map<String, dynamic>> _logs = [];

  // Test email
  final _testEmailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res =
          await SettingsService.getEmailSettings(widget.token ?? '');
      final d = res['data'];
      if (d != null) {
        setState(() {
          _driver = d['mailDriver'] ?? 'smtp';
          _smtpHostCtrl.text = d['smtpHost'] ?? 'smtp.gmail.com';
          _smtpPort = (d['smtpPort'] ?? 587) as int;
          _usernameCtrl.text = d['smtpUsername'] ?? '';
          _passwordCtrl.text = d['smtpPassword'] ?? '';
          _encryption = d['encryption'] ?? 'tls';
          _fromNameCtrl.text = d['fromName'] ?? 'HRMS';
          _fromEmailCtrl.text = d['fromEmail'] ?? 'noreply@hrms.com';
          final t = d['triggers'] as Map?;
          if (t != null) {
            _leaveApplication = t['leaveApplication'] ?? true;
            _leaveApproval = t['leaveApproval'] ?? true;
            _leaveRejection = t['leaveRejection'] ?? true;
            _attendanceLate = t['attendanceLateArrival'] ?? true;
            _taskAssignment = t['taskAssignment'] ?? true;
            _expenseSubmission = t['expenseSubmission'] ?? true;
            _expenseApproval = t['expenseApproval'] ?? true;
            _resignation = t['resignation'] ?? true;
            _passwordReset = t['passwordReset'] ?? true;
            _welcomeEmail = t['welcomeEmail'] ?? true;
            _payslipGenerated = t['payslipGenerated'] ?? true;
            _announcement = t['announcement'] ?? true;
          }
        });
      }
      // load logs
      final logsRes = await SettingsService.getEmailLogs(widget.token ?? '');
      final logsData = logsRes['data'];
      if (logsData is List) {
        setState(() => _logs = logsData.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SettingsService.updateEmailSettings(widget.token ?? '', {
        'mailDriver': _driver,
        'smtpHost': _smtpHostCtrl.text,
        'smtpPort': _smtpPort,
        'smtpUsername': _usernameCtrl.text,
        'smtpPassword': _passwordCtrl.text,
        'encryption': _encryption,
        'fromName': _fromNameCtrl.text,
        'fromEmail': _fromEmailCtrl.text,
        'triggers': {
          'leaveApplication': _leaveApplication,
          'leaveApproval': _leaveApproval,
          'leaveRejection': _leaveRejection,
          'attendanceLateArrival': _attendanceLate,
          'taskAssignment': _taskAssignment,
          'expenseSubmission': _expenseSubmission,
          'expenseApproval': _expenseApproval,
          'resignation': _resignation,
          'passwordReset': _passwordReset,
          'welcomeEmail': _welcomeEmail,
          'payslipGenerated': _payslipGenerated,
          'announcement': _announcement,
        },
      });
      if (mounted) showAdminSnack(context, 'Email settings updated');
    } catch (_) {
      if (mounted) showAdminSnack(context, 'Failed to update', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendTest() async {
    if (_testEmailCtrl.text.isEmpty) return;
    setState(() => _testSending = true);
    try {
      await SettingsService.sendTestEmail(
          widget.token ?? '', _testEmailCtrl.text);
      if (mounted) showAdminSnack(context, 'Test email sent!');
    } catch (_) {
      if (mounted)
        showAdminSnack(context, 'Failed to send test email', error: true);
    } finally {
      if (mounted) setState(() => _testSending = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _smtpHostCtrl, _usernameCtrl, _passwordCtrl,
      _fromNameCtrl, _fromEmailCtrl, _testEmailCtrl,
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
              title: 'Email Settings',
              subtitle: 'SMTP configuration and email triggers',
              icon: Icons.email_rounded,
              iconColor: const Color(0xFF8B5CF6),
              trailing: AdminSaveButton(saving: _saving, onTap: _save),
            ),
            // Tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: ['SMTP', 'Triggers', 'Logs']
                    .asMap()
                    .entries
                    .map((e) => Expanded(
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
                                        : Colors.white.withOpacity(0.07)),
                              ),
                              child: Text(
                                e.value,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: _tab == e.key
                                        ? Colors.white
                                        : Colors.grey[500],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            Expanded(
              child: _loading
                  ? adminLoader()
                  : _tab == 0
                      ? _buildSMTP()
                      : _tab == 1
                          ? _buildTriggers()
                          : _buildLogs(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSMTP() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        AdminCard(
          title: 'Mail Driver',
          children: [
            AdminDropdown(
              label: 'Driver',
              value: _driver,
              items: const [
                DropdownMenuItem(value: 'smtp', child: Text('SMTP')),
                DropdownMenuItem(value: 'sendgrid', child: Text('SendGrid')),
                DropdownMenuItem(value: 'mailgun', child: Text('Mailgun')),
                DropdownMenuItem(value: 'ses', child: Text('Amazon SES')),
              ],
              onChanged: (v) => setState(() => _driver = v!),
            ),
          ],
        ),
        AdminCard(
          title: 'SMTP Configuration',
          children: [
            AdminRow2(
              left: AdminTextField(
                  label: 'SMTP Host',
                  controller: _smtpHostCtrl,
                  hint: 'smtp.gmail.com'),
              right: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminSectionLabel('Port', topPad: false),
                  const SizedBox(height: 6),
                  TextFormField(
                    initialValue: _smtpPort.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        setState(() => _smtpPort = int.tryParse(v) ?? 587),
                    style:
                        const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.07)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.07)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AppTheme.primaryColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AdminDropdown(
              label: 'Encryption',
              value: _encryption,
              items: const [
                DropdownMenuItem(value: 'tls', child: Text('TLS')),
                DropdownMenuItem(value: 'ssl', child: Text('SSL')),
                DropdownMenuItem(value: 'none', child: Text('None')),
              ],
              onChanged: (v) => setState(() => _encryption = v!),
            ),
            const SizedBox(height: 14),
            AdminTextField(label: 'Username', controller: _usernameCtrl),
            const SizedBox(height: 14),
            AdminTextField(
              label: 'Password',
              controller: _passwordCtrl,
              obscure: !_showPassword,
              suffix: IconButton(
                icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.grey[500],
                    size: 18),
                onPressed: () =>
                    setState(() => _showPassword = !_showPassword),
              ),
            ),
          ],
        ),
        AdminCard(
          title: 'From Address',
          children: [
            AdminRow2(
              left: AdminTextField(
                  label: 'From Name', controller: _fromNameCtrl),
              right: AdminTextField(
                  label: 'From Email',
                  controller: _fromEmailCtrl,
                  keyboardType: TextInputType.emailAddress),
            ),
          ],
        ),
        AdminCard(
          title: 'Send Test Email',
          children: [
            Row(
              children: [
                Expanded(
                  child: AdminTextField(
                      label: 'Test Email Address',
                      controller: _testEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      hint: 'test@example.com'),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: GestureDetector(
                    onTap: _testSending ? null : _sendTest,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF3B82F6).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF3B82F6).withOpacity(0.4)),
                      ),
                      child: _testSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF3B82F6)))
                          : const Icon(Icons.send_rounded,
                              color: Color(0xFF3B82F6), size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTriggers() {
    final triggers = [
      ('Leave Application', _leaveApplication,
          (v) => setState(() => _leaveApplication = v)),
      ('Leave Approval', _leaveApproval,
          (v) => setState(() => _leaveApproval = v)),
      ('Leave Rejection', _leaveRejection,
          (v) => setState(() => _leaveRejection = v)),
      ('Late Attendance', _attendanceLate,
          (v) => setState(() => _attendanceLate = v)),
      ('Task Assignment', _taskAssignment,
          (v) => setState(() => _taskAssignment = v)),
      ('Expense Submission', _expenseSubmission,
          (v) => setState(() => _expenseSubmission = v)),
      ('Expense Approval', _expenseApproval,
          (v) => setState(() => _expenseApproval = v)),
      ('Resignation', _resignation,
          (v) => setState(() => _resignation = v)),
      ('Password Reset', _passwordReset,
          (v) => setState(() => _passwordReset = v)),
      ('Welcome Email', _welcomeEmail,
          (v) => setState(() => _welcomeEmail = v)),
      ('Payslip Generated', _payslipGenerated,
          (v) => setState(() => _payslipGenerated = v)),
      ('Announcement', _announcement,
          (v) => setState(() => _announcement = v)),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        AdminCard(
          title: 'Email Triggers',
          children: [
            ...triggers.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AdminToggleRow(
                    label: t.$1,
                    value: t.$2,
                    onChanged: (v) => t.$3(v),
                  ),
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildLogs() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        AdminCard(
          title: 'Recent Email Logs (${_logs.length})',
          children: [
            if (_logs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Text('No email logs found.',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13))),
              )
            else
              ..._logs.take(20).map((log) => _LogItem(log: log)),
          ],
        ),
      ],
    );
  }
}

class _LogItem extends StatelessWidget {
  final Map<String, dynamic> log;
  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final status = log['status']?.toString() ?? 'unknown';
    final isSuccess = status == 'sent' || status == 'success';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isSuccess
                ? const Color(0xFF22C55E).withOpacity(0.2)
                : const Color(0xFFEF4444).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSuccess
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log['subject']?.toString() ?? 'No subject',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('To: ${log['to'] ?? '—'} · $status',
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
