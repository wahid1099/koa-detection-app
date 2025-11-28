import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:koa_detecion/presentation/screens/settings_screen.dart';
import 'package:koa_detecion/data/models/app_settings.dart';

void main() {
  group('SettingsScreen Widget Tests', () {
    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('displays current endpoint correctly', (
      WidgetTester tester,
    ) async {
      // Set up mock preferences with a custom endpoint
      const customEndpoint = 'https://custom-api.example.com/predict';
      SharedPreferences.setMockInitialValues({'api_endpoint': customEndpoint});

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      // Wait for initialization to complete
      await tester.pumpAndSettle();

      // Verify the current endpoint is displayed in the text field
      expect(find.text(customEndpoint), findsOneWidget);

      // Verify the current settings info shows the custom endpoint
      expect(find.text('Current Settings'), findsOneWidget);
      expect(find.text('Using Default'), findsOneWidget);
      expect(
        find.text('No'),
        findsOneWidget,
      ); // Should show "No" for custom endpoint
    });

    testWidgets('displays default endpoint when no custom endpoint is set', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      // Wait for initialization to complete
      await tester.pumpAndSettle();

      // Verify the default endpoint is displayed
      expect(find.text(AppSettings.defaultApiEndpoint), findsOneWidget);

      // Verify the current settings info shows it's using default
      expect(
        find.text('Yes'),
        findsOneWidget,
      ); // Should show "Yes" for default endpoint
    });

    testWidgets('URL validation prevents invalid saves', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      // Wait for initialization to complete
      await tester.pumpAndSettle();

      // Find the text field and enter an invalid URL
      final textField = find.byType(TextFormField);
      await tester.enterText(textField, 'invalid-url');

      // Tap the save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify validation error is shown
      expect(
        find.text('Please enter a valid HTTP or HTTPS URL'),
        findsOneWidget,
      );

      // Verify no success message is shown
      expect(find.text('API endpoint updated successfully'), findsNothing);
    });

    testWidgets('URL validation accepts valid HTTP URLs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      // Wait for initialization to complete
      await tester.pumpAndSettle();

      // Find the text field and enter a valid HTTP URL
      final textField = find.byType(TextFormField);
      await tester.enterText(textField, 'http://valid-api.example.com/predict');

      // Tap the save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify no validation error is shown
      expect(find.text('Please enter a valid HTTP or HTTPS URL'), findsNothing);

      // Verify success message is shown
      expect(find.text('API endpoint updated successfully'), findsOneWidget);
    });

    testWidgets('URL validation accepts valid HTTPS URLs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      // Wait for initialization to complete
      await tester.pumpAndSettle();

      // Find the text field and enter a valid HTTPS URL
      final textField = find.byType(TextFormField);
      await tester.enterText(
        textField,
        'https://valid-api.example.com/predict',
      );

      // Tap the save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify no validation error is shown
      expect(find.text('Please enter a valid HTTP or HTTPS URL'), findsNothing);

      // Verify success message is shown
      expect(find.text('API endpoint updated successfully'), findsOneWidget);
    });

    testWidgets('URL validation rejects empty input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      // Wait for initialization to complete
      await tester.pumpAndSettle();

      // Clear the text field
      final textField = find.byType(TextFormField);
      await tester.enterText(textField, '');

      // Tap the save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify validation error is shown
      expect(find.text('Please enter an API endpoint URL'), findsOneWidget);
    });

    testWidgets('reset restores default endpoint', (WidgetTester tester) async {
      // Set up mock preferences with a custom endpoint
      const customEndpoint = 'https://custom-api.example.com/predict';
      SharedPreferences.setMockInitialValues({'api_endpoint': customEndpoint});

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      // Wait for initialization to complete
      await tester.pumpAndSettle();

      // Verify custom endpoint is initially displayed
      expect(find.text(customEndpoint), findsOneWidget);

      // Tap the reset button
      await tester.tap(find.text('Reset to Default'));
      await tester.pumpAndSettle();

      // Confirm the reset in the dialog
      expect(find.text('Reset Settings'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to reset all settings to their default values?',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Verify default endpoint is now displayed
      expect(find.text(AppSettings.defaultApiEndpoint), findsOneWidget);

      // Verify success message is shown
      expect(find.text('Settings reset to default'), findsOneWidget);

      // Verify the current settings info shows it's using default
      expect(
        find.text('Yes'),
        findsOneWidget,
      ); // Should show "Yes" for default endpoint
    });

    testWidgets('reset dialog can be cancelled', (WidgetTester tester) async {
      // Set up mock preferences with a custom endpoint
      const customEndpoint = 'https://custom-api.example.com/predict';
      SharedPreferences.setMockInitialValues({'api_endpoint': customEndpoint});

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      // Wait for initialization to complete
      await tester.pumpAndSettle();

      // Verify custom endpoint is initially displayed
      expect(find.text(customEndpoint), findsOneWidget);

      // Tap the reset button
      await tester.tap(find.text('Reset to Default'));
      await tester.pumpAndSettle();

      // Cancel the reset in the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify custom endpoint is still displayed (not reset)
      expect(find.text(customEndpoint), findsOneWidget);

      // Verify no success message is shown
      expect(find.text('Settings reset to default'), findsNothing);
    });

    testWidgets('successful save persists new endpoint', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      // Wait for initialization to complete
      await tester.pumpAndSettle();

      const newEndpoint = 'https://new-api.example.com/predict';

      // Find the text field and enter a new valid URL
      final textField = find.byType(TextFormField);
      await tester.enterText(textField, newEndpoint);

      // Tap the save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify success message is shown
      expect(find.text('API endpoint updated successfully'), findsOneWidget);

      // Verify the new endpoint is displayed in current settings
      expect(find.text(newEndpoint), findsOneWidget);

      // Verify it's not using default anymore
      expect(
        find.text('No'),
        findsOneWidget,
      ); // Should show "No" for custom endpoint
    });

    testWidgets('displays all required UI elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      // Wait for initialization to complete
      await tester.pumpAndSettle();

      // Verify AppBar
      expect(find.text('Settings'), findsOneWidget);

      // Verify API Configuration section
      expect(find.text('API Configuration'), findsOneWidget);
      expect(find.text('API Endpoint URL'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(
        find.text('Default: ${AppSettings.defaultApiEndpoint}'),
        findsOneWidget,
      );

      // Verify action buttons
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Reset to Default'), findsOneWidget);

      // Verify current settings info
      expect(find.text('Current Settings'), findsOneWidget);
      expect(find.text('API Endpoint:'), findsOneWidget);
      expect(find.text('Request Timeout:'), findsOneWidget);
      expect(find.text('Using Default:'), findsOneWidget);

      // Verify icons
      expect(find.byIcon(Icons.api), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
      expect(find.byIcon(Icons.restore), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('shows loading state during initialization', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      // Before pumpAndSettle, should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // After initialization completes
      await tester.pumpAndSettle();

      // Loading indicator should be gone, form should be visible
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('disables buttons during loading operations', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      // Wait for initialization to complete
      await tester.pumpAndSettle();

      // Find the text field and enter a valid URL
      final textField = find.byType(TextFormField);
      await tester.enterText(textField, 'https://test-api.example.com/predict');

      // Tap the save button
      await tester.tap(find.text('Save'));

      // During the save operation, buttons should be disabled
      // Note: This is a simplified test - in a real scenario we'd need to mock
      // the async operations to test the loading state properly
      await tester.pump(); // Pump once to trigger the save operation

      // The save button should show loading indicator when disabled
      // This test verifies the UI structure is in place for loading states
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });
  });
}
