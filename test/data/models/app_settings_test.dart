import 'package:flutter_test/flutter_test.dart';
import 'package:koa_detecion/data/models/app_settings.dart';

void main() {
  group('AppSettings', () {
    // Feature: koa-detection-app, Property 20: Settings persistence round-trip
    // For any valid API endpoint URL saved to settings, retrieving the settings
    // should return the same URL.
    test('property: serialization round-trip preserves all settings', () {
      // Test with 100 different configurations
      for (int i = 0; i < 100; i++) {
        final originalSettings = AppSettings(
          apiEndpoint: 'https://api.example.com/v$i/predict',
          requestTimeout: 10 + (i % 50), // Timeout between 10-59 seconds
        );

        // Serialize to JSON
        final json = originalSettings.toJson();

        // Deserialize from JSON
        final deserializedSettings = AppSettings.fromJson(json);

        // Verify all fields are preserved
        expect(
          deserializedSettings.apiEndpoint,
          equals(originalSettings.apiEndpoint),
          reason: 'API endpoint should be preserved',
        );
        expect(
          deserializedSettings.requestTimeout,
          equals(originalSettings.requestTimeout),
          reason: 'Request timeout should be preserved',
        );
      }
    });

    test('property: handles various valid URL formats', () {
      final urlTestCases = [
        'https://api.example.com/predict',
        'https://huggingface.co/spaces/user/model/predict',
        'http://localhost:8000/api/classify',
        'https://api-v2.example.com:8443/ml/predict',
        'https://subdomain.domain.co.uk/path/to/endpoint',
      ];

      for (final url in urlTestCases) {
        final settings = AppSettings(apiEndpoint: url, requestTimeout: 30);

        final json = settings.toJson();
        final deserialized = AppSettings.fromJson(json);

        expect(deserialized.apiEndpoint, equals(url));
      }
    });

    test('property: handles edge case timeout values', () {
      final timeoutTestCases = [1, 5, 30, 60, 120, 300];

      for (final timeout in timeoutTestCases) {
        final settings = AppSettings(
          apiEndpoint: 'https://api.example.com/predict',
          requestTimeout: timeout,
        );

        final json = settings.toJson();
        final deserialized = AppSettings.fromJson(json);

        expect(deserialized.requestTimeout, equals(timeout));
      }
    });

    test('property: default settings are consistent', () {
      for (int i = 0; i < 10; i++) {
        final settings1 = AppSettings.defaultSettings();
        final settings2 = AppSettings.defaultSettings();

        expect(settings1.apiEndpoint, equals(settings2.apiEndpoint));
        expect(settings1.requestTimeout, equals(settings2.requestTimeout));
        expect(settings1, equals(settings2));
      }
    });

    test('property: fromJson handles missing fields with defaults', () {
      final testCases = [
        <String, dynamic>{}, // Empty JSON
        {'apiEndpoint': 'https://custom.api.com/predict'}, // Missing timeout
        {'requestTimeout': 45}, // Missing endpoint
      ];

      for (final json in testCases) {
        final settings = AppSettings.fromJson(json);

        // Should not throw and should have valid values
        expect(settings.apiEndpoint, isNotEmpty);
        expect(settings.requestTimeout, greaterThan(0));
      }
    });

    test('copyWith creates new instance with updated fields', () {
      final original = AppSettings(
        apiEndpoint: 'https://original.com/predict',
        requestTimeout: 30,
      );

      final updated = original.copyWith(
        apiEndpoint: 'https://updated.com/predict',
      );

      expect(updated.apiEndpoint, equals('https://updated.com/predict'));
      expect(updated.requestTimeout, equals(30)); // Unchanged
      expect(updated, isNot(equals(original)));
    });

    test('isDefaultEndpoint correctly identifies default endpoint', () {
      final defaultSettings = AppSettings.defaultSettings();
      expect(defaultSettings.isDefaultEndpoint, isTrue);

      final customSettings = AppSettings(
        apiEndpoint: 'https://custom.com/predict',
        requestTimeout: 30,
      );
      expect(customSettings.isDefaultEndpoint, isFalse);
    });

    test('equality operator works correctly', () {
      final settings1 = AppSettings(
        apiEndpoint: 'https://api.example.com/predict',
        requestTimeout: 30,
      );

      final settings2 = AppSettings(
        apiEndpoint: 'https://api.example.com/predict',
        requestTimeout: 30,
      );

      final settings3 = AppSettings(
        apiEndpoint: 'https://different.com/predict',
        requestTimeout: 30,
      );

      expect(settings1, equals(settings2));
      expect(settings1, isNot(equals(settings3)));
    });

    test('property: handles URLs with special characters', () {
      final specialUrlCases = [
        'https://api.example.com/predict?key=value',
        'https://api.example.com/predict#fragment',
        'https://user:pass@api.example.com/predict',
        'https://api.example.com/path%20with%20encoding/predict',
      ];

      for (final url in specialUrlCases) {
        final settings = AppSettings(apiEndpoint: url, requestTimeout: 30);

        final json = settings.toJson();
        final deserialized = AppSettings.fromJson(json);

        expect(deserialized.apiEndpoint, equals(url));
      }
    });

    test('property: multiple serialization cycles preserve data', () {
      var settings = AppSettings(
        apiEndpoint: 'https://api.example.com/predict',
        requestTimeout: 45,
      );

      // Perform multiple serialization/deserialization cycles
      for (int i = 0; i < 10; i++) {
        final json = settings.toJson();
        settings = AppSettings.fromJson(json);
      }

      // After 10 cycles, data should still be intact
      expect(settings.apiEndpoint, equals('https://api.example.com/predict'));
      expect(settings.requestTimeout, equals(45));
    });

    test('toString provides useful information', () {
      final settings = AppSettings(
        apiEndpoint: 'https://api.example.com/predict',
        requestTimeout: 30,
      );

      final stringRepresentation = settings.toString();

      expect(stringRepresentation, contains('api.example.com'));
      expect(stringRepresentation, contains('30'));
    });
  });
}
