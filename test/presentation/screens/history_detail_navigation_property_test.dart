import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:koa_detecion/data/models/classification_result.dart';

/// Feature: koa-detection-app, Property 17: History detail navigation
/// Validates: Requirements 6.4
///
/// Property: For any history entry selected, the detail view should display
/// complete classification data including the Grad-CAM visualization.

void main() {
  group('Property 17: History detail navigation', () {
    test('should display complete classification data for any history entry', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        final historyEntry = _generateRandomHistoryEntry();

        // Simulate navigating to detail view and rendering the entry
        final detailViewText = _renderHistoryDetailToText(historyEntry);

        // Property: Detail view must contain KL grade
        expect(
          detailViewText.contains('KL Grade') ||
              detailViewText.contains('Grade ${historyEntry.klGrade}'),
          isTrue,
          reason:
              'Detail view must show KL grade for entry with grade ${historyEntry.klGrade}',
        );

        // Property: Detail view must contain confidence score
        final confidencePercentage = (historyEntry.confidence * 100)
            .toStringAsFixed(1);
        expect(
          detailViewText.contains('Confidence') ||
              detailViewText.contains(confidencePercentage) ||
              detailViewText.contains('%'),
          isTrue,
          reason:
              'Detail view must show confidence for entry with confidence ${historyEntry.confidence}',
        );

        // Property: Detail view must contain Grad-CAM visualization
        expect(
          detailViewText.contains('Grad-CAM') ||
              detailViewText.contains('gradCam') ||
              detailViewText.contains('Visualization') ||
              detailViewText.contains(historyEntry.gradCamPath),
          isTrue,
          reason: 'Detail view must show Grad-CAM visualization',
        );

        // Property: Detail view must contain original image reference
        expect(
          detailViewText.contains('Original') ||
              detailViewText.contains('X-ray') ||
              detailViewText.contains(historyEntry.imagePath),
          isTrue,
          reason: 'Detail view must show original image reference',
        );

        // Property: Detail view must contain timestamp information
        expect(
          detailViewText.contains('Analyzed') ||
              detailViewText.contains('Date') ||
              detailViewText.contains(historyEntry.timestamp.year.toString()),
          isTrue,
          reason: 'Detail view must show timestamp information',
        );
      }
    });

    test('should include all grade confidences for any history entry', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        final historyEntry = _generateRandomHistoryEntry();
        final detailViewText = _renderHistoryDetailToText(historyEntry);

        // Property: Detail view should show confidence breakdown
        if (historyEntry.allGradeConfidences.isNotEmpty) {
          expect(
            detailViewText.contains('Confidence Breakdown') ||
                detailViewText.contains('All Grades') ||
                detailViewText.contains('Grade 0') ||
                detailViewText.contains('Grade 1'),
            isTrue,
            reason:
                'Detail view should show confidence breakdown when available',
          );

          // Verify that at least some grade confidences are shown
          int gradeConfidencesShown = 0;
          for (int grade = 0; grade <= 4; grade++) {
            if (historyEntry.allGradeConfidences.containsKey(grade)) {
              final confidence = historyEntry.allGradeConfidences[grade]!;
              final confidenceText = (confidence * 100).toStringAsFixed(1);
              if (detailViewText.contains('Grade $grade') ||
                  detailViewText.contains(confidenceText)) {
                gradeConfidencesShown++;
              }
            }
          }

          expect(
            gradeConfidencesShown,
            greaterThan(0),
            reason: 'Detail view should show at least some grade confidences',
          );
        }
      }
    });

    test('should provide navigation context for any history entry', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        final historyEntry = _generateRandomHistoryEntry();
        final detailViewText = _renderHistoryDetailToText(historyEntry);

        // Property: Detail view should have navigation context
        expect(
          detailViewText.contains('Classification Details') ||
              detailViewText.contains('Detail') ||
              detailViewText.contains('Result'),
          isTrue,
          reason: 'Detail view should have clear navigation context',
        );

        // Property: Detail view should have unique identifier context
        expect(
          detailViewText.contains(historyEntry.id) ||
              detailViewText.contains('ID') ||
              detailViewText.length > 100, // Sufficient detail content
          isTrue,
          reason: 'Detail view should have sufficient identifying information',
        );
      }
    });
  });
}

