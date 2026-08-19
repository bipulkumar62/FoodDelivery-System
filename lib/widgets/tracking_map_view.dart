import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/live_location.dart';

/// Lightweight canvas map: projects coordinates into the widget rectangle.
/// Keeps the customer app free of map SDK/API-key dependencies while still
/// giving a real moving marker, grid background and destination pin.
class TrackingMapView extends StatefulWidget {
  final LiveLocation? location;
  final double? destinationLat;
  final double? destinationLng;
  final double height;

  const TrackingMapView({
    super.key,
    required this.location,
    this.destinationLat,
    this.destinationLng,
    this.height = 220,
  });

  @override
  State<TrackingMapView> createState() => _TrackingMapViewState();
}

class _TrackingMapViewState extends State<TrackingMapView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  LiveLocation? _from;
  LiveLocation? _to;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _to = widget.location;
  }

  @override
  void didUpdateWidget(covariant TrackingMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.location;
    if (incoming == null) return;
    if (_to == null ||
        _to!.latitude != incoming.latitude ||
        _to!.longitude != incoming.longitude) {
      // Smooth movement: lerp from the previous painted position to the new
      // coordinate instead of jumping.
      setState(() {
        _from = _to;
        _to = incoming;
      });
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LiveLocation? _paintedPosition() {
    if (_to == null) return null;
    if (_from == null) return _to;
    final t = Curves.easeInOut.transform(_controller.value);
    return LiveLocation.lerp(_from!, _to!, t);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final position = _paintedPosition();
          final lats = <double>[];
          final lngs = <double>[];

          void addPoint(double lat, double lng) {
            lats.add(lat);
            lngs.add(lng);
          }

          if (position != null) {
            addPoint(position.latitude, position.longitude);
          }
          if (widget.destinationLat != null && widget.destinationLng != null) {
            addPoint(widget.destinationLat!, widget.destinationLng!);
          }

          return CustomPaint(
            size: Size.infinite,
            painter: _TrackingMapPainter(
              position: position,
              accuracy: position?.accuracy ?? 0,
              destinationLat: widget.destinationLat,
              destinationLng: widget.destinationLng,
              lats: lats,
              lngs: lngs,
            ),
          );
        },
      ),
    );
  }
}

class _TrackingMapPainter extends CustomPainter {
  final LiveLocation? position;
  final double accuracy;
  final double? destinationLat;
  final double? destinationLng;
  final List<double> lats;
  final List<double> lngs;

  _TrackingMapPainter({
    required this.position,
    required this.accuracy,
    required this.destinationLat,
    required this.destinationLng,
    required this.lats,
    required this.lngs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF0F2F5),
    );

    if (lats.isEmpty || lngs.isEmpty) {
      return;
    }

    // Bounds with padding.
    var minLat = lats.reduce((a, b) => a < b ? a : b);
    var maxLat = lats.reduce((a, b) => a > b ? a : b);
    var minLng = lngs.reduce((a, b) => a < b ? a : b);
    var maxLng = lngs.reduce((a, b) => a > b ? a : b);

    final latSpan = (maxLat - minLat).abs();
    final lngSpan = (maxLng - minLng).abs();
    final pad = (latSpan > lngSpan ? latSpan : lngSpan) * 0.4 + 0.0012;
    minLat -= pad;
    maxLat += pad;
    minLng -= pad;
    maxLng += pad;

    Offset project(double lat, double lng) {
      final x = ((lng - minLng) / (maxLng - minLng)) * size.width;
      final y = ((maxLat - lat) / (maxLat - minLat)) * size.height;
      return Offset(x, y);
    }

    // Grid lines.
    final gridPaint = Paint()
      ..color = const Color(0xFFDDE1E6)
      ..strokeWidth = 0.7;
    const gridSteps = 7;
    for (var i = 1; i < gridSteps; i++) {
      final x = size.width * i / gridSteps;
      final y = size.height * i / gridSteps;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Destination pin.
    if (destinationLat != null && destinationLng != null) {
      final d = project(destinationLat!, destinationLng!);
      canvas.drawCircle(
        d,
        10,
        Paint()..color = Colors.purple.shade700,
      );
      canvas.drawCircle(
        d,
        10,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      final stem = Path()
        ..moveTo(d.dx - 5, d.dy + 8)
        ..lineTo(d.dx, d.dy + 22)
        ..lineTo(d.dx + 5, d.dy + 8);
      canvas.drawPath(stem, Paint()..color = Colors.purple.shade700);
    }

    // Rider marker with accuracy halo.
    final pos = position;
    if (pos != null) {
      final p = project(pos.latitude, pos.longitude);

      final haloRadius = (accuracy.clamp(5, 200) / 200 * 26) + 10;
      canvas.drawCircle(
        p,
        haloRadius,
        Paint()
          ..color = AppTheme.primaryColor.withValues(alpha: 0.18),
      );
      canvas.drawCircle(
        p,
        haloRadius,
        Paint()
          ..color = AppTheme.primaryColor.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(p, 10, Paint()..color = AppTheme.primaryColor);
      canvas.drawCircle(
        p,
        10,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      canvas.drawCircle(
        p,
        3.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
    }

    // North-up clue label.
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'RIDER DELIVERY MAP',
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 1.2,
          color: Color(0xFF9AA3AB),
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(12, size.height - textPainter.height - 10));
  }

  @override
  bool shouldRepaint(covariant _TrackingMapPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.accuracy != accuracy ||
        oldDelegate.lats != lats ||
        oldDelegate.lngs != lngs ||
        oldDelegate.destinationLat != destinationLat ||
        oldDelegate.destinationLng != destinationLng;
  }
}