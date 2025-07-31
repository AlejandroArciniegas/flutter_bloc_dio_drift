import 'dart:async';
import 'dart:collection';

import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:flutter/foundation.dart';

/// Advanced database operations using isolates for heavy processing
class DatabaseIsolates {
  /// Process large batch operations in parallel chunks
  static Future<void> processBatchOperationsInParallel<T>(
    List<T> items,
    Future<void> Function(List<T>) batchProcessor, {
    int maxConcurrency = 3,
    int chunkSize = 200,
  }) async {
    if (items.isEmpty) return;

    // Create chunks
    final chunks = <List<T>>[];
    for (var i = 0; i < items.length; i += chunkSize) {
      chunks.add(items.skip(i).take(chunkSize).toList());
    }

    // Process chunks in parallel with limited concurrency
    final semaphore = Semaphore(maxConcurrency);
    final futures = chunks.map((chunk) async {
      await semaphore.acquire();
      try {
        await batchProcessor(chunk);
      } finally {
        semaphore.release();
      }
    });

    await Future.wait(futures);
  }

  /// Optimized data validation in isolate
  static Future<List<WishlistItem>> validateWishlistItems(
    List<WishlistItem> items,
  ) async {
    if (items.length < 50) {
      return _validateItemsSync(items);
    }

    return compute(_validateWishlistItemsIsolate, items);
  }

  /// Prepare data for batch operations in isolate
  static Future<List<Map<String, dynamic>>> prepareBatchData(
    List<WishlistItem> items,
  ) async {
    if (items.length < 30) {
      return _prepareBatchDataSync(items);
    }

    return compute(_prepareBatchDataIsolate, items);
  }
}

/// Isolate function for validating wishlist items
List<WishlistItem> _validateWishlistItemsIsolate(List<WishlistItem> items) {
  return _validateItemsSync(items);
}

/// Synchronous validation helper
List<WishlistItem> _validateItemsSync(List<WishlistItem> items) {
  return items.where((item) {
    return item.id.isNotEmpty &&
        item.name.isNotEmpty &&
        item.flagUrl.isNotEmpty;
  }).toList();
}

/// Isolate function for preparing batch data
List<Map<String, dynamic>> _prepareBatchDataIsolate(List<WishlistItem> items) {
  return _prepareBatchDataSync(items);
}

/// Synchronous batch data preparation
List<Map<String, dynamic>> _prepareBatchDataSync(List<WishlistItem> items) {
  return items
      .map(
        (item) => {
          'id': item.id,
          'name': item.name,
          'flag_url': item.flagUrl,
          'added_at': item.addedAt.millisecondsSinceEpoch,
        },
      )
      .toList();
}

/// Simple semaphore implementation for controlling concurrency
class Semaphore {
  Semaphore(int maxCount) : _currentCount = maxCount;

  int _currentCount;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      _waitQueue.removeFirst().complete();
    } else {
      _currentCount++;
    }
  }
}
