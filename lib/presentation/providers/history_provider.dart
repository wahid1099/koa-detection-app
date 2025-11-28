import 'package:flutter/foundation.dart';
import '../../data/models/classification_result.dart';
import '../../domain/use_cases/get_history_use_case.dart';
import '../../domain/use_cases/delete_history_entry_use_case.dart';

/// Provider for managing classification history state
class HistoryProvider extends ChangeNotifier {
  final GetHistoryUseCase _getHistoryUseCase;
  final DeleteHistoryEntryUseCase _deleteHistoryEntryUseCase;

  List<ClassificationResult> _historyEntries = [];
  bool _isLoading = false;
  String? _errorMessage;

  HistoryProvider(this._getHistoryUseCase, this._deleteHistoryEntryUseCase);

  /// List of all history entries (sorted in reverse chronological order)
  List<ClassificationResult> get historyEntries =>
      List.unmodifiable(_historyEntries);

  /// Whether history is currently being loaded
  bool get isLoading => _isLoading;

  /// Current error message, if any
  String? get errorMessage => _errorMessage;

  /// Whether there are any history entries
  bool get hasEntries => _historyEntries.isNotEmpty;

  /// Number of total classifications
  int get totalCount => _historyEntries.length;

  /// Load all history entries from repository
  Future<void> loadHistory() async {
    _setLoading(true);
    _clearError();

    try {
      _historyEntries = await _getHistoryUseCase.execute();
      notifyListeners();
    } on HistoryException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to load history: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a history entry by ID
  /// Returns true if successful, false otherwise
  Future<bool> deleteEntry(String id) async {
    _clearError();

    try {
      await _deleteHistoryEntryUseCase.execute(id);

      // Remove from local list
      _historyEntries.removeWhere((entry) => entry.id == id);
      notifyListeners();

      return true;
    } on HistoryException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to delete entry: ${e.toString()}');
      return false;
    }
  }

  /// Get a specific history entry by ID
  ClassificationResult? getEntryById(String id) {
    try {
      return _historyEntries.firstWhere((entry) => entry.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Refresh history by reloading from repository
  Future<void> refresh() async {
    await loadHistory();
  }

  /// Add a new entry to the history (used when a new classification is completed)
  void addEntry(ClassificationResult result) {
    // Insert at the beginning to maintain reverse chronological order
    _historyEntries.insert(0, result);
    notifyListeners();
  }

  /// Clear all error messages
  void clearError() {
    _clearError();
  }

  /// Set error message (for initialization errors)
  void setError(String message) {
    _setError(message);
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
