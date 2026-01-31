import 'dart:ui';

class PaletteData {
  final String name;
  final List<Color> colors;

  const PaletteData({required this.name, required this.colors});
}

final List<PaletteData> palettes = [
  PaletteData(
    name: 'Retro Gaming',
    colors: [
      const Color(0xFF000000), // black
      const Color(0xFFFFFFFF), // white
      const Color(0xFFFF0000), // red
      const Color(0xFF00AA00), // green
      const Color(0xFF0000FF), // blue
      const Color(0xFFFFFF00), // yellow
      const Color(0xFF00FFFF), // cyan
      const Color(0xFFFF00FF), // magenta
      const Color(0xFFFF8800), // orange
      const Color(0xFF884400), // brown
      const Color(0xFF005500), // dark green
      const Color(0xFF000088), // navy
      const Color(0xFF888888), // gray
      const Color(0xFFCCCCCC), // light gray
      const Color(0xFFFF88AA), // pink
      const Color(0xFF9C27B0), // purple
    ],
  ),
  PaletteData(
    name: 'Pastel',
    colors: [
      const Color(0xFFFFB6C1), // soft pink
      const Color(0xFFE6E6FA), // lavender
      const Color(0xFF98FB98), // mint
      const Color(0xFFFFDAB9), // peach
      const Color(0xFF87CEEB), // sky blue
      const Color(0xFFFFFDD0), // cream
      const Color(0xFFC8A2C8), // lilac
      const Color(0xFFFF7F7F), // coral
      const Color(0xFFBCB88A), // sage
      const Color(0xFFFFFFC2), // butter
      const Color(0xFFDCAE96), // dusty rose
      const Color(0xFFCCCCFF), // periwinkle
      const Color(0xFF93E9BE), // seafoam
      const Color(0xFFDE5D83), // blush
      const Color(0xFFE0B0FF), // mauve
      const Color(0xFFFFFFF0), // ivory
    ],
  ),
  PaletteData(
    name: 'Earth Tones',
    colors: [
      const Color(0xFFE2725B), // terra cotta
      const Color(0xFF808000), // olive
      const Color(0xFFA0522D), // sienna
      const Color(0xFF8A9A5B), // moss
      const Color(0xFFB66A50), // clay
      const Color(0xFF5C4033), // bark
      const Color(0xFFC2B280), // sand
      const Color(0xFF9CAF88), // sage
      const Color(0xFFB7410E), // rust
      const Color(0xFFC3B091), // khaki
      const Color(0xFF5C5248), // walnut
      const Color(0xFF4F7942), // fern
      const Color(0xFFFFBF00), // amber
      const Color(0xFF928E85), // stone
      const Color(0xFF6F4E37), // coffee
      const Color(0xFFF5DEB3), // wheat
    ],
  ),
  PaletteData(
    name: 'Monochrome',
    colors: List.generate(16, (i) {
      final value = (i * 255 / 15).round();
      return Color.fromARGB(255, value, value, value);
    }),
  ),
];
