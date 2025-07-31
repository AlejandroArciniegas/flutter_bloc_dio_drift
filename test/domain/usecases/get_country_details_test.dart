import 'package:euro_explorer/domain/entities/country.dart';
import 'package:euro_explorer/domain/repositories/countries_repository.dart';
import 'package:euro_explorer/domain/usecases/get_country_details.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCountriesRepository extends Mock implements CountriesRepository {}

void main() {
  late GetCountryDetails useCase;
  late MockCountriesRepository mockRepository;

  setUp(() {
    mockRepository = MockCountriesRepository();
    useCase = GetCountryDetails(repository: mockRepository);
  });

  group('GetCountryDetails', () {
    test('should return country details from repository', () async {
      // Arrange
      const countryName = 'Spain';
      const country = Country(
        name: 'Spain',
        capital: 'Madrid',
        population: 47000000,
        region: 'Europe',
        subregion: 'Southern Europe',
        area: 505992,
        flagUrl: 'https://flagcdn.com/es.svg',
        nativeNames: {'spa': 'España'},
        currencies: {'EUR': 'Euro (€)'},
        languages: {'spa': 'Spanish'},
        timezones: ['UTC+01:00'],
        mapsUrl: 'https://goo.gl/maps/example',
      );

      when(() => mockRepository.getCountryDetails(countryName))
          .thenAnswer((_) async => country);

      // Act
      final result = await useCase(countryName);

      // Assert
      expect(result, equals(country));
      verify(() => mockRepository.getCountryDetails(countryName)).called(1);
    });

    test('should throw ArgumentError when country name is empty', () async {
      // Act & Assert
      expect(() => useCase(''), throwsArgumentError);
      verifyNever(() => mockRepository.getCountryDetails(any()));
    });

    test('should throw exception when repository throws', () async {
      // Arrange
      const countryName = 'Spain';
      final exception = Exception('Country not found');
      when(() => mockRepository.getCountryDetails(countryName))
          .thenThrow(exception);

      // Act & Assert
      expect(() => useCase(countryName), throwsException);
      verify(() => mockRepository.getCountryDetails(countryName)).called(1);
    });

    test('should pass correct country name to repository', () async {
      // Arrange
      const countryName = 'Spain';
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

      when(() => mockRepository.getCountryDetails(any()))
          .thenAnswer((_) async => country);

      // Act
      await useCase(countryName);

      // Assert
      verify(() => mockRepository.getCountryDetails(countryName)).called(1);
    });
  });
}
