import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile_client/src/core/config/app_config.dart';

class ReadingPdfService {
  Future<List<String>> getChapterTextPages({
    required String bookName,
    required int chapterNumber,
    required String type,
    String? token,
  }) async {
    final trimmedName = bookName.trim();
    if (trimmedName.isEmpty || chapterNumber <= 0) {
      throw const ReadingPdfException('Thong tin chuong khong hop le.');
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/books/chapters/content').replace(
      queryParameters: {
        'bookName': trimmedName,
        'chapter': chapterNumber.toString(),
        'type': type,
      },
    );

    final response = await http.get(
      uri,
      headers: token == null || token.isEmpty ? null : {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      print('[ReadingPdfService] Chapter content failed: $uri => ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('[ReadingPdfService] Body: ${response.body}');
      }
      throw ReadingPdfException('Tai text that bai (${response.statusCode}).');
    }

    final text = _extractText(response.body);
    return _paginateText(text);
  }

  String _extractText(String rawBody) {
    final trimmed = rawBody.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is String) {
          return data;
        }
        if (data is Map<String, dynamic>) {
          final nested = data['content'] ?? data['text'] ?? data['data'];
          return nested?.toString() ?? trimmed;
        }
        final content = decoded['content'] ?? decoded['text'];
        if (content is String) {
          return content;
        }
      }
    } catch (_) {
      // Non-JSON response is treated as plain text.
    }

    return trimmed;
  }

  List<String> _paginateText(String text) {
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (normalized.isEmpty) {
      return const [''];
    }

    const maxChars = 1200;
    if (normalized.length <= maxChars) {
      return [normalized];
    }

    final words = normalized.split(RegExp(r'\s+'));
    final pages = <String>[];
    final buffer = StringBuffer();

    for (final word in words) {
      if (buffer.isNotEmpty && buffer.length + word.length + 1 > maxChars) {
        pages.add(buffer.toString().trim());
        buffer.clear();
      }
      if (buffer.isNotEmpty) {
        buffer.write(' ');
      }
      buffer.write(word);
    }

    if (buffer.isNotEmpty) {
      pages.add(buffer.toString().trim());
    }

    return pages;
  }
}

class ReadingPdfException implements Exception {
  const ReadingPdfException(this.message);

  final String message;

  @override
  String toString() => message;
}
