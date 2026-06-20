import '../entities/activity_session.dart';

abstract class ActivityHistoryRepository {
  Future<int> saveSession(ActivitySession session);
  Future<List<ActivitySession>> getAllSessions();
  Future<void> deleteSession(int id);
  Future<void> updateSession(ActivitySession session);
}
