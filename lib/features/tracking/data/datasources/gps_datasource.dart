import 'package:geolocator/geolocator.dart';

import '../../domain/entities/location_point.dart';

abstract class GpsDataSource {
  Future<LocationPoint?> getCurrentLocation();
  Stream<LocationPoint> get locationStream;
  Future<bool> isGpsEnabled();
  Future<bool> requestPermissions();
}

class GpsDataSourceImpl implements GpsDataSource {
  static const _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 2,
  );

  @override
  Future<LocationPoint?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );
      return _mapPosition(position);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<LocationPoint> get locationStream {
    return Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).map(_mapPosition);
  }

  @override
  Future<bool> isGpsEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<bool> requestPermissions() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  LocationPoint _mapPosition(Position position) {
    return LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      speed: position.speed,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
    );
  }
}
