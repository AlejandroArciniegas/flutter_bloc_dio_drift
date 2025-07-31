import 'package:json_annotation/json_annotation.dart';
import 'package:euro_explorer/domain/entities/country.dart';

part 'country_dto.g.dart';

/// Data Transfer Object for Country from REST Countries API
@JsonSerializable()
class CountryDto {
  const CountryDto({
    required this.name,
    required this.capital,
    required this.population,
    required this.region,
    required this.subregion,
    required this.area,
    required this.flags,
    required this.currencies,
    required this.languages,
    required this.timezones,
    required this.maps,
  });

  factory CountryDto.fromJson(Map<String, dynamic> json) =>
      _$CountryDtoFromJson(json);

  final NameDto name;
  final List<String>? capital;
  final int population;
  final String region;
  final String? subregion;
  final double? area;
  final FlagsDto flags;
  final Map<String, CurrencyDto>? currencies;
  final Map<String, String>? languages;
  final List<String> timezones;
  final MapsDto maps;

  Map<String, dynamic> toJson() => _$CountryDtoToJson(this);

  /// Convert DTO to domain entity
  Country toDomain() {
    return Country(
      name: name.common,
      capital: capital?.isNotEmpty == true ? capital!.first : 'N/A',
      population: population,
      region: region,
      subregion: subregion ?? 'N/A',
      area: area ?? 0.0,
      flagUrl: flags.svg ?? flags.png ?? '',
      nativeNames: name.nativeName != null
          ? name.nativeName!.map((key, value) => MapEntry(key, value.common))
          : <String, String>{},
      currencies: currencies?.map((key, value) =>
              MapEntry(key, '${value.name} (${value.symbol ?? ''})'),) ??
          <String, String>{},
      languages: languages ?? <String, String>{},
      timezones: timezones,
      mapsUrl: maps.googleMaps ?? maps.openStreetMaps ?? '',
    );
  }
}

@JsonSerializable()
class NameDto {
  const NameDto({
    required this.common,
    required this.official,
    this.nativeName,
  });

  factory NameDto.fromJson(Map<String, dynamic> json) =>
      _$NameDtoFromJson(json);

  final String common;
  final String official;
  final Map<String, NativeNameDto>? nativeName;

  Map<String, dynamic> toJson() => _$NameDtoToJson(this);
}

@JsonSerializable()
class NativeNameDto {
  const NativeNameDto({
    required this.official,
    required this.common,
  });

  factory NativeNameDto.fromJson(Map<String, dynamic> json) =>
      _$NativeNameDtoFromJson(json);

  final String official;
  final String common;

  Map<String, dynamic> toJson() => _$NativeNameDtoToJson(this);
}

@JsonSerializable()
class FlagsDto {
  const FlagsDto({
    this.png,
    this.svg,
  });

  factory FlagsDto.fromJson(Map<String, dynamic> json) =>
      _$FlagsDtoFromJson(json);

  final String? png;
  final String? svg;

  Map<String, dynamic> toJson() => _$FlagsDtoToJson(this);
}

@JsonSerializable()
class CurrencyDto {
  const CurrencyDto({
    required this.name,
    this.symbol,
  });

  factory CurrencyDto.fromJson(Map<String, dynamic> json) =>
      _$CurrencyDtoFromJson(json);

  final String name;
  final String? symbol;

  Map<String, dynamic> toJson() => _$CurrencyDtoToJson(this);
}

@JsonSerializable()
class MapsDto {
  const MapsDto({
    this.googleMaps,
    this.openStreetMaps,
  });

  factory MapsDto.fromJson(Map<String, dynamic> json) =>
      _$MapsDtoFromJson(json);

  @JsonKey(name: 'googleMaps')
  final String? googleMaps;
  @JsonKey(name: 'openStreetMaps')
  final String? openStreetMaps;

  Map<String, dynamic> toJson() => _$MapsDtoToJson(this);
}