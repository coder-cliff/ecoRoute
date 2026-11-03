import 'package:flutter/material.dart';
import '../models/waste_request.dart';
import '../theme/app_theme.dart';

class MilestoneStepperWidget extends StatelessWidget {
  final RequestStatus status;
  final DateTime requestedAt;
  final DateTime? collectedAt;
  final String? assignedRiderName;

  const MilestoneStepperWidget({
    super.key,
    required this.status,
    required this.requestedAt,
    this.collectedAt,
    this.assignedRiderName,
  });

  @override
  Widget build(BuildContext context) {
    if (status == RequestStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pickup Cancelled',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15),
                  ),
                  Text(
                    'This request was cancelled and is no longer active in municipal dispatch.',
                    style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final int currentStep;
    switch (status) {
      case RequestStatus.pending:
        currentStep = 0;
        break;
      case RequestStatus.assigned:
        currentStep = 1;
        break;
      case RequestStatus.collected:
        currentStep = 2;
        break;
      case RequestStatus.cancelled:
        currentStep = -1;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pickup Milestone Pipeline',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: -0.2),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accentMint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.name.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStepNode(
                stepIndex: 0,
                currentStep: currentStep,
                icon: Icons.assignment_turned_in_rounded,
                title: 'Requested',
                subtitle: 'Logged',
              ),
              _buildStepConnector(isCompleted: currentStep >= 1),
              _buildStepNode(
                stepIndex: 1,
                currentStep: currentStep,
                icon: Icons.electric_moped_rounded,
                title: 'Assigned',
                subtitle: assignedRiderName != null ? 'Dispatched' : 'Pending',
              ),
              _buildStepConnector(isCompleted: currentStep >= 2),
              _buildStepNode(
                stepIndex: 2,
                currentStep: currentStep,
                icon: Icons.task_alt_rounded,
                title: 'Collected',
                subtitle: 'Settled',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode({
    required int stepIndex,
    required int currentStep,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool isCompleted = currentStep > stepIndex;
    final bool isCurrent = currentStep == stepIndex;

    final Color nodeColor;
    if (isCompleted || isCurrent) {
      nodeColor = AppTheme.primaryGreen;
    } else {
      nodeColor = Colors.grey.shade300;
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppTheme.primaryGreen
                  : isCompleted
                      ? AppTheme.accentMint
                      : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(
                color: nodeColor,
                width: isCurrent ? 2.5 : 1.5,
              ),
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : icon,
              size: 20,
              color: isCurrent
                  ? Colors.white
                  : isCompleted
                      ? AppTheme.primaryGreen
                      : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrent || isCompleted ? FontWeight.bold : FontWeight.w500,
              color: isCurrent || isCompleted ? AppTheme.textDark : AppTheme.textMuted,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isCurrent ? AppTheme.primaryGreen : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: isCompleted ? AppTheme.primaryGreen : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
