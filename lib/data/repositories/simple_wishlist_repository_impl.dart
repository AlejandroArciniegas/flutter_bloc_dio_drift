import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:euro_explorer/domain/repositories/wishlist_repository.dart';

/// Simple in-memory implementation of WishlistRepository for demonstration
class SimpleWishlistRepositoryImpl implements WishlistRepository {
  final List<WishlistItem> _items = [];

  @override
  Future<List<WishlistItem>> getWishlistItems() async {
    // Sort by added date, newest first
    final sortedItems = List<WishlistItem>.from(_items);
    sortedItems.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return sortedItems;
  }

  @override
  Future<void> addToWishlist(WishlistItem item) async {
    // Check if already exists
    if (!_items.any((existing) => existing.id == item.id)) {
      _items.add(item);
    }
  }

  @override
  Future<void> removeFromWishlist(String countryId) async {
    _items.removeWhere((item) => item.id == countryId);
  }

  @override
  Future<bool> isInWishlist(String countryId) async {
    return _items.any((item) => item.id == countryId);
  }

  @override
  Future<void> clearWishlist() async {
    _items.clear();
  }

  @override
  Future<int> getWishlistCount() async {
    return _items.length;
  }

  @override
  Future<void> addAllStressTest(List<WishlistItem> items) async {
    // For stress testing, we'll simulate adding large amounts of data
    // In a real app, this would be done in an isolate
    await Future.delayed(const Duration(milliseconds: 100));
    _items.addAll(items);
  }
}