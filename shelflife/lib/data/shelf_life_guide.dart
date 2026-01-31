import 'package:flutter/material.dart';

class ShelfLifeGuide {
  static const Map<String, Map<String, int>> guide = {
    'Dairy': {
      'Milk': 7,
      'Yogurt': 10,
      'Cream cheese': 14,
      'Sour cream': 14,
      'Butter': 30,
      'Heavy cream': 10,
      'Cottage cheese': 7,
      'Shredded cheese': 21,
    },
    'Condiments': {
      'Ketchup': 180,
      'Mustard': 365,
      'Mayo': 60,
      'Salsa': 14,
      'Soy sauce': 180,
      'Hot sauce': 180,
      'Ranch dressing': 60,
      'BBQ sauce': 120,
      'Worcestershire sauce': 365,
    },
    'Proteins': {
      'Deli meat': 5,
      'Cooked chicken': 4,
      'Cooked fish': 3,
      'Eggs': 35,
      'Hummus': 7,
      'Tofu': 5,
      'Cooked ground beef': 4,
    },
    'Produce': {
      'Cut fruit': 4,
      'Leafy greens': 5,
      'Avocado': 3,
      'Berries': 5,
      'Cut vegetables': 5,
      'Fresh herbs': 7,
    },
    'Beverages': {
      'Orange juice': 7,
      'Red wine': 5,
      'White wine': 3,
      'Opened soda': 3,
      'Almond milk': 10,
      'Coconut water': 3,
    },
    'Pantry': {
      'Bread': 7,
      'Peanut butter': 90,
      'Jam': 30,
      'Cooked rice': 5,
      'Pasta sauce': 10,
      'Canned beans': 5,
      'Maple syrup': 365,
      'Tortillas': 14,
    },
    'Personal Care': {
      'Mascara': 90,
      'Foundation': 180,
      'Sunscreen': 180,
      'Eye drops': 30,
      'Contact solution': 90,
      'Lip gloss': 180,
    },
  };

  static List<String> get categories => guide.keys.toList();

  static Map<String, int> getItemsForCategory(String category) {
    return guide[category] ?? {};
  }

  static int? getShelfLife(String category, String itemName) {
    return guide[category]?[itemName];
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Dairy':
        return Icons.local_drink;
      case 'Condiments':
        return Icons.kitchen;
      case 'Proteins':
        return Icons.egg;
      case 'Produce':
        return Icons.eco;
      case 'Beverages':
        return Icons.local_cafe;
      case 'Pantry':
        return Icons.shelves;
      case 'Personal Care':
        return Icons.face;
      default:
        return Icons.inventory_2;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Dairy':
        return Colors.blue.shade300;
      case 'Condiments':
        return Colors.orange.shade300;
      case 'Proteins':
        return Colors.red.shade300;
      case 'Produce':
        return Colors.green.shade300;
      case 'Beverages':
        return Colors.purple.shade300;
      case 'Pantry':
        return Colors.brown.shade300;
      case 'Personal Care':
        return Colors.pink.shade300;
      default:
        return Colors.grey.shade300;
    }
  }
}
