import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/features/profile/data/models/profile_model.dart';
import 'package:hrms_app/features/announcements/presentation/screens/announcements_screen.dart';
import 'package:hrms_app/features/leave/presentation/screens/apply_leave_screen.dart';
import 'package:hrms_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:hrms_app/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:hrms_app/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:hrms_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:hrms_app/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:hrms_app/features/tasks/presentation/screens/bod_eod_screen.dart';
import 'package:hrms_app/features/tasks/presentation/screens/task_management_screen.dart';
import 'package:hrms_app/features/auth/presentation/screens/login_screen.dart';
import 'package:hrms_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:hrms_app/shared/services/communication/notification_service.dart';
import 'package:hrms_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:hrms_app/features/payroll/presentation/screens/payroll_screen.dart';
import 'package:hrms_app/features/policies/presentation/screens/policies_screen.dart';
import 'package:hrms_app/features/payroll/presentation/screens/pre_payments_screen.dart';
import 'package:hrms_app/features/admin/presentation/screens/employee_management/increment_promotion_screen.dart';
import 'package:hrms_app/features/payroll/presentation/screens/my_salary_screen.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';
import 'package:hrms_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:hrms_app/features/admin/presentation/screens/employee_management/hr_accounts_screen.dart';
import 'package:hrms_app/features/admin/presentation/screens/employee_management/all_employees_screen.dart';
import 'package:hrms_app/features/leave/presentation/screens/leave_management_screen.dart';
import 'package:hrms_app/features/leave/presentation/screens/leave_balance_screen.dart';
import 'package:hrms_app/features/admin/presentation/screens/clients/all_clients_screen.dart';
import 'package:hrms_app/features/admin/presentation/screens/admin_attendance_screen.dart';
import 'package:hrms_app/features/payroll/presentation/screens/admin_salary_screen.dart';
import 'package:hrms_app/features/admin/presentation/screens/edit_requests_screen.dart';
import 'package:hrms_app/features/admin/presentation/screens/company_management/all_companies_screen.dart';
import 'package:hrms_app/features/admin/presentation/screens/calendar_screen/calendar_screen.dart';

class SidebarMenu extends StatefulWidget {
  final ProfileUser? user;
  final String? token;

  const SidebarMenu({super.key, this.user, this.token});

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  int _selectedIndex = 0;
  bool _payrollExpanded = false;
  bool _leavesExpanded = false;
  bool _attendanceExpanded = false;
  bool _tasksExpanded = false;
  late String _userRole;

  @override
  void initState() {
    super.initState();
    // Determine user role
    final roleStr = widget.user?.role.toLowerCase().trim() ?? '';
    print('[SIDEBAR] 🔍 Raw role from widget.user: "${widget.user?.role}"');
    print('[SIDEBAR] 🔍 Processed roleStr (lowercase trim): "$roleStr"');

    if (roleStr == 'admin') {
      _userRole = 'admin';
      print('[SIDEBAR] ✅ User role set to: ADMIN');
    } else if (roleStr == 'hr') {
      _userRole = 'hr';
      print('[SIDEBAR] ✅ User role set to: HR');
    } else if (roleStr == 'client') {
      _userRole = 'client';
      print('[SIDEBAR] ✅ User role set to: CLIENT');
    } else {
      _userRole = 'employee';
      print(
        '[SIDEBAR] ⚠️ User role defaulted to: EMPLOYEE (received role was: "$roleStr")',
      );
    }
  }

  late final List<Map<String, dynamic>> _employeeMenuItems = [
    {"title": "Dashboard", "icon": Icons.grid_view_rounded},
    {"title": "My Profile", "icon": Icons.person_rounded},
    {"title": "Attendance", "icon": Icons.schedule_rounded},
    {"title": "Calendar", "icon": Icons.event_rounded},
    {"title": "Tasks", "icon": Icons.task_alt_rounded, "hasSubmenu": true},
    {"title": "Expenses", "icon": Icons.account_balance_wallet_rounded},
    {"title": "Chat", "icon": Icons.chat_bubble_rounded},
    {"title": "Announcements", "icon": Icons.campaign_rounded},
    {"title": "Company Policy", "icon": Icons.policy_rounded},
    {"title": "Payroll", "icon": Icons.payments_rounded, "hasSubmenu": true},
    {"title": "Settings", "icon": Icons.settings_rounded},
  ];

