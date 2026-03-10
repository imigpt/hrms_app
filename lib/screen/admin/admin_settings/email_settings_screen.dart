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

class _AdminEmailSettingsScreenState extends State<AdminEmailSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _testSending = false;
  bool _bulkSending = false;
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
  final _fromEmailCtrl = TextEditingController(text: 'noreply@hrms.com');

  // Triggers
  bool _leaveApplication = true;
  bool _leaveApproval = true;
  bool _leaveRejection = true;
  bool _attendanceCheckIn = false;
  bool _attendanceCheckOut = false;
  bool _attendanceLate = true;
  bool _taskAssignment = true;
  bool _taskCompletion = false;
  bool _expenseSubmission = true;
  bool _expenseApproval = true;
  bool _resignation = true;
  bool _complaint = true;
  bool _passwordReset = true;
  bool _welcomeEmail = true;
  bool _payslipGenerated = true;
  bool _announcement = true;

  // Logs
  List<Map<String, dynamic>> _logs = [];

  // Test email
  final _testEmailCtrl = TextEditingController();

  // Bulk email
  final _bulkSubjectCtrl = TextEditingController();
  final _bulkBodyCtrl = TextEditingController();
  String _bulkTargetRole = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await SettingsService.getEmailSettings(widget.token ?? '');
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
            _attendanceCheckIn = t['attendanceCheckIn'] ?? false;
            _attendanceCheckOut = t['attendanceCheckOut'] ?? false;
            _attendanceLate = t['attendanceLateArrival'] ?? true;
            _taskAssignment = t['taskAssignment'] ?? true;
            _taskCompletion = t['taskCompletion'] ?? false;
            _expenseSubmission = t['expenseSubmission'] ?? true;
            _expenseApproval = t['expenseApproval'] ?? true;
            _resignation = t['resignation'] ?? true;
            _complaint = t['complaint'] ?? true;
            _passwordReset = t['passwordReset'] ?? true;
            _welcomeEmail = t['welcomeEmail'] ?? true;
            _payslipGenerated = t['payslipGenerated'] ?? true;
            _announcement = t['announcement'] ?? true;
          }
        });
      }
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
          'attendanceCheckIn': _attendanceCheckIn,
          'attendanceCheckOut': _attendanceCheckOut,
          'attendanceLateArrival': _attendanceLate,
          'taskAssignment': _taskAssignment,
          'taskCompletion': _taskCompletion,
          'expenseSubmission': _expenseSubmission,
          'expenseApproval': _expenseApproval,
          'resignation': _resignation,
          'complaint': _complaint,
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
        widget.token ?? '',
        _testEmailCtrl.text,
      );
      if (mounted) showAdminSnack(context, 'Test email sent!');
      _loadLogs();
    } catch (_) {
      if (mounted)
        showAdminSnack(context, 'Failed to send test email', error: true);
    } finally {
      if (mounted) setState(() => _testSending = false);
    }
  }

  Future<void> _loadLogs() async {
    try {
      final logsRes = await SettingsService.getEmailLogs(widget.token ?? '');
      final logsData = logsRes['data'];
      if (logsData is List && mounted) {
        setState(() => _logs = logsData.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  Future<void> _sendBulk() async {
    if (_bulkSubjectCtrl.text.isEmpty || _bulkBodyCtrl.text.isEmpty) return;
    setState(() => _bulkSending = true);
    try {
      await SettingsService.sendBulkEmail(widget.token ?? '', {
        'subject': _bulkSubjectCtrl.text.trim(),
        'body': _bulkBodyCtrl.text.trim(),
        'targetRole': _bulkTargetRole,
      });
      if (mounted) {
        showAdminSnack(context, 'Bulk email sent successfully');
        _bulkSubjectCtrl.clear();
        _bulkBodyCtrl.clear();
        setState(() => _bulkTargetRole = 'all');
        Navigator.of(context).pop();
        _loadLogs();
      }
    } catch (_) {
      if (mounted) showAdminSnack(context, 'Failed to send', error: true);
    } finally {
      if (mounted) setState(() => _bulkSending = false);
    }
  }

  void _showBulkEmailDialog() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Send Bulk Email',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send email to employees by role or to all.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 14),
                // Target Role
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminSectionLabel('Target Role', topPad: false),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _bulkTargetRole,
                      dropdownColor: AppTheme.cardColor,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.07),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.07),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (v) => setDlg(
                        () => _bulkTargetRole = v ?? 'all',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Users')),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Admins'),
                        ),
                        DropdownMenuItem(value: 'hr', child: Text('HR')),
                        DropdownMenuItem(
                          value: 'employee',
                          child: Text('Employees'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DlgField(
                  label: 'Subject',
                  ctrl: _bulkSubjectCtrl,
                  hint: 'Email subject',
                ),
                const SizedBox(height: 12),
                _DlgField(
                  label: 'Body (HTML supported)',
                  ctrl: _bulkBodyCtrl,
                  hint: 'Email body...',
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[500])),
            ),
            GestureDetector(
              onTap: _bulkSending ? null : _sendBulk,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _bulkSending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Send',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [
      _smtpHostCtrl,
      _usernameCtrl,
      _passwordCtrl,
      _fromNameCtrl,
      _fromEmailCtrl,
      _testEmailCtrl,
      _bulkSubjectCtrl,
      _bulkBodyCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tabLabels = [
      'Server Config',
      'Email Triggers',
      'Test & Logs',
      'Templates',
    ];
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _showBulkEmailDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.send_rounded,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Send Email',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AdminSaveButton(saving: _saving, onTap: _save),
                ],
              ),
            ),
            // Tabs (4 tabs)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: tabLabels.asMap().entries.map((e) {
                  final isLast = e.key == tabLabels.length - 1;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: EdgeInsets.only(right: isLast ? 0 : 6),
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
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: _loading
                  ? adminLoader()
                  : _tab == 0
                  ? _buildServer()
                  : _tab == 1
                  ? _buildTriggers()
                  : _tab == 2
                  ? _buildTestLogs()
                  : _buildTemplates(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServer() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        AdminCard(
          title: 'Mail Server',
          children: [
            // Row 1: Driver + Encryption
            AdminRow2(
              left: AdminDropdown(
                label: 'Mail Driver',
                value: _driver,
                items: const [
                  DropdownMenuItem(value: 'smtp', child: Text('SMTP')),
                  DropdownMenuItem(
                    value: 'sendgrid',
                    child: Text('SendGrid'),
                  ),
                  DropdownMenuItem(
                    value: 'ses',
                    child: Text('Amazon SES'),
                  ),
                  DropdownMenuItem(value: 'mailgun', child: Text('Mailgun')),
                ],
                onChanged: (v) => setState(() => _driver = v!),
              ),
              right: AdminDropdown(
                label: 'Encryption',
                value: _encryption,
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('None')),
                  DropdownMenuItem(value: 'ssl', child: Text('SSL')),
                  DropdownMenuItem(value: 'tls', child: Text('TLS')),
                ],
                onChanged: (v) => setState(() => _encryption = v!),
              ),
            ),
            const SizedBox(height: 14),
            // Row 2: SMTP Host + Port
            AdminRow2(
              left: AdminTextField(
                label: 'SMTP Host',
                controller: _smtpHostCtrl,
                hint: 'smtp.gmail.com',
              ),
              right: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminSectionLabel('SMTP Port', topPad: false),
                  const SizedBox(height: 6),
                  TextFormField(
                    initialValue: _smtpPort.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        setState(() => _smtpPort = int.tryParse(v) ?? 587),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Row 3: Username + Password
            AdminRow2(
              left: AdminTextField(
                label: 'Username',
                controller: _usernameCtrl,
              ),
              right: AdminTextField(
                label: 'Password',
                controller: _passwordCtrl,
                obscure: !_showPassword,
                suffix: IconButton(
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.grey[500],
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Row 4: From Name + From Email
            AdminRow2(
              left: AdminTextField(
                label: 'From Name',
                controller: _fromNameCtrl,
              ),
              right: AdminTextField(
                label: 'From Email',
                controller: _fromEmailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTriggers() {
    final triggers = [
      ('Leave Application', _leaveApplication, (v) => setState(() => _leaveApplication = v)),
      ('Leave Approval', _leaveApproval, (v) => setState(() => _leaveApproval = v)),
      ('Leave Rejection', _leaveRejection, (v) => setState(() => _leaveRejection = v)),
      ('Attendance Check In', _attendanceCheckIn, (v) => setState(() => _attendanceCheckIn = v)),
      ('Attendance Check Out', _attendanceCheckOut, (v) => setState(() => _attendanceCheckOut = v)),
      ('Late Arrival Alert', _attendanceLate, (v) => setState(() => _attendanceLate = v)),
      ('Task Assignment', _taskAssignment, (v) => setState(() => _taskAssignment = v)),
      ('Task Completion', _taskCompletion, (v) => setState(() => _taskCompletion = v)),
      ('Expense Submission', _expenseSubmission, (v) => setState(() => _expenseSubmission = v)),
      ('Expense Approval', _expenseApproval, (v) => setState(() => _expenseApproval = v)),
      ('Resignation', _resignation, (v) => setState(() => _resignation = v)),
      ('Complaint', _complaint, (v) => setState(() => _complaint = v)),
      ('Password Reset', _passwordReset, (v) => setState(() => _passwordReset = v)),
      ('Welcome Email', _welcomeEmail, (v) => setState(() => _welcomeEmail = v)),
      ('Payslip Generated', _payslipGenerated, (v) => setState(() => _payslipGenerated = v)),
      ('Announcement', _announcement, (v) => setState(() => _announcement = v)),
    ];

    // Build 2-column grid of toggle tiles
    final rows = <Widget>[];
    for (int i = 0; i < triggers.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: _TriggerTile(
                  label: triggers[i].$1,
                  value: triggers[i].$2,
                  onChanged: (v) => triggers[i].$3(v),
                ),
              ),
              const SizedBox(width: 8),
              if (i + 1 < triggers.length)
                Expanded(
                  child: _TriggerTile(
                    label: triggers[i + 1].$1,
                    value: triggers[i + 1].$2,
                    onChanged: (v) => triggers[i + 1].$3(v),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        AdminCard(
          title: 'Email Triggers',
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Enable or disable automatic email notifications for these events:',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
            ...rows,
          ],
        ),
      ],
    );
  }

  Widget _buildTestLogs() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        AdminCard(
          title: 'Send Test Email',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AdminTextField(
                    label: 'Recipient Address',
                    controller: _testEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    hint: 'recipient@example.com',
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _testSending ? null : _sendTest,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withOpacity(0.4),
                      ),
                    ),
                    child: _testSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF3B82F6),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.science_rounded,
                                color: Color(0xFF3B82F6),
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Send Test',
                                style: TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
        AdminCard(
          title: 'Recent Email Logs (${_logs.length})',
          children: [
            if (_logs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No email logs found.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
              )
            else ...[
              // Table header
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Subject',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Recipient',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        'Status',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ..._logs.take(20).map((log) => _LogRow(log: log)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTemplates() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        AdminCard(
          title: 'Email Templates',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: Colors.grey[700],
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Email Templates',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage notification email templates.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TriggerTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _TriggerTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final Map<String, dynamic> log;
  const _LogRow({required this.log});

  @override
  Widget build(BuildContext context) {
    final status = log['status']?.toString() ?? 'unknown';
    final isSuccess = status == 'sent' || status == 'success';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSuccess
              ? const Color(0xFF22C55E).withOpacity(0.15)
              : const Color(0xFFEF4444).withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              log['subject']?.toString() ?? 'No subject',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log['to']?.toString() ?? '—',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 60,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? const Color(0xFF22C55E).withOpacity(0.15)
                      : const Color(0xFFEF4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isSuccess
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DlgField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  const _DlgField({
    required this.label,
    required this.ctrl,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
            filled: true,
            fillColor: AppTheme.background,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
