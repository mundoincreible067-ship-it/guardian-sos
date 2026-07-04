import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';

/// Muestra la ubicación actual y el recorrido dibujado en el mapa mientras
/// el SOS está activo. Los puntos se van agregando desde SosScreen
/// (routePointsProvider) conforme llega la ubicación en vivo.
///
/// Usa flutter_map con teselas de Carto (gratis, sin cuenta ni API key).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _controller = MapController();

  @override
  Widget build(BuildContext context) {
    final points = ref.watch(routePointsProvider);
    final hasPoints = points.isNotEmpty;
    final current = hasPoints ? points.last : const LatLng(19.4326, -99.1332); // CDMX de respaldo

    if (hasPoints) {
      // Sigue el punto más reciente con la cámara.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.move(current, _controller.camera.zoom);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(title: const Text('Recorrido en vivo')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: current,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.guardiansos.guardian_sos',
                maxZoom: 19,
              ),
              if (points.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(points: points, color: AppColors.accentPink, strokeWidth: 5),
                  ],
                ),
              if (hasPoints)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: current,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.dangerRed,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: AppColors.dangerRed.withOpacity(0.6), blurRadius: 10)],
                        ),
                        child: const Icon(Icons.person_pin, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors © CARTO'),
                ],
              ),
            ],
          ),
          if (!hasPoints)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgMid,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Esperando la primera ubicación… activa el SOS con seguimiento en vivo para ver el recorrido aquí.',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
