import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/entities/physical_activity_type.dart';
import '../bloc/activity_monitor_bloc.dart';

class ActivityMonitorWidget extends StatelessWidget {
  const ActivityMonitorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivityMonitorBloc, ActivityMonitorState>(
      builder: (context, state) {
        final isMonitoring = state.isSessionActive;
        final activity = state is ActivityMonitorActive
            ? state.currentActivity
            : state is FallAlertActive
                ? state.currentActivity
                : null;
        final errorMessage = state is ActivityMonitorActive
            ? state.errorMessage
            : state is FallAlertActive
                ? state.errorMessage
                : null;
        final fallTestMode = state is ActivityMonitorActive
            ? state.fallTestModeEnabled
            : state is FallAlertActive
                ? state.fallTestModeEnabled
                : false;
        final fallAlertVisible = state is FallAlertActive;
        final scheme = Theme.of(context).colorScheme;

        return FeatureCard(
          animationIndex: 2,
          accentColor: AppTheme.monitorAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Monitor de Actividad',
                subtitle: fallAlertVisible
                    ? 'Alerta de caída activa'
                    : isMonitoring
                        ? 'Escuchando cambios de actividad'
                        : 'Presiona Iniciar para comenzar',
                isActive: isMonitoring,
                onToggle: () {
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
                icon: Icons.monitor_heart_rounded,
                accentColor: AppTheme.monitorAccent,
                activeSubtitleColor: AppTheme.orange,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AccentIconBadge(
                    icon: _activityIcon(activity),
                    color: _activityColor(activity),
                    size: 56,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity?.displayName ?? 'Sin actividad detectada',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: AppTheme.animFast,
                          child: Text(
                            fallAlertVisible
                                ? 'Responde el diálogo para continuar'
                                : isMonitoring
                                    ? 'Detección de caminata, carrera y caídas'
                                    : 'Inicia el monitor para comenzar',
                            key: ValueKey(
                              fallAlertVisible
                                  ? 'fall'
                                  : isMonitoring
                                      ? 'on'
                                      : 'off',
                            ),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: fallAlertVisible
                                      ? AppTheme.red
                                      : scheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 20),
                InfoBanner(
                  message: errorMessage,
                  icon: Icons.error_outline_rounded,
                  backgroundColor: AppTheme.redBg,
                  iconColor: AppTheme.red,
                  borderColor: AppTheme.red,
                ),
              ],
              const SizedBox(height: 24),
              InfoBanner(
                message: fallTestMode
                    ? 'Modo prueba: sacudida fuerte dispara alerta al instante.'
                    : 'Voz según pasos/min: caminar ≥55, correr ≥110. '
                        'Caída solo con sacudida fuerte y sin pasos recientes.',
                icon: Icons.tips_and_updates_outlined,
                backgroundColor: AppTheme.yellowBg,
                iconColor: AppTheme.orange,
                borderColor: AppTheme.orange,
              ),
              if (isMonitoring) ...[
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: AppTheme.orangeBg,
                  title: const Text('Modo prueba de caída'),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Umbrales más bajos para sacudidas de prueba'),
                  ),
                  value: fallTestMode,
                  onChanged: (_) {
                    context
                        .read<ActivityMonitorBloc>()
                        .add(const ToggleFallTestMode());
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
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
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _activityColor(PhysicalActivityType? type) {
    switch (type) {
      case PhysicalActivityType.walking:
        return AppTheme.green;
      case PhysicalActivityType.running:
        return AppTheme.red;
      case PhysicalActivityType.stationary:
      case null:
        return const Color(0xFF78909C);
    }
  }

  IconData _activityIcon(PhysicalActivityType? type) {
    switch (type) {
      case PhysicalActivityType.walking:
        return Icons.directions_walk_rounded;
      case PhysicalActivityType.running:
        return Icons.directions_run_rounded;
      case PhysicalActivityType.stationary:
        return Icons.self_improvement_rounded;
      default:
        return Icons.sensors_rounded;
    }
  }
}
