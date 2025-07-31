import 'package:euro_explorer/data/datasources/remote/rest_countries_api.dart';
import 'package:euro_explorer/data/isolates/data_processing_isolates.dart';
import 'package:euro_explorer/domain/entities/country.dart';
import 'package:euro_explorer/domain/repositories/countries_repository.dart';

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
      
      // Use isolate for heavy DTO to domain conversion to prevent UI blocking
      return DataProcessingIsolates.convertCountriesDtoToDomain(countriesDto);
    } catch (e) {
      throw CountriesRepositoryException('Failed to fetch European countries: $e');
    }
  }

  @override
  Future<Country> getCountryDetails(String name) async {
    try {
      final countryDto = await _api.getCountryByTranslation(name);
      
      // Single country conversion - no need for isolate
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
