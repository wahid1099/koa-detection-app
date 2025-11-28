import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:koa_detecion/data/models/classification_result.dart';
import 'package:koa_detecion/data/repositories/classification_repository.dart';
import 'package:koa_detecion/domain/use_cases/classify_image_use_case.dart';

void main() {
  group('ClassifyImageUseCase', () {
    late ClassifyImageUseCase useCase;
    late MockClassificationRepository mockRepository;

    setUp(() {
      mockRepository = MockClassificationRepository();
      useCase = ClassifyImageUseCase(mockRepository);
    });

    group('Network Error Messaging', () {
      // Feature: koa-detection-app, Property 21: Network error messaging
      // Validates: Requirements 8.1
      test(
        'Property 21: For any network error, a user-friendly error message should be displayed',
        () async {
          final testFile = File('/path/to/test.jpg');

          // Test various network error scenarios
          final networkErrorScenarios = [
            {
              'error': NetworkException('Connection timeout'),
              'expectedKeywords': ['timeout', 'internet', 'try again'],
            },
            {
              'error': NetworkException('No internet connection'),
              'expectedKeywords': ['internet', 'network', 'try again'],
            },
            {
              'error': NetworkException('DNS resolution failed'),
              'expectedKeywords': ['server', 'endpoint', 'settings'],
            },
            {
              'error': NetworkException('Host unreachable'),
              'expectedKeywords': ['server', 'endpoint'],
            },
            {
              'error': NetworkException('Network unreachable'),
              'expectedKeywords': ['internet', 'network'],
            },
            {
              'error': NetworkException('Unknown network error'),
              'expectedKeywords': ['network', 'internet', 'try again'],
            },
          ];

          for (final scenario in networkErrorScenarios) {
            mockRepository.setError(scenario['error'] as Exception);

            try {
              await useCase.execute(testFile);
              fail('Should throw ClassificationException');
            } on ClassificationException catch (e) {
              // Verify it's marked as a network error
              expect(
                e.isNetworkError,
                true,
                reason: 'Should be marked as network error',
              );

              // Verify message is user-friendly (contains expected keywords)
              final message = e.message.toLowerCase();
              final keywords = scenario['expectedKeywords'] as List<String>;
              final hasKeyword = keywords.any(
                (keyword) => message.contains(keyword),
              );

              expect(
                hasKeyword,
                true,
                reason:
                    'Message should contain one of $keywords, got: ${e.message}',
              );

              // Verify message doesn't expose technical details
              expect(
                message.contains('exception'),
                false,
                reason: 'Should not expose exception details',
              );
              expect(
                message.contains('stack'),
                false,
                reason: 'Should not expose stack trace',
              );
            }
          }
        },
      );

      test('Property 21: Network error messages are actionable', () async {
        final testFile = File('/path/to/test.jpg');
        mockRepository.setError(NetworkException('Connection timeout'));

        try {
          await useCase.execute(testFile);
          fail('Should throw ClassificationException');
        } on ClassificationException catch (e) {
          final message = e.message.toLowerCase();

          // Should provide guidance on what to do
          final hasActionableGuidance =
              message.contains('try again') ||
              message.contains('check') ||
              message.contains('please');

          expect(
            hasActionableGuidance,
            true,
            reason: 'Message should provide actionable guidance',
          );
        }
      });
    });

    group('API Error Handling', () {
      // Feature: koa-detection-app, Property 22: API error response handling
      // Validates: Requirements 8.2
      test(
        'Property 22: For any API error response, error details should be parsed and displayed',
        () async {
          final testFile = File('/path/to/test.jpg');

          // Test various API error scenarios
          final apiErrorScenarios = [
            {
              'error': ApiException('Bad request', statusCode: 400),
              'expectedKeywords': ['invalid', 'request'],
            },
            {
              'error': ApiException('Unauthorized', statusCode: 401),
              'expectedKeywords': ['invalid', 'request'],
            },
            {
              'error': ApiException('Not found', statusCode: 404),
              'expectedKeywords': ['invalid', 'request'],
            },
            {
              'error': ApiException('Internal server error', statusCode: 500),
              'expectedKeywords': ['service', 'unavailable', 'try again'],
            },
            {
              'error': ApiException('Service unavailable', statusCode: 503),
              'expectedKeywords': ['service', 'unavailable', 'try again'],
            },
            {
              'error': ApiException('Gateway timeout', statusCode: 504),
              'expectedKeywords': ['service', 'unavailable', 'try again'],
            },
            {
              'error': ApiException('Invalid image format'),
              'expectedKeywords': ['error', 'invalid image format'],
            },
          ];

          for (final scenario in apiErrorScenarios) {
            mockRepository.setError(scenario['error'] as Exception);

            try {
              await useCase.execute(testFile);
              fail('Should throw ClassificationException');
            } on ClassificationException catch (e) {
              // Verify it's marked as an API error
              expect(
                e.isApiError,
                true,
                reason: 'Should be marked as API error',
              );

              // Verify message is user-friendly
              final message = e.message.toLowerCase();
              final keywords = scenario['expectedKeywords'] as List<String>;
              final hasKeyword = keywords.any(
                (keyword) => message.contains(keyword),
              );

              expect(
                hasKeyword,
                true,
                reason:
                    'Message should contain one of $keywords, got: ${e.message}',
              );
            }
          }
        },
      );

      test('Property 22: API 4xx errors suggest client-side issues', () async {
        final testFile = File('/path/to/test.jpg');
        final clientErrors = [400, 401, 403, 404, 422];

        for (final statusCode in clientErrors) {
          mockRepository.setError(
            ApiException('Client error', statusCode: statusCode),
          );

          try {
            await useCase.execute(testFile);
            fail('Should throw ClassificationException');
          } on ClassificationException catch (e) {
            final message = e.message.toLowerCase();

            // Should indicate it's a request issue
            final indicatesClientIssue =
                message.contains('invalid') ||
                message.contains('request') ||
                message.contains('contact');

            expect(
              indicatesClientIssue,
              true,
              reason: 'Status $statusCode should indicate client-side issue',
            );
          }
        }
      });

      test('Property 22: API 5xx errors suggest server-side issues', () async {
        final testFile = File('/path/to/test.jpg');
        final serverErrors = [500, 502, 503, 504];

        for (final statusCode in serverErrors) {
          mockRepository.setError(
            ApiException('Server error', statusCode: statusCode),
          );

          try {
            await useCase.execute(testFile);
            fail('Should throw ClassificationException');
          } on ClassificationException catch (e) {
            final message = e.message.toLowerCase();

            // Should indicate it's a server issue
            final indicatesServerIssue =
                message.contains('service') ||
                message.contains('unavailable') ||
                message.contains('try again') ||
                message.contains('later');

            expect(
              indicatesServerIssue,
              true,
              reason: 'Status $statusCode should indicate server-side issue',
            );
          }
        }
      });
    });
  });
}

/// Mock implementation of ClassificationRepository for testing
class MockClassificationRepository implements ClassificationRepository {
  Exception? _error;
  ClassificationResult? _result;

  void setError(Exception error) {
    _error = error;
    _result = null;
  }

  void setResult(ClassificationResult result) {
    _result = result;
    _error = null;
  }

  @override
  Future<ClassificationResult> classifyImage(File image) async {
    if (_error != null) {
      throw _error!;
    }
    if (_result != null) {
      return _result!;
    }
    throw Exception('Mock not configured');
  }
}
