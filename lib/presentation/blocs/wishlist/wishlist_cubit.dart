import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:euro_explorer/domain/usecases/manage_wishlist.dart';

part 'wishlist_state.dart';

/// Cubit for managing wishlist screen state
class WishlistCubit extends Cubit<WishlistState> {
  WishlistCubit({
    required GetWishlistItems getWishlistItems,
    required RemoveFromWishlist removeFromWishlist,
    required PerformWishlistStressTest performStressTest,
  })  : _getWishlistItems = getWishlistItems,
        _removeFromWishlist = removeFromWishlist,
        _performStressTest = performStressTest,
        super(const WishlistInitial());

  final GetWishlistItems _getWishlistItems;
  final RemoveFromWishlist _removeFromWishlist;
  final PerformWishlistStressTest _performStressTest;

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
    if (currentState is! WishlistLoaded) return;

    try {
      await _removeFromWishlist(countryId);
      
      // Update local state
      final updatedItems = currentState.items
          .where((item) => item.id != countryId)
          .toList();
      
      emit(WishlistLoaded(items: updatedItems));
    } catch (e) {
      emit(WishlistError(message: 'Failed to remove item: $e'));
      // Restore previous state after showing error
      emit(currentState);
    }
  }

  /// Run stress test with 5000 entries
  Future<void> runStressTest() async {
    emit(const WishlistStressTestRunning());
    
    try {
      final stopwatch = Stopwatch()..start();
      await _performStressTest();
      stopwatch.stop();

      // Reload items to show the results
      final items = await _getWishlistItems();
      emit(WishlistStressTestCompleted(
        items: items,
        duration: stopwatch.elapsed,
      ),);
    } catch (e) {
      emit(WishlistError(message: 'Stress test failed: $e'));
    }
  }

  /// Refresh wishlist
  Future<void> refresh() async {
    await loadWishlist();
  }
}