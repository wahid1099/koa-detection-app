import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:koa_detecion/presentation/screens/history_screen.dart';
import 'package:koa_detecion/presentation/screens/history_detail_screen.dart';
import 'package:koa_detecion/presentation/providers/history_provider.dart';
import 'package:koa_detecion/data/models/classification_result.dart';

void main() {
  group('HistoryScreen Widget Tests', () {
    late MockHistoryProvider mockHistoryProvider;

    setUp(() {
      mockHistoryProvider = MockHistoryProvider();
    });

    Widget createTestWidget({List<ClassificationResult>? entries}) {
      if (entries != null) {
        mockHistoryProvider.setMockEntries(entries);
      }

      return MaterialApp(
        home: ChangeNotifierProvider<HistoryProvider>.value(
          value: mockHistoryProvider,
          child: const HistoryScreen(),
        ),
        onGenerateRoute: (settings) {
          if (settings.name == '/history-detail') {
            final entryId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => HistoryDetailScreen(entryId: entryId),
            );
          }
          return null;
        },
      );
    }

    testWidgets('displays loading indicator when loading', (
      WidgetTester tester,
    ) async {
      mockHistoryProvider.setLoading(true);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error view when error occurs', (
      WidgetTester tester,
    ) async {
      mockHistoryProvider.setError('Failed to load history');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Error Loading History'), findsOneWidget);
      expect(find.text('Failed to load history'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('displays empty view when no entries exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(entries: []));
      await tester.pumpAndSettle();

      expect(find.text('No Classifications Yet'), findsOneWidget);
      expect(
        find.text(
          'Your classification history will appear here after you analyze your first X-ray image.',
        ),
        findsOneWidget,
      );
      expect(find.text('Start Classification'), findsOneWidget);
    });

    testWidgets('displays history entries in correct order', (
      WidgetTester tester,
    ) async {
      final entries = [
        _createMockEntry(
          '1',
          DateTime.now().subtract(const Duration(days: 1)),
          2,
        ),
        _createMockEntry(
          '2',
          DateTime.now().subtract(const Duration(days: 2)),
          1,
        ),
        _createMockEntry(
          '3',
          DateTime.now().subtract(const Duration(days: 3)),
          3,
        ),
      ];

      await tester.pumpWidget(createTestWidget(entries: entries));
      await tester.pumpAndSettle();

      // Verify entries are displayed
      expect(find.text('KL Grade: 2'), findsOneWidget);
      expect(find.text('KL Grade: 1'), findsOneWidget);
      expect(find.text('KL Grade: 3'), findsOneWidget);

      // Verify they appear in reverse chronological order (newest first)
      final listTiles = find.byType(ListTile);
      expect(listTiles, findsNWidgets(3));
    });

    testWidgets('displays entry details correctly', (
      WidgetTester tester,
    ) async {
      final entry = _createMockEntry('test-id', DateTime.now(), 4);

      await tester.pumpWidget(createTestWidget(entries: [entry]));
      await tester.pumpAndSettle();

      // Verify KL grade is displayed
      expect(find.text('KL Grade: 4'), findsOneWidget);

      // Verify confidence is displayed
      expect(find.textContaining('Confidence: '), findsOneWidget);

      // Verify grade label is displayed
      expect(find.text('Severe'), findsOneWidget);

      // Verify timestamp is displayed
      expect(find.textContaining('2024'), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog when delete is tapped', (
      WidgetTester tester,
    ) async {
      final entry = _createMockEntry('test-id', DateTime.now(), 2);

      await tester.pumpWidget(createTestWidget(entries: [entry]));
      await tester.pumpAndSettle();

      // Tap the popup menu button
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap delete option
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Delete Classification'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete this classification?'),
        findsOneWidget,
      );
      expect(find.text('This action cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(
        find.text('Delete'),
        findsNWidgets(2),
      ); // One in dialog, one in menu
    });

    testWidgets('navigates to detail view when entry is tapped', (
      WidgetTester tester,
    ) async {
      final entry = _createMockEntry('test-id', DateTime.now(), 1);

      await tester.pumpWidget(createTestWidget(entries: [entry]));
      await tester.pumpAndSettle();

      // Tap the list tile
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // Verify navigation to detail screen
      expect(find.byType(HistoryDetailScreen), findsOneWidget);
    });

    testWidgets('displays refresh button in app bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('displays correct app bar title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Classification History'), findsOneWidget);
    });

    testWidgets('supports pull to refresh', (WidgetTester tester) async {
      final entries = [_createMockEntry('1', DateTime.now(), 1)];

      await tester.pumpWidget(createTestWidget(entries: entries));
      await tester.pumpAndSettle();

      // Verify RefreshIndicator is present
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });

  group('HistoryDetailScreen Widget Tests', () {
    late MockHistoryProvider mockHistoryProvider;

    setUp(() {
      mockHistoryProvider = MockHistoryProvider();
    });

    Widget createDetailTestWidget(
      String entryId, {
      ClassificationResult? entry,
    }) {
      if (entry != null) {
        mockHistoryProvider.setMockEntries([entry]);
      }

      return MaterialApp(
        home: ChangeNotifierProvider<HistoryProvider>.value(
          value: mockHistoryProvider,
          child: HistoryDetailScreen(entryId: entryId),
        ),
      );
    }

    testWidgets('displays not found view when entry does not exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createDetailTestWidget('non-existent-id'));
      await tester.pumpAndSettle();

      expect(find.text('Classification Not Found'), findsOneWidget);
      expect(
        find.text(
          'The requested classification could not be found. It may have been deleted.',
        ),
        findsOneWidget,
      );
      expect(find.text('Go Back'), findsOneWidget);
    });

    testWidgets('displays all classification details when entry exists', (
      WidgetTester tester,
    ) async {
      final entry = _createMockEntry('test-id', DateTime.now(), 3);

      await tester.pumpWidget(createDetailTestWidget('test-id', entry: entry));
      await tester.pumpAndSettle();

      // Verify classification summary
      expect(find.text('Classification Result'), findsOneWidget);
      expect(find.text('KL Grade: 3'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.textContaining('Confidence: '), findsOneWidget);

      // Verify sections are present
      expect(find.text('About KL Grade 3'), findsOneWidget);
      expect(find.text('Original X-ray Image'), findsOneWidget);
      expect(find.text('Grad-CAM Visualization'), findsOneWidget);
      expect(find.text('Confidence Breakdown'), findsOneWidget);
    });

    testWidgets('displays correct app bar with share button', (
      WidgetTester tester,
    ) async {
      final entry = _createMockEntry('test-id', DateTime.now(), 2);

      await tester.pumpWidget(createDetailTestWidget('test-id', entry: entry));
      await tester.pumpAndSettle();

      expect(find.text('Classification Details'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('displays re-save floating action button', (
      WidgetTester tester,
    ) async {
      final entry = _createMockEntry('test-id', DateTime.now(), 1);

      await tester.pumpWidget(createDetailTestWidget('test-id', entry: entry));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Re-save'), findsOneWidget);
      expect(find.byIcon(Icons.save_alt), findsOneWidget);
    });

    testWidgets('displays confidence breakdown for all grades', (
      WidgetTester tester,
    ) async {
      final entry = _createMockEntry('test-id', DateTime.now(), 2);

      await tester.pumpWidget(createDetailTestWidget('test-id', entry: entry));
      await tester.pumpAndSettle();

      // Verify confidence breakdown section
      expect(find.text('Confidence Breakdown'), findsOneWidget);

      // Verify progress indicators for grades
      expect(find.byType(LinearProgressIndicator), findsWidgets);

      // Verify grade labels
      expect(find.textContaining('Grade 0:'), findsOneWidget);
      expect(find.textContaining('Grade 1:'), findsOneWidget);
      expect(find.textContaining('Grade 2:'), findsOneWidget);
      expect(find.textContaining('Grade 3:'), findsOneWidget);
      expect(find.textContaining('Grade 4:'), findsOneWidget);
    });
  });
}

/// Mock HistoryProvider for testing
class MockHistoryProvider extends ChangeNotifier implements HistoryProvider {
  List<ClassificationResult> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  List<ClassificationResult> get historyEntries => _entries;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get errorMessage => _errorMessage;

  @override
  bool get hasEntries => _entries.isNotEmpty;

  @override
  int get totalCount => _entries.length;

  void setMockEntries(List<ClassificationResult> entries) {
    _entries = entries;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  @override
  ClassificationResult? getEntryById(String id) {
    try {
      return _entries.firstWhere((entry) => entry.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> loadHistory() async {
    // Mock implementation
  }

  @override
  Future<bool> deleteEntry(String id) async {
    _entries.removeWhere((entry) => entry.id == id);
    notifyListeners();
    return true;
  }

  @override
  Future<void> refresh() async {
    // Mock implementation
  }

  @override
  void addEntry(ClassificationResult result) {
    _entries.insert(0, result);
    notifyListeners();
  }

  @override
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Required overrides for HistoryProvider interface
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Create a mock classification result for testing
ClassificationResult _createMockEntry(
  String id,
  DateTime timestamp,
  int klGrade,
) {
  return ClassificationResult(
    id: id,
    imagePath: '/test/image_$id.jpg',
    klGrade: klGrade,
    confidence: 0.85,
    gradCamPath: '/test/gradcam_$id.jpg',
    timestamp: timestamp,
    allGradeConfidences: {0: 0.05, 1: 0.10, 2: 0.15, 3: 0.20, 4: 0.50},
  );
}
