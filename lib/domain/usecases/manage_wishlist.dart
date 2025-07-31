import 'package:euro_explorer/data/isolates/data_processing_isolates.dart';
import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:euro_explorer/domain/repositories/countries_repository.dart';
import 'package:euro_explorer/domain/repositories/wishlist_repository.dart';

/// Use case for getting wishlist items
class GetWishlistItems {
  const GetWishlistItems({
    required WishlistRepository repository,
  }) : _repository = repository;

  final WishlistRepository _repository;

  /// Execute the use case
  Future<List<WishlistItem>> call() async {
    return _repository.getWishlistItems();
  }
}

/// Use case for adding item to wishlist
class AddToWishlist {
  const AddToWishlist({
    required WishlistRepository repository,
  }) : _repository = repository;

  final WishlistRepository _repository;

  /// Execute the use case
  Future<void> call(WishlistItem item) async {
    // Check if item is already in wishlist
    final isAlreadyInWishlist = await _repository.isInWishlist(item.id);
    if (isAlreadyInWishlist) {
      throw const WishlistException('Item is already in wishlist');
    }

    await _repository.addToWishlist(item);
  }
}

/// Use case for removing item from wishlist
class RemoveFromWishlist {
  const RemoveFromWishlist({
    required WishlistRepository repository,
  }) : _repository = repository;

  final WishlistRepository _repository;

  /// Execute the use case
  Future<void> call(String countryId) async {
    if (countryId.isEmpty) {
      throw ArgumentError('Country ID cannot be empty');
    }

    await _repository.removeFromWishlist(countryId);
  }
}

/// Use case for checking if item is in wishlist
class IsInWishlist {
  const IsInWishlist({
    required WishlistRepository repository,
  }) : _repository = repository;

  final WishlistRepository _repository;

  /// Execute the use case
  Future<bool> call(String countryId) async {
    if (countryId.isEmpty) {
      return false;
    }

    return _repository.isInWishlist(countryId);
  }
}

/// Use case for batch checking wishlist status (optimized for multiple countries)
class BatchCheckWishlistStatus {
  const BatchCheckWishlistStatus({
    required WishlistRepository repository,
  }) : _repository = repository;

  final WishlistRepository _repository;

  /// Execute the use case
  Future<Map<String, bool>> call(List<String> countryIds) async {
    if (countryIds.isEmpty) {
      return {};
    }

    return _repository.batchCheckWishlistStatus(countryIds);
  }
}

/// Use case for clearing all wishlist items
class ClearWishlist {
  const ClearWishlist({
    required WishlistRepository repository,
  }) : _repository = repository;

  final WishlistRepository _repository;

  /// Execute the use case
  Future<void> call() async {
    await _repository.clearWishlist();
  }
}

/// Use case for performing stress test
class PerformWishlistStressTest {
  const PerformWishlistStressTest({
    required WishlistRepository repository,
    required CountriesRepository countriesRepository,
  }) : _repository = repository,
       _countriesRepository = countriesRepository;

  final WishlistRepository _repository;
  final CountriesRepository _countriesRepository;

  /// Execute the use case - add all European countries to wishlist
  Future<void> call() async {
    // Clear existing wishlist before stress test to avoid duplicates
    await _repository.clearWishlist();
    
    // Fetch all European countries (already optimized with isolates)
    final countries = await _countriesRepository.getEuropeanCountries();
    
    // Convert countries to wishlist items using isolate for heavy processing
    final wishlistItems = await DataProcessingIsolates.convertCountriesToWishlistItems(countries);

    await _repository.addAllStressTest(wishlistItems);
  }
}

/// Custom exception for wishlist operations
class WishlistException implements Exception {
  const WishlistException(this.message);

  final String message;

  @override
  String toString() => 'WishlistException: $message';
}
