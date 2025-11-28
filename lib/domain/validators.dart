import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Validation utilities for the domain layer
class Validators {
  /// Validates if an image file has a supported format (JPEG or PNG)
  /// Returns true if the format is supported, false otherwise
  static bool isValidImageFormat(File imageFile) {
    final path = imageFile.path.toLowerCase();

    // On web, skip file extension validation since:
    // 1. Browser's file picker already filters by MIME type
    // 2. File paths on web are blob URLs, not traditional file paths
    if (kIsWeb) {
      return true;
    }

    // On mobile/desktop, check file extension
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png');
  }

  /// Validates if a URL string is properly formatted
  /// Returns true if the URL is valid HTTP/HTTPS, false otherwise
  static bool isValidUrl(String url) {
    if (url.isEmpty) {
      return false;
    }

    try {
      final uri = Uri.parse(url);
      // Check if scheme is http or https
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return false;
      }
      // Check if host is present
      if (uri.host.isEmpty) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
