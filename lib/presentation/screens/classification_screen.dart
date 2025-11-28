import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/classification_result.dart';
import '../../data/repositories/classification_repository_impl.dart';
import '../../data/repositories/image_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/use_cases/classify_image_use_case.dart';
import '../../domain/use_cases/save_result_use_case.dart';

/// Screen for displaying classification progress and results
/// Shows upload progress, KL grade, confidence, Grad-CAM visualization
/// Provides save and share functionality
class ClassificationScreen extends StatefulWidget {
  final File imageFile;

  const ClassificationScreen({super.key, required this.imageFile});

  @override
  State<ClassificationScreen> createState() => _ClassificationScreenState();
}

class _ClassificationScreenState extends State<ClassificationScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  ClassificationResult? _result;
  String? _errorMessage;
  String? _saveMessage;

  @override
  void initState() {
    super.initState();
    _classifyImage();
  }

  /// Classify the image using the use case
  Future<void> _classifyImage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create real repository implementation
      final prefs = await SharedPreferences.getInstance();
      final settingsRepository = SettingsRepositoryImpl(prefs);
      final classificationRepository = ClassificationRepositoryImpl(
        settingsRepository,
        http.Client(),
      );
      final classifyUseCase = ClassifyImageUseCase(classificationRepository);

      final result = await classifyUseCase.execute(widget.imageFile);

      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } on ClassificationException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// Save the classification result to gallery
  Future<void> _saveResult() async {
    if (_result == null) return;

    setState(() {
      _isSaving = true;
      _saveMessage = null;
    });

    try {
      // TODO: Replace with actual repository implementation
      final imageRepository = ImageRepositoryImpl(ImagePicker());
      final saveUseCase = SaveResultUseCase(imageRepository);

      final savedPath = await saveUseCase.execute(_result!);

      if (mounted) {
        setState(() {
          _saveMessage = 'Result saved to gallery: $savedPath';
          _isSaving = false;
        });
      }
    } on PermissionDeniedException {
      if (mounted) {
        setState(() {
          _saveMessage =
              'Storage permission denied. Please grant permission in settings to save results.';
          _isSaving = false;
        });
      }
    } on SaveResultException catch (e) {
      if (mounted) {
        setState(() {
          _saveMessage = 'Failed to save result: ${e.message}';
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saveMessage = 'An unexpected error occurred while saving.';
          _isSaving = false;
        });
      }
    }
  }

  /// Get explanation text for a KL grade
  String _getKlGradeExplanation(int klGrade) {
    switch (klGrade) {
      case 0:
        return 'No osteoarthritis detected. The joint appears healthy.';
      case 1:
        return 'Doubtful osteoarthritis. Minimal changes may be present.';
      case 2:
        return 'Mild osteoarthritis. Definite osteophytes and possible joint space narrowing.';
      case 3:
        return 'Moderate osteoarthritis. Multiple osteophytes and definite joint space narrowing.';
      case 4:
        return 'Severe osteoarthritis. Large osteophytes, marked joint space narrowing, and bone deformity.';
      default:
        return 'Unknown KL grade.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classification Results'),
        backgroundColor: Colors.blue[700],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingView();
    } else if (_errorMessage != null) {
      return _buildErrorView();
    } else if (_result != null) {
      return _buildResultsView();
    } else {
      return const Center(child: Text('No results available'));
    }
  }

  /// Build loading view with progress indicator
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Analyzing image...',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// Build error view with retry option
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 24),
            Text(
              'Classification Failed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _classifyImage,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48),
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build results view with classification details
  Widget _buildResultsView() {
    final result = _result!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KL Grade Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    'KL Grade',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result.klGrade}',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Explanation Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'What does this mean?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getKlGradeExplanation(result.klGrade),
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Original Image
          Card(
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Original X-Ray',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                kIsWeb
                    ? Image.network(
                        result.imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.error, size: 48),
                            ),
                          );
                        },
                      )
                    : Image.file(
                        File(result.imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.error, size: 48),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Grad-CAM Visualization
          Card(
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grad-CAM Visualization',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Highlighted regions influenced the classification',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                kIsWeb
                    ? Image.network(
                        result.gradCamPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.error, size: 48),
                            ),
                          );
                        },
                      )
                    : Image.file(
                        File(result.gradCamPath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.error, size: 48),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save Message
          if (_saveMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Card(
                color: _saveMessage!.contains('saved to gallery')
                    ? Colors.green[50]
                    : Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        _saveMessage!.contains('saved to gallery')
                            ? Icons.check_circle
                            : Icons.warning,
                        color: _saveMessage!.contains('saved to gallery')
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _saveMessage!,
                          style: TextStyle(
                            color: _saveMessage!.contains('saved to gallery')
                                ? Colors.green[900]
                                : Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveResult,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save to Gallery'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () {
                          // TODO: Implement share functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Share functionality coming soon'),
                            ),
                          );
                        },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
