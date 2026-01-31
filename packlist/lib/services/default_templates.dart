import '../models/pack_item.dart';
import '../models/template.dart';

class DefaultTemplates {
  static List<Template> get all => [
        weekendGetaway,
        beachVacation,
        businessTrip,
        camping,
      ];

  static Template get weekendGetaway => Template(
        name: 'Weekend Getaway',
        iconName: 'weekend',
        isDefault: true,
        items: _buildItems({
          'Essentials': ['Phone charger', 'Wallet', 'Keys'],
          'Clothing': ['Change of clothes'],
          'Toiletries': ['Toiletry bag'],
          'Electronics': ['Headphones'],
          'Other': ['Snacks', 'Water bottle', 'Book'],
        }),
      );

  static Template get beachVacation => Template(
        name: 'Beach Vacation',
        iconName: 'beach_access',
        isDefault: true,
        items: _buildItems({
          'Essentials': ['Sunglasses', 'Hat', 'Water bottle'],
          'Clothing': ['Swimsuit', 'Sandals', 'Change of clothes'],
          'Toiletries': ['Sunscreen', 'Towel'],
          'Electronics': ['Phone charger'],
          'Other': ['Beach bag', 'Book'],
        }),
      );

  static Template get businessTrip => Template(
        name: 'Business Trip',
        iconName: 'business_center',
        isDefault: true,
        items: _buildItems({
          'Essentials': ['Wallet', 'Business cards'],
          'Clothing': ['Suit/Blazer', 'Dress shoes'],
          'Toiletries': ['Toiletry kit'],
          'Electronics': ['Laptop', 'Charger', 'Phone charger'],
          'Documents': ['ID/Passport', 'Notebook', 'Pen'],
        }),
      );

  static Template get camping => Template(
        name: 'Camping',
        iconName: 'forest',
        isDefault: true,
        items: _buildItems({
          'Essentials': ['Water bottle', 'First aid kit', 'Lighter', 'Knife'],
          'Clothing': ['Extra socks'],
          'Toiletries': ['Sunscreen', 'Insect repellent'],
          'Electronics': ['Flashlight'],
          'Other': ['Tent', 'Sleeping bag', 'Food/Snacks'],
        }),
      );

  static List<PackItem> _buildItems(Map<String, List<String>> categoryItems) {
    final items = <PackItem>[];
    int sortOrder = 0;
    for (final entry in categoryItems.entries) {
      for (final name in entry.value) {
        items.add(PackItem(
          name: name,
          category: entry.key,
          sortOrder: sortOrder++,
        ));
      }
    }
    return items;
  }
}
