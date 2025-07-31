import 'package:euro_explorer/domain/entities/country.dart';
import 'package:euro_explorer/domain/repositories/countries_repository.dart';
import 'package:euro_explorer/domain/usecases/get_european_countries.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCountriesRepository extends Mock implements CountriesRepository {}

void main() {
  late GetEuropeanCountries useCase;
  late MockCountriesRepository mockRepository;

  setUp(() {
    mockRepository = MockCountriesRepository();
    useCase = GetEuropeanCountries(repository: mockRepository);
  });

  group('GetEuropeanCountries', () {
    test('should return list of countries from repository', () async {
      // Arrange
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

      when(() => mockRepository.getEuropeanCountries())
          .thenAnswer((_) async => countries);

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(countries));
      verify(() => mockRepository.getEuropeanCountries()).called(1);
    });

    test('should throw exception when repository throws', () async {
      // Arrange
      final exception = Exception('Network error');
      when(() => mockRepository.getEuropeanCountries()).thenThrow(exception);

      // Act & Assert
      expect(() => useCase(), throwsException);
      verify(() => mockRepository.getEuropeanCountries()).called(1);
    });

    test('should return empty list when repository returns empty list', () async {
      // Arrange
      when(() => mockRepository.getEuropeanCountries())
          .thenAnswer((_) async => []);

      // Act
      final result = await useCase();

      // Assert
      expect(result, isEmpty);
      verify(() => mockRepository.getEuropeanCountries()).called(1);
    });
  });
}
