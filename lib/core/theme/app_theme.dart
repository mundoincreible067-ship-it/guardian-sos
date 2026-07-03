import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta "Guardian": noche profunda + coral de urgencia + teal de calma.
/// Pensada para usarse en momentos de estrés, a menudo de noche: alto
/// contraste, un solo acento urgente (el SOS) y todo lo demás sereno.
class AppColors {
  // Fondo
  static const Color night = Color(0xFF0B1120);
  static const Color nightElevated = Color(0xFF141B2E);
  static const Color nightCard = Color(0xFF1A2338);

  // Acento de urgencia (SOS)
  static const Color signal = Color(0xFFFF4757);
  static const Color signalDeep = Color(0xFFC0293A);
  static const Color signalGlow = Color(0x33FF4757);

  // Acento de calma / estado seguro
  static const Color calm = Color(0xFF2DD4BF);
  static const Color calmDeep = Color(0xFF14B8A6);

  // Aviso
  static const Color amber = Color(0xFFFBBF24);

  // Texto
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Superficies claras (para el modo claro alternativo)
  static const Color paper = Color(0xFFF6F7FB);
  static const Color paperCard = Color(0xFFFFFFFF);
}

class AppTheme {
  static TextTheme _textTheme(Color primary, Color secondary) {
    final display = GoogleFonts.spaceGroteskTextTheme();
    final body = GoogleFonts.interTextTheme();
    return body.copyWith(
      displayLarge: display.displayLarge?.copyWith(color: primary, fontWeight: FontWeight.w700),
      displayMedium: display.displayMedium?.copyWith(color: primary, fontWeight: FontWeight.w700),
      headlineLarge: display.headlineLarge?.copyWith(color: primary, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: display.headlineMedium?.copyWith(color: primary, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineSmall: display.headlineSmall?.copyWith(color: primary, fontWeight: FontWeight.w600),
      titleLarge: display.titleLarge?.copyWith(color: primary, fontWeight: FontWeight.w600),
      titleMedium: body.titleMedium?.copyWith(color: primary, fontWeight: FontWeight.w600),
      bodyLarge: body.bodyLarge?.copyWith(color: primary),
      bodyMedium: body.bodyMedium?.copyWith(color: secondary),
      labelLarge: body.labelLarge?.copyWith(color: primary, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    );
  }

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.night,
    textTheme: _textTheme(AppColors.textPrimary, AppColors.textSecondary),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.signal,
      secondary: AppColors.calm,
      surface: AppColors.nightCard,
      error: AppColors.signal,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.nightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.nightElevated,
      indicatorColor: AppColors.signal.withOpacity(0.18),
      elevation: 0,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.inter(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? AppColors.signal : AppColors.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? AppColors.signal : AppColors.textMuted);
      }),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.signal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.calm : AppColors.textMuted),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.calm.withOpacity(0.35) : AppColors.nightCard),
    ),
    dividerColor: Colors.white.withOpacity(0.06),
  );

  // Tema claro alternativo, por si el usuario lo prefiere de día.
  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.paper,
    textTheme: _textTheme(const Color(0xFF0F172A), const Color(0xFF475569)),
    colorScheme: const ColorScheme.light(
      primary: AppColors.signal,
      secondary: AppColors.calmDeep,
      surface: AppColors.paperCard,
      error: AppColors.signal,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        color: const Color(0xFF0F172A),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.paperCard,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
