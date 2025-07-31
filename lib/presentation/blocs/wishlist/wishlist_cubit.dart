import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:euro_explorer/domain/repositories/wishlist_repository.dart';
import 'package:euro_explorer/domain/usecases/manage_wishlist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'wishlist_state.dart';

/// Cubit for managing wishlist screen state
class WishlistCubit extends Cubit<WishlistState> {
  WishlistCubit({
    required GetWishlistItems getWishlistItems,
    required RemoveFromWishlist removeFromWishlist,
    required ClearWishlist clearWishlist,
    required PerformWishlistStressTest performStressTest,
    required WishlistRepository wishlistRepository,
  })  : _getWishlistItems = getWishlistItems,
        _removeFromWishlist = removeFromWishlist,
        _clearWishlist = clearWishlist,
        _performStressTest = performStressTest,
        _wishlistRepository = wishlistRepository,
        super(const WishlistInitial()) {
    // Listen to wishlist changes for real-time updates
    _wishlistSubscription =
        _wishlistRepository.wishlistChanges.listen(_onWishlistChanged);
  }

  final GetWishlistItems _getWishlistItems;
  final RemoveFromWishlist _removeFromWishlist;
  final ClearWishlist _clearWishlist;
  final PerformWishlistStressTest _performStressTest;
  final WishlistRepository _wishlistRepository;

  StreamSubscription<WishlistChangeEvent>? _wishlistSubscription;

  /// Load wishlist items
  Future<void> loadWishlist() async {
    emit(const WishlistLoading());

    try {
      final items = await _getWishlistItems();
      emit(WishlistLoaded(items: items));
    } catch (e) {
      emit(WishlistError(message: e.toString()));
    }
  }

  /// Remove item from wishlist
  Future<void> removeItem(String countryId) async {
    final currentState = state;

    // Extract current items from different state types
    List<WishlistItem>? currentItems;
    if (currentState is WishlistLoaded) {
      currentItems = currentState.items;
    } else if (currentState is WishlistStressTestCompleted) {
      currentItems = currentState.items;
    } else {
      return; // No items to remove from
    }

    try {
      await _removeFromWishlist(countryId);

      // Update local state
      final updatedItems =
          currentItems.where((item) => item.id != countryId).toList();

      // Always transition to regular loaded state after manual operations
      // The stress test completion state should only show once
      emit(WishlistLoaded(items: updatedItems));
    } catch (e) {
      emit(WishlistError(message: 'Failed to remove item: $e'));
      // Restore previous state after showing error
      emit(currentState);
    }
  }

  /// Run stress test with all European countries
  Future<void> runStressTest() async {
    emit(const WishlistStressTestRunning());

    try {
      final stopwatch = Stopwatch()..start();
      await _performStressTest();
      stopwatch.stop();

      // Reload items to show the results
      final items = await _getWishlistItems();
      emit(
        WishlistStressTestCompleted(
          items: items,
          duration: stopwatch.elapsed,
        ),
      );
    } catch (e) {
      emit(WishlistError(message: 'Stress test failed: $e'));
    }
  }

  /// Clear all items from wishlist
  Future<void> clearWishlist() async {
    try {
      await _clearWishlist();
      emit(const WishlistLoaded(items: []));
    } catch (e) {
      emit(WishlistError(message: 'Failed to clear wishlist: $e'));
    }
  }

  /// Refresh wishlist
  Future<void> refresh() async {
    await loadWishlist();
  }

  /// Handle wishlist changes from other parts of the app
  void _onWishlistChanged(WishlistChangeEvent event) {
    final currentState = state;

    // Extract current items from different state types
    List<WishlistItem>? currentItems;
    if (currentState is WishlistLoaded) {
      currentItems = currentState.items;
    } else if (currentState is WishlistStressTestCompleted) {
      currentItems = currentState.items;
    } else {
      return; // No items to update
    }

    switch (event.type) {
      case WishlistChangeType.added:
        if (event.countryId == '*BATCH*') {
          // Handle batch operations by reloading the entire list
          loadWishlist();
          return;
        }
        // For individual additions, transition to regular loaded state
        // The stress test completion state should only show once
        loadWishlist();
      case WishlistChangeType.removed:
        // Remove the item from current state and transition to regular loaded state
        // Any operation after stress test should return to normal state
        final updatedItems =
            currentItems.where((item) => item.id != event.countryId).toList();

        emit(WishlistLoaded(items: updatedItems));
      case WishlistChangeType.cleared:
        // Clear all items and transition to regular loaded state
        emit(const WishlistLoaded(items: []));
    }
  }

  @override
  Future<void> close() {
    _wishlistSubscription?.cancel();
    return super.close();
  }
}
