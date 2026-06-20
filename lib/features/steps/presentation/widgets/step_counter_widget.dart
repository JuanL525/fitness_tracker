import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivityMonitorBloc, ActivityMonitorState>(
      builder: (context, monitorState) {
        final data = _displayData(monitorState);
        final isLive =
            _isTracking || monitorState.isSessionActive;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Contador de Pasos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _toggleTracking,
                      icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                      label: Text(_isTracking ? 'Detener' : 'Iniciar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTracking ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Text(
                  '${data?.stepCount ?? 0}',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const Text(
                  'pasos',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                if (isLive && (data?.stepCount ?? 0) == 0)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Camina unos segundos para registrar pasos',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoChip(
                      icon: _getActivityIcon(data?.activityType),
                      label: _getActivityLabel(data),
                      color: Colors.blue,
                    ),
                    _buildInfoChip(
                      icon: Icons.local_fire_department,
                      label:
                          '${data?.estimatedCalories.toStringAsFixed(1) ?? "0"} cal',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  IconData _getActivityIcon(ActivityType? type) {
    switch (type) {
      case ActivityType.walking:
        return Icons.directions_walk;
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.stationary:
        return Icons.accessibility_new;
      default:
        return Icons.help_outline;
    }
  }

  String _getActivityLabel(StepData? data) {
    if (data == null) {
      return 'Detectando...';
    }
    final spm = data.stepsPerMinute.round();
    switch (data.activityType) {
      case ActivityType.walking:
        return spm > 0 ? 'Caminando · $spm pas/min' : 'Caminando';
      case ActivityType.running:
        return spm > 0 ? 'Corriendo · $spm pas/min' : 'Corriendo';
      case ActivityType.stationary:
        return 'Quieto';
    }
  }
}
