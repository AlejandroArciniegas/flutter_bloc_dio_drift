import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WishlistItem', () {
    test('should create wishlist item instance with all properties', () {
      // Arrange
      final addedAt = DateTime(2024, 1, 15);
      final wishlistItem = WishlistItem(
        id: 'spain',
        name: 'Spain',
        flagUrl: 'https://flagcdn.com/es.svg',
        addedAt: addedAt,
      );

      // Assert
      expect(wishlistItem.id, equals('spain'));
      expect(wishlistItem.name, equals('Spain'));
      expect(wishlistItem.flagUrl, equals('https://flagcdn.com/es.svg'));
      expect(wishlistItem.addedAt, equals(addedAt));
    });

    test('should support equality comparison', () {
      // Arrange
      final addedAt = DateTime(2024, 1, 15);
      final wishlistItem1 = WishlistItem(
        id: 'spain',
        name: 'Spain',
        flagUrl: 'https://flagcdn.com/es.svg',
        addedAt: addedAt,
      );

      final wishlistItem2 = WishlistItem(
        id: 'spain',
        name: 'Spain',
        flagUrl: 'https://flagcdn.com/es.svg',
        addedAt: addedAt,
      );

      final wishlistItem3 = WishlistItem(
        id: 'france',
        name: 'France',
        flagUrl: 'https://flagcdn.com/fr.svg',
        addedAt: addedAt,
      );

      // Assert
      expect(wishlistItem1, equals(wishlistItem2));
      expect(wishlistItem1.hashCode, equals(wishlistItem2.hashCode));
      expect(wishlistItem1, isNot(equals(wishlistItem3)));
    });
  });
}
