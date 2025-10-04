import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  @override
  void didUpdateWidget(MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAlert != null &&
        widget.selectedAlert != oldWidget.selectedAlert) {
      _animateToAlert(widget.selectedAlert!);
    }
  }

  void _animateToAlert(Alert alert) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(alert.location[0], alert.location[1]), zoom: 8.0),
      ),
    );
  }

  Color _getMarkerColor(double risk) {
    if (risk > 0.7) return const Color(0xFFEF4444);
    if (risk > 0.3) return const Color(0xFFEAB308);
    return const Color(0xFF22C55E);
  }

  int get _currentDateIndex {
    return widget.availableDates.indexOf(widget.selectedDate);
  }

  void _handleDateChange(String direction) {
    final currentIndex = _currentDateIndex;
    if (direction == 'prev' && currentIndex > 0) {
      widget.onDateChange(widget.availableDates[currentIndex - 1]);
    } else if (direction == 'next' &&
        currentIndex < widget.availableDates.length - 1) {
      widget.onDateChange(widget.availableDates[currentIndex + 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          mapType: widget.mapMode == MapMode.threeD ? MapType.satellite : MapType.normal,
          initialCameraPosition: const CameraPosition(
            target: LatLng(36.5, 127.5),
            zoom: 7.0,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          circles: widget.alerts.map((alert) {
            final color = _getMarkerColor(alert.risk);
            return Circle(
              circleId: CircleId(alert.id),
              center: LatLng(alert.location[0], alert.location[1]),
              radius: 10000 + alert.risk * 20000, // Radius in meters
              fillColor: color.withOpacity(0.5),
              strokeColor: color,
              strokeWidth: 2,
            );
          }).toSet(),
          // Disable default buttons since we have custom ones
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      mode.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFF3F4F6),
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
}
