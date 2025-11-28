import 'package:flutter_test/flutter_test.dart';
import 'package:koa_detecion/data/models/classification_result.dart';
import 'package:koa_detecion/data/repositories/history_repository.dart';
import 'package:koa_detecion/domain/use_cases/get_history_use_case.dart';

void main() {
  group('GetHistoryUseCase', () {
    late GetHistoryUseCase useCase;
    late MockHistoryRepository mockRepository;

    setUp(() {
      mockRepository = MockHistoryRepository();
      useCase = GetHistoryUseCase(mockRepository);
    });

    group('History Chronological Ordering', () {
      // Feature: koa-detection-app, Property 15: History chronological ordering
      // Validates: Requirements 6.2
      test(
        'Property 15: For any set of history entries, they should be ordered by timestamp descending',
        () async {
          // Generate test data with various timestamp orderings
          final testScenarios = [
            // Scenario 1: Already sorted
            _generateResultsWithTimestamps([
              DateTime(2024, 3, 1),
              DateTime(2024, 2, 1),
              DateTime(2024, 1, 1),
            ]),
            // Scenario 2: Reverse sorted
            _generateResultsWithTimestamps([
              DateTime(2024, 1, 1),
              DateTime(2024, 2, 1),
              DateTime(2024, 3, 1),
            ]),
            // Scenario 3: Random order
            _generateResultsWithTimestamps([
              DateTime(2024, 2, 15),
              DateTime(2024, 1, 10),
              DateTime(2024, 3, 20),
              DateTime(2024, 2, 1),
            ]),
            // Scenario 4: Same day, different times
            _generateResultsWithTimestamps([
              DateTime(2024, 1, 1, 10, 0),
              DateTime(2024, 1, 1, 14, 30),
              DateTime(2024, 1, 1, 9, 15),
            ]),
            // Scenario 5: Single entry
            _generateResultsWithTimestamps([DateTime(2024, 1, 1)]),
            // Scenario 6: Empty list
            <ClassificationResult>[],
          ];

          for (final scenario in testScenarios) {
            mockRepository.setResults(scenario);

            final results = await useCase.execute();

            // Verify results are sorted in descending order (newest first)
            for (int i = 0; i < results.length - 1; i++) {
              final current = results[i].timestamp;
              final next = results[i + 1].timestamp;

              expect(
                current.isAfter(next) || current.isAtSameMomentAs(next),
                true,
                reason:
                    'Entry at index $i (${current}) should be >= entry at ${i + 1} (${next})',
              );
            }
          }
        },
      );

      test(
        'Property 15: Ordering is stable for entries with same timestamp',
        () async {
          // Create entries with identical timestamps
          final sameTime = DateTime(2024, 1, 1, 12, 0);
          final results = [
            ClassificationResult(
              id: 'id-1',
              imagePath: '/path/1.jpg',
              klGrade: 0,
              confidence: 0.9,
              gradCamPath: '/gradcam/1.jpg',
              timestamp: sameTime,
              allGradeConfidences: {0: 0.9, 1: 0.1, 2: 0.0, 3: 0.0, 4: 0.0},
            ),
            ClassificationResult(
              id: 'id-2',
              imagePath: '/path/2.jpg',
              klGrade: 1,
              confidence: 0.8,
              gradCamPath: '/gradcam/2.jpg',
              timestamp: sameTime,
              allGradeConfidences: {0: 0.1, 1: 0.8, 2: 0.1, 3: 0.0, 4: 0.0},
            ),
          ];

          mockRepository.setResults(results);

          final sorted = await useCase.execute();

          // All entries should have the same timestamp
          for (final result in sorted) {
            expect(result.timestamp, sameTime);
          }
        },
      );

      test('Property 15: Ordering handles millisecond precision', () async {
        final baseTime = DateTime(2024, 1, 1, 12, 0, 0);
        final results = _generateResultsWithTimestamps([
          baseTime.add(Duration(milliseconds: 100)),
          baseTime.add(Duration(milliseconds: 50)),
          baseTime.add(Duration(milliseconds: 200)),
          baseTime,
        ]);

        mockRepository.setResults(results);

        final sorted = await useCase.execute();

        // Verify precise ordering
        expect(sorted[0].timestamp, baseTime.add(Duration(milliseconds: 200)));
        expect(sorted[1].timestamp, baseTime.add(Duration(milliseconds: 100)));
        expect(sorted[2].timestamp, baseTime.add(Duration(milliseconds: 50)));
        expect(sorted[3].timestamp, baseTime);
      });
    });
  });
}

/// Generates classification results with specified timestamps
List<ClassificationResult> _generateResultsWithTimestamps(
  List<DateTime> timestamps,
) {
  return timestamps.asMap().entries.map((entry) {
    final index = entry.key;
    final timestamp = entry.value;

    return ClassificationResult(
      id: 'test-$index',
      imagePath: '/path/to/image$index.jpg',
      klGrade: index % 5,
      confidence: 0.8 + (index % 3) * 0.05,
      gradCamPath: '/path/to/gradcam$index.jpg',
      timestamp: timestamp,
      allGradeConfidences: {0: 0.2, 1: 0.2, 2: 0.2, 3: 0.2, 4: 0.2},
    );
  }).toList();
}

/// Mock implementation of HistoryRepository for testing
class MockHistoryRepository implements HistoryRepository {
  List<ClassificationResult> _results = [];
  Exception? _error;

  void setResults(List<ClassificationResult> results) {
    _results = results;
    _error = null;
  }

  void setError(Exception error) {
    _error = error;
    _results = [];
  }

  @override
  Future<List<ClassificationResult>> getAll() async {
    if (_error != null) {
      throw _error!;
    }
    return List.from(_results);
  }

  @override
  Future<void> save(ClassificationResult result) async {
    _results.add(result);
  }

  @override
  Future<void> delete(String id) async {
    _results.removeWhere((r) => r.id == id);
  }

  @override
  Future<ClassificationResult?> getById(String id) async {
    try {
      return _results.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
