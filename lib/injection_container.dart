import 'package:get_it/get_it.dart';

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

/// Service locator instance
final sl = GetIt.instance;

/// Initialize dependency injection
Future<void> init() async {
  // External dependencies
  final api = RestCountriesApi();
  final database = AppDatabase();

  sl.registerLazySingleton<RestCountriesApi>(() => api);
  sl.registerLazySingleton<AppDatabase>(() => database);

  // Repositories
  sl.registerLazySingleton<CountriesRepository>(
    () => CountriesRepositoryImpl(api: sl()),
  );
  sl.registerLazySingleton<WishlistRepository>(
    () => WishlistRepositoryImpl(database: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetEuropeanCountries(repository: sl()));
  sl.registerLazySingleton(() => GetCountryDetails(repository: sl()));
  sl.registerLazySingleton(() => GetWishlistItems(repository: sl()));
  sl.registerLazySingleton(() => AddToWishlist(repository: sl()));
  sl.registerLazySingleton(() => RemoveFromWishlist(repository: sl()));
  sl.registerLazySingleton(() => IsInWishlist(repository: sl()));
  sl.registerLazySingleton(() => PerformWishlistStressTest(repository: sl()));

  // BLoCs
  sl.registerFactory(() => CountriesCubit(
        getEuropeanCountries: sl(),
        isInWishlist: sl(),
        addToWishlist: sl(),
        removeFromWishlist: sl(),
      ),);
  sl.registerFactory(() => CountryDetailCubit(
        getCountryDetails: sl(),
        isInWishlist: sl(),
        addToWishlist: sl(),
        removeFromWishlist: sl(),
      ),);
  sl.registerFactory(() => WishlistCubit(
        getWishlistItems: sl(),
        removeFromWishlist: sl(),
        performStressTest: sl(),
      ),);
}