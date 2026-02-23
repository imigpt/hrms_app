import 'package:flutter/material.dart';
import 'package:hrms_app/services/token_storage_service.dart';
import 'package:hrms_app/widgets/dashboard_stats_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hrms_app/theme/app_theme.dart';

class DashboardQuickStatsSection extends StatefulWidget {
  final String? userId;

  const DashboardQuickStatsSection({
    super.key,
    this.userId,
  });

  @override
  State<DashboardQuickStatsSection> createState() =>
      _DashboardQuickStatsSectionState();
}

class _DashboardQuickStatsSectionState
    extends State<DashboardQuickStatsSection> {
  bool _isLoading = true;
  String? _error;

  int _appreciations = 0;
  int _warnings = 0;
  int _expenses = 0;
  int _complaints = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final token = await TokenStorageService().getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Fetch all stats in parallel
      final results = await Future.wait([
        _fetchAppreciations(token),
        _fetchWarnings(token),
        _fetchExpenses(token),
        _fetchComplaints(token),
      ]);

      setState(() {
        _appreciations = results[0];
        _warnings = results[1];
        _expenses = results[2];
        _complaints = results[3];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<int> _fetchAppreciations(String token) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://hrms-backend-zzzc.onrender.com/api/appreciations'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is List) {
          return data['data'].length;
        }
      }
      return 0;
    } catch (e) {
      print('Error fetching appreciations: $e');
      return 0;
    }
  }

  Future<int> _fetchWarnings(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://hrms-backend-zzzc.onrender.com/api/warnings'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is List) {
          return data['data'].length;
        }
      }
      return 0;
    } catch (e) {
      print('Error fetching warnings: $e');
      return 0;
    }
  }

  Future<int> _fetchExpenses(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://hrms-backend-zzzc.onrender.com/api/expenses'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is Map) {
          // Sum total amount from expenses
          int total = 0;
          final expenses = data['data'];
          if (expenses is Map) {
            expenses.forEach((key, value) {
              if (value is Map && value.containsKey('amount')) {
                total += (value['amount'] as num?)?.toInt() ?? 0;
              } else if (value is List) {
                for (var expense in value) {
                  if (expense is Map && expense.containsKey('amount')) {
                    total += (expense['amount'] as num?)?.toInt() ?? 0;
                  }
                }
              }
            });
          }
          return total;
        } else if (data['data'] is List) {
          int total = 0;
          for (var expense in data['data']) {
            total += (expense['amount'] as num?)?.toInt() ?? 0;
          }
          return total;
        }
      }
      return 0;
    } catch (e) {
      print('Error fetching expenses: $e');
      return 0;
    }
  }

  Future<int> _fetchComplaints(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://hrms-backend-zzzc.onrender.com/api/complaints'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is List) {
          return data['data'].length;
        }
      }
      return 0;
    } catch (e) {
      print('Error fetching complaints: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      children: [
        if (_isLoading)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          )
        else if (_error != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.red, size: 20),
                  onPressed: _loadStats,
                )
              ],
            ),
          )
        else
          GridView(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : 4,
              childAspectRatio: isMobile ? 1.4 : 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              DashboardStatsCard(
                value: _appreciations,
                label: 'Appreciations',
                icon:Icons.accessibility,
                iconColor: const Color(0xFFB66FD9),
                backgroundColor: const Color(0xFFB66FD9),
              ),
              DashboardStatsCard(
                value: _warnings,
                label: 'Warnings',
                icon: Icons.warning_outlined,
                iconColor: const Color(0xFFFFC107),
                backgroundColor: const Color(0xFFFFC107),
              ),
              DashboardStatsCard(
                value: _expenses,
                label: 'Expenses',
                icon: Icons.currency_rupee_outlined,
                iconColor: const Color(0xFF3B82F6),
                backgroundColor: const Color(0xFF3B82F6),
              ),
              DashboardStatsCard(
                value: _complaints,
                label: 'Complaints',
                icon: Icons.chat_bubble_outline,
                iconColor: const Color(0xFF8B4356),
                backgroundColor: const Color(0xFF8B4356),
              ),
            ],
          ),
      ],
    );
  }
}
