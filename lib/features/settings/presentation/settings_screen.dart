import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/neon_background.dart';
import '../../history/presentation/history_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countdown = ref.watch(countdownSecondsProvider);
    final instantSend = ref.watch(instantSendProvider);
    final vibrationOn = ref.watch(vibrationEnabledProvider);
    final alarmOn = ref.watch(alarmEnabledProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Configuración')),
      body: NeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(top: 66, bottom: 24),
            children: [
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primaryPurple, AppColors.accentPink]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Ver historial de emergencias',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const _SectionHeader('Activación del botón SOS'),
              _RealSwitchTile(
                title: 'Envío instantáneo',
                subtitle: 'El botón manda el SOS de inmediato, sin espera',
                value: instantSend,
                onChanged: (v) => ref.read(instantSendProvider.notifier).state = v,
              ),
              if (!instantSend) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Cuenta regresiva: $countdown segundos',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: AppColors.accentPink,
                          inactiveTrackColor: AppColors.glassLight,
                          thumbColor: AppColors.accentPink,
                          overlayColor: AppColors.accentPink.withOpacity(0.15),
                        ),
                        child: Slider(
                          value: countdown.toDouble(),
                          min: 3,
                          max: 15,
                          divisions: 12,
                          label: '$countdown s',
                          onChanged: (v) => ref.read(countdownSecondsProvider.notifier).state = v.round(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const _SectionHeader('Funciones automáticas'),
              _RealSwitchTile(
                title: 'Vibración',
                subtitle: 'El teléfono vibra al activar el SOS',
                value: vibrationOn,
                onChanged: (v) => ref.read(vibrationEnabledProvider.notifier).state = v,
              ),
              _RealSwitchTile(
                title: 'Alarma sonora',
                subtitle: 'Sirena en bucle mientras el SOS está activo',
                value: alarmOn,
                onChanged: (v) => ref.read(alarmEnabledProvider.notifier).state = v,
              ),
              _RealSwitchTile(
                title: 'Flash estroboscópico',
                subtitle: 'La linterna parpadea mientras el SOS está activo',
                value: ref.watch(flashEnabledProvider),
                onChanged: (v) => ref.read(flashEnabledProvider.notifier).state = v,
              ),
              _RealSwitchTile(
                title: 'Grabar audio',
                subtitle: 'Graba el ambiente como evidencia mientras el SOS está activo',
                value: ref.watch(recordAudioEnabledProvider),
                onChanged: (v) => ref.read(recordAudioEnabledProvider.notifier).state = v,
              ),
              const _SwitchTilePending(title: 'Grabar video'),
              const _SwitchTilePending(title: 'Seguimiento en vivo (30 min)'),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(title.toUpperCase(), style: GoogleFonts.inter(
        color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2,
      )),
    );
  }
}

/// Interruptor conectado a una función real de la app.
class _RealSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RealSwitchTile({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.glassLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(subtitle, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Interruptor de una función que aún no está conectada (próxima entrega).
class _SwitchTilePending extends StatelessWidget {
  final String title;
  const _SwitchTilePending({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.glassLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w600)),
                Text('Próxima entrega', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Switch(value: false, onChanged: null),
        ],
      ),
    );
  }
}
