import 'package:flutter_test/flutter_test.dart';
import 'package:koa_detecion/data/models/classification_result.dart';

void main() {
  group('ClassificationResult', () {
    // Feature: koa-detection-app, Property 8: API response parsing completeness
    // For any valid API response, parsing should successfully extract KL grade,
    // confidence score, and Grad-CAM data without loss.
    test('property: serialization round-trip preserves all data', () {
      // Run 100 iterations with different data
      for (int i = 0; i < 100; i++) {
        // Generate test data with varying values
        final originalResult = ClassificationResult(
          id: 'test-id-$i',
          imagePath: '/path/to/image$i.jpg',
          klGrade: i % 5, // KL grades are 0-4
          confidence: (i % 100) / 100.0, // Confidence 0.0-1.0
          gradCamPath: '/path/to/gradcam$i.jpg',
          timestamp: DateTime.now().add(Duration(minutes: i)),
          allGradeConfidences: {
            0: (i % 20) / 100.0,
            1: ((i + 20) % 30) / 100.0,
            2: ((i + 40) % 40) / 100.0,
            3: ((i + 60) % 50) / 100.0,
            4: ((i + 80) % 60) / 100.0,
          },
        );

        // Serialize to JSON
        final json = originalResult.toJson();

        // Deserialize from JSON
        final deserializedResult = ClassificationResult.fromJson(json);

        // Verify all fields are preserved
        expect(
          deserializedResult.id,
          equals(originalResult.id),
          reason: 'ID should be preserved',
        );
        expect(
          deserializedResult.imagePath,
          equals(originalResult.imagePath),
          reason: 'Image path should be preserved',
        );
        expect(
          deserializedResult.klGrade,
          equals(originalResult.klGrade),
          reason: 'KL grade should be preserved',
        );
        expect(
          deserializedResult.confidence,
          equals(originalResult.confidence),
          reason: 'Confidence should be preserved',
        );
        expect(
          deserializedResult.gradCamPath,
          equals(originalResult.gradCamPath),
          reason: 'Grad-CAM path should be preserved',
        );
        expect(
          deserializedResult.timestamp.millisecondsSinceEpoch,
          equals(originalResult.timestamp.millisecondsSinceEpoch),
          reason: 'Timestamp should be preserved',
        );
        expect(
          deserializedResult.allGradeConfidences,
          equals(originalResult.allGradeConfidences),
          reason: 'All grade confidences should be preserved',
        );
      }
    });

    test('property: handles edge case KL grades (0 and 4)', () {
      final testCases = [
        ClassificationResult(
          id: 'edge-0',
          imagePath: '/test.jpg',
          klGrade: 0,
          confidence: 0.0,
          gradCamPath: '/gradcam.jpg',
          timestamp: DateTime.now(),
          allGradeConfidences: {0: 1.0, 1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0},
        ),
        ClassificationResult(
          id: 'edge-4',
          imagePath: '/test.jpg',
          klGrade: 4,
          confidence: 1.0,
          gradCamPath: '/gradcam.jpg',
          timestamp: DateTime.now(),
          allGradeConfidences: {0: 0.0, 1: 0.0, 2: 0.0, 3: 0.0, 4: 1.0},
        ),
      ];

      for (final original in testCases) {
        final json = original.toJson();
        final deserialized = ClassificationResult.fromJson(json);

        expect(deserialized.klGrade, equals(original.klGrade));
        expect(deserialized.confidence, equals(original.confidence));
      }
    });

    test('property: handles various timestamp formats', () {
      final timestamps = [
        DateTime(2024, 1, 1),
        DateTime(2024, 12, 31, 23, 59, 59),
        DateTime.now(),
        DateTime.now().subtract(Duration(days: 365)),
      ];

      for (final timestamp in timestamps) {
        final result = ClassificationResult(
          id: 'test',
          imagePath: '/test.jpg',
          klGrade: 2,
          confidence: 0.85,
          gradCamPath: '/gradcam.jpg',
          timestamp: timestamp,
          allGradeConfidences: {0: 0.1, 1: 0.2, 2: 0.85, 3: 0.05, 4: 0.0},
        );

        final json = result.toJson();
        final deserialized = ClassificationResult.fromJson(json);

        expect(
          deserialized.timestamp.millisecondsSinceEpoch,
          equals(timestamp.millisecondsSinceEpoch),
        );
      }
    });

    test('property: handles empty and special characters in paths', () {
      final pathTestCases = [
        '/simple/path.jpg',
        '/path with spaces/image.jpg',
        '/path/with/unicode/图片.jpg',
        '/path-with-dashes/image_with_underscores.jpg',
      ];

      for (final path in pathTestCases) {
        final result = ClassificationResult(
          id: 'test',
          imagePath: path,
          klGrade: 1,
          confidence: 0.75,
          gradCamPath: path.replaceAll('.jpg', '_gradcam.jpg'),
          timestamp: DateTime.now(),
          allGradeConfidences: {0: 0.1, 1: 0.75, 2: 0.1, 3: 0.05, 4: 0.0},
        );

        final json = result.toJson();
        final deserialized = ClassificationResult.fromJson(json);

        expect(deserialized.imagePath, equals(path));
        expect(deserialized.gradCamPath, contains('gradcam'));
      }
    });

    test('property: confidence values maintain precision', () {
      final confidenceValues = [0.0, 0.123456789, 0.5, 0.999999999, 1.0];

      for (final confidence in confidenceValues) {
        final result = ClassificationResult(
          id: 'test',
          imagePath: '/test.jpg',
          klGrade: 2,
          confidence: confidence,
          gradCamPath: '/gradcam.jpg',
          timestamp: DateTime.now(),
          allGradeConfidences: {0: 0.1, 1: 0.2, 2: confidence, 3: 0.05, 4: 0.0},
        );

        final json = result.toJson();
        final deserialized = ClassificationResult.fromJson(json);

        expect(deserialized.confidence, closeTo(confidence, 0.0000001));
      }
    });

    test('copyWith creates new instance with updated fields', () {
      final original = ClassificationResult(
        id: 'original',
        imagePath: '/original.jpg',
        klGrade: 1,
        confidence: 0.5,
        gradCamPath: '/gradcam.jpg',
        timestamp: DateTime.now(),
        allGradeConfidences: {0: 0.1, 1: 0.5, 2: 0.2, 3: 0.1, 4: 0.1},
      );

      final updated = original.copyWith(klGrade: 3, confidence: 0.9);

      expect(updated.id, equals(original.id));
      expect(updated.klGrade, equals(3));
      expect(updated.confidence, equals(0.9));
      expect(updated.imagePath, equals(original.imagePath));
    });

    test('equality operator works correctly', () {
      final timestamp = DateTime.now();
      final result1 = ClassificationResult(
        id: 'test',
        imagePath: '/test.jpg',
        klGrade: 2,
        confidence: 0.85,
        gradCamPath: '/gradcam.jpg',
        timestamp: timestamp,
        allGradeConfidences: {0: 0.1, 1: 0.2, 2: 0.85, 3: 0.05, 4: 0.0},
      );

      final result2 = ClassificationResult(
        id: 'test',
        imagePath: '/test.jpg',
        klGrade: 2,
        confidence: 0.85,
        gradCamPath: '/gradcam.jpg',
        timestamp: timestamp,
        allGradeConfidences: {0: 0.1, 1: 0.2, 2: 0.85, 3: 0.05, 4: 0.0},
      );

      final result3 = ClassificationResult(
        id: 'different',
        imagePath: '/test.jpg',
        klGrade: 2,
        confidence: 0.85,
        gradCamPath: '/gradcam.jpg',
        timestamp: timestamp,
        allGradeConfidences: {0: 0.1, 1: 0.2, 2: 0.85, 3: 0.05, 4: 0.0},
      );

      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
    });
  });
}
