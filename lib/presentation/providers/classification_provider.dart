import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../data/models/classification_result.dart';
import '../../data/repositories/image_repository.dart';
import '../../domain/use_cases/capture_image_use_case.dart';
import '../../domain/use_cases/select_image_use_case.dart';
import '../../domain/use_cases/classify_image_use_case.dart';
import '../../domain/use_cases/save_result_use_case.dart';
import '../../domain/use_cases/save_to_history_use_case.dart';

/// Enumeration of classification workflow states
enum ClassificationState {
  idle,
  selectingImage,
  imageSelected,
  classifying,
  success,
  error,
  saving,
  saved,
}

/// Provider for managing classification workflow state
class ClassificationProvider extends ChangeNotifier {
  final CaptureImageUseCase _captureImageUseCase;
  final SelectImageUseCase _selectImageUseCase;
  final ClassifyImageUseCase _classifyImageUseCase;
  final SaveResultUseCase _saveResultUseCase;
  final SaveToHistoryUseCase _saveToHistoryUseCase;

  ClassificationState _state = ClassificationState.idle;
  File? _selectedImage;
  ClassificationResult? _classificationResult;
  String? _errorMessage;
  String? _savedImagePath;

  ClassificationProvider(
    this._captureImageUseCase,
    this._selectImageUseCase,
    this._classifyImageUseCase,
    this._saveResultUseCase,
    this._saveToHistoryUseCase,
  );

  /// Current classification workflow state
  ClassificationState get state => _state;

  /// Currently selected image file
  File? get selectedImage => _selectedImage;

  /// Current classification result
  ClassificationResult? get classificationResult => _classificationResult;

  /// Current error message, if any
  String? get errorMessage => _errorMessage;

  /// Path where the result was saved, if any
  String? get savedImagePath => _savedImagePath;

  /// Whether the provider is in a loading state
  bool get isLoading =>
      _state == ClassificationState.selectingImage ||
      _state == ClassificationState.classifying ||
      _state == ClassificationState.saving;

  /// Whether interactions should be disabled
  bool get isInteractionDisabled => isLoading;

  /// Whether there is a classification result available
  bool get hasResult => _classificationResult != null;

  /// Whether there is an error
  bool get hasError => _state == ClassificationState.error;

  /// Capture an image from camera
  Future<void> captureImage() async {
    _setState(ClassificationState.selectingImage);
    _clearError();

    try {
      final imageFile = await _captureImageUseCase.execute();

      if (imageFile != null) {
        _selectedImage = imageFile;
        _setState(ClassificationState.imageSelected);
      } else {
        // User cancelled
        _setState(ClassificationState.idle);
      }
    } on PermissionDeniedException catch (e) {
      _setError(
        'Camera permission is required to capture images. Please grant permission in settings.',
      );
    } on InvalidImageFormatException catch (e) {
      _setError(e.message);
    } on ImageCaptureException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to capture image: ${e.toString()}');
    }
  }

  /// Select an image from gallery
  Future<void> selectImage() async {
    _setState(ClassificationState.selectingImage);
    _clearError();

    try {
      final imageFile = await _selectImageUseCase.execute();

      if (imageFile != null) {
        _selectedImage = imageFile;
        _setState(ClassificationState.imageSelected);
      } else {
        // User cancelled
        _setState(ClassificationState.idle);
      }
    } on PermissionDeniedException catch (e) {
      _setError(
        'Gallery access permission is required to select images. Please grant permission in settings.',
      );
    } on InvalidImageFormatException catch (e) {
      _setError(e.message);
    } on ImageSelectionException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to select image: ${e.toString()}');
    }
  }

  /// Classify the selected image
  Future<void> classifyImage() async {
    if (_selectedImage == null) {
      _setError('No image selected for classification');
      return;
    }

    _setState(ClassificationState.classifying);
    _clearError();

    try {
      final result = await _classifyImageUseCase.execute(_selectedImage!);

      _classificationResult = result;

      // Save to history automatically
      await _saveToHistoryUseCase.execute(result);

      _setState(ClassificationState.success);
    } on ClassificationException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Classification failed: ${e.toString()}');
    }
  }

  /// Save the classification result to gallery
  Future<void> saveResult() async {
    if (_classificationResult == null) {
      _setError('No classification result to save');
      return;
    }

    _setState(ClassificationState.saving);
    _clearError();

    try {
      final savedPath = await _saveResultUseCase.execute(
        _classificationResult!,
      );

      _savedImagePath = savedPath;
      _setState(ClassificationState.saved);
    } on PermissionDeniedException catch (e) {
      _setError(
        'Storage permission is required to save images. Please grant permission in settings.',
      );
    } on SaveResultException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to save result: ${e.toString()}');
    }
  }

  /// Reset the classification workflow to start over
  void reset() {
    _selectedImage = null;
    _classificationResult = null;
    _savedImagePath = null;
    _setState(ClassificationState.idle);
    _clearError();
  }

  /// Clear any error and return to appropriate state
  void clearError() {
    _clearError();

    if (_classificationResult != null) {
      _setState(ClassificationState.success);
    } else if (_selectedImage != null) {
      _setState(ClassificationState.imageSelected);
    } else {
      _setState(ClassificationState.idle);
    }
  }

  /// Set the current state
  void _setState(ClassificationState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  /// Set error message and state
  void _setError(String message) {
    _errorMessage = message;
    _setState(ClassificationState.error);
  }

  /// Clear error message
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
