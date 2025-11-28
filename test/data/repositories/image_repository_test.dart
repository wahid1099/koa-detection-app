import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:koa_detecion/data/repositories/image_repository.dart';

@GenerateMocks([ImagePicker])
import 'image_repository_test.mocks.dart';

void main() {
  group('ImageRepository Property Tests', () {
    late MockImagePicker mockPicker;
    late ImageRepositoryImpl repository;

    setUp(() {
      mockPicker = MockImagePicker();
      repository = ImageRepositoryImpl(mockPicker);
    });

    /// Feature: koa-detection-app, Property 2: Image source selection invokes correct handler
    /// Validates: Requirements 2.2, 2.3
    test(
      'Property 2: For any image source selection (camera or gallery), the corresponding device API should be invoked correctly',
      () async {
        // Test camera source selection
        for (int i = 0; i < 100; i++) {
          final mockPicker = MockImagePicker();
          final repository = ImageRepositoryImpl(mockPicker);

          // Mock camera capture
          when(
            mockPicker.pickImage(
              source: ImageSource.camera,
              imageQuality: anyNamed('imageQuality'),
            ),
          ).thenAnswer((_) async => null);

          try {
            await repository.captureFromCamera();
          } catch (e) {
            // Permission exceptions are expected in test environment
            if (e is! PermissionDeniedException) {
              rethrow;
            }
          }

          // Verify camera source was used
          verify(
            mockPicker.pickImage(
              source: ImageSource.camera,
              imageQuality: anyNamed('imageQuality'),
            ),
          ).called(1);
        }

        // Test gallery source selection
        for (int i = 0; i < 100; i++) {
          final mockPicker = MockImagePicker();
          final repository = ImageRepositoryImpl(mockPicker);

          // Mock gallery selection
          when(
            mockPicker.pickImage(
              source: ImageSource.gallery,
              imageQuality: anyNamed('imageQuality'),
            ),
          ).thenAnswer((_) async => null);

          try {
            await repository.selectFromGallery();
          } catch (e) {
            // Permission exceptions are expected in test environment
            if (e is! PermissionDeniedException) {
              rethrow;
            }
          }

          // Verify gallery source was used
          verify(
            mockPicker.pickImage(
              source: ImageSource.gallery,
              imageQuality: anyNamed('imageQuality'),
            ),
          ).called(1);
        }
      },
    );

    test('captureFromCamera invokes ImagePicker with camera source', () async {
      when(
        mockPicker.pickImage(
          source: ImageSource.camera,
          imageQuality: anyNamed('imageQuality'),
        ),
      ).thenAnswer((_) async => null);

      try {
        await repository.captureFromCamera();
      } catch (e) {
        // Permission exceptions are expected
        expect(e, isA<PermissionDeniedException>());
      }

      verify(
        mockPicker.pickImage(source: ImageSource.camera, imageQuality: 85),
      ).called(1);
    });

    test('selectFromGallery invokes ImagePicker with gallery source', () async {
      when(
        mockPicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: anyNamed('imageQuality'),
        ),
      ).thenAnswer((_) async => null);

      try {
        await repository.selectFromGallery();
      } catch (e) {
        // Permission exceptions are expected
        expect(e, isA<PermissionDeniedException>());
      }

      verify(
        mockPicker.pickImage(source: ImageSource.gallery, imageQuality: 85),
      ).called(1);
    });
  });
}
