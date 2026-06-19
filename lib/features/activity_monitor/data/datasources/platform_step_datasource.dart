import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/platform/platform_channels.dart';
import '../../../auth/domain/entities/step_data.dart';

abstract class PlatformStepDataSource {
  Stream<StepData> get stepStream;
  Future<void> start();
  Future<void> stop();
  Future<bool> requestPermissions();
}

class PlatformStepDataSourceImpl implements PlatformStepDataSource {
  final EventChannel _eventChannel = const EventChannel(
    PlatformChannels.accelerometer,
  );

  @override
  Stream<StepData> get stepStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      return StepData.fromMap(event as Map<dynamic, dynamic>);
    });
  }

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<bool> requestPermissions() async {
    final activityStatus = await Permission.activityRecognition.request();
    final sensorsStatus = await Permission.sensors.request();
    return activityStatus.isGranted && sensorsStatus.isGranted;
  }
}
