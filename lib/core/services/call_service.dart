import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Realiza llamadas de emergencia.
///
/// IMPORTANTE (limitación real de plataforma):
/// - Android: con el permiso CALL_PHONE concedido, se puede iniciar la
///   llamada directamente sin pasar por el marcador (usando un intent
///   ACTION_CALL a nivel nativo). Aquí usamos url_launcher con esquema
///   `tel:`, que en Android con el permiso otorgado también puede disparar
///   la llamada sin confirmación adicional del usuario en la mayoría de
///   fabricantes; si el fabricante restringe esto, se abrirá el marcador.
/// - iOS: Apple SIEMPRE requiere que el usuario confirme la llamada desde
///   la app Teléfono. No hay forma de evitarlo (política de la App Store).
///   Se abre el marcador con el número pre-cargado y el usuario solo debe
///   tocar el botón verde de llamar.
class CallService {
  Future<bool> requestCallPermission() async {
    if (!Platform.isAndroid) return true; // iOS no usa este permiso
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  Future<void> call(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
