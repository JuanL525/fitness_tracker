import '../entities/activity_session.dart';
import '../repositories/activity_history_repository.dart';

class SaveActivitySession {
  SaveActivitySession(this._repository);

  final ActivityHistoryRepository _repository;

  Future<int> call(ActivitySession session) {
    return _repository.saveSession(session);
  }
}
