import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers.dart';
import '../../../core/services/settings_repository.dart';
import '../../../core/theme/app_theme.dart';

class PremiumFeature {
  final IconData icon;
  final String title;
  final String description;
  const PremiumFeature({required this.icon, required this.title, required this.description});
}

const premiumFeatures = [
  PremiumFeature(
    icon: Icons.videocam_rounded,
    title: 'Grabación de video',
    description: 'Graba video (cámara frontal o trasera) automáticamente al activar el SOS',
  ),
  PremiumFeature(
    icon: Icons.qr_code_rounded,
    title: 'Perfil médico con QR',
    description: 'Tipo de sangre, alergias y medicamentos, visibles con un escaneo aunque tu teléfono esté bloqueado',
  ),
  PremiumFeature(
    icon: Icons.accessibility_new_rounded,
    title: 'Detección de caídas',
    description: 'Activa el SOS solo si detecta una caída fuerte y no respondes',
  ),
  PremiumFeature(
    icon: Icons.mic_rounded,
    title: 'Activación por voz',
    description: 'Di "ayuda" o "emergencia" para activar el SOS sin tocar la pantalla',
  ),
  PremiumFeature(
    icon: Icons.cloud_rounded,
    title: 'Respaldo en la nube',
    description: 'Tus contactos e historial respaldados, por si cambias de teléfono',
  ),
];

/// Abre la hoja de desbloqueo Premium.
void showPremiumPaywall(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PremiumPaywallSheet(),
  );
}

class _PremiumPaywallSheet extends ConsumerWidget {
  const _PremiumPaywallSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(premiumUnlockedProvider);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bgDeep, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [AppColors.accentPink, AppColors.primaryPurple]),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Guardian Premium', style: GoogleFonts.spaceGrotesk(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800,
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Más capas de protección para cuando de verdad importan.',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ...premiumFeatures.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.glassLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(f.icon, color: AppColors.accentCyan, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                              Text(f.description, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              if (unlocked)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.successGreen.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 20),
                      const SizedBox(width: 8),
                      Text('Premium activo', style: GoogleFonts.inter(color: AppColors.successGreen, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primaryPurple, AppColors.accentPink]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text('Próximamente disponible para compra',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('El cobro real se activará cuando la app esté publicada en Google Play.',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () {
                    ref.read(premiumUnlockedProvider.notifier).state = true;
                    SettingsRepository().setPremiumUnlocked(true);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: AppColors.glassBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Simular desbloqueo (modo prueba, sin cobro)',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
