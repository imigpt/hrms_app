import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class ProfileCardWidget extends StatelessWidget {
  final String? name;
  final String? role;
  final String? department;
  final String? phone;
  final String? email;
  final String? address;
  final String? dateOfBirth;
  final bool isActive;

  const ProfileCardWidget({
    super.key,
    this.name,
    this.role,
    this.department,
    this.phone,
    this.email,
    this.address,
    this.dateOfBirth,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar and basic info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Name, role, and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'User Name',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${role ?? 'Role'} • ${department ?? 'Department'}',
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Status badge
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          // Contact and address info
          _buildInfoRow(
            Icons.phone_outlined,
            phone ?? 'N/A',
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.email_outlined,
            email ?? 'N/A',
            Colors.cyan,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.home_outlined,
            address ?? 'N/A',
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            dateOfBirth != null
                ? DateFormat('MMMM d, yyyy').format(DateTime.parse(dateOfBirth!))
                : 'N/A',
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey.withOpacity(0.8),
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
