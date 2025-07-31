import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:euro_explorer/domain/entities/country.dart';
import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:euro_explorer/domain/usecases/get_country_details.dart';
import 'package:euro_explorer/domain/usecases/manage_wishlist.dart';

part 'country_detail_state.dart';

/// Cubit for managing country detail screen state
class CountryDetailCubit extends Cubit<CountryDetailState> {
  CountryDetailCubit({
    required GetCountryDetails getCountryDetails,
    required IsInWishlist isInWishlist,
    required AddToWishlist addToWishlist,
    required RemoveFromWishlist removeFromWishlist,
  })  : _getCountryDetails = getCountryDetails,
        _isInWishlist = isInWishlist,
        _addToWishlist = addToWishlist,
        _removeFromWishlist = removeFromWishlist,
        super(const CountryDetailInitial());

  final GetCountryDetails _getCountryDetails;
  final IsInWishlist _isInWishlist;
  final AddToWishlist _addToWishlist;
  final RemoveFromWishlist _removeFromWishlist;

  /// Load country details
  Future<void> loadCountryDetails(String countryName) async {
    emit(const CountryDetailLoading());

    try {
      final country = await _getCountryDetails(countryName);
      final isInWishlist = await _isInWishlist(country.name);

      emit(CountryDetailLoaded(
        country: country,
        isInWishlist: isInWishlist,
      ),);
    } catch (e) {
      emit(CountryDetailError(message: e.toString()));
    }
  }

  /// Toggle wishlist status
  Future<void> toggleWishlist() async {
    final currentState = state;
    if (currentState is! CountryDetailLoaded) return;

    try {
      if (currentState.isInWishlist) {
        await _removeFromWishlist(currentState.country.name);
      } else {
        final wishlistItem = WishlistItem(
          id: currentState.country.name,
          name: currentState.country.name,
          flagUrl: currentState.country.flagUrl,
          addedAt: DateTime.now(),
        );
        await _addToWishlist(wishlistItem);
      }

      emit(currentState.copyWith(isInWishlist: !currentState.isInWishlist));
    } catch (e) {
      emit(CountryDetailError(message: 'Failed to update wishlist: $e'));
      // Restore previous state after showing error
      emit(currentState);
    }
  }
}