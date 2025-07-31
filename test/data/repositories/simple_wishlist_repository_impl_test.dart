import 'package:euro_explorer/data/repositories/simple_wishlist_repository_impl.dart';
import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SimpleWishlistRepositoryImpl repository;

  setUp(() {
    repository = SimpleWishlistRepositoryImpl();
  });

  group('SimpleWishlistRepositoryImpl', () {
    group('addToWishlist', () {
      test('should add item to wishlist', () async {
        // Arrange
        final item = WishlistItem(
          id: 'spain',
          name: 'Spain',
          flagUrl: 'https://flagcdn.com/es.svg',
          addedAt: DateTime(2024, 1, 15),
        );

        // Act
        await repository.addToWishlist(item);

        // Assert
        final items = await repository.getWishlistItems();
        expect(items, contains(item));
        expect(items.length, equals(1));
      });

      test('should not add duplicate items', () async {
        // Arrange
        final item = WishlistItem(
          id: 'spain',
          name: 'Spain',
          flagUrl: 'https://flagcdn.com/es.svg',
          addedAt: DateTime(2024, 1, 15),
        );

        // Act
        await repository.addToWishlist(item);
        await repository.addToWishlist(item);

        // Assert
        final items = await repository.getWishlistItems();
        expect(items.length, equals(1));
      });
    });

    group('removeFromWishlist', () {
      test('should remove item from wishlist', () async {
        // Arrange
        final item = WishlistItem(
          id: 'spain',
          name: 'Spain',
          flagUrl: 'https://flagcdn.com/es.svg',
          addedAt: DateTime(2024, 1, 15),
        );

        await repository.addToWishlist(item);

        // Act
        await repository.removeFromWishlist('spain');

        // Assert
        final items = await repository.getWishlistItems();
        expect(items, isEmpty);
      });

      test('should not throw when removing non-existent item', () async {
        // Act & Assert
        expect(
          () => repository.removeFromWishlist('nonexistent'),
          returnsNormally,
        );
      });
    });

    group('isInWishlist', () {
      test('should return true when item is in wishlist', () async {
        // Arrange
        final item = WishlistItem(
          id: 'spain',
          name: 'Spain',
          flagUrl: 'https://flagcdn.com/es.svg',
          addedAt: DateTime(2024, 1, 15),
        );

        await repository.addToWishlist(item);

        // Act
        final result = await repository.isInWishlist('spain');

        // Assert
        expect(result, isTrue);
      });

      test('should return false when item is not in wishlist', () async {
        // Act
        final result = await repository.isInWishlist('spain');

        // Assert
        expect(result, isFalse);
      });
    });

    group('getWishlistItems', () {
      test('should return items sorted by added date descending', () async {
        // Arrange
        final item1 = WishlistItem(
          id: 'spain',
          name: 'Spain',
          flagUrl: 'https://flagcdn.com/es.svg',
          addedAt: DateTime(2024, 1, 15),
        );

        final item2 = WishlistItem(
          id: 'france',
          name: 'France',
          flagUrl: 'https://flagcdn.com/fr.svg',
          addedAt: DateTime(2024, 1, 16),
        );

        final item3 = WishlistItem(
          id: 'italy',
          name: 'Italy',
          flagUrl: 'https://flagcdn.com/it.svg',
          addedAt: DateTime(2024, 1, 14),
        );

        await repository.addToWishlist(item1);
        await repository.addToWishlist(item2);
        await repository.addToWishlist(item3);

        // Act
        final items = await repository.getWishlistItems();

        // Assert
        expect(items.length, equals(3));
        expect(items[0], equals(item2)); // Most recent
        expect(items[1], equals(item1));
        expect(items[2], equals(item3)); // Oldest
      });

      test('should return empty list when no items', () async {
        // Act
        final items = await repository.getWishlistItems();

        // Assert
        expect(items, isEmpty);
      });
    });

    group('clearWishlist', () {
      test('should remove all items from wishlist', () async {
        // Arrange
        final item1 = WishlistItem(
          id: 'spain',
          name: 'Spain',
          flagUrl: 'https://flagcdn.com/es.svg',
          addedAt: DateTime(2024, 1, 15),
        );

        final item2 = WishlistItem(
          id: 'france',
          name: 'France',
          flagUrl: 'https://flagcdn.com/fr.svg',
          addedAt: DateTime(2024, 1, 16),
        );

        await repository.addToWishlist(item1);
        await repository.addToWishlist(item2);

        // Act
        await repository.clearWishlist();

        // Assert
        final items = await repository.getWishlistItems();
        expect(items, isEmpty);
      });
    });

    group('getWishlistCount', () {
      test('should return correct count of items', () async {
        // Arrange
        final item1 = WishlistItem(
          id: 'spain',
          name: 'Spain',
          flagUrl: 'https://flagcdn.com/es.svg',
          addedAt: DateTime(2024, 1, 15),
        );

        final item2 = WishlistItem(
          id: 'france',
          name: 'France',
          flagUrl: 'https://flagcdn.com/fr.svg',
          addedAt: DateTime(2024, 1, 16),
        );

        await repository.addToWishlist(item1);
        await repository.addToWishlist(item2);

        // Act
        final count = await repository.getWishlistCount();

        // Assert
        expect(count, equals(2));
      });

      test('should return zero when no items', () async {
        // Act
        final count = await repository.getWishlistCount();

        // Assert
        expect(count, equals(0));
      });
    });

    group('addAllStressTest', () {
      test('should add all items from the list', () async {
        // Arrange
        final items = List.generate(
          1000,
          (index) => WishlistItem(
            id: 'test_$index',
            name: 'Test Country $index',
            flagUrl: 'https://example.com/flag$index.png',
            addedAt: DateTime.now().subtract(Duration(seconds: index)),
          ),
        );

        // Act
        await repository.addAllStressTest(items);

        // Assert
        final wishlistItems = await repository.getWishlistItems();
        expect(wishlistItems.length, equals(1000));
        expect(wishlistItems, containsAll(items));
      });

      test('should handle large datasets efficiently', () async {
        // Arrange
        final items = List.generate(
          5000,
          (index) => WishlistItem(
            id: 'stress_test_$index',
            name: 'Stress Test Country $index',
            flagUrl: 'https://example.com/flag$index.png',
            addedAt: DateTime.now().subtract(Duration(seconds: index)),
          ),
        );

        // Act
        final stopwatch = Stopwatch()..start();
        await repository.addAllStressTest(items);
        stopwatch.stop();

        // Assert
        final wishlistItems = await repository.getWishlistItems();
        expect(wishlistItems.length, equals(5000));
        // Should complete within a reasonable time (less than 1 second for in-memory)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
  });
}
