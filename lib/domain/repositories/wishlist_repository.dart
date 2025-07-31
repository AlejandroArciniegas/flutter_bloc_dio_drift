import 'package:euro_explorer/domain/entities/wishlist_item.dart';

/// Repository interface for wishlist operations
abstract class WishlistRepository {
  /// Get all wishlist items
  Future<List<WishlistItem>> getWishlistItems();

  /// Add item to wishlist
  Future<void> addToWishlist(WishlistItem item);

  /// Remove item from wishlist
  Future<void> removeFromWishlist(String countryId);

  /// Check if country is in wishlist
  Future<bool> isInWishlist(String countryId);

  /// Clear all wishlist items
  Future<void> clearWishlist();

  /// Get wishlist count
  Future<int> getWishlistCount();

  /// Performance test: Add multiple items efficiently
  Future<void> addAllStressTest(List<WishlistItem> items);
}