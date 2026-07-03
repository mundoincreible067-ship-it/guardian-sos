import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> with TickerProviderStateMixin {
  Timer? _countdownTimer;
  int _secondsLeft = 0;
  bool _countdownActive = false;
  bool _sosSent = false;

  late final AnimationController _radarController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _radarController.dispose();
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
    _showSnack('Obteniendo ubicación y notificando contactos...', AppColors.nightElevated);

    try {
      final SosSnapshot snapshot = await locationService.captureSosSnapshot();
      final message = messagingService.buildEmergencyMessage(snapshot);
      final primaryContacts = await contactsRepo.getPrimaryPair();
      final phones = primaryContacts.map((c) => c.phone).toList();

      await Future.wait([
        if (phones.isNotEmpty) messagingService.sendSms(phones, message),
        for (final c in primaryContacts) messagingService.openWhatsApp(c.phone, message),
        for (final c in primaryContacts)
          if (c.email != null && c.email!.isNotEmpty) messagingService.openEmail(c.email!, message),
      ]);

      if (!mounted) return;
      _showSnack(
        'SOS enviado a ${primaryContacts.length} contacto(s) · Batería ${snapshot.batteryLevel}% · '
        'Precisión ${snapshot.accuracyMeters.toStringAsFixed(0)}m',
        AppColors.calmDeep,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error al enviar SOS: $e', AppColors.signalDeep);
    }
  }

  void _showSnack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(text, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
      ),
    );
  }

  void _cancelActiveSos() {
    setState(() => _sosSent = false);
    ref.read(sosActiveProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.1,
            colors: [AppColors.nightElevated, AppColors.night],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GUARDIAN', style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 3,
                        )),
                        Text('SOS', style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5,
                        )),
                      ],
                    ),
                    _StatusChip(active: _sosSent),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: _countdownActive
                      ? _buildCountdown()
                      : _sosSent
                          ? _buildActiveState()
                          : _buildIdleState(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdleState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Mantén presionado para activar',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 15)),
        const SizedBox(height: 40),
        GestureDetector(
          onLongPress: _startCountdown,
          child: SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(280, 280),
                      painter: _RadarPainter(_radarController.value),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.04);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    width: 168,
                    height: 168,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.signal, AppColors.signalDeep],
                      ),
                      boxShadow: [
                        BoxShadow(color: AppColors.signal.withOpacity(0.45), blurRadius: 36, spreadRadius: 4),
                      ],
                    ),
                    child: Center(
                      child: Text('SOS', style: GoogleFonts.spaceGrotesk(
                        color: Colors.white, fontSize: 42, fontWeight: FontWeight.w700, letterSpacing: 3,
                      )),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 36),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            'Envía tu ubicación exacta y avisa a tus contactos de emergencia al instante',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdown() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                key: ValueKey(_secondsLeft),
                tween: Tween(begin: 1.0, end: 0.0),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: const AlwaysStoppedAnimation(AppColors.signal),
                ),
              ),
              Text('$_secondsLeft', style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary, fontSize: 72, fontWeight: FontWeight.w700,
              )),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Enviando SOS automáticamente…', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 15)),
        const SizedBox(height: 36),
        OutlinedButton(
          onPressed: _cancelCountdown,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text('CANCELAR', style: GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: 1)),
        ),
      ],
    );
  }

  Widget _buildActiveState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.calm.withOpacity(0.12),
            border: Border.all(color: AppColors.calm.withOpacity(0.4), width: 2),
          ),
          child: const Icon(Icons.check_rounded, color: AppColors.calm, size: 48),
        ),
        const SizedBox(height: 24),
        Text('SOS ACTIVO', style: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 1,
        )),
        const SizedBox(height: 8),
        Text('Seguimiento en vivo activado', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
        const SizedBox(height: 36),
        ElevatedButton(
          onPressed: _cancelActiveSos,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.nightCard,
            foregroundColor: AppColors.signal,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
          ),
          child: Text('DETENER SOS', style: GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: 1)),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.calm : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(active ? 'En vivo' : 'En espera',
              style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Pinta 3 anillos concéntricos que se expanden y desvanecen, como una
/// señal de radar — el elemento visual distintivo de la app: comunica
/// "transmitiendo tu ubicación" sin usar texto.
class _RadarPainter extends CustomPainter {
  final double progress;
  _RadarPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final t = (progress + i / 3) % 1.0;
      final radius = 84 + t * (maxRadius - 84);
      final opacity = (1 - t).clamp(0.0, 1.0) * 0.35;
      final paint = Paint()
        ..color = AppColors.signal.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => oldDelegate.progress != progress;
}
