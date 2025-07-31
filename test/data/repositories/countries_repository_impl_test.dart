import 'package:euro_explorer/data/datasources/remote/rest_countries_api.dart';
import 'package:euro_explorer/data/models/country_dto.dart';
import 'package:euro_explorer/data/repositories/countries_repository_impl.dart';
import 'package:euro_explorer/domain/entities/country.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRestCountriesApi extends Mock implements RestCountriesApi {}

class MockCountryDto extends Mock implements CountryDto {}

void main() {
  late CountriesRepositoryImpl repository;
  late MockRestCountriesApi mockApi;

  setUp(() {
    mockApi = MockRestCountriesApi();
    repository = CountriesRepositoryImpl(api: mockApi);
  });

  group('CountriesRepositoryImpl', () {
    group('getEuropeanCountries', () {
      test('should return list of countries when API call succeeds', () async {
        // Arrange
        final mockDto = MockCountryDto();
        const expectedCountry = Country(
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

        when(mockDto.toDomain).thenReturn(expectedCountry);
        when(() => mockApi.getEuropeanCountries())
            .thenAnswer((_) async => [mockDto]);

        // Act
        final result = await repository.getEuropeanCountries();

        // Assert
        expect(result, equals([expectedCountry]));
        verify(() => mockApi.getEuropeanCountries()).called(1);
        verify(mockDto.toDomain).called(1);
      });

      test('should throw CountriesRepositoryException when API throws', () async {
        // Arrange
        when(() => mockApi.getEuropeanCountries())
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => repository.getEuropeanCountries(),
          throwsA(isA<CountriesRepositoryException>()),
        );
        verify(() => mockApi.getEuropeanCountries()).called(1);
      });

      test('should return empty list when API returns empty list', () async {
        // Arrange
        when(() => mockApi.getEuropeanCountries())
            .thenAnswer((_) async => []);

        // Act
        final result = await repository.getEuropeanCountries();

        // Assert
        expect(result, isEmpty);
        verify(() => mockApi.getEuropeanCountries()).called(1);
      });
    });

    group('getCountryDetails', () {
      test('should return country when API call succeeds', () async {
        // Arrange
        const countryName = 'Spain';
        final mockDto = MockCountryDto();
        const expectedCountry = Country(
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

        when(mockDto.toDomain).thenReturn(expectedCountry);
        when(() => mockApi.getCountryByTranslation(countryName))
            .thenAnswer((_) async => mockDto);

        // Act
        final result = await repository.getCountryDetails(countryName);

        // Assert
        expect(result, equals(expectedCountry));
        verify(() => mockApi.getCountryByTranslation(countryName)).called(1);
        verify(mockDto.toDomain).called(1);
      });

      test('should throw CountriesRepositoryException when API throws', () async {
        // Arrange
        const countryName = 'Spain';
        when(() => mockApi.getCountryByTranslation(countryName))
            .thenThrow(const RestCountriesException('Country not found'));

        // Act & Assert
        expect(
          () => repository.getCountryDetails(countryName),
          throwsA(isA<CountriesRepositoryException>()),
        );
        verify(() => mockApi.getCountryByTranslation(countryName)).called(1);
      });

      test('should pass correct country name to API', () async {
        // Arrange
        const countryName = 'France';
        final mockDto = MockCountryDto();
        const expectedCountry = Country(
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
        );

        when(mockDto.toDomain).thenReturn(expectedCountry);
        when(() => mockApi.getCountryByTranslation(any()))
            .thenAnswer((_) async => mockDto);

        // Act
        await repository.getCountryDetails(countryName);

        // Assert
        verify(() => mockApi.getCountryByTranslation(countryName)).called(1);
      });
    });
  });
}
