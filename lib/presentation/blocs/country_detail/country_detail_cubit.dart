import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:euro_explorer/domain/entities/country.dart';
import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:euro_explorer/domain/repositories/wishlist_repository.dart';
import 'package:euro_explorer/domain/usecases/get_country_details.dart';
import 'package:euro_explorer/domain/usecases/manage_wishlist.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'country_detail_state.dart';

/// Cubit for managing country detail screen state
class CountryDetailCubit extends Cubit<CountryDetailState> {
  CountryDetailCubit({
    required GetCountryDetails getCountryDetails,
    required IsInWishlist isInWishlist,
    required AddToWishlist addToWishlist,
    required RemoveFromWishlist removeFromWishlist,
    required WishlistRepository wishlistRepository,
  })  : _getCountryDetails = getCountryDetails,
        _isInWishlist = isInWishlist,
        _addToWishlist = addToWishlist,
        _removeFromWishlist = removeFromWishlist,
        _wishlistRepository = wishlistRepository,
        super(const CountryDetailInitial()) {
    // Listen to wishlist changes to update button state in real-time
    _wishlistSubscription =
        _wishlistRepository.wishlistChanges.listen(_onWishlistChanged);
  }

  final GetCountryDetails _getCountryDetails;
  final IsInWishlist _isInWishlist;
  final AddToWishlist _addToWishlist;
  final RemoveFromWishlist _removeFromWishlist;
  final WishlistRepository _wishlistRepository;

  StreamSubscription<WishlistChangeEvent>? _wishlistSubscription;

  /// Load country details
  Future<void> loadCountryDetails(String countryName) async {
    emit(const CountryDetailLoading());

    try {
      final country = await _getCountryDetails(countryName);
      final isInWishlist = await _isInWishlist(country.name);

      emit(
        CountryDetailLoaded(
          country: country,
          isInWishlist: isInWishlist,
        ),
      );
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

  /// Handle wishlist changes from other parts of the app
  void _onWishlistChanged(WishlistChangeEvent event) {
    final currentState = state;
    if (currentState is! CountryDetailLoaded) return;

    // Only update if this country is affected
    final currentCountryName = currentState.country.name;

    switch (event.type) {
      case WishlistChangeType.added:
        if (event.countryId == '*BATCH*') {
          // Handle batch operations by checking current status
          _checkWishlistStatusAsync();
          return;
        }
        if (event.countryId == currentCountryName &&
            !currentState.isInWishlist) {
          emit(currentState.copyWith(isInWishlist: true));
        }
      case WishlistChangeType.removed:
        if (event.countryId == currentCountryName &&
            currentState.isInWishlist) {
          emit(currentState.copyWith(isInWishlist: false));
        }
      case WishlistChangeType.cleared:
        if (currentState.isInWishlist) {
          emit(currentState.copyWith(isInWishlist: false));
        }
    }
  }

  /// Check wishlist status asynchronously for batch operations
  Future<void> _checkWishlistStatusAsync() async {
    final currentState = state;
    if (currentState is! CountryDetailLoaded) return;

    try {
      final isInWishlist = await _isInWishlist(currentState.country.name);

      // Only emit if the current state is still valid and the status has changed
      if (state is CountryDetailLoaded &&
          (state as CountryDetailLoaded).isInWishlist != isInWishlist) {
        emit(currentState.copyWith(isInWishlist: isInWishlist));
      }
    } catch (e) {
      // Log error but don't change state
      if (kDebugMode) {
        print('Failed to check wishlist status: $e');
      }
    }
  }

  @override
  Future<void> close() {
    _wishlistSubscription?.cancel();
    return super.close();
  }
}
