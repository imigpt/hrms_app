import 'package:flutter/material.dart';
import 'package:hrms_app/screen/announcements_screen.dart';
import 'package:hrms_app/screen/attendance_screen.dart';
import 'package:hrms_app/screen/expenses_screen.dart';
import 'package:hrms_app/screen/profile_screen.dart';
import 'package:hrms_app/screen/tasks_screen.dart';

class SidebarMenu extends StatefulWidget {
  const SidebarMenu({super.key});

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _menuItems = [
    {"title": "Dashboard", "icon": Icons.grid_view_rounded},
    {"title": "My Profile", "icon": Icons.person_rounded},
    {"title": "Attendance", "icon": Icons.schedule_rounded},
    {"title": "Tasks", "icon": Icons.task_alt_rounded},
    {"title": "Expenses", "icon": Icons.account_balance_wallet_rounded},
    {"title": "Chat", "icon": Icons.chat_bubble_rounded},
    {"title": "Announcements", "icon": Icons.campaign_rounded},
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                return _buildMenuItem(
                  context, 
                  index: index,
                  title: _menuItems[index]['title'], 
                  icon: _menuItems[index]['icon']
                );
              },
            ),
          ),
          
          // --- BOTTOM ACTION ---
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
            child: Image.asset('assets/images/aselea-logo.png', height: 24, width: 44),
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
          leading: Icon(Icons.logout_rounded, color: Colors.redAccent.shade200, size: 20),
          title: Text(
            "Log Out", 
            style: TextStyle(color: Colors.redAccent.shade100, fontSize: 14, fontWeight: FontWeight.w500)
          ),
          onTap: () {
            // Add logout logic
          },
        ),
      ),
    );
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
      Navigator.of(context).push(_createSmoothRoute(const ProfileScreen()));
    } else if (title == "Attendance") {
      Navigator.of(context).push(_createSmoothRoute(const AttendanceScreen()));
    } else if (title == "Tasks") {
      Navigator.of(context).push(_createSmoothRoute(const TasksScreen()));
    } else if (title == "Expenses") {
      Navigator.of(context).push(_createSmoothRoute(const ExpensesScreen()));
    } else if (title == "Announcements") {
      Navigator.of(context).push(_createSmoothRoute(const AnnouncementsScreen()));
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