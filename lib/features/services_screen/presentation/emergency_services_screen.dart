import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers.dart';
import '../../../core/constants/emergency_numbers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/neon_background.dart';

class EmergencyServicesScreen extends ConsumerWidget {
  const EmergencyServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(emergencyServicesProvider);
    final callService = ref.watch(callServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(title: const Text('Servicios de Emergencia')),
      extendBodyBehindAppBar: true,
      body: NeonBackground(
        child: SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 90, 20, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.05,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return _ServiceCard(
                service: service,
                index: index,
                onTap: () async {
                  await callService.requestCallPermission();
                  await callService.call(service.currentNumber);
                },
                onLongPress: () => _editNumber(context, ref, service),
              );
            },
          ),
        ),
      ),
    );
  }

  void _editNumber(BuildContext context, WidgetRef ref, EmergencyService service) {
    final controller = TextEditingController(text: service.currentNumber);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A3E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Editar número · ${service.name}', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Número de teléfono',
                labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.glassBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accentCyan)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final services = [...ref.read(emergencyServicesProvider)];
                  final i = services.indexWhere((s) => s.id == service.id);
                  services[i].currentNumber = controller.text.trim();
                  ref.read(emergencyServicesProvider.notifier).state = services;
                  Navigator.pop(ctx);
                },
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mapea cada servicio a un ícono de Material Design (vectorial, sin emoji).
IconData _iconForService(String id) {
  switch (id) {
    case 'police':
      return Icons.local_police_rounded;
    case 'ambulance':
      return Icons.medical_services_rounded;
    case 'firefighters':
      return Icons.local_fire_department_rounded;
    case 'redcross':
      return Icons.health_and_safety_rounded;
    case 'civilprotection':
      return Icons.shield_rounded;
    case 'guardianacional':
      return Icons.security_rounded;
    case 'women':
      return Icons.woman_rounded;
    case 'children':
      return Icons.child_care_rounded;
    case 'psychological':
      return Icons.psychology_rounded;
    case 'roadrescue':
      return Icons.car_repair_rounded;
    default:
      return Icons.emergency_rounded;
  }
}

class _ServiceCard extends StatefulWidget {
  final EmergencyService service;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ServiceCard({required this.service, required this.index, required this.onTap, required this.onLongPress});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.glassLight,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.glassBorder)),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final scale = 1.0 + _controller.value * 0.08;
                  final glow = Color.lerp(AppColors.primaryPurple, AppColors.accentPink, _controller.value)!;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [AppColors.accentPink, AppColors.primaryPurple, AppColors.accentCyan]),
                        boxShadow: [BoxShadow(color: glow.withOpacity(0.5), blurRadius: 12, spreadRadius: 1)],
                      ),
                      child: Center(child: Icon(_iconForService(widget.service.id), color: Colors.white, size: 22)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(widget.service.name, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 3),
              Text(widget.service.currentNumber, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
