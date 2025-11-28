import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';
import '../../data/models/classification_result.dart';

/// Screen for viewing detailed classification results from history
/// Shows original image, Grad-CAM visualization, and complete classification details
class HistoryDetailScreen extends StatelessWidget {
  final String entryId;

  const HistoryDetailScreen({super.key, required this.entryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classification Details'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareResult(context),
            tooltip: 'Share Result',
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, historyProvider, child) {
          final entry = historyProvider.getEntryById(entryId);

          if (entry == null) {
            return _buildNotFoundView(context);
          }

          return _buildDetailView(context, entry);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _resaveResult(context),
        icon: const Icon(Icons.save_alt),
        label: const Text('Re-save'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildNotFoundView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Classification Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'The requested classification could not be found. It may have been deleted.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailView(BuildContext context, ClassificationResult entry) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy \'at\' HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Classification Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.medical_services,
                        color: Colors.blue[700],
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Classification Result',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'KL Grade: ${entry.klGrade}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getGradeColor(entry.klGrade),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getGradeLabel(entry.klGrade),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Confidence: ${(entry.confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analyzed on ${dateFormat.format(entry.timestamp)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // KL Grade Explanation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About KL Grade ${entry.klGrade}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getGradeExplanation(entry.klGrade),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Original Image
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original X-ray Image',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: _buildImage(entry.imagePath),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Grad-CAM Visualization
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grad-CAM Visualization',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This heatmap shows which regions of the X-ray influenced the AI\'s classification decision. Warmer colors (red/yellow) indicate areas of higher importance.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: _buildImage(entry.gradCamPath),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // All Grade Confidences
          if (entry.allGradeConfidences.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confidence Breakdown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...entry.allGradeConfidences.entries.map((gradeEntry) {
                      final grade = gradeEntry.key;
                      final confidence = gradeEntry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            SizedBox(width: 80, child: Text('Grade $grade:')),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: confidence,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getGradeColor(grade),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 50,
                              child: Text(
                                '${(confidence * 100).toStringAsFixed(1)}%',
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: File(imagePath).existsSync()
          ? Image.file(
              File(imagePath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildImagePlaceholder();
              },
            )
          : _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, color: Colors.grey[400], size: 48),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(int grade) {
    switch (grade) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.lightGreen;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.deepOrange;
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getGradeLabel(int grade) {
    switch (grade) {
      case 0:
        return 'Normal';
      case 1:
        return 'Doubtful';
      case 2:
        return 'Minimal';
      case 3:
        return 'Moderate';
      case 4:
        return 'Severe';
      default:
        return 'Unknown';
    }
  }

  String _getGradeExplanation(int grade) {
    switch (grade) {
      case 0:
        return 'No radiographic features of osteoarthritis are present. The joint space appears normal with no visible osteophytes or other degenerative changes.';
      case 1:
        return 'Doubtful joint space narrowing and possible osteophytic lipping. Early signs that may or may not indicate the beginning of osteoarthritis.';
      case 2:
        return 'Definite osteophytes and possible joint space narrowing. Clear evidence of osteoarthritis with minimal functional impact.';
      case 3:
        return 'Multiple osteophytes, definite joint space narrowing, some sclerosis and possible deformity of bone contour. Moderate osteoarthritis with likely functional impact.';
      case 4:
        return 'Large osteophytes, marked joint space narrowing, severe sclerosis and definite deformity of bone contour. Severe osteoarthritis with significant functional limitations.';
      default:
        return 'Classification not recognized. Please consult with a healthcare professional for proper interpretation.';
    }
  }

  void _shareResult(BuildContext context) {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Share functionality will be implemented in a future update',
        ),
      ),
    );
  }

  void _resaveResult(BuildContext context) {
    // TODO: Implement re-save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Re-save functionality will be implemented in a future update',
        ),
      ),
    );
  }
}
