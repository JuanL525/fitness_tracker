import 'package:flutter/material.dart';

import '../../../activity_monitor/domain/entities/physical_activity_type.dart';
import '../../domain/entities/activity_session.dart';
import '../../domain/usecases/delete_activity_session.dart';
import '../../domain/usecases/get_all_activity_sessions.dart';
import '../../domain/usecases/update_activity_session.dart';

class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({
    super.key,
    required this.getAllSessions,
    required this.deleteSession,
    required this.updateSession,
  });

  final GetAllActivitySessions getAllSessions;
  final DeleteActivitySession deleteSession;
  final UpdateActivitySession updateSession;

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  late Future<List<ActivitySession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = widget.getAllSessions();
  }

  Future<void> _reload() async {
    setState(() {
      _sessionsFuture = widget.getAllSessions();
    });
    await _sessionsFuture;
  }

  Future<void> _confirmDelete(ActivitySession session) async {
    final id = session.id;
    if (id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar sesión'),
        content: const Text('¿Deseas eliminar este registro del historial?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await widget.deleteSession(id);
    await _reload();
  }

  Future<void> _editSession(ActivitySession session) async {
    final stepsController = TextEditingController(
      text: session.totalSteps.toString(),
    );
    var selectedActivity = session.primaryActivityType;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar sesión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stepsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pasos totales',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedActivity,
              decoration: const InputDecoration(
                labelText: 'Actividad principal',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'stationary',
                  child: Text('Quieto'),
                ),
                DropdownMenuItem(
                  value: 'walking',
                  child: Text('Caminando'),
                ),
                DropdownMenuItem(
                  value: 'running',
                  child: Text('Corriendo'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  selectedActivity = value;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) {
      stepsController.dispose();
      return;
    }

    final parsedSteps = int.tryParse(stepsController.text.trim());
    stepsController.dispose();

    if (parsedSteps == null || session.id == null) {
      return;
    }

    await widget.updateSession(
      session.copyWith(
        totalSteps: parsedSteps,
        primaryActivityType: selectedActivity,
      ),
    );
    await _reload();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}m ${seconds}s';
  }

  String _activityLabel(String type) {
    switch (type) {
      case 'walking':
        return 'Caminando';
      case 'running':
        return 'Corriendo';
      default:
        return 'Quieto';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de actividad'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<ActivitySession>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar historial: ${snapshot.error}'),
            );
          }

          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return const Center(
              child: Text(
                'No hay sesiones guardadas.\nDetén el monitor para registrar una.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      _activityLabel(session.primaryActivityType),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${session.date.day}/${session.date.month}/${session.date.year} '
                      '· ${_formatDuration(session.duration)}\n'
                      '${session.totalSteps} pasos',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editSession(session),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(session),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

String activityTypeToStorage(PhysicalActivityType? type) {
  switch (type) {
    case PhysicalActivityType.walking:
      return 'walking';
    case PhysicalActivityType.running:
      return 'running';
    case PhysicalActivityType.stationary:
    case null:
      return 'stationary';
  }
}
