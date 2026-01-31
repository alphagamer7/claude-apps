import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/counter.dart';
import 'database_service.dart';

class CsvExportService {
  final DatabaseService _db = DatabaseService();

  Future<void> exportAllHistory() async {
    final counters = await _db.getCounters();
    final allHistory = await _db.getAllHistory();

    final counterNames = <int, String>{};
    for (final c in counters) {
      if (c.id != null) counterNames[c.id!] = c.name;
    }

    final buffer = StringBuffer();
    buffer.writeln('Counter,Date,Value');

    for (final entry in allHistory) {
      final name = counterNames[entry.counterId] ?? 'Unknown';
      final escapedName = name.contains(',') ? '"$name"' : name;
      buffer.writeln('$escapedName,${entry.date},${entry.value}');
    }

    await _shareCSV(buffer.toString(), 'tallymark_history.csv');
  }

  Future<void> exportCounterHistory(Counter counter) async {
    if (counter.id == null) return;
    final history = await _db.getHistoryForCounter(counter.id!);

    final buffer = StringBuffer();
    buffer.writeln('Date,Value');

    for (final entry in history) {
      buffer.writeln('${entry.date},${entry.value}');
    }

    final safeName = counter.name.replaceAll(RegExp(r'[^\w]'), '_').toLowerCase();
    await _shareCSV(buffer.toString(), 'tallymark_$safeName.csv');
  }

  Future<void> _shareCSV(String csvContent, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csvContent);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'TallyMark Export',
    );
  }
}
