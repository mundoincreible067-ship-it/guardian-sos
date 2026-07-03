import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/location_service.dart';
import 'services/messaging_service.dart';
import 'services/call_service.dart';
import '../features/contacts/data/contacts_repository.dart';
import '../features/contacts/domain/contact_model.dart';
import '../core/constants/emergency_numbers.dart';

final locationServiceProvider = Provider((ref) => LocationService());
final messagingServiceProvider = Provider((ref) => MessagingService());
final callServiceProvider = Provider((ref) => CallService());
final contactsRepositoryProvider = Provider((ref) => ContactsRepository());

/// Tema: claro / oscuro / sistema
final themeModeProvider = StateProvider<ThemeModeOption>((ref) => ThemeModeOption.system);

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
final countdownSecondsProvider = StateProvider<int>((ref) => 5);

/// Estado del SOS activo (para mostrar overlay/seguimiento en vivo)
final sosActiveProvider = StateProvider<bool>((ref) => false);
