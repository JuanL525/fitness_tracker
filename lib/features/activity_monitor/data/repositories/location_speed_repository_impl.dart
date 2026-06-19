import '../../../tracking/data/datasources/gps_datasource.dart';
import '../../domain/entities/movement_speed.dart';
import '../../domain/repositories/activity_monitor_repositories.dart';

class LocationSpeedRepositoryImpl implements LocationSpeedRepository {
  LocationSpeedRepositoryImpl(this._gps);

  final GpsDataSource _gps;

  @override
  Stream<MovementSpeed> get speedSamples {
    return _gps.locationStream.map((point) {
      return MovementSpeed(
        metersPerSecond: point.speed,
        accuracyMeters: point.accuracy,
        timestamp: point.timestamp,
      );
    });
  }

  @override
  Future<bool> requestPermissions() => _gps.requestPermissions();

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}
