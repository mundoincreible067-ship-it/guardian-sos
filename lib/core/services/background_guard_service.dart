import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Mantiene el proceso de la app vivo (con una notificación visible, como
/// exige Android) mientras el SOS está activo, para que la grabación de
/// audio no se detenga si el usuario minimiza la app durante la emergencia.
///
/// Nota: quien realmente grava el audio sigue siendo el paquete `record`
/// (ver AudioRecordingService) — este servicio solo evita que el sistema
/// operativo mate el proceso de la app en segundo plano.
class BackgroundGuardService {
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'guardian_sos_channel',
        channelName: 'Guardian SOS activo',
        channelDescription: 'Se muestra mientras hay una emergencia activa, para que la grabación no se detenga.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<void> start() async {
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceId: 911,
      notificationTitle: 'Guardian SOS activo',
      notificationText: 'Grabando audio de la emergencia. Toca para volver a la app.',
      callback: _startCallback,
    );
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}

/// Debe ser una función de nivel superior (no un método de clase) porque
/// Android la ejecuta en un isolate separado.
@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_GuardianTaskHandler());
}

class _GuardianTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
