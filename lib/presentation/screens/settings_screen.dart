import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/app_settings.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/use_cases/update_api_endpoint_use_case.dart';
import '../../presentation/providers/settings_provider.dart';

/// Screen for app settings and configuration
/// Displays current API endpoint URL, provides text field for modification
/// Implements save and reset buttons, shows validation errors for invalid URLs
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsProvider _settingsProvider;
  final TextEditingController _endpointController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeProvider();
  }

  /// Initialize the settings provider and load current settings
  Future<void> _initializeProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsRepository = SettingsRepositoryImpl(prefs);
    final updateApiEndpointUseCase = UpdateApiEndpointUseCase(
      settingsRepository,
    );

    _settingsProvider = SettingsProvider(
      settingsRepository,
      updateApiEndpointUseCase,
    );

    // Load current settings
    await _settingsProvider.loadSettings();

    // Set the current endpoint in the text field
    _endpointController.text = _settingsProvider.apiEndpoint;

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _endpointController.dispose();
    super.dispose();
  }

  /// Validate URL format
  String? _validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an API endpoint URL';
    }

    if (!_settingsProvider.isValidUrl(value)) {
      return 'Please enter a valid HTTP or HTTPS URL';
    }

    return null;
  }

  /// Save the new API endpoint
  Future<void> _saveEndpoint() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await _settingsProvider.updateApiEndpoint(
      _endpointController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API endpoint updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Reset to default endpoint
  Future<void> _resetToDefault() async {
    final confirmed = await _showResetConfirmationDialog();
    if (!confirmed) return;

    final success = await _settingsProvider.resetToDefault();

    if (success && mounted) {
      _endpointController.text = _settingsProvider.apiEndpoint;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings reset to default'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Show confirmation dialog for reset action
  Future<bool> _showResetConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Colors.blue[700],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // API Configuration Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.api, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'API Configuration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'API Endpoint URL',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _endpointController,
                        validator: _validateUrl,
                        decoration: const InputDecoration(
                          hintText: 'Enter API endpoint URL',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                        ),
                        keyboardType: TextInputType.url,
                        enabled: !_settingsProvider.isLoading,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Default: ${AppSettings.defaultApiEndpoint}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (_settingsProvider.errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red[300]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error,
                                color: Colors.red[700],
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _settingsProvider.errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _settingsProvider.isLoading
                          ? null
                          : _saveEndpoint,
                      icon: _settingsProvider.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _settingsProvider.isLoading
                          ? null
                          : _resetToDefault,
                      icon: const Icon(Icons.restore),
                      label: const Text('Reset to Default'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Current Settings Info
              Card(
                elevation: 1,
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
                            'Current Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'API Endpoint',
                        _settingsProvider.apiEndpoint,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Request Timeout',
                        '${_settingsProvider.requestTimeout}s',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Using Default',
                        _settingsProvider.settings.isDefaultEndpoint
                            ? 'Yes'
                            : 'No',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build an info row for the current settings display
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}
