import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Route;

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
  Route _route = Route();

  StreamSubscription<LocationPoint>? _subscription;
  Timer? _metricsTimer;
  bool _isTracking = false;
  String _statusMessage = 'Presiona Iniciar para comenzar';
  DateTime? _lastPointAddedAt;

  @override
  void dispose() {
    _subscription?.cancel();
    _metricsTimer?.cancel();
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

    _subscription?.cancel();
    _route = Route();
    _lastPointAddedAt = null;
    _subscription = _dataSource.locationStream.listen(
      (point) {
        if (!_shouldAcceptPoint(point)) {
          return;
        }

        final lastPoint =
            _route.points.isEmpty ? null : _route.points.last;
        if (lastPoint != null) {
          final distance = lastPoint.distanceTo(point);
          if (distance < LocationPoint.minDistanceBetweenPointsMeters) {
            return;
          }
        }

        setState(() {
          _route.addPoint(point);
          _lastPointAddedAt = DateTime.now();
          _statusMessage =
              'Registrando ruta · ${_route.points.length} puntos';
        });
      },
      onError: (error) {
        setState(() => _statusMessage = 'Error: $error');
      },
    );

    _startMetricsTimer();
    setState(() {
      _isTracking = true;
      _statusMessage = 'Esperando señal GPS…';
    });
  }

  bool _shouldAcceptPoint(LocationPoint point) {
    if (point.accuracy <= LocationPoint.maxAcceptableAccuracyMeters) {
      return true;
    }

    final lastAdded = _lastPointAddedAt ?? _route.startTime;
    final starving = DateTime.now().difference(lastAdded) >=
        LocationPoint.pointStarvationTimeout;

    return starving && point.accuracy <= LocationPoint.relaxedAccuracyMeters;
  }

  void _startMetricsTimer() {
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isTracking) {
        setState(() {});
      }
    });
  }

  void _stopTracking() {
    _subscription?.cancel();
    _metricsTimer?.cancel();
    _metricsTimer = null;
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
                          value: _formatDistance(_route.distanceKm),
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

  String _formatDistance(double km) {
    if (km < 0.1) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(2)} km';
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
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

    const padding = 24.0;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;

    final centerLat = route.points
            .map((p) => p.latitude)
            .reduce((a, b) => a + b) /
        route.points.length;
    final centerLon = route.points
            .map((p) => p.longitude)
            .reduce((a, b) => a + b) /
        route.points.length;

    const metersPerDegLat = 111320.0;
    final metersPerDegLon =
        metersPerDegLat * math.cos(centerLat * math.pi / 180);

    double toLocalX(LocationPoint point) =>
        (point.longitude - centerLon) * metersPerDegLon;
    double toLocalY(LocationPoint point) =>
        (point.latitude - centerLat) * metersPerDegLat;

    var minX = toLocalX(route.points.first);
    var maxX = minX;
    var minY = toLocalY(route.points.first);
    var maxY = minY;

    for (final point in route.points) {
      final x = toLocalX(point);
      final y = toLocalY(point);
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    var rangeX = maxX - minX;
    var rangeY = maxY - minY;
    if (rangeX < 1) rangeX = 1;
    if (rangeY < 1) rangeY = 1;

    final scale = math.min(drawWidth / rangeX, drawHeight / rangeY);
    final offsetX = padding + (drawWidth - rangeX * scale) / 2;
    final offsetY = padding + (drawHeight - rangeY * scale) / 2;

    Offset toPixel(LocationPoint point) {
      final x = toLocalX(point);
      final y = toLocalY(point);
      return Offset(
        offsetX + (x - minX) * scale,
        offsetY + (maxY - y) * scale,
      );
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
