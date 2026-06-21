import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/activity_monitor_bloc.dart';

class FallConfirmationDialog extends StatelessWidget {
  const FallConfirmationDialog({
    super.key,
    required this.escalated,
  });

  final bool escalated;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.slate900,
      icon: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.rose500.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.rose500),
        ),
        child: const Icon(
          LucideIcons.triangle_alert,
          color: AppTheme.rose500,
          size: 32,
        ),
      ),
      title: const Text('Posible caída'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Estás bien? Detectamos un posible impacto.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.slate100,
                  height: 1.5,
                ),
          ),
          if (escalated) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.rose500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.rose500.withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'Por favor confirma que estás bien. Si no respondes, '
                'consideraremos que necesitas ayuda.',
                style: TextStyle(
                  color: AppTheme.rose500,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        TextButton(
          onPressed: () {
            context.read<ActivityMonitorBloc>().add(const FallNeedsHelp());
          },
          child: const Text(
            'Necesito ayuda',
            style: TextStyle(color: AppTheme.rose500),
          ),
        ),
        FilledButton(
          onPressed: () {
            context.read<ActivityMonitorBloc>().add(const FallConfirmedOk());
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.emerald400,
            foregroundColor: AppTheme.slate950,
          ),
          child: const Text('Estoy bien'),
        ),
      ],
    );
  }
}
