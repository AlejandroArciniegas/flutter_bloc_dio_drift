import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:euro_explorer/domain/entities/country.dart';
import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:euro_explorer/domain/usecases/get_european_countries.dart';
import 'package:euro_explorer/domain/usecases/manage_wishlist.dart';

part 'countries_state.dart';

/// Cubit for managing countries list screen state
class CountriesCubit extends Cubit<CountriesState> {
  CountriesCubit({
    required GetEuropeanCountries getEuropeanCountries,
    required IsInWishlist isInWishlist,
    required AddToWishlist addToWishlist,
    required RemoveFromWishlist removeFromWishlist,
  })  : _getEuropeanCountries = getEuropeanCountries,
        _isInWishlist = isInWishlist,
        _addToWishlist = addToWishlist,
        _removeFromWishlist = removeFromWishlist,
        super(const CountriesInitial());

  final GetEuropeanCountries _getEuropeanCountries;
  final IsInWishlist _isInWishlist;
  final AddToWishlist _addToWishlist;
  final RemoveFromWishlist _removeFromWishlist;

  /// Load European countries
  Future<void> loadCountries() async {
    emit(const CountriesLoading());

    try {
      final countries = await _getEuropeanCountries();
      
      // Check wishlist status for each country
      final wishlistStatus = <String, bool>{};
      for (final country in countries) {
        wishlistStatus[country.name] = await _isInWishlist(country.name);
      }

      emit(CountriesLoaded(
        countries: countries,
        wishlistStatus: wishlistStatus,
      ),);
    } catch (e) {
      emit(CountriesError(message: e.toString()));
    }
  }

  /// Toggle wishlist status for a country
  Future<void> toggleWishlist(Country country) async {
    final currentState = state;
    if (currentState is! CountriesLoaded) return;

    try {
      final isCurrentlyInWishlist = currentState.wishlistStatus[country.name] ?? false;
      
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
      final updatedWishlistStatus = Map<String, bool>.from(currentState.wishlistStatus);
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
}