  late final List<Map<String, dynamic>> _adminMenuItems = [
    {"title": "Dashboard", "icon": Icons.grid_view_rounded},
    {"title": "HR Accounts", "icon": Icons.manage_accounts_rounded},
    {"title": "Employees", "icon": Icons.people_rounded},
    {"title": "Companies", "icon": Icons.apartment_rounded},
    // {"title": "Clients", "icon": Icons.people_outline_rounded},
    {"title": "Attendance", "icon": Icons.schedule_rounded, "hasSubmenu": true},
    {
      "title": "Leaves",
      "icon": Icons.calendar_month_rounded,
      "hasSubmenu": true,
    },
    {"title": "Calendar", "icon": Icons.event_rounded},
    {"title": "Tasks", "icon": Icons.task_alt_rounded, "hasSubmenu": true},
    {"title": "Expenses", "icon": Icons.account_balance_wallet_rounded},
    {"title": "Chat", "icon": Icons.chat_bubble_rounded},
    {"title": "Announcements", "icon": Icons.campaign_rounded},
    {"title": "Company Policy", "icon": Icons.policy_rounded},
    {"title": "Payroll", "icon": Icons.payments_rounded, "hasSubmenu": true},
    {"title": "Settings", "icon": Icons.settings_rounded},
  ];

  late final List<Map<String, dynamic>> _hrMenuItems = [
    {"title": "Dashboard", "icon": Icons.grid_view_rounded},
    {"title": "My Profile", "icon": Icons.person_rounded},
    {"title": "Employees", "icon": Icons.people_rounded},
    // {"title": "Clients", "icon": Icons.people_outline_rounded},
    {"title": "Attendance", "icon": Icons.schedule_rounded, "hasSubmenu": true},
    {
      "title": "Leaves",
      "icon": Icons.calendar_month_rounded,
      "hasSubmenu": true,
    },
    {"title": "Calendar", "icon": Icons.event_rounded},
    {"title": "Tasks", "icon": Icons.task_alt_rounded, "hasSubmenu": true},
    {"title": "Expenses", "icon": Icons.account_balance_wallet_rounded},
    {"title": "Chat", "icon": Icons.chat_bubble_rounded},
    {"title": "Announcements", "icon": Icons.campaign_rounded},
    {"title": "Company Policy", "icon": Icons.policy_rounded},
    {"title": "Payroll", "icon": Icons.payments_rounded, "hasSubmenu": true},
    {"title": "Settings", "icon": Icons.settings_rounded},
  ];

  late final List<Map<String, dynamic>> _attendanceSubItems = [
    {"title": "Attendance", "icon": Icons.schedule_rounded},
    {"title": "Edit Requests", "icon": Icons.description_rounded},
  ];

  late final List<Map<String, dynamic>> _hrAttendanceSubItems = [
    {"title": "Attendance", "icon": Icons.schedule_rounded},
    {"title": "My Attendance", "icon": Icons.assignment_rounded},
    {"title": "Edit Requests", "icon": Icons.description_rounded},
    {"title": "My Edit Requests", "icon": Icons.edit_rounded},
  ];

  // Menu for client users (minimal)
  late final List<Map<String, dynamic>> _clientMenuItems = [
    {"title": "Dashboard", "icon": Icons.grid_view_rounded},
    {"title": "Chat", "icon": Icons.chat_bubble_rounded},
    {"title": "Notifications", "icon": Icons.notifications_rounded},
  ];

  late final List<Map<String, dynamic>> _leavesSubItems = [
    {"title": "Employee Leaves", "icon": Icons.calendar_month_rounded},
    {"title": "My Leaves", "icon": Icons.assignment_rounded},
  ];

  late final List<Map<String, dynamic>> _adminLeavesSubItems = [
    {"title": "Leaves", "icon": Icons.calendar_month_rounded},
    {"title": "Leaves Management", "icon": Icons.assignment_rounded},
  ];

  late final List<Map<String, dynamic>> _adminTasksSubItems = [
    {"title": "Tasks", "icon": Icons.task_alt_rounded},
    {"title": "BOD/EOD", "icon": Icons.event_note_rounded},
  ];

  late final List<Map<String, dynamic>> _employeeTasksSubItems = [
    {"title": "Task Management", "icon": Icons.assignment_rounded},
    {"title": "Tasks", "icon": Icons.task_alt_rounded},
    {"title": "BOD/EOD", "icon": Icons.event_note_rounded},
  ];

