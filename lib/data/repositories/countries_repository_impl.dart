import 'package:euro_explorer/domain/entities/country.dart';
import 'package:euro_explorer/domain/repositories/countries_repository.dart';
import 'package:euro_explorer/data/datasources/remote/rest_countries_api.dart';

/// Implementation of CountriesRepository
class CountriesRepositoryImpl implements CountriesRepository {
  const CountriesRepositoryImpl({
    required RestCountriesApi api,
  }) : _api = api;

  final RestCountriesApi _api;

  @override
  Future<List<Country>> getEuropeanCountries() async {
    try {
      final countriesDto = await _api.getEuropeanCountries();
      return countriesDto.map((dto) => dto.toDomain()).toList();
    } catch (e) {
      throw CountriesRepositoryException('Failed to fetch European countries: $e');
    }
  }

  @override
  Future<Country> getCountryDetails(String name) async {
    try {
      final countryDto = await _api.getCountryByTranslation(name);
      return countryDto.toDomain();
    } catch (e) {
      throw CountriesRepositoryException('Failed to fetch country details for $name: $e');
    }
  }
}

/// Custom exception for countries repository
class CountriesRepositoryException implements Exception {
  const CountriesRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'CountriesRepositoryException: $message';
}