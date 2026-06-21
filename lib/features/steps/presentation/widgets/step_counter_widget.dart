import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_animations.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/data/datasources/accelerometer_datasource.dart';
import '../../../auth/domain/entities/step_data.dart';
import '../../../activity_monitor/domain/entities/physical_activity_type.dart';
import '../../../activity_monitor/presentation/bloc/activity_monitor_bloc.dart';

class StepCounterWidget extends StatefulWidget {
  const StepCounterWidget({super.key});

  @override
  State<StepCounterWidget> createState() => _StepCounterWidgetState();
}

class _StepCounterWidgetState extends State<StepCounterWidget> {
  late final AccelerometerDataSource _dataSource = getIt<AccelerometerDataSource>();

  StreamSubscription<StepData>? _subscription;
  StepData? _localData;
  bool _isTracking = false;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _toggleTracking() {
    if (_isTracking) {
      _stopTracking();
    } else {
      _startTracking();
    }
  }

  Future<void> _startTracking() async {
    final hasPermission = await _dataSource.requestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permisos de sensores denegados'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _subscription = _dataSource.stepStream.listen(
      (data) {
        if (mounted) {
          setState(() {
            _localData = data;
          });
        }
      },
      onError: (error) {
        debugPrint('Error en stream de pasos: $error');
      },
    );

    await _dataSource.startCounting();

    setState(() {
      _isTracking = true;
    });
  }

  Future<void> _stopTracking() async {
    await _dataSource.stopCounting();
    await _subscription?.cancel();
    _subscription = null;

    setState(() {
      _isTracking = false;
    });
  }

  StepData? _displayData(ActivityMonitorState monitorState) {
    final local = _localData;
    if (monitorState.isSessionActive) {
      final count = monitorState is ActivityMonitorActive
          ? monitorState.stepCount
          : monitorState is FallAlertActive
              ? monitorState.stepCount
              : 0;
      final stepsPerMinute = monitorState is ActivityMonitorActive
          ? monitorState.stepsPerMinute
          : monitorState is FallAlertActive
              ? monitorState.stepsPerMinute
              : 0.0;
      final currentActivity = monitorState is ActivityMonitorActive
          ? monitorState.currentActivity
          : monitorState is FallAlertActive
              ? monitorState.currentActivity
              : null;

      return StepData(
        stepCount: count,
        activityType: _mapActivity(currentActivity) != ActivityType.stationary
            ? _mapActivity(currentActivity)
            : (local?.activityType ?? ActivityType.stationary),
        magnitude: local?.magnitude ?? 9.8,
        stepsPerMinute:
            stepsPerMinute > 0 ? stepsPerMinute : (local?.stepsPerMinute ?? 0),
      );
    }
    return local;
  }

  ActivityType _mapActivity(PhysicalActivityType? type) {
    switch (type) {
      case PhysicalActivityType.walking:
        return ActivityType.walking;
      case PhysicalActivityType.running:
        return ActivityType.running;
      case PhysicalActivityType.stationary:
      case null:
        return ActivityType.stationary;
    }
  }

  Color _activityColor(ActivityType? type) {
    switch (type) {
      case ActivityType.walking:
        return AppTheme.activityColor('walking');
      case ActivityType.running:
        return AppTheme.activityColor('running');
      case ActivityType.stationary:
        return AppTheme.activityColor('stationary');
      default:
        return const Color(0xFF78909C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivityMonitorBloc, ActivityMonitorState>(
      builder: (context, monitorState) {
        final data = _displayData(monitorState);
        final isLive = _isTracking || monitorState.isSessionActive;
        final scheme = Theme.of(context).colorScheme;

        return FeatureCard(
          animationIndex: 0,
          accentColor: AppTheme.stepsAccent,
          child: Column(
            children: [
              SectionHeader(
                title: 'Contador de Pasos',
                subtitle: isLive ? 'Registrando movimiento' : 'Listo para iniciar',
                isActive: _isTracking,
                onToggle: _toggleTracking,
                icon: Icons.directions_walk_rounded,
                accentColor: AppTheme.stepsAccent,
                activeSubtitleColor: AppTheme.blue,
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: AppTheme.stepsBg,
                  borderRadius: BorderRadius.circular(AppTheme.chipRadius),
                  border: Border.all(color: AppTheme.blue, width: 2),
                ),
                child: Column(
                  children: [
                    AnimatedCount(
                      value: data?.stepCount ?? 0,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppTheme.blue,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'pasos',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ],
                ),
              ),
              if (isLive && (data?.stepCount ?? 0) == 0) ...[
                const SizedBox(height: 16),
                Text(
                  'Camina unos segundos para registrar pasos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  InfoChip(
                    icon: _getActivityIcon(data?.activityType),
                    label: _getActivityLabel(data),
                    color: _activityColor(data?.activityType),
                  ),
                  const SizedBox(width: 12),
                  InfoChip(
                    icon: Icons.local_fire_department_rounded,
                    label: '${data?.estimatedCalories.toStringAsFixed(1) ?? "0"} cal',
                    color: AppTheme.orange,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getActivityIcon(ActivityType? type) {
    switch (type) {
      case ActivityType.walking:
        return Icons.directions_walk_rounded;
      case ActivityType.running:
        return Icons.directions_run_rounded;
      case ActivityType.stationary:
        return Icons.self_improvement_rounded;
      default:
        return Icons.sensors_rounded;
    }
  }

  String _getActivityLabel(StepData? data) {
    if (data == null) {
      return 'Detectando…';
    }
    final spm = data.stepsPerMinute.round();
    switch (data.activityType) {
      case ActivityType.walking:
        return spm > 0 ? 'Caminando · $spm/min' : 'Caminando';
      case ActivityType.running:
        return spm > 0 ? 'Corriendo · $spm/min' : 'Corriendo';
      case ActivityType.stationary:
        return 'Quieto';
    }
  }
}
