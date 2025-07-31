import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:euro_explorer/domain/repositories/wishlist_repository.dart';

/// Use case for getting wishlist items
class GetWishlistItems {
  const GetWishlistItems({
    required WishlistRepository repository,
  }) : _repository = repository;

  final WishlistRepository _repository;

  /// Execute the use case
  Future<List<WishlistItem>> call() async {
    return _repository.getWishlistItems();
  }
}

/// Use case for adding item to wishlist
class AddToWishlist {
  const AddToWishlist({
    required WishlistRepository repository,
  }) : _repository = repository;

  final WishlistRepository _repository;

  /// Execute the use case
  Future<void> call(WishlistItem item) async {
    // Check if item is already in wishlist
    final isAlreadyInWishlist = await _repository.isInWishlist(item.id);
    if (isAlreadyInWishlist) {
      throw const WishlistException('Item is already in wishlist');
    }

    await _repository.addToWishlist(item);
  }
}

/// Use case for removing item from wishlist
class RemoveFromWishlist {
  const RemoveFromWishlist({
    required WishlistRepository repository,
  }) : _repository = repository;

  final WishlistRepository _repository;

  /// Execute the use case
  Future<void> call(String countryId) async {
    if (countryId.isEmpty) {
      throw ArgumentError('Country ID cannot be empty');
    }

    await _repository.removeFromWishlist(countryId);
  }
}

/// Use case for checking if item is in wishlist
class IsInWishlist {
  const IsInWishlist({
    required WishlistRepository repository,
  }) : _repository = repository;

  final WishlistRepository _repository;

  /// Execute the use case
  Future<bool> call(String countryId) async {
    if (countryId.isEmpty) {
      return false;
    }

    return _repository.isInWishlist(countryId);
  }
}

/// Use case for performing stress test
class PerformWishlistStressTest {
  const PerformWishlistStressTest({
    required WishlistRepository repository,
  }) : _repository = repository;

  final WishlistRepository _repository;

  /// Execute the use case - generate and insert 5000 fake entries
  Future<void> call() async {
    // Generate 5000 fake entries
    final fakeItems = List.generate(5000, (index) {
      return WishlistItem(
        id: 'stress_test_$index',
        name: 'Test Country $index',
        flagUrl: 'https://example.com/flag$index.png',
        addedAt: DateTime.now().subtract(Duration(seconds: index)),
      );
    });

    await _repository.addAllStressTest(fakeItems);
  }
}

/// Custom exception for wishlist operations
class WishlistException implements Exception {
  const WishlistException(this.message);

  final String message;

  @override
  String toString() => 'WishlistException: $message';
}