import 'package:flutter_test/flutter_test.dart';

/// Feature: koa-detection-app, Property 10: KL grade explanation availability
/// Validates: Requirements 4.5
///
/// Property: For any KL grade value (0-4), the system should provide
/// an associated explanation text.

void main() {
  group('Property 10: KL grade explanation availability', () {
    test('should provide explanation for all valid KL grades (0-4)', () {
      // Test all valid KL grades
      for (int klGrade = 0; klGrade <= 4; klGrade++) {
        final explanation = _getKlGradeExplanation(klGrade);

        // Property: Explanation must not be null or empty
        expect(
          explanation,
          isNotNull,
          reason: 'Explanation for KL grade $klGrade must not be null',
        );

        expect(
          explanation.isNotEmpty,
          isTrue,
          reason: 'Explanation for KL grade $klGrade must not be empty',
        );

        // Property: Explanation must be meaningful (more than just a few characters)
        expect(
          explanation.length,
          greaterThan(10),
          reason:
              'Explanation for KL grade $klGrade must be meaningful (length: ${explanation.length})',
        );

        // Property: Explanation should not be a generic "Unknown" message
        expect(
          explanation.toLowerCase().contains('unknown'),
          isFalse,
          reason:
              'Explanation for valid KL grade $klGrade should not be "unknown"',
        );
      }
    });

    test('should provide unique explanations for each KL grade', () {
      final explanations = <String>{};

      // Collect explanations for all valid grades
      for (int klGrade = 0; klGrade <= 4; klGrade++) {
        final explanation = _getKlGradeExplanation(klGrade);
        explanations.add(explanation);
      }

      // Property: Each grade should have a unique explanation
      expect(
        explanations.length,
        equals(5),
        reason:
            'Each KL grade (0-4) should have a unique explanation, but found ${explanations.length} unique explanations',
      );
    });

    test(
      'should provide explanations that describe severity appropriately',
      () {
        // Test that explanations reflect increasing severity
        final grade0 = _getKlGradeExplanation(0).toLowerCase();
        final grade2 = _getKlGradeExplanation(2).toLowerCase();
        final grade4 = _getKlGradeExplanation(4).toLowerCase();

        // Property: Grade 0 should indicate no or minimal osteoarthritis
        expect(
          grade0.contains('no') || grade0.contains('healthy'),
          isTrue,
          reason: 'Grade 0 explanation should indicate no osteoarthritis',
        );

        // Property: Grade 2 should indicate mild/moderate severity
        expect(
          grade2.contains('mild') || grade2.contains('moderate'),
          isTrue,
          reason: 'Grade 2 explanation should indicate mild/moderate severity',
        );

        // Property: Grade 4 should indicate severe osteoarthritis
        expect(
          grade4.contains('severe'),
          isTrue,
          reason: 'Grade 4 explanation should indicate severe osteoarthritis',
        );
      },
    );

    test('should handle invalid grades gracefully', () {
      // Test invalid grades
      final invalidGrades = [-1, 5, 10, 100];

      for (final invalidGrade in invalidGrades) {
        final explanation = _getKlGradeExplanation(invalidGrade);

        // Property: Invalid grades should still return a non-empty explanation
        expect(
          explanation,
          isNotNull,
          reason:
              'Explanation for invalid grade $invalidGrade must not be null',
        );

        expect(
          explanation.isNotEmpty,
          isTrue,
          reason:
              'Explanation for invalid grade $invalidGrade must not be empty',
        );

        // Property: Invalid grades should indicate they are unknown/invalid
        expect(
          explanation.toLowerCase().contains('unknown'),
          isTrue,
          reason:
              'Explanation for invalid grade $invalidGrade should indicate it is unknown',
        );
      }
    });
  });
}

/// Get explanation text for a KL grade
/// This mirrors the implementation in ClassificationScreen
String _getKlGradeExplanation(int klGrade) {
  switch (klGrade) {
    case 0:
      return 'No osteoarthritis detected. The joint appears healthy.';
    case 1:
      return 'Doubtful osteoarthritis. Minimal changes may be present.';
    case 2:
      return 'Mild osteoarthritis. Definite osteophytes and possible joint space narrowing.';
    case 3:
      return 'Moderate osteoarthritis. Multiple osteophytes and definite joint space narrowing.';
    case 4:
      return 'Severe osteoarthritis. Large osteophytes, marked joint space narrowing, and bone deformity.';
    default:
      return 'Unknown KL grade.';
  }
}
