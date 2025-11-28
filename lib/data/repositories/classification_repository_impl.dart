import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/classification_result.dart';
import '../models/api_response.dart';
import 'classification_repository.dart';
import 'settings_repository.dart';

/// Implementation of ClassificationRepository using HTTP API
class ClassificationRepositoryImpl implements ClassificationRepository {
  final SettingsRepository _settingsRepository;
  final http.Client _httpClient;

  ClassificationRepositoryImpl(this._settingsRepository, this._httpClient);

  @override
  Future<ClassificationResult> classifyImage(File image) async {
    try {
      // Get API endpoint from settings
      final apiEndpoint = await _settingsRepository.getApiEndpoint();

      print('🔍 Starting classification...');
      print('📍 API Endpoint: $apiEndpoint');
      print('📁 Image path: ${image.path}');

      // Read image bytes
      Uint8List imageBytes;
      if (kIsWeb) {
        // On web, read from XFile
        final xFile = XFile(image.path);
        imageBytes = await xFile.readAsBytes();
      } else {
        imageBytes = await image.readAsBytes();
      }

      print('📦 Image size: ${imageBytes.length} bytes');

      print('📤 Sending request to API...');

      // On web, use CORS proxy to avoid CORS issues
      final requestUrl = kIsWeb
          ? 'https://corsproxy.io/?${Uri.encodeComponent(apiEndpoint)}'
          : apiEndpoint;

      print('🌐 Request URL: $requestUrl');

      // Create multipart request (as your backend expects)
      final request = http.MultipartRequest('POST', Uri.parse(requestUrl));
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', // Field name - adjust if your backend expects different name
          imageBytes,
          filename: 'image.jpg',
        ),
      );

      // Send multipart request
      final streamResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw NetworkException('Request timed out after 60 seconds');
        },
      );

      final response = await http.Response.fromStream(streamResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw ApiException(
          'API returned status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      // Parse response
      final responseData = jsonDecode(response.body);
      print('✅ Response parsed successfully');
      print('📊 Response data: $responseData');

      final apiResponse = ApiResponse.fromJson(responseData);
      print('🎯 Class name: ${apiResponse.className}');
      print('🔢 Predicted class: ${apiResponse.predictedClass}');
      print('📊 Confidence: ${apiResponse.confidence}');
      print('📈 All confidences: ${apiResponse.confidences}');

      // Save Grad-CAM image
      final gradCamPath = await _saveGradCamImage(
        apiResponse.gradCamBase64,
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
      print('🖼️ Grad-CAM saved to: $gradCamPath');

      // Create classification result
      final result = ClassificationResult(
        id: const Uuid().v4(),
        imagePath: image.path,
        klGrade: apiResponse.predictedClass,
        confidence: apiResponse.confidences[apiResponse.predictedClass] ?? 0.0,
        gradCamPath: gradCamPath,
        timestamp: DateTime.now(),
        allGradeConfidences: apiResponse.confidences,
      );

      print('✨ Classification complete!');
      print(
        '📋 Result: KL Grade ${result.klGrade}, Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
      );

      return result;
    } on NetworkException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      print('❌ Error during classification: $e');
      throw ApiException('Failed to classify image: ${e.toString()}');
    }
  }

  /// Save Grad-CAM image from base64 string
  Future<String> _saveGradCamImage(String base64Data, String id) async {
    try {
      // Decode base64 to bytes
      final bytes = base64Decode(base64Data);

      if (kIsWeb) {
        // On web, create a blob URL
        // For now, we'll return a data URL that can be used with Image.network
        return 'data:image/png;base64,$base64Data';
      } else {
        // On mobile/desktop, save to temporary directory
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/gradcam_$id.png');
        await file.writeAsBytes(bytes);
        return file.path;
      }
    } catch (e) {
      print('⚠️ Failed to save Grad-CAM image: $e');
      throw ApiException('Failed to save Grad-CAM image: ${e.toString()}');
    }
  }
}
