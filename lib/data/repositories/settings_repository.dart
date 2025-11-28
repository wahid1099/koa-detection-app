import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

/// Abstract repository for managing application settings
abstract class SettingsRepository {
  /// Get the current API endpoint URL
  Future<String> getApiEndpoint();

  /// Set a new API endpoint URL
  Future<void> setApiEndpoint(String url);

  /// Reset settings to default values
  Future<void> resetToDefault();

  /// Get complete app settings
  Future<AppSettings> getSettings();

  /// Save complete app settings
  Future<void> saveSettings(AppSettings settings);
}

/// Implementation of SettingsRepository using SharedPreferences
class SettingsRepositoryImpl implements SettingsRepository {
  static const String _keyApiEndpoint = 'api_endpoint';
  static const String _keyRequestTimeout = 'request_timeout';

  final SharedPreferences _prefs;

  SettingsRepositoryImpl(this._prefs);

  @override
  Future<String> getApiEndpoint() async {
    return _prefs.getString(_keyApiEndpoint) ?? AppSettings.defaultApiEndpoint;
  }

  @override
  Future<void> setApiEndpoint(String url) async {
    await _prefs.setString(_keyApiEndpoint, url);
  }

  @override
  Future<void> resetToDefault() async {
    await _prefs.remove(_keyApiEndpoint);
    await _prefs.remove(_keyRequestTimeout);
  }

  @override
  Future<AppSettings> getSettings() async {
    final apiEndpoint =
        _prefs.getString(_keyApiEndpoint) ?? AppSettings.defaultApiEndpoint;
    final requestTimeout =
        _prefs.getInt(_keyRequestTimeout) ?? AppSettings.defaultRequestTimeout;

    return AppSettings(
      apiEndpoint: apiEndpoint,
      requestTimeout: requestTimeout,
    );
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_keyApiEndpoint, settings.apiEndpoint);
    await _prefs.setInt(_keyRequestTimeout, settings.requestTimeout);
  }
}
