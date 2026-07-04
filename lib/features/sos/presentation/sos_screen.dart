import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart' show Position;
import 'package:latlong2/latlong.dart' show LatLng;
import '../../history/data/history_repository.dart';
import '../../history/domain/history_entry.dart';
import '../../history/presentation/history_screen.dart';
import '../../map/presentation/map_screen.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/background_guard_service.dart';
import '../../../shared/widgets/neon_background.dart';
import '../../../shared/widgets/guardian_logo.dart';

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

  late final AnimationController _ringController;
  late final AnimationController _btnController;
  late final AnimationController _iconController;
  late final AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _btnController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _iconController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _dotController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _vibrationTimer?.cancel();
    _trackingSubscription?.cancel();
    _resendTimer?.cancel();
    ref.read(flashServiceProvider).stopStrobe();
    ref.read(audioRecordingServiceProvider).stopRecording();
    BackgroundGuardService.stop();
    _ringController.dispose();
    _btnController.dispose();
    _iconController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  Timer? _vibrationTimer;
  StreamSubscription<Position>? _trackingSubscription;
  Timer? _resendTimer;
  int _resendCount = 0;
  SosSnapshot? _lastSnapshot;

  void _handleActivation() {
    HapticFeedback.mediumImpact();
    final instant = ref.read(instantSendProvider);
    if (instant) {
      _triggerSos();
    } else {
      _startCountdown();
    }
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

    if (ref.read(vibrationEnabledProvider)) {
      _startVibrationPattern();
    }
    if (ref.read(alarmEnabledProvider)) {
      _startAlarm();
    }
    if (ref.read(flashEnabledProvider)) {
      ref.read(flashServiceProvider).startStrobe();
    }
    if (ref.read(recordAudioEnabledProvider)) {
      ref.read(audioRecordingServiceProvider).startRecording();
      BackgroundGuardService.start();
    }
    if (ref.read(liveTrackingEnabledProvider)) {
      _startLiveTracking();
      if (!ref.read(recordAudioEnabledProvider)) {
        BackgroundGuardService.start(); // por si el audio está apagado
      }
    }

    final locationService = ref.read(locationServiceProvider);
    final messagingService = ref.read(messagingServiceProvider);
    final contactsRepo = ref.read(contactsRepositoryProvider);

    if (!mounted) return;
    _showSnack('Obteniendo ubicación y notificando contactos...', AppColors.primaryPurple);

    try {
      final SosSnapshot snapshot = await locationService.captureSosSnapshot();
      _lastSnapshot = snapshot;
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
        'SOS enviado a ${primaryContacts.length} contacto(s) · Batería ${snapshot.batteryLevel}%',
        AppColors.successGreen,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error al enviar SOS: $e', AppColors.dangerRedDeep);
    }
  }

  void _startLiveTracking() {
    ref.read(routePointsProvider.notifier).state = [];
    final locationService = ref.read(locationServiceProvider);

    _trackingSubscription = locationService.liveTrackingStream().listen((position) {
      final points = [...ref.read(routePointsProvider), LatLng(position.latitude, position.longitude)];
      ref.read(routePointsProvider.notifier).state = points;
    });

    // Reenvía la ubicación actualizada a los contactos cada 20s, hasta 30 min
    // (90 veces × 20s = 30 min), o hasta que se cancele el SOS.
    _resendCount = 0;
    _resendTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      _resendCount++;
      if (_resendCount > 90) {
        timer.cancel();
        return;
      }
      await _resendLocationUpdate();
    });
  }

  Future<void> _resendLocationUpdate() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final messagingService = ref.read(messagingServiceProvider);
      final contactsRepo = ref.read(contactsRepositoryProvider);

      final snapshot = await locationService.captureSosSnapshot();
      final message = 'Actualización de ubicación en vivo:\n${messagingService.buildEmergencyMessage(snapshot)}';
      final primaryContacts = await contactsRepo.getPrimaryPair();
      for (final c in primaryContacts) {
        await messagingService.openWhatsApp(c.phone, message);
      }
    } catch (_) {
      // Si falla un envío puntual, se sigue intentando en el próximo ciclo.
    }
  }

  void _stopLiveTracking() {
    _trackingSubscription?.cancel();
    _trackingSubscription = null;
    _resendTimer?.cancel();
    _resendTimer = null;
  }

  void _startVibrationPattern() {
    HapticFeedback.heavyImpact();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      HapticFeedback.heavyImpact();
    });
  }

  void _stopVibration() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
  }

  Future<void> _startAlarm() async {
    final player = ref.read(audioPlayerProvider);
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource('sounds/alarm.wav'));
  }

  Future<void> _stopAlarm() async {
    final player = ref.read(audioPlayerProvider);
    await player.stop();
  }

  void _showSnack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(text, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _cancelActiveSos() async {
    setState(() => _sosSent = false);
    ref.read(sosActiveProvider.notifier).state = false;
    _stopVibration();
    _stopAlarm();
    _stopLiveTracking();
    ref.read(flashServiceProvider).stopStrobe();

    final path = await ref.read(audioRecordingServiceProvider).stopRecording();
    await BackgroundGuardService.stop();

    if (_lastSnapshot != null) {
      final entry = HistoryEntry(
        id: const Uuid().v4(),
        timestamp: _lastSnapshot!.timestamp,
        latitude: _lastSnapshot!.latitude,
        longitude: _lastSnapshot!.longitude,
        address: _lastSnapshot!.address,
        batteryLevel: _lastSnapshot!.batteryLevel,
        audioPath: path,
      );
      await ref.read(historyRepositoryProvider).add(entry);
      ref.invalidate(historyProvider);
    }

    if (path != null && mounted) {
      _showSnack('Audio guardado en el teléfono', AppColors.successGreen);
    }
  }

  Future<void> _callPolice() async {
    final callService = ref.read(callServiceProvider);
    final services = ref.read(emergencyServicesProvider);
    final police = services.firstWhere((s) => s.id == 'police', orElse: () => services.first);
    await callService.requestCallPermission();
    await callService.call(police.currentNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              const GuardianLogo(),
              const SizedBox(height: 6),
              Text('Sistema de Protección Personal', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
              const SizedBox(height: 18),
              _buildStatusPill(),
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

  Widget _buildStatusPill() {
    return AnimatedBuilder(
      animation: _dotController,
      builder: (context, child) {
        final glow = 0.5 + _dotController.value * 0.5;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.glassLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [AppColors.successGreen, AppColors.accentCyan]),
                  boxShadow: [BoxShadow(color: AppColors.successGreen.withOpacity(glow), blurRadius: 8, spreadRadius: 1)],
                ),
              ),
              const SizedBox(width: 8),
              Text('Sistema activo · GPS conectado',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIdleState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _handleActivation,
          child: SizedBox(
            width: 260,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildRing(delayFraction: 0.0, color: AppColors.accentPink, baseSize: 190),
                _buildRing(delayFraction: 0.33, color: AppColors.primaryPurple, baseSize: 216),
                _buildRing(delayFraction: 0.66, color: AppColors.accentCyan, baseSize: 242),
                AnimatedBuilder(
                  animation: Listenable.merge([_btnController, _iconController]),
                  builder: (context, child) {
                    final t = _btnController.value;
                    final scale = 1.0 + t * 0.05;
                    final iconT = _iconController.value;
                    final iconOffset = (iconT < 0.5 ? iconT : 1 - iconT) * 8;
                    final glowColor = Color.lerp(AppColors.dangerRed, AppColors.accentPink, t)!;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.dangerRed, AppColors.dangerRedDeep, AppColors.accentPink],
                          ),
                          boxShadow: [
                            BoxShadow(color: glowColor.withOpacity(0.6), blurRadius: 34, spreadRadius: 3),
                            const BoxShadow(color: Colors.black38, blurRadius: 24, offset: Offset(0, 14)),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.translate(
                                offset: Offset(0, -iconOffset),
                                child: const Icon(Icons.warning_rounded, color: Colors.white, size: 34),
                              ),
                              const SizedBox(height: 4),
                              Text('AYUDA', style: GoogleFonts.spaceGrotesk(
                                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 1.2,
                              )),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text('Toca para activar', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 22),
        _buildPoliceButton(),
      ],
    );
  }

  Widget _buildRing({required double delayFraction, required Color color, required double baseSize}) {
    return AnimatedBuilder(
      animation: _ringController,
      builder: (context, child) {
        double t = (_ringController.value + delayFraction) % 1.0;
        final scale = 0.85 + (t < 0.5 ? t * 2 : (1 - t) * 2) * 0.15;
        final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2) * 0.7;
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: baseSize,
              height: baseSize,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPoliceButton() {
    return GestureDetector(
      onTap: _callPolice,
      child: AnimatedBuilder(
        animation: _btnController,
        builder: (context, child) {
          final glowColor = Color.lerp(AppColors.policeBlue, AppColors.policeBlueLight, _btnController.value)!;
          return Container(
            width: 230,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [AppColors.policeBlue, AppColors.policeBlueMid, AppColors.policeBlueLight],
              ),
              boxShadow: [
                BoxShadow(color: glowColor.withOpacity(0.5), blurRadius: 20, spreadRadius: 1),
                const BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 8)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_police_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('LLAMAR POLICÍA', style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5,
                )),
              ],
            ),
          );
        },
      ),
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
                  backgroundColor: AppColors.glassLight,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accentPink),
                ),
              ),
              Text('$_secondsLeft', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Enviando SOS automáticamente…', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 15)),
        const SizedBox(height: 36),
        OutlinedButton(
          onPressed: _cancelCountdown,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: AppColors.glassBorder),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text('CANCELAR', style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: 1)),
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
            gradient: const LinearGradient(colors: [AppColors.successGreen, AppColors.accentCyan]),
            boxShadow: [BoxShadow(color: AppColors.successGreen.withOpacity(0.5), blurRadius: 24, spreadRadius: 2)],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 22),
        Text('SOS ACTIVO', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text('Seguimiento en vivo activado', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MapScreen()),
          ),
          icon: const Icon(Icons.map_rounded, color: AppColors.accentCyan, size: 18),
          label: Text('Ver mapa', style: GoogleFonts.inter(color: AppColors.accentCyan, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.accentCyan),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _cancelActiveSos,
          child: const Text('DETENER SOS'),
        ),
      ],
    );
  }
}