  late final List<Map<String, dynamic>> _hrTasksSubItems = [
    {"title": "Employee Tasks", "icon": Icons.task_alt_rounded},
    {"title": "My Tasks", "icon": Icons.assignment_rounded},
    {"title": "BOD/EOD", "icon": Icons.event_note_rounded},
  ];

  /// Get payroll sub items based on user role
  /// Employee: Pre Payments, Increment/Promotion, Payroll, My Salary
  /// Admin: Pre Payments, Increment/Promotion, Payroll, Salary Management
  List<Map<String, dynamic>> get _payrollSubItems {
    final items = [
      {"title": "Pre Payments", "icon": Icons.payment_rounded},
      {"title": "Increment/Promotion", "icon": Icons.trending_up_rounded},
      {"title": "Payroll", "icon": Icons.payments_rounded},
    ];
    // Add My Salary for employees, Salary Management for admin
    if (_userRole == 'admin') {
      items.add({
        "title": "Employee Salary",
        "icon": Icons.admin_panel_settings_rounded,
      });
    } else {
      items.add({"title": "My Salary", "icon": Icons.money_rounded});
    }
    return items;
  }

  /// Get the appropriate menu items based on user role
  List<Map<String, dynamic>> get _menuItems {
    if (_userRole == 'admin') return _adminMenuItems;
    if (_userRole == 'hr') return _hrMenuItems;
    if (_userRole == 'client') return _clientMenuItems;
    return _employeeMenuItems;
  }

