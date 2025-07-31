import 'package:euro_explorer/domain/entities/country.dart';

/// Repository interface for countries data
abstract class CountriesRepository {
  /// Get all European countries
  Future<List<Country>> getEuropeanCountries();

  /// Get detailed country information by name
  Future<Country> getCountryDetails(String name);
}
