import 'dart:async';

import '../entities/physical_activity_type.dart';

class ActivityDebouncer {
  ActivityDebouncer({
    this.stabilityDuration = const Duration(milliseconds: 400),
    this.paceChangeDuration = const Duration(milliseconds: 600),
    this.stationaryDuration = const Duration(milliseconds: 900),
  });

  final Duration stabilityDuration;
  final Duration paceChangeDuration;
  final Duration stationaryDuration;
  PhysicalActivityType? _candidate;
  PhysicalActivityType? _lastAnnounced;
  Timer? _timer;
  void Function(PhysicalActivityType type, bool isFirst)? _onConfirmed;

  void listen(void Function(PhysicalActivityType type, bool isFirst) onConfirmed) {
    _onConfirmed = onConfirmed;
  }

  void onCandidate(PhysicalActivityType type) {
    if (_candidate == type && _timer?.isActive == true) {
      return;
    }

    if (_candidate == type && _lastAnnounced == type) {
      return;
    }

    if (type == PhysicalActivityType.stationary &&
        _lastAnnounced == PhysicalActivityType.stationary) {
      return;
    }

    _candidate = type;
    _timer?.cancel();
    _timer = Timer(_durationFor(type), () {
      if (_candidate == null || _candidate == _lastAnnounced) {
        return;
      }

      final isFirst = _lastAnnounced == null;
      _lastAnnounced = _candidate;
      _onConfirmed?.call(_candidate!, isFirst);
    });
  }

  Duration _durationFor(PhysicalActivityType type) {
    if (type == PhysicalActivityType.stationary) {
      return stationaryDuration;
    }

    final last = _lastAnnounced;
    if (last != null &&
        last != PhysicalActivityType.stationary &&
        type != PhysicalActivityType.stationary &&
        last != type) {
      return paceChangeDuration;
    }

    return stabilityDuration;
  }

  void reset() {
    _timer?.cancel();
    _candidate = null;
    _lastAnnounced = null;
  }

  void cancelPending() {
    _timer?.cancel();
    _candidate = null;
  }

  void dispose() {
    _timer?.cancel();
    _onConfirmed = null;
  }

  PhysicalActivityType? get lastAnnounced => _lastAnnounced;
}
