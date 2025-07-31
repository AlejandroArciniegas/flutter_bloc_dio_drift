import 'dart:async';

import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:euro_explorer/domain/repositories/wishlist_repository.dart';

/// Simple in-memory implementation of WishlistRepository for demonstration
class SimpleWishlistRepositoryImpl implements WishlistRepository {
  final List<WishlistItem> _items = [];
  final StreamController<WishlistChangeEvent> _changeController = 
      StreamController<WishlistChangeEvent>.broadcast();

  @override
  Stream<WishlistChangeEvent> get wishlistChanges => _changeController.stream;

  @override
  Future<List<WishlistItem>> getWishlistItems() async {
    // Sort by added date, newest first
    return List<WishlistItem>.from(_items)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  @override
  Future<void> addToWishlist(WishlistItem item) async {
    // Check if already exists
    if (!_items.any((existing) => existing.id == item.id)) {
      _items.add(item);
      _changeController.add(WishlistChangeEvent(
        type: WishlistChangeType.added,
        countryId: item.id,
      ),);
    }
  }

  @override
  Future<void> removeFromWishlist(String countryId) async {
    final initialLength = _items.length;
    _items.removeWhere((item) => item.id == countryId);
    final wasRemoved = _items.length < initialLength;
    
    if (wasRemoved) {
      _changeController.add(WishlistChangeEvent(
        type: WishlistChangeType.removed,
        countryId: countryId,
      ),);
    }
  }

  @override
  Future<bool> isInWishlist(String countryId) async {
    return _items.any((item) => item.id == countryId);
  }

  @override
  Future<void> clearWishlist() async {
    if (_items.isNotEmpty) {
      _items.clear();
      _changeController.add(const WishlistChangeEvent(
        type: WishlistChangeType.cleared,
        countryId: '',
      ),);
    }
  }

  @override
  Future<int> getWishlistCount() async {
    return _items.length;
  }

  @override
  Future<void> addAllStressTest(List<WishlistItem> items) async {
    // For stress testing, we'll simulate adding large amounts of data
    // In a real app, this would be done in an isolate
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _items.addAll(items);
  }

  @override
  Future<Map<String, bool>> batchCheckWishlistStatus(List<String> countryIds) async {
    final statusMap = <String, bool>{};
    for (final id in countryIds) {
      statusMap[id] = _items.any((item) => item.id == id);
    }
    return statusMap;
  }

  /// Dispose method for cleanup
  void dispose() {
    _changeController.close();
  }
}
