import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/drivetrain.dart';

class StorageService {
  static const String _key = 'saved_drivetrains';

  static Future<List<Drivetrain>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((e) => Drivetrain.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> save(Drivetrain drivetrain) async {
    final all = await loadAll();
    // Replace if same id exists
    final idx = all.indexWhere((d) => d.id == drivetrain.id);
    if (idx >= 0) {
      all[idx] = drivetrain;
    } else {
      all.add(drivetrain);
    }
    await _saveAll(all);
  }

  static Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((d) => d.id == id);
    await _saveAll(all);
  }

  static Future<void> _saveAll(List<Drivetrain> drivetrains) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString =
        jsonEncode(drivetrains.map((d) => d.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }
}
