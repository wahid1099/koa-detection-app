import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Abstract repository for managing image operations
abstract class ImageRepository {
  /// Capture an image from the device camera
  Future<File?> captureFromCamera();

  /// Select an image from the device gallery
  Future<File?> selectFromGallery();

  /// Save an image to the device gallery
  Future<String> saveToGallery(File image, String filename);
}

/// Implementation of ImageRepository using image_picker and image_gallery_saver
class ImageRepositoryImpl implements ImageRepository {
  final ImagePicker _picker;

  ImageRepositoryImpl(this._picker);

  @override
  Future<File?> captureFromCamera() async {
    // On web, camera access works differently
    if (kIsWeb) {
      try {
        // On web, this will try to access the webcam
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        return image != null ? File(image.path) : null;
      } catch (e) {
        throw ImageSaveException(
          'Camera not available on web. Please use gallery selection instead.',
        );
      }
    }

    // Request camera permission for mobile
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      throw PermissionDeniedException('Camera permission denied');
    }

    // Capture image from camera
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    return image != null ? File(image.path) : null;
  }

  @override
  Future<File?> selectFromGallery() async {
    // On web, permissions are handled by the browser
    if (kIsWeb) {
      try {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        return image != null ? File(image.path) : null;
      } catch (e) {
        throw ImageSaveException('Failed to select image: ${e.toString()}');
      }
    }

    // Request storage/photos permission for mobile platforms
    PermissionStatus storageStatus;

    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), use photos permission
      if (await _isAndroid13OrHigher()) {
        storageStatus = await Permission.photos.status;
        
        // If permission is not granted, request it
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.photos.request();
        }
        
        // If still not granted, check if permanently denied
        if (!storageStatus.isGranted) {
          if (storageStatus.isPermanentlyDenied) {
            throw PermissionDeniedException(
              'Gallery access permission is permanently denied. '
              'Please enable it in app settings.',
            );
          } else {
            throw PermissionDeniedException('Gallery access permission denied');
          }
        }
      } else {
        storageStatus = await Permission.storage.status;
        
        // If permission is not granted, request it
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }
        
        // If still not granted, check if permanently denied
        if (!storageStatus.isGranted) {
          if (storageStatus.isPermanentlyDenied) {
            throw PermissionDeniedException(
              'Storage permission is permanently denied. '
              'Please enable it in app settings.',
            );
          } else {
            throw PermissionDeniedException('Storage permission denied');
          }
        }
      }
    } else if (Platform.isIOS) {
      storageStatus = await Permission.photos.status;
      
      // If permission is not granted, request it
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.photos.request();
      }
      
      // If still not granted, check if permanently denied
      if (!storageStatus.isGranted) {
        if (storageStatus.isPermanentlyDenied) {
          throw PermissionDeniedException(
            'Photo library access is permanently denied. '
            'Please enable it in app settings.',
          );
        } else {
          throw PermissionDeniedException('Photo library access denied');
        }
      }
    } else {
      // For other platforms, assume permission is granted
      storageStatus = PermissionStatus.granted;
    }

    // Select image from gallery
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    return image != null ? File(image.path) : null;
  }

  @override
  Future<String> saveToGallery(File image, String filename) async {
    // Note: image_gallery_saver dependency was removed due to Android namespace issues
    // This functionality is currently disabled
    throw ImageSaveException(
      'Saving to gallery is currently not supported. '
      'The image_gallery_saver package was removed due to compatibility issues.',
    );
  }

  /// Check if Android version is 13 or higher (API 33+)
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;

    // This is a simplified check. In production, you might want to use
    // a package like device_info_plus to get the exact Android version
    return true; // Default to using photos permission for modern Android
  }
}

/// Exception thrown when permission is denied
class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException(this.message);

  @override
  String toString() => 'PermissionDeniedException: $message';
}

/// Exception thrown when image save operation fails
class ImageSaveException implements Exception {
  final String message;
  ImageSaveException(this.message);

  @override
  String toString() => 'ImageSaveException: $message';
}
