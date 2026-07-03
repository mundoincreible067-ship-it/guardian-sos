import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers.dart';
import '../domain/contact_model.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
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
        onPressed: () => _showEditor(context, ref),
        child: const Icon(Icons.add),
      ),
      body: contactsAsync.when(
        data: (contacts) {
          if (contacts.isEmpty) {
            return const Center(child: Text('Aún no tienes contactos. Toca + para añadir uno.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: contacts.length,
            itemBuilder: (context, i) {
              final c = contacts[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(c.name.isNotEmpty ? c.name[0] : '?')),
                  title: Text(c.name),
                  subtitle: Text('${c.relation} · ${c.phone}${c.isPrimary ? ' · Principal' : ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditor(context, ref, existing: c)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _importFromDevice(BuildContext context, WidgetRef ref) async {
    // La importación real usa flutter_contacts con permiso Permission.contacts.
    // Aquí se deja el flujo listo; requiere que el usuario conceda el permiso
    // "Contactos" la primera vez (ver AndroidManifest / Info.plist).
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selecciona un contacto de tu agenda (requiere permiso de Contactos)')),
    );
    // TODO próxima entrega: usar FlutterContacts.openExternalPick() y mapear a EmergencyContact.
  }

  void _showEditor(BuildContext context, WidgetRef ref, {EmergencyContact? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final phoneCtrl = TextEditingController(text: existing?.phone);
    final relationCtrl = TextEditingController(text: existing?.relation);
    final emailCtrl = TextEditingController(text: existing?.email);
    bool isPrimary = existing?.isPrimary ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(existing == null ? 'Nuevo contacto' : 'Editar contacto',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Teléfono'), keyboardType: TextInputType.phone),
                TextField(controller: relationCtrl, decoration: const InputDecoration(labelText: 'Relación (ej. Madre, Amigo)')),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Correo electrónico (opcional)')),
                SwitchListTile(
                  title: const Text('Contacto principal (recibe el SOS automático)'),
                  value: isPrimary,
                  onChanged: (v) => setState(() => isPrimary = v),
                ),
                const SizedBox(height: 12),
                FilledButton(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
