import '../entities/activity_session.dart';
import '../repositories/activity_history_repository.dart';

class UpdateActivitySession {
  UpdateActivitySession(this._repository);

  final ActivityHistoryRepository _repository;

  Future<void> call(ActivitySession session) {
    return _repository.updateSession(session);
  }
}
