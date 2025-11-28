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
  group('Loading Indicator Property Tests', () {
    test(
      'Property 7: Loading indicator during upload - '
      'For any upload operation in progress, a loading indicator should be visible in the UI',
      () async {
        // **Feature: koa-detection-app, Property 7: Loading indicator during upload**
        // **Validates: Requirements 3.3**

        final random = Random();

        // Run property test with multiple iterations
        for (int i = 0; i < 100; i++) {
          // Generate random test data
          final shouldSucceed = random.nextBool();
          final delayMs = random.nextInt(1000) + 100; // 100-1100ms delay

          // Create a mock image file
          final mockImageFile = File('test_image_$i.jpg');

          // Create mock use cases with specific behavior
          final mockClassifyImageUseCase = MockClassifyImageUseCase((
            file,
          ) async {
            await Future.delayed(Duration(milliseconds: delayMs));
            if (shouldSucceed) {
              return ClassificationResult(
                id: 'test_$i',
                imagePath: file.path,
                klGrade: random.nextInt(5),
                confidence: random.nextDouble(),
                gradCamPath: 'gradcam_$i.png',
                timestamp: DateTime.now(),
                allGradeConfidences: {0: 0.1, 1: 0.2, 2: 0.3, 3: 0.2, 4: 0.2},
              );
            } else {
              throw Exception('Classification failed');
            }
          });

          final mockSaveToHistoryUseCase = MockSaveToHistoryUseCase(
            (_) async {},
          );

          final mockCaptureImageUseCase = MockCaptureImageUseCase(
            () async => mockImageFile,
          );
          final mockSelectImageUseCase = MockSelectImageUseCase(
            () async => mockImageFile,
          );
          final mockSaveResultUseCase = MockSaveResultUseCase(
            (_) async => '/saved/path',
          );

          final provider = ClassificationProvider(
            mockCaptureImageUseCase,
            mockSelectImageUseCase,
            mockClassifyImageUseCase,
            mockSaveResultUseCase,
            mockSaveToHistoryUseCase,
          );

          // First select an image to have something to classify
          await provider.captureImage();

          // Verify initial state is not loading
          expect(
            provider.isLoading,
            false,
            reason: 'Provider should not be loading initially (iteration $i)',
          );

          // Start classification (which should trigger loading state)
          final classificationFuture = provider.classifyImage();

          // Immediately check that loading indicator is visible
          expect(
            provider.isLoading,
            true,
            reason:
                'Provider should be loading during classification (iteration $i)',
          );
          expect(
            provider.state,
            ClassificationState.classifying,
            reason: 'Provider state should be classifying (iteration $i)',
          );

          // Wait for operation to complete
          await classificationFuture;

          // Verify loading indicator is no longer visible
          expect(
            provider.isLoading,
            false,
            reason:
                'Provider should not be loading after classification completes (iteration $i)',
          );
          expect(
            provider.state,
            isNot(ClassificationState.classifying),
            reason:
                'Provider state should not be classifying after completion (iteration $i)',
          );
        }
      },
    );

    test(
      'Property 7 (Save Operation): Loading indicator during save - '
      'For any save operation in progress, a loading indicator should be visible in the UI',
      () async {
        // **Feature: koa-detection-app, Property 7: Loading indicator during save**
        // **Validates: Requirements 3.3**

        final random = Random();

        // Run property test with multiple iterations
        for (int i = 0; i < 100; i++) {
          // Generate random test data
          final shouldSucceed = random.nextBool();
          final delayMs = random.nextInt(500) + 50; // 50-550ms delay

          // Create a mock classification result
          final mockResult = ClassificationResult(
            id: 'test_$i',
            imagePath: 'test_image_$i.jpg',
            klGrade: random.nextInt(5),
            confidence: random.nextDouble(),
            gradCamPath: 'gradcam_$i.png',
            timestamp: DateTime.now(),
            allGradeConfidences: {0: 0.1, 1: 0.2, 2: 0.3, 3: 0.2, 4: 0.2},
          );

          // Create mock use cases
          final mockClassifyImageUseCase = MockClassifyImageUseCase(
            (_) async => mockResult,
          );
          final mockSaveToHistoryUseCase = MockSaveToHistoryUseCase(
            (_) async {},
          );
          final mockCaptureImageUseCase = MockCaptureImageUseCase(
            () async => File('test.jpg'),
          );
          final mockSelectImageUseCase = MockSelectImageUseCase(
            () async => File('test.jpg'),
          );

          final mockSaveResultUseCase = MockSaveResultUseCase((result) async {
            await Future.delayed(Duration(milliseconds: delayMs));
            if (shouldSucceed) {
              return '/saved/path/result_$i.jpg';
            } else {
              throw Exception('Save failed');
            }
          });

          final provider = ClassificationProvider(
            mockCaptureImageUseCase,
            mockSelectImageUseCase,
            mockClassifyImageUseCase,
            mockSaveResultUseCase,
            mockSaveToHistoryUseCase,
          );

          // First get a classification result
          await provider.captureImage();
          await provider.classifyImage();

          // Verify initial state is not loading
          expect(
            provider.isLoading,
            false,
            reason: 'Provider should not be loading initially (iteration $i)',
          );

          // Start save operation (which should trigger loading state)
          final saveFuture = provider.saveResult();

          // Immediately check that loading indicator is visible
          expect(
            provider.isLoading,
            true,
            reason:
                'Provider should be loading during save operation (iteration $i)',
          );
          expect(
            provider.state,
            ClassificationState.saving,
            reason: 'Provider state should be saving (iteration $i)',
          );

          // Wait for operation to complete
          await saveFuture;

          // Verify loading indicator is no longer visible
          expect(
            provider.isLoading,
            false,
            reason:
                'Provider should not be loading after save completes (iteration $i)',
          );
          expect(
            provider.state,
            isNot(ClassificationState.saving),
            reason:
                'Provider state should not be saving after completion (iteration $i)',
          );
        }
      },
    );
  });
}
