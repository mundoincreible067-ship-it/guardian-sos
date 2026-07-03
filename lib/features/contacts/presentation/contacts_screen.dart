import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/contact_model.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: AppBar(
        title: const Text('Contactos de Emergencia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.contact_page_outlined),
            tooltip: 'Importar desde agenda',
            onPressed: () => _importFromDevice(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.signal,
        onPressed: () => _showEditor(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: contactsAsync.when(
        data: (contacts) {
          if (contacts.isEmpty) {
            return Center(
              child: Text('Aún no tienes contactos. Toca + para añadir uno.',
                  style: GoogleFonts.inter(color: AppColors.textMuted)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length,
            itemBuilder: (context, i) {
              final c = contacts[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.nightCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.calm.withOpacity(0.15),
                    child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                        style: GoogleFonts.spaceGrotesk(color: AppColors.calm, fontWeight: FontWeight.w700)),
                  ),
                  title: Text(c.name, style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('${c.relation} · ${c.phone}${c.isPrimary ? ' · Principal' : ''}',
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.textMuted, size: 20),
                        onPressed: () => _showEditor(context, ref, existing: c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.signal, size: 20),
                        onPressed: () async {
                          await ref.read(contactsRepositoryProvider).delete(c.id);
                          ref.invalidate(contactsProvider);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.signal)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.textMuted))),
      ),
    );
  }

  Future<void> _importFromDevice(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.nightElevated,
        content: Text('Selecciona un contacto de tu agenda (requiere permiso de Contactos)',
            style: GoogleFonts.inter(color: AppColors.textPrimary)),
      ),
    );
  }

  void _showEditor(BuildContext context, WidgetRef ref, {EmergencyContact? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final phoneCtrl = TextEditingController(text: existing?.phone);
    final relationCtrl = TextEditingController(text: existing?.relation);
    final emailCtrl = TextEditingController(text: existing?.email);
    bool isPrimary = existing?.isPrimary ?? false;

    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.calm),
          ),
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.nightElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: StatefulBuilder(
          builder: (ctx, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing == null ? 'Nuevo contacto' : 'Editar contacto',
                    style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 18),
                TextField(controller: nameCtrl, style: GoogleFonts.inter(color: AppColors.textPrimary), decoration: deco('Nombre')),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, style: GoogleFonts.inter(color: AppColors.textPrimary), decoration: deco('Teléfono'), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: relationCtrl, style: GoogleFonts.inter(color: AppColors.textPrimary), decoration: deco('Relación (ej. Madre, Amigo)')),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, style: GoogleFonts.inter(color: AppColors.textPrimary), decoration: deco('Correo electrónico (opcional)')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Switch(
                      value: isPrimary,
                      onChanged: (v) => setState(() => isPrimary = v),
                    ),
                    Expanded(
                      child: Text('Contacto principal (recibe el SOS automático)',
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final repo = ref.read(contactsRepositoryProvider);
                      final contact = EmergencyContact(
                        id: existing?.id ?? const Uuid().v4(),
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        relation: relationCtrl.text.trim(),
                        email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                        isPrimary: isPrimary,
                      );
                      if (existing == null) {
                        await repo.add(contact);
                      } else {
                        await repo.update(contact);
                      }
                      ref.invalidate(contactsProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
