/// Model representing application settings
class AppSettings {
  final String apiEndpoint;
  final int requestTimeout;

  /// Default Hugging Face API endpoint
  static const String defaultApiEndpoint =
      'https://wahid1099-koa-version-3.hf.space/predict';

  /// Default request timeout in seconds
  static const int defaultRequestTimeout = 30;

  AppSettings({
    required this.apiEndpoint,
    this.requestTimeout = defaultRequestTimeout,
  });

  /// Create default settings
  factory AppSettings.defaultSettings() {
    return AppSettings(
      apiEndpoint: defaultApiEndpoint,
      requestTimeout: defaultRequestTimeout,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {'apiEndpoint': apiEndpoint, 'requestTimeout': requestTimeout};
  }

  /// Create from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      apiEndpoint: json['apiEndpoint'] as String? ?? defaultApiEndpoint,
      requestTimeout: json['requestTimeout'] as int? ?? defaultRequestTimeout,
    );
  }

  /// Create a copy with modified fields
  AppSettings copyWith({String? apiEndpoint, int? requestTimeout}) {
    return AppSettings(
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      requestTimeout: requestTimeout ?? this.requestTimeout,
    );
  }

  /// Check if using default endpoint
  bool get isDefaultEndpoint => apiEndpoint == defaultApiEndpoint;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.apiEndpoint == apiEndpoint &&
        other.requestTimeout == requestTimeout;
  }

  @override
  int get hashCode {
    return Object.hash(apiEndpoint, requestTimeout);
  }

  @override
  String toString() {
    return 'AppSettings(apiEndpoint: $apiEndpoint, requestTimeout: ${requestTimeout}s)';
  }
}
