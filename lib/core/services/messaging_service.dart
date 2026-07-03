import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';

/// Construye y envía el mensaje de emergencia por todos los canales disponibles.
///
/// IMPORTANTE (limitación real de plataforma):
/// - Android: puede enviar SMS de forma directa y silenciosa usando el paquete
///   `telephony` con el permiso SEND_SMS (funciona en Android, NO en iOS).
/// - iOS: Apple no permite enviar SMS sin que el usuario confirme en la app
///   Mensajes. Por eso en iOS se abre el compositor nativo pre-rellenado.
/// - WhatsApp / Telegram / Correo: en ambas plataformas, por diseño del
///   sistema operativo y de esas apps, solo se puede ABRIR la conversación
///   con el texto pre-rellenado; el usuario debe tocar "enviar". Esto sigue
///   siendo casi instantáneo (1 toque) y es la única vía permitida.
class MessagingService {
  final Telephony telephony = Telephony.instance;

  String buildEmergencyMessage(SosSnapshot snapshot, {String appName = 'Guardian SOS'}) {
    final date = '${snapshot.timestamp.day.toString().padLeft(2, '0')}/'
        '${snapshot.timestamp.month.toString().padLeft(2, '0')}/'
        '${snapshot.timestamp.year}';
    final time = '${snapshot.timestamp.hour.toString().padLeft(2, '0')}:'
        '${snapshot.timestamp.minute.toString().padLeft(2, '0')}';

    return '🚨 EMERGENCIA 🚨\n'
        'Necesito ayuda.\n'
        'Mi ubicación es:\n'
        '${snapshot.googleMapsUrl}\n'
        'Hora: $time\n'
        'Fecha: $date\n'
        'Enviado desde $appName.';
  }

  /// Envía SMS directo a una lista de teléfonos (solo Android; en iOS hace fallback al compositor).
  Future<void> sendSms(List<String> phoneNumbers, String message) async {
    if (Platform.isAndroid) {
      final bool? granted = await telephony.requestPhoneAndSmsPermissions;
      if (granted == true) {
        for (final phone in phoneNumbers) {
          try {
            await telephony.sendSms(to: phone, message: message);
          } catch (e) {
            debugPrint('Error enviando SMS a $phone: $e');
            await _openSmsComposer(phone, message);
          }
        }
        return;
      }
    }
    // iOS o permiso denegado: abrir compositor nativo.
    for (final phone in phoneNumbers) {
      await _openSmsComposer(phone, message);
    }
  }

  Future<void> _openSmsComposer(String phone, String message) async {
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );
    await launchUrl(uri);
  }

  Future<void> openWhatsApp(String phone, String message) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> openTelegram(String phone, String message) async {
    // Telegram no soporta destinatario por teléfono vía URL scheme sin username;
    // se abre el share sheet de Telegram con el texto listo.
    final uri = Uri.parse('https://t.me/share/url?url=&text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> openEmail(String email, String message) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': '🚨 EMERGENCIA - Guardian SOS', 'body': message},
    );
    await launchUrl(uri);
  }
}
