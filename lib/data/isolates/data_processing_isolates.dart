import 'package:euro_explorer/data/models/country_dto.dart';
import 'package:euro_explorer/domain/entities/country.dart';
import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:flutter/foundation.dart';

/// Utilities for processing data in isolates to prevent UI blocking
class DataProcessingIsolates {
  /// Convert list of CountryDto to Country entities in an isolate
  static Future<List<Country>> convertCountriesDtoToDomain(
    List<CountryDto> countriesDto,
  ) async {
    if (countriesDto.isEmpty) return [];
    
    // For smaller lists (< 20), process on main thread to avoid isolate overhead
    if (countriesDto.length < 20) {
      return countriesDto.map((dto) => dto.toDomain()).toList();
    }
    
    // Use compute for heavy processing to move to isolate
    return compute(_convertCountriesDtoToDomainIsolate, countriesDto);
  }
  
  /// Convert CountryDto list to WishlistItem list in an isolate
  static Future<List<WishlistItem>> convertCountriesToWishlistItems(
    List<Country> countries,
  ) async {
    if (countries.isEmpty) return [];
    
    // For smaller lists, process on main thread
    if (countries.length < 20) {
      return _convertCountriesToWishlistItemsSync(countries);
    }
    
    // Use compute for heavy processing
    return compute(_convertCountriesToWishlistItemsIsolate, countries);
  }
  
  /// Process batch operations in chunks within an isolate
  static Future<List<List<T>>> chunkDataForBatchProcessing<T>(
    List<T> data, {
    int chunkSize = 500,
  }) async {
    if (data.isEmpty) return [];
    
    // For small datasets, return single chunk
    if (data.length <= chunkSize) {
      return [data];
    }
    
    // Use compute for large chunking operations
    return compute(_chunkDataIsolate<T>, _ChunkingData<T>(data, chunkSize));
  }
  
  /// Batch check wishlist status in optimized chunks
  static Future<Map<String, bool>> optimizedBatchCheck(
    List<String> countryIds,
    Future<Map<String, bool>> Function(List<String>) checkFunction,
  ) async {
    if (countryIds.isEmpty) return {};
    
    // For small lists, process directly
    if (countryIds.length <= 50) {
      return checkFunction(countryIds);
    }
    
    // Process in parallel chunks for large lists
    const chunkSize = 25;
    final chunks = <List<String>>[];
    
    for (var i = 0; i < countryIds.length; i += chunkSize) {
      chunks.add(
        countryIds.skip(i).take(chunkSize).toList(),
      );
    }
    
    // Process chunks in parallel
    final futures = chunks.map((chunk) => checkFunction(chunk));
    final results = await Future.wait(futures);
    
    // Merge results
    final mergedResults = <String, bool>{};
    for (final result in results) {
      mergedResults.addAll(result);
    }
    
    return mergedResults;
  }
}

/// Isolate function for converting CountryDto to Country
List<Country> _convertCountriesDtoToDomainIsolate(List<CountryDto> countriesDto) {
  return countriesDto.map((dto) => dto.toDomain()).toList();
}

/// Isolate function for converting Countries to WishlistItems
List<WishlistItem> _convertCountriesToWishlistItemsIsolate(List<Country> countries) {
  return _convertCountriesToWishlistItemsSync(countries);
}

/// Synchronous conversion helper
List<WishlistItem> _convertCountriesToWishlistItemsSync(List<Country> countries) {
  final now = DateTime.now();
  return countries.map((country) {
    return WishlistItem(
      id: country.name,
      name: country.name,
      flagUrl: country.flagUrl,
      addedAt: now,
    );
  }).toList();
}

/// Data class for chunking operations
class _ChunkingData<T> {
  const _ChunkingData(this.data, this.chunkSize);
  
  final List<T> data;
  final int chunkSize;
}

/// Isolate function for chunking data
List<List<T>> _chunkDataIsolate<T>(_ChunkingData<T> input) {
  final chunks = <List<T>>[];
  final data = input.data;
  final chunkSize = input.chunkSize;
  
  for (var i = 0; i < data.length; i += chunkSize) {
    chunks.add(data.skip(i).take(chunkSize).toList());
  }
  
  return chunks;
}

/// Optimized data processing configuration
class ProcessingConfig {
  const ProcessingConfig({
    this.useIsolatesForHeavyOperations = true,
    this.isolateThreshold = 20,
    this.batchChunkSize = 500,
    this.parallelChunkSize = 25,
    this.delayBetweenChunks = const Duration(milliseconds: 5),
  });
  
  final bool useIsolatesForHeavyOperations;
  final int isolateThreshold;
  final int batchChunkSize;
  final int parallelChunkSize;
  final Duration delayBetweenChunks;
  
  static const ProcessingConfig optimized = ProcessingConfig(
    isolateThreshold: 15,
    batchChunkSize: 300,
    parallelChunkSize: 20,
    delayBetweenChunks: Duration(milliseconds: 3),
  );
  
  static const ProcessingConfig standard = ProcessingConfig();
}
