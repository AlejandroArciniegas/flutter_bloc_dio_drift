import 'package:euro_explorer/domain/entities/country.dart';
import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:euro_explorer/domain/repositories/countries_repository.dart';
import 'package:euro_explorer/domain/repositories/wishlist_repository.dart';
import 'package:euro_explorer/domain/usecases/manage_wishlist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWishlistRepository extends Mock implements WishlistRepository {}
class MockCountriesRepository extends Mock implements CountriesRepository {}

void main() {
  late MockWishlistRepository mockRepository;
  late MockCountriesRepository mockCountriesRepository;

  setUpAll(() {
    registerFallbackValue(
      WishlistItem(
        id: 'test',
        name: 'Test',
        flagUrl: 'test.svg',
        addedAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockRepository = MockWishlistRepository();
    mockCountriesRepository = MockCountriesRepository();
  });

  group('GetWishlistItems', () {
    late GetWishlistItems useCase;

    setUp(() {
      reset(mockRepository);
      useCase = GetWishlistItems(repository: mockRepository);
    });

    test('should return list of wishlist items from repository', () async {
      // Arrange
      final items = [
        WishlistItem(
          id: 'spain',
          name: 'Spain',
          flagUrl: 'https://flagcdn.com/es.svg',
          addedAt: DateTime(2024, 1, 15),
        ),
        WishlistItem(
          id: 'france',
          name: 'France',
          flagUrl: 'https://flagcdn.com/fr.svg',
          addedAt: DateTime(2024, 1, 16),
        ),
      ];

      when(() => mockRepository.getWishlistItems())
          .thenAnswer((_) async => items);

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(items));
      verify(() => mockRepository.getWishlistItems()).called(1);
    });

    test('should return empty list when repository returns empty list', () async {
      // Arrange
      when(() => mockRepository.getWishlistItems())
          .thenAnswer((_) async => []);

      // Act
      final result = await useCase();

      // Assert
      expect(result, isEmpty);
      verify(() => mockRepository.getWishlistItems()).called(1);
    });
  });

  group('AddToWishlist', () {
    late AddToWishlist useCase;

    setUp(() {
      reset(mockRepository);
      useCase = AddToWishlist(repository: mockRepository);
    });

    test('should add item to wishlist when not already present', () async {
      // Arrange
      final item = WishlistItem(
        id: 'spain',
        name: 'Spain',
        flagUrl: 'https://flagcdn.com/es.svg',
        addedAt: DateTime(2024, 1, 15),
      );

      when(() => mockRepository.isInWishlist(item.id))
          .thenAnswer((_) async => false);
      when(() => mockRepository.addToWishlist(item))
          .thenAnswer((_) async {});

      // Act
      await useCase(item);

      // Assert
      verify(() => mockRepository.isInWishlist(item.id)).called(1);
      verify(() => mockRepository.addToWishlist(item)).called(1);
    });

    test('should throw WishlistException when item already in wishlist', () async {
      // Arrange
      final item = WishlistItem(
        id: 'spain',
        name: 'Spain',
        flagUrl: 'https://flagcdn.com/es.svg',
        addedAt: DateTime(2024, 1, 15),
      );

      when(() => mockRepository.isInWishlist(item.id))
          .thenAnswer((_) async => true);

      // Act & Assert
      expect(() => useCase(item), throwsA(isA<WishlistException>()));
      verify(() => mockRepository.isInWishlist(item.id)).called(1);
      verifyNever(() => mockRepository.addToWishlist(any()));
    });
  });

  group('RemoveFromWishlist', () {
    late RemoveFromWishlist useCase;

    setUp(() {
      reset(mockRepository);
      useCase = RemoveFromWishlist(repository: mockRepository);
    });

    test('should remove item from wishlist', () async {
      // Arrange
      const countryId = 'spain';
      when(() => mockRepository.removeFromWishlist(countryId))
          .thenAnswer((_) async {});

      // Act
      await useCase(countryId);

      // Assert
      verify(() => mockRepository.removeFromWishlist(countryId)).called(1);
    });

    test('should throw ArgumentError when country ID is empty', () async {
      // Act & Assert
      expect(() => useCase(''), throwsArgumentError);
      verifyNever(() => mockRepository.removeFromWishlist(any()));
    });
  });

  group('IsInWishlist', () {
    late IsInWishlist useCase;

    setUp(() {
      reset(mockRepository);
      useCase = IsInWishlist(repository: mockRepository);
    });

    test('should return true when item is in wishlist', () async {
      // Arrange
      const countryId = 'spain';
      when(() => mockRepository.isInWishlist(countryId))
          .thenAnswer((_) async => true);

      // Act
      final result = await useCase(countryId);

      // Assert
      expect(result, isTrue);
      verify(() => mockRepository.isInWishlist(countryId)).called(1);
    });

    test('should return false when item is not in wishlist', () async {
      // Arrange
      const countryId = 'spain';
      when(() => mockRepository.isInWishlist(countryId))
          .thenAnswer((_) async => false);

      // Act
      final result = await useCase(countryId);

      // Assert
      expect(result, isFalse);
      verify(() => mockRepository.isInWishlist(countryId)).called(1);
    });

    test('should return false when country ID is empty', () async {
      // Act
      final result = await useCase('');

      // Assert
      expect(result, isFalse);
      verifyNever(() => mockRepository.isInWishlist(any()));
    });
  });

  group('PerformWishlistStressTest', () {
    late PerformWishlistStressTest useCase;

    setUp(() {
      reset(mockRepository);
      reset(mockCountriesRepository);
      useCase = PerformWishlistStressTest(
        repository: mockRepository,
        countriesRepository: mockCountriesRepository,
      );
    });

    test('should clear wishlist and fetch European countries and add them to repository', () async {
      // Arrange
      const mockCountries = [
        Country(
          name: 'Germany',
          capital: 'Berlin',
          population: 83783942,
          region: 'Europe',
          subregion: 'Central Europe',
          area: 357022,
          flagUrl: 'https://flagcdn.com/w320/de.png',
          nativeNames: {'deu': 'Deutschland'},
          languages: {'German': 'German'},
          currencies: {'EUR': 'Euro'},
          timezones: ['UTC+01:00'],
          mapsUrl: 'https://maps.google.com/germany',
        ),
        Country(
          name: 'France',
          capital: 'Paris',
          population: 65273511,
          region: 'Europe',
          subregion: 'Western Europe',
          area: 551695,
          flagUrl: 'https://flagcdn.com/w320/fr.png',
          nativeNames: {'fra': 'France'},
          languages: {'French': 'French'},
          currencies: {'EUR': 'Euro'},
          timezones: ['UTC+01:00'],
          mapsUrl: 'https://maps.google.com/france',
        ),
      ];

      when(() => mockCountriesRepository.getEuropeanCountries())
          .thenAnswer((_) async => mockCountries);
      when(() => mockRepository.clearWishlist())
          .thenAnswer((_) async {});
      when(() => mockRepository.addAllStressTest(any()))
          .thenAnswer((_) async {});

      // Act
      await useCase();

      // Assert
      verify(() => mockRepository.clearWishlist()).called(1);
      final captured = verify(() => mockRepository.addAllStressTest(captureAny()))
          .captured.single as List<WishlistItem>;
      
      expect(captured.length, equals(2));
      expect(captured[0].name, equals('Germany'));
      expect(captured[0].flagUrl, equals('https://flagcdn.com/w320/de.png'));
      expect(captured[1].name, equals('France'));
      expect(captured[1].flagUrl, equals('https://flagcdn.com/w320/fr.png'));
    });

    test('should handle countries repository errors', () async {
      // Arrange
      when(() => mockRepository.clearWishlist())
          .thenAnswer((_) async {});
      when(() => mockCountriesRepository.getEuropeanCountries())
          .thenThrow(Exception('Failed to fetch countries'));

      // Act & Assert
      expect(() => useCase(), throwsException);
      verify(() => mockRepository.clearWishlist()).called(1);
      verifyNever(() => mockRepository.addAllStressTest(any()));
    });

    test('should convert countries to wishlist items correctly', () async {
      // Arrange
      const mockCountries = [
        Country(
          name: 'Spain',
          capital: 'Madrid',
          population: 46754778,
          region: 'Europe',
          subregion: 'Southern Europe',
          area: 505992,
          flagUrl: 'https://flagcdn.com/w320/es.png',
          nativeNames: {'spa': 'España'},
          languages: {'Spanish': 'Spanish'},
          currencies: {'EUR': 'Euro'},
          timezones: ['UTC+01:00'],
          mapsUrl: 'https://maps.google.com/spain',
        ),
      ];

      when(() => mockRepository.clearWishlist())
          .thenAnswer((_) async {});
      when(() => mockCountriesRepository.getEuropeanCountries())
          .thenAnswer((_) async => mockCountries);
      when(() => mockRepository.addAllStressTest(any()))
          .thenAnswer((_) async {});

      // Act
      await useCase();

      // Assert
      verify(() => mockRepository.clearWishlist()).called(1);
      final captured = verify(() => mockRepository.addAllStressTest(captureAny()))
          .captured.single as List<WishlistItem>;
      
      expect(captured.length, equals(1));
      expect(captured[0].id, equals('Spain'));
      expect(captured[0].name, equals('Spain'));
      expect(captured[0].flagUrl, equals('https://flagcdn.com/w320/es.png'));
    });

    test('should handle empty countries list', () async {
      // Arrange
      when(() => mockRepository.clearWishlist())
          .thenAnswer((_) async {});
      when(() => mockCountriesRepository.getEuropeanCountries())
          .thenAnswer((_) async => []);
      when(() => mockRepository.addAllStressTest(any()))
          .thenAnswer((_) async {});

      // Act
      await useCase();

      // Assert
      verify(() => mockRepository.clearWishlist()).called(1);
      final captured = verify(() => mockRepository.addAllStressTest(captureAny()))
          .captured.single as List<WishlistItem>;
      
      expect(captured, isEmpty);
    });
  });
}
