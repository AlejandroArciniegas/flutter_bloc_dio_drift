import 'package:euro_explorer/data/datasources/local/app_database.dart';
import 'package:euro_explorer/data/datasources/remote/rest_countries_api.dart';
import 'package:euro_explorer/data/repositories/countries_repository_impl.dart';
import 'package:euro_explorer/data/repositories/wishlist_repository_impl.dart';
import 'package:euro_explorer/domain/repositories/countries_repository.dart';
import 'package:euro_explorer/domain/repositories/wishlist_repository.dart';
import 'package:euro_explorer/domain/usecases/get_country_details.dart';
import 'package:euro_explorer/domain/usecases/get_european_countries.dart';
import 'package:euro_explorer/domain/usecases/manage_wishlist.dart';
import 'package:euro_explorer/presentation/blocs/countries/countries_cubit.dart';
import 'package:euro_explorer/presentation/blocs/country_detail/country_detail_cubit.dart';
import 'package:euro_explorer/presentation/blocs/wishlist/wishlist_cubit.dart';
import 'package:get_it/get_it.dart';

/// Service locator instance
final sl = GetIt.instance;

/// Initialize dependency injection
Future<void> init() async {
  // External dependencies
  final api = RestCountriesApi();
  final database = AppDatabase();

  sl
    ..registerLazySingleton<RestCountriesApi>(() => api)
    ..registerLazySingleton<AppDatabase>(() => database)

    // Repositories
    ..registerLazySingleton<CountriesRepository>(
      () => CountriesRepositoryImpl(api: sl()),
    )
    ..registerLazySingleton<WishlistRepository>(
      () => WishlistRepositoryImpl(database: sl()),
    )

    // Use cases
    ..registerLazySingleton(() => GetEuropeanCountries(repository: sl()))
    ..registerLazySingleton(() => GetCountryDetails(repository: sl()))
    ..registerLazySingleton(() => GetWishlistItems(repository: sl()))
    ..registerLazySingleton(() => AddToWishlist(repository: sl()))
    ..registerLazySingleton(() => RemoveFromWishlist(repository: sl()))
    ..registerLazySingleton(() => ClearWishlist(repository: sl()))
    ..registerLazySingleton(() => IsInWishlist(repository: sl()))
    ..registerLazySingleton(() => BatchCheckWishlistStatus(repository: sl()))
    ..registerLazySingleton(
      () => PerformWishlistStressTest(
        repository: sl(),
        countriesRepository: sl(),
      ),
    )

    // BLoCs
    ..registerFactory(
      () => CountriesCubit(
        getEuropeanCountries: sl(),
        batchCheckWishlistStatus: sl(),
        addToWishlist: sl(),
        removeFromWishlist: sl(),
        wishlistRepository: sl(),
      ),
    )
    ..registerFactory(
      () => CountryDetailCubit(
        getCountryDetails: sl(),
        isInWishlist: sl(),
        addToWishlist: sl(),
        removeFromWishlist: sl(),
        wishlistRepository: sl(),
      ),
    )
    ..registerFactory(
      () => WishlistCubit(
        getWishlistItems: sl(),
        removeFromWishlist: sl(),
        clearWishlist: sl(),
        performStressTest: sl(),
        wishlistRepository: sl(),
      ),
    );
}
