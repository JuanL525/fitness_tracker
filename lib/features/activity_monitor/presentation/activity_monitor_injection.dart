import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/datasources/accelerometer_sensor_datasource.dart';
import '../data/datasources/platform_step_datasource.dart';
import '../data/datasources/sensor_permissions_datasource.dart';
import '../data/datasources/text_to_speech_datasource.dart';
import '../data/repositories/activity_monitor_repository_impl.dart';
import '../data/repositories/location_speed_repository_impl.dart';
import '../domain/usecases/monitor_activity.dart';
import '../../tracking/data/datasources/gps_datasource.dart';
import 'bloc/activity_monitor_bloc.dart';
import 'widgets/activity_monitor_fall_listener.dart';

MonitorActivityUseCase createMonitorActivityUseCase() {
  final sensorDataSource = AccelerometerSensorDataSourceImpl();
  final stepDataSource = PlatformStepDataSourceImpl();
  final ttsDataSource = TextToSpeechDataSourceImpl();
  final permissionsDataSource = SensorPermissionsDataSourceImpl();
  final gpsDataSource = GpsDataSourceImpl();

  return MonitorActivityUseCase(
    sensorRepository: ActivitySensorRepositoryImpl(sensorDataSource),
    voiceRepository: VoiceFeedbackRepositoryImpl(ttsDataSource),
    permissionsRepository:
        SensorPermissionsRepositoryImpl(permissionsDataSource),
    stepDataSource: stepDataSource,
    locationRepository: LocationSpeedRepositoryImpl(gpsDataSource),
  );
}

ActivityMonitorBloc createActivityMonitorBloc() {
  return ActivityMonitorBloc(
    monitorActivity: createMonitorActivityUseCase(),
  );
}

class ActivityMonitorScope extends StatelessWidget {
  const ActivityMonitorScope({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => createActivityMonitorBloc(),
      child: ActivityMonitorFallListener(child: child),
    );
  }
}
