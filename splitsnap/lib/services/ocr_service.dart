import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/split_item.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Price pattern: optional $ followed by digits, dot, and exactly 2 decimal digits.
  static final RegExp _priceRegex = RegExp(r'\$?\s?(\d+\.\d{2})');

  /// Lines to filter out (subtotals, totals, tax, etc.)
  static final RegExp _filterRegex = RegExp(
    r'(subtotal|sub\s*total|total|tax|gratuity|tip|balance|change|visa|mastercard|amex|cash|credit|debit|card|thank|guest|server|table|check|order|date|time)',
    caseSensitive: false,
  );

  /// Process an image file and return extracted line items.
  Future<List<SplitItem>> processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return _parseReceipt(recognizedText.text);
  }

  /// Parse recognized text into SplitItems.
  List<SplitItem> _parseReceipt(String text) {
    final items = <SplitItem>[];
    final lines = text.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Skip lines that match filter patterns
      if (_filterRegex.hasMatch(trimmed)) continue;

      // Look for a price on this line
      final priceMatch = _priceRegex.firstMatch(trimmed);
      if (priceMatch == null) continue;

      final priceString = priceMatch.group(1)!;
      final price = double.tryParse(priceString);
      if (price == null || price <= 0) continue;

      // Extract item name: everything before the price match
      String itemName = trimmed.substring(0, priceMatch.start).trim();

      // Clean up common prefixes like quantity numbers (e.g., "1 " or "2x ")
      itemName = itemName.replaceFirst(RegExp(r'^\d+[x\s]\s*'), '');

      // Remove trailing special characters
      itemName = itemName.replaceAll(RegExp(r'[\.\-_:]+$'), '').trim();

      if (itemName.isEmpty) {
        itemName = 'Item';
      }

      // Capitalize first letter
      itemName = itemName[0].toUpperCase() + itemName.substring(1);

      items.add(SplitItem(name: itemName, price: price));
    }

    return items;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
