import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/api_response.dart';
import '../models/file_dto.dart';

class AdminFileApiService {
  final String baseUrl;
  final Future<String?> Function() getAccessToken;

  AdminFileApiService({
    required this.baseUrl,
    required this.getAccessToken,
  });

  Future<FileDto> uploadImage(File file) async {
    return uploadFile(file: file, type: 'image');
  }

  Future<FileDto> uploadFile({
    required File file,
    required String type,
  }) async {
    final uri = Uri.parse('$baseUrl/files/upload').replace(
      queryParameters: {'type': type},
    );

    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse<FileDto>.fromJson(
        body,
        (data) => FileDto.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse.data;
    }

    throw _buildException(response);
  }

  Future<FileDto> uploadFileBytes({
    required List<int> bytes,
    required String filename,
    required String type,
  }) async {
    final uri = Uri.parse('$baseUrl/files/upload').replace(
      queryParameters: {'type': type},
    );

    final request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse<FileDto>.fromJson(
        body,
        (data) => FileDto.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse.data;
    }

    throw _buildException(response);
  }

  Future<List<FileDto>> uploadMultipleFiles({
    required List<File> files,
    required String type,
  }) async {
    if (files.isEmpty) return [];

    final uri = Uri.parse('$baseUrl/files/upload-multiple').replace(
      queryParameters: {'type': type},
    );

    final request = http.MultipartRequest('POST', uri);
    for (final file in files) {
      request.files.add(await http.MultipartFile.fromPath('files', file.path));
    }

    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse<List<FileDto>>.fromJson(
        body,
        (data) => (data as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(FileDto.fromJson)
            .toList(),
      );
      return apiResponse.data;
    }

    throw _buildException(response);
  }

  Exception _buildException(http.Response response) {
    try {
      if (response.body.trim().isNotEmpty) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return Exception(body['message'] ?? 'Upload file thất bại');
      }
      return Exception('Upload file thất bại');
    } catch (_) {
      return Exception('Upload file thất bại: ${response.statusCode}');
    }
  }
}
