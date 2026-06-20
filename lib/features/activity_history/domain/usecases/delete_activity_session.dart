import '../repositories/activity_history_repository.dart';

class DeleteActivitySession {
  DeleteActivitySession(this._repository);

  final ActivityHistoryRepository _repository;

  Future<void> call(int id) {
    return _repository.deleteSession(id);
  }
}
