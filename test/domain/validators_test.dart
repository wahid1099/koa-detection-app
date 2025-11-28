import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:koa_detecion/domain/validators.dart';

void main() {
  group('Validators', () {
    group('Image Format Validation', () {
      // Feature: koa-detection-app, Property 3: Image format validation
      // Validates: Requirements 2.4
      test(
        'Property 3: For any image file, validation should accept only JPEG and PNG formats',
        () {
          // Valid formats
          final validExtensions = [
            '.jpg',
            '.jpeg',
            '.png',
            '.JPG',
            '.JPEG',
            '.PNG',
          ];
          for (final ext in validExtensions) {
            final file = File('/path/to/image$ext');
            expect(
              Validators.isValidImageFormat(file),
              true,
              reason: 'Should accept $ext format',
            );
          }

          // Invalid formats
          final invalidExtensions = [
            '.gif',
            '.bmp',
            '.tiff',
            '.webp',
            '.svg',
            '.pdf',
            '.txt',
            '.doc',
            '',
            '.jp',
            '.pn',
            '.jpe',
          ];
          for (final ext in invalidExtensions) {
            final file = File('/path/to/image$ext');
            expect(
              Validators.isValidImageFormat(file),
              false,
              reason: 'Should reject $ext format',
            );
          }
        },
      );

      test('Property 3: Validation handles files without extensions', () {
        final file = File('/path/to/image');
        expect(Validators.isValidImageFormat(file), false);
      });

      test('Property 3: Validation handles mixed case extensions', () {
        final testCases = [
          '/path/to/image.JpG',
          '/path/to/image.JpEg',
          '/path/to/image.PnG',
          '/path/to/image.Jpg',
        ];

        for (final path in testCases) {
          final file = File(path);
          expect(
            Validators.isValidImageFormat(file),
            true,
            reason: 'Should accept $path (case insensitive)',
          );
        }
      });
    });

    group('URL Validation', () {
      // Feature: koa-detection-app, Property 19: URL validation correctness
      // Validates: Requirements 7.2, 7.4
      test(
        'Property 19: For any URL string, validation should accept valid HTTP/HTTPS URLs and reject malformed ones',
        () {
          // Valid URLs
          final validUrls = [
            'http://example.com',
            'https://example.com',
            'http://api.example.com',
            'https://api.example.com/v1/predict',
            'http://192.168.1.1',
            'https://192.168.1.1:8080',
            'http://localhost:3000',
            'https://wahid1099-koa-version-3.hf.space/predict',
            'http://example.com:8080/api/v1',
            'https://sub.domain.example.com/path?query=value',
          ];

          for (final url in validUrls) {
            expect(
              Validators.isValidUrl(url),
              true,
              reason: 'Should accept valid URL: $url',
            );
          }

          // Invalid URLs
          final invalidUrls = [
            '',
            'not a url',
            'ftp://example.com',
            'file:///path/to/file',
            'example.com',
            'www.example.com',
            'http://',
            'https://',
            'http:///',
            'http:// example.com',
            '://example.com',
            'http//example.com',
            'ht tp://example.com',
            'javascript:alert(1)',
            'data:text/html,<script>alert(1)</script>',
          ];

          for (final url in invalidUrls) {
            expect(
              Validators.isValidUrl(url),
              false,
              reason: 'Should reject invalid URL: $url',
            );
          }
        },
      );

      test('Property 19: Validation requires non-empty host', () {
        final urlsWithoutHost = ['http://', 'https://', 'http:///'];

        for (final url in urlsWithoutHost) {
          expect(
            Validators.isValidUrl(url),
            false,
            reason: 'Should reject URL without host: $url',
          );
        }
      });

      test('Property 19: Validation rejects non-HTTP(S) schemes', () {
        final nonHttpSchemes = [
          'ftp://example.com',
          'file:///path',
          'ws://example.com',
          'wss://example.com',
          'mailto:test@example.com',
        ];

        for (final url in nonHttpSchemes) {
          expect(
            Validators.isValidUrl(url),
            false,
            reason: 'Should reject non-HTTP(S) scheme: $url',
          );
        }
      });
    });
  });
}
