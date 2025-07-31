import 'dart:isolate';

import 'package:euro_explorer/domain/entities/wishlist_item.dart' as domain;
import 'package:euro_explorer/domain/repositories/wishlist_repository.dart';
import 'package:euro_explorer/data/datasources/local/app_database.dart';

/// Implementation of WishlistRepository
class WishlistRepositoryImpl implements WishlistRepository {
  const WishlistRepositoryImpl({
    required AppDatabase database,
  }) : _database = database;

  final AppDatabase _database;

  @override
  Future<List<domain.WishlistItem>> getWishlistItems() async {
    try {
      return await _database.getAllWishlistItems();
    } catch (e) {
      throw WishlistRepositoryException('Failed to get wishlist items: $e');
    }
  }

  @override
  Future<void> addToWishlist(domain.WishlistItem item) async {
    try {
      await _database.addToWishlist(item);
    } catch (e) {
      throw WishlistRepositoryException('Failed to add item to wishlist: $e');
    }
  }

  @override
  Future<void> removeFromWishlist(String countryId) async {
    try {
      await _database.removeFromWishlist(countryId);
    } catch (e) {
      throw WishlistRepositoryException('Failed to remove item from wishlist: $e');
    }
  }

  @override
  Future<bool> isInWishlist(String countryId) async {
    try {
      return await _database.isInWishlist(countryId);
    } catch (e) {
      throw WishlistRepositoryException('Failed to check wishlist status: $e');
    }
  }

  @override
  Future<void> clearWishlist() async {
    try {
      await _database.clearWishlist();
    } catch (e) {
      throw WishlistRepositoryException('Failed to clear wishlist: $e');
    }
  }

  @override
  Future<int> getWishlistCount() async {
    try {
      return await _database.getWishlistCount();
    } catch (e) {
      throw WishlistRepositoryException('Failed to get wishlist count: $e');
    }
  }

  @override
  Future<void> addAllStressTest(List<domain.WishlistItem> items) async {
    try {
      // Use isolate to prevent UI blocking for large batch operations
      if (items.length > 1000) {
        await _performBatchInsertInIsolate(items);
      } else {
        await _database.batchInsertWishlistItems(items);
      }
    } catch (e) {
      throw WishlistRepositoryException('Failed to perform stress test: $e');
    }
  }

  /// Perform batch insert in isolate for large datasets
  Future<void> _performBatchInsertInIsolate(List<domain.WishlistItem> items) async {
    final receivePort = ReceivePort();
    
    // Create data for isolate
    final isolateData = IsolateData(
      items: items,
      sendPort: receivePort.sendPort,
    );

    // Spawn isolate
    await Isolate.spawn(_batchInsertIsolate, isolateData);

    // Wait for completion
    await receivePort.first;
  }

  /// Isolate entry point for batch insert
  static Future<void> _batchInsertIsolate(IsolateData data) async {
    try {
      // Create new database connection in isolate
      final database = AppDatabase();
      
      // Perform batch insert in chunks to avoid memory issues
      const chunkSize = 500;
      for (var i = 0; i < data.items.length; i += chunkSize) {
        final chunk = data.items.skip(i).take(chunkSize).toList();
        await database.batchInsertWishlistItems(chunk);
      }

      await database.close();
      data.sendPort.send('completed');
    } catch (e) {
      data.sendPort.send('error: $e');
    }
  }
}

/// Data class for isolate communication
class IsolateData {
  const IsolateData({
    required this.items,
    required this.sendPort,
  });

  final List<domain.WishlistItem> items;
  final SendPort sendPort;
}

/// Custom exception for wishlist repository
class WishlistRepositoryException implements Exception {
  const WishlistRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'WishlistRepositoryException: $message';
}