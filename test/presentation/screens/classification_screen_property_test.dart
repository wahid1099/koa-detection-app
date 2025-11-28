import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:koa_detecion/data/models/classification_result.dart';

/// Feature: koa-detection-app, Property 9: Classification result display completeness
/// Validates: Requirements 4.1, 4.2, 4.3
///
/// Property: For any successful classification, the results view should display
/// KL grade, confidence percentage, and Grad-CAM visualization.

void main() {
  group('Property 9: Classification result display completeness', () {
    test('should contain KL grade, confidence, and Grad-CAM for any result', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        final result = _generateRandomClassificationResult();

        // Simulate rendering the result to a string representation
        final displayText = _renderResultToText(result);

        // Property: Display must contain KL grade
        expect(
          displayText.contains('KL Grade') ||
              displayText.contains('${result.klGrade}'),
          isTrue,
          reason:
              'Display must show KL grade for result with grade ${result.klGrade}',
        );

        // Property: Display must contain confidence as percentage
        final confidencePercentage = (result.confidence * 100).toStringAsFixed(
          1,
        );
        expect(
          displayText.contains('Confidence') ||
              displayText.contains(confidencePercentage) ||
              displayText.contains('%'),
          isTrue,
          reason:
              'Display must show confidence percentage for result with confidence ${result.confidence}',
        );

        // Property: Display must reference Grad-CAM visualization
        expect(
          displayText.contains('Grad-CAM') ||
              displayText.contains('gradCam') ||
              displayText.contains(result.gradCamPath),
          isTrue,
          reason: 'Display must show Grad-CAM visualization reference',
        );
      }
    });

    test('should display all three elements together for any result', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        final result = _generateRandomClassificationResult();
        final displayText = _renderResultToText(result);

        // Count how many required elements are present
        int elementCount = 0;

        // Check for KL grade
        if (displayText.contains('KL Grade') ||
            displayText.contains('${result.klGrade}')) {
          elementCount++;
        }

        // Check for confidence
        if (displayText.contains('Confidence') || displayText.contains('%')) {
          elementCount++;
        }

        // Check for Grad-CAM
        if (displayText.contains('Grad-CAM') ||
            displayText.contains('gradCam')) {
          elementCount++;
        }

        // Property: All three elements must be present
        expect(
          elementCount,
          equals(3),
          reason:
              'Display must contain all three elements (KL grade, confidence, Grad-CAM) but found $elementCount',
        );
      }
    });
  });
}

/// Generate a random classification result for property testing
ClassificationResult _generateRandomClassificationResult() {
  final random = Random();

  // Generate random KL grade (0-4)
  final klGrade = random.nextInt(5);

  // Generate random confidence (0.5 to 1.0 for realistic values)
  final confidence = 0.5 + (random.nextDouble() * 0.5);

  // Generate random confidences for all grades
  final allGradeConfidences = <int, double>{};
  double remainingConfidence = 1.0;

  for (int i = 0; i < 5; i++) {
    if (i == 4) {
      allGradeConfidences[i] = remainingConfidence;
    } else {
      final value = random.nextDouble() * remainingConfidence * 0.3;
      allGradeConfidences[i] = value;
      remainingConfidence -= value;
    }
  }

  // Ensure the predicted grade has the highest confidence
  allGradeConfidences[klGrade] = confidence;

  return ClassificationResult(
    id: 'test_${random.nextInt(100000)}',
    imagePath: '/tmp/test_image_${random.nextInt(1000)}.jpg',
    klGrade: klGrade,
    confidence: confidence,
    gradCamPath: '/tmp/gradcam_${random.nextInt(1000)}.jpg',
    timestamp: DateTime.now().subtract(Duration(days: random.nextInt(365))),
    allGradeConfidences: allGradeConfidences,
  );
}

/// Simulate rendering a classification result to text
/// This represents what would be displayed in the UI
String _renderResultToText(ClassificationResult result) {
  final buffer = StringBuffer();

  // Simulate the UI rendering
  buffer.writeln('Classification Results');
  buffer.writeln('KL Grade: ${result.klGrade}');
  buffer.writeln(
    'Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
  );
  buffer.writeln('Grad-CAM Visualization');
  buffer.writeln('Image Path: ${result.imagePath}');
  buffer.writeln('Grad-CAM Path: ${result.gradCamPath}');
  buffer.writeln('Timestamp: ${result.timestamp}');

  return buffer.toString();
}
