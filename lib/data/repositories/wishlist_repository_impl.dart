import 'dart:async';

import 'package:euro_explorer/data/datasources/local/app_database.dart';
import 'package:euro_explorer/data/isolates/data_processing_isolates.dart';
import 'package:euro_explorer/domain/entities/wishlist_item.dart' as domain;
import 'package:euro_explorer/domain/repositories/wishlist_repository.dart';


/// Implementation of WishlistRepository
class WishlistRepositoryImpl implements WishlistRepository {
  WishlistRepositoryImpl({
    required AppDatabase database,
  }) : _database = database;

  final AppDatabase _database;
  final StreamController<WishlistChangeEvent> _changeController = 
      StreamController<WishlistChangeEvent>.broadcast();

  @override
  Stream<WishlistChangeEvent> get wishlistChanges => _changeController.stream;

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
      _changeController.add(WishlistChangeEvent(
        type: WishlistChangeType.added,
        countryId: item.id,
      ),);
    } catch (e) {
      throw WishlistRepositoryException('Failed to add item to wishlist: $e');
    }
  }

  @override
  Future<void> removeFromWishlist(String countryId) async {
    try {
      await _database.removeFromWishlist(countryId);
      _changeController.add(WishlistChangeEvent(
        type: WishlistChangeType.removed,
        countryId: countryId,
      ),);
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
      _changeController.add(const WishlistChangeEvent(
        type: WishlistChangeType.cleared,
        countryId: '',
      ),);
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
  Future<Map<String, bool>> batchCheckWishlistStatus(List<String> countryIds) async {
    try {
      // Use optimized batch checking for large lists
      return DataProcessingIsolates.optimizedBatchCheck(
        countryIds,
        _database.batchCheckWishlistStatus,
      );
    } catch (e) {
      throw WishlistRepositoryException('Failed to batch check wishlist status: $e');
    }
  }

  @override
  Future<void> addAllStressTest(List<domain.WishlistItem> items) async {
    try {
      // Use optimized chunked processing for all operations
      await _performBatchInsertInIsolate(items);
      
      // Emit a single batch event to notify all listeners
      // This is more efficient than individual events for each item
      _changeController.add(const WishlistChangeEvent(
        type: WishlistChangeType.added,
        countryId: '*BATCH*', // Special marker for batch operations
      ),);
    } catch (e) {
      throw WishlistRepositoryException('Failed to perform stress test: $e');
    }
  }

  /// Optimized batch insert using isolate-prepared chunking with reduced delays
  Future<void> _performBatchInsertInIsolate(List<domain.WishlistItem> items) async {
    // Use optimized chunking from isolate utility
    final chunks = await DataProcessingIsolates.chunkDataForBatchProcessing(
      items,
      chunkSize: ProcessingConfig.optimized.batchChunkSize,
    );
    
    // Process chunks with optimized delays
    for (var i = 0; i < chunks.length; i++) {
      await _database.batchInsertWishlistItems(chunks[i]);
      
      // Reduced delay for better performance
      if (i < chunks.length - 1) {
        await Future<void>.delayed(ProcessingConfig.optimized.delayBetweenChunks);
      }
    }
  }
}



/// Custom exception for wishlist repository
class WishlistRepositoryException implements Exception {
  const WishlistRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'WishlistRepositoryException: $message';
}

/// Dispose method for cleanup
extension WishlistRepositoryImplDispose on WishlistRepositoryImpl {
  void dispose() {
    _changeController.close();
  }
}
