// lib/widgets/map_view.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/alert.dart';

// ===== Date ribbon sizing (global constants) =====
const double kRibbonHeight   = 64.0;  // 전체 바 높이
const double kDateChipHeight = 40.0;  // 날짜 칩 높이
const double kDateChipWidth  = 120.0; // 날짜 칩 가로 폭
const double kDateChipGap    = 8.0;   // 칩 간격

class MapView extends StatefulWidget {
  final List<Alert> alerts;
  final Alert? selectedAlert;
  final MapMode mapMode;
  final void Function(MapMode) onMapModeChange;
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

  /// 💡 그라데이션/캐릭터가 '고정'될 지도 좌표(선택 알림 없으면 한국 중심)
  LatLng _anchorLatLng = const LatLng(36.5, 127.5);

  /// 화면상의 중심 픽셀 위치 & 반경(px)
  Offset? _anchorPx;
  double _radiusPx = 200;
  double _currentZoom = 7.0;

  /// 원하는 실제 반경(미터)
  double _desiredRadiusMeters = 120000; // 120km

  /// 캐릭터(피그마 SVG) 배치 설정
  final List<_CharacterCfg> _chars = const [
    _CharacterCfg(asset: 'assets/svg/satellite_red.svg',    angleDeg: 150, rotateDeg: -10, scale: 1.0),
    _CharacterCfg(asset: 'assets/svg/satellite_yellow.svg', angleDeg: 30,  rotateDeg: 12,  scale: 1.0),
    _CharacterCfg(asset: 'assets/svg/satellite_orange.svg', angleDeg: 250, rotateDeg: -18, scale: 1.0),
  ];

  // 날짜 리본 스크롤 컨트롤러
  final ScrollController _dateScroll = ScrollController();

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerSelectedDate());
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

    if (widget.selectedDate != oldWidget.selectedDate ||
        widget.availableDates != oldWidget.availableDates) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerSelectedDate());
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

  int get _currentDateIndex => widget.availableDates.indexOf(widget.selectedDate);

  void _handleDateChange(String direction) {
    final i = _currentDateIndex;
    if (direction == 'prev' && i > 0) {
      widget.onDateChange(widget.availableDates[i - 1]);
    } else if (direction == 'next' && i < widget.availableDates.length - 1) {
      widget.onDateChange(widget.availableDates[i + 1]);
    }
  }

  // 현재 선택된 날짜칩을 가운데로 스크롤
  void _centerSelectedDate() {
    if (!_dateScroll.hasClients) return;
    final i = _currentDateIndex;
    if (i < 0) return;
    final itemExtent = kDateChipWidth + kDateChipGap;
    final viewportWidth = _dateScroll.position.viewportDimension;
    final target = i * itemExtent - (viewportWidth - kDateChipWidth) / 2;

    _dateScroll.animateTo(
      target.clamp(
        _dateScroll.position.minScrollExtent,
        _dateScroll.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  /// LatLng → 화면 픽셀로 변환 + 반경(px) 계산
  Future<void> _updateAnchorPx() async {
    if (_mapController == null) return;
    try {
      final sc = await _mapController!.getScreenCoordinate(_anchorLatLng);
      final offset = Offset(sc.x.toDouble(), sc.y.toDouble());

      final metersPerPixel = 156543.03392 *
          math.cos(_anchorLatLng.latitude * math.pi / 180.0) /
          math.pow(2, _currentZoom);

      final rPx = _desiredRadiusMeters / metersPerPixel;

      setState(() {
        _anchorPx = offset;
        _radiusPx = rPx.toDouble();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          mapType: widget.mapMode == MapMode.threeD ? MapType.satellite : MapType.normal,
          initialCameraPosition: CameraPosition(target: _anchorLatLng, zoom: 7.0),
          onMapCreated: (c) async {
            _mapController = c;
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

        // 🌈 오버레이
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

        // 모드 전환 버튼
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

        // ===== 날짜 리본 (가로 스크롤) =====
        Positioned(
          bottom: 16,
          left: 240,
          right: 60,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
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
                height: kRibbonHeight, // ← 슬림한 리본 높이
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _RoundIconBtn(
                      icon: Icons.chevron_left,
                      onTap: _currentDateIndex > 0 ? () => _handleDateChange('prev') : null,
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: ListView.builder(
                        controller: _dateScroll,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        itemCount: widget.availableDates.length,
                        itemBuilder: (context, index) {
                          final date = widget.availableDates[index];
                          final isSelected = date == widget.selectedDate;
                          return Padding(
                            padding: const EdgeInsets.only(right: kDateChipGap, top: 6, bottom: 6,),
                            child: _DateChip(
                              width: kDateChipWidth,
                              label: date,
                              selected: isSelected,
                              onTap: () {
                                if (!isSelected) widget.onDateChange(date);
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 8),
                    _RoundIconBtn(
                      icon: Icons.chevron_right,
                      onTap: _currentDateIndex < widget.availableDates.length - 1
                          ? () => _handleDateChange('next')
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// SVG 캐릭터들을 화면 픽셀 좌표로 배치
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
          child: SvgPicture.asset(c.asset, fit: BoxFit.contain),
        ),
      );
    }).toList();
  }
}

class _AnchoredGradientPainter extends CustomPainter {
  final Offset centerPx;
  final double radiusPx;

  const _AnchoredGradientPainter({required this.centerPx, required this.radiusPx});

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = const RadialGradient(
      colors: [Color(0xCCFF5252), Color(0xAAFFDB10), Color(0x883CD1FF)],
      stops: [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: centerPx, radius: radiusPx));

    final paint = Paint()..shader = gradient..isAntiAlias = true;
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

class _RoundIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundIconBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Color(0xFFF3F4F6),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: enabled ? const Color(0xFF6B7280) : const Color(0xFFBFC5CF),
          size: 26,
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double width;

  const _DateChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: kDateChipHeight, // ← 슬림한 칩 높이
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), // 세로 여백 최소화
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}
