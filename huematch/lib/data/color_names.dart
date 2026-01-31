import 'dart:ui';
import 'dart:math';

/// Bundled dictionary of ~200 named colors.
/// Includes common web/CSS colors and popular paint names.
class ColorNames {
  ColorNames._();

  static const Map<String, Color> namedColors = {
    // Reds
    'Red': Color(0xFFFF0000),
    'Dark Red': Color(0xFF8B0000),
    'Crimson': Color(0xFFDC143C),
    'Fire Brick': Color(0xFFB22222),
    'Indian Red': Color(0xFFCD5C5C),
    'Light Coral': Color(0xFFF08080),
    'Salmon': Color(0xFFFA8072),
    'Dark Salmon': Color(0xFFE9967A),
    'Light Salmon': Color(0xFFFFA07A),
    'Scarlet': Color(0xFFFF2400),
    'Vermilion': Color(0xFFE34234),
    'Cardinal': Color(0xFFC41E3A),
    'Carmine': Color(0xFF960018),
    'Ruby': Color(0xFFE0115F),
    'Raspberry': Color(0xFFE30B5C),
    'Burgundy': Color(0xFF800020),
    'Maroon': Color(0xFF800000),
    'Wine': Color(0xFF722F37),

    // Pinks
    'Pink': Color(0xFFFFC0CB),
    'Hot Pink': Color(0xFFFF69B4),
    'Deep Pink': Color(0xFFFF1493),
    'Medium Violet Red': Color(0xFFC71585),
    'Pale Violet Red': Color(0xFFDB7093),
    'Light Pink': Color(0xFFFFB6C1),
    'Fuchsia': Color(0xFFFF00FF),
    'Magenta': Color(0xFFFF00FF),
    'Rose': Color(0xFFFF007F),
    'Blush': Color(0xFFDE5D83),
    'Flamingo': Color(0xFFFC8EAC),
    'Coral Pink': Color(0xFFF88379),
    'Cerise': Color(0xFFDE3163),
    'Mauve': Color(0xFFE0B0FF),
    'Orchid': Color(0xFFDA70D6),

    // Oranges
    'Orange': Color(0xFFFFA500),
    'Dark Orange': Color(0xFFFF8C00),
    'Orange Red': Color(0xFFFF4500),
    'Coral': Color(0xFFFF7F50),
    'Tomato': Color(0xFFFF6347),
    'Tangerine': Color(0xFFF28500),
    'Peach': Color(0xFFFFDAB9),
    'Apricot': Color(0xFFFBCEB1),
    'Burnt Orange': Color(0xFFCC5500),
    'Pumpkin': Color(0xFFFF7518),
    'Mango': Color(0xFFFF8243),
    'Papaya': Color(0xFFFF9966),
    'Amber': Color(0xFFFFBF00),
    'Rust': Color(0xFFB7410E),
    'Terra Cotta': Color(0xFFE2725B),

    // Yellows
    'Yellow': Color(0xFFFFFF00),
    'Light Yellow': Color(0xFFFFFFE0),
    'Lemon Chiffon': Color(0xFFFFFACD),
    'Gold': Color(0xFFFFD700),
    'Golden Rod': Color(0xFFDAA520),
    'Dark Golden Rod': Color(0xFFB8860B),
    'Khaki': Color(0xFFF0E68C),
    'Dark Khaki': Color(0xFFBDB76B),
    'Canary': Color(0xFFFFEF00),
    'Lemon': Color(0xFFFFF44F),
    'Mustard': Color(0xFFFFDB58),
    'Saffron': Color(0xFFF4C430),
    'Cream': Color(0xFFFFFDD0),
    'Buttercup': Color(0xFFF9E154),
    'Honey': Color(0xFFEB9605),
    'Banana': Color(0xFFFFE135),
    'Flax': Color(0xFFEEDC82),

    // Greens
    'Green': Color(0xFF008000),
    'Lime': Color(0xFF00FF00),
    'Lime Green': Color(0xFF32CD32),
    'Dark Green': Color(0xFF006400),
    'Forest Green': Color(0xFF228B22),
    'Sea Green': Color(0xFF2E8B57),
    'Medium Sea Green': Color(0xFF3CB371),
    'Light Sea Green': Color(0xFF20B2AA),
    'Spring Green': Color(0xFF00FF7F),
    'Medium Spring Green': Color(0xFF00FA9A),
    'Olive': Color(0xFF808000),
    'Dark Olive Green': Color(0xFF556B2F),
    'Olive Drab': Color(0xFF6B8E23),
    'Yellow Green': Color(0xFF9ACD32),
    'Lawn Green': Color(0xFF7CFC00),
    'Chartreuse': Color(0xFF7FFF00),
    'Green Yellow': Color(0xFFADFF2F),
    'Pale Green': Color(0xFF98FB98),
    'Light Green': Color(0xFF90EE90),
    'Medium Aquamarine': Color(0xFF66CDAA),
    'Emerald': Color(0xFF50C878),
    'Jade': Color(0xFF00A86B),
    'Sage': Color(0xFFBCB88A),
    'Mint': Color(0xFF3EB489),
    'Mint Cream': Color(0xFFF5FFFA),
    'Shamrock': Color(0xFF45CEA2),
    'Pine': Color(0xFF01796F),
    'Fern': Color(0xFF4F7942),
    'Moss': Color(0xFF8A9A5B),
    'Kelly Green': Color(0xFF4CBB17),
    'Hunter Green': Color(0xFF355E3B),

    // Blues
    'Blue': Color(0xFF0000FF),
    'Navy': Color(0xFF000080),
    'Dark Blue': Color(0xFF00008B),
    'Medium Blue': Color(0xFF0000CD),
    'Royal Blue': Color(0xFF4169E1),
    'Cornflower Blue': Color(0xFF6495ED),
    'Steel Blue': Color(0xFF4682B4),
    'Light Steel Blue': Color(0xFFB0C4DE),
    'Dodger Blue': Color(0xFF1E90FF),
    'Deep Sky Blue': Color(0xFF00BFFF),
    'Light Sky Blue': Color(0xFF87CEFA),
    'Sky Blue': Color(0xFF87CEEB),
    'Light Blue': Color(0xFFADD8E6),
    'Powder Blue': Color(0xFFB0E0E6),
    'Cadet Blue': Color(0xFF5F9EA0),
    'Azure': Color(0xFFF0FFFF),
    'Alice Blue': Color(0xFFF0F8FF),
    'Midnight Blue': Color(0xFF191970),
    'Cobalt': Color(0xFF0047AB),
    'Sapphire': Color(0xFF0F52BA),
    'Cerulean': Color(0xFF007BA7),
    'Denim': Color(0xFF1560BD),
    'Indigo': Color(0xFF4B0082),
    'Periwinkle': Color(0xFFCCCCFF),
    'Baby Blue': Color(0xFF89CFF0),
    'Ice Blue': Color(0xFF99C5C4),
    'Oxford Blue': Color(0xFF002147),
    'Electric Blue': Color(0xFF7DF9FF),
    'Prussian Blue': Color(0xFF003153),

    // Cyans / Teals
    'Cyan': Color(0xFF00FFFF),
    'Aqua': Color(0xFF00FFFF),
    'Dark Cyan': Color(0xFF008B8B),
    'Teal': Color(0xFF008080),
    'Dark Turquoise': Color(0xFF00CED1),
    'Turquoise': Color(0xFF40E0D0),
    'Medium Turquoise': Color(0xFF48D1CC),
    'Pale Turquoise': Color(0xFFAFEEEE),
    'Aquamarine': Color(0xFF7FFFD4),

    // Purples / Violets
    'Purple': Color(0xFF800080),
    'Dark Magenta': Color(0xFF8B008B),
    'Dark Violet': Color(0xFF9400D3),
    'Dark Orchid': Color(0xFF9932CC),
    'Medium Orchid': Color(0xFFBA55D3),
    'Plum': Color(0xFFDDA0DD),
    'Violet': Color(0xFFEE82EE),
    'Thistle': Color(0xFFD8BFD8),
    'Lavender': Color(0xFFE6E6FA),
    'Medium Purple': Color(0xFF9370DB),
    'Blue Violet': Color(0xFF8A2BE2),
    'Slate Blue': Color(0xFF6A5ACD),
    'Medium Slate Blue': Color(0xFF7B68EE),
    'Dark Slate Blue': Color(0xFF483D8B),
    'Rebecca Purple': Color(0xFF663399),
    'Amethyst': Color(0xFF9966CC),
    'Lilac': Color(0xFFC8A2C8),
    'Wisteria': Color(0xFFC9A0DC),
    'Grape': Color(0xFF6F2DA8),
    'Eggplant': Color(0xFF614051),
    'Mulberry': Color(0xFFC54B8C),
    'Heather': Color(0xFFB7C3D0),

    // Browns
    'Brown': Color(0xFFA52A2A),
    'Saddle Brown': Color(0xFF8B4513),
    'Sienna': Color(0xFFA0522D),
    'Chocolate': Color(0xFFD2691E),
    'Peru': Color(0xFFCD853F),
    'Sandy Brown': Color(0xFFF4A460),
    'Burly Wood': Color(0xFFDEB887),
    'Tan': Color(0xFFD2B48C),
    'Rosy Brown': Color(0xFFBC8F8F),
    'Wheat': Color(0xFFF5DEB3),
    'Navajo White': Color(0xFFFFDEAD),
    'Bisque': Color(0xFFFFE4C4),
    'Blanched Almond': Color(0xFFFFEBCD),
    'Cornsilk': Color(0xFFFFF8DC),
    'Mahogany': Color(0xFFC04000),
    'Chestnut': Color(0xFF954535),
    'Cinnamon': Color(0xFFD2691E),
    'Copper': Color(0xFFB87333),
    'Bronze': Color(0xFFCD7F32),
    'Coffee': Color(0xFF6F4E37),
    'Mocha': Color(0xFF967117),
    'Taupe': Color(0xFF483C32),
    'Umber': Color(0xFF635147),
    'Sepia': Color(0xFF704214),
    'Caramel': Color(0xFFFFD59A),
    'Beige': Color(0xFFF5F5DC),

    // Whites
    'White': Color(0xFFFFFFFF),
    'Snow': Color(0xFFFFFAFA),
    'Honeydew': Color(0xFFF0FFF0),
    'Ghost White': Color(0xFFF8F8FF),
    'White Smoke': Color(0xFFF5F5F5),
    'Seashell': Color(0xFFFFF5EE),
    'Old Lace': Color(0xFFFDF5E6),
    'Floral White': Color(0xFFFFFAF0),
    'Ivory': Color(0xFFFFFFF0),
    'Antique White': Color(0xFFFAEBD7),
    'Linen': Color(0xFFFAF0E6),
    'Lavender Blush': Color(0xFFFFF0F5),
    'Misty Rose': Color(0xFFFFE4E1),
    'Pearl': Color(0xFFEAE0C8),
    'Vanilla': Color(0xFFF3E5AB),

    // Grays
    'Black': Color(0xFF000000),
    'Dark Slate Gray': Color(0xFF2F4F4F),
    'Dim Gray': Color(0xFF696969),
    'Slate Gray': Color(0xFF708090),
    'Light Slate Gray': Color(0xFF778899),
    'Gray': Color(0xFF808080),
    'Dark Gray': Color(0xFFA9A9A9),
    'Silver': Color(0xFFC0C0C0),
    'Light Gray': Color(0xFFD3D3D3),
    'Gainsboro': Color(0xFFDCDCDC),
    'Charcoal': Color(0xFF36454F),
    'Ash': Color(0xFFB2BEB5),
    'Gunmetal': Color(0xFF2A3439),
    'Pewter': Color(0xFF96A8A1),
    'Platinum': Color(0xFFE5E4E2),
    'Smoke': Color(0xFF738276),
    'Onyx': Color(0xFF353839),
    'Jet': Color(0xFF343434),
    'Steel': Color(0xFF71797E),
    'Iron': Color(0xFF48494B),
  };

  /// Find the nearest named color to the given RGB values
  /// using Euclidean distance in RGB space.
  static String findNearest(int r, int g, int b) {
    String nearest = 'Unknown';
    double minDistance = double.infinity;

    for (final entry in namedColors.entries) {
      final c = entry.value;
      final dr = r - ((c.r * 255.0).round() & 0xff);
      final dg = g - ((c.g * 255.0).round() & 0xff);
      final db = b - ((c.b * 255.0).round() & 0xff);
      final distance = sqrt(dr * dr + dg * dg + db * db);

      if (distance < minDistance) {
        minDistance = distance;
        nearest = entry.key;
      }
    }

    return nearest;
  }

  /// Get the Color object for a named color, or null if not found.
  static Color? getColor(String name) {
    return namedColors[name];
  }
}
