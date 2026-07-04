import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/history_entry.dart';

class HistoryRepository {
  static const _key = 'guardian_sos_history';

  Future<List<HistoryEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    final entries = list.map((e) => HistoryEntry.fromJson(e)).toList();
    // Más reciente primero.
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  Future<void> add(HistoryEntry entry) async {
    final entries = await getAll();
    entries.add(entry);
    await _saveAll(entries);
  }

  Future<void> delete(String id) async {
    final entries = await getAll();
    entries.removeWhere((e) => e.id == id);
    await _saveAll(entries);
  }

  Future<void> _saveAll(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
