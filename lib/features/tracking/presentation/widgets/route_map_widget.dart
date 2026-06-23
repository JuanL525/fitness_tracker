import 'package:flutter/material.dart' hide Route;
import 'dart:async';

import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/gps_datasource.dart';
import '../../domain/entities/location_point.dart';

class RouteMapWidget extends StatefulWidget {
  const RouteMapWidget({super.key});

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  late final GpsDataSource _dataSource = getIt<GpsDataSource>();
  final Route _route = Route();

  StreamSubscription<LocationPoint>? _subscription;
  bool _isTracking = false;
  String _statusMessage = 'Presiona Iniciar para comenzar';

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      _stopTracking();
    } else {
      await _startTracking();
    }
  }

  Future<void> _startTracking() async {
    final hasPermission = await _dataSource.requestPermissions();
    if (!hasPermission) {
      setState(() => _statusMessage = 'Permisos denegados');
      return;
    }

    final gpsEnabled = await _dataSource.isGpsEnabled();
    if (!gpsEnabled) {
      setState(() => _statusMessage = 'Activa el GPS del dispositivo');
      return;
    }

    _subscription = _dataSource.locationStream.listen(
      (point) {
        // Filtro de precisión: descartar puntos con mucho error horizontal.
        if (point.accuracy > LocationPoint.maxAcceptableAccuracyMeters) {
          return;
        }

        if (_route.points.isEmpty) {
          setState(() {
            _route.addPoint(point);
            _statusMessage =
                'Registrando ruta · ${_route.points.length} puntos';
          });
        } else {
          final lastPoint = _route.points.last;
          final distance = lastPoint.distanceTo(point);

          // Anti-spaghetti: solo añadir si hay movimiento real ≥ 1 m.
          if (distance >= LocationPoint.minDistanceBetweenPointsMeters) {
            setState(() {
              _route.addPoint(point);
              _statusMessage =
                  'Registrando ruta · ${_route.points.length} puntos';
            });
          }
        }
      },
      onError: (error) {
        setState(() => _statusMessage = 'Error: $error');
      },
    );

    setState(() {
      _isTracking = true;
      _statusMessage = 'Esperando señal GPS…';
    });
  }

  void _stopTracking() {
    _subscription?.cancel();
    _route.finish();
    setState(() {
      _isTracking = false;
      _statusMessage = 'Ruta finalizada';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: AppTheme.screenPadding.copyWith(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ruta GPS', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(_statusMessage, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            Container(
              decoration: AppTheme.cardDecoration(),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    height: 240,
                    color: AppTheme.slate800.withValues(alpha: 0.4),
                    child: CustomPaint(
                      painter: RoutePainter(
                        route: _route,
                        routeColor: AppTheme.blue400,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        _RouteMetric(
                          label: 'DISTANCIA',
                          value: '${_route.distanceKm.toStringAsFixed(2)} km',
                          color: AppTheme.blue400,
                        ),
                        _RouteMetric(
                          label: 'TIEMPO',
                          value: _formatDuration(_route.duration),
                          color: AppTheme.emerald400,
                        ),
                        _RouteMetric(
                          label: 'VELOC.',
                          value:
                              '${_route.averageSpeed.toStringAsFixed(1)} km/h',
                          color: AppTheme.emerald400,
                        ),
                        _RouteMetric(
                          label: 'CALORÍAS',
                          value: _route.estimatedCalories.toStringAsFixed(0),
                          color: AppTheme.rose500,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _GpsToggleButton(
              isTracking: _isTracking,
              onPressed: _toggleTracking,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GpsToggleButton extends StatelessWidget {
  const _GpsToggleButton({
    required this.isTracking,
    required this.onPressed,
  });

  final bool isTracking;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isTracking) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppTheme.rose500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.rose500, width: 2),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.square, color: AppTheme.rose500, size: 18),
                SizedBox(width: 10),
                Text(
                  'DETENER GPS',
                  style: TextStyle(
                    color: AppTheme.rose500,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.blue400, Color(0xFF2563EB)],
            ),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.map, color: AppTheme.slate950, size: 20),
              SizedBox(width: 10),
              Text(
                'INICIAR GPS',
                style: TextStyle(
                  color: AppTheme.slate950,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoutePainter extends CustomPainter {
  RoutePainter({required this.route, required this.routeColor});

  final Route route;
  final Color routeColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (route.points.isEmpty) {
      const textStyle = TextStyle(
        color: AppTheme.slate500,
        fontSize: 15,
        letterSpacing: 0.2,
      );
      final textPainter = TextPainter(
        text: const TextSpan(text: 'Sin datos de ruta', style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
      return;
    }

    double minLat = route.points.first.latitude;
    double maxLat = route.points.first.latitude;
    double minLon = route.points.first.longitude;
    double maxLon = route.points.first.longitude;

    for (final point in route.points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }

    const padding = 24.0;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;

    Offset toPixel(LocationPoint point) {
      final latRange = maxLat - minLat;
      final lonRange = maxLon - minLon;
      final x = lonRange == 0
          ? drawWidth / 2
          : ((point.longitude - minLon) / lonRange) * drawWidth;
      final y = latRange == 0
          ? drawHeight / 2
          : ((maxLat - point.latitude) / latRange) * drawHeight;
      return Offset(x + padding, y + padding);
    }

    final linePaint = Paint()
      ..color = routeColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(toPixel(route.points.first).dx, toPixel(route.points.first).dy);
    for (int i = 1; i < route.points.length; i++) {
      final pixel = toPixel(route.points[i]);
      path.lineTo(pixel.dx, pixel.dy);
    }
    canvas.drawPath(path, linePaint);

    canvas.drawCircle(
      toPixel(route.points.first),
      8,
      Paint()..color = AppTheme.emerald400,
    );
    canvas.drawCircle(
      toPixel(route.points.last),
      8,
      Paint()..color = AppTheme.rose500,
    );
  }

  @override
  bool shouldRepaint(RoutePainter oldDelegate) {
    return oldDelegate.route.points.length != route.points.length;
  }
}
