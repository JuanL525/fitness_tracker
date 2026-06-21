import 'package:get_it/get_it.dart';

import '../../features/activity_history/data/database/database_provider.dart';
import '../../features/activity_history/data/datasources/activity_history_local_datasource.dart';
import '../../features/activity_history/data/repositories/activity_history_repository_impl.dart';
import '../../features/activity_history/domain/repositories/activity_history_repository.dart';
import '../../features/activity_history/domain/usecases/delete_activity_session.dart';
import '../../features/activity_history/domain/usecases/get_all_activity_sessions.dart';
import '../../features/activity_history/domain/usecases/save_activity_session.dart';
import '../../features/activity_history/domain/usecases/update_activity_session.dart';
import '../../features/auth/data/datasources/accelerometer_datasource.dart';
import '../../features/auth/data/datasources/biometric_datasource.dart';
import '../../features/auth/domain/usecases/authenticate_user.dart';
import '../../features/tracking/data/datasources/gps_datasource.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  if (getIt.isRegistered<DatabaseProvider>()) {
    return;
  }

  getIt.registerLazySingleton<DatabaseProvider>(() => DatabaseProvider());

  getIt.registerLazySingleton<BiometricDataSource>(
    () => BiometricDataSourceImpl(),
  );

  getIt.registerFactory<AccelerometerDataSource>(
    () => AccelerometerDataSourceImpl(),
  );

  getIt.registerLazySingleton<GpsDataSource>(
    () => GpsDataSourceImpl(),
  );

  getIt.registerLazySingleton<ActivityHistoryLocalDataSource>(
    () => ActivityHistoryLocalDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<ActivityHistoryRepository>(
    () => ActivityHistoryRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton(() => SaveActivitySession(getIt()));
  getIt.registerLazySingleton(() => GetAllActivitySessions(getIt()));
  getIt.registerLazySingleton(() => DeleteActivitySession(getIt()));
  getIt.registerLazySingleton(() => UpdateActivitySession(getIt()));

  getIt.registerLazySingleton(
    () => AuthenticateUser(getIt<BiometricDataSource>()),
  );
}
