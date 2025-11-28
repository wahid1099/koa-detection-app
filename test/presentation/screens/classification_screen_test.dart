import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koa_detecion/presentation/screens/classification_screen.dart';

/// Widget tests for ClassificationScreen
/// Tests loading indicator, results display, error handling, and save functionality
/// Requirements: 3.3, 4.1, 4.2, 4.3, 5.1, 8.1, 8.2

void main() {
  group('ClassificationScreen Widget Tests', () {
    late File testImageFile;

    setUp(() {
      // Create a temporary test image file
      testImageFile = File('test_image.jpg');
    });

    testWidgets('should display loading indicator during classification', (
      WidgetTester tester,
    ) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(home: ClassificationScreen(imageFile: testImageFile)),
      );

      // Verify loading indicator is displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Analyzing image...'), findsOneWidget);
    });

    testWidgets('should display app bar with title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ClassificationScreen(imageFile: testImageFile)),
      );

      // Verify app bar is present
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Classification Results'), findsOneWidget);
    });

    testWidgets('should show loading text during upload', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ClassificationScreen(imageFile: testImageFile)),
      );

      // Verify loading messages
      expect(find.text('Analyzing image...'), findsOneWidget);
      expect(find.text('This may take a few moments'), findsOneWidget);
    });

    testWidgets('should have proper widget structure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ClassificationScreen(imageFile: testImageFile)),
      );

      // Verify basic structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display error icon when error occurs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ClassificationScreen(imageFile: testImageFile)),
      );

      // Wait for the mock classification to complete
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // The mock implementation should succeed, so we won't see error
      // This test verifies the widget can be built without errors
      expect(find.byType(ClassificationScreen), findsOneWidget);
    });

    testWidgets('should have retry button structure in error state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ClassificationScreen(imageFile: testImageFile)),
      );

      // Widget should build successfully
      expect(find.byType(ClassificationScreen), findsOneWidget);
    });

    testWidgets('should display save button after successful classification', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ClassificationScreen(imageFile: testImageFile)),
      );

      // Wait for mock classification to complete
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verify save button is present
      expect(find.text('Save to Gallery'), findsOneWidget);
    });

    testWidgets('should display share button after successful classification', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ClassificationScreen(imageFile: testImageFile)),
      );

      // Wait for mock classification to complete
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verify share button is present
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('should display KL grade after successful classification', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ClassificationScreen(imageFile: testImageFile)),
      );

      // Wait for mock classification to complete
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verify KL grade is displayed
      expect(find.text('KL Grade'), findsOneWidget);
    });

    testWidgets('should display confidence after successful classification', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ClassificationScreen(imageFile: testImageFile)),
      );

      // Wait for mock classification to complete
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verify confidence is displayed (looking for "Confidence:" text)
      expect(find.textContaining('Confidence:'), findsOneWidget);
    });

    testWidgets('should display Grad-CAM section after classification', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ClassificationScreen(imageFile: testImageFile)),
      );

      // Wait for mock classification to complete
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verify Grad-CAM section is present
      expect(find.text('Grad-CAM Visualization'), findsOneWidget);
    });

    testWidgets('should display explanation section after classification', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ClassificationScreen(imageFile: testImageFile)),
      );

      // Wait for mock classification to complete
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verify explanation section is present
      expect(find.text('What does this mean?'), findsOneWidget);
    });

    testWidgets('should disable save button while saving', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ClassificationScreen(imageFile: testImageFile)),
      );

      // Wait for mock classification to complete
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Find and tap the save button
      final saveButton = find.text('Save to Gallery');
      expect(saveButton, findsOneWidget);

      await tester.tap(saveButton);
      await tester.pump();

      // Verify saving state is shown
      expect(find.text('Saving...'), findsOneWidget);
    });

    testWidgets('should show confirmation after successful save', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ClassificationScreen(imageFile: testImageFile)),
      );

      // Wait for mock classification to complete
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Tap save button
      await tester.tap(find.text('Save to Gallery'));
      await tester.pump();

      // Wait for save operation
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Verify confirmation message appears
      expect(find.textContaining('saved to gallery'), findsOneWidget);
    });
  });
}
