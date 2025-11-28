import 'package:flutter/foundation.dart';
import '../../data/models/app_settings.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/use_cases/update_api_endpoint_use_case.dart';
import '../../domain/validators.dart';

/// Provider for managing application settings state
class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _settingsRepository;
  final UpdateApiEndpointUseCase _updateApiEndpointUseCase;

  AppSettings _settings = AppSettings(
    apiEndpoint: AppSettings.defaultApiEndpoint,
    requestTimeout: AppSettings.defaultRequestTimeout,
  );

  bool _isLoading = false;
  String? _errorMessage;

  SettingsProvider(this._settingsRepository, this._updateApiEndpointUseCase);

  /// Current app settings
  AppSettings get settings => _settings;

  /// Current API endpoint URL
  String get apiEndpoint => _settings.apiEndpoint;

  /// Current request timeout in seconds
  int get requestTimeout => _settings.requestTimeout;

  /// Whether settings are currently being loaded or saved
  bool get isLoading => _isLoading;

  /// Current error message, if any
  String? get errorMessage => _errorMessage;

  /// Load settings from repository
  Future<void> loadSettings() async {
    _setLoading(true);
    _clearError();

    try {
      _settings = await _settingsRepository.getSettings();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load settings: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Update the API endpoint URL
  /// Returns true if successful, false otherwise
  Future<bool> updateApiEndpoint(String newEndpoint) async {
    _setLoading(true);
    _clearError();

    try {
      await _updateApiEndpointUseCase.execute(newEndpoint);

      // Reload settings to get the updated value
      await loadSettings();
      return true;
    } on ValidationException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to update API endpoint: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset settings to default values
  Future<bool> resetToDefault() async {
    _setLoading(true);
    _clearError();

    try {
      await _settingsRepository.resetToDefault();

      // Reload settings to get the default values
      await loadSettings();
      return true;
    } catch (e) {
      _setError('Failed to reset settings: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Validate if a URL is properly formatted
  bool isValidUrl(String url) {
    return Validators.isValidUrl(url);
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

/// Exception thrown when validation fails
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}
