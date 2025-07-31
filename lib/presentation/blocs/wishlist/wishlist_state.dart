part of 'wishlist_cubit.dart';

/// State for wishlist screen
@immutable
sealed class WishlistState extends Equatable {
  const WishlistState();

  @override
  List<Object?> get props => [];
}

/// Initial state
final class WishlistInitial extends WishlistState {
  const WishlistInitial();
}

/// Loading state
final class WishlistLoading extends WishlistState {
  const WishlistLoading();
}

/// Success state with wishlist items
final class WishlistLoaded extends WishlistState {
  const WishlistLoaded({
    required this.items,
  });

  final List<WishlistItem> items;

  @override
  List<Object?> get props => [items];

  WishlistLoaded copyWith({
    List<WishlistItem>? items,
  }) {
    return WishlistLoaded(
      items: items ?? this.items,
    );
  }
}

/// Error state
final class WishlistError extends WishlistState {
  const WishlistError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Stress test running state
final class WishlistStressTestRunning extends WishlistState {
  const WishlistStressTestRunning();
}

/// Stress test completed state
final class WishlistStressTestCompleted extends WishlistState {
  const WishlistStressTestCompleted({
    required this.items,
    required this.duration,
  });

  final List<WishlistItem> items;
  final Duration duration;

  @override
  List<Object?> get props => [items, duration];
}
