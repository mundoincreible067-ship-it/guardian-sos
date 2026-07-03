import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final countdown = ref.watch(countdownSecondsProvider);

    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _SectionHeader('Apariencia'),
          _RadioTile(
            title: 'Claro',
            selected: themeMode == ThemeModeOption.light,
            onTap: () => ref.read(themeModeProvider.notifier).state = ThemeModeOption.light,
          ),
          _RadioTile(
            title: 'Oscuro',
            selected: themeMode == ThemeModeOption.dark,
            onTap: () => ref.read(themeModeProvider.notifier).state = ThemeModeOption.dark,
          ),
          _RadioTile(
            title: 'Sistema',
            selected: themeMode == ThemeModeOption.system,
            onTap: () => ref.read(themeModeProvider.notifier).state = ThemeModeOption.system,
          ),
          const _SectionHeader('Cuenta regresiva de SOS'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$countdown segundos', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.signal,
                    inactiveTrackColor: Colors.white.withOpacity(0.08),
                    thumbColor: AppColors.signal,
                    overlayColor: AppColors.signal.withOpacity(0.15),
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
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
      child: Text(title.toUpperCase(), style: GoogleFonts.inter(
        color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2,
      )),
    );
  }
}

class _RadioTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  const _RadioTile({required this.title, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? AppColors.calm : AppColors.textMuted, width: 2),
              ),
              child: selected
                  ? Center(child: Container(
                      width: 12, height: 12,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.calm),
                    ))
                  : null,
            ),
            const SizedBox(width: 14),
            Text(title, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15)),
          ],
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(widget.title, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15))),
          Switch(value: value, onChanged: (v) => setState(() => value = v)),
        ],
      ),
    );
  }
}
