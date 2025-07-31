import 'package:euro_explorer/domain/entities/country.dart';
import 'package:euro_explorer/domain/repositories/countries_repository.dart';

/// Use case for getting country details
class GetCountryDetails {
  const GetCountryDetails({
    required CountriesRepository repository,
  }) : _repository = repository;

  final CountriesRepository _repository;

  /// Execute the use case
  Future<Country> call(String countryName) async {
    if (countryName.isEmpty) {
      throw ArgumentError('Country name cannot be empty');
    }
    
    return _repository.getCountryDetails(countryName);
  }
}
