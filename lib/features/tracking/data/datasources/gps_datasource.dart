import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/location_point.dart';

abstract class GpsDataSource {
  Future<LocationPoint?> getCurrentLocation();
  Stream<LocationPoint> get locationStream;
  Future<bool> isGpsEnabled();
  Future<bool> requestPermissions();
}

class GpsDataSourceImpl implements GpsDataSource {
  Stream<LocationPoint>? _sharedStream;

  /// Alta precisión; el filtrado fino (accuracy / distancia) se hace en la UI.
  static LocationSettings get _locationSettings {
    if (!kIsWeb && Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
      );
    }
    if (!kIsWeb && Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
  }

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
    return _sharedStream ??= Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).map(_mapPosition).asBroadcastStream();
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
    if (permission == LocationPermission.denied) {
      return false;
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  LocationPoint _mapPosition(Position position) {
    final speed = position.speed < 0 ? 0.0 : position.speed;
    final accuracy = position.accuracy < 0 ? 0.0 : position.accuracy;

    return LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      speed: speed,
      accuracy: accuracy,
      timestamp: position.timestamp,
    );
  }
}
