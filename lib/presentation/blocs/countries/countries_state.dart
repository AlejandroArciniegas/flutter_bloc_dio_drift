part of 'countries_cubit.dart';

/// State for countries screen
@immutable
sealed class CountriesState extends Equatable {
  const CountriesState();

  @override
  List<Object?> get props => [];
}

/// Initial state
final class CountriesInitial extends CountriesState {
  const CountriesInitial();
}

/// Loading state
final class CountriesLoading extends CountriesState {
  const CountriesLoading();
}

/// Success state with countries data
final class CountriesLoaded extends CountriesState {
  const CountriesLoaded({
    required this.countries,
    required this.wishlistStatus,
  });

  final List<Country> countries;
  final Map<String, bool> wishlistStatus;

  @override
  List<Object?> get props => [countries, wishlistStatus];

  CountriesLoaded copyWith({
    List<Country>? countries,
    Map<String, bool>? wishlistStatus,
  }) {
    return CountriesLoaded(
      countries: countries ?? this.countries,
      wishlistStatus: wishlistStatus ?? this.wishlistStatus,
    );
  }
}

/// Error state
final class CountriesError extends CountriesState {
  const CountriesError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
