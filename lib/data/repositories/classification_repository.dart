import 'dart:io';
import '../models/classification_result.dart';

/// Abstract repository for image classification operations
abstract class ClassificationRepository {
  /// Classifies an image and returns the classification result
  /// Throws [NetworkException] if network error occurs
  /// Throws [ApiException] if API returns an error
  Future<ClassificationResult> classifyImage(File image);
}

/// Exception thrown when network error occurs
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when API returns an error
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
