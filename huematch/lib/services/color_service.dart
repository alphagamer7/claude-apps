import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import '../data/color_names.dart';

class ColorService {
  ColorService._();

  /// Convert RGB to hex string (e.g., "#FF7F50").
  static String rgbToHex(int r, int g, int b) {
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  /// Convert RGB to HSL. Returns [hue (0-360), saturation (0-100), lightness (0-100)].
  static List<double> rgbToHsl(int r, int g, int b) {
    final double rNorm = r / 255.0;
    final double gNorm = g / 255.0;
    final double bNorm = b / 255.0;

    final double maxC = max(rNorm, max(gNorm, bNorm));
    final double minC = min(rNorm, min(gNorm, bNorm));
    final double delta = maxC - minC;

    double hue = 0;
    double saturation = 0;
    final double lightness = (maxC + minC) / 2;

    if (delta != 0) {
      saturation =
          lightness > 0.5 ? delta / (2 - maxC - minC) : delta / (maxC + minC);

      if (maxC == rNorm) {
        hue = ((gNorm - bNorm) / delta) + (gNorm < bNorm ? 6 : 0);
      } else if (maxC == gNorm) {
        hue = ((bNorm - rNorm) / delta) + 2;
      } else {
        hue = ((rNorm - gNorm) / delta) + 4;
      }

      hue *= 60;
    }

    return [
      double.parse(hue.toStringAsFixed(1)),
      double.parse((saturation * 100).toStringAsFixed(1)),
      double.parse((lightness * 100).toStringAsFixed(1)),
    ];
  }

  /// Convert a single YUV pixel to RGB.
  /// Y: luminance, U (Cb): chrominance blue, V (Cr): chrominance red.
  static List<int> yuvToRgb(int y, int u, int v) {
    // ITU-R BT.601 conversion
    final double yVal = y.toDouble();
    final double uVal = u.toDouble() - 128;
    final double vVal = v.toDouble() - 128;

    int r = (yVal + 1.402 * vVal).round().clamp(0, 255);
    int g = (yVal - 0.344136 * uVal - 0.714136 * vVal).round().clamp(0, 255);
    int b = (yVal + 1.772 * uVal).round().clamp(0, 255);

    return [r, g, b];
  }

  /// Find the nearest named color for given RGB values.
  static String findNearestName(int r, int g, int b) {
    return ColorNames.findNearest(r, g, b);
  }

  /// Extract the average color from a 5x5 pixel area centered on a point
  /// from a CameraImage (YUV420 format).
  ///
  /// Returns [r, g, b] or null if extraction fails.
  static List<int>? extractCenterColor(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;
      final int centerX = width ~/ 2;
      final int centerY = height ~/ 2;

      // Size of sampling area
      const int sampleRadius = 2; // 5x5 area

      final Uint8List yPlane = image.planes[0].bytes;
      final int yRowStride = image.planes[0].bytesPerRow;

      Uint8List uPlane;
      Uint8List vPlane;
      int uvRowStride;
      int uvPixelStride;

      if (image.planes.length >= 3) {
        // YUV420 (Android typically sends YUV_420_888 with 3 planes)
        uPlane = image.planes[1].bytes;
        vPlane = image.planes[2].bytes;
        uvRowStride = image.planes[1].bytesPerRow;
        uvPixelStride = image.planes[1].bytesPerPixel ?? 1;
      } else if (image.planes.length == 2) {
        // Some formats pack UV into a single interleaved plane (NV12/NV21)
        // planes[1] contains interleaved UV data
        final Uint8List uvData = image.planes[1].bytes;
        uvRowStride = image.planes[1].bytesPerRow;
        uvPixelStride = image.planes[1].bytesPerPixel ?? 2;

        // For NV21 (common on Android): V,U,V,U...
        // For NV12 (common on iOS): U,V,U,V...
        // We'll handle both by checking platform format
        uPlane = uvData;
        vPlane = uvData;
      } else {
        return null;
      }

      int totalR = 0, totalG = 0, totalB = 0;
      int count = 0;

      for (int dy = -sampleRadius; dy <= sampleRadius; dy++) {
        for (int dx = -sampleRadius; dx <= sampleRadius; dx++) {
          final int px = centerX + dx;
          final int py = centerY + dy;

          if (px < 0 || px >= width || py < 0 || py >= height) continue;

          final int yIndex = py * yRowStride + px;
          if (yIndex >= yPlane.length) continue;

          final int yVal = yPlane[yIndex];

          final int uvX = px ~/ 2;
          final int uvY = py ~/ 2;

          int uVal, vVal;

          if (image.planes.length >= 3) {
            final int uIndex = uvY * uvRowStride + uvX * uvPixelStride;
            final int vIndex = uvY * uvRowStride + uvX * uvPixelStride;

            if (uIndex >= uPlane.length || vIndex >= vPlane.length) continue;

            uVal = uPlane[uIndex];
            vVal = vPlane[vIndex];
          } else {
            // Interleaved UV plane (NV12 or NV21)
            final int uvIndex = uvY * uvRowStride + uvX * uvPixelStride;
            if (uvIndex + 1 >= uPlane.length) continue;

            // NV12: U first, then V. NV21: V first, then U
            // iOS uses NV12 (kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
            uVal = uPlane[uvIndex];
            vVal = uPlane[uvIndex + 1];
          }

          final rgb = yuvToRgb(yVal, uVal, vVal);
          totalR += rgb[0];
          totalG += rgb[1];
          totalB += rgb[2];
          count++;
        }
      }

      if (count == 0) return null;

      return [totalR ~/ count, totalG ~/ count, totalB ~/ count];
    } catch (e) {
      return null;
    }
  }

  /// Extract color from a BGRA8888 formatted image (iOS).
  static List<int>? extractCenterColorBGRA(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;
      final int centerX = width ~/ 2;
      final int centerY = height ~/ 2;
      const int sampleRadius = 2;

      final Uint8List bytes = image.planes[0].bytes;
      final int bytesPerRow = image.planes[0].bytesPerRow;

      int totalR = 0, totalG = 0, totalB = 0;
      int count = 0;

      for (int dy = -sampleRadius; dy <= sampleRadius; dy++) {
        for (int dx = -sampleRadius; dx <= sampleRadius; dx++) {
          final int px = centerX + dx;
          final int py = centerY + dy;

          if (px < 0 || px >= width || py < 0 || py >= height) continue;

          final int index = py * bytesPerRow + px * 4;
          if (index + 3 >= bytes.length) continue;

          // BGRA format
          totalB += bytes[index];
          totalG += bytes[index + 1];
          totalR += bytes[index + 2];
          count++;
        }
      }

      if (count == 0) return null;

      return [totalR ~/ count, totalG ~/ count, totalB ~/ count];
    } catch (e) {
      return null;
    }
  }
}
