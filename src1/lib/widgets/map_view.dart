import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';  
import '../models/alert.dart';

class MapView extends StatefulWidget {
  final List<Alert> alerts;
  final Alert? selectedAlert;
  final MapMode mapMode;
  final Function(MapMode) onMapModeChange;
  final String selectedDate;
  final Function(String) onDateChange;
  final List<String> availableDates;

  const MapView({
    super.key,
    required this.alerts,
    required this.selectedAlert,
    required this.mapMode,
    required this.onMapModeChange,
    required this.selectedDate,
    required this.onDateChange,
    required this.availableDates,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _mapController;
// change map center to earthexplorer lat lon values
  LatLng _anchorLatLng = const LatLng(42, -96);

  Offset? _anchorPx;
  double _radiusPx = 200; 
  double _currentZoom = 7.0;

  double _desiredRadiusMeters = 120000; 

  final List<_CharacterCfg> _chars = const [
    _CharacterCfg(
      asset: 'assets/svg/satellite_red.svg',
      angleDeg: 150, 
      rotateDeg: -10,
      scale: 1.00,
    ),
    _CharacterCfg(
      asset: 'assets/svg/satellite_yellow.svg',
      angleDeg: 30,
      rotateDeg: 12,
      scale: 1.00,
    ),
    _CharacterCfg(
      asset: 'assets/svg/satellite_orange.svg',
      angleDeg: 250,
      rotateDeg: -18,
      scale: 1.00,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.selectedAlert != null) {
      _anchorLatLng = LatLng(
        widget.selectedAlert!.location[0],
        widget.selectedAlert!.location[1],
      );
    } else if (widget.alerts.isNotEmpty) {
      final a = widget.alerts.first;
      _anchorLatLng = LatLng(a.location[0], a.location[1]);
    }
  }

  @override
  void didUpdateWidget(MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAlert != null &&
        widget.selectedAlert != oldWidget.selectedAlert) {
      _animateToAlert(widget.selectedAlert!);
      _anchorLatLng = LatLng(
        widget.selectedAlert!.location[0],
        widget.selectedAlert!.location[1],
      );
      _updateAnchorPx();
    }
  }

  void _animateToAlert(Alert alert) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(alert.location[0], alert.location[1]),
          zoom: 8.0,
        ),
      ),
    );
  }

  Color _getMarkerColor(double risk) {
    if (risk > 0.7) return const Color(0xFFEF4444);
    if (risk > 0.3) return const Color(0xFFEAB308);
    return const Color(0xFF22C55E);
  }

  int get _currentDateIndex =>
      widget.availableDates.indexOf(widget.selectedDate);

  void _handleDateChange(String direction) {
    final i = _currentDateIndex;
    if (direction == 'prev' && i > 0) {
      widget.onDateChange(widget.availableDates[i - 1]);
    } else if (direction == 'next' && i < widget.availableDates.length - 1) {
      widget.onDateChange(widget.availableDates[i + 1]);
    }
  }

  Future<void> _updateAnchorPx() async {
    if (_mapController == null) return;
    try {
      final sc = await _mapController!.getScreenCoordinate(_anchorLatLng);
      final offset = Offset(sc.x.toDouble(), sc.y.toDouble());

      final metersPerPixel =
          156543.03392 *
              math.cos(_anchorLatLng.latitude * math.pi / 180.0) /
              math.pow(2, _currentZoom);

      final rPx = _desiredRadiusMeters / metersPerPixel;

      setState(() {
        _anchorPx = offset;
        _radiusPx = rPx.toDouble();
      });
    } catch (_) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          mapType:
              widget.mapMode == MapMode.threeD ? MapType.satellite : MapType.normal,
          initialCameraPosition: CameraPosition(target: _anchorLatLng, zoom: 7.0),
          onMapCreated: (GoogleMapController controller) async {
            _mapController = controller;
            await _updateAnchorPx();
          },
          onCameraMove: (pos) {
            _currentZoom = pos.zoom;
            _updateAnchorPx(); 
          },
          onCameraIdle: _updateAnchorPx, 
          circles: widget.alerts.map((alert) {
            final color = _getMarkerColor(alert.risk);
            return Circle(
              circleId: CircleId(alert.id),
              center: LatLng(alert.location[0], alert.location[1]),
              radius: 10000 + alert.risk * 20000,
              fillColor: color.withOpacity(0.5),
              strokeColor: color,
              strokeWidth: 2,
            );
          }).toSet(),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),

        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: Stack(
              children: [
                if (_anchorPx != null)
                  CustomPaint(
                    painter: _AnchoredGradientPainter(
                      centerPx: _anchorPx!,
                      radiusPx: _radiusPx,
                    ),
                  ),

                if (_anchorPx != null) ..._buildCharacterWidgets(),
              ],
            ),
          ),
        ),

        Positioned(
          top: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: MapMode.values.map((mode) {
                final isSelected = widget.mapMode == mode;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: () => widget.onMapModeChange(mode),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSelected ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6),
                      foregroundColor:
                          isSelected ? Colors.white : const Color(0xFF374151),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      mode.label,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _currentDateIndex > 0
                        ? () => _handleDateChange('prev')
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      disabledBackgroundColor: const Color(0xFFF3F4F6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ...widget.availableDates
                      .sublist(
                        _currentDateIndex > 0 ? _currentDateIndex - 1 : 0,
                        (_currentDateIndex + 2).clamp(0, widget.availableDates.length),
                      )
                      .map((date) {
                    final isSelected = date == widget.selectedDate;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        date,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF374151),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _currentDateIndex < widget.availableDates.length - 1
                        ? () => _handleDateChange('next')
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      disabledBackgroundColor: const Color(0xFFF3F4F6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCharacterWidgets() {
    final center = _anchorPx!;
    final r = _radiusPx;

    final groupBiasY = -r * 0.06; 

    final baseSize = r * 0.42; 

    final orbit = r * 0.33;

    Offset posFromAngle(double deg) {
      final rad = deg * math.pi / 180;
      return Offset(
        center.dx + orbit * math.cos(rad),
        center.dy + groupBiasY + orbit * math.sin(rad),
      );
    }

    return _chars.map((c) {
      final p = posFromAngle(c.angleDeg);
      final sizePx = baseSize * c.scale;

      return Positioned(
        left: p.dx - sizePx / 2,
        top: p.dy - sizePx / 2,
        width: sizePx,
        height: sizePx,
        child: Transform.rotate(
          angle: c.rotateDeg * math.pi / 180,
          alignment: Alignment.center,
          child: SvgPicture.asset(
            c.asset,
            fit: BoxFit.contain,
          ),
        ),
      );
    }).toList();
  }
}

class _AnchoredGradientPainter extends CustomPainter {
  final Offset centerPx;
  final double radiusPx;

  const _AnchoredGradientPainter({
    required this.centerPx,
    required this.radiusPx,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = const RadialGradient(
      colors: [
        Color(0xCCFF5252),
        Color(0xAAFFDB10),
        Color(0x883CD1FF), 
      ],
      stops: [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: centerPx, radius: radiusPx));

    final paint = Paint()
      ..shader = gradient
      ..isAntiAlias = true;

    canvas.drawCircle(centerPx, radiusPx, paint);
  }

  @override
  bool shouldRepaint(covariant _AnchoredGradientPainter old) =>
      old.centerPx != centerPx || old.radiusPx != radiusPx;
}

class _CharacterCfg {
  final String asset;
  final double angleDeg;   
  final double rotateDeg;  
  final double scale;      
  const _CharacterCfg({
    required this.asset,
    required this.angleDeg,
    this.rotateDeg = 0,
    this.scale = 1.0,
  });
}
