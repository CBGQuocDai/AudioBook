import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ReadingPdfService {
  Future<String> cachePdf({
    required String pdfUrl,
    required String fileName,
  }) async {
    final uri = Uri.tryParse(pdfUrl);
    if (uri == null || !uri.hasScheme) {
      throw const ReadingPdfException('URL PDF khong hop le.');
    }

    final dir = await getTemporaryDirectory();
    final sanitized = _sanitize(fileName.isEmpty ? 'chapter.pdf' : fileName);
    final ext = sanitized.toLowerCase().endsWith('.pdf') ? '' : '.pdf';
    final file = File('${dir.path}/$sanitized$ext');

    if (await file.exists() && await file.length() > 0) {
      return file.path;
    }

    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ReadingPdfException('Tai PDF that bai (${response.statusCode}).');
    }

    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file.path;
  }

  String _sanitize(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    if (cleaned.trim().isEmpty) {
      return 'chapter';
    }
    return cleaned;
  }
}

class ReadingPdfException implements Exception {
  const ReadingPdfException(this.message);

  final String message;

  @override
  String toString() => message;
}

