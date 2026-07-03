import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return _ServiceButton(
            service: service,
            onTap: () async {
              await callService.requestCallPermission();
              await callService.call(service.currentNumber);
            },
            onLongPress: () => _editNumber(context, ref, service),
          );
        },
      ),
    );
  }

  void _editNumber(BuildContext context, WidgetRef ref, EmergencyService service) {
    final controller = TextEditingController(text: service.currentNumber);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar número · ${service.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Número de teléfono'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final services = [...ref.read(emergencyServicesProvider)];
              final i = services.indexWhere((s) => s.id == service.id);
              services[i].currentNumber = controller.text.trim();
              ref.read(emergencyServicesProvider.notifier).state = services;
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _ServiceButton extends StatelessWidget {
  final EmergencyService service;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ServiceButton({required this.service, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(service.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(service.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(service.currentNumber, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
