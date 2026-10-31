import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/eco_palette.dart';

/// Embedded CartoDB Positron map matching the Rich Sage / Khaki aesthetic
class EcoCartoMap extends StatelessWidget {
  const EcoCartoMap({
    super.key,
    required this.center,
    this.zoom = 14.2,
    this.height = 160,
    this.routePoints,
    this.markers = const [],
    this.interactive = false,
    this.onTap,
  });

  final LatLng center;
  final double zoom;
  final double height;
  final List<LatLng>? routePoints;
  final List<Marker> markers;
  final bool interactive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: EcoPalette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EcoPalette.cardBorder, width: 1),
        ),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
                interactionOptions: InteractionOptions(
                  flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'ug.ecoroute.app',
                  tileBuilder: (context, tileWidget, tile) {
                    // Soft color blend to match sage tone perfectly
                    return ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        EcoPalette.surface.withValues(alpha: 0.12),
                        BlendMode.darken,
                      ),
                      child: tileWidget,
                    );
                  },
                ),
                if (routePoints != null && routePoints!.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints!,
                        strokeWidth: 4.0,
                        color: EcoPalette.accentTerracotta,
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                    ],
                  ),
                if (markers.isNotEmpty) MarkerLayer(markers: markers),
              ],
            ),
            if (onTap != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
