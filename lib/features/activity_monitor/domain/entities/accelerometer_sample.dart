import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'physical_activity_type.dart';

class AccelerometerSample extends Equatable {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;
  /// Presión barométrica en hPa (mayor = altura más baja).
  final double? pressureHpa;

  AccelerometerSample({
    required this.x,
    required this.y,
    required this.z,
    DateTime? timestamp,
    this.pressureHpa,
  }) : timestamp = timestamp ?? DateTime.now();

  double get magnitude {
    return math.sqrt(x * x + y * y + z * z);
  }

  @override
  List<Object?> get props => [x, y, z, timestamp, pressureHpa];
}

class PhysicalActivityState extends Equatable {
  final PhysicalActivityType type;
  final double smoothedMagnitude;
  final DateTime timestamp;

  const PhysicalActivityState({
    required this.type,
    required this.smoothedMagnitude,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [type, smoothedMagnitude, timestamp];
}

class FallEvent extends Equatable {
  final DateTime timestamp;
  final double impactMagnitude;

  const FallEvent({
    required this.timestamp,
    required this.impactMagnitude,
  });

  @override
  List<Object?> get props => [timestamp, impactMagnitude];
}
