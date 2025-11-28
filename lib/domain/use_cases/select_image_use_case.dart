import 'dart:io';
import '../../data/repositories/image_repository.dart';
import '../validators.dart';
import 'capture_image_use_case.dart';

/// Use case for selecting an image from the device gallery
class SelectImageUseCase {
  final ImageRepository _imageRepository;

  SelectImageUseCase(this._imageRepository);

  /// Selects an image from gallery with validation and error handling
  /// Returns the selected image file or null if cancelled
  /// Throws [ImageSelectionException] if selection fails
  /// Throws [PermissionDeniedException] if gallery permission is denied
  /// Throws [InvalidImageFormatException] if selected image format is not supported
  Future<File?> execute() async {
    try {
      final imageFile = await _imageRepository.selectFromGallery();

      if (imageFile == null) {
        // User cancelled the operation
        return null;
      }

      // Validate image format
      if (!Validators.isValidImageFormat(imageFile)) {
        throw InvalidImageFormatException(
          'Selected image format is not supported. Only JPEG and PNG formats are allowed.',
        );
      }

      return imageFile;
    } on PermissionDeniedException {
      rethrow;
    } on InvalidImageFormatException {
      rethrow;
    } catch (e) {
      throw ImageSelectionException(
        'Failed to select image from gallery: ${e.toString()}',
      );
    }
  }
}

/// Exception thrown when image selection fails
class ImageSelectionException implements Exception {
  final String message;
  ImageSelectionException(this.message);

  @override
  String toString() => 'ImageSelectionException: $message';
}
