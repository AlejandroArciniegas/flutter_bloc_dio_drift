import 'package:euro_explorer/domain/entities/country.dart';
import 'package:euro_explorer/domain/repositories/countries_repository.dart';

/// Use case for getting European countries
class GetEuropeanCountries {
  const GetEuropeanCountries({
    required CountriesRepository repository,
  }) : _repository = repository;

  final CountriesRepository _repository;

  /// Execute the use case
  Future<List<Country>> call() async {
    return _repository.getEuropeanCountries();
  }
}