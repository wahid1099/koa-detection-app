import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';
import '../../data/models/classification_result.dart';
import '../../data/repositories/history_repository.dart';
import '../../domain/use_cases/get_history_use_case.dart';
import '../../domain/use_cases/delete_history_entry_use_case.dart';

/// Screen for viewing classification history
/// Displays all previous classifications in reverse chronological order
/// with thumbnails, KL grades, confidence scores, and timestamps
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HistoryProvider>(
      future: _createHistoryProvider(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Classification History'),
              backgroundColor: Colors.blue[700],
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Classification History'),
              backgroundColor: Colors.blue[700],
            ),
            body: Center(
              child: Text('Error initializing history: ${snapshot.error}'),
            ),
          );
        }

        return ChangeNotifierProvider<HistoryProvider>.value(
          value: snapshot.data!,
          child: const _HistoryScreenContent(),
        );
      },
    );
  }

  Future<HistoryProvider> _createHistoryProvider() async {
    try {
      final historyRepository = HistoryRepositoryImpl();
      final getHistoryUseCase = GetHistoryUseCase(historyRepository);
      final deleteHistoryEntryUseCase = DeleteHistoryEntryUseCase(
        historyRepository,
      );

      final provider = HistoryProvider(
        getHistoryUseCase,
        deleteHistoryEntryUseCase,
      );

      // Load history with proper error handling
      await provider.loadHistory();
      return provider;
    } catch (e) {
      // If there's an error, create a provider anyway but don't load history
      // This allows the UI to show the error gracefully
      final historyRepository = HistoryRepositoryImpl();
      final getHistoryUseCase = GetHistoryUseCase(historyRepository);
      final deleteHistoryEntryUseCase = DeleteHistoryEntryUseCase(
        historyRepository,
      );

      final provider = HistoryProvider(
        getHistoryUseCase,
        deleteHistoryEntryUseCase,
      );

      // Set the error message directly
      provider.setError('Database initialization failed: ${e.toString()}');
      return provider;
    }
  }
}

class _HistoryScreenContent extends StatefulWidget {
  const _HistoryScreenContent();

  @override
  State<_HistoryScreenContent> createState() => _HistoryScreenContentState();
}

class _HistoryScreenContentState extends State<_HistoryScreenContent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classification History'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<HistoryProvider>().refresh(),
            tooltip: 'Refresh History',
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, historyProvider, child) {
          if (historyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (historyProvider.errorMessage != null) {
            return _buildErrorView(historyProvider.errorMessage!);
          }

          if (!historyProvider.hasEntries) {
            return _buildEmptyView();
          }

          return _buildHistoryList(historyProvider.historyEntries);
        },
      ),
    );
  }

  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error Loading History',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<HistoryProvider>().refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Classifications Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Your classification history will appear here after you analyze your first X-ray image.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Start Classification'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<ClassificationResult> entries) {
    return RefreshIndicator(
      onRefresh: () => context.read<HistoryProvider>().refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _buildHistoryCard(entry);
        },
      ),
    );
  }

  Widget _buildHistoryCard(ClassificationResult entry) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: ListTile(
        leading: _buildThumbnail(entry.imagePath),
        title: Row(
          children: [
            Text(
              'KL Grade: ${entry.klGrade}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getGradeColor(entry.klGrade),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getGradeLabel(entry.klGrade),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Confidence: ${(entry.confidence * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 2),
            Text(
              dateFormat.format(entry.timestamp),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteConfirmation(entry);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _navigateToDetail(entry),
      ),
    );
  }

  Widget _buildThumbnail(String imagePath) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: File(imagePath).existsSync()
            ? Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildThumbnailPlaceholder();
                },
              )
            : _buildThumbnailPlaceholder(),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 24),
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

  void _navigateToDetail(ClassificationResult entry) {
    Navigator.of(context).pushNamed('/history-detail', arguments: entry.id);
  }

  void _showDeleteConfirmation(ClassificationResult entry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Classification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete this classification?',
              ),
              const SizedBox(height: 8),
              Text(
                'KL Grade: ${entry.klGrade}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(entry.timestamp)}',
              ),
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteEntry(entry);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEntry(ClassificationResult entry) async {
    final historyProvider = context.read<HistoryProvider>();
    final success = await historyProvider.deleteEntry(entry.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Classification deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            historyProvider.errorMessage ?? 'Failed to delete classification',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
