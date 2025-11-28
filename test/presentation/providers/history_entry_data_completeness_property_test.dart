import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

import 'package:koa_detecion/presentation/providers/history_provider.dart';
import 'package:koa_detecion/domain/use_cases/get_history_use_case.dart';
import 'package:koa_detecion/domain/use_cases/delete_history_entry_use_case.dart';
import 'package:koa_detecion/data/models/classification_result.dart';

// Mock implementations for testing
class MockGetHistoryUseCase implements GetHistoryUseCase {
  final Future<List<ClassificationResult>> Function() _executeImpl;
  MockGetHistoryUseCase(this._executeImpl);

  @override
  Future<List<ClassificationResult>> execute() => _executeImpl();
}

class MockDeleteHistoryEntryUseCase implements DeleteHistoryEntryUseCase {
  final Future<void> Function(String) _executeImpl;
  MockDeleteHistoryEntryUseCase(this._executeImpl);

  @override
  Future<void> execute(String id) => _executeImpl(id);
}

void main() {
  group('History Entry Data Completeness Property Tests', () {
    test('Property 16: History entry data completeness - '
        'For any history entry displayed, it should include thumbnail image, KL grade, confidence score, and timestamp', () async {
      // **Feature: koa-detection-app, Property 16: History entry data completeness**
      // **Validates: Requirements 6.3**

      final random = Random();

      // Run property test with multiple iterations
      for (int i = 0; i < 100; i++) {
        // Generate random number of history entries
        final entryCount = random.nextInt(20) + 1; // 1-20 entries
        final historyEntries = <ClassificationResult>[];

        // Generate random history entries
        for (int j = 0; j < entryCount; j++) {
          final entry = ClassificationResult(
            id: 'entry_${i}_$j',
            imagePath: 'image_${i}_$j.jpg', // This serves as thumbnail path
            klGrade: random.nextInt(5), // KL grades 0-4
            confidence: random.nextDouble(), // Confidence score 0.0-1.0
            gradCamPath: 'gradcam_${i}_$j.png',
            timestamp: DateTime.now().subtract(
              Duration(days: random.nextInt(365)),
            ), // Random timestamp within last year
            allGradeConfidences: {
              0: random.nextDouble(),
              1: random.nextDouble(),
              2: random.nextDouble(),
              3: random.nextDouble(),
              4: random.nextDouble(),
            },
          );
          historyEntries.add(entry);
        }

        // Create mock use cases
        final mockGetHistoryUseCase = MockGetHistoryUseCase(
          () async => historyEntries,
        );
        final mockDeleteHistoryEntryUseCase = MockDeleteHistoryEntryUseCase(
          (_) async {},
        );

        final provider = HistoryProvider(
          mockGetHistoryUseCase,
          mockDeleteHistoryEntryUseCase,
        );

        // Load history
        await provider.loadHistory();

        // Verify all entries have complete data
        final loadedEntries = provider.historyEntries;
        expect(
          loadedEntries.length,
          equals(entryCount),
          reason: 'Should load all history entries (iteration $i)',
        );

        for (int j = 0; j < loadedEntries.length; j++) {
          final entry = loadedEntries[j];

          // Verify thumbnail image path is present and not empty
          expect(
            entry.imagePath,
            isNotNull,
            reason: 'Entry $j should have non-null image path (iteration $i)',
          );
          expect(
            entry.imagePath,
            isNotEmpty,
            reason: 'Entry $j should have non-empty image path (iteration $i)',
          );

          // Verify KL grade is present and valid (0-4)
          expect(
            entry.klGrade,
            isNotNull,
            reason: 'Entry $j should have non-null KL grade (iteration $i)',
          );
          expect(
            entry.klGrade,
            inInclusiveRange(0, 4),
            reason: 'Entry $j should have valid KL grade 0-4 (iteration $i)',
          );

          // Verify confidence score is present and valid (0.0-1.0)
          expect(
            entry.confidence,
            isNotNull,
            reason:
                'Entry $j should have non-null confidence score (iteration $i)',
          );
          expect(
            entry.confidence,
            inInclusiveRange(0.0, 1.0),
            reason:
                'Entry $j should have valid confidence score 0.0-1.0 (iteration $i)',
          );

          // Verify timestamp is present and not null
          expect(
            entry.timestamp,
            isNotNull,
            reason: 'Entry $j should have non-null timestamp (iteration $i)',
          );
          expect(
            entry.timestamp,
            isA<DateTime>(),
            reason:
                'Entry $j should have valid DateTime timestamp (iteration $i)',
          );

          // Verify timestamp is reasonable (not in the future, not too far in the past)
          final now = DateTime.now();
          final oneYearAgo = now.subtract(const Duration(days: 365));
          expect(
            entry.timestamp.isBefore(now.add(const Duration(minutes: 1))),
            true,
            reason:
                'Entry $j timestamp should not be in the future (iteration $i)',
          );
          expect(
            entry.timestamp.isAfter(
              oneYearAgo.subtract(const Duration(days: 1)),
            ),
            true,
            reason:
                'Entry $j timestamp should not be too far in the past (iteration $i)',
          );
        }
      }
    });

    test('Property 16 (Entry Accessibility): History entries provide all required display data - '
        'For any history entry, all required display fields should be accessible and properly formatted', () async {
      // **Feature: koa-detection-app, Property 16: History entry data completeness**
      // **Validates: Requirements 6.3**

      final random = Random();

      // Run property test with multiple iterations
      for (int i = 0; i < 100; i++) {
        // Generate random history entries with edge cases
        final entryCount = random.nextInt(10) + 1; // 1-10 entries
        final historyEntries = <ClassificationResult>[];

        for (int j = 0; j < entryCount; j++) {
          // Test various edge cases for data completeness
          final klGrade = random.nextInt(5); // 0-4
          final confidence = random.nextDouble();

          // Generate timestamps with various patterns
          DateTime timestamp;
          switch (random.nextInt(4)) {
            case 0:
              timestamp = DateTime.now(); // Current time
              break;
            case 1:
              timestamp = DateTime.now().subtract(
                Duration(minutes: random.nextInt(60)),
              ); // Recent
              break;
            case 2:
              timestamp = DateTime.now().subtract(
                Duration(days: random.nextInt(30)),
              ); // This month
              break;
            case 3:
              timestamp = DateTime.now().subtract(
                Duration(days: random.nextInt(365)),
              ); // This year
              break;
            default:
              timestamp = DateTime.now();
          }

          final entry = ClassificationResult(
            id: 'test_${i}_$j',
            imagePath: 'path/to/image_${i}_$j.jpg',
            klGrade: klGrade,
            confidence: confidence,
            gradCamPath: 'path/to/gradcam_${i}_$j.png',
            timestamp: timestamp,
            allGradeConfidences: {
              0: random.nextDouble(),
              1: random.nextDouble(),
              2: random.nextDouble(),
              3: random.nextDouble(),
              4: random.nextDouble(),
            },
          );
          historyEntries.add(entry);
        }

        // Create mock use cases
        final mockGetHistoryUseCase = MockGetHistoryUseCase(
          () async => historyEntries,
        );
        final mockDeleteHistoryEntryUseCase = MockDeleteHistoryEntryUseCase(
          (_) async {},
        );

        final provider = HistoryProvider(
          mockGetHistoryUseCase,
          mockDeleteHistoryEntryUseCase,
        );

        // Load history
        await provider.loadHistory();

        // Verify all entries provide complete display data
        final loadedEntries = provider.historyEntries;

        for (int j = 0; j < loadedEntries.length; j++) {
          final entry = loadedEntries[j];

          // Test that all required fields are accessible for display

          // Thumbnail image - should have a valid file path
          expect(
            entry.imagePath,
            matches(r'.*\.(jpg|jpeg|png)$'),
            reason:
                'Entry $j should have valid image file extension (iteration $i)',
          );

          // KL grade - should be displayable as string
          final klGradeString = entry.klGrade.toString();
          expect(
            klGradeString,
            matches(r'^[0-4]$'),
            reason:
                'Entry $j KL grade should be displayable as single digit 0-4 (iteration $i)',
          );

          // Confidence score - should be displayable as percentage
          final confidencePercentage = (entry.confidence * 100).toStringAsFixed(
            1,
          );
          expect(
            double.tryParse(confidencePercentage),
            isNotNull,
            reason:
                'Entry $j confidence should be convertible to percentage string (iteration $i)',
          );
          expect(
            double.parse(confidencePercentage),
            inInclusiveRange(0.0, 100.0),
            reason:
                'Entry $j confidence percentage should be in valid range (iteration $i)',
          );

          // Timestamp - should be displayable in various formats
          final timestampString = entry.timestamp.toString();
          expect(
            timestampString,
            isNotEmpty,
            reason:
                'Entry $j timestamp should be convertible to string (iteration $i)',
          );

          // Test ISO format
          final isoString = entry.timestamp.toIso8601String();
          expect(
            DateTime.tryParse(isoString),
            isNotNull,
            reason:
                'Entry $j timestamp should be convertible to ISO string (iteration $i)',
          );

          // Test that we can format for display (common UI patterns)
          final displayDate =
              '${entry.timestamp.day}/${entry.timestamp.month}/${entry.timestamp.year}';
          expect(
            displayDate,
            matches(r'^\d{1,2}/\d{1,2}/\d{4}$'),
            reason:
                'Entry $j timestamp should be formattable for display (iteration $i)',
          );
        }
      }
    });

    test(
      'Property 16 (Chronological Ordering): History entries maintain required data in chronological order - '
      'For any set of history entries, they should be ordered by timestamp and maintain data completeness',
      () async {
        // **Feature: koa-detection-app, Property 16: History entry data completeness**
        // **Validates: Requirements 6.3**

        final random = Random();

        // Run property test with multiple iterations
        for (int i = 0; i < 100; i++) {
          // Generate random history entries with different timestamps
          final entryCount = random.nextInt(15) + 2; // 2-16 entries
          final historyEntries = <ClassificationResult>[];

          final baseTime = DateTime.now();

          for (int j = 0; j < entryCount; j++) {
            // Create entries with decreasing timestamps (reverse chronological)
            final timestamp = baseTime.subtract(
              Duration(minutes: j * 10 + random.nextInt(10)),
            );

            final entry = ClassificationResult(
              id: 'ordered_${i}_$j',
              imagePath: 'image_$j.jpg',
              klGrade: random.nextInt(5),
              confidence: random.nextDouble(),
              gradCamPath: 'gradcam_$j.png',
              timestamp: timestamp,
              allGradeConfidences: {
                0: random.nextDouble(),
                1: random.nextDouble(),
                2: random.nextDouble(),
                3: random.nextDouble(),
                4: random.nextDouble(),
              },
            );
            historyEntries.add(entry);
          }

          // Create mock use cases
          final mockGetHistoryUseCase = MockGetHistoryUseCase(
            () async => historyEntries,
          );
          final mockDeleteHistoryEntryUseCase = MockDeleteHistoryEntryUseCase(
            (_) async {},
          );

          final provider = HistoryProvider(
            mockGetHistoryUseCase,
            mockDeleteHistoryEntryUseCase,
          );

          // Load history
          await provider.loadHistory();

          final loadedEntries = provider.historyEntries;

          // Verify chronological ordering is maintained while preserving data completeness
          for (int j = 0; j < loadedEntries.length - 1; j++) {
            final currentEntry = loadedEntries[j];
            final nextEntry = loadedEntries[j + 1];

            // Verify chronological order (newest first)
            expect(
              currentEntry.timestamp.isAfter(nextEntry.timestamp) ||
                  currentEntry.timestamp.isAtSameMomentAs(nextEntry.timestamp),
              true,
              reason:
                  'Entry $j should be newer than or equal to entry ${j + 1} (iteration $i)',
            );

            // Verify both entries maintain data completeness
            for (final entry in [currentEntry, nextEntry]) {
              expect(
                entry.imagePath,
                isNotEmpty,
                reason:
                    'Entry should maintain image path in chronological order (iteration $i)',
              );
              expect(
                entry.klGrade,
                inInclusiveRange(0, 4),
                reason:
                    'Entry should maintain valid KL grade in chronological order (iteration $i)',
              );
              expect(
                entry.confidence,
                inInclusiveRange(0.0, 1.0),
                reason:
                    'Entry should maintain valid confidence in chronological order (iteration $i)',
              );
              expect(
                entry.timestamp,
                isNotNull,
                reason:
                    'Entry should maintain timestamp in chronological order (iteration $i)',
              );
            }
          }
        }
      },
    );
  });
}