  @override
  Widget build(BuildContext context) {
    // Deep dark theme background
    return Container(
      color: const Color(0xFF050505),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // --- LOGO AREA ---
          _buildLogo(context),

          const SizedBox(height: 50),

          // --- MENU ITEMS ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Build all menu items in order
                ..._menuItems.asMap().entries.map((entry) {
                  int idx = entry.key;
                  Map<String, dynamic> menuItem = entry.value;

                  // If this is Attendance with submenu (admin and hr)
                  if (menuItem['title'] == 'Attendance' &&
                      menuItem['hasSubmenu'] == true &&
                      (_userRole == 'admin' || _userRole == 'hr')) {
                    final subItems = _userRole == 'hr'
                        ? _hrAttendanceSubItems
                        : _attendanceSubItems;
                    return Column(
                      children: [
                        _buildMenuItemWithSubmenu(
                          context,
                          index: idx,
                          title: menuItem['title'],
                          icon: menuItem['icon'],
                          isExpanded: _attendanceExpanded,
                        ),
                        // Insert submenu items right after Attendance
                        if (_attendanceExpanded)
                          ...subItems.asMap().entries.map((subEntry) {
                            int subIdx = subEntry.key;
                            return _buildAttendanceSubMenuItem(
                              context,
                              subIdx,
                              subItems,
                            );
                          }).toList(),
                      ],
                    );
                  }

                  // If this is Payroll with submenu
                  if (menuItem['title'] == 'Payroll' &&
                      menuItem['hasSubmenu'] == true) {
                    return Column(
                      children: [
                        _buildMenuItemWithSubmenu(
                          context,
                          index: idx,
                          title: menuItem['title'],
                          icon: menuItem['icon'],
                          isExpanded: _payrollExpanded,
                        ),
                        // Insert submenu items right after Payroll
                        if (_payrollExpanded)
                          ..._payrollSubItems.asMap().entries.map((subEntry) {
                            int subIdx = subEntry.key;
                            return _buildPayrollSubMenuItem(context, subIdx);
                          }).toList(),
                      ],
                    );
                  }

                  // If this is Leaves with submenu
                  if (menuItem['title'] == 'Leaves' &&
                      menuItem['hasSubmenu'] == true) {
                    final subItems = _userRole == 'admin'
                        ? _adminLeavesSubItems
                        : _leavesSubItems;
                    return Column(
                      children: [
                        _buildMenuItemWithSubmenu(
                          context,
                          index: idx,
                          title: menuItem['title'],
                          icon: menuItem['icon'],
                          isExpanded: _leavesExpanded,
                        ),
                        // Insert submenu items right after Leaves
                        if (_leavesExpanded)
                          ...subItems.asMap().entries.map((subEntry) {
                            int subIdx = subEntry.key;
                            return _buildLeavesSubMenuItem(
                              context,
                              subIdx,
                              subItems,
                            );
                          }).toList(),
                      ],
                    );
                  }

                  // If this is Tasks with submenu
                  if (menuItem['title'] == 'Tasks' &&
                      menuItem['hasSubmenu'] == true) {
                    final subItems = _userRole == 'admin'
                        ? _adminTasksSubItems
                        : _userRole == 'hr'
                        ? _hrTasksSubItems
                        : _employeeTasksSubItems;
                    return Column(
                      children: [
                        _buildMenuItemWithSubmenu(
                          context,
                          index: idx,
                          title: menuItem['title'],
                          icon: menuItem['icon'],
                          isExpanded: _tasksExpanded,
                        ),
                        // Insert submenu items right after Tasks
                        if (_tasksExpanded)
                          ...subItems.asMap().entries.map((subEntry) {
                            int subIdx = subEntry.key;
                            return _buildTasksSubMenuItem(
                              context,
                              subIdx,
                              subItems,
                            );
                          }).toList(),
                      ],
                    );
                  }

                  // Regular menu item
                  return _buildMenuItem(
                    context,
                    index: idx,
                    title: menuItem['title'],
                    icon: menuItem['icon'],
                  );
                }).toList(),
              ],
            ),
          ),

          // --- PROFILE SUMMARY ---
          _buildProfileSummary(),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          SizedBox(
            height: 60,
            width: 80,
            child: Image.asset(
              'assets/images/aselea-logo.jpeg',
              height: 50,
              width: 70,
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            "Aselea",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemWithSubmenu(
    BuildContext context, {
    required int index,
    required String title,
    required IconData icon,
    required bool isExpanded,
  }) {
    Color primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (title == 'Payroll') {
                _payrollExpanded = !_payrollExpanded;
              } else if (title == 'Leaves') {
                _leavesExpanded = !_leavesExpanded;
              } else if (title == 'Attendance') {
                _attendanceExpanded = !_attendanceExpanded;
              } else if (title == 'Tasks') {
                _tasksExpanded = !_tasksExpanded;
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withOpacity(0.03),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isExpanded
                  ? primaryColor.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isExpanded
                  ? Border.all(color: primaryColor.withOpacity(0.1), width: 1)
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isExpanded ? primaryColor : Colors.grey[600],
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isExpanded ? Colors.white : Colors.grey[500],
                      fontWeight: isExpanded
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: isExpanded
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
                    size: 20,
                  ),
                ),
                if (isExpanded) const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPayrollSubMenuItem(BuildContext context, int index) {
    final subItem = _payrollSubItems[index];
    Color primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handlePayrollSubMenuClick(context, subItem['title']),
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.white.withOpacity(0.03),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(subItem['icon'], color: Colors.grey[500], size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subItem['title'],
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeavesSubMenuItem(
    BuildContext context,
    int index,
    List<Map<String, dynamic>> subItems,
  ) {
    final subItem = subItems[index];
    Color primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleLeavesSubMenuClick(context, subItem['title']),
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.white.withOpacity(0.03),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(subItem['icon'], color: Colors.grey[500], size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subItem['title'],
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceSubMenuItem(
    BuildContext context,
    int index,
    List<Map<String, dynamic>> subItems,
  ) {
    final subItem = subItems[index];
    Color primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleAttendanceSubMenuClick(context, subItem['title']),
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.white.withOpacity(0.03),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(subItem['icon'], color: Colors.grey[500], size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subItem['title'],
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTasksSubMenuItem(
    BuildContext context,
    int index,
    List<Map<String, dynamic>> subItems,
  ) {
    final subItem = subItems[index];
    Color primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTasksSubMenuClick(context, subItem['title']),
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.white.withOpacity(0.03),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(subItem['icon'], color: Colors.grey[500], size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subItem['title'],
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required int index,
    required String title,
    required IconData icon,
  }) {
    bool isActive = _selectedIndex == index;
    Color primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleMenuClick(context, index, title),
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withOpacity(0.03),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isActive
                  ? primaryColor.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(color: primaryColor.withOpacity(0.1), width: 1)
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                // Animated Icon
                Icon(
                  icon,
                  color: isActive ? primaryColor : Colors.grey[600],
                  size: 22,
                ),
                const SizedBox(width: 16),

                // Title
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[500],
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                // Active Indicator (Glowing Dot)
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSummary() {
    final userName = widget.user?.name ?? "Rahul Gupta";
    final userRole = widget.user?.role ?? "Employee";

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF1D1D1D),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_outline,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userRole,
                    style: const TextStyle(
                      color: Color(0xFF8A8A8A),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: ListTile(
          visualDensity: VisualDensity.compact,
          leading: Icon(
            Icons.logout_rounded,
            color: Colors.redAccent.shade100,
            size: 20,
          ),
          title: Text(
            "Log Out",
            style: TextStyle(
              color: Colors.redAccent.shade100,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () => _handleLogout(context),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Call logout via AuthNotifier (which updates global auth state)
    final authNotifier = context.read<AuthNotifier>();
    await authNotifier.logout();

    // Remove FCM token from backend (fire-and-forget)
    NotificationService().removeFcmToken(widget.token ?? '').catchError((_) {});

    // Close loading dialog
    if (context.mounted) Navigator.of(context).pop();

    // Navigate to login screen
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // --- LOGIC SECTION ---

  void _handleMenuClick(BuildContext context, int index, String title) {
    setState(() => _selectedIndex = index);

    // Close Drawer if open (Mobile)
    if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
      Navigator.pop(context);
    }

    // Smooth Navigation
    switch (title) {
      case "Dashboard":
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are already on the Dashboard.')),
        );
        break;

      case "My Profile":
        Navigator.of(context).push(
          _createSmoothRoute(
            ProfileScreen(
              user: widget.user,
              token: widget.token,
              role: _userRole,
            ),
          ),
        );
        break;

      case "Attendance":
        // For admin, this is now a submenu parent, do nothing
        // For employee, navigate to attendance screen
        if (_userRole != 'admin') {
          Navigator.of(
            context,
          ).push(_createSmoothRoute(const AttendanceScreen()));
        }
        break;

      case "Tasks":
        Navigator.of(context).push(
          _createSmoothRoute(TasksScreen(token: widget.token, role: _userRole)),
        );
        break;

      case "Expenses":
        Navigator.of(context).push(
          _createSmoothRoute(
            ExpensesScreen(
              role:
                  _userRole, // Pass user's actual role: 'hr', 'employee', or 'admin'
            ),
          ),
        );
        break;

      case "Chat":
        Navigator.of(context).push(_createSmoothRoute(const ChatScreen()));
        break;

      case "Announcements":
        Navigator.of(context).push(
          _createSmoothRoute(
            AnnouncementsScreen(role: _userRole, token: widget.token),
          ),
        );
        break;

      case "Notifications":
        Navigator.of(
          context,
        ).push(_createSmoothRoute(const NotificationsScreen()));
        break;

      case "Company Policy":
        Navigator.of(context).push(
          _createSmoothRoute(
            PoliciesScreen(role: _userRole, token: widget.token),
          ),
        );
        break;

      case "Settings":
        Navigator.of(context).push(
          _createSmoothRoute(
            SettingsScreen(user: widget.user, token: widget.token),
          ),
        );
        break;

      case "Edit Request":
        Navigator.of(
          context,
        ).push(_createSmoothRoute(EditRequestsScreen(token: widget.token)));
        break;

      case "Companies":
        Navigator.of(
          context,
        ).push(_createSmoothRoute(AllCompaniesScreen(token: widget.token)));
        break;

      case "Clients":
        Navigator.of(
          context,
        ).push(_createSmoothRoute(AllClientsScreen(token: widget.token)));
        break;

      case "Employees":
        Navigator.of(context).push(
          _createSmoothRoute(
            AllEmployeesScreen(token: widget.token, role: _userRole),
          ),
        );
        break;

      case "HR Accounts":
        Navigator.of(
          context,
        ).push(_createSmoothRoute(HRAccountsScreen(token: widget.token)));
        break;

      case "Leaves":
        // This is now a submenu parent, do nothing on direct click
        break;

      case "Calendar":
        Navigator.of(context).push(
          _createSmoothRoute(
            AdminCalendarScreen(
              token: widget.token,
              userId: widget.user?.id,
              companyId: null, // Can be selected in calendar screen
            ),
          ),
        );
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This screen is under development.')),
        );
    }
  }

  void _handleAttendanceSubMenuClick(BuildContext context, String title) {
    // Close Drawer if open (Mobile)
    if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
      Navigator.pop(context);
    }

    // Navigate to appropriate attendance subscreen
    if (title == "Attendance") {
      // For admin, view all employees' attendance; for HR, view all
      Navigator.of(
        context,
      ).push(_createSmoothRoute(AdminAttendanceScreen(token: widget.token)));
    } else if (title == "My Attendance") {
      // View own attendance (HR only)
      Navigator.of(
        context,
      ).push(_createSmoothRoute(AttendanceScreen(token: widget.token)));
    } else if (title == "Edit Requests") {
      // View all employees' edit requests
      Navigator.of(context).push(
        _createSmoothRoute(
          EditRequestsScreen(token: widget.token, showOnlyCurrentUser: false),
        ),
      );
    } else if (title == "My Edit Requests") {
      // View own edit requests (HR personal view)
      Navigator.of(context).push(
        _createSmoothRoute(
          EditRequestsScreen(token: widget.token, showOnlyCurrentUser: true),
        ),
      );
    }
  }

  void _handlePayrollSubMenuClick(BuildContext context, String title) {
    // Close Drawer if open (Mobile)
    if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
      Navigator.pop(context);
    }

    // Navigate to appropriate payroll subscreen
    if (title == "Pre Payments") {
      Navigator.of(context).push(_createSmoothRoute(const PrePaymentsScreen()));
    } else if (title == "Increment/Promotion") {
      Navigator.of(
        context,
      ).push(_createSmoothRoute(const IncrementPromotionScreen()));
    } else if (title == "Payroll") {
      Navigator.of(context).push(_createSmoothRoute(const PayrollScreen()));
    } else if (title == "My Salary") {
      Navigator.of(context).push(_createSmoothRoute(const MySalaryScreen()));
    } else if (title == "Employee Salary") {
      Navigator.of(
        context,
      ).push(_createSmoothRoute(AdminSalaryScreen(token: widget.token)));
    }
  }

  void _handleLeavesSubMenuClick(BuildContext context, String title) {
    // Close Drawer if open (Mobile)
    if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
      Navigator.pop(context);
    }

    // Navigate to appropriate leaves subscreen
    if (title == "Leaves") {
      // Leaves (Admin)
      Navigator.of(
        context,
      ).push(_createSmoothRoute(const LeaveManagementScreen()));
    } else if (title == "Leaves Management") {
      // Leaves Management (Admin)
      Navigator.of(
        context,
      ).push(_createSmoothRoute(const LeaveBalanceScreen()));
    } else if (title == "Employee Leaves") {
      // Employee Leaves (HR)
      Navigator.of(
        context,
      ).push(_createSmoothRoute(const LeaveManagementScreen()));
    } else if (title == "My Leaves") {
      // My Leaves (HR)
      Navigator.of(context).push(_createSmoothRoute(const LeaveScreen()));
    }
  }

  void _handleTasksSubMenuClick(BuildContext context, String title) {
    // Close Drawer if open (Mobile)
    if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
      Navigator.pop(context);
    }

    // Navigate to appropriate tasks subscreen
    if (title == "Task Management") {
      // View task management dashboard (Admin only)
      Navigator.of(
        context,
      ).push(_createSmoothRoute(TaskManagementScreen(token: widget.token)));
    } else if (title == "Tasks" || title == "Employee Tasks") {
      // View all employee tasks (Admin/HR)
      Navigator.of(context).push(
        _createSmoothRoute(TasksScreen(token: widget.token, role: _userRole)),
      );
    } else if (title == "My Tasks") {
      // View only current user's tasks (HR only)
      Navigator.of(context).push(
        _createSmoothRoute(
          TasksScreen(
            token: widget.token,
            role: _userRole,
            showOnlyCurrentUser: true,
          ),
        ),
      );
    } else if (title == "BOD/EOD") {
      Navigator.of(context).push(
        _createSmoothRoute(BodEodScreen(token: widget.token, role: _userRole)),
      );
    }
  }

  // --- CUSTOM SMOOTH ROUTE ANIMATION ---
  Route _createSmoothRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Defines the animation curve
        const curve = Curves.easeOutQuart;

        // 1. Slide from right (slightly)
        var slideTween = Tween(
          begin: const Offset(0.05, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: curve));

        // 2. Fade in
        var fadeTween = Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(slideTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(
        milliseconds: 600,
      ), // Slower = Smoother
    );
  }
}
