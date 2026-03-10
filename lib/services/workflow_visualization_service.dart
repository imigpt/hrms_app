// lib/services/workflow_visualization_service.dart
// Workflow Visualization Service
// Handles workflow step visualization, status tracking, and step completion logic

import 'package:flutter/material.dart';

class WorkflowVisualizationService {
  /// Get step status color based on step state
  static Color getStepStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return const Color(0xFF00C853); // Green
      case 'active':
      case 'current':
      case 'in_progress':
        return const Color(0xFF2196F3); // Blue
      case 'pending':
      case 'todo':
      case 'upcoming':
        return const Color(0xFF9E9E9E); // Grey
      case 'skipped':
        return const Color(0xFFFF9800); // Orange
      case 'blocked':
      case 'failed':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Get step status icon based on step state
  static IconData getStepStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return Icons.check_circle;
      case 'active':
      case 'current':
      case 'in_progress':
        return Icons.schedule;
      case 'pending':
      case 'todo':
      case 'upcoming':
        return Icons.radio_button_unchecked;
      case 'skipped':
        return Icons.skip_next;
      case 'blocked':
      case 'failed':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  /// Calculate workflow progress percentage
  static double calculateProgress(List<dynamic> steps) {
    if (steps.isEmpty) return 0.0;
    
    final completedCount = steps
        .where((s) {
          final status = s['status'] ?? s['stepStatus'] ?? 'pending';
          return status.toString().toLowerCase() == 'completed';
        })
        .length;
    
    return (completedCount / steps.length).clamp(0.0, 1.0);
  }

  /// Get current active step index
  static int getCurrentStepIndex(List<dynamic> steps) {
    for (int i = 0; i < steps.length; i++) {
      final status = steps[i]['status'] ?? steps[i]['stepStatus'] ?? 'pending';
      if (status.toString().toLowerCase() == 'active' || 
          status.toString().toLowerCase() == 'current' ||
          status.toString().toLowerCase() == 'in_progress') {
        return i;
      }
    }
    // If no active step, return first incomplete step
    for (int i = 0; i < steps.length; i++) {
      final status = steps[i]['status'] ?? steps[i]['stepStatus'] ?? 'pending';
      if (status.toString().toLowerCase() != 'completed') {
        return i;
      }
    }
    return steps.length - 1;
  }

  /// Get step status label for UI
  static String getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return 'Completed';
      case 'active':
      case 'current':
      case 'in_progress':
        return 'Active';
      case 'pending':
      case 'todo':
      case 'upcoming':
        return 'Pending';
      case 'skipped':
        return 'Skipped';
      case 'blocked':
        return 'Blocked';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  /// Format role name for display
  static String formatRoleName(dynamic role) {
    if (role == null) return 'Any';
    if (role is String) {
      return role
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
          .join(' ');
    }
    return 'Any';
  }

  /// Get role badge color
  static Color getRoleColor(String role) {
    final normalized = role.toLowerCase();
    switch (normalized) {
      case 'hr':
      case 'hr_manager':
        return const Color(0xFFFF8FA3); // Pink
      case 'admin':
      case 'superadmin':
        return const Color(0xFF651FFF); // Purple
      case 'employee':
      case 'staff':
        return const Color(0xFF2196F3); // Blue
      case 'manager':
      case 'supervisor':
        return const Color(0xFFFFAB00); // Orange
      case 'any':
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Check if current user can complete a step based on role
  static bool canCompleteStep(String requiredRole, String? userRole) {
    if (userRole == null) return false;
    if (requiredRole.toLowerCase() == 'any') return true;
    return userRole.toLowerCase() == requiredRole.toLowerCase() ||
        userRole.toLowerCase() == 'admin' ||
        userRole.toLowerCase() == 'superadmin';
  }

  /// Build workflow step summary
  static Map<String, dynamic> buildStepSummary(Map<String, dynamic> step, int index) {
    return {
      'index': index,
      'title': step['title'] ?? 'Step ${index + 1}',
      'description': step['description'] ?? '',
      'role': step['responsibleRole'] ?? step['requiredRole'] ?? 'any',
      'status': step['status'] ?? step['stepStatus'] ?? 'pending',
      'dueDate': step['dueDate'],
      'approvalRequired': step['approvalRequired'] ?? false,
      'completedBy': step['completedBy'],
      'completedAt': step['completedAt'],
      'comment': step['comment'],
    };
  }

  /// Get workflow state summary
  static String getWorkflowStateSummary(
    List<dynamic> steps, {
    int? currentStepIndex,
  }) {
    if (steps.isEmpty) return 'Empty workflow';
    
    final current = currentStepIndex ?? getCurrentStepIndex(steps);
    final total = steps.length;
    final completed = steps
        .where((s) {
          final status = s['status'] ?? s['stepStatus'] ?? 'pending';
          return status.toString().toLowerCase() == 'completed';
        })
        .length;
    
    if (completed == total) {
      return 'Workflow completed';
    } else if (current < total) {
      return 'Step ${current + 1} of $total';
    } else {
      return 'All steps completed';
    }
  }
}
