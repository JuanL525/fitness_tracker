import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_animations.dart';
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
    this.embedded = false,
  });

  final GetAllActivitySessions getAllSessions;
  final DeleteActivitySession deleteSession;
  final UpdateActivitySession updateSession;
  final bool embedded;

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
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(LucideIcons.trash_2,
            color: AppTheme.rose500, size: 32),
        title: const Text('Eliminar sesión'),
        content: const Text(
          '¿Deseas eliminar este registro del historial? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.rose500),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

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
        icon: const Icon(LucideIcons.pencil,
            color: AppTheme.emerald400, size: 32),
        title: const Text('Editar sesión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stepsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pasos totales',
                prefixIcon: Icon(LucideIcons.footprints),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: selectedActivity,
              decoration: const InputDecoration(
                labelText: 'Actividad principal',
                prefixIcon: Icon(LucideIcons.activity),
              ),
              items: const [
                DropdownMenuItem(value: 'stationary', child: Text('Quieto')),
                DropdownMenuItem(value: 'walking', child: Text('Caminando')),
                DropdownMenuItem(value: 'running', child: Text('Corriendo')),
              ],
              onChanged: (value) {
                if (value != null) selectedActivity = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
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

    if (parsedSteps == null || session.id == null) return;

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
        return 'Caminar';
      case 'running':
        return 'Correr';
      default:
        return 'Quieto';
    }
  }

  IconData _activityLucideIcon(String type) {
    switch (type) {
      case 'walking':
        return LucideIcons.footprints;
      case 'running':
        return LucideIcons.zap;
      default:
        return LucideIcons.armchair;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = widget.embedded ? 100.0 : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.slate950,
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Historial de actividad')),
      body: FutureBuilder<List<ActivitySession>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.emerald400),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: AppTheme.screenPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.circle_alert,
                        size: 48, color: AppTheme.rose500),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar historial',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          }

          final sessions = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.embedded)
                Padding(
                  padding: AppTheme.screenPadding.copyWith(
                    top: MediaQuery.of(context).padding.top + 12,
                    bottom: 0,
                  ),
                  child: Text(
                    'Historial',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              Expanded(
                child: sessions.isEmpty
                    ? FadeSlideIn(
                        child: Center(
                          child: Padding(
                            padding: AppTheme.screenPadding,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppTheme.slate900,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.slate800,
                                    ),
                                  ),
                                  child: const Icon(
                                    LucideIcons.history,
                                    size: 48,
                                    color: AppTheme.blue400,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Sin sesiones guardadas',
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Inicia el monitor y presiona Detener para registrar tu primera sesión.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _reload,
                        color: AppTheme.emerald400,
                        backgroundColor: AppTheme.slate900,
                        child: ListView.builder(
                          padding: AppTheme.screenPadding.copyWith(
                            top: widget.embedded ? 16 : 8,
                            bottom: bottomPad + 16,
                          ),
                          itemCount: sessions.length,
                          itemBuilder: (context, index) {
                            final session = sessions[index];
                            final accent =
                                AppTheme.activityColor(
                                    session.primaryActivityType);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: FadeSlideIn(
                                delay: Duration(milliseconds: 50 * index),
                                offsetY: 16,
                                child: _SessionCard(
                                  session: session,
                                  accent: accent,
                                  activityLabel: _activityLabel(
                                    session.primaryActivityType,
                                  ),
                                  activityIcon: _activityLucideIcon(
                                    session.primaryActivityType,
                                  ),
                                  formattedDate: _formatDate(session.date),
                                  formattedDuration:
                                      _formatDuration(session.duration),
                                  onEdit: () => _editSession(session),
                                  onDelete: () => _confirmDelete(session),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.accent,
    required this.activityLabel,
    required this.activityIcon,
    required this.formattedDate,
    required this.formattedDuration,
    required this.onEdit,
    required this.onDelete,
  });

  final ActivitySession session;
  final Color accent;
  final String activityLabel;
  final IconData activityIcon;
  final String formattedDate;
  final String formattedDuration;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(activityIcon, color: accent, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activityLabel,
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppTheme.slate400),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Editar',
                          icon: const Icon(LucideIcons.pencil, size: 18),
                          color: AppTheme.slate400,
                          onPressed: onEdit,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(36, 36),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Eliminar',
                          icon: const Icon(LucideIcons.trash_2, size: 18),
                          color: AppTheme.rose500,
                          onPressed: onDelete,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(36, 36),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatColumn(
                            label: 'TIEMPO',
                            value: formattedDuration,
                          ),
                        ),
                        Expanded(
                          child: _StatColumn(
                            label: 'PASOS',
                            value: '${session.totalSteps}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.slate100,
          ),
        ),
      ],
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
