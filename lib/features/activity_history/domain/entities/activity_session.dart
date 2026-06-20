import 'package:equatable/equatable.dart';

class ActivitySession extends Equatable {
  const ActivitySession({
    this.id,
    required this.date,
    required this.duration,
    required this.totalSteps,
    required this.primaryActivityType,
  });

  final int? id;
  final DateTime date;
  final Duration duration;
  final int totalSteps;
  final String primaryActivityType;

  ActivitySession copyWith({
    int? id,
    DateTime? date,
    Duration? duration,
    int? totalSteps,
    String? primaryActivityType,
  }) {
    return ActivitySession(
      id: id ?? this.id,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      totalSteps: totalSteps ?? this.totalSteps,
      primaryActivityType: primaryActivityType ?? this.primaryActivityType,
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        duration,
        totalSteps,
        primaryActivityType,
      ];
}
