import '../../data/repositories/settings_repository.dart';
import '../validators.dart';

/// Use case for updating the API endpoint configuration
class UpdateApiEndpointUseCase {
  final SettingsRepository _settingsRepository;

  UpdateApiEndpointUseCase(this._settingsRepository);

  /// Updates the API endpoint URL with validation
  /// Throws [InvalidUrlException] if URL format is invalid
  /// Throws [UpdateEndpointException] if update fails
  Future<void> execute(String url) async {
    // Validate URL format
    if (!Validators.isValidUrl(url)) {
      throw InvalidUrlException(
        'Invalid URL format. Please enter a valid HTTP or HTTPS URL.',
      );
    }

    try {
      await _settingsRepository.setApiEndpoint(url);
    } catch (e) {
      throw UpdateEndpointException(
        'Failed to update API endpoint: ${e.toString()}',
      );
    }
  }
}

/// Exception thrown when URL is invalid
class InvalidUrlException implements Exception {
  final String message;
  InvalidUrlException(this.message);

  @override
  String toString() => 'InvalidUrlException: $message';
}

/// Exception thrown when endpoint update fails
class UpdateEndpointException implements Exception {
  final String message;
  UpdateEndpointException(this.message);

  @override
  String toString() => 'UpdateEndpointException: $message';
}
