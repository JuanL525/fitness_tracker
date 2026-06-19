import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
          SizedBox(width: 8),
          Text('Posible caída'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Estás bien? Detectamos un posible impacto.',
            style: TextStyle(fontSize: 16),
          ),
          if (escalated) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                'Por favor confirma que estás bien. Si no respondes, '
                'consideraremos que necesitas ayuda.',
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.read<ActivityMonitorBloc>().add(const FallNeedsHelp());
          },
          child: const Text('Necesito ayuda'),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<ActivityMonitorBloc>().add(const FallConfirmedOk());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Estoy bien'),
        ),
      ],
    );
  }
}
