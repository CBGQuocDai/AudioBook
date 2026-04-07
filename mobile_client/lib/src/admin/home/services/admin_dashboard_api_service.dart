import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../user/models/api_response.dart';
import '../models/admin_dashboard_models.dart';

class AdminDashboardApiService {
  final String baseUrl;
  final Future<String?> Function() getAccessToken;

  AdminDashboardApiService({
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
    if (response.body.trim().isEmpty) return null;
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

  Future<UserDashboardData> getUserDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users/dashboard'),
      headers: await _headers(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = _decodeResponse(response) as Map<String, dynamic>;
      final apiResponse = ApiResponse<UserDashboardData>.fromJson(
        body,
        (data) => UserDashboardData.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse.data;
    }

    throw _buildException(response);
  }

  Future<BookDashboardData> getBookDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/books/dashboard'),
      headers: await _headers(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = _decodeResponse(response) as Map<String, dynamic>;
      final apiResponse = ApiResponse<BookDashboardData>.fromJson(
        body,
        (data) => BookDashboardData.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse.data;
    }

    throw _buildException(response);
  }

  Future<PaymentDashboardData> getPaymentDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/payments/dashboard'),
      headers: await _headers(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = _decodeResponse(response) as Map<String, dynamic>;
      final apiResponse = ApiResponse<PaymentDashboardData>.fromJson(
        body,
        (data) => PaymentDashboardData.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse.data;
    }

    throw _buildException(response);
  }

  Future<AdminDashboardBundle> getDashboardBundle() async {
    final results = await Future.wait<dynamic>([
      getUserDashboard(),
      getBookDashboard(),
      getPaymentDashboard(),
    ]);

    return AdminDashboardBundle(
      users: results[0] as UserDashboardData,
      books: results[1] as BookDashboardData,
      payments: results[2] as PaymentDashboardData,
    );
  }
}
