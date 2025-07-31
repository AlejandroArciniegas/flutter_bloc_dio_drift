import 'package:equatable/equatable.dart';

/// Domain entity representing a wishlist item
class WishlistItem extends Equatable {
  const WishlistItem({
    required this.id,
    required this.name,
    required this.flagUrl,
    required this.addedAt,
  });

  final String id;
  final String name;
  final String flagUrl;
  final DateTime addedAt;

  @override
  List<Object?> get props => [id, name, flagUrl, addedAt];
}
