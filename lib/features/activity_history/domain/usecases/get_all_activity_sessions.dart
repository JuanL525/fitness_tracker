import '../entities/activity_session.dart';
import '../repositories/activity_history_repository.dart';

class GetAllActivitySessions {
  GetAllActivitySessions(this._repository);

  final ActivityHistoryRepository _repository;

  Future<List<ActivitySession>> call() {
    return _repository.getAllSessions();
  }
}
