import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koa_detecion/presentation/screens/home_screen.dart';
import 'package:koa_detecion/presentation/screens/image_selection_screen.dart';
import 'package:koa_detecion/presentation/screens/history_screen.dart';
import 'package:koa_detecion/presentation/screens/settings_screen.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('displays all required navigation buttons', (
      WidgetTester tester,
    ) async {
      // Build the HomeScreen widget
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for any async operations to complete
      await tester.pumpAndSettle();

      // Verify that all three navigation buttons are present
      expect(find.text('New Classification'), findsOneWidget);
      expect(find.text('View History'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify button icons are present
      expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('displays app title and welcome text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      await tester.pumpAndSettle();

      // Verify app title in AppBar
      expect(find.text('KOA Detection'), findsOneWidget);

      // Verify welcome text
      expect(find.text('Welcome to KOA Detection'), findsOneWidget);
      expect(
        find.text('Analyze knee X-rays for osteoarthritis detection'),
        findsOneWidget,
      );
    });

    testWidgets('displays total classifications stat', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Verify the stats card is displayed
      expect(find.text('Total Classifications'), findsOneWidget);

      // Verify a number is displayed (could be 0 or more)
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets(
      'navigates to ImageSelectionScreen when New Classification is tapped',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

        await tester.pumpAndSettle();

        // Tap the New Classification button
        await tester.tap(find.text('New Classification'));
        await tester.pumpAndSettle();

        // Verify navigation to ImageSelectionScreen
        expect(find.byType(ImageSelectionScreen), findsOneWidget);
      },
    );

    testWidgets('navigates to HistoryScreen when View History is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      await tester.pumpAndSettle();

      // Tap the View History button
      await tester.tap(find.text('View History'));
      await tester.pumpAndSettle();

      // Verify navigation to HistoryScreen
      expect(find.byType(HistoryScreen), findsOneWidget);
    });

    testWidgets('navigates to SettingsScreen when Settings is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      await tester.pumpAndSettle();

      // Tap the Settings button
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Verify navigation to SettingsScreen
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('displays medical services icon', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      await tester.pumpAndSettle();

      // Verify the medical services icon is displayed
      expect(find.byIcon(Icons.medical_services), findsOneWidget);
    });
  });
}
