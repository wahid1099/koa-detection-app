import '../../data/models/classification_result.dart';
import '../../data/repositories/history_repository.dart';
import 'get_history_use_case.dart';

/// Use case for saving a classification result to history
class SaveToHistoryUseCase {
  final HistoryRepository _historyRepository;

  SaveToHistoryUseCase(this._historyRepository);

  /// Saves a classification result to history
  /// Throws [HistoryException] if save fails
  Future<void> execute(ClassificationResult result) async {
    try {
      await _historyRepository.save(result);
    } catch (e) {
      throw HistoryException(
        'Failed to save classification to history: ${e.toString()}',
      );
    }
  }
}
