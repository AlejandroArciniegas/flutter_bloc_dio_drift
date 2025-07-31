import 'package:bloc_test/bloc_test.dart';
import 'package:euro_explorer/domain/entities/country.dart';
import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:euro_explorer/domain/usecases/get_european_countries.dart';
import 'package:euro_explorer/domain/usecases/manage_wishlist.dart';
import 'package:euro_explorer/presentation/blocs/countries/countries_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetEuropeanCountries extends Mock implements GetEuropeanCountries {}
class MockIsInWishlist extends Mock implements IsInWishlist {}
class MockAddToWishlist extends Mock implements AddToWishlist {}
class MockRemoveFromWishlist extends Mock implements RemoveFromWishlist {}

void main() {
  late CountriesCubit cubit;
  late MockGetEuropeanCountries mockGetEuropeanCountries;
  late MockIsInWishlist mockIsInWishlist;
  late MockAddToWishlist mockAddToWishlist;
  late MockRemoveFromWishlist mockRemoveFromWishlist;

  setUp(() {
    mockGetEuropeanCountries = MockGetEuropeanCountries();
    mockIsInWishlist = MockIsInWishlist();
    mockAddToWishlist = MockAddToWishlist();
    mockRemoveFromWishlist = MockRemoveFromWishlist();

    cubit = CountriesCubit(
      getEuropeanCountries: mockGetEuropeanCountries,
      isInWishlist: mockIsInWishlist,
      addToWishlist: mockAddToWishlist,
      removeFromWishlist: mockRemoveFromWishlist,
    );

    // Register fallback values
    registerFallbackValue(
      WishlistItem(
        id: 'test',
        name: 'Test',
        flagUrl: 'test.svg',
        addedAt: DateTime.now(),
      ),
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('CountriesCubit', () {
    test('initial state is CountriesInitial', () {
      expect(cubit.state, equals(const CountriesInitial()));
    });

    group('loadCountries', () {
      const countries = [
        Country(
          name: 'Spain',
          capital: 'Madrid',
          population: 47000000,
          region: 'Europe',
          subregion: 'Southern Europe',
          area: 505992,
          flagUrl: 'https://flagcdn.com/es.svg',
          nativeNames: {},
          currencies: {},
          languages: {},
          timezones: [],
          mapsUrl: '',
        ),
        Country(
          name: 'France',
          capital: 'Paris',
          population: 68000000,
          region: 'Europe',
          subregion: 'Western Europe',
          area: 643801,
          flagUrl: 'https://flagcdn.com/fr.svg',
          nativeNames: {},
          currencies: {},
          languages: {},
          timezones: [],
          mapsUrl: '',
        ),
      ];

      blocTest<CountriesCubit, CountriesState>(
        'emits [CountriesLoading, CountriesLoaded] when loadCountries succeeds',
        build: () {
          when(() => mockGetEuropeanCountries()).thenAnswer((_) async => countries);
          when(() => mockIsInWishlist('Spain')).thenAnswer((_) async => true);
          when(() => mockIsInWishlist('France')).thenAnswer((_) async => false);
          return cubit;
        },
        act: (cubit) => cubit.loadCountries(),
        expect: () => [
          const CountriesLoading(),
          const CountriesLoaded(
            countries: countries,
            wishlistStatus: {'Spain': true, 'France': false},
          ),
        ],
        verify: (_) {
          verify(() => mockGetEuropeanCountries()).called(1);
          verify(() => mockIsInWishlist('Spain')).called(1);
          verify(() => mockIsInWishlist('France')).called(1);
        },
      );

      blocTest<CountriesCubit, CountriesState>(
        'emits [CountriesLoading, CountriesError] when loadCountries fails',
        build: () {
          when(() => mockGetEuropeanCountries()).thenThrow(Exception('Network error'));
          return cubit;
        },
        act: (cubit) => cubit.loadCountries(),
        expect: () => [
          const CountriesLoading(),
          const CountriesError(message: 'Exception: Network error'),
        ],
      );
    });

    group('toggleWishlist', () {
      const country = Country(
        name: 'Spain',
        capital: 'Madrid',
        population: 47000000,
        region: 'Europe',
        subregion: 'Southern Europe',
        area: 505992,
        flagUrl: 'https://flagcdn.com/es.svg',
        nativeNames: {},
        currencies: {},
        languages: {},
        timezones: [],
        mapsUrl: '',
      );

      blocTest<CountriesCubit, CountriesState>(
        'adds country to wishlist when not already in wishlist',
        build: () {
          return cubit;
        },
        seed: () => const CountriesLoaded(
          countries: [country],
          wishlistStatus: {'Spain': false},
        ),
        setUp: () {
          when(() => mockAddToWishlist(any())).thenAnswer((_) async {});
        },
        act: (cubit) => cubit.toggleWishlist(country),
        expect: () => [
          const CountriesLoaded(
            countries: [country],
            wishlistStatus: {'Spain': true},
          ),
        ],
        verify: (_) {
          verify(() => mockAddToWishlist(any())).called(1);
        },
      );

      blocTest<CountriesCubit, CountriesState>(
        'removes country from wishlist when already in wishlist',
        build: () {
          return cubit;
        },
        seed: () => const CountriesLoaded(
          countries: [country],
          wishlistStatus: {'Spain': true},
        ),
        setUp: () {
          when(() => mockRemoveFromWishlist('Spain')).thenAnswer((_) async {});
        },
        act: (cubit) => cubit.toggleWishlist(country),
        expect: () => [
          const CountriesLoaded(
            countries: [country],
            wishlistStatus: {'Spain': false},
          ),
        ],
        verify: (_) {
          verify(() => mockRemoveFromWishlist('Spain')).called(1);
        },
      );

      blocTest<CountriesCubit, CountriesState>(
        'does nothing when state is not CountriesLoaded',
        build: () => cubit,
        act: (cubit) => cubit.toggleWishlist(country),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockAddToWishlist(any()));
          verifyNever(() => mockRemoveFromWishlist(any()));
        },
      );

      blocTest<CountriesCubit, CountriesState>(
        'emits error and restores state when toggle operation fails',
        build: () {
          return cubit;
        },
        seed: () => const CountriesLoaded(
          countries: [country],
          wishlistStatus: {'Spain': false},
        ),
        setUp: () {
          when(() => mockAddToWishlist(any())).thenThrow(Exception('Database error'));
        },
        act: (cubit) => cubit.toggleWishlist(country),
        expect: () => [
          const CountriesError(message: 'Failed to update wishlist: Exception: Database error'),
          const CountriesLoaded(
            countries: [country],
            wishlistStatus: {'Spain': false},
          ),
        ],
      );
    });

    group('refresh', () {
      const countries = [
        Country(
          name: 'Spain',
          capital: 'Madrid',
          population: 47000000,
          region: 'Europe',
          subregion: 'Southern Europe',
          area: 505992,
          flagUrl: 'https://flagcdn.com/es.svg',
          nativeNames: {},
          currencies: {},
          languages: {},
          timezones: [],
          mapsUrl: '',
        ),
      ];

      blocTest<CountriesCubit, CountriesState>(
        'calls loadCountries when refresh is called',
        build: () {
          when(() => mockGetEuropeanCountries()).thenAnswer((_) async => countries);
          when(() => mockIsInWishlist('Spain')).thenAnswer((_) async => false);
          return cubit;
        },
        act: (cubit) => cubit.refresh(),
        expect: () => [
          const CountriesLoading(),
          const CountriesLoaded(
            countries: countries,
            wishlistStatus: {'Spain': false},
          ),
        ],
        verify: (_) {
          verify(() => mockGetEuropeanCountries()).called(1);
        },
      );
    });
  });
}