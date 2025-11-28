/// Model representing a knee osteoarthritis classification result
class ClassificationResult {
  final String id;
  final String imagePath;
  final int klGrade;
  final double confidence;
  final String gradCamPath;
  final DateTime timestamp;
  final Map<int, double> allGradeConfidences;

  ClassificationResult({
    required this.id,
    required this.imagePath,
    required this.klGrade,
    required this.confidence,
    required this.gradCamPath,
    required this.timestamp,
    required this.allGradeConfidences,
  });

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'klGrade': klGrade,
      'confidence': confidence,
      'gradCamPath': gradCamPath,
      'timestamp': timestamp.toIso8601String(),
      'allGradeConfidences': allGradeConfidences.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }

  /// Create model from JSON
  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    return ClassificationResult(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      klGrade: json['klGrade'] as int,
      confidence: (json['confidence'] as num).toDouble(),
      gradCamPath: json['gradCamPath'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      allGradeConfidences: (json['allGradeConfidences'] as Map<String, dynamic>)
          .map(
            (key, value) => MapEntry(int.parse(key), (value as num).toDouble()),
          ),
    );
  }

  /// Create a copy with modified fields
  ClassificationResult copyWith({
    String? id,
    String? imagePath,
    int? klGrade,
    double? confidence,
    String? gradCamPath,
    DateTime? timestamp,
    Map<int, double>? allGradeConfidences,
  }) {
    return ClassificationResult(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      klGrade: klGrade ?? this.klGrade,
      confidence: confidence ?? this.confidence,
      gradCamPath: gradCamPath ?? this.gradCamPath,
      timestamp: timestamp ?? this.timestamp,
      allGradeConfidences: allGradeConfidences ?? this.allGradeConfidences,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassificationResult &&
        other.id == id &&
        other.imagePath == imagePath &&
        other.klGrade == klGrade &&
        other.confidence == confidence &&
        other.gradCamPath == gradCamPath &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      imagePath,
      klGrade,
      confidence,
      gradCamPath,
      timestamp,
    );
  }

  @override
  String toString() {
    return 'ClassificationResult(id: $id, klGrade: $klGrade, confidence: $confidence, timestamp: $timestamp)';
  }
}
