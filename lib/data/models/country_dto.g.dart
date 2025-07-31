// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CountryDto _$CountryDtoFromJson(Map<String, dynamic> json) => CountryDto(
      name: NameDto.fromJson(json['name'] as Map<String, dynamic>),
      capital:
          (json['capital'] as List<dynamic>?)?.map((e) => e as String).toList(),
      population: (json['population'] as num).toInt(),
      region: json['region'] as String,
      subregion: json['subregion'] as String?,
      area: (json['area'] as num?)?.toDouble(),
      flags: FlagsDto.fromJson(json['flags'] as Map<String, dynamic>),
      currencies: (json['currencies'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, CurrencyDto.fromJson(e as Map<String, dynamic>)),
      ),
      languages: (json['languages'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      timezones:
          (json['timezones'] as List<dynamic>).map((e) => e as String).toList(),
      maps: MapsDto.fromJson(json['maps'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CountryDtoToJson(CountryDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'capital': instance.capital,
      'population': instance.population,
      'region': instance.region,
      'subregion': instance.subregion,
      'area': instance.area,
      'flags': instance.flags,
      'currencies': instance.currencies,
      'languages': instance.languages,
      'timezones': instance.timezones,
      'maps': instance.maps,
    };

NameDto _$NameDtoFromJson(Map<String, dynamic> json) => NameDto(
      common: json['common'] as String,
      official: json['official'] as String,
      nativeName: (json['nativeName'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, NativeNameDto.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$NameDtoToJson(NameDto instance) => <String, dynamic>{
      'common': instance.common,
      'official': instance.official,
      'nativeName': instance.nativeName,
    };

NativeNameDto _$NativeNameDtoFromJson(Map<String, dynamic> json) =>
    NativeNameDto(
      official: json['official'] as String,
      common: json['common'] as String,
    );

Map<String, dynamic> _$NativeNameDtoToJson(NativeNameDto instance) =>
    <String, dynamic>{
      'official': instance.official,
      'common': instance.common,
    };

FlagsDto _$FlagsDtoFromJson(Map<String, dynamic> json) => FlagsDto(
      png: json['png'] as String?,
      svg: json['svg'] as String?,
    );

Map<String, dynamic> _$FlagsDtoToJson(FlagsDto instance) => <String, dynamic>{
      'png': instance.png,
      'svg': instance.svg,
    };

CurrencyDto _$CurrencyDtoFromJson(Map<String, dynamic> json) => CurrencyDto(
      name: json['name'] as String,
      symbol: json['symbol'] as String?,
    );

Map<String, dynamic> _$CurrencyDtoToJson(CurrencyDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'symbol': instance.symbol,
    };

MapsDto _$MapsDtoFromJson(Map<String, dynamic> json) => MapsDto(
      googleMaps: json['googleMaps'] as String?,
      openStreetMaps: json['openStreetMaps'] as String?,
    );

Map<String, dynamic> _$MapsDtoToJson(MapsDto instance) => <String, dynamic>{
      'googleMaps': instance.googleMaps,
      'openStreetMaps': instance.openStreetMaps,
    };
