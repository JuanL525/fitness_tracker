import 'package:permission_handler/permission_handler.dart';

abstract class SensorPermissionsDataSource {
  Future<bool> requestSensorPermissions();
}

class SensorPermissionsDataSourceImpl implements SensorPermissionsDataSource {
  @override
  Future<bool> requestSensorPermissions() async {
    final permissions = [
      Permission.activityRecognition,
      Permission.sensors,
    ];

    final statuses = await permissions.request();
    final activityGranted =
        statuses[Permission.activityRecognition]?.isGranted ?? false;
    final sensorsGranted = statuses[Permission.sensors]?.isGranted ?? false;

    return activityGranted && sensorsGranted;
  }
}
