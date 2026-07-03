import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final countdown = ref.watch(countdownSecondsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        children: [
          const _SectionHeader('Apariencia'),
          RadioListTile<ThemeModeOption>(
            title: const Text('Claro'),
            value: ThemeModeOption.light,
            groupValue: themeMode,
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),
          RadioListTile<ThemeModeOption>(
            title: const Text('Oscuro'),
            value: ThemeModeOption.dark,
            groupValue: themeMode,
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),
          RadioListTile<ThemeModeOption>(
            title: const Text('Sistema'),
            value: ThemeModeOption.system,
            groupValue: themeMode,
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),
          const _SectionHeader('Cuenta regresiva de SOS'),
          ListTile(
            title: Text('$countdown segundos'),
            subtitle: Slider(
              value: countdown.toDouble(),
              min: 3,
              max: 15,
              divisions: 12,
              label: '$countdown s',
              onChanged: (v) => ref.read(countdownSecondsProvider.notifier).state = v.round(),
            ),
          ),
          const _SectionHeader('Funciones automáticas'),
          SwitchListTile(title: const Text('Activar flash estroboscópico'), value: true, onChanged: (_) {}),
          SwitchListTile(title: const Text('Activar alarma sonora'), value: true, onChanged: (_) {}),
          SwitchListTile(title: const Text('Grabar audio'), value: true, onChanged: (_) {}),
          SwitchListTile(title: const Text('Grabar video'), value: true, onChanged: (_) {}),
          SwitchListTile(title: const Text('Seguimiento en vivo (30 min)'), value: true, onChanged: (_) {}),
          SwitchListTile(title: const Text('Vibración'), value: true, onChanged: (_) {}),
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
    );
  }
}
