import '../entities/accelerometer_sample.dart';
import '../entities/movement_speed.dart';

abstract class ActivitySensorRepository {
  Stream<AccelerometerSample> get samples;
  Future<bool> requestPermissions();
  Future<void> start();
  Future<void> stop();
}

abstract class VoiceFeedbackRepository {
  Future<void> initialize();
  Future<void> speak(String message);
}

abstract class SensorPermissionsRepository {
  Future<bool> requestSensorPermissions();
}

abstract class LocationSpeedRepository {
  Stream<MovementSpeed> get speedSamples;
  Future<bool> requestPermissions();
  Future<void> start();
  Future<void> stop();
}
