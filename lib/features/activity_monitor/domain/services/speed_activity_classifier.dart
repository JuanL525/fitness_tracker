import '../entities/physical_activity_type.dart';

/// GPS solo para quietud; umbrales amplios para evitar saltos.
class SpeedActivityClassifier {
  static const double enterWalking = 0.9;
  static const double exitWalking = 0.4;
  static const double enterRunning = 3.5;
  static const double exitRunning = 2.8;
  static const double enterStationary = 0.35;

  PhysicalActivityType _state = PhysicalActivityType.stationary;

  void reset() {
    _state = PhysicalActivityType.stationary;
  }

  PhysicalActivityType get current => _state;

  /// Solo distingue quieto vs en movimiento (no caminar/correr fino).
  PhysicalActivityType classifyMovement(double metersPerSecond) {
    if (_state == PhysicalActivityType.stationary) {
      if (metersPerSecond >= enterWalking) {
        return _state = PhysicalActivityType.walking;
      }
      return _state;
    }

    if (metersPerSecond <= enterStationary) {
      return _state = PhysicalActivityType.stationary;
    }

    return _state == PhysicalActivityType.stationary
        ? PhysicalActivityType.walking
        : _state;
  }

  bool isLikelyStationary(double metersPerSecond) {
    return metersPerSecond <= enterStationary;
  }
}
