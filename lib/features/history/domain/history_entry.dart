/// Un evento de SOS guardado en el historial: cuándo, dónde, y qué
/// evidencia (audio) se generó.
class HistoryEntry {
  final String id;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String? address;
  final int batteryLevel;
  final String? audioPath;

  HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.batteryLevel,
    this.audioPath,
  });

  String get googleMapsUrl => 'https://maps.google.com/?q=$latitude,$longitude';

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'batteryLevel': batteryLevel,
        'audioPath': audioPath,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'],
        timestamp: DateTime.parse(json['timestamp']),
        latitude: json['latitude'],
        longitude: json['longitude'],
        address: json['address'],
        batteryLevel: json['batteryLevel'],
        audioPath: json['audioPath'],
      );
}
