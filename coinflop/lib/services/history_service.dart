import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/randomizer_result.dart';

class HistoryService {
  static const String _historyKey = 'randomizer_history';
  static const int _maxHistory = 100;

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  List<RandomizerResult> getHistory() {
    final json = _prefs.getString(_historyKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => RandomizerResult.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  List<RandomizerResult> getHistoryByType(RandomizerType type) {
    return getHistory().where((r) => r.type == type).toList();
  }

  Future<void> addResult(RandomizerResult result) async {
    final history = getHistory();
    history.insert(0, result);
    if (history.length > _maxHistory) {
      history.removeRange(_maxHistory, history.length);
    }
    await _prefs.setString(
      _historyKey,
      jsonEncode(history.map((r) => r.toMap()).toList()),
    );
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }

  Future<void> clearHistoryByType(RandomizerType type) async {
    final history = getHistory().where((r) => r.type != type).toList();
    await _prefs.setString(
      _historyKey,
      jsonEncode(history.map((r) => r.toMap()).toList()),
    );
  }

  Map<String, int> getCoinFlipStats() {
    final results = getHistoryByType(RandomizerType.coinFlip);
    int heads = 0;
    int tails = 0;
    for (final r in results) {
      if (r.outcome == 'HEADS') {
        heads++;
      } else {
        tails++;
      }
    }
    return {'heads': heads, 'tails': tails};
  }
}
