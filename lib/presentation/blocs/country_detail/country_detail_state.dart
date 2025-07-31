part of 'country_detail_cubit.dart';

/// State for country detail screen
@immutable
sealed class CountryDetailState extends Equatable {
  const CountryDetailState();

  @override
  List<Object?> get props => [];
}

/// Initial state
final class CountryDetailInitial extends CountryDetailState {
  const CountryDetailInitial();
}

/// Loading state
final class CountryDetailLoading extends CountryDetailState {
  const CountryDetailLoading();
}

/// Success state with country details
final class CountryDetailLoaded extends CountryDetailState {
  const CountryDetailLoaded({
    required this.country,
    required this.isInWishlist,
  });

  final Country country;
  final bool isInWishlist;

  @override
  List<Object?> get props => [country, isInWishlist];

  CountryDetailLoaded copyWith({
    Country? country,
    bool? isInWishlist,
  }) {
    return CountryDetailLoaded(
      country: country ?? this.country,
      isInWishlist: isInWishlist ?? this.isInWishlist,
    );
  }
}

/// Error state
final class CountryDetailError extends CountryDetailState {
  const CountryDetailError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}