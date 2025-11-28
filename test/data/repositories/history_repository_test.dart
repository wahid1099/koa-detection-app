import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:koa_detecion/data/repositories/history_repository.dart';
import 'package:koa_detecion/data/models/classification_result.dart';

void main() {
  // Initialize sqflite for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('HistoryRepository', () {
    late HistoryRepositoryImpl repository;

    setUp(() async {
      repository = HistoryRepositoryImpl();
      // Ensure clean state for each test
      final db = await repository.database;
      await db.delete('classification_history');
    });

    tearDown(() async {
      await repository.close();
    });

    test('save and getById should persist and retrieve a result', () async {
      // Arrange
      final result = ClassificationResult(
        id: 'test-id-1',
        imagePath: '/path/to/image.jpg',
        klGrade: 2,
        confidence: 0.85,
        gradCamPath: '/path/to/gradcam.jpg',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        allGradeConfidences: {0: 0.05, 1: 0.10, 2: 0.85, 3: 0.00, 4: 0.00},
      );

      // Act
      await repository.save(result);
      final retrieved = await repository.getById('test-id-1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('test-id-1'));
      expect(retrieved.imagePath, equals('/path/to/image.jpg'));
      expect(retrieved.klGrade, equals(2));
      expect(retrieved.confidence, equals(0.85));
      expect(retrieved.gradCamPath, equals('/path/to/gradcam.jpg'));
      expect(retrieved.timestamp, equals(DateTime(2024, 1, 15, 10, 30)));
      expect(retrieved.allGradeConfidences[2], equals(0.85));
    });

    test('getAll should return all saved results', () async {
      // Arrange
      final result1 = ClassificationResult(
        id: 'test-id-1',
        imagePath: '/path/to/image1.jpg',
        klGrade: 1,
        confidence: 0.75,
        gradCamPath: '/path/to/gradcam1.jpg',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        allGradeConfidences: {0: 0.10, 1: 0.75, 2: 0.15, 3: 0.00, 4: 0.00},
      );

      final result2 = ClassificationResult(
        id: 'test-id-2',
        imagePath: '/path/to/image2.jpg',
        klGrade: 3,
        confidence: 0.90,
        gradCamPath: '/path/to/gradcam2.jpg',
        timestamp: DateTime(2024, 1, 16, 14, 45),
        allGradeConfidences: {0: 0.00, 1: 0.05, 2: 0.05, 3: 0.90, 4: 0.00},
      );

      // Act
      await repository.save(result1);
      await repository.save(result2);
      final results = await repository.getAll();

      // Assert
      expect(results.length, equals(2));
      expect(results.any((r) => r.id == 'test-id-1'), isTrue);
      expect(results.any((r) => r.id == 'test-id-2'), isTrue);
    });

    test('delete should remove a result', () async {
      // Arrange
      final result = ClassificationResult(
        id: 'test-id-1',
        imagePath: '/path/to/image.jpg',
        klGrade: 2,
        confidence: 0.85,
        gradCamPath: '/path/to/gradcam.jpg',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        allGradeConfidences: {0: 0.05, 1: 0.10, 2: 0.85, 3: 0.00, 4: 0.00},
      );

      await repository.save(result);

      // Act
      await repository.delete('test-id-1');
      final retrieved = await repository.getById('test-id-1');

      // Assert
      expect(retrieved, isNull);
    });

    test('getById should return null for non-existent ID', () async {
      // Act
      final result = await repository.getById('non-existent-id');

      // Assert
      expect(result, isNull);
    });

    test('save with same ID should replace existing result', () async {
      // Arrange
      final result1 = ClassificationResult(
        id: 'test-id-1',
        imagePath: '/path/to/image1.jpg',
        klGrade: 1,
        confidence: 0.75,
        gradCamPath: '/path/to/gradcam1.jpg',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        allGradeConfidences: {0: 0.10, 1: 0.75, 2: 0.15, 3: 0.00, 4: 0.00},
      );

      final result2 = ClassificationResult(
        id: 'test-id-1',
        imagePath: '/path/to/image2.jpg',
        klGrade: 3,
        confidence: 0.90,
        gradCamPath: '/path/to/gradcam2.jpg',
        timestamp: DateTime(2024, 1, 16, 14, 45),
        allGradeConfidences: {0: 0.00, 1: 0.05, 2: 0.05, 3: 0.90, 4: 0.00},
      );

      // Act
      await repository.save(result1);
      await repository.save(result2);
      final results = await repository.getAll();
      final retrieved = await repository.getById('test-id-1');

      // Assert
      expect(results.length, equals(1));
      expect(retrieved!.klGrade, equals(3));
      expect(retrieved.confidence, equals(0.90));
    });
  });
}
