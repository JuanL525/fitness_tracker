import '../../domain/entities/activity_session.dart';
import '../../domain/repositories/activity_history_repository.dart';
import '../datasources/activity_history_local_datasource.dart';

class ActivityHistoryRepositoryImpl implements ActivityHistoryRepository {
  ActivityHistoryRepositoryImpl(this._localDataSource);

  final ActivityHistoryLocalDataSource _localDataSource;

  @override
  Future<int> saveSession(ActivitySession session) {
    return _localDataSource.insertSession(session);
  }

  @override
  Future<List<ActivitySession>> getAllSessions() {
    return _localDataSource.fetchAllSessions();
  }

  @override
  Future<void> deleteSession(int id) {
    return _localDataSource.deleteSession(id);
  }

  @override
  Future<void> updateSession(ActivitySession session) {
    return _localDataSource.updateSession(session);
  }
}
