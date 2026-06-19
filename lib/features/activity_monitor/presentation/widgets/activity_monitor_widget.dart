import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/physical_activity_type.dart';
import '../bloc/activity_monitor_bloc.dart';

class ActivityMonitorWidget extends StatelessWidget {
  const ActivityMonitorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivityMonitorBloc, ActivityMonitorState>(
      builder: (context, state) {
        final isMonitoring = state is ActivityMonitorActive && state.isMonitoring;
        final activity = state is ActivityMonitorActive
            ? state.currentActivity
            : null;
        final errorMessage =
            state is ActivityMonitorActive ? state.errorMessage : null;
        final fallTestMode =
            state is ActivityMonitorActive && state.fallTestModeEnabled;

        return Card(          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Monitor de Actividad',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (isMonitoring) {
                          context
                              .read<ActivityMonitorBloc>()
                              .add(const StopMonitoring());
                        } else {
                          context
                              .read<ActivityMonitorBloc>()
                              .add(const StartMonitoring());
                        }
                      },
                      icon: Icon(isMonitoring ? Icons.stop : Icons.play_arrow),
                      label: Text(isMonitoring ? 'Detener' : 'Iniciar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMonitoring ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Icon(
                      _activityIcon(activity),
                      size: 48,
                      color: const Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity?.displayName ?? 'Sin actividad detectada',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isMonitoring
                                ? 'Escuchando cambios de actividad…'
                                : 'Presiona Iniciar para comenzar',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    fallTestMode
                        ? 'Modo prueba: sacudida fuerte dispara alerta al instante.'
                        : 'Voz según pasos/min: caminar ≥65, correr ≥130. '
                            'Caída solo con sacudida fuerte y sin pasos recientes. '
                            'Inicia también el Contador de Pasos.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                if (isMonitoring) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Modo prueba de caída'),
                    subtitle: const Text(
                      'Umbrales más bajos para sacudidas de prueba',
                    ),
                    value: fallTestMode,
                    onChanged: (_) {
                      context
                          .read<ActivityMonitorBloc>()
                          .add(const ToggleFallTestMode());
                    },
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      context
                          .read<ActivityMonitorBloc>()
                          .add(const SimulateFallAlert());
                    },
                    icon: const Icon(Icons.health_and_safety_outlined),
                    label: Text(
                      kDebugMode
                          ? 'Simular caída (seguro)'
                          : 'Probar diálogo de caída',
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  IconData _activityIcon(PhysicalActivityType? type) {
    switch (type) {
      case PhysicalActivityType.walking:
        return Icons.directions_walk;
      case PhysicalActivityType.running:
        return Icons.directions_run;
      case PhysicalActivityType.stationary:
        return Icons.accessibility_new;
      default:
        return Icons.sensors;
    }
  }
}
