import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta "Guardian Neon": morado-índigo profundo con acentos neón
/// (rosa, cian, morado) — inspirada directamente en el boceto de
/// referencia del cliente.
class AppColors {
  static const Color primaryDark = Color(0xFF0F0F23);
  static const Color bgMid = Color(0xFF1A1A3E);
  static const Color bgDeep = Color(0xFF2D1B69);

  static const Color primaryPurple = Color(0xFF6366F1);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color dangerRedDeep = Color(0xFFDC2626);
  static const Color successGreen = Color(0xFF10B981);
  static const Color policeBlue = Color(0xFF1E40AF);
  static const Color policeBlueMid = Color(0xFF2563EB);
  static const Color policeBlueLight = Color(0xFF3B82F6);

  static const Color glassLight = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textMuted = Color(0x80FFFFFF);

  static const LinearGradient appBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, bgMid, bgDeep],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [dangerRed, dangerRedDeep, accentPink],
  );

  static const LinearGradient policeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [policeBlue, policeBlueMid, policeBlueLight],
  );

  static const LinearGradient logoGradient = LinearGradient(
    colors: [accentPink, primaryPurple, accentCyan],
  );
}

class AppTheme {
  static TextTheme _textTheme() {
    final display = GoogleFonts.spaceGroteskTextTheme();
    final body = GoogleFonts.interTextTheme();
    return body.copyWith(
      displayLarge: display.displayLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      headlineMedium: display.headlineMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      headlineSmall: display.headlineSmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      titleLarge: display.titleLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      titleMedium: body.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: body.bodyLarge?.copyWith(color: AppColors.textPrimary),
      bodyMedium: body.bodyMedium?.copyWith(color: AppColors.textSecondary),
      labelLarge: body.labelLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: 0.5),
    );
  }

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.primaryDark,
    textTheme: _textTheme(),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentPink,
      secondary: AppColors.accentCyan,
      surface: Color(0xFF1A1A3E),
      error: AppColors.dangerRed,
      onPrimary: Colors.white,
      onSurface: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xE6141428),
      indicatorColor: AppColors.accentPink.withOpacity(0.18),
      elevation: 0,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.inter(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.accentPink : AppColors.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? AppColors.accentPink : AppColors.textMuted);
      }),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentPink,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.successGreen : AppColors.textMuted),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.accentCyan.withOpacity(0.4) : AppColors.glassLight),
    ),
    dividerColor: AppColors.glassBorder,
  );

  static ThemeData light = dark;
}
