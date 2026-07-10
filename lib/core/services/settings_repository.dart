import 'package:shared_preferences/shared_preferences.dart';

/// Guarda y recupera las preferencias del usuario para que no se pierdan
/// al cerrar y volver a abrir la app.
class SettingsRepository {
  static const _kInstantSend = 'settings_instant_send';
  static const _kVibration = 'settings_vibration';
  static const _kAlarm = 'settings_alarm';
  static const _kFlash = 'settings_flash';
  static const _kRecordAudio = 'settings_record_audio';
  static const _kLiveTracking = 'settings_live_tracking';
  static const _kCountdownSeconds = 'settings_countdown_seconds';
  static const _kPremiumUnlocked = 'settings_premium_unlocked';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> setInstantSend(bool v) async => (await _prefs).setBool(_kInstantSend, v);
  Future<void> setVibration(bool v) async => (await _prefs).setBool(_kVibration, v);
  Future<void> setAlarm(bool v) async => (await _prefs).setBool(_kAlarm, v);
  Future<void> setFlash(bool v) async => (await _prefs).setBool(_kFlash, v);
  Future<void> setRecordAudio(bool v) async => (await _prefs).setBool(_kRecordAudio, v);
  Future<void> setLiveTracking(bool v) async => (await _prefs).setBool(_kLiveTracking, v);
  Future<void> setCountdownSeconds(int v) async => (await _prefs).setInt(_kCountdownSeconds, v);
  Future<void> setPremiumUnlocked(bool v) async => (await _prefs).setBool(_kPremiumUnlocked, v);

  /// Carga todos los ajustes guardados de una vez (con valores por defecto
  /// si el usuario nunca los ha cambiado).
  Future<AppSettings> loadAll() async {
    final prefs = await _prefs;
    return AppSettings(
      instantSend: prefs.getBool(_kInstantSend) ?? true,
      vibration: prefs.getBool(_kVibration) ?? true,
      alarm: prefs.getBool(_kAlarm) ?? true,
      flash: prefs.getBool(_kFlash) ?? true,
      recordAudio: prefs.getBool(_kRecordAudio) ?? true,
      liveTracking: prefs.getBool(_kLiveTracking) ?? true,
      countdownSeconds: prefs.getInt(_kCountdownSeconds) ?? 5,
      premiumUnlocked: prefs.getBool(_kPremiumUnlocked) ?? false,
    );
  }
}

/// Snapshot de todos los ajustes cargados al iniciar la app.
class AppSettings {
  final bool instantSend;
  final bool vibration;
  final bool alarm;
  final bool flash;
  final bool recordAudio;
  final bool liveTracking;
  final int countdownSeconds;
  final bool premiumUnlocked;

  AppSettings({
    required this.instantSend,
    required this.vibration,
    required this.alarm,
    required this.flash,
    required this.recordAudio,
    required this.liveTracking,
    required this.countdownSeconds,
    required this.premiumUnlocked,
  });
}
