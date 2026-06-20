import '../../domain/entities/activity_session.dart';
import '../database/database_provider.dart';

abstract class ActivityHistoryLocalDataSource {
  Future<int> insertSession(ActivitySession session);
  Future<List<ActivitySession>> fetchAllSessions();
  Future<void> deleteSession(int id);
  Future<void> updateSession(ActivitySession session);
}

class ActivityHistoryLocalDataSourceImpl
    implements ActivityHistoryLocalDataSource {
  ActivityHistoryLocalDataSourceImpl(this._databaseProvider);

  final DatabaseProvider _databaseProvider;

  static const _tableName = 'activity_history';

  @override
  Future<int> insertSession(ActivitySession session) async {
    final db = await _databaseProvider.database;
    return db.insert(_tableName, _toMap(session));
  }

  @override
  Future<List<ActivitySession>> fetchAllSessions() async {
    final db = await _databaseProvider.database;
    final rows = await db.query(
      _tableName,
      orderBy: 'date DESC',
    );
    return rows.map(_fromMap).toList();
  }

  @override
  Future<void> deleteSession(int id) async {
    final db = await _databaseProvider.database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateSession(ActivitySession session) async {
    final id = session.id;
    if (id == null) {
      throw ArgumentError('Session id is required for update');
    }

    final db = await _databaseProvider.database;
    await db.update(
      _tableName,
      _toMap(session),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Map<String, Object> _toMap(ActivitySession session) {
    return {
      if (session.id != null) 'id': session.id!,
      'date': session.date.toIso8601String(),
      'duration_seconds': session.duration.inSeconds,
      'total_steps': session.totalSteps,
      'primary_activity_type': session.primaryActivityType,
    };
  }

  ActivitySession _fromMap(Map<String, Object?> row) {
    return ActivitySession(
      id: row['id'] as int?,
      date: DateTime.parse(row['date'] as String),
      duration: Duration(seconds: row['duration_seconds'] as int),
      totalSteps: row['total_steps'] as int,
      primaryActivityType: row['primary_activity_type'] as String,
    );
  }
}
