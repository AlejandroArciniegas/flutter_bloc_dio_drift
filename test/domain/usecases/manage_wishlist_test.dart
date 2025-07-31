import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:euro_explorer/domain/repositories/wishlist_repository.dart';
import 'package:euro_explorer/domain/usecases/manage_wishlist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWishlistRepository extends Mock implements WishlistRepository {}

void main() {
  late MockWishlistRepository mockRepository;

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
      useCase = PerformWishlistStressTest(repository: mockRepository);
    });

    test('should generate and add 5000 fake items to repository', () async {
      // Arrange
      when(() => mockRepository.addAllStressTest(any()))
          .thenAnswer((_) async {});

      // Act
      await useCase();

      // Assert
      final captured = verify(() => mockRepository.addAllStressTest(captureAny()))
          .captured.single as List<WishlistItem>;
      
      expect(captured.length, equals(5000));
      expect(captured.first.id, startsWith('stress_test_'));
      expect(captured.first.name, startsWith('Test Country '));
      expect(captured.first.flagUrl, contains('flag0.png'));
    });

    test('should generate items with sequential IDs and names', () async {
      // Arrange
      when(() => mockRepository.addAllStressTest(any()))
          .thenAnswer((_) async {});

      // Act
      await useCase();

      // Assert
      final captured = verify(() => mockRepository.addAllStressTest(captureAny()))
          .captured.single as List<WishlistItem>;
      
      expect(captured[0].id, equals('stress_test_0'));
      expect(captured[0].name, equals('Test Country 0'));
      expect(captured[100].id, equals('stress_test_100'));
      expect(captured[100].name, equals('Test Country 100'));
      expect(captured[4999].id, equals('stress_test_4999'));
      expect(captured[4999].name, equals('Test Country 4999'));
    });

    test('should generate items with decreasing timestamps', () async {
      // Arrange
      when(() => mockRepository.addAllStressTest(any()))
          .thenAnswer((_) async {});

      // Act
      await useCase();

      // Assert
      final captured = verify(() => mockRepository.addAllStressTest(captureAny()))
          .captured.single as List<WishlistItem>;
      
      // First item should have a more recent timestamp than later items
      expect(captured[0].addedAt.isAfter(captured[1].addedAt), isTrue);
      expect(captured[1].addedAt.isAfter(captured[2].addedAt), isTrue);
    });
  });
}