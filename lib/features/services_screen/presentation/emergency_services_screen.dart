import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers.dart';
import '../../../core/constants/emergency_numbers.dart';
import '../../../core/theme/app_theme.dart';

class EmergencyServicesScreen extends ConsumerWidget {
  const EmergencyServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(emergencyServicesProvider);
    final callService = ref.watch(callServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Servicios de Emergencia')),
      body: Container(
        decoration: const BoxDecoration(color: AppColors.night),
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.05,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return _ServiceCard(
              service: service,
              onTap: () async {
                await callService.requestCallPermission();
                await callService.call(service.currentNumber);
              },
              onLongPress: () => _editNumber(context, ref, service),
            );
          },
        ),
      ),
    );
  }

  void _editNumber(BuildContext context, WidgetRef ref, EmergencyService service) {
    final controller = TextEditingController(text: service.currentNumber);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.nightElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Editar número · ${service.name}', style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.inter(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Número de teléfono',
                labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.calm),
                ),
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

class _ServiceCard extends StatelessWidget {
  final EmergencyService service;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ServiceCard({required this.service, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.nightCard,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.signal.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(service.emoji, style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(height: 12),
              Text(service.name, textAlign: TextAlign.center, style: GoogleFonts.inter(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13,
              )),
              const SizedBox(height: 4),
              Text(service.currentNumber, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
