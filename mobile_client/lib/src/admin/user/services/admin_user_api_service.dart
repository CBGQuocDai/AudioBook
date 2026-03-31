import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/admin_user_search_request.dart';
import '../models/api_response.dart';
import '../models/create_user_request.dart';
import '../models/page_response.dart';
import '../models/update_user_request.dart';
import '../models/user_response.dart';

class AdminUserApiService {
  final String baseUrl;
  final Future<String?> Function() getAccessToken;

  AdminUserApiService({
    required this.baseUrl,
    required this.getAccessToken,
  });

  Future<Map<String, String>> _headers() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Exception _buildException(http.Response response) {
    try {
      final body = _decodeResponse(response);
      if (body is Map<String, dynamic>) {
        return Exception(body['message'] ?? 'Request failed');
      }
      return Exception('Request failed');
    } catch (_) {
      return Exception('Request failed: ${response.statusCode}');
    }
  }

  Future<PageResponse<UserResponse>> searchUsers(AdminUserSearchRequest request) async {
    final uri = Uri.parse('$baseUrl/admin/users/search').replace(
      queryParameters: request.toQueryParameters(),
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = _decodeResponse(response) as Map<String, dynamic>;
      final apiResponse = ApiResponse<PageResponse<UserResponse>>.fromJson(
        body,
            (data) => PageResponse<UserResponse>.fromJson(
          data as Map<String, dynamic>,
              (item) => UserResponse.fromJson(item),
        ),
      );
      return apiResponse.data;
    }

    throw _buildException(response);
  }

  Future<UserResponse> getUserById(int id) async {
    final uri = Uri.parse('$baseUrl/admin/users/$id');
    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = _decodeResponse(response) as Map<String, dynamic>;
      final apiResponse = ApiResponse<UserResponse>.fromJson(
        body,
            (data) => UserResponse.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse.data;
    }

    throw _buildException(response);
  }

  Future<UserResponse> createUser(CreateUserRequest request) async {
    final uri = Uri.parse('$baseUrl/admin/users');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = _decodeResponse(response) as Map<String, dynamic>;
      final apiResponse = ApiResponse<UserResponse>.fromJson(
        body,
            (data) => UserResponse.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse.data;
    }

    throw _buildException(response);
  }

  Future<UserResponse> updateUser(int id, UpdateUserRequest request) async {
    final uri = Uri.parse('$baseUrl/admin/users/$id');
    final response = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = _decodeResponse(response) as Map<String, dynamic>;
      final apiResponse = ApiResponse<UserResponse>.fromJson(
        body,
            (data) => UserResponse.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse.data;
    }

    throw _buildException(response);
  }

  Future<void> deleteUser(int id) async {
    final uri = Uri.parse('$baseUrl/admin/users/$id');
    final response = await http.delete(uri, headers: await _headers());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }
  }
}