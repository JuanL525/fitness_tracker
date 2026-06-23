/// Suaviza lecturas ruidosas de velocidad GPS (media móvil exponencial).
class SpeedSmoother {
  SpeedSmoother({this.alpha = 0.35});

  final double alpha;
  double? _smoothed;

  void reset() {
    _smoothed = null;
  }

  double smooth(double metersPerSecond) {
    final clamped = metersPerSecond.isNaN || metersPerSecond < 0
        ? 0.0
        : metersPerSecond;
    _smoothed ??= clamped;
    _smoothed = alpha * clamped + (1 - alpha) * _smoothed!;
    return _smoothed!;
  }
}
