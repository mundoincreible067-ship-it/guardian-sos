import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:battery_plus/battery_plus.dart';

/// Snapshot completo de datos capturados al momento del SOS.
class SosSnapshot {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double speedMetersPerSecond;
  final int batteryLevel;
  final String? address;
  final DateTime timestamp;

  SosSnapshot({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.speedMetersPerSecond,
    required this.batteryLevel,
    required this.address,
    required this.timestamp,
  });

  String get googleMapsUrl => 'https://maps.google.com/?q=$latitude,$longitude';

  double get speedKmH => speedMetersPerSecond * 3.6;
}

class LocationService {
  final Battery _battery = Battery();

  /// Verifica y solicita permisos de ubicación (incluye segundo plano si aplica).
  Future<bool> ensurePermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Solicita también permiso de ubicación en segundo plano (Android "Always").
  Future<bool> ensureBackgroundPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always) return true;
    final requested = await Geolocator.requestPermission();
    return requested == LocationPermission.always;
  }

  Future<Position> getHighAccuracyPosition() async {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    );
  }

  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      return [
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.postalCode,
        p.country,
      ].where((e) => e != null && e.isNotEmpty).join(', ');
    } catch (_) {
      return null;
    }
  }

  /// Captura TODO lo necesario para el SOS en una sola llamada, en paralelo.
  Future<SosSnapshot> captureSosSnapshot() async {
    final positionFuture = getHighAccuracyPosition();
    final batteryFuture = _battery.batteryLevel;

    final position = await positionFuture;
    final battery = await batteryFuture;
    final address = await reverseGeocode(position.latitude, position.longitude);

    return SosSnapshot(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      speedMetersPerSecond: position.speed < 0 ? 0 : position.speed,
      batteryLevel: battery,
      address: address,
      timestamp: DateTime.now(),
    );
  }

  /// Stream de posiciones para el seguimiento en vivo (cada ~20s / 10m de movimiento).
  Stream<Position> liveTrackingStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }
}
