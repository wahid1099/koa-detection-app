import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/classification_result.dart';

/// Abstract repository for managing classification history
abstract class HistoryRepository {
  /// Get all classification results from history
  Future<List<ClassificationResult>> getAll();

  /// Save a classification result to history
  Future<void> save(ClassificationResult result);

  /// Delete a classification result from history by ID
  Future<void> delete(String id);

  /// Get a specific classification result by ID
  Future<ClassificationResult?> getById(String id);
}

/// Implementation of HistoryRepository using sqflite
class HistoryRepositoryImpl implements HistoryRepository {
  static const String _tableName = 'classification_history';
  static const String _dbName = 'koa_detection.db';
  static const int _dbVersion = 1;

  Database? _database;

  /// Get database instance, initializing if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);

      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _onCreate,
        onOpen: (db) async {
          // Ensure foreign keys are enabled
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    } catch (e) {
      throw HistoryOperationException('Failed to initialize database: $e');
    }
  }

  /// Create database schema
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        imagePath TEXT NOT NULL,
        klGrade INTEGER NOT NULL,
        confidence REAL NOT NULL,
        gradCamPath TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        allGradeConfidences TEXT NOT NULL
      )
    ''');
  }

  @override
  Future<List<ClassificationResult>> getAll() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'timestamp DESC', // Order by newest first
      );

      return maps.map((map) => _fromDatabaseMap(map)).toList();
    } catch (e) {
      throw HistoryOperationException('Failed to retrieve history: $e');
    }
  }

  @override
  Future<void> save(ClassificationResult result) async {
    try {
      final db = await database;
      await db.insert(
        _tableName,
        _toDatabaseMap(result),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw HistoryOperationException('Failed to save classification: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final db = await database;
      final result = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result == 0) {
        throw HistoryOperationException('Classification with id $id not found');
      }
    } catch (e) {
      if (e is HistoryOperationException) rethrow;
      throw HistoryOperationException('Failed to delete classification: $e');
    }
  }

  @override
  Future<ClassificationResult?> getById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return _fromDatabaseMap(maps.first);
    } catch (e) {
      throw HistoryOperationException('Failed to retrieve classification: $e');
    }
  }

  /// Convert ClassificationResult to database map
  Map<String, dynamic> _toDatabaseMap(ClassificationResult result) {
    // Convert allGradeConfidences map to JSON string for storage
    final confidencesJson = result.allGradeConfidences.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');

    return {
      'id': result.id,
      'imagePath': result.imagePath,
      'klGrade': result.klGrade,
      'confidence': result.confidence,
      'gradCamPath': result.gradCamPath,
      'timestamp': result.timestamp.toIso8601String(),
      'allGradeConfidences': confidencesJson,
    };
  }

  /// Convert database map to ClassificationResult
  ClassificationResult _fromDatabaseMap(Map<String, dynamic> map) {
    // Parse allGradeConfidences from JSON string
    final confidencesString = map['allGradeConfidences'] as String;
    final allGradeConfidences = <int, double>{};

    if (confidencesString.isNotEmpty) {
      for (final entry in confidencesString.split(',')) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          allGradeConfidences[int.parse(parts[0])] = double.parse(parts[1]);
        }
      }
    }

    return ClassificationResult(
      id: map['id'] as String,
      imagePath: map['imagePath'] as String,
      klGrade: map['klGrade'] as int,
      confidence: (map['confidence'] as num).toDouble(),
      gradCamPath: map['gradCamPath'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      allGradeConfidences: allGradeConfidences,
    );
  }

  /// Close the database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

/// Exception thrown when a history operation fails
class HistoryOperationException implements Exception {
  final String message;
  HistoryOperationException(this.message);

  @override
  String toString() => 'HistoryOperationException: $message';
}
