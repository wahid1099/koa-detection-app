import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'dart:math';

import 'package:koa_detecion/presentation/providers/classification_provider.dart';
import 'package:koa_detecion/domain/use_cases/capture_image_use_case.dart';
import 'package:koa_detecion/domain/use_cases/select_image_use_case.dart';
import 'package:koa_detecion/domain/use_cases/classify_image_use_case.dart';
import 'package:koa_detecion/domain/use_cases/save_result_use_case.dart';
import 'package:koa_detecion/domain/use_cases/save_to_history_use_case.dart';
import 'package:koa_detecion/data/models/classification_result.dart';

// Mock implementations for testing
class MockCaptureImageUseCase implements CaptureImageUseCase {
  final Future<File?> Function() _executeImpl;
  MockCaptureImageUseCase(this._executeImpl);

  @override
  Future<File?> execute() => _executeImpl();
}

class MockSelectImageUseCase implements SelectImageUseCase {
  final Future<File?> Function() _executeImpl;
  MockSelectImageUseCase(this._executeImpl);

  @override
  Future<File?> execute() => _executeImpl();
}

class MockClassifyImageUseCase implements ClassifyImageUseCase {
  final Future<ClassificationResult> Function(File) _executeImpl;
  MockClassifyImageUseCase(this._executeImpl);

  @override
  Future<ClassificationResult> execute(File imageFile) =>
      _executeImpl(imageFile);
}

class MockSaveResultUseCase implements SaveResultUseCase {
  final Future<String> Function(ClassificationResult) _executeImpl;
  MockSaveResultUseCase(this._executeImpl);

  @override
  Future<String> execute(ClassificationResult result) => _executeImpl(result);
}

class MockSaveToHistoryUseCase implements SaveToHistoryUseCase {
  final Future<void> Function(ClassificationResult) _executeImpl;
  MockSaveToHistoryUseCase(this._executeImpl);

  @override
  Future<void> execute(ClassificationResult result) => _executeImpl(result);
}

