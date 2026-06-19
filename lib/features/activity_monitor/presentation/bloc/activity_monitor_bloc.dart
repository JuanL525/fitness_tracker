import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/activity_monitor_event.dart' as domain;
import '../../domain/entities/physical_activity_type.dart';
import '../../domain/usecases/monitor_activity.dart';

abstract class ActivityMonitorState extends Equatable {
  const ActivityMonitorState();

  @override
  List<Object?> get props => [];
}

class ActivityMonitorInitial extends ActivityMonitorState {
  const ActivityMonitorInitial();
}

class ActivityMonitorIdle extends ActivityMonitorState {
  const ActivityMonitorIdle();
}

class ActivityMonitorActive extends ActivityMonitorState {
  final PhysicalActivityType? currentActivity;
  final bool isMonitoring;
  final String? errorMessage;
  final bool fallTestModeEnabled;
  final int stepCount;
  final double stepsPerMinute;

  const ActivityMonitorActive({
    this.currentActivity,
    this.isMonitoring = false,
    this.errorMessage,
    this.fallTestModeEnabled = false,
    this.stepCount = 0,
    this.stepsPerMinute = 0,
  });

  ActivityMonitorActive copyWith({
    PhysicalActivityType? currentActivity,
    bool? isMonitoring,
    String? errorMessage,
    bool? fallTestModeEnabled,
    int? stepCount,
    double? stepsPerMinute,
    bool clearError = false,
  }) {
    return ActivityMonitorActive(
      currentActivity: currentActivity ?? this.currentActivity,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      fallTestModeEnabled: fallTestModeEnabled ?? this.fallTestModeEnabled,
      stepCount: stepCount ?? this.stepCount,
      stepsPerMinute: stepsPerMinute ?? this.stepsPerMinute,
    );
  }

  @override
  List<Object?> get props => [
        currentActivity,
        isMonitoring,
        errorMessage,
        fallTestModeEnabled,
        stepCount,
        stepsPerMinute,
      ];
}

class FallAlertActive extends ActivityMonitorState {
  final bool escalated;
  final DateTime detectedAt;

  const FallAlertActive({
    required this.escalated,
    required this.detectedAt,
  });

  FallAlertActive copyWith({bool? escalated}) {
    return FallAlertActive(
      escalated: escalated ?? this.escalated,
      detectedAt: detectedAt,
    );
  }

  @override
  List<Object?> get props => [escalated, detectedAt];
}

abstract class ActivityMonitorBlocEvent extends Equatable {
  const ActivityMonitorBlocEvent();

  @override
  List<Object?> get props => [];
}

class StartMonitoring extends ActivityMonitorBlocEvent {
  const StartMonitoring();
}

class StopMonitoring extends ActivityMonitorBlocEvent {
  const StopMonitoring();
}

class FallConfirmedOk extends ActivityMonitorBlocEvent {
  const FallConfirmedOk();
}

class FallNeedsHelp extends ActivityMonitorBlocEvent {
  const FallNeedsHelp();
}

class FallTimeoutElapsed extends ActivityMonitorBlocEvent {
  const FallTimeoutElapsed();
}

class ToggleFallTestMode extends ActivityMonitorBlocEvent {
  const ToggleFallTestMode();
}

class SimulateFallAlert extends ActivityMonitorBlocEvent {
  const SimulateFallAlert();
}

class _InternalMonitorEvent extends ActivityMonitorBlocEvent {
  const _InternalMonitorEvent(this.event);

  final domain.ActivityMonitorEvent event;

  @override
  List<Object?> get props => [event];
}

