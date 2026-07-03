import 'dart:async';
import 'package:torch_light/torch_light.dart';

/// Controla el flash del celular en modo estroboscópico (encendido/apagado
/// rápido y constante) para hacer visible al usuario en la oscuridad.
class FlashService {
  Timer? _strobeTimer;
  bool _isOn = false;

  Future<bool> isAvailable() async {
    try {
      return await TorchLight.isTorchAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Empieza a parpadear el flash cada 200ms hasta llamar a stopStrobe().
  Future<void> startStrobe() async {
    if (_strobeTimer != null) return; // ya está corriendo
    if (!await isAvailable()) return;

    _strobeTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      try {
        if (_isOn) {
          await TorchLight.disableTorch();
        } else {
          await TorchLight.enableTorch();
        }
        _isOn = !_isOn;
      } catch (_) {
        // Si el sistema operativo niega el acceso (ej. cámara en uso por
        // otra app), simplemente se deja de intentar en el próximo tick.
      }
    });
  }

  Future<void> stopStrobe() async {
    _strobeTimer?.cancel();
    _strobeTimer = null;
    if (_isOn) {
      try {
        await TorchLight.disableTorch();
      } catch (_) {}
      _isOn = false;
    }
  }
}
