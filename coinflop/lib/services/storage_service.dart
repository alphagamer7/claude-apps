import 'package:shared_preferences/shared_preferences.dart';
import '../models/spinner_config.dart';

class StorageService {
  static const String _spinnerConfigKey = 'spinner_config';
  static const String _diceCountKey = 'dice_count';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Spinner config persistence
  SpinnerConfig getSpinnerConfig() {
    final json = _prefs.getString(_spinnerConfigKey);
    if (json == null) return SpinnerConfig.defaultConfig();
    return SpinnerConfig.fromJson(json);
  }

  Future<void> saveSpinnerConfig(SpinnerConfig config) async {
    await _prefs.setString(_spinnerConfigKey, config.toJson());
  }

  // Dice count persistence
  int getDiceCount() => _prefs.getInt(_diceCountKey) ?? 2;

  Future<void> saveDiceCount(int count) async {
    await _prefs.setInt(_diceCountKey, count);
  }
}
