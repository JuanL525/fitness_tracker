class MovementSpeed {
  const MovementSpeed({
    required this.metersPerSecond,
    required this.accuracyMeters,
    required this.timestamp,
  });

  final double metersPerSecond;
  final double accuracyMeters;
  final DateTime timestamp;

  bool isFresh({Duration maxAge = const Duration(seconds: 5)}) {
    return DateTime.now().difference(timestamp) <= maxAge;
  }

  bool get isReliable {
    return isFresh() && accuracyMeters > 0 && accuracyMeters <= 25;
  }
}
