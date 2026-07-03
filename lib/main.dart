import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart'; // generado por `flutterfire configure` (ver README)
import 'core/theme/app_theme.dart';
import 'core/providers.dart';
import 'features/home/presentation/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Descomentar tras ejecutar `flutterfire configure` (ver README, sección Firebase):
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await _requestCorePermissions();

  runApp(const ProviderScope(child: GuardianSosApp()));
}

/// Solicita al arrancar los permisos imprescindibles para que el botón SOS
/// funcione desde el primer uso. El resto (cámara, micrófono, contactos,
/// ubicación en segundo plano) se piden justo antes de usarse.
Future<void> _requestCorePermissions() async {
  await [
    Permission.location,
    Permission.locationWhenInUse,
    Permission.sms,
    Permission.phone,
    Permission.notification,
  ].request();
}

class GuardianSosApp extends ConsumerWidget {
  const GuardianSosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeOption = ref.watch(themeModeProvider);
    final themeMode = switch (themeOption) {
      ThemeModeOption.light => ThemeMode.light,
      ThemeModeOption.dark => ThemeMode.dark,
      ThemeModeOption.system => ThemeMode.system,
    };

    return MaterialApp(
      title: 'Guardian SOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}
