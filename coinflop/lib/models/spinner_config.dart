import 'dart:convert';

class SpinnerConfig {
  final List<String> options;

  SpinnerConfig({required this.options});

  String toJson() => jsonEncode(options);

  factory SpinnerConfig.fromJson(String json) {
    final list = (jsonDecode(json) as List).cast<String>();
    return SpinnerConfig(options: list);
  }

  factory SpinnerConfig.defaultConfig() => SpinnerConfig(
        options: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
      );
}
