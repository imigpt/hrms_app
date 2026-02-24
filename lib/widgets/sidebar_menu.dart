import 'package:flutter/material.dart';
import 'package:hrms_app/models/profile_model.dart';
import 'package:hrms_app/screen/announcements_screen.dart';
import 'package:hrms_app/screen/attendance_screen.dart';
import 'package:hrms_app/screen/expenses_screen.dart';
import 'package:hrms_app/screen/profile_screen.dart';
import 'package:hrms_app/screen/tasks_screen.dart';
import 'package:hrms_app/screen/login_screen.dart';
import 'package:hrms_app/services/auth_service.dart';
import 'package:hrms_app/services/token_storage_service.dart';
import 'package:hrms_app/screen/chat_screen.dart';
import 'package:hrms_app/screen/payroll_screen.dart';
import 'package:hrms_app/screen/policies_screen.dart';
import 'package:hrms_app/screen/pre_payments_screen.dart';
import 'package:hrms_app/screen/increment_promotion_screen.dart';
import 'package:hrms_app/screen/my_salary_screen.dart';
import 'package:hrms_app/theme/app_theme.dart';
import 'package:hrms_app/screen/settings_screen.dart';

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

  final List<Map<String, dynamic>> _menuItems = [
    {"title": "Dashboard", "icon": Icons.grid_view_rounded},
    {"title": "My Profile", "icon": Icons.person_rounded},
    {"title": "Attendance", "icon": Icons.schedule_rounded},
    {"title": "Tasks", "icon": Icons.task_alt_rounded},
    {"title": "Expenses", "icon": Icons.account_balance_wallet_rounded},
    {"title": "Chat", "icon": Icons.chat_bubble_rounded},
    {"title": "Announcements", "icon": Icons.campaign_rounded},
    {"title": "Payroll", "icon": Icons.payments_rounded, "hasSubmenu": true},
    {"title": "Policies", "icon": Icons.policy_rounded},
    {"title": "Settings", "icon": Icons.settings_rounded},
  ];

  final List<Map<String, dynamic>> _payrollSubItems = [
    {"title": "Pre Payments", "icon": Icons.payment_rounded},
    {"title": "Increment/Promotion", "icon": Icons.trending_up_rounded},
    {"title": "Payroll", "icon": Icons.payments_rounded},
    {"title": "My Salary", "icon": Icons.money_rounded},
  ];

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
                  
                  // If this is Payroll with submenu
                  if (menuItem['title'] == 'Payroll' && menuItem['hasSubmenu'] == true) {
                    return Column(
                      children: [
                        _buildMenuItemWithSubmenu(
                          context, 
                          index: idx,
                          title: menuItem['title'], 
                          icon: menuItem['icon']
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
                  
                  // Regular menu item
                  return _buildMenuItem(
                    context, 
                    index: idx,
                    title: menuItem['title'], 
                    icon: menuItem['icon']
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
            height: 40,
            width: 40,
            child: Image.asset('assets/images/aselea-logo.png', height: 50, width: 70),
          ),
          const SizedBox(width: 14),
          const Text(
            "Aselea", 
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.w700, 
              letterSpacing: 0.8,
              color: Colors.white
            )
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemWithSubmenu(BuildContext context, {
    required int index, 
    required String title, 
    required IconData icon
  }) {
    Color primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _payrollExpanded = !_payrollExpanded);
          },
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withOpacity(0.03),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _payrollExpanded ? primaryColor.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: _payrollExpanded 
                  ? Border.all(color: primaryColor.withOpacity(0.1), width: 1)
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(
                  icon, 
                  color: _payrollExpanded ? primaryColor : Colors.grey[600],
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title, 
                    style: TextStyle(
                      color: _payrollExpanded ? Colors.white : Colors.grey[500],
                      fontWeight: _payrollExpanded ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    )
                  ),
                ),
                AnimatedRotation(
                  turns: _payrollExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: _payrollExpanded ? Theme.of(context).primaryColor : Colors.grey[600],
                    size: 20,
                  ),
                ),
                if (_payrollExpanded)
                  const SizedBox(width: 8)
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
                Icon(
                  subItem['icon'],
                  color: Colors.grey[500],
                  size: 18,
                ),
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

  Widget _buildMenuItem(BuildContext context, {
    required int index, 
    required String title, 
    required IconData icon
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
              color: isActive ? primaryColor.withOpacity(0.12) : Colors.transparent,
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
                    )
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
                        BoxShadow(color: primaryColor.withOpacity(0.6), blurRadius: 6, spreadRadius: 1)
                      ]
                    )
                  )
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
                child: Icon(Icons.person_outline, size: 18, color: AppTheme.primaryColor),
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
          leading: Icon(Icons.logout_rounded, color: Colors.redAccent.shade100, size: 20),
          title: Text(
            "Log Out",
            style: TextStyle(color: Colors.redAccent.shade100, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          onTap: () => _handleLogout(context),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final tokenStorage = TokenStorageService();
    
    if (widget.token == null) {
      // Clear any stored data and navigate to login
      await tokenStorage.clearLoginData();
      
      if (!context.mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Call logout API
    final authService = AuthService();
    final success = await authService.logout(widget.token!);

    // Clear stored token and user data
    await tokenStorage.clearLoginData();

    // Close loading dialog
    if (context.mounted) Navigator.of(context).pop();

    // Navigate to login screen
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

      // Show success/failure message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Logged out successfully' : 'Logout completed'),
          backgroundColor: success ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
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
    if (title == "My Profile") {
      Navigator.of(context).push(
        _createSmoothRoute(ProfileScreen(user: widget.user, token: widget.token)),
      );
    } else if (title == "Attendance") {
      Navigator.of(context).push(_createSmoothRoute(const AttendanceScreen()));
    } else if (title == "Tasks") {
      Navigator.of(context).push(_createSmoothRoute(const TasksScreen()));
    } else if (title == "Expenses") {
      Navigator.of(context).push(_createSmoothRoute(const ExpensesScreen()));
    } else if (title == "Announcements") {
      Navigator.of(context).push(_createSmoothRoute(const AnnouncementsScreen()));
    } else if (title == "Chat") {
      Navigator.of(context).push(_createSmoothRoute(const ChatScreen()));
    } else if (title == "Policies") {
      Navigator.of(context).push(_createSmoothRoute(const PoliciesScreen()));
    } else if (title == "Settings") {
      Navigator.of(context).push(_createSmoothRoute(
        SettingsScreen(user: widget.user, token: widget.token),
      ));
    } else {
      // For Dashboard and any other unimplemented screens
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This screen is under development.')),
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
      Navigator.of(context).push(_createSmoothRoute(const IncrementPromotionScreen()));
    } else if (title == "Payroll") {
      Navigator.of(context).push(_createSmoothRoute(const PayrollScreen()));
    } else if (title == "My Salary") {
      Navigator.of(context).push(_createSmoothRoute(const MySalaryScreen()));
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
        var slideTween = Tween(begin: const Offset(0.05, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: curve));
            
        // 2. Fade in
        var fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(slideTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 600), // Slower = Smoother
    );
  }
}