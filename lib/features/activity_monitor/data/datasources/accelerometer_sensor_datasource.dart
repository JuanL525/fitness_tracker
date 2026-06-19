import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../../domain/entities/accelerometer_sample.dart';

abstract class AccelerometerSensorDataSource {
  Stream<AccelerometerSample> get samples;
  Future<void> start();
  Future<void> stop();
}

class AccelerometerSensorDataSourceImpl implements AccelerometerSensorDataSource {
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<BarometerEvent>? _barometerSubscription;
  final _controller = StreamController<AccelerometerSample>.broadcast();

  double? _latestPressureHpa;

  @override
  Stream<AccelerometerSample> get samples => _controller.stream;

  @override
  Future<void> start() async {
    await stop();

    _barometerSubscription = barometerEventStream().listen(
      (event) {
        _latestPressureHpa = event.pressure;
      },
      onError: (_) {
        _latestPressureHpa = null;
      },
    );

    _accelSubscription = accelerometerEventStream().listen((event) {
      _controller.add(
        AccelerometerSample(
          x: event.x,
          y: event.y,
          z: event.z,
          pressureHpa: _latestPressureHpa,
        ),
      );
    });
  }

  @override
  Future<void> stop() async {
    await _accelSubscription?.cancel();
    await _barometerSubscription?.cancel();
    _accelSubscription = null;
    _barometerSubscription = null;
    _latestPressureHpa = null;
  }
}
