/// Model representing the API response from the classification service
class ApiResponse {
  final String className; // e.g., "KL-4"
  final int predictedClass; // e.g., 4 (extracted from "KL-4")
  final double confidence; // e.g., 0.9999
  final String gradCamBase64; // Base64 encoded Grad-CAM image
  final Map<int, double> confidences; // Generated confidence map

  ApiResponse({
    required this.className,
    required this.predictedClass,
    required this.confidence,
    required this.gradCamBase64,
    required this.confidences,
  });

  /// Create model from JSON response
  /// Handles your FastAPI format: {"class": "KL-4", "confidence": 0.9999, "gradcam": "BASE64_STRING"}
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    try {
      // Parse the class name (e.g., "KL-4")
      final className = json['class'] as String? ?? '';

      // Extract the numeric class from "KL-X" format
      int predictedClass = 0;
      if (className.startsWith('KL-')) {
        final classNumberStr = className.substring(3); // Remove "KL-"
        predictedClass = int.tryParse(classNumberStr) ?? 0;
      }

      // Get confidence value
      final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;

      // Get Grad-CAM base64 string
      final gradCamBase64 = json['gradcam'] as String? ?? '';

      // Create confidence map - put all confidence in the predicted class
      // In a real scenario, you might want to request all class confidences from your API
      final confidences = <int, double>{
        0: predictedClass == 0 ? confidence : 0.0,
        1: predictedClass == 1 ? confidence : 0.0,
        2: predictedClass == 2 ? confidence : 0.0,
        3: predictedClass == 3 ? confidence : 0.0,
        4: predictedClass == 4 ? confidence : 0.0,
      };

      return ApiResponse(
        className: className,
        predictedClass: predictedClass,
        confidence: confidence,
        gradCamBase64: gradCamBase64,
        confidences: confidences,
      );
    } catch (e) {
      throw FormatException('Failed to parse API response: $e');
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'class': className,
      'confidence': confidence,
      'gradcam': gradCamBase64,
      'predicted_class': predictedClass,
      'confidences': confidences,
    };
  }

  /// Get confidence for a specific class
  double getConfidenceForClass(int classIndex) {
    return confidences[classIndex] ?? 0.0;
  }

  /// Get the confidence for the predicted class
  double get predictedConfidence {
    return confidences[predictedClass] ?? 0.0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiResponse &&
        other.predictedClass == predictedClass &&
        other.gradCamBase64 == gradCamBase64;
  }

  @override
  int get hashCode {
    return Object.hash(predictedClass, gradCamBase64);
  }

  @override
  String toString() {
    return 'ApiResponse(className: $className, predictedClass: $predictedClass, confidence: ${confidence.toStringAsFixed(3)})';
  }
}
