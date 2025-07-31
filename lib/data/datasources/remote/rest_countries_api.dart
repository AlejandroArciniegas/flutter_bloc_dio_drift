import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_db_store/dio_cache_interceptor_db_store.dart';
import 'package:euro_explorer/data/models/country_dto.dart';
import 'package:path_provider/path_provider.dart';

/// REST Countries API client with caching
class RestCountriesApi {
  RestCountriesApi({Dio? dio}) : _dio = dio ?? _createDio() {
    _initializeCache();
  }

  static const String _baseUrl = 'https://restcountries.com/v3.1';
  static CacheOptions? _cacheOptions;
  final Dio _dio;

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),);

    // Add logging interceptor for development
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) {
        // Only log in debug mode
        assert(() {
          // ignore: avoid_print
          print(object);
          return true;
        }(), 'Logging is enabled',);
      },
    ),);

    return dio;
  }

  /// Initialize cache asynchronously
  Future<void> _initializeCache() async {
    if (_cacheOptions != null) return; // Already set up

    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheStore = DbCacheStore(
        databasePath: '${cacheDir.path}/countries_cache.db',
      );

      _cacheOptions = CacheOptions(
        store: cacheStore,
        hitCacheOnErrorExcept: [401, 403, 404],
        maxStale: const Duration(days: 7),
        priority: CachePriority.high,
      );

      // Add cache interceptor after setup
      _dio.interceptors.add(DioCacheInterceptor(options: _cacheOptions!));
    } catch (e) {
      // Fallback to memory cache if DB cache setup fails
      _cacheOptions = CacheOptions(
        store: MemCacheStore(),
        hitCacheOnErrorExcept: [401, 403, 404],
        maxStale: const Duration(days: 7),
      );
      
      // Add fallback cache interceptor
      _dio.interceptors.add(DioCacheInterceptor(options: _cacheOptions!));
    }
  }

  /// Get all European countries
  /// Cache TTL: 24 hours
  Future<List<CountryDto>> getEuropeanCountries() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/region/europe',
        options: buildCacheOptions(
          const Duration(hours: 24),
        ),
      );

      if (response.data == null) {
        throw const RestCountriesException('No data received');
      }

      return response.data!
          .cast<Map<String, dynamic>>()
          .map(CountryDto.fromJson)
          .toList();
    } on DioException catch (e) {
      throw RestCountriesException.fromDioException(e);
    } catch (e) {
      throw RestCountriesException('Unexpected error: $e');
    }
  }

  /// Get country details by name
  /// Cache TTL: 7 days
  Future<CountryDto> getCountryByName(String name) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/name/${Uri.encodeComponent(name)}',
        queryParameters: {'fullText': true},
        options: buildCacheOptions(
          const Duration(days: 7),
        ),
      );

      if (response.data == null || response.data!.isEmpty) {
        throw const RestCountriesException('Country not found');
      }

      return CountryDto.fromJson(
        response.data!.first as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw RestCountriesException.fromDioException(e);
    } catch (e) {
      throw RestCountriesException('Unexpected error: $e');
    }
  }

  /// Get country details by translation (common name)
  /// Cache TTL: 7 days
  Future<CountryDto> getCountryByTranslation(String commonName) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/translation/${Uri.encodeComponent(commonName)}',
        options: buildCacheOptions(
          const Duration(days: 7),
        ),
      );

      if (response.data == null || response.data!.isEmpty) {
        throw const RestCountriesException('Country not found');
      }

      return CountryDto.fromJson(
        response.data!.first as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw RestCountriesException.fromDioException(e);
    } catch (e) {
      throw RestCountriesException('Unexpected error: $e');
    }
  }

  /// Build cache options with custom TTL
  Options buildCacheOptions(Duration maxAge) {
    // Ensure cache is initialized before use
    if (_cacheOptions == null) {
      // Use temporary memory cache if not initialized yet
      return CacheOptions(
        store: MemCacheStore(),
        maxStale: maxAge,
        hitCacheOnErrorExcept: [401, 403, 404],
      ).toOptions();
    }
    
    return CacheOptions(
      store: _cacheOptions!.store,
      maxStale: maxAge,
      hitCacheOnErrorExcept: [401, 403, 404],
      priority: CachePriority.high,
    ).toOptions();
  }

  /// Close the Dio client and clean up cache
  Future<void> close() async {
    _dio.close();
    
    // Clean up cache store if it's a database store
    if (_cacheOptions?.store is DbCacheStore) {
      await (_cacheOptions!.store! as DbCacheStore).close();
    }
  }
}

/// Custom exception for REST Countries API
class RestCountriesException implements Exception {
  const RestCountriesException(this.message);

  factory RestCountriesException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const RestCountriesException('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 404) {
          return const RestCountriesException('Country not found');
        } else if (statusCode == 500) {
          return const RestCountriesException('Server error');
        }
        return RestCountriesException(
          'HTTP $statusCode: ${e.response?.statusMessage ?? 'Unknown error'}',
        );
      case DioExceptionType.cancel:
        return const RestCountriesException('Request cancelled');
      case DioExceptionType.connectionError:
        return const RestCountriesException('No internet connection');
      case DioExceptionType.badCertificate:
        return const RestCountriesException('SSL certificate error');
      case DioExceptionType.unknown:
      // ignore: no_default_cases
      default:
        return RestCountriesException('Unknown error: ${e.message}');
    }
  }

  final String message;

  @override
  String toString() => 'RestCountriesException: $message';
}
