import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:euro_explorer/domain/entities/country.dart';
import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:euro_explorer/domain/repositories/wishlist_repository.dart';
import 'package:euro_explorer/domain/usecases/get_european_countries.dart';
import 'package:euro_explorer/domain/usecases/manage_wishlist.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'countries_state.dart';

/// Cubit for managing countries list screen state
class CountriesCubit extends Cubit<CountriesState> {
  CountriesCubit({
    required GetEuropeanCountries getEuropeanCountries,
    required BatchCheckWishlistStatus batchCheckWishlistStatus,
    required AddToWishlist addToWishlist,
    required RemoveFromWishlist removeFromWishlist,
    required WishlistRepository wishlistRepository,
  })  : _getEuropeanCountries = getEuropeanCountries,
        _batchCheckWishlistStatus = batchCheckWishlistStatus,
        _addToWishlist = addToWishlist,
        _removeFromWishlist = removeFromWishlist,
        _wishlistRepository = wishlistRepository,
        super(const CountriesInitial()) {
    // Listen to wishlist changes to update heart icons in real-time
    _wishlistSubscription =
        _wishlistRepository.wishlistChanges.listen(_onWishlistChanged);
  }

  final GetEuropeanCountries _getEuropeanCountries;
  final BatchCheckWishlistStatus _batchCheckWishlistStatus;
  final AddToWishlist _addToWishlist;
  final RemoveFromWishlist _removeFromWishlist;
  final WishlistRepository _wishlistRepository;

  StreamSubscription<WishlistChangeEvent>? _wishlistSubscription;

  /// Load European countries
  Future<void> loadCountries() async {
    emit(const CountriesLoading());

    try {
      final countries = await _getEuropeanCountries();

      // Batch check wishlist status for all countries (optimized - single query)
      final countryNames = countries.map((country) => country.name).toList();
      final wishlistStatus = await _batchCheckWishlistStatus(countryNames);

      emit(
        CountriesLoaded(
          countries: countries,
          wishlistStatus: wishlistStatus,
        ),
      );
    } catch (e) {
      emit(CountriesError(message: e.toString()));
    }
  }

  /// Toggle wishlist status for a country
  Future<void> toggleWishlist(Country country) async {
    final currentState = state;
    if (currentState is! CountriesLoaded) return;

    try {
      final isCurrentlyInWishlist =
          currentState.wishlistStatus[country.name] ?? false;

      if (isCurrentlyInWishlist) {
        await _removeFromWishlist(country.name);
      } else {
        final wishlistItem = WishlistItem(
          id: country.name,
          name: country.name,
          flagUrl: country.flagUrl,
          addedAt: DateTime.now(),
        );
        await _addToWishlist(wishlistItem);
      }

      // Update local state
      final updatedWishlistStatus =
          Map<String, bool>.from(currentState.wishlistStatus);
      updatedWishlistStatus[country.name] = !isCurrentlyInWishlist;

      emit(currentState.copyWith(wishlistStatus: updatedWishlistStatus));
    } catch (e) {
      // Show error but keep current state
      emit(CountriesError(message: 'Failed to update wishlist: $e'));
      // Restore previous state after showing error
      emit(currentState);
    }
  }

  /// Refresh countries list
  Future<void> refresh() async {
    await loadCountries();
  }

  /// Handle wishlist changes from other parts of the app
  void _onWishlistChanged(WishlistChangeEvent event) {
    final currentState = state;
    if (currentState is! CountriesLoaded) return;

    final updatedWishlistStatus =
        Map<String, bool>.from(currentState.wishlistStatus);

    switch (event.type) {
      case WishlistChangeType.added:
        if (event.countryId == '*BATCH*') {
          // Handle batch operations (like stress test) by refreshing the entire status
          _refreshWishlistStatusAsync();
          return;
        }
        updatedWishlistStatus[event.countryId] = true;
      case WishlistChangeType.removed:
        updatedWishlistStatus[event.countryId] = false;
      case WishlistChangeType.cleared:
        // Reset all countries to not wishlisted
        for (final key in updatedWishlistStatus.keys) {
          updatedWishlistStatus[key] = false;
        }
    }

    emit(currentState.copyWith(wishlistStatus: updatedWishlistStatus));
  }

  /// Refresh wishlist status asynchronously for batch operations
  Future<void> _refreshWishlistStatusAsync() async {
    final currentState = state;
    if (currentState is! CountriesLoaded) return;

    try {
      final countryNames =
          currentState.countries.map((country) => country.name).toList();
      final wishlistStatus = await _batchCheckWishlistStatus(countryNames);

      // Only emit if the current state is still valid (no navigation away)
      if (state is CountriesLoaded) {
        emit(currentState.copyWith(wishlistStatus: wishlistStatus));
      }
    } catch (e) {
      // Log error but don't change state
      if (kDebugMode) {
        print('Failed to refresh wishlist status: $e');
      }
    }
  }

  @override
  Future<void> close() {
    _wishlistSubscription?.cancel();
    return super.close();
  }
}
