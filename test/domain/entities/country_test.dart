import 'package:euro_explorer/domain/entities/country.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Country', () {
    test('should create country instance with all properties', () {
      // Arrange
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

      // Assert
      expect(country.name, equals('Spain'));
      expect(country.capital, equals('Madrid'));
      expect(country.population, equals(47000000));
      expect(country.region, equals('Europe'));
      expect(country.subregion, equals('Southern Europe'));
      expect(country.area, equals(505992.0));
      expect(country.flagUrl, equals('https://flagcdn.com/es.svg'));
      expect(country.nativeNames, equals({'spa': 'España'}));
      expect(country.currencies, equals({'EUR': 'Euro (€)'}));
      expect(country.languages, equals({'spa': 'Spanish'}));
      expect(country.timezones, equals(['UTC+01:00']));
      expect(country.mapsUrl, equals('https://goo.gl/maps/example'));
    });

    test('should support equality comparison', () {
      // Arrange
      const country1 = Country(
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

      const country2 = Country(
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

      const country3 = Country(
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

      // Assert
      expect(country1, equals(country2));
      expect(country1.hashCode, equals(country2.hashCode));
      expect(country1, isNot(equals(country3)));
    });
  });
}
