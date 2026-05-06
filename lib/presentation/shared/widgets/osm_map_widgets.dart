import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';

class OsmTiles extends StatelessWidget {
  const OsmTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'veloce_express',
      maxZoom: 19,
    );
  }
}

Marker osmPinMarker({
  required LatLng point,
  required Color color,
  required IconData icon,
  String? label,
}) {
  return Marker(
    point: point,
    width: 46,
    height: 56,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.14),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        Icon(Icons.arrow_drop_down_rounded, color: color, size: 24),
        if (label != null)
          Semantics(label: label, child: const SizedBox.shrink()),
      ],
    ),
  );
}
