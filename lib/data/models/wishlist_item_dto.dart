import 'package:drift/drift.dart';
import 'package:euro_explorer/data/datasources/local/app_database.dart';
import 'package:euro_explorer/domain/entities/wishlist_item.dart'
    as domain;

/// Data class for Drift database
class WishlistItems extends Table {
  TextColumn get id => text().withLength(min: 1, max: 255)();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get flagUrl => text().withLength(min: 1, max: 500)();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Extension to convert domain entity to Drift companion
extension WishlistItemDomainToData on domain.WishlistItem {
  WishlistItemsCompanion toCompanion() {
    return WishlistItemsCompanion(
      id: Value(id),
      name: Value(name),
      flagUrl: Value(flagUrl),
      addedAt: Value(addedAt),
    );
  }
}