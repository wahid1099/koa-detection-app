import 'dart:io';
import '../../data/models/classification_result.dart';
import '../../data/repositories/classification_repository.dart';
import '../validators.dart';
import 'capture_image_use_case.dart';

/// Use case for classifying a knee X-ray image
class ClassifyImageUseCase {
  final ClassificationRepository _classificationRepository;

  ClassifyImageUseCase(this._classificationRepository);

  /// Classifies an image with validation and error handling
  /// Returns the classification result
  /// Throws [InvalidImageFormatException] if image format is not supported
  /// Throws [ClassificationException] with user-friendly message for any errors
  Future<ClassificationResult> execute(File imageFile) async {
    // Validate image format
    if (!Validators.isValidImageFormat(imageFile)) {
      throw InvalidImageFormatException(
        'Image format is not supported. Only JPEG and PNG formats are allowed.',
      );
    }

    try {
      // Call repository to classify the image
      final result = await _classificationRepository.classifyImage(imageFile);
      return result;
    } on NetworkException catch (e) {
      // Handle network errors with user-friendly message
      throw ClassificationException(
        _getNetworkErrorMessage(e),
        isNetworkError: true,
      );
    } on ApiException catch (e) {
      // Handle API errors with user-friendly message
      throw ClassificationException(_getApiErrorMessage(e), isApiError: true);
    } catch (e) {
      // Handle unexpected errors
      throw ClassificationException(
        'An unexpected error occurred during classification. Please try again.',
        originalError: e.toString(),
      );
    }
  }

  /// Generates user-friendly message for network errors
  String _getNetworkErrorMessage(NetworkException error) {
    final message = error.message.toLowerCase();

    if (message.contains('timeout')) {
      return 'The request timed out. Please check your internet connection and try again.';
    } else if (message.contains('no internet') ||
        message.contains('network unreachable')) {
      return 'No internet connection. Please check your network settings and try again.';
    } else if (message.contains('dns') || message.contains('host')) {
      return 'Unable to reach the server. Please check the API endpoint in settings.';
    } else {
      return 'A network error occurred. Please check your internet connection and try again.';
    }
  }

  /// Generates user-friendly message for API errors
  String _getApiErrorMessage(ApiException error) {
    if (error.statusCode != null) {
      if (error.statusCode! >= 400 && error.statusCode! < 500) {
        return 'Invalid request to the classification service. Please try again or contact support.';
      } else if (error.statusCode! >= 500) {
        return 'The classification service is currently unavailable. Please try again later.';
      }
    }

    return 'The classification service returned an error: ${error.message}';
  }
}

/// Exception thrown when classification fails
class ClassificationException implements Exception {
  final String message;
  final bool isNetworkError;
  final bool isApiError;
  final String? originalError;

  ClassificationException(
    this.message, {
    this.isNetworkError = false,
    this.isApiError = false,
    this.originalError,
  });

  @override
  String toString() => 'ClassificationException: $message';
}
