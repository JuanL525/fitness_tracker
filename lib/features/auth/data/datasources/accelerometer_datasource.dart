import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/step_data.dart';
import 'sensors_step_engine.dart';

abstract class AccelerometerDataSource {
  Stream<StepData> get stepStream;
  Future<void> startCounting();
  Future<void> stopCounting();
  Future<bool> requestPermissions();
}

class AccelerometerDataSourceImpl implements AccelerometerDataSource {
  AccelerometerDataSourceImpl({SensorsStepEngine? engine})
      : _engine = engine ?? SensorsStepEngine();

  final SensorsStepEngine _engine;

  @override
  Stream<StepData> get stepStream => _engine.stream;

  @override
  Future<void> startCounting() => _engine.start();

  @override
  Future<void> stopCounting() => _engine.stop();

  @override
  Future<bool> requestPermissions() async {
    final activityStatus = await Permission.activityRecognition.request();
    final sensorsStatus = await Permission.sensors.request();
    return activityStatus.isGranted && sensorsStatus.isGranted;
  }
}
