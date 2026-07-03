import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/neon_background.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countdown = ref.watch(countdownSecondsProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Configuración')),
      body: NeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(top: 66, bottom: 24),
            children: [
              const _SectionHeader('Cuenta regresiva de SOS'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$countdown segundos', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
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
              const _SectionHeader('Funciones automáticas'),
              const _SwitchTile(title: 'Activar flash estroboscópico'),
              const _SwitchTile(title: 'Activar alarma sonora'),
              const _SwitchTile(title: 'Grabar audio'),
              const _SwitchTile(title: 'Grabar video'),
              const _SwitchTile(title: 'Seguimiento en vivo (30 min)'),
              const _SwitchTile(title: 'Vibración'),
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

class _SwitchTile extends StatefulWidget {
  final String title;
  const _SwitchTile({required this.title});

  @override
  State<_SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends State<_SwitchTile> {
  bool value = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glassLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(child: Text(widget.title, style: GoogleFonts.inter(color: Colors.white, fontSize: 14))),
          Switch(value: value, onChanged: (v) => setState(() => value = v)),
        ],
      ),
    );
  }
}
