import 'dart:io';
import '../../data/repositories/image_repository.dart';
import '../validators.dart';

/// Use case for capturing an image from the device camera
class CaptureImageUseCase {
  final ImageRepository _imageRepository;

  CaptureImageUseCase(this._imageRepository);

  /// Captures an image from camera with validation and error handling
  /// Returns the captured image file or null if cancelled
  /// Throws [ImageCaptureException] if capture fails
  /// Throws [PermissionDeniedException] if camera permission is denied
  /// Throws [InvalidImageFormatException] if captured image format is not supported
  Future<File?> execute() async {
    try {
      final imageFile = await _imageRepository.captureFromCamera();

      if (imageFile == null) {
        // User cancelled the operation
        return null;
      }

      // Validate image format
      if (!Validators.isValidImageFormat(imageFile)) {
        throw InvalidImageFormatException(
          'Captured image format is not supported. Only JPEG and PNG formats are allowed.',
        );
      }

      return imageFile;
    } on PermissionDeniedException {
      rethrow;
    } on InvalidImageFormatException {
      rethrow;
    } catch (e) {
      throw ImageCaptureException(
        'Failed to capture image from camera: ${e.toString()}',
      );
    }
  }
}

/// Exception thrown when image capture fails
class ImageCaptureException implements Exception {
  final String message;
  ImageCaptureException(this.message);

  @override
  String toString() => 'ImageCaptureException: $message';
}

/// Exception thrown when image format is invalid
class InvalidImageFormatException implements Exception {
  final String message;
  InvalidImageFormatException(this.message);

  @override
  String toString() => 'InvalidImageFormatException: $message';
}
