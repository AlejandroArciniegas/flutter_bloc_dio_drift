import 'package:equatable/equatable.dart';

/// Domain entity representing a country
class Country extends Equatable {
  const Country({
    required this.name,
    required this.capital,
    required this.population,
    required this.region,
    required this.subregion,
    required this.area,
    required this.flagUrl,
    required this.nativeNames,
    required this.currencies,
    required this.languages,
    required this.timezones,
    required this.mapsUrl,
  });

  final String name;
  final String capital;
  final int population;
  final String region;
  final String subregion;
  final double area;
  final String flagUrl;
  final Map<String, String> nativeNames;
  final Map<String, String> currencies;
  final Map<String, String> languages;
  final List<String> timezones;
  final String mapsUrl;

  @override
  List<Object?> get props => [
        name,
        capital,
        population,
        region,
        subregion,
        area,
        flagUrl,
        nativeNames,
        currencies,
        languages,
        timezones,
        mapsUrl,
      ];
}