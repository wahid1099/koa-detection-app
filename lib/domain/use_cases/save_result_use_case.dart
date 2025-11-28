import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../data/models/classification_result.dart';
import '../../data/repositories/image_repository.dart';

/// Use case for saving classification results to device gallery
class SaveResultUseCase {
  final ImageRepository _imageRepository;

  SaveResultUseCase(this._imageRepository);

  /// Saves a classification result as a composite image to the gallery
  /// Returns the path where the image was saved
  /// Throws [SaveResultException] if save operation fails
  Future<String> execute(ClassificationResult result) async {
    try {
      // Generate composite image
      final compositeFile = await _generateCompositeImage(result);

      // Save to gallery
      final savedPath = await _imageRepository.saveToGallery(
        compositeFile,
        'koa_result_${result.id}.jpg',
      );

      // Clean up temporary file
      try {
        await compositeFile.delete();
      } catch (_) {
        // Ignore cleanup errors
      }

      return savedPath;
    } on PermissionDeniedException {
      rethrow;
    } catch (e) {
      throw SaveResultException(
        'Failed to save classification result: ${e.toString()}',
      );
    }
  }

  /// Generates a composite image containing original X-ray, KL grade, confidence, and Grad-CAM
  Future<File> _generateCompositeImage(ClassificationResult result) async {
    try {
      // Load original image
      final originalFile = File(result.imagePath);
      final originalBytes = await originalFile.readAsBytes();
      final originalImage = img.decodeImage(originalBytes);

      if (originalImage == null) {
        throw SaveResultException('Failed to decode original image');
      }

      // Load Grad-CAM image
      final gradCamFile = File(result.gradCamPath);
      final gradCamBytes = await gradCamFile.readAsBytes();
      final gradCamImage = img.decodeImage(gradCamBytes);

      if (gradCamImage == null) {
        throw SaveResultException('Failed to decode Grad-CAM image');
      }

      // Calculate dimensions for composite image
      final width = originalImage.width;
      final height = originalImage.height;
      final textHeight = 120; // Space for text information
      final compositeHeight =
          height * 2 + textHeight; // Original + Grad-CAM + text

      // Create composite image
      final composite = img.Image(width: width, height: compositeHeight);

      // Fill with white background
      img.fill(composite, color: img.ColorRgb8(255, 255, 255));

      // Copy original image to top
      img.compositeImage(composite, originalImage, dstY: 0);

      // Resize Grad-CAM to match original dimensions if needed
      final resizedGradCam = img.copyResize(
        gradCamImage,
        width: width,
        height: height,
      );

      // Copy Grad-CAM below original
      img.compositeImage(composite, resizedGradCam, dstY: height);

      // Add text information
      final textY = height * 2 + 10;
      final klGradeText = 'KL Grade: ${result.klGrade}';
      final confidenceText =
          'Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%';
      final timestampText =
          'Date: ${result.timestamp.toString().split('.')[0]}';

      // Draw text (using simple text drawing)
      _drawText(composite, klGradeText, 10, textY);
      _drawText(composite, confidenceText, 10, textY + 30);
      _drawText(composite, timestampText, 10, textY + 60);

      // Encode to JPEG
      final jpegBytes = img.encodeJpg(composite, quality: 90);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/composite_${result.id}.jpg');
      await tempFile.writeAsBytes(jpegBytes);

      return tempFile;
    } catch (e) {
      throw SaveResultException(
        'Failed to generate composite image: ${e.toString()}',
      );
    }
  }

  /// Simple text drawing function
  void _drawText(img.Image image, String text, int x, int y) {
    // Use the image package's drawString function
    img.drawString(
      image,
      text,
      font: img.arial24,
      x: x,
      y: y,
      color: img.ColorRgb8(0, 0, 0),
    );
  }
}

/// Exception thrown when save result operation fails
class SaveResultException implements Exception {
  final String message;
  SaveResultException(this.message);

  @override
  String toString() => 'SaveResultException: $message';
}
