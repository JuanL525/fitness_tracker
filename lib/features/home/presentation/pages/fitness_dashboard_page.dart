import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tracking/data/datasources/gps_datasource.dart';
import '../../../tracking/domain/entities/location_point.dart';
import '../../../activity_monitor/domain/entities/physical_activity_type.dart';
import '../../../activity_monitor/presentation/bloc/activity_monitor_bloc.dart';

class FitnessDashboardPage extends StatefulWidget {
  const FitnessDashboardPage({super.key});

  @override
  State<FitnessDashboardPage> createState() => _FitnessDashboardPageState();
}

class _FitnessDashboardPageState extends State<FitnessDashboardPage> {
  double _speedKmh = 0;
  StreamSubscription<LocationPoint>? _speedSub;

  @override
  void dispose() {
    _speedSub?.cancel();
    super.dispose();
  }

  void _toggleSpeedStream(bool isMonitoring) {
    if (isMonitoring && _speedSub == null) {
      final gps = getIt<GpsDataSource>();
      _speedSub = gps.locationStream.listen((point) {
        if (mounted) {
          setState(() {
            _speedKmh = (point.speed * 3.6).clamp(0, 999);
          });
        }
      });
    } else if (!isMonitoring && _speedSub != null) {
      _speedSub?.cancel();
      _speedSub = null;
      if (mounted) {
        setState(() => _speedKmh = 0);
      }
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _activityPillLabel(PhysicalActivityType? type) {
    switch (type) {
      case PhysicalActivityType.running:
        return 'Running';
      case PhysicalActivityType.walking:
        return 'Walking';
      case PhysicalActivityType.stationary:
      case null:
        return 'Idle';
    }
  }

  Color _activityPillColor(PhysicalActivityType? type) {
    switch (type) {
      case PhysicalActivityType.running:
        return AppTheme.emerald400;
      case PhysicalActivityType.walking:
        return AppTheme.blue400;
      case PhysicalActivityType.stationary:
      case null:
        return AppTheme.slate500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ActivityMonitorBloc, ActivityMonitorState>(
      listenWhen: (prev, curr) =>
          prev.isSessionActive != curr.isSessionActive,
      listener: (context, state) {
        _toggleSpeedStream(state.isSessionActive);
      },
      builder: (context, state) {
        final isMonitoring = state.isSessionActive;
        final stepCount = state is ActivityMonitorActive
            ? state.stepCount
            : state is FallAlertActive
                ? state.stepCount
                : 0;
        final spm = state is ActivityMonitorActive
            ? state.stepsPerMinute
            : state is FallAlertActive
                ? state.stepsPerMinute
                : 0.0;
        final activity = state is ActivityMonitorActive
            ? state.currentActivity
            : state is FallAlertActive
                ? state.currentActivity
                : null;
        final fallTestMode = state is ActivityMonitorActive
            ? state.fallTestModeEnabled
            : state is FallAlertActive
                ? state.fallTestModeEnabled
                : false;
        final fallAlertVisible = state is FallAlertActive;
        final errorMessage = state is ActivityMonitorActive
            ? state.errorMessage
            : state is FallAlertActive
                ? state.errorMessage
                : null;

        final progress =
            (stepCount / AppTheme.dailyStepGoal).clamp(0.0, 1.0);
        final pillColor = _activityPillColor(activity);

        return SafeArea(
          child: SingleChildScrollView(
            padding: AppTheme.screenPadding.copyWith(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  _greeting(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Atleta',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 28,
                      ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    decoration: AppTheme.emeraldGlow(radius: 120),
                    child: CircularPercentIndicator(
                      radius: 100,
                      lineWidth: 14,
                      percent: progress,
                      animation: true,
                      animationDuration: 800,
                      circularStrokeCap: CircularStrokeCap.round,
                      backgroundColor: AppTheme.slate800,
                      progressColor: AppTheme.emerald400,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$stepCount',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.slate100,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'PASOS HOY',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppTheme.slate400,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Meta: ${AppTheme.dailyStepGoal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} pasos',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ACTIVIDAD ACTUAL',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppTheme.slate400,
                                ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: pillColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: pillColor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              _activityPillLabel(activity),
                              style: TextStyle(
                                color: pillColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricColumn(
                              label: 'CADENCIA',
                              value: spm > 0
                                  ? '${spm.round()}'
                                  : '—',
                              unit: 'spm',
                              color: AppTheme.blue400,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 48,
                            color: AppTheme.slate800,
                          ),
                          Expanded(
                            child: _MetricColumn(
                              label: 'VELOCIDAD',
                              value: isMonitoring && _speedKmh > 0
                                  ? _speedKmh.toStringAsFixed(1)
                                  : '—',
                              unit: 'km/h',
                              color: AppTheme.emerald400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (fallAlertVisible) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration(
                      borderColor: AppTheme.rose500.withValues(alpha: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.triangle_alert,
                          color: AppTheme.rose500,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Alerta de caída activa — responde el diálogo',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.rose500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration(
                      borderColor: AppTheme.rose500.withValues(alpha: 0.4),
                    ),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: AppTheme.rose500),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                _SessionButton(
                  isMonitoring: isMonitoring,
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
                ),
                if (isMonitoring) ...[
                  const SizedBox(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Modo prueba de caída'),
                    subtitle: const Text(
                      'Umbrales más bajos para sacudidas de prueba',
                    ),
                    value: fallTestMode,
                    activeThumbColor: AppTheme.emerald400,
                    onChanged: (_) {
                      context
                          .read<ActivityMonitorBloc>()
                          .add(const ToggleFallTestMode());
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      context
                          .read<ActivityMonitorBloc>()
                          .add(const SimulateFallAlert());
                    },
                    icon: const Icon(LucideIcons.shield_alert, size: 18),
                    label: Text(
                      kDebugMode
                          ? 'Simular caída (seguro)'
                          : 'Probar diálogo de caída',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.slate400,
                      side: const BorderSide(color: AppTheme.slate800),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SessionButton extends StatelessWidget {
  const _SessionButton({
    required this.isMonitoring,
    required this.onPressed,
  });

  final bool isMonitoring;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isMonitoring) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppTheme.rose500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.rose500, width: 2),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.square, color: AppTheme.rose500, size: 20),
                SizedBox(width: 10),
                Text(
                  'DETENER SESIÓN',
                  style: TextStyle(
                    color: AppTheme.rose500,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.emerald400, AppTheme.emerald600],
            ),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.play, color: AppTheme.slate950, size: 22),
              SizedBox(width: 10),
              Text(
                'INICIAR SESIÓN',
                style: TextStyle(
                  color: AppTheme.slate950,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