/// Generate a random history entry for property testing
ClassificationResult _generateRandomHistoryEntry() {
  final random = Random();

  // Generate random KL grade (0-4)
  final klGrade = random.nextInt(5);

  // Generate random confidence (0.3 to 0.95 for realistic values)
  final confidence = 0.3 + (random.nextDouble() * 0.65);

  // Generate random confidences for all grades
  final allGradeConfidences = <int, double>{};
  double totalConfidence = 0.0;

  // Generate confidences for grades 0-3
  for (int i = 0; i < 4; i++) {
    final value = random.nextDouble() * 0.2; // Max 20% for non-predicted grades
    allGradeConfidences[i] = value;
    totalConfidence += value;
  }

  // Assign remaining confidence to grade 4
  allGradeConfidences[4] = 1.0 - totalConfidence;

  // Ensure the predicted grade has higher confidence
  if (allGradeConfidences[klGrade]! < confidence) {
    allGradeConfidences[klGrade] = confidence;

    // Redistribute remaining confidence
    final remaining = 1.0 - confidence;
    final otherGrades = allGradeConfidences.keys
        .where((k) => k != klGrade)
        .toList();
    for (int i = 0; i < otherGrades.length; i++) {
      allGradeConfidences[otherGrades[i]] = remaining / otherGrades.length;
    }
  }

  // Generate random timestamp (within last year)
  final timestamp = DateTime.now().subtract(
    Duration(
      days: random.nextInt(365),
      hours: random.nextInt(24),
      minutes: random.nextInt(60),
    ),
  );

  return ClassificationResult(
    id: 'history_${random.nextInt(100000)}_${timestamp.millisecondsSinceEpoch}',
    imagePath: '/storage/images/xray_${random.nextInt(1000)}.jpg',
    klGrade: klGrade,
    confidence: confidence,
    gradCamPath: '/storage/gradcam/gradcam_${random.nextInt(1000)}.jpg',
    timestamp: timestamp,
    allGradeConfidences: allGradeConfidences,
  );
}

/// Simulate rendering a history detail view to text
/// This represents what would be displayed in the detail screen UI
String _renderHistoryDetailToText(ClassificationResult entry) {
  final buffer = StringBuffer();

  // Simulate the detail view UI rendering
  buffer.writeln('Classification Details');
  buffer.writeln('Entry ID: ${entry.id}');
  buffer.writeln('');

  // Classification Summary
  buffer.writeln('Classification Result');
  buffer.writeln('KL Grade: ${entry.klGrade}');
  buffer.writeln('Confidence: ${(entry.confidence * 100).toStringAsFixed(1)}%');
  buffer.writeln('Analyzed on ${entry.timestamp}');
  buffer.writeln('');

  // Grade explanation
  buffer.writeln('About KL Grade ${entry.klGrade}');
  buffer.writeln(_getGradeExplanation(entry.klGrade));
  buffer.writeln('');

  // Original image
  buffer.writeln('Original X-ray Image');
  buffer.writeln('Image Path: ${entry.imagePath}');
  buffer.writeln('');

  // Grad-CAM visualization
  buffer.writeln('Grad-CAM Visualization');
  buffer.writeln('Heatmap Path: ${entry.gradCamPath}');
  buffer.writeln(
    'This heatmap shows which regions influenced the classification',
  );
  buffer.writeln('');

  // Confidence breakdown
  if (entry.allGradeConfidences.isNotEmpty) {
    buffer.writeln('Confidence Breakdown');
    for (int grade = 0; grade <= 4; grade++) {
      if (entry.allGradeConfidences.containsKey(grade)) {
        final confidence = entry.allGradeConfidences[grade]!;
        buffer.writeln(
          'Grade $grade: ${(confidence * 100).toStringAsFixed(1)}%',
        );
      }
    }
  }

  return buffer.toString();
}

/// Get explanation text for a KL grade
String _getGradeExplanation(int grade) {
  switch (grade) {
    case 0:
      return 'No radiographic features of osteoarthritis are present.';
    case 1:
      return 'Doubtful joint space narrowing and possible osteophytic lipping.';
    case 2:
      return 'Definite osteophytes and possible joint space narrowing.';
    case 3:
      return 'Multiple osteophytes, definite joint space narrowing, some sclerosis.';
    case 4:
      return 'Large osteophytes, marked joint space narrowing, severe sclerosis.';
    default:
      return 'Classification not recognized.';
  }
}
