/// Modelo de un servicio de emergencia (número configurable por el usuario)
class EmergencyService {
  final String id;
  final String name;
  final String defaultNumber;
  String currentNumber;

  EmergencyService({
    required this.id,
    required this.name,
    required this.defaultNumber,
    String? currentNumber,
  }) : currentNumber = currentNumber ?? defaultNumber;
}

/// Números por defecto para México (el usuario puede cambiarlos en Configuración).
/// El número 911 cubre policía/ambulancia/bomberos en México; se listan también
/// líneas directas específicas cuando existen.
class EmergencyNumbers {
  static List<EmergencyService> defaultsForMexico() => [
        EmergencyService(id: 'police', name: 'Policía', defaultNumber: '911'),
        EmergencyService(id: 'ambulance', name: 'Ambulancia', defaultNumber: '911'),
        EmergencyService(id: 'firefighters', name: 'Bomberos', defaultNumber: '911'),
        EmergencyService(id: 'redcross', name: 'Cruz Roja', defaultNumber: '911'),
        EmergencyService(id: 'civilprotection', name: 'Protección Civil', defaultNumber: '911'),
        EmergencyService(id: 'guardianacional', name: 'Guardia Nacional', defaultNumber: '911'),
        EmergencyService(id: 'women', name: 'Emergencias para Mujeres', defaultNumber: '911'),
        EmergencyService(id: 'children', name: 'Emergencias Infantiles', defaultNumber: '911'),
        EmergencyService(id: 'psychological', name: 'Atención Psicológica', defaultNumber: '800 290 0024'),
        EmergencyService(id: 'roadrescue', name: 'Rescate en Carreteras', defaultNumber: '074'),
      ];

  /// Otros países pueden añadirse aquí (ej. Colombia: 123, España: 112, EE.UU.: 911, etc.)
  static Map<String, List<EmergencyService> Function()> byCountry = {
    'MX': defaultsForMexico,
  };
}
