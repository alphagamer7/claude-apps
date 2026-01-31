import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/artwork.dart';
import '../data/palettes.dart';

class ExportService {
  static Future<Uint8List> renderToPng(Artwork artwork, int cellSize) async {
    final palette = palettes[artwork.paletteIndex].colors;
    final imageSize = artwork.gridSize * cellSize;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, imageSize.toDouble(), imageSize.toDouble()),
    );

    // Draw background
    final bgPaint = Paint()..color = const Color(0xFF303030);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, imageSize.toDouble(), imageSize.toDouble()),
      bgPaint,
    );

    // Draw cells
    for (int row = 0; row < artwork.gridSize; row++) {
      for (int col = 0; col < artwork.gridSize; col++) {
        final colorIndex = artwork.getCell(row, col);
        if (colorIndex >= 0 && colorIndex < palette.length) {
          final paint = Paint()..color = palette[colorIndex];
          canvas.drawRect(
            Rect.fromLTWH(
              col * cellSize.toDouble(),
              row * cellSize.toDouble(),
              cellSize.toDouble(),
              cellSize.toDouble(),
            ),
            paint,
          );
        }
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(imageSize, imageSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static Future<File> saveToTempFile(Uint8List pngBytes, String name) async {
    final dir = await getTemporaryDirectory();
    final sanitized = name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final file = File('${dir.path}/${sanitized}_gridsketch.png');
    await file.writeAsBytes(pngBytes);
    return file;
  }

  static Future<void> shareImage(Artwork artwork, int cellSize) async {
    final bytes = await renderToPng(artwork, cellSize);
    final file = await saveToTempFile(bytes, artwork.name);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Created with GridSketch: ${artwork.name}',
    );
  }
}
