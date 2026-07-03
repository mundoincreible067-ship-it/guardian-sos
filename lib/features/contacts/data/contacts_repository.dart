import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/contact_model.dart';

class ContactsRepository {
  static const _key = 'guardian_sos_contacts';
  static const maxContacts = 10;

  Future<List<EmergencyContact>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => EmergencyContact.fromJson(e)).toList();
  }

  Future<void> saveAll(List<EmergencyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<void> add(EmergencyContact contact) async {
    final contacts = await getAll();
    if (contacts.length >= maxContacts) {
      throw Exception('Máximo $maxContacts contactos permitidos');
    }
    contacts.add(contact);
    await saveAll(contacts);
  }

  Future<void> update(EmergencyContact contact) async {
    final contacts = await getAll();
    final index = contacts.indexWhere((c) => c.id == contact.id);
    if (index != -1) {
      contacts[index] = contact;
      await saveAll(contacts);
    }
  }

  Future<void> delete(String id) async {
    final contacts = await getAll();
    contacts.removeWhere((c) => c.id == id);
    await saveAll(contacts);
  }

  /// Los primeros dos contactos marcados como primarios (o los dos primeros
  /// registrados si ninguno está marcado) reciben el SOS automático.
  Future<List<EmergencyContact>> getPrimaryPair() async {
    final contacts = await getAll();
    final primaries = contacts.where((c) => c.isPrimary).toList();
    if (primaries.length >= 2) return primaries.take(2).toList();
    return contacts.take(2).toList();
  }
}
