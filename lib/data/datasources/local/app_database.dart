import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:euro_explorer/data/models/wishlist_item_dto.dart';
import 'package:euro_explorer/domain/entities/wishlist_item.dart'
    as domain;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'app_database.g.dart';

/// Main application database using Drift
@DriftDatabase(tables: [WishlistItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing with in-memory database
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  /// Get all wishlist items
  Future<List<domain.WishlistItem>> getAllWishlistItems() async {
    final query = select(wishlistItems)..orderBy([
      (t) => OrderingTerm(expression: t.addedAt, mode: OrderingMode.desc),
    ]);
    
    final results = await query.get();
    return results.map((data) => domain.WishlistItem(
      id: data.id,
      name: data.name,
      flagUrl: data.flagUrl,
      addedAt: data.addedAt,
    ),).toList();
  }

  /// Add item to wishlist
  Future<void> addToWishlist(domain.WishlistItem item) async {
    await into(wishlistItems).insert(item.toCompanion());
  }

  /// Remove item from wishlist
  Future<void> removeFromWishlist(String id) async {
    await (delete(wishlistItems)..where((t) => t.id.equals(id))).go();
  }

  /// Check if item is in wishlist
  Future<bool> isInWishlist(String id) async {
    final query = select(wishlistItems)..where((t) => t.id.equals(id));
    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Clear all wishlist items
  Future<void> clearWishlist() async {
    await delete(wishlistItems).go();
  }

  /// Batch insert for performance testing
  Future<void> batchInsertWishlistItems(List<domain.WishlistItem> items) async {
    await batch((batch) {
      for (final item in items) {
        batch.insert(wishlistItems, item.toCompanion());
      }
    });
  }

  /// Get wishlist count
  Future<int> getWishlistCount() async {
    final countExp = wishlistItems.id.count();
    final query = selectOnly(wishlistItems)..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  /// Batch check if multiple items are in wishlist (optimized to avoid N+1 queries)
  Future<Map<String, bool>> batchCheckWishlistStatus(List<String> ids) async {
    if (ids.isEmpty) return {};
    
    final query = select(wishlistItems)..where((t) => t.id.isIn(ids));
    final results = await query.get();
    
    // Create map with all IDs set to false initially
    final statusMap = <String, bool>{};
    for (final id in ids) {
      statusMap[id] = false;
    }
    
    // Set found items to true
    for (final item in results) {
      statusMap[item.id] = true;
    }
    
    return statusMap;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'euro_explorer.db'));

    // Make sure sqlite3 is available for Flutter apps
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    return NativeDatabase(file);
  });
}
