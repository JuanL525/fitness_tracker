import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/activity_monitor_event.dart' as domain;
import '../../domain/entities/physical_activity_type.dart';
import '../../domain/usecases/monitor_activity.dart';
import '../../../activity_history/domain/entities/activity_session.dart';
import '../../../activity_history/domain/usecases/save_activity_session.dart';
import '../../../activity_history/presentation/pages/activity_history_page.dart';

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
  final PhysicalActivityType? currentActivity;
  final bool fallTestModeEnabled;
  final int stepCount;
  final double stepsPerMinute;
  final String? errorMessage;

  const FallAlertActive({
    required this.escalated,
    required this.detectedAt,
    this.currentActivity,
    this.fallTestModeEnabled = false,
    this.stepCount = 0,
    this.stepsPerMinute = 0,
    this.errorMessage,
  });

  bool get isMonitoring => true;

  FallAlertActive copyWith({
    bool? escalated,
    PhysicalActivityType? currentActivity,
    bool? fallTestModeEnabled,
    int? stepCount,
    double? stepsPerMinute,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FallAlertActive(
      escalated: escalated ?? this.escalated,
      detectedAt: detectedAt,
      currentActivity: currentActivity ?? this.currentActivity,
      fallTestModeEnabled: fallTestModeEnabled ?? this.fallTestModeEnabled,
      stepCount: stepCount ?? this.stepCount,
      stepsPerMinute: stepsPerMinute ?? this.stepsPerMinute,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  ActivityMonitorActive toActive({
    bool? fallTestModeEnabled,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ActivityMonitorActive(
      currentActivity: currentActivity,
      isMonitoring: true,
      fallTestModeEnabled: fallTestModeEnabled ?? this.fallTestModeEnabled,
      stepCount: stepCount,
      stepsPerMinute: stepsPerMinute,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        escalated,
        detectedAt,
        currentActivity,
        fallTestModeEnabled,
        stepCount,
        stepsPerMinute,
        errorMessage,
      ];
}

extension ActivityMonitorStateX on ActivityMonitorState {
  bool get isSessionActive {
    if (this is ActivityMonitorActive) {
      return (this as ActivityMonitorActive).isMonitoring;
    }
    return this is FallAlertActive;
  }

  ActivityMonitorActive? get sessionSnapshot {
    if (this is ActivityMonitorActive) {
      return this as ActivityMonitorActive;
    }
    if (this is FallAlertActive) {
      return (this as FallAlertActive).toActive();
    }
    return null;
  }
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
  ActivityMonitorBloc({
    required MonitorActivityUseCase monitorActivity,
    SaveActivitySession? saveActivitySession,
  })  : _monitorActivity = monitorActivity,
        _saveActivitySession = saveActivitySession,
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
  final SaveActivitySession? _saveActivitySession;
  StreamSubscription<domain.ActivityMonitorEvent>? _subscription;
  Timer? _fallTimer;
  DateTime? _sessionStartedAt;

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
      return;
    }

    _sessionStartedAt = DateTime.now();
  }

  Future<void> _onStopMonitoring(
    StopMonitoring event,
    Emitter<ActivityMonitorState> emit,
  ) async {
    final snapshot = state.sessionSnapshot;
    if (snapshot != null && _sessionStartedAt != null) {
      await _persistSession(snapshot);
    }

    _sessionStartedAt = null;
    _fallTimer?.cancel();
    _monitorActivity.setFallAlertActive(false);
    await _subscription?.cancel();
    await _monitorActivity.stop();
    emit(const ActivityMonitorIdle());
  }

  Future<void> _persistSession(ActivityMonitorActive sessionState) async {
    final saveSession = _saveActivitySession;
    final startedAt = _sessionStartedAt;
    if (saveSession == null || startedAt == null) {
      return;
    }

    final duration = DateTime.now().difference(startedAt);
    if (duration.inSeconds < 1 && sessionState.stepCount == 0) {
      return;
    }

    await saveSession(
      ActivitySession(
        date: startedAt,
        duration: duration,
        totalSteps: sessionState.stepCount,
        primaryActivityType: activityTypeToStorage(sessionState.currentActivity),
      ),
    );
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
      if (state is FallAlertActive) {
        final current = state as FallAlertActive;
        emit(
          current.copyWith(
            stepCount: monitorEvent.stepData.stepCount,
            stepsPerMinute: monitorEvent.stepData.stepsPerMinute,
          ),
        );
        return;
      }

      final current = state;
      if (current is ActivityMonitorActive) {
        emit(
          current.copyWith(
            stepCount: monitorEvent.stepData.stepCount,
            stepsPerMinute: monitorEvent.stepData.stepsPerMinute,
            isMonitoring: true,
          ),
        );
      } else {
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
      if (state is FallAlertActive) {
        return;
      }

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

    final current = state;
    final active = current is ActivityMonitorActive
        ? current
        : current is FallAlertActive
            ? current.toActive()
            : const ActivityMonitorActive(isMonitoring: true);

    _monitorActivity.setFallAlertActive(true);
    emit(
      FallAlertActive(
        escalated: false,
        detectedAt: detectedAt,
        currentActivity: active.currentActivity,
        fallTestModeEnabled: active.fallTestModeEnabled,
        stepCount: active.stepCount,
        stepsPerMinute: active.stepsPerMinute,
        errorMessage: active.errorMessage,
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
    if (current is ActivityMonitorActive) {
      final enabled = !current.fallTestModeEnabled;
      _monitorActivity.setFallTestSensitivity(enabled);
      emit(current.copyWith(fallTestModeEnabled: enabled));
      return;
    }

    if (current is FallAlertActive) {
      final enabled = !current.fallTestModeEnabled;
      _monitorActivity.setFallTestSensitivity(enabled);
      emit(current.copyWith(fallTestModeEnabled: enabled));
    }
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
    _monitorActivity.setFallAlertActive(false);
    _monitorActivity.resetFallDetector();
    final testMode = _monitorActivity.fallTestSensitivity;
    final current = state;

    emit(
      current is FallAlertActive
          ? current.toActive(fallTestModeEnabled: testMode, clearError: true)
          : ActivityMonitorActive(
              isMonitoring: true,
              fallTestModeEnabled: testMode,
            ),
    );
  }

  void _onFallNeedsHelp(
    FallNeedsHelp event,
    Emitter<ActivityMonitorState> emit,
  ) {
    _fallTimer?.cancel();
    _monitorActivity.setFallAlertActive(false);
    _monitorActivity.resetFallDetector();
    final testMode = _monitorActivity.fallTestSensitivity;
    final current = state;

    emit(
      current is FallAlertActive
          ? current.toActive(
              fallTestModeEnabled: testMode,
              errorMessage: 'Alerta registrada: necesitas ayuda',
            )
          : ActivityMonitorActive(
              isMonitoring: true,
              fallTestModeEnabled: testMode,
              errorMessage: 'Alerta registrada: necesitas ayuda',
            ),
    );
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
