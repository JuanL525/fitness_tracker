import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/step_data.dart';
import '../entities/physical_activity_type.dart';

class ActivityMonitorEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ActivityConfirmed extends ActivityMonitorEvent {
  final PhysicalActivityType type;
  final bool isFirstAnnouncement;

  ActivityConfirmed({
    required this.type,
    required this.isFirstAnnouncement,
  });

  @override
  List<Object?> get props => [type, isFirstAnnouncement];
}

class FallDetected extends ActivityMonitorEvent {
  final DateTime timestamp;
  final double impactMagnitude;

  FallDetected({
    required this.timestamp,
    required this.impactMagnitude,
  });

  @override
  List<Object?> get props => [timestamp, impactMagnitude];
}

class PermissionsDenied extends ActivityMonitorEvent {
  @override
  List<Object?> get props => [];
}

class StepCountUpdated extends ActivityMonitorEvent {
  final StepData stepData;

  StepCountUpdated(this.stepData);

  @override
  List<Object?> get props => [stepData];
}
