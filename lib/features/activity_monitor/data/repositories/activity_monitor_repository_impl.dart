import '../../domain/entities/accelerometer_sample.dart';
import '../../domain/repositories/activity_monitor_repositories.dart';
import '../datasources/accelerometer_sensor_datasource.dart';
import '../datasources/sensor_permissions_datasource.dart';
import '../datasources/text_to_speech_datasource.dart';

class ActivitySensorRepositoryImpl implements ActivitySensorRepository {
  ActivitySensorRepositoryImpl(this._dataSource);

  final AccelerometerSensorDataSource _dataSource;

  @override
  Stream<AccelerometerSample> get samples => _dataSource.samples;

  @override
  Future<bool> requestPermissions() async {
    return true;
  }

  @override
  Future<void> start() => _dataSource.start();

  @override
  Future<void> stop() => _dataSource.stop();
}

class VoiceFeedbackRepositoryImpl implements VoiceFeedbackRepository {
  VoiceFeedbackRepositoryImpl(this._dataSource);

  final TextToSpeechDataSource _dataSource;

  @override
  Future<void> initialize() => _dataSource.initialize();

  @override
  Future<void> speak(String message) => _dataSource.speak(message);
}

class SensorPermissionsRepositoryImpl implements SensorPermissionsRepository {
  SensorPermissionsRepositoryImpl(this._dataSource);

  final SensorPermissionsDataSource _dataSource;

  @override
  Future<bool> requestSensorPermissions() {
    return _dataSource.requestSensorPermissions();
  }
}
