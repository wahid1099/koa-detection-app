import '../../data/models/classification_result.dart';
import '../../data/repositories/history_repository.dart';

/// Use case for retrieving classification history
class GetHistoryUseCase {
  final HistoryRepository _historyRepository;

  GetHistoryUseCase(this._historyRepository);

  /// Retrieves all classification history sorted in reverse chronological order
  /// Returns list of classification results (newest first)
  /// Throws [HistoryException] if retrieval fails
  Future<List<ClassificationResult>> execute() async {
    try {
      final results = await _historyRepository.getAll();

      // Sort by timestamp in descending order (newest first)
      results.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return results;
    } catch (e) {
      throw HistoryException(
        'Failed to retrieve classification history: ${e.toString()}',
      );
    }
  }
}

/// Exception thrown when history operations fail
class HistoryException implements Exception {
  final String message;
  HistoryException(this.message);

  @override
  String toString() => 'HistoryException: $message';
}
