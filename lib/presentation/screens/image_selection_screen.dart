import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/use_cases/capture_image_use_case.dart';
import '../../domain/use_cases/select_image_use_case.dart';
import '../../data/repositories/image_repository.dart';
import 'classification_screen.dart';

/// Screen for selecting or capturing images for classification
class ImageSelectionScreen extends StatefulWidget {
  const ImageSelectionScreen({super.key});

  @override
  State<ImageSelectionScreen> createState() => _ImageSelectionScreenState();
}

class _ImageSelectionScreenState extends State<ImageSelectionScreen> {
  File? _selectedImage;
  String? _errorMessage;
  bool _isLoading = false;

  late final CaptureImageUseCase _captureImageUseCase;
  late final SelectImageUseCase _selectImageUseCase;

  @override
  void initState() {
    super.initState();
    // Initialize use cases with repository
    final imageRepository = ImageRepositoryImpl(ImagePicker());
    _captureImageUseCase = CaptureImageUseCase(imageRepository);
    _selectImageUseCase = SelectImageUseCase(imageRepository);
  }

  Future<void> _handleCameraCapture() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final imageFile = await _captureImageUseCase.execute();

      if (mounted) {
        setState(() {
          _selectedImage = imageFile;
          _isLoading = false;
        });
      }
    } on PermissionDeniedException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
        // Check if permission is permanently denied
        final isPermanentlyDenied = _errorMessage!.contains('permanently denied');
        _showErrorDialog(
          'Permission Denied',
          _errorMessage!,
          showSettingsButton: isPermanentlyDenied,
        );
      }
    } on InvalidImageFormatException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
        _showErrorDialog('Invalid Format', _errorMessage!);
      }
    } on ImageCaptureException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to capture image: ${e.message}';
          _isLoading = false;
        });
        _showErrorDialog('Capture Failed', _errorMessage!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred: ${e.toString()}';
          _isLoading = false;
        });
        _showErrorDialog('Error', _errorMessage!);
      }
    }
  }

  Future<void> _handleGallerySelection() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final imageFile = await _selectImageUseCase.execute();

      if (mounted) {
        setState(() {
          _selectedImage = imageFile;
          _isLoading = false;
        });
      }
    } on PermissionDeniedException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
        // Check if permission is permanently denied
        final isPermanentlyDenied = _errorMessage!.contains('permanently denied');
        _showErrorDialog(
          'Permission Denied',
          _errorMessage!,
          showSettingsButton: isPermanentlyDenied,
        );
      }
    } on InvalidImageFormatException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
        _showErrorDialog('Invalid Format', _errorMessage!);
      }
    } on ImageSelectionException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to select image: ${e.message}';
          _isLoading = false;
        });
        _showErrorDialog('Selection Failed', _errorMessage!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred: ${e.toString()}';
          _isLoading = false;
        });
        _showErrorDialog('Error', _errorMessage!);
      }
    }
  }

  void _showErrorDialog(String title, String message, {bool showSettingsButton = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (showSettingsButton)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(showSettingsButton ? 'Cancel' : 'OK'),
          ),
        ],
      ),
    );
  }

  void _proceedToClassification() {
    if (_selectedImage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ClassificationScreen(imageFile: _selectedImage!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Classification'),
        backgroundColor: Colors.blue[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instructions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Image Source',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            kIsWeb
                                ? 'Select an image file from your computer. Only JPEG and PNG formats are supported. Note: Camera capture is not available on web browsers.'
                                : 'Choose to capture a new knee X-ray image or select from your gallery. Only JPEG and PNG formats are supported.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Camera button (hide on web)
                  if (!kIsWeb) ...[
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleCameraCapture,
                      icon: const Icon(Icons.camera_alt, size: 32),
                      label: const Text('Capture from Camera'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(20),
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Gallery button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleGallerySelection,
                    icon: const Icon(Icons.photo_library, size: 32),
                    label: const Text('Select from Gallery'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Image preview section
                  if (_selectedImage != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Image Preview',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? Image.network(
                                      _selectedImage!.path,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              height: 200,
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: Text(
                                                  'Failed to load image',
                                                ),
                                              ),
                                            );
                                          },
                                    )
                                  : Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              height: 200,
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: Text(
                                                  'Failed to load image',
                                                ),
                                              ),
                                            );
                                          },
                                    ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _proceedToClassification,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                              ),
                              child: const Text('Proceed to Classification'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Error message display
                  if (_errorMessage != null && _selectedImage == null) ...[
                    Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
