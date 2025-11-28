import '../../data/repositories/history_repository.dart';
import 'get_history_use_case.dart';

/// Use case for deleting a classification result from history
class DeleteHistoryEntryUseCase {
  final HistoryRepository _historyRepository;

  DeleteHistoryEntryUseCase(this._historyRepository);

  /// Deletes a classification result from history by ID
  /// Note: Confirmation should be handled at the UI layer before calling this
  /// Throws [HistoryException] if deletion fails
  /// Throws [HistoryEntryNotFoundException] if entry doesn't exist
  Future<void> execute(String id) async {
    try {
      // Verify entry exists before attempting deletion
      final entry = await _historyRepository.getById(id);
      if (entry == null) {
        throw HistoryEntryNotFoundException(
          'Classification result with ID $id not found',
        );
      }

      await _historyRepository.delete(id);
    } on HistoryEntryNotFoundException {
      rethrow;
    } catch (e) {
      throw HistoryException(
        'Failed to delete classification from history: ${e.toString()}',
      );
    }
  }
}

/// Exception thrown when a history entry is not found
class HistoryEntryNotFoundException implements Exception {
  final String message;
  HistoryEntryNotFoundException(this.message);

  @override
  String toString() => 'HistoryEntryNotFoundException: $message';
}
