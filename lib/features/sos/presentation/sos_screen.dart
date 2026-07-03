import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> with SingleTickerProviderStateMixin {
  Timer? _countdownTimer;
  int _secondsLeft = 0;
  bool _countdownActive = false;
  bool _sosSent = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    final seconds = ref.read(countdownSecondsProvider);
    setState(() {
      _countdownActive = true;
      _secondsLeft = seconds;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        timer.cancel();
        _triggerSos();
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdownActive = false;
      _secondsLeft = 0;
    });
  }

  Future<void> _triggerSos() async {
    setState(() {
      _countdownActive = false;
      _sosSent = true;
    });
    ref.read(sosActiveProvider.notifier).state = true;

    final locationService = ref.read(locationServiceProvider);
    final messagingService = ref.read(messagingServiceProvider);
    final contactsRepo = ref.read(contactsRepositoryProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Obteniendo ubicación y notificando contactos...')),
    );

    try {
      // 1. Capturar TODO en paralelo: GPS, dirección, batería, velocidad, precisión.
      final SosSnapshot snapshot = await locationService.captureSosSnapshot();

      // 2. Construir el mensaje estándar.
      final message = messagingService.buildEmergencyMessage(snapshot);

      // 3. Obtener los primeros dos contactos primarios.
      final primaryContacts = await contactsRepo.getPrimaryPair();
      final phones = primaryContacts.map((c) => c.phone).toList();

      // 4. Disparar TODO simultáneamente: SMS + WhatsApp + Telegram + Email.
      await Future.wait([
        if (phones.isNotEmpty) messagingService.sendSms(phones, message),
        for (final c in primaryContacts) messagingService.openWhatsApp(c.phone, message),
        for (final c in primaryContacts)
          if (c.email != null && c.email!.isNotEmpty) messagingService.openEmail(c.email!, message),
      ]);

      // 5. TODO: aquí se conecta también:
      //    - Inicio de grabación de audio/video (ver AudioVideoService, próxima entrega)
      //    - Activación de flash estroboscópico y alarma
      //    - Seguimiento en vivo cada 20s durante 30 min (ver LiveTrackingService)
      //    - Guardado en historial local + Firebase

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text('SOS enviado a ${primaryContacts.length} contacto(s). '
              'Batería: ${snapshot.batteryLevel}% · Precisión: ${snapshot.accuracyMeters.toStringAsFixed(0)}m'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.sosRed, content: Text('Error al enviar SOS: $e')),
      );
    }
  }

  void _cancelActiveSos() {
    setState(() => _sosSent = false);
    ref.read(sosActiveProvider.notifier).state = false;
    // TODO: detener seguimiento en vivo, grabación, alarma.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guardian SOS')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_countdownActive) _buildCountdown() else if (_sosSent) _buildActiveState() else _buildIdleState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdleState() {
    return Column(
      children: [
        Text(
          'Mantén presionado para activar',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onLongPress: _startCountdown,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.05);
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [AppColors.sosRed, AppColors.sosRedDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sosRed.withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Envía tu ubicación y notifica a tus contactos de emergencia'),
      ],
    );
  }

  Widget _buildCountdown() {
    return Column(
      children: [
        Text(
          '$_secondsLeft',
          style: const TextStyle(fontSize: 96, fontWeight: FontWeight.bold, color: AppColors.sosRed),
        ),
        const SizedBox(height: 16),
        const Text('Enviando SOS automáticamente...', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _cancelCountdown,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade800,
            foregroundColor: Colors.white,
            minimumSize: const Size(200, 56),
          ),
          child: const Text('CANCELAR', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  Widget _buildActiveState() {
    return Column(
      children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 96),
        const SizedBox(height: 16),
        const Text('SOS ACTIVO', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Seguimiento en vivo activado · contactos notificados'),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _cancelActiveSos,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sosRed,
            foregroundColor: Colors.white,
            minimumSize: const Size(220, 56),
          ),
          child: const Text('DETENER SOS', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }
}
