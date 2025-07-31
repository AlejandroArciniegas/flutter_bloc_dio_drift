import 'package:euro_explorer/domain/entities/wishlist_item.dart';

/// Wishlist change event types
enum WishlistChangeType { added, removed, cleared }

/// Wishlist change notification
class WishlistChangeEvent {
  const WishlistChangeEvent({
    required this.type,
    required this.countryId,
  });

  final WishlistChangeType type;
  final String countryId;
}

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

  /// Batch check wishlist status for multiple countries (optimized)
  Future<Map<String, bool>> batchCheckWishlistStatus(List<String> countryIds);

  /// Stream of wishlist changes for real-time updates
  Stream<WishlistChangeEvent> get wishlistChanges;
}
