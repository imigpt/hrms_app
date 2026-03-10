// lib/widgets/workflow_tab_widget.dart
// Workflow Tab Widget for Task Detail Dialog

import 'package:flutter/material.dart';
import '../services/workflow_visualization_service.dart';
import '../services/workflow_service.dart';

class WorkflowTabWidget extends StatelessWidget {
  final Map<String, dynamic> taskData;
  final String? token;
  final Color statusGreen;
  final Color statusPink;
  final Color statusOrange;
  final Color textGrey;
  final Color inputDark;
  final Function() onStepCompleted;
  final String Function(String) formatDate;

  const WorkflowTabWidget({
    super.key,
    required this.taskData,
    required this.token,
    required this.statusGreen,
    required this.statusPink,
    required this.statusOrange,
    required this.textGrey,
    required this.inputDark,
    required this.onStepCompleted,
    required this.formatDate, required workflow, required onStepComplete, required onWorkflowAction,
  });

  @override
  Widget build(BuildContext context) {
    final workflowData = taskData['taskWorkflow'];
    final steps = (workflowData?['steps'] as List?) ?? [];
    
    if (steps.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.schema_outlined, size: 40, color: textGrey.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Text('No workflow assigned', style: TextStyle(color: textGrey, fontSize: 13)),
        ]),
      );
    }
    
    final currentStepIndex = WorkflowVisualizationService.getCurrentStepIndex(steps);
    final progress = WorkflowVisualizationService.calculateProgress(steps);
    
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        // Workflow header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workflowData?['workflowName'] ?? 'Workflow',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: inputDark,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress == 1.0 ? statusGreen : statusPink,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              WorkflowVisualizationService.getWorkflowStateSummary(steps, currentStepIndex: currentStepIndex),
              style: TextStyle(color: textGrey, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 16),
        
        // Workflow steps
        ...List.generate(
          steps.length,
          (i) {
            final step = steps[i];
            final stepStatus = (step['status'] ?? step['stepStatus'] ?? 'pending').toString();
            final stepColor = WorkflowVisualizationService.getStepStatusColor(stepStatus);
            final isActive = i == currentStepIndex;
            final isCompleted = stepStatus.toLowerCase() == 'completed';
            
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive ? inputDark : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? stepColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: stepColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: stepColor.withValues(alpha: 0.3)),
                            ),
                            child: Center(
                              child: Icon(
                                WorkflowVisualizationService.getStepStatusIcon(stepStatus),
                                size: 16,
                                color: stepColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${step['title'] ?? 'Step ${i + 1}'}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: stepColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        WorkflowVisualizationService.getStatusLabel(stepStatus),
                                        style: TextStyle(color: stepColor, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                if ((step['description'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    step['description'].toString(),
                                    style: TextStyle(color: textGrey, fontSize: 11),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: WorkflowVisualizationService.getRoleColor(
                                (step['responsibleRole'] ?? step['requiredRole'] ?? 'any').toString(),
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Role: ${WorkflowVisualizationService.formatRoleName(step['responsibleRole'] ?? step['requiredRole'])}',
                              style: TextStyle(
                                color: WorkflowVisualizationService.getRoleColor(
                                  (step['responsibleRole'] ?? step['requiredRole'] ?? 'any').toString(),
                                ),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (step['approvalRequired'] == true) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusOrange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Approval Required',
                                style: TextStyle(color: statusOrange, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (isCompleted && (step['completedAt'] != null || step['completedBy'] != null)) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Completed by ${step['completedBy'] ?? 'Unknown'}',
                                style: TextStyle(color: statusGreen, fontSize: 10),
                              ),
                              Text(
                                formatDate(step['completedAt']),
                                style: TextStyle(color: textGrey, fontSize: 9),
                              ),
                              if ((step['comment'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '"${step['comment']}"',
                                  style: TextStyle(color: textGrey, fontSize: 10, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (isActive && !isCompleted && token != null) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: statusGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => _completeStep(context, i),
                            child: const Text('Complete Step', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (i < steps.length - 1) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Icon(Icons.arrow_downward, size: 16, color: textGrey.withValues(alpha: 0.3)),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _completeStep(BuildContext context, int stepIndex) async {
    String? comment;
    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (_) {
        final commentCtrl = TextEditingController();
        return AlertDialog(
          backgroundColor: inputDark,
          title: const Text('Complete Step', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)',
                  hintStyle: TextStyle(color: textGrey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: inputDark),
                  ),
                  filled: true,
                  fillColor: inputDark,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: textGrey)),
            ),
            TextButton(
              onPressed: () {
                comment = commentCtrl.text.trim();
                Navigator.pop(context, true);
              },
              child: const Text('Complete', style: TextStyle(color: Color(0xFF00C853))),
            ),
          ],
        );
      },
    );
    
    if (shouldComplete == true && token != null) {
      try {
        await WorkflowService.completeStep(
          token!,
          taskData['_id'].toString(),
          stepIndex: stepIndex,
          comment: comment,
        );
        onStepCompleted();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Step completed'),
              backgroundColor: statusGreen,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
