import 'package:permission_handler/permission_handler.dart';

import '../../../auth/data/datasources/sensors_step_engine.dart';
import '../../../auth/domain/entities/step_data.dart';

abstract class PlatformStepDataSource {
  Stream<StepData> get stepStream;
  Future<void> start();
  Future<void> stop();
  Future<bool> requestPermissions();
}

class PlatformStepDataSourceImpl implements PlatformStepDataSource {
  PlatformStepDataSourceImpl({SensorsStepEngine? engine})
      : _engine = engine ?? SensorsStepEngine();

  final SensorsStepEngine _engine;

  @override
  Stream<StepData> get stepStream => _engine.stream;

  @override
  Future<void> start() => _engine.start();

  @override
  Future<void> stop() => _engine.stop();

  @override
  Future<bool> requestPermissions() async {
    final activityStatus = await Permission.activityRecognition.request();
    return activityStatus.isGranted;
  }
}
