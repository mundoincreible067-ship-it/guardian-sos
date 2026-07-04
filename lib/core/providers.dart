import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:latlong2/latlong.dart';
import 'services/location_service.dart';
import 'services/flash_service.dart';
import 'services/audio_recording_service.dart';
import 'services/messaging_service.dart';
import 'services/call_service.dart';
import '../features/contacts/data/contacts_repository.dart';
import '../features/contacts/domain/contact_model.dart';
import '../core/constants/emergency_numbers.dart';

final locationServiceProvider = Provider((ref) => LocationService());
final audioPlayerProvider = Provider((ref) => AudioPlayer());
final flashServiceProvider = Provider((ref) => FlashService());
final audioRecordingServiceProvider = Provider((ref) => AudioRecordingService());

/// Flash estroboscópico real al activar el SOS
final flashEnabledProvider = StateProvider<bool>((ref) => true);

/// Grabación de audio real al activar el SOS
final recordAudioEnabledProvider = StateProvider<bool>((ref) => true);

/// Seguimiento en vivo real al activar el SOS
final liveTrackingEnabledProvider = StateProvider<bool>((ref) => true);

/// Puntos del recorrido durante el SOS activo, para dibujar la ruta en el mapa
final routePointsProvider = StateProvider<List<LatLng>>((ref) => []);
final messagingServiceProvider = Provider((ref) => MessagingService());
final callServiceProvider = Provider((ref) => CallService());
final contactsRepositoryProvider = Provider((ref) => ContactsRepository());

/// Tema: claro / oscuro / sistema
final themeModeProvider = StateProvider<ThemeModeOption>((ref) => ThemeModeOption.dark);

enum ThemeModeOption { light, dark, system }

/// Lista de contactos (se recarga desde el repositorio)
final contactsProvider = FutureProvider<List<EmergencyContact>>((ref) async {
  final repo = ref.watch(contactsRepositoryProvider);
  return repo.getAll();
});

/// Servicios de emergencia configurables (números por país)
final emergencyServicesProvider = StateProvider<List<EmergencyService>>((ref) {
  return EmergencyNumbers.defaultsForMexico();
});

/// Segundos de cuenta regresiva antes de disparar SOS / llamada automática
/// (solo se usa si instantSendProvider está desactivado)
final countdownSecondsProvider = StateProvider<int>((ref) => 5);

/// Si está activo, el botón SOS envía de inmediato al mantenerlo presionado,
/// sin cuenta regresiva. Si se desactiva, usa countdownSecondsProvider.
final instantSendProvider = StateProvider<bool>((ref) => true);

/// Vibración real al activar el SOS (usa HapticFeedback, sin paquetes extra)
final vibrationEnabledProvider = StateProvider<bool>((ref) => true);

/// Alarma sonora real (sirena en bucle) al activar el SOS
final alarmEnabledProvider = StateProvider<bool>((ref) => true);

/// Estado del SOS activo (para mostrar overlay/seguimiento en vivo)
final sosActiveProvider = StateProvider<bool>((ref) => false);