class ActivityMonitorBloc
    extends Bloc<ActivityMonitorBlocEvent, ActivityMonitorState> {
  ActivityMonitorBloc({required MonitorActivityUseCase monitorActivity})
      : _monitorActivity = monitorActivity,
        super(const ActivityMonitorInitial()) {
    on<StartMonitoring>(_onStartMonitoring);
    on<StopMonitoring>(_onStopMonitoring);
    on<FallConfirmedOk>(_onFallConfirmedOk);
    on<FallNeedsHelp>(_onFallNeedsHelp);
    on<FallTimeoutElapsed>(_onFallTimeoutElapsed);
    on<ToggleFallTestMode>(_onToggleFallTestMode);
    on<SimulateFallAlert>(_onSimulateFallAlert);
    on<_InternalMonitorEvent>(_onInternalEvent);
  }

  final MonitorActivityUseCase _monitorActivity;
  StreamSubscription<domain.ActivityMonitorEvent>? _subscription;
  Timer? _fallTimer;

  Future<void> _onStartMonitoring(
    StartMonitoring event,
    Emitter<ActivityMonitorState> emit,
  ) async {
    emit(const ActivityMonitorActive(isMonitoring: true));

    await _subscription?.cancel();
    _subscription = _monitorActivity.events.listen((monitorEvent) {
      add(_InternalMonitorEvent(monitorEvent));
    });

    final started = await _monitorActivity.start();
    if (!started) {
      emit(
        const ActivityMonitorActive(
          isMonitoring: false,
          errorMessage: 'Permisos de sensores denegados',
        ),
      );
    }
  }

  Future<void> _onStopMonitoring(
    StopMonitoring event,
    Emitter<ActivityMonitorState> emit,
  ) async {
    _fallTimer?.cancel();
    await _subscription?.cancel();
    await _monitorActivity.stop();
    emit(const ActivityMonitorIdle());
  }

  Future<void> _onInternalEvent(
    _InternalMonitorEvent event,
    Emitter<ActivityMonitorState> emit,
  ) async {
    final monitorEvent = event.event;

    if (monitorEvent is domain.PermissionsDenied) {
      emit(
        const ActivityMonitorActive(
          isMonitoring: false,
          errorMessage: 'Permisos de sensores denegados',
        ),
      );
      return;
    }

    if (monitorEvent is domain.StepCountUpdated) {
      final current = state;
      if (current is ActivityMonitorActive) {
        emit(
          current.copyWith(
            stepCount: monitorEvent.stepData.stepCount,
            stepsPerMinute: monitorEvent.stepData.stepsPerMinute,
            isMonitoring: true,
          ),
        );
      } else if (current is! FallAlertActive) {
        emit(
          ActivityMonitorActive(
            stepCount: monitorEvent.stepData.stepCount,
            stepsPerMinute: monitorEvent.stepData.stepsPerMinute,
            isMonitoring: true,
          ),
        );
      }
      return;
    }

    if (monitorEvent is domain.ActivityConfirmed) {
      final current = state;
      if (current is ActivityMonitorActive) {
        emit(
          current.copyWith(
            currentActivity: monitorEvent.type,
            isMonitoring: true,
          ),
        );
      } else {
        emit(
          ActivityMonitorActive(
            currentActivity: monitorEvent.type,
            isMonitoring: true,
          ),
        );
      }
      return;
    }

    if (monitorEvent is domain.FallDetected) {
      if (state is! FallAlertActive) {
        await _triggerFallAlert(emit, monitorEvent.timestamp);
      }
      return;
    }
  }

  Future<void> _triggerFallAlert(
    Emitter<ActivityMonitorState> emit,
    DateTime detectedAt,
  ) async {
    _fallTimer?.cancel();
    emit(
      FallAlertActive(
        escalated: false,
        detectedAt: detectedAt,
      ),
    );
    await _monitorActivity.announceFallPrompt();
    _fallTimer = Timer(const Duration(seconds: 15), () {
      add(const FallTimeoutElapsed());
    });
  }

  void _onToggleFallTestMode(
    ToggleFallTestMode event,
    Emitter<ActivityMonitorState> emit,
  ) {
    final current = state;
    if (current is! ActivityMonitorActive) {
      return;
    }

    final enabled = !current.fallTestModeEnabled;
    _monitorActivity.setFallTestSensitivity(enabled);
    emit(current.copyWith(fallTestModeEnabled: enabled));
  }

  Future<void> _onSimulateFallAlert(
    SimulateFallAlert event,
    Emitter<ActivityMonitorState> emit,
  ) async {
    await _triggerFallAlert(emit, DateTime.now());
  }

  void _onFallConfirmedOk(
    FallConfirmedOk event,
    Emitter<ActivityMonitorState> emit,
  ) {
    _fallTimer?.cancel();
    _monitorActivity.resetFallDetector();
    final testMode = _monitorActivity.fallTestSensitivity;
    final previous = state;
    if (previous is ActivityMonitorActive) {
      emit(
        previous.copyWith(
          isMonitoring: true,
          fallTestModeEnabled: testMode,
          clearError: true,
        ),
      );
    } else {
      emit(ActivityMonitorActive(isMonitoring: true, fallTestModeEnabled: testMode));
    }
  }

  void _onFallNeedsHelp(
    FallNeedsHelp event,
    Emitter<ActivityMonitorState> emit,
  ) {
    _fallTimer?.cancel();
    _monitorActivity.resetFallDetector();
    final testMode = _monitorActivity.fallTestSensitivity;
    final previous = state;
    if (previous is ActivityMonitorActive) {
      emit(
        previous.copyWith(
          isMonitoring: true,
          fallTestModeEnabled: testMode,
          errorMessage: 'Alerta registrada: necesitas ayuda',
        ),
      );
    } else {
      emit(
        ActivityMonitorActive(
          isMonitoring: true,
          fallTestModeEnabled: testMode,
          errorMessage: 'Alerta registrada: necesitas ayuda',
        ),
      );
    }
  }

  void _onFallTimeoutElapsed(
    FallTimeoutElapsed event,
    Emitter<ActivityMonitorState> emit,
  ) {
    final current = state;
    if (current is FallAlertActive && !current.escalated) {
      emit(current.copyWith(escalated: true));
    }
  }

  @override
  Future<void> close() async {
    _fallTimer?.cancel();
    await _subscription?.cancel();
    _monitorActivity.dispose();
    return super.close();
  }
}