void main() {
  group('Loading State Disables Interactions Property Tests', () {
    test(
      'Property 24: Loading state disables interactions - '
      'For any loading state, all interactive UI elements should be disabled to prevent duplicate actions',
      () async {
        // **Feature: koa-detection-app, Property 24: Loading state disables interactions**
        // **Validates: Requirements 9.4**

        final random = Random();

        // Run property test with multiple iterations
        for (int i = 0; i < 100; i++) {
          // Generate random test data
          final delayMs = random.nextInt(1000) + 100; // 100-1100ms delay

          // Create a mock image file
          final mockImageFile = File('test_image_$i.jpg');

          // Create mock classification result
          final mockResult = ClassificationResult(
            id: 'test_$i',
            imagePath: mockImageFile.path,
            klGrade: random.nextInt(5),
            confidence: random.nextDouble(),
            gradCamPath: 'gradcam_$i.png',
            timestamp: DateTime.now(),
            allGradeConfidences: {0: 0.1, 1: 0.2, 2: 0.3, 3: 0.2, 4: 0.2},
          );

          // Test different loading operations
          final operations = ['capture', 'select', 'classify', 'save'];
          final operation = operations[random.nextInt(operations.length)];

          // Create mock use cases with delays
          final mockCaptureImageUseCase = MockCaptureImageUseCase(() async {
            if (operation == 'capture') {
              await Future.delayed(Duration(milliseconds: delayMs));
            }
            return mockImageFile;
          });

          final mockSelectImageUseCase = MockSelectImageUseCase(() async {
            if (operation == 'select') {
              await Future.delayed(Duration(milliseconds: delayMs));
            }
            return mockImageFile;
          });

          final mockClassifyImageUseCase = MockClassifyImageUseCase((_) async {
            if (operation == 'classify') {
              await Future.delayed(Duration(milliseconds: delayMs));
            }
            return mockResult;
          });

          final mockSaveResultUseCase = MockSaveResultUseCase((_) async {
            if (operation == 'save') {
              await Future.delayed(Duration(milliseconds: delayMs));
            }
            return '/saved/path';
          });

          final mockSaveToHistoryUseCase = MockSaveToHistoryUseCase(
            (_) async {},
          );

          final provider = ClassificationProvider(
            mockCaptureImageUseCase,
            mockSelectImageUseCase,
            mockClassifyImageUseCase,
            mockSaveResultUseCase,
            mockSaveToHistoryUseCase,
          );

          // Verify initial state - interactions should be enabled
          expect(
            provider.isInteractionDisabled,
            false,
            reason:
                'Interactions should be enabled initially (iteration $i, operation: $operation)',
          );
          expect(
            provider.isLoading,
            false,
            reason:
                'Provider should not be loading initially (iteration $i, operation: $operation)',
          );

          // Start the operation based on the random selection
          Future<void> operationFuture;

          switch (operation) {
            case 'capture':
              operationFuture = provider.captureImage();
              break;
            case 'select':
              operationFuture = provider.selectImage();
              break;
            case 'classify':
              // First need to have an image selected
              await provider.captureImage();
              operationFuture = provider.classifyImage();
              break;
            case 'save':
              // First need to have a classification result
              await provider.captureImage();
              await provider.classifyImage();
              operationFuture = provider.saveResult();
              break;
            default:
              throw Exception('Unknown operation: $operation');
          }

          // Immediately check that interactions are disabled during loading
          expect(
            provider.isInteractionDisabled,
            true,
            reason:
                'Interactions should be disabled during $operation (iteration $i)',
          );
          expect(
            provider.isLoading,
            true,
            reason:
                'Provider should be loading during $operation (iteration $i)',
          );

          // Wait for operation to complete
          await operationFuture;

          // Verify interactions are re-enabled after operation completes
          expect(
            provider.isInteractionDisabled,
            false,
            reason:
                'Interactions should be enabled after $operation completes (iteration $i)',
          );
          expect(
            provider.isLoading,
            false,
            reason:
                'Provider should not be loading after $operation completes (iteration $i)',
          );
        }
      },
    );

    test('Property 24 (State Consistency): isInteractionDisabled matches isLoading - '
        'For any provider state, isInteractionDisabled should be true when isLoading is true', () async {
      // **Feature: koa-detection-app, Property 24: Loading state disables interactions**
      // **Validates: Requirements 9.4**

      final random = Random();

      // Run property test with multiple iterations
      for (int i = 0; i < 100; i++) {
        // Generate random test data
        final delayMs = random.nextInt(500) + 50; // 50-550ms delay

        // Create mock use cases with delays
        final mockCaptureImageUseCase = MockCaptureImageUseCase(() async {
          await Future.delayed(Duration(milliseconds: delayMs));
          return File('test.jpg');
        });

        final mockSelectImageUseCase = MockSelectImageUseCase(() async {
          await Future.delayed(Duration(milliseconds: delayMs));
          return File('test.jpg');
        });

        final mockClassifyImageUseCase = MockClassifyImageUseCase((_) async {
          await Future.delayed(Duration(milliseconds: delayMs));
          return ClassificationResult(
            id: 'test_$i',
            imagePath: 'test.jpg',
            klGrade: random.nextInt(5),
            confidence: random.nextDouble(),
            gradCamPath: 'gradcam.png',
            timestamp: DateTime.now(),
            allGradeConfidences: {0: 0.1, 1: 0.2, 2: 0.3, 3: 0.2, 4: 0.2},
          );
        });

        final mockSaveResultUseCase = MockSaveResultUseCase((_) async {
          await Future.delayed(Duration(milliseconds: delayMs));
          return '/saved/path';
        });

        final mockSaveToHistoryUseCase = MockSaveToHistoryUseCase((_) async {});

        final provider = ClassificationProvider(
          mockCaptureImageUseCase,
          mockSelectImageUseCase,
          mockClassifyImageUseCase,
          mockSaveResultUseCase,
          mockSaveToHistoryUseCase,
        );

        // Test the consistency property: isInteractionDisabled should equal isLoading

        // Initial state
        expect(
          provider.isInteractionDisabled,
          equals(provider.isLoading),
          reason:
              'isInteractionDisabled should equal isLoading in initial state (iteration $i)',
        );

        // During capture
        final captureFuture = provider.captureImage();
        expect(
          provider.isInteractionDisabled,
          equals(provider.isLoading),
          reason:
              'isInteractionDisabled should equal isLoading during capture (iteration $i)',
        );
        await captureFuture;

        expect(
          provider.isInteractionDisabled,
          equals(provider.isLoading),
          reason:
              'isInteractionDisabled should equal isLoading after capture (iteration $i)',
        );

        // During classification
        final classifyFuture = provider.classifyImage();
        expect(
          provider.isInteractionDisabled,
          equals(provider.isLoading),
          reason:
              'isInteractionDisabled should equal isLoading during classification (iteration $i)',
        );
        await classifyFuture;

        expect(
          provider.isInteractionDisabled,
          equals(provider.isLoading),
          reason:
              'isInteractionDisabled should equal isLoading after classification (iteration $i)',
        );

        // During save
        final saveFuture = provider.saveResult();
        expect(
          provider.isInteractionDisabled,
          equals(provider.isLoading),
          reason:
              'isInteractionDisabled should equal isLoading during save (iteration $i)',
        );
        await saveFuture;

        expect(
          provider.isInteractionDisabled,
          equals(provider.isLoading),
          reason:
              'isInteractionDisabled should equal isLoading after save (iteration $i)',
        );
      }
    });
  });
}